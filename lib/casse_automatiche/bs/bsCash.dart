import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 1. COSTANTI E CONFIGURAZIONE (Constants & Config)
// =============================================================================

enum LogType { info, success, error, warning }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  LogEntry(this.message, {this.type = LogType.info})
      : timestamp = DateTime.now();
}

const String kAppName = 'BSCASH POS';

// Enterprise Palette - Slate/Emerald/Blue
class AppColors {
  static const Color primary = Color(0xFF1E293B); // Slate 900
  static const Color primaryLight = Color(0xFF334155); // Slate 700
  static const Color accent = Color(0xFF0EA5E9); // Sky 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color background = Color(0xFFF1F5F9); // Slate 100
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textSub = Color(0xFF64748B); // Slate 500
}

enum BSCommand {
  CHRG, // Incasso
  CANC, // Annullamento
  WTDW, // Prelievo
  STOC, // Stato
  ABRC, // Interrompi
  BKOF, // BackOffice
  CHNG, // Cambio
}

// =============================================================================
// 2. MODELLI DATI (Data Models)
// =============================================================================

class TransactionResult {
  final bool success;
  final String statusRaw;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? requestPayload; // Store original request
  final String message;
  final DateTime timestamp;
  final bool isCompleted; // True if response received, False if still pending

  TransactionResult({
    required this.success,
    required this.statusRaw,
    this.payload,
    this.requestPayload,
    required this.message,
    this.isCompleted = true,
  }) : timestamp = DateTime.now();

  factory TransactionResult.fromFileContent(String content) {
    final parts = content.split('|');

    if (parts.isEmpty) {
      return TransactionResult(
        success: false,
        statusRaw: 'ERR',
        message: "File di risposta vuoto",
      );
    }

    final status = parts[0];
    bool isSuccess = status == '000';
    Map<String, dynamic>? jsonPayload;
    String msg = '';

    if (parts.length > 1) {
      final jsonString = parts.sublist(1).join('|');
      try {
        if (jsonString.trim().isNotEmpty) {
          jsonPayload = jsonDecode(jsonString);
          if (jsonPayload != null &&
              jsonPayload.containsKey('error') &&
              jsonPayload['error'] != null) {
            msg = jsonPayload['error'];
          }
        }
      } catch (e) {
        msg = "Errore JSON: $e";
        isSuccess = false;
      }
    }

    if (isSuccess && msg.isEmpty) msg = "Operazione Completata";
    if (!isSuccess && msg.isEmpty) msg = "Errore Sistema ($status)";

    return TransactionResult(
      success: isSuccess,
      statusRaw: status,
      payload: jsonPayload,
      message: msg,
    );
  }
}

// =============================================================================
// 3. SERVICE LAYER (Logic)
// =============================================================================

class IntegrationService {
  String watchDirectory = "";
  String writeDirectory = "";

  // Cancellation support
  Completer<void>? _cancelCompleter;
  bool _isCancelled = false;
  File? _currentRequestFile; // Track current request file for cancellation
  BSCommand? _currentCommand; // Track current command
  Map<String, dynamic>? _currentPayload; // Track current payload for CANC command

  String _generateFileName(BSCommand cmd) {
    // Generate unique sequence number
    final seq = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
  // [cite: 7, 8] File Name format: BS-Command-SequenceNumber
    return "BS-${cmd.name}-$seq";
  }

  String formatAmount(double amount) => amount.toStringAsFixed(2);

  /// Request cancellation of the current transaction by deleting the request file
  Future<void> requestCancel() async {
    debugPrint("=== CANCEL REQUESTED ===");
    debugPrint("Current request file: $_currentRequestFile");
    
    _isCancelled = true;
    _cancelCompleter?.complete();
    
    // Delete the request file to signal cancellation to the simulator
    if (_currentRequestFile == null) {
      debugPrint("ERROR: No current request file to delete!");
      return;
    }
    
    debugPrint("Checking if file exists: ${_currentRequestFile!.path}");
    final exists = await _currentRequestFile!.exists();
    debugPrint("File exists: $exists");
    
    if (exists) {
      try {
        debugPrint("Attempting to delete file...");
        await _currentRequestFile!.delete();
        debugPrint("✓ Request file deleted successfully: ${_currentRequestFile!.path}");
      } catch (e) {
        debugPrint("✗ Failed to delete request file: $e");
      }
    } else {
      debugPrint("File does not exist, cannot delete");
    }
  }

  /// Reset cancellation state before starting a new transaction
  void _resetCancellation() {
    _isCancelled = false;
    _cancelCompleter = Completer<void>();
    _currentRequestFile = null; // Clear previous request file reference
    _currentCommand = null;
    _currentPayload = null;
  }

  Future<TransactionResult> executeTransaction({
    required BSCommand command,
    Map<String, dynamic>? payload,
    bool autoAbortOnTimeout = true,
    bool resetCancellation = true,
  }) async {
    // Reset cancellation state only if requested
    if (resetCancellation) {
      _resetCancellation();
    }

    // 1. Check Config
    if (watchDirectory.isEmpty || writeDirectory.isEmpty) {
      return TransactionResult(
        success: false,
        statusRaw: 'CFG',
        message: "Configurazione mancante",
      );
    }

    final fileName = _generateFileName(command);
    final requestPayload = jsonEncode(payload ?? {});
    
    // Store for potential CANC command
    _currentCommand = command;
    _currentPayload = payload;

    debugPrint("=== BS CASH TRANSACTION START ===");
    debugPrint("Command: ${command.name}");
    debugPrint("FileName: $fileName");
    debugPrint("Payload: $requestPayload");

    try {
      final dirInput = Directory(watchDirectory);
      final dirOutput = Directory(writeDirectory);

      // 2. Check Directories
      if (!await dirInput.exists() || !await dirOutput.exists()) {
        return TransactionResult(
          success: false,
          statusRaw: 'DIR',
          message: "Cartelle I/O non trovate. Verifica permessi.",
        );
      }

      final File requestFile = File(
        '${dirInput.path}${Platform.pathSeparator}$fileName',
      );
      
      // Store reference for potential cancellation
      _currentRequestFile = requestFile;

      // 3. Write File (Flush ensure it hits disk)
      debugPrint("Writing request file to: ${requestFile.path}");
      await requestFile.writeAsString(requestPayload, flush: true);
      debugPrint("Request file written successfully");

      // Small delay to let FS catch up
      await Future.delayed(const Duration(milliseconds: 100));

    // [cite: 16, 17] Answer file has same name as origin file
      final File answerFile = File(
        '${dirOutput.path}${Platform.pathSeparator}$fileName',
      );

      debugPrint("Waiting for response file: ${answerFile.path}");

      // 4. Poll for Answer
      int attempts = 0;
      const int maxAttempts = 1200; // 60 seconds (120 * 500ms)
      int? cancelledAtAttempt; // Track when cancellation was requested

      while (attempts < maxAttempts) {
        // Check if cancelled - but don't exit immediately, wait for response
          // Check if cancelled - exit immediately since we launched CANC separately
          if (_isCancelled) {
             debugPrint("Transaction cancelled - exiting polling loop immediately");
             return TransactionResult(
               success: true,
               statusRaw: 'SILENT_CANCEL', // Special status to ignore
               message: "Transazione annullata",
             );
          }
        
        // If cancelled, only wait up to 10 seconds (20 attempts) for response
        if (cancelledAtAttempt != null && (attempts - cancelledAtAttempt) > 20) {
          debugPrint("Timeout waiting for cancellation response after ${attempts - cancelledAtAttempt} attempts");
          debugPrint("Returning silently - CANC command was sent separately");
          // Return a silent success so we don't show an error
          // The CANC command result will be shown instead
          return TransactionResult(
            success: true,
            statusRaw: '000',
            message: "Transazione annullata.",
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));

        if (await answerFile.exists()) {
          debugPrint("Response file found at attempt $attempts");
          // Anti-lock delay
          await Future.delayed(const Duration(milliseconds: 300));
          final content = await answerFile.readAsString();
          debugPrint("Response content: $content");

        // [cite: 6] "It's YOUR duty to delete the answer file"
          try {
            await answerFile.delete();
            debugPrint("Response file deleted");
          } catch (e) {
            debugPrint("Warning: delete failed $e");
          }

          return TransactionResult.fromFileContent(content);
        }
        attempts++;

        if (attempts % 10 == 0) {
          debugPrint("Still waiting... attempt $attempts of $maxAttempts");
        }
      }

      // 5. Timeout - Auto send ABRC command if enabled
      debugPrint("Timeout reached after ${attempts * 500}ms");
      if (autoAbortOnTimeout && command != BSCommand.ABRC) {
        debugPrint("Sending ABRC due to timeout");
        await sendAbortCommand();
      }

      return TransactionResult(
        success: false,
        statusRaw: 'T/O',
        message: "Timeout Hardware (60s). Richiesta di annullamento inviata.",
      );
    } catch (e) {
      debugPrint("Exception in executeTransaction: $e");
      return TransactionResult(
        success: false,
        statusRaw: 'EXC',
        message: e.toString(),
      );
    }
  }

  /// Send ABRC (abort) command to cancel ongoing transaction
  Future<void> sendAbortCommand() async {
    try {
      final fileName = _generateFileName(BSCommand.ABRC);
      final dirInput = Directory(watchDirectory);

      if (await dirInput.exists()) {
        final File abortFile = File(
          '${dirInput.path}${Platform.pathSeparator}$fileName',
        );
      // [cite: 255] Abort command payload is empty object {}
        await abortFile.writeAsString(jsonEncode({}), flush: true);
        debugPrint("ABRC abort command sent");
      }
    } catch (e) {
      debugPrint("Failed to send ABRC: $e");
    }
  }
}

// =============================================================================
// 4. STATE MANAGEMENT
// =============================================================================

class BSCASHCONTROLLER extends ChangeNotifier {
  final IntegrationService service = IntegrationService();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => _logs;

  final List<TransactionResult> _transactionHistory = [];
  List<TransactionResult> get transactionHistory => _transactionHistory;

  TransactionResult? _lastResult;
  TransactionResult? get lastResult => _lastResult;

  void updatePaths(String watch, String write) async {
    service.watchDirectory = watch;
    service.writeDirectory = write;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('watchDirectory', watch);
    await prefs.setString('writeDirectory', write);

    notifyListeners();
  }

  Future<void> login(String in_, String out_) async {
    addLog("Verifica configurazione cartelle BS Cash...");
    try {
      final prefs = await SharedPreferences.getInstance();
      service.watchDirectory = in_ ;
      service.writeDirectory = out_;

      if (service.watchDirectory.isNotEmpty && service.writeDirectory.isNotEmpty ) {
        _isAuthenticated = true;
        addLog(
          "Configurazione valida. Accesso al POS abilitato.",
          type: LogType.success,
        );
      } else {
        addLog(
          "Cartelle non configurate. Configurare prima le cartelle I/O.",
          type: LogType.warning,
        );
      }
    } catch (e) {
      addLog("Errore durante la configurazione: $e", type: LogType.error);
    }
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    addLog("Disconnessione dal sistema BS Cash.", type: LogType.warning);
    notifyListeners();
  }

  Future<bool> runCommand(BSCommand cmd, {Map<String, dynamic>? data}) async {
    bool complete = true;

    _isLoading = true;
    addLog("Invio comando ${cmd.name}...", type: LogType.info);
    notifyListeners();

    try {
      final result = await service.executeTransaction(
        command: cmd,
        payload: data,
        // Don't reset cancellation flag if we are sending a CANC command
        // otherwise the original transaction will resume waiting!
        resetCancellation: cmd != BSCommand.CANC,
      );
      
      // If silent cancel, just return (CANC command will show its own result)
      if (result. statusRaw == 'SILENT_CANCEL') {
        _isLoading = false;
        notifyListeners();
        complete = false;
      }

      _lastResult = result;

      // Create result with request payload stored and mark as completed
      final resultWithRequest = TransactionResult(
        success: result.success,
        statusRaw: result.statusRaw,
        payload: result.payload,
        requestPayload: data, // Store the original request
        message: result.message,
        isCompleted: true, // Transaction received response
      );

      _transactionHistory.insert(0, resultWithRequest);
      _lastResult = resultWithRequest;

      // Log the result
      final logType = result.success ? LogType.success : LogType.error;
      addLog(
        "${cmd.name}: ${result.message} (${result.statusRaw})",
        type: logType,
      );

      if (_transactionHistory.length > 500) _transactionHistory.removeLast();
      if( !result.success ) complete = false;
    } catch (e) {
      _lastResult = TransactionResult(
        success: false,
        statusRaw: 'CRIT',
        message: e.toString(),
        isCompleted: true,
      );
      _transactionHistory.insert(0, _lastResult!);
      addLog("ERRORE ${cmd.name}: $e", type: LogType.error);
      if (_transactionHistory.length > 500) _transactionHistory.removeLast();
      complete = false;
    } finally {
      _isLoading = false;
      notifyListeners(); // Updates UI to show result
      return complete;
    }
    
  }

  void addLog(String msg, {LogType type = LogType.info}) {
    logs.insert(0, LogEntry(msg, type: type));
    if (logs.length > 100) logs.removeLast();
    notifyListeners();
  }

  /// Cancel the current ongoing transaction (Emergency Stop / Abort)
  Future<void> cancelCurrentTransaction() async {
    if (!_isLoading) return;

    addLog("Richiesta annullamento transazione...", type: LogType.warning);
    
    // First, stop the original transaction from waiting
    service._isCancelled = true;
    service._cancelCompleter?.complete();
    
    // Then send a CANC command with the original payload
    // This is the same approach as the "Storno" button and works correctly
    if (service._currentCommand == BSCommand.CHRG && service._currentPayload != null) {
      addLog("Invio comando CANC per annullare la transazione...", type: LogType.info);
      // Don't await - let it run in background
      runCommand(BSCommand.CANC, data: service._currentPayload);
    } else {
      addLog("Nessuna transazione attiva da annullare.", type: LogType.warning);
    }
  }
}

// =============================================================================
// 5. UI COMPONENTS & WIDGETS
// =============================================================================

/* void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BSCashFileProtocolPage(),
  ));
} */

class BSCashFileProtocolPage extends StatefulWidget {
  const BSCashFileProtocolPage({super.key});

  @override
  State<BSCashFileProtocolPage> createState() => _BSCashFileProtocolPageState();
}

class _BSCashFileProtocolPageState extends State<BSCashFileProtocolPage> {
  final BSCASHCONTROLLER _appState = BSCASHCONTROLLER();

  @override
  void initState() {
    super.initState();
   // _appState.login();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleStateProvider(state: _appState, child: const MainLayout());
  }
}

// --- STATE PROVIDER ---
class SimpleStateProvider extends InheritedWidget {
  final BSCASHCONTROLLER state;
  const SimpleStateProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static BSCASHCONTROLLER of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SimpleStateProvider>()!
        .state;
  }

  @override
  bool updateShouldNotify(SimpleStateProvider oldWidget) => true;
}

// --- TASTIERINO VIRTUALE ---
class VirtualNumpad extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDecimal;
  final bool isLoading;

  const VirtualNumpad({
    super.key,
    required this.controller,
    required this.onConfirm,
    this.onCancel,
    this.isDecimal = true,
    this.isLoading = false,
  });

  @override
  State<VirtualNumpad> createState() => _VirtualNumpadState();
}

class _VirtualNumpadState extends State<VirtualNumpad> {
  void _onKeyTap(String val) {
    if (val == 'C') {
      widget.controller.clear();
    } else if (val == '<') {
      if (widget.controller.text.isNotEmpty) {
        widget.controller.text = widget.controller.text.substring(
          0,
          widget.controller.text.length - 1,
        );
      }
    } else if (val == '.') {
      if (!widget.controller.text.contains('.')) {
        widget.controller.text += val;
      }
    } else {
      widget.controller.text += val;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            "Elaborazione in corso...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Attendere la risposta dalla macchina",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 32),
          if (widget.onCancel != null)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(
                  "ANNULLA TRANSAZIONE",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildKey('1'),
            const SizedBox(width: 8),
            _buildKey('2'),
            const SizedBox(width: 8),
            _buildKey('3'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildKey('4'),
            const SizedBox(width: 8),
            _buildKey('5'),
            const SizedBox(width: 8),
            _buildKey('6'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildKey('7'),
            const SizedBox(width: 8),
            _buildKey('8'),
            const SizedBox(width: 8),
            _buildKey('9'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildKey(widget.isDecimal ? '.' : ''),
            const SizedBox(width: 8),
            _buildKey('0'),
            const SizedBox(width: 8),
            _buildKey('<', icon: Icons.backspace_outlined),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "CONFERMA",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String value, {IconData? icon}) {
    if (value.isEmpty) return const Expanded(child: SizedBox());
    return Expanded(
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _onKeyTap(value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: AppColors.primaryLight)
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// --- LAYOUT PRINCIPALE ---

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = SimpleStateProvider.of(context);

    // ListenableBuilder ensures the WHOLE scaffold rebuilds when appState changes.
    return ListenableBuilder(
      listenable: appState,
      builder: (ctx, _) {
        return Scaffold(
          body: Row(
            children: [
              // 1. SIDEBAR
              Container(
                width: 280,
                color: AppColors.primary,
                child: Column(
                  children: [
                    // Brand Area
                    Container(
                      height: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, Colors.blue],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.point_of_sale,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "BS CASH",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "Enterprise",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    // Menu
                    _NavItem(
                      title: "Terminale POS",
                      icon: Icons.storefront_outlined,
                      isActive: _pageIndex == 0,
                      onTap: () => setState(() => _pageIndex = 0),
                    ),
                    _NavItem(
                      title: "Configurazione",
                      icon: Icons.settings_outlined,
                      isActive: _pageIndex == 1,
                      onTap: () => setState(() => _pageIndex = 1),
                    ),
                    _NavItem(
                      title: "Log Attività",
                      icon: Icons.history_outlined,
                      isActive: _pageIndex == 2,
                      onTap: () => setState(() => _pageIndex = 2),
                    ),
                    const Spacer(),
                    // Status Widget
                    _ConnectionStatus(
                      configured: appState.service.watchDirectory.isNotEmpty,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // 2. MAIN CONTENT AREA
              Expanded(
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getPageTitle(_pageIndex),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const Spacer(),
                          if (appState.isLoading)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "ELABORAZIONE...",
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Body
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _getPage(_pageIndex),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return "Terminale";
      case 1:
        return "Impostazioni Sistema";
      case 2:
        return "Storico Transazioni";
      default:
        return "";
    }
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const PosScreen();
      case 1:
        return const ConfigScreen();
      case 2:
        return const LogsScreen();
      default:
        return const SizedBox();
    }
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white54),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final bool configured;
  const _ConnectionStatus({required this.configured});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: configured ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (configured ? AppColors.success : AppColors.error)
                      .withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                configured ? "SISTEMA ONLINE" : "OFFLINE",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                configured ? "Pronto per I/O" : "Richiede Config.",
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- SCHERMATA POS (CORE UI) ---

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = SimpleStateProvider.of(context);

    // Using LayoutBuilder for responsive grid
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 3;
        if (constraints.maxWidth < 800) columns = 2;
        if (constraints.maxWidth < 500) columns = 1;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: ACTIONS GRID
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Operazioni",
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: columns,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _ActionCard(
                            title: "Nuovo Incasso",
                            subtitle: "Pagamento Standard",
                            icon: Icons.shopping_cart,
                            color: AppColors.accent,
                            onTap: () => _showSaleDialog(context, appState),
                          ),
                          _ActionCard(
                            title: "Prelievo",
                            subtitle: "Uscita Cassa",
                            icon: Icons.outbond,
                            color: AppColors.warning,
                            onTap: () => _showWithdrawDialog(context, appState),
                          ),
                          _ActionCard(
                            title: "Cambio",
                            subtitle: "Cambio Banconote",
                            icon: Icons.change_circle,
                            color: Colors.purple,
                            onTap: () => _confirmChange(context, appState),
                          ),
                          _ActionCard(
                            title: "Stato Cassa",
                            subtitle: "Livello Monete",
                            icon: Icons.inventory_2,
                            color: AppColors.success,
                            onTap: () =>
                                appState.runCommand(BSCommand.STOC, data: {}),
                          ),
                          _ActionCard(
                            title: "Storno / Annulla",
                            subtitle: "Annulla Ultimo",
                            icon: Icons.replay,
                            color: AppColors.error,
                            onTap: () => _showCancelDialog(context, appState),
                          ),
                          _ActionCard(
                            title: "STOP EMERGENZA",
                            subtitle: "Blocca Macchina",
                            icon: Icons.pan_tool,
                            color: AppColors.primary,
                            isDark: true,
                            onTap: () =>
                                appState.runCommand(BSCommand.ABRC, data: {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // RIGHT: DIGITAL RECEIPT / STATUS PANEL
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ultima Transazione",
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      // Local Listener to ensure receipt updates immediately
                      child: ListenableBuilder(
                        listenable: appState,
                        builder: (context, _) {
                          return _ReceiptPanel(result: appState.lastResult);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DIALOGS (Corrected Payloads) ---

  // 1. SALE (CHRG)
  void _showSaleDialog(BuildContext context, BSCASHCONTROLLER appState) {
    _showGenericNumpad(context, "Nuovo Incasso", (val) async {
      if (val > 0) {
        final payload = {
          "type": "receipt",
          "identifier": "DOC-${DateTime.now().millisecondsSinceEpoch}",
          "amount": appState.service.formatAmount(val),
          "date": DateTime.now().toIso8601String(),
          "cashRegister": "POS-01",
          "operator": "Admin",
          "payments": [
            {"type": "cash", "amount": appState.service.formatAmount(val)},
          ],
        };
        await appState.runCommand(BSCommand.CHRG, data: payload);
      }
    });
  }

  // 2. WITHDRAW (WTDW) - Corrected: {"amount": "...", "motivation": "..."}
  void _showWithdrawDialog(BuildContext context, BSCASHCONTROLLER appState) {
    _showGenericNumpad(context, "Importo Prelievo", (val) async {
      if (val > 0) {
        final payload = {
          "amount": appState.service.formatAmount(val),
          "motivation": "Uscita Cassa Manuale",
        };
        await appState.runCommand(BSCommand.WTDW, data: payload);
      }
    });
  }

// 3. CHANGE (CHNG) - Corrected: Must be empty object {} [cite: 278]
  void _confirmChange(BuildContext context, BSCASHCONTROLLER appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Avviare Cambio?"),
        content: const Text("La macchina accetterà banconote per cambiarle."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              appState.runCommand(BSCommand.CHNG, data: {});
              Navigator.pop(ctx);
            },
            child: const Text("AVVIA"),
          ),
        ],
      ),
    );
  }

  // 4. CANCEL (CANC)
  // FIXED: Logic now allows cancelling successful transactions
  void _showCancelDialog(BuildContext context, BSCASHCONTROLLER appState) {
    // Filter for transactions that are receipts (CHRG) and have identifiers
    final cancelableTransactions = appState.transactionHistory
        .where((t) =>
            t.isCompleted &&
            t.requestPayload != null &&
            t.requestPayload!.containsKey('type') &&
            t.requestPayload!['type'] == 'receipt' &&
            t.requestPayload!.containsKey('identifier'))
        .toList();

    if (cancelableTransactions.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Nessuna Transazione"),
          content: const Text(
            "Non ci sono transazioni recenti disponibili per l'annullamento.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;/*  */
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Storno / Annulla Transazione"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Seleziona la transazione da annullare:",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: cancelableTransactions.length,
                  itemBuilder: (context, index) {
                    final trans = cancelableTransactions[index];
                    final identifier =
                        trans.requestPayload!['identifier'] ?? 'N/A';
                    final amount = trans.requestPayload!['amount'] ?? '0.00';
                    final timestamp = trans.timestamp;

                    // Visual indicator: Green (Success) or Red (Failed)
                    final isSuccess = trans.success;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? AppColors.success : AppColors.error,
                      ),
                      title: Text(
                        identifier,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '€ $amount - ${DateFormat('HH:mm:ss').format(timestamp)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                      // [cite: 207-211] Cancel command uses same payload as CHRG
                        appState.addLog(
                          "Inviando CANC per annullare $identifier",
                          type: LogType.warning,
                        );

                        // We clone the original payload exactly
                        final cancellationPayload =
                            Map<String, dynamic>.from(trans.requestPayload!);

                        appState.runCommand(
                          BSCommand.CANC,
                          data: cancellationPayload,
                        );

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Richiesta annullamento inviata per $identifier"),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Chiudi"),
          ),
        ],
      ),
    );
  }

  // Helper Numpad Dialog
  void _showGenericNumpad(
    BuildContext context,
    String title,
    Function(double) onConfirm,
  ) {
    final ctrl = TextEditingController();
    bool isProcessing = false;
    bool wasCancelled = false;
    final appState = SimpleStateProvider.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Center(child: Text(title)),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    readOnly: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "0.00",
                      prefixText: "€ ",
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  VirtualNumpad(
                    controller: ctrl,
                    isLoading: isProcessing,
                    onCancel: () async {
                      wasCancelled = true;
                      // Request cancellation (deletes file and sets flag)
                      await appState.cancelCurrentTransaction();
                      
                      // Close dialog immediately - the transaction will complete in background
                      setState(() => isProcessing = false);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Richiesta annullamento inviata"),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    },
                    onConfirm: () async {
                      setState(() => isProcessing = true);
                      try {
                        final val = double.tryParse(ctrl.text);
                        if (val != null && val > 0) {
                          await onConfirm(val);
                        } else {
                          // If invalid value, show error and close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Inserisci un importo valido"),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          await Future.delayed(const Duration(seconds: 2));
                        }
                      } finally {
                        if (!wasCancelled) {
                          setState(() => isProcessing = false);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? color : Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : color,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : AppColors.textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPanel extends StatelessWidget {
  final TransactionResult? result;

  const _ReceiptPanel({this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Nessuna transazione recente",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final currency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final amount = result?.payload?['amount'] != null
        ? double.tryParse(result!.payload!['amount'].toString()) ?? 0.0
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Receipt Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: result!.success ? AppColors.success : AppColors.error,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result!.success ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result!.success ? "SUCCESSO" : "FALLITO",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(result!.timestamp),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Receipt Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (amount > 0) ...[
                    const Text(
                      "IMPORTO TOTALE",
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(amount),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                  ],
                  _buildDetailRow("Codice Stato", result!.statusRaw),
                  const SizedBox(height: 12),
                  _buildDetailRow("Messaggio", result!.message),
                  if (result!.payload != null &&
                      result!.payload!.containsKey('identifier'))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildDetailRow(
                        "Rif. ID",
                        result!.payload!['identifier'].toString(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSub)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// --- SCHERMATA CONFIGURAZIONE ---

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _watchCtrl = TextEditingController();
  final _writeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = SimpleStateProvider.of(context);
      _watchCtrl.text = state.service.watchDirectory;
      _writeCtrl.text = state.service.writeDirectory;
    });
  }

  Future<void> _pickFolder(TextEditingController ctrl) async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      setState(() => ctrl.text = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = SimpleStateProvider.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Percorsi di Integrazione",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Configura le cartelle condivise per comunicare con il servizio hardware Cashlogy.",
                style: TextStyle(color: AppColors.textSub),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildPathInput(
                        "Cartella Input (Comandi)",
                        "Dove vengono scritti i file di comando",
                        _watchCtrl,
                      ),
                      const SizedBox(height: 24),
                      _buildPathInput(
                        "Cartella Output (Risposte)",
                        "Dove attendiamo le risposte",
                        _writeCtrl,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("SALVA CONFIGURAZIONE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                  ),
                  onPressed: () {
                    appState.updatePaths(_watchCtrl.text, _writeCtrl.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Configurazione Salvata"),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathInput(
    String label,
    String hint,
    TextEditingController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.folder, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => _pickFolder(ctrl),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("SFOGLIA"),
            ),
          ],
        ),
      ],
    );
  }
}

// --- SCHERMATA LOGS ---

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = SimpleStateProvider.of(context);
    // Listen to logs updates locally
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Card(
          margin: const EdgeInsets.all(24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, color: AppColors.textSub),
                    const SizedBox(width: 12),
                    const Text(
                      "Eventi di Sistema",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text("${appState.logs.length} Record"),
                      backgroundColor: AppColors.background,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: appState.logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final log = appState.logs[i];
                    Color iconColor;
                    IconData iconData;
                    Color bgColor;

                    switch (log.type) {
                      case LogType.success:
                        iconColor = AppColors.success;
                        iconData = Icons.check;
                        bgColor = AppColors.success.withOpacity(0.1);
                        break;
                      case LogType.error:
                        iconColor = AppColors.error;
                        iconData = Icons.priority_high;
                        bgColor = AppColors.error.withOpacity(0.1);
                        break;
                      case LogType.warning:
                        iconColor = Colors.orange;
                        iconData = Icons.warning;
                        bgColor = Colors.orange.withOpacity(0.1);
                        break;
                      default:
                        iconColor = Colors.blue;
                        iconData = Icons.info;
                        bgColor = Colors.blue.withOpacity(0.1);
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: bgColor,
                        child: Icon(iconData, color: iconColor, size: 16),
                      ),
                      title: Text(
                        log.message,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        DateFormat('HH:mm:ss').format(log.timestamp),
                        style: const TextStyle(
                          fontFamily: 'Monospace',
                          fontSize: 12,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          log.type.name.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STORNO PAGAMENTO — funzione globale + modal
// Usa: BSCASHCONTROLLER, IntegrationService, BSCommand, TransactionResult
// ═══════════════════════════════════════════════════════════════════════════

void showStornoDialog(BuildContext context, BSCASHCONTROLLER ctrl) {
  // Filtra solo CHRG completate con identifier stornabile
  final stornabili = ctrl.transactionHistory
      .where((t) =>
          t.isCompleted &&
          t.requestPayload != null &&
          t.requestPayload!['type'] == 'receipt' &&
          t.requestPayload!.containsKey('identifier'))
      .toList();

  if (stornabili.isEmpty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.info_outline, color: AppColors.accent),
          SizedBox(width: 10),
          Text('Nessuna transazione'),
        ]),
        content: const Text(
          'Non ci sono transazioni recenti disponibili per lo storno.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _StornoDialog(transazioni: stornabili, ctrl: ctrl),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _StornoDialog extends StatefulWidget {
  final List<TransactionResult> transazioni;
  final BSCASHCONTROLLER ctrl;

  const _StornoDialog({required this.transazioni, required this.ctrl});

  @override
  State<_StornoDialog> createState() => _StornoDialogState();
}

class _StornoDialogState extends State<_StornoDialog> {
  TransactionResult? _selected;
  bool _isLoading = false;

  Future<void> _confermaStorno() async {
    if (_selected == null) return;

    final identifier = _selected!.requestPayload!['identifier'] ?? 'N/A';
    final importo    = _selected!.requestPayload!['amount']     ?? '0.00';

    // Dialog conferma
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Text('Conferma Storno'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stai per annullare la seguente transazione:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _rigaDettaglio('ID Transazione', identifier),
                  const SizedBox(height: 8),
                  _rigaDettaglio('Importo', '€ $importo'),
                  const SizedBox(height: 8),
                  _rigaDettaglio(
                    'Data',
                    DateFormat('dd/MM/yyyy HH:mm:ss').format(_selected!.timestamp),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Questa operazione è irreversibile.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('STORNA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (conferma != true || !mounted) return;

    setState(() => _isLoading = true);

    widget.ctrl.addLog(
      'Inviando CANC per annullare $identifier...',
      type: LogType.warning,
    );

    // CANC vuole lo stesso identico payload della CHRG originale
    final cancellationPayload =
        Map<String, dynamic>.from(_selected!.requestPayload!);

    await widget.ctrl.runCommand(BSCommand.CANC, data: cancellationPayload);

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Richiesta storno inviata per $identifier'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                    bottom:
                        BorderSide(color: AppColors.error.withOpacity(0.15))),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.replay,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storno Pagamento',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Seleziona la transazione da annullare',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
              ]),
            ),

            // ── Lista transazioni ────────────────────────────────────────
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.transazioni.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final t          = widget.transazioni[i];
                  final identifier = t.requestPayload!['identifier'] ?? 'N/A';
                  final importo    = t.requestPayload!['amount']     ?? '0.00';
                  final sel        = _selected == t;

                  return InkWell(
                    onTap: _isLoading ? null : () => setState(() => _selected = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      color: sel
                          ? AppColors.error.withOpacity(0.06)
                          : Colors.transparent,
                      child: Row(children: [

                        // Radio
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sel
                                  ? AppColors.error
                                  : Colors.grey.shade300,
                              width: sel ? 2 : 1.5,
                            ),
                            color: sel
                                ? AppColors.error.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: sel
                              ? const Center(
                                  child: Icon(Icons.circle,
                                      size: 10, color: AppColors.error))
                              : null,
                        ),
                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(identifier,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textMain)),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm:ss')
                                    .format(t.timestamp),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSub),
                              ),
                            ],
                          ),
                        ),

                        // Importo + badge stato
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€ $importo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: sel
                                      ? AppColors.error
                                      : AppColors.textMain),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.success
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t.success ? 'Completata' : 'Fallita',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: t.success
                                        ? AppColors.success
                                        : AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  border:
                      Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Chiudi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selected == null || _isLoading
                        ? null
                        : _confermaStorno,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.replay, size: 18),
                    label: Text(
                        _isLoading ? 'Elaborazione...' : 'STORNA TRANSAZIONE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == null
                          ? Colors.grey.shade300
                          : AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper riga dettaglio ─────────────────────────────────────────────────
Widget _rigaDettaglio(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textMain)),
    ],
  );
}
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// --- SECURITY FIX FOR SIMULATOR ---
class VneHTTPsOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// ============================================================================
// 2. DATA MODELS
// ============================================================================

enum LogType { info, success, error, warning, network }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  LogEntry(this.message, {this.type = LogType.info})
    : timestamp = DateTime.now();
}

class MachineLevels {
  final int totalRecycler;
  final Map<String, dynamic> recyclerDetails;

  MachineLevels({this.totalRecycler = 0, this.recyclerDetails = const {}});

  factory MachineLevels.fromJson(Map<String, dynamic> json) {
    // [Source 8, Source 284] Safe parsing for recycler data
    final recycler = json['recycler'];
    if (recycler is Map<String, dynamic>) {
      return MachineLevels(
        totalRecycler: recycler['totalInRecycle'] ?? 0,
        recyclerDetails: recycler,
      );
    }
    return MachineLevels();
  }
}

// ============================================================================
// 3. SERVICE LAYER (VNE PROTOCOL 3.04)
// ============================================================================

class VneService {
  final String ipAddress;
  final String opName;
  final http.Client _client;

  VneService(
    this.ipAddress, 
    {
      this.opName = "CASSA_01"
    })
    : _client = IOClient(
        HttpClient()..badCertificateCallback = ((cert, host, port) => true),
      );

  String get _baseUrl => "https://$ipAddress/selfcashapi/";

  /// [Source 12] "Nel caso in cui il client non riceva risposta... entro 5 secondi, è necessario inviare nuovamente"
  /// Implements retry logic for robustness.
  Future<Map<String, dynamic>> _send(
    Map<String, dynamic> body, {
    int attempts = 3,
  }) async {
    int currentAttempt = 0;
    while (currentAttempt < attempts) {
      try {
        final response = await _client
            .post(
              Uri.parse(_baseUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 5)); // [Source 12] 5s timeout

        print(response.body);
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception("HTTP ${response.statusCode}");
        }
      } catch (e) {
        currentAttempt++;
        if (currentAttempt >= attempts) {
          throw Exception("Errore Connessione dopo $attempts tentativi: $e");
        }
        // Small delay before retry to let socket clear
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception("Errore Sconosciuto");
  }

  // --- COMMANDS ---

  // [Source 53] Type 1: Payment Request
  Future<Map<String, dynamic>> startPayment(int amountCents) async {
    return _send({
      "tipo": 1,
      "importo": amountCents,
      "opName": opName, // [Source 61] Auto-login
      "refundable": 1,
    });
  }

  // [Source 90] Type 2: Polling Payment
  Future<Map<String, dynamic>> pollPayment(String id) async {
    return _send({"tipo": 2, "id": id, "opName": opName});
  }

  // [Source 146] Type 3: Cancel Payment
  Future<Map<String, dynamic>> cancelPayment(String id) async {
    return _send({
      "tipo": 3,
      "id": id,
      "tipo_annullamento": 2, // 2 = Return inserted money [Source 166]
      "opName": opName,
    });
  }

  // [Source 278] Type 20: Status
  Future<Map<String, dynamic>> getStatus() async {
    return _send({"tipo": 20, "opName": opName});
  }

  // [Source 206] Type 10: Withdrawal
  Future<Map<String, dynamic>> startWithdrawal(int amountCents) async {
    return _send({
      "tipo": 10,
      "importo": amountCents,
      "opName": opName,
      "taglio": "all",
    });
  }

  // [Source 239] Type 11: Poll Withdrawal
  Future<Map<String, dynamic>> pollWithdrawal(String id) async {
    return _send({"tipo": 11, "id": id, "opName": opName});
  }

  // [Source 264] Type 12: End Withdrawal
  Future<Map<String, dynamic>> endWithdrawal() async {
    return _send({"tipo": 12, "opName": opName});
  }

  // [Source 641] Type 60: Close Cash (Z-Report)
  Future<Map<String, dynamic>> closeCash() async {
    return _send({"tipo": 60, "opName": opName});
  }

  // [Source 683] Type 65: Refund
  Future<Map<String, dynamic>> startRefund(String id) async {
    return _send({"tipo": 65, "id": id, "opName": opName});
  }

  // [Source 703] Type 66: Poll Refund
  Future<Map<String, dynamic>> pollRefund(String id) async {
    return _send({"tipo": 66, "id": id});
  }
}

// ============================================================================
// 4. STATE MANAGEMENT
// ============================================================================

class VnePosState extends ChangeNotifier {
  late String machineIp;
  bool isMachineOnline = false;
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;
  String _inputBuffer = "0";
  double get currentAmount => double.tryParse(_inputBuffer) ?? 0.0;

  // Authentication State
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Transaction State
  String? activeTxId;
  String txStatus = "IDLE";
  double amountPaid = 0.0;
  double amountRest = 0.0;
  String txErrorMessage = "";

  // Withdrawal State
  String? activeWithdrawalId;
  String withdrawalStatus = "IDLE";
  double withdrawalAmount = 0.0;
  String withdrawalErrorMessage = "";

  MachineLevels? machineStatus;
  final List<LogEntry> logs = [];
  bool _isPolling = false; // Flag to control recursive polling

  VnePosState() {
    // machineIp = _prefs.getString('vne_ip') ?? "172.17.107.113";
    // addLog("Sistema avviato. IP Target: $machineIp", type: LogType.info);
    // machineIp = "103.61.185.146:28565";
    machineIp = "127.0.0.1";

    _checkConnectivity();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  void setTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void updateIp(String ip) {
    // machineIp = ip;
    machineIp = "127.0.0.1";
    addLog("Configurazione aggiornata. Nuovo IP: $ip", type: LogType.warning);
    _checkConnectivity();
    notifyListeners();
  }

  void keypadInput(String val) {
    if (val == "C") {
      _inputBuffer = "0";
    } else if (val == "DEL") {
      if (_inputBuffer.length > 1) {
        _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
      } else {
        _inputBuffer = "0";
      }
    } else if (val == ".") {
      if (!_inputBuffer.contains(".")) _inputBuffer += ".";
    } else {
      if (_inputBuffer == "0") {
        _inputBuffer = val;
      } else {
        if (_inputBuffer.contains(".")) {
          if (_inputBuffer.split(".")[1].length >= 2) return;
        }
        _inputBuffer += val;
      }
    }
    notifyListeners();
  }

  void addAmount(double amount) {
    double current = double.tryParse(_inputBuffer) ?? 0.0;
    _inputBuffer = (current + amount).toStringAsFixed(2);
    notifyListeners();
  }

  void addLog(String msg, {LogType type = LogType.info}) {
    logs.insert(0, LogEntry(msg, type: type));
    if (logs.length > 100) logs.removeLast();
    notifyListeners();
  }

  Future<void> _checkConnectivity() async {
    try {
      final service = VneService("127.0.0.1"); // or machineIp
      final res = await service.getStatus();
      if (res['tipo'] != -1) {
        isMachineOnline = true;
        machineStatus = MachineLevels.fromJson(res);
        addLog("Macchina Connessa (HTTPS)", type: LogType.success);
      }
    } catch (e) {
      isMachineOnline = false;
      addLog("Macchina Offline: $e", type: LogType.error);
    }
    notifyListeners();
  }

  Future<void> refreshStatus() async => await _checkConnectivity();

  Future<bool> startTransaction() async {
    if (currentAmount <= 0) return false;

    final service = VneService(machineIp);
    // [Source 59] Importo in forma centesimale
    int cents = (currentAmount * 100).round();

    txStatus = "INIT";
    amountPaid = 0;
    amountRest = 0;
    notifyListeners();

    try {
      addLog(
        "Richiesta pagamento: €${currentAmount.toStringAsFixed(2)}",
        type: LogType.network,
      );
      final res = await service.startPayment(cents);

      // [Source 80] req_status 1 = ACK
      if (res['req_status'] == 1) {
        activeTxId = res['id'];
        txStatus = "PENDING";
        addLog("Transazione creata ID: $activeTxId", type: LogType.success);

        // Start Polling Loop
        _isPolling = true;
        _pollLoop(service, isRefund: false);
        return true;
      } else {
        txStatus = "ERROR";
        // [Source 85] Handle NACK messages
        txErrorMessage = "Errore Codice ${res['mess'] ?? 'Sconosciuto'}";
        addLog("NACK Pagamento: ${res['mess']}", type: LogType.error);
        notifyListeners();
        return false;
      }
    } catch (e) {
      txStatus = "ERROR";
      txErrorMessage = e.toString();
      addLog("Fallimento Transazione: $e", type: LogType.error);
      notifyListeners();
      return false;
    }
  }

  Future<void> startRefundFlow(String txId) async {
    final service = VneService(machineIp);
    addLog("Avvio Rimborso per ID: $txId", type: LogType.warning);

    String targetId = txId.isEmpty ? (activeTxId ?? "0") : txId;

    try {
      final res = await service.startRefund(targetId);
      if (res['req_status'] == 1) {
        activeTxId = targetId;
        txStatus = "REFUNDING";
        addLog("Rimborso avviato...", type: LogType.success);
        _isPolling = true;
        _pollLoop(service, isRefund: true);
      } else {
        addLog(
          "Errore avvio rimborso: Codice ${res['mess']}",
          type: LogType.error,
        );
      }
    } catch (e) {
      addLog("Errore Rimborso: $e", type: LogType.error);
    }
  }

  // Recursive polling pattern to prevent overlapping requests
  void _pollLoop(VneService service, {required bool isRefund}) async {
    if (!_isPolling || activeTxId == null) return;

    try {
      if (isRefund) {
        // [Source 703] Polling Rimborso
        final res = await service.pollRefund(activeTxId!);
        if (res['req_status'] == 1) {
          String status = res['refund_status'] ?? "";
          if (status == "completed") {
            _isPolling = false;
            txStatus = "COMPLETED";
            addLog(
              "Rimborso Completato. Restituito: €${(res['refunded'] ?? 0) / 100}",
              type: LogType.success,
            );
          }
        }
      } else {
        // [Source 90] Polling Pagamento
        final res = await service.pollPayment(activeTxId!);

        if (res['req_status'] == 1) {
          if (res['payment_details'] != null) {
            // [Source 112] Parse Payment Details
            int insertedCents = res['payment_details']['inserted'] ?? 0;

            // [Source 135] "nel caso si sia scelto di effettuare il pagamento con carta di credito/debito... inserted prenderà il valore -2"
            if (insertedCents == -2) {
              amountPaid = currentAmount; // Visual fix for POS
            } else {
              amountPaid = insertedCents / 100.0;
            }
            amountRest = (res['payment_details']['rest'] ?? 0) / 100.0;
            notifyListeners();
          }

          // [Source 108] payment_status: 1 = Completed
          int pStatus = res['payment_status'];
          if (pStatus == 1) {
            _isPolling = false;
            txStatus = "COMPLETED";
            _inputBuffer = "0";
            addLog(
              "Pagamento Completato. Resto: €${amountRest.toStringAsFixed(2)}",
              type: LogType.success,
            );
            refreshStatus();
          }
        }
      }
    } catch (e) {
      // Log connection glitches but keep polling
      print("Polling error: $e");
    }

    if (_isPolling) {
      // [Source 110] "attendere un breve intervallo di tempo (ad esempio 1 secondo)"
      await Future.delayed(const Duration(seconds: 1));
      _pollLoop(service, isRefund: isRefund);
    }
  }

  Future<void> cancelTransaction() async {
    if (activeTxId == null) return;
    try {
      addLog("Invio Annullamento...", type: LogType.warning);
      final service = VneService(machineIp);
      await service.cancelPayment(activeTxId!);
      // Note: We don't stop polling here; polling will detect the 'returned' or 'deleted' status eventually.
    } catch (e) {
      addLog("Annullamento fallito: $e", type: LogType.error);
    }
  }

  Future<bool> startWithdrawalTransaction(double amount) async {
    final service = VneService(machineIp);
    int cents = (amount * 100).round();

    withdrawalStatus = "INIT";
    withdrawalAmount = amount;
    withdrawalErrorMessage = "";
    notifyListeners();

    addLog(
      "Richiesta prelievo: €${amount.toStringAsFixed(2)}",
      type: LogType.network,
    );

    try {
      final res = await service.startWithdrawal(cents);
      if (res['req_status'] == 1) {
        activeWithdrawalId = res['id'];
        withdrawalStatus = "PENDING";
        addLog("Prelievo creato ID: $activeWithdrawalId", type: LogType.success);
        
        // Start polling for withdrawal
        _isPolling = true;
        _pollWithdrawalLoop(service);
        return true;
      } else {
        withdrawalStatus = "ERROR";
        withdrawalErrorMessage = "Errore Codice ${res['mess'] ?? 'Sconosciuto'}";
        addLog("NACK Prelievo: ${res['mess']}", type: LogType.error);
        notifyListeners();
        return false;
      }
    } catch (e) {
      withdrawalStatus = "ERROR";
      withdrawalErrorMessage = e.toString();
      addLog("Fallimento Prelievo: $e", type: LogType.error);
      notifyListeners();
      return false;
    }
  }

  void _pollWithdrawalLoop(VneService service) async {
    if (!_isPolling || activeWithdrawalId == null) return;

    try {
      final poll = await service.pollWithdrawal(activeWithdrawalId!);
      if (poll['req_status'] == 1) {
        // [Source 254] withdraw_status: 1 = Effettuato
        int wStatus = poll['withdraw_status'] ?? 0;
        if (wStatus == 1) {
          // Withdrawal completed
          await service.endWithdrawal();
          withdrawalStatus = "COMPLETED";
          LogService.instance().saveLog('Prelievo cassa','Prelevati ${withdrawalAmount.toStringAsFixed(2)}','');
          addLog(
            "Prelievo Completato: €${withdrawalAmount.toStringAsFixed(2)}",
            type: LogType.success,
          );
          _isPolling = false;
          refreshStatus();
          notifyListeners();
          return;
        } else if (wStatus == -1) {
          // Error during dispensing
          withdrawalStatus = "ERROR";
          withdrawalErrorMessage = poll['mess'] ?? "Errore interno durante l'erogazione.";
          addLog("Errore Prelievo: $withdrawalErrorMessage", type: LogType.error);
          _isPolling = false;
          notifyListeners();
          return;
        }
      } else {
        // req_status != 1 (NACK or connection lost)
        withdrawalStatus = "ERROR";
        withdrawalErrorMessage = "La macchina ha interrotto l'operazione.";
        _isPolling = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      print("Polling withdrawal error: $e");
    }

    if (_isPolling) {
      await Future.delayed(const Duration(seconds: 1));
      _pollWithdrawalLoop(service);
    }
  }

  // Legacy method for backward compatibility
  Future<void> performWithdrawal(double amount) async {
    await startWithdrawalTransaction(amount);
  }

  Future<void> closeDay() async {
    final service = VneService(machineIp);
    addLog("Chiusura Cassa (Z-Report)...", type: LogType.warning);
    try {
      final res = await service.closeCash();
      if (res['req_status'] == 1) {
        double totalIn = (res['total_in'] ?? 0) / 100.0;
        double totalOut = (res['total_out'] ?? 0) / 100.0;
        addLog(
          "Chiusura OK. Entrate: €$totalIn, Uscite: €$totalOut",
          type: LogType.success,
        );
      } else {
        addLog("Errore Chiusura.", type: LogType.error);
      }
    } catch (e) {
      addLog("Eccezione Chiusura: $e", type: LogType.error);
    }
  }

  // Authentication methods
  Future<void> login() async {
    addLog("Tentativo di connessione alla macchina VNE...");
    try {
      // For VNE, we just check if the machine is online
      await _checkConnectivity();
      if (isMachineOnline) {
        _isAuthenticated = true;
        addLog(
          "Connessione riuscita. Accesso al POS abilitato.",
          type: LogType.success,
        );
      } else {
        addLog(
          "Impossibile connettersi alla macchina. Verifica IP e connessione.",
          type: LogType.error,
        );
      }
    } catch (e) {
      addLog("Errore durante la connessione: $e", type: LogType.error);
    }
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    addLog("Disconnessione dal sistema VNE.", type: LogType.warning);
    notifyListeners();
  }

  void resetTxState() {
    _isPolling = false;
    activeTxId = null;
    txStatus = "IDLE";
    amountPaid = 0;
    amountRest = 0;
    txErrorMessage = "";
    notifyListeners();
  }

  void resetWithdrawalState() {
    _isPolling = false;
    activeWithdrawalId = null;
    withdrawalStatus = "IDLE";
    withdrawalAmount = 0;
    withdrawalErrorMessage = "";
    notifyListeners();
  }

  Future<void> openWebTool() async {
    String urlStr = machineIp;
    if (!urlStr.startsWith('http')) {
      urlStr = 'https://$urlStr';
    }
    
    // Ensure the tool path is appended correctly
    if (!urlStr.contains('/tool')) {
      if (!urlStr.endsWith('/')) {
        urlStr = '$urlStr/tool';
      } else {
        urlStr = '${urlStr}tool';
      }
    }

    final Uri url = Uri.parse(urlStr);
    addLog("Apertura Tool Web: $urlStr", type: LogType.info);
    
    try {
      // 1. Try standard url_launcher
      bool launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      
      if (!launched) {
        // 2. Windows-Specific Fallback using dart:io
        if (Platform.isWindows) {
          addLog("Fallback Windows: avvio tramite shell...", type: LogType.warning);
          await Process.run('start', [urlStr], runInShell: true);
        } else {
          addLog("Impossibile aprire il browser per: $urlStr", type: LogType.error);
        }
      }
    } catch (e) {
      // 3. Last resort fallback for PlatformExceptions
      if (Platform.isWindows) {
        addLog("Errore plugin, uso fallback Windows...", type: LogType.warning);
        try {
          await Process.run('start', [urlStr], runInShell: true);
        } catch (innerE) {
          addLog("Errore fatale: $innerE", type: LogType.error);
        }
      } else {
        addLog("Errore apertura browser: $e", type: LogType.error);
      }
    }
  }
}

// ============================================================================
// 5. LAYOUT UI
// ============================================================================

class VneHttpProtocolPage extends StatelessWidget {
  const VneHttpProtocolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<VnePosState>().isAuthenticated;
    return isAuthenticated ? const MainLayout() : VneLoginScreen();
  }
}

class VneLoginScreen extends StatefulWidget {
  const VneLoginScreen({super.key});

  @override
  State<VneLoginScreen> createState() => _VneLoginScreenState();
}

class _VneLoginScreenState extends State<VneLoginScreen> {
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    await context.read<VnePosState>().login();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: Center(
        child: Card(
          elevation: 12,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    size: 64,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "SDS Italia POS",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const Text("Sistema VNE - Connessione Automatica"),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: state.isMachineOnline
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.isMachineOnline ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isMachineOnline ? Icons.wifi : Icons.wifi_off,
                        color: state.isMachineOnline
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.isMachineOnline
                              ? "Macchina VNE rilevata e pronta"
                              : "Macchina VNE non raggiungibile",
                          style: TextStyle(
                            color: state.isMachineOnline
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("CONNETTI AL POS"),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "IP Target: ${state.machineIp}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: state.selectedTab,
            onDestinationSelected: state.setTab,
            backgroundColor: Colors.white,
            elevation: 5,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Icon(
                Icons.point_of_sale,
                size: 40,
                color: Color(0xFF1976D2),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Vendita'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: Text('Prelievo'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings),
                label: Text('Admin'),
              ),
            ],
          ),
          Expanded(
            flex: 6,
            child: IndexedStack(
              index: state.selectedTab,
              children: const [
                SalesScreen(),
                WithdrawalScreen(),
                AdminScreen(),
              ],
            ),
          ),
          const Expanded(flex: 3, child: StatusSidebar()),
        ],
      ),
    );
  }
}

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Vendita",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              _ConnectionChip(online: state.isMachineOnline),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "DA INCASSARE",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "€ ${state.currentAmount.toStringAsFixed(2)}",
                                style: Theme.of(context).textTheme.displayLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            return GridView.count(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.5,
                              children: [
                                ...[
                                  "1",
                                  "2",
                                  "3",
                                  "4",
                                  "5",
                                  "6",
                                  "7",
                                  "8",
                                  "9",
                                  "C",
                                  "0",
                                  ".",
                                ].map((k) {
                                  bool isAction = k == "C";
                                  return Material(
                                    color: isAction
                                        ? Colors.red.shade50
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    elevation: 1,
                                    child: InkWell(
                                      onTap: () => state.keypadInput(k),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Center(
                                        child: Text(
                                          k,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: isAction
                                                ? Colors.red
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 1,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3.5,
                          children: [
                            _QuickAddBtn(
                              amount: 5,
                              onTap: () => state.addAmount(5),
                            ),
                            _QuickAddBtn(
                              amount: 10,
                              onTap: () => state.addAmount(10),
                            ),
                            _QuickAddBtn(
                              amount: 20,
                              onTap: () => state.addAmount(20),
                            ),
                            _QuickAddBtn(
                              amount: 50,
                              onTap: () => state.addAmount(50),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed:
                              state.isMachineOnline && state.currentAmount > 0
                              ? () => _showPaymentDialog(context)
                              : null,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payments, size: 28),
                              SizedBox(height: 4),
                              Text(
                                "PAGA / INCASSA",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    context.read<VnePosState>().startTransaction();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PaymentDialog(),
    ).then((_) {
      if (context.mounted) context.read<VnePosState>().resetTxState();
    });
  }
}

class _QuickAddBtn extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;
  const _QuickAddBtn({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        "+ €$amount",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class WithdrawalScreen extends StatelessWidget {
  const WithdrawalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();
    final presets = [5.0, 10.0, 20.0, 50.0, 100.0, 200.0];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Prelievo Operatore",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text("Seleziona l'importo da erogare dalla cassa."),
          const SizedBox(height: 24),
          // Custom Amount Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.blue),
                const SizedBox(width: 16),
                const Text(
                  "Importo Libero:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "0.00",
                      suffixText: "€",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      double? amount = double.tryParse(val);
                      if (amount != null && amount > 0) {
                        _showWithdrawalDialog(context, amount);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final amount = presets[index];
                return Card(
                  child: InkWell(
                    onTap: state.isMachineOnline
                        ? () => _showWithdrawalDialog(context, amount)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.outbond,
                            size: 28,
                            color: Color(0xFF0EA5E9),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "€ ${amount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
  }

  void _showWithdrawalDialog(BuildContext context, double amount) {
    context.read<VnePosState>().startWithdrawalTransaction(amount);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const WithdrawalDialog(),
    ).then((_) {
      if (context.mounted) context.read<VnePosState>().resetWithdrawalState();
    });
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();
    final refundCtrl = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Amministrazione",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _AdminBtn(
                  icon: Icons.receipt_long,
                  label: "Chiusura Giornaliera (Z)",
                  color: Colors.orange,
                  onTap: state.isMachineOnline ? () => state.closeDay() : null,
                ),
                _AdminBtn(
                  icon: Icons.sync,
                  label: "Aggiorna Stato",
                  color: Colors.blue,
                  onTap: () => state.refreshStatus(),
                ),
                _AdminBtn(
                  icon: Icons.settings_ethernet,
                  label: "Configura IP",
                  color: Colors.grey,
                  onTap: () => _showIpDialog(context),
                ),
                _AdminBtn(
                  icon: Icons.open_in_browser,
                  label: "Tool Web VNE",
                  color: Colors.purple,
                  onTap: () => state.openWebTool(),
                ),
              ],
            ),
          ),
          const Divider(),
          const Text(
            "Rimborso Manuale",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: refundCtrl,
                  decoration: const InputDecoration(
                    labelText: "ID Transazione (lasciare vuoto per ultima)",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: state.isMachineOnline
                    ? () {
                        state.startRefundFlow(refundCtrl.text);
                      }
                    : null,
                icon: const Icon(Icons.replay),
                label: const Text("Esegui Rimborso"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const Text(
            "Dettagli Periferiche",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.machineStatus == null
                ? const Center(child: Text("Nessun Dato"))
                : ListView(
                    children: [
                      // Dynamically build list based on available keys
                      ...state.machineStatus!.recyclerDetails.entries
                          .where((e) =>
                              (e.key.startsWith('banconota_') ||
                                  e.key.startsWith('moneta_')) &&
                              e.value is Map)
                          .map((e) {
                        String name = e.key
                            .replaceAll('_', ' ')
                            .replaceAll('banconota', 'Cassetto Banconote')
                            .replaceAll('moneta', 'Cassetto Monete');
                        // Capitalize
                        name = name[0].toUpperCase() + name.substring(1);

                        return _PeripheralTile(
                          name: name,
                          data: e.value as Map<String, dynamic>,
                        );
                      }),
                      const Divider(),
                      ListTile(
                        title: const Text("Totale in Riciclo"),
                        trailing: Text(
                          "€ ${(state.machineStatus!.totalRecycler / 100).toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        tileColor: Colors.white,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showIpDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: context.read<VnePosState>().machineIp,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("IP Macchina VNE"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<VnePosState>().updateIp(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }
}

class _AdminBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _AdminBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: Colors.grey.shade300),
        alignment: Alignment.centerLeft,
      ),
      onPressed: onTap,
    );
  }
}

class _PeripheralTile extends StatelessWidget {
  final String name;
  final Map<String, dynamic> data;
  const _PeripheralTile({required this.name, required this.data});

  @override
  Widget build(BuildContext context) {
    int qty = data['quantita'] ?? 0;
    int val = data['valore'] ?? 0;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.savings_outlined),
        title: Text(name),
        subtitle: Text("Taglio: € ${(val / 100).toStringAsFixed(2)}"),
        trailing: Chip(label: Text("$qty pz")),
      ),
    );
  }
}

class PaymentDialog extends StatelessWidget {
  const PaymentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusIndicator(status: state.txStatus),
            const SizedBox(height: 24),
            Text(
              state.txStatus == "PENDING" ? "Inserire Denaro" : state.txStatus,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _MoneyRow(label: "Totale Dovuto", amount: state.currentAmount),
            const Divider(),
            _MoneyRow(
              label: "Inserito",
              amount: state.amountPaid,
              color: Colors.green,
            ),
            _MoneyRow(
              label: "Rimanente",
              amount: state.currentAmount - state.amountPaid,
              color: Colors.red,
            ),
            if (state.amountRest > 0)
              _MoneyRow(
                label: "Resto Erogato",
                amount: state.amountRest,
                color: Colors.orange,
              ),
            const SizedBox(height: 40),
            if (state.txStatus == "PENDING")
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => state.cancelTransaction(),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("ANNULLA TRANSAZIONE"),
                ),
              ),
            if (state.txStatus == "COMPLETED" || state.txStatus == "ERROR")
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CHIUDI"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WithdrawalDialog extends StatelessWidget {
  const WithdrawalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    // Auto-close on completion or error with delay
    if (state.withdrawalStatus == "COMPLETED" || state.withdrawalStatus == "ERROR") {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          // Show success/failure snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.withdrawalStatus == "COMPLETED"
                        ? Icons.check_circle
                        : Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.withdrawalStatus == "COMPLETED"
                          ? "Prelievo completato con successo!"
                          : "Errore durante il prelievo: ${state.withdrawalErrorMessage}",
                    ),
                  ),
                ],
              ),
              backgroundColor: state.withdrawalStatus == "COMPLETED"
                  ? Colors.green
                  : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusIndicator(status: state.withdrawalStatus),
            const SizedBox(height: 24),
            Text(
              _getStatusText(state.withdrawalStatus),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _MoneyRow(
              label: "Importo Richiesto",
              amount: state.withdrawalAmount,
              color: const Color(0xFF0EA5E9),
            ),
            if (state.withdrawalStatus == "ERROR" && 
                state.withdrawalErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.withdrawalErrorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
            if (state.withdrawalStatus == "PENDING")
              const Text(
                "Attendere l'erogazione del contante...",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            if (state.withdrawalStatus == "COMPLETED" || 
                state.withdrawalStatus == "ERROR")
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.withdrawalStatus == "COMPLETED"
                        ? Colors.green
                        : Colors.red,
                  ),
                  child: Text(
                    state.withdrawalStatus == "COMPLETED"
                        ? "COMPLETATO"
                        : "CHIUDI",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case "INIT":
        return "Inizializzazione...";
      case "PENDING":
        return "Erogazione in Corso";
      case "COMPLETED":
        return "Prelievo Completato!";
      case "ERROR":
        return "Errore Prelievo";
      default:
        return "In Attesa";
    }
  }
}

class StatusSidebar extends StatelessWidget {
  const StatusSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            width: double.infinity,
            child: const Text(
              "Log Sistema",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (ctx, i) {
                final log = state.logs[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(log.timestamp),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: log.type == LogType.error
                              ? Colors.red
                              : Colors.black87,
                          fontWeight: log.type == LogType.network
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "VNE Protocol 3.04",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  "IP: ${state.machineIp}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final bool online;
  const _ConnectionChip({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: online ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: online ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: online ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            online ? "ONLINE" : "DISCONNESSO",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: online ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;
  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case "PENDING":
        return const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(strokeWidth: 5),
        );
      case "COMPLETED":
        return const Icon(Icons.check_circle, color: Colors.green, size: 80);
      case "ERROR":
        return const Icon(Icons.error, color: Colors.red, size: 80);
      default:
        return const SizedBox(width: 60, height: 60);
    }
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _MoneyRow({
    required this.label,
    required this.amount,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            "€ ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VNE PAYMENT — setState diretto, nessun ChangeNotifier
// Logica identica a VnePosState del protocollo v3.04
// ═══════════════════════════════════════════════════════════════════════════

class VnePaymentResult {
  final bool    success;
  final double  amountPaid;
  final double  changeDispensed;
  final double  changeNotDispensed;
  final bool    wasCancelled;
  final bool    wasCardPayment;
  final String? errorMessage;

  const VnePaymentResult({
    required this.success,
    this.amountPaid         = 0,
    this.changeDispensed    = 0,
    this.changeNotDispensed = 0,
    this.wasCancelled       = false,
    this.wasCardPayment     = false,
    this.errorMessage,
  });
}

Future<VnePaymentResult> showVnePaymentDialog(
  BuildContext context, {
  required double amountEuro,
  required String ipMacchina,
  String          opName = 'CASSA01',
}) async {
  final result = await showDialog<VnePaymentResult>(
    context:            context,
    barrierDismissible: false,
    builder: (_) => _VnePaymentDialog(
      amountCents: (amountEuro * 100).round(),
      ip:          ipMacchina,
      opName:      opName,
    ),
  );
  return result ?? const VnePaymentResult(success: false, wasCancelled: true);
}

// ─────────────────────────────────────────────────────────────────────────────

class _VnePaymentDialog extends StatefulWidget {
  final int    amountCents;
  final String ip;
  final String opName;

  const _VnePaymentDialog({
    required this.amountCents,
    required this.ip,
    required this.opName,
  });

  @override
  State<_VnePaymentDialog> createState() => _VnePaymentDialogState();
}

class _VnePaymentDialogState extends State<_VnePaymentDialog> {

  late final VneService _service;

  // ── Stato — identico ai campi di VnePosState ─────────────────────────
  String  _txStatus    = 'INIT';
  String? _activeTxId;
  double  _amountPaid  = 0.0;
  double  _amountRest  = 0.0;
  bool    _isPolling   = false;
  bool    _isCard      = false;
  String  _errorMsg    = '';

  double get _amountToPay        => widget.amountCents / 100.0;
  double get _remaining          => (_amountToPay - _amountPaid).clamp(0.0, double.infinity);
  double get _progress           => _amountToPay > 0 ? (_amountPaid / _amountToPay).clamp(0.0, 1.0) : 0.0;
  double get _changeNotDispensed {
    if (_isCard) return 0;
    final expected = (_amountPaid - _amountToPay).clamp(0.0, double.infinity);
    final missing  = expected - _amountRest;
    return missing > 0 ? missing : 0;
  }

  @override
  void initState() {
    super.initState();
    _service = VneService(widget.ip,opName: widget.opName);
    _startTransaction();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  // ── 1. Start — identico a startTransaction() ─────────────────────────
Future<void> _startTransaction() async {
  if (!mounted) return;
  setState(() { _txStatus = 'INIT'; _amountPaid = 0; _amountRest = 0; _errorMsg = ''; });

  try {
    final res = await _service.startPayment(widget.amountCents);
    if (!mounted) return;

    // ← CHIAVE CORRETTA: req_status (con underscore)
    if (res['req_status'] == 1) {
      _activeTxId = res['id']?.toString();
      _isPolling  = true;
      setState(() => _txStatus = 'PENDING');
      _pollLoop();
    } else {
      setState(() {
        _txStatus = 'ERROR';
        _errorMsg = res['mess']?.toString() ?? 'Errore avvio';
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() { _txStatus = 'ERROR'; _errorMsg = e.toString(); });
  }
}

Future<void> _pollLoop() async {
  if (!_isPolling || _activeTxId == null || !mounted) return;

  try {
    final res = await _service.pollPayment(_activeTxId!);
    if (!mounted) return;

    // ← CHIAVE CORRETTA: req_status (con underscore)
    if (res['req_status'] == 1) {

      // ← CHIAVE CORRETTA: payment_details (con underscore)
      if (res['payment_details'] != null) {

        final int inserted = res['payment_details']['inserted'] ?? 0;
        final int rest     = res['payment_details']['rest']     ?? 0;

        // inserted == -2 → carta di credito/debito
        setState(() {
          if (inserted == -2) {
            _isCard     = true;
            _amountPaid = _amountToPay;
          } else {
            _isCard     = false;
            _amountPaid = inserted / 100.0;
          }
          _amountRest = rest / 100.0;
        });

        // ← CHIAVE CORRETTA: payment_status (con underscore)
        final int pStatus = res['payment_status'] ?? 0;
        if (pStatus == 1) {
          _isPolling = false;
          setState(() => _txStatus = 'COMPLETED');
          if (_changeNotDispensed == 0) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _chiudi(success: true);
            });
          }
          return;
        }
      }
    }
    // NACK temporaneo → continua polling (identico al protocollo)
  } catch (e) {
    debugPrint('VNE poll (continuo): $e');
  }

  await Future.delayed(const Duration(seconds: 1));
  _pollLoop();
}

  // ── 3. Annulla ────────────────────────────────────────────────────────
  Future<void> _annulla() async {
    if (_activeTxId == null) return;
    _isPolling = false;
    setState(() => _txStatus = 'CANCELLING');
    try {
      await _service.cancelPayment(_activeTxId!);
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop(
          const VnePaymentResult(success: false, wasCancelled: true));
    }
  }

  void _chiudi({required bool success}) {
    if (!mounted) return;
    Navigator.of(context).pop(VnePaymentResult(
      success:            success,
      amountPaid:         _amountToPay,
      changeDispensed:    _amountRest,
      changeNotDispensed: _changeNotDispensed,
      wasCancelled:       !success && _txStatus != 'ERROR',
      wasCardPayment:     _isCard,
      errorMessage:       _errorMsg.isEmpty ? null : _errorMsg,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isPending    = _txStatus == 'PENDING';
    final bool isCompleted  = _txStatus == 'COMPLETED';
    final bool isError      = _txStatus == 'ERROR';
    final bool isCancelling = _txStatus == 'CANCELLING';
    final bool isInit       = _txStatus == 'INIT';
    final bool hasWarning   = isCompleted && _changeNotDispensed > 0;

    final Color themeColor = isCompleted
        ? (hasWarning ? Colors.orange.shade700 : Colors.green.shade600)
        : isError
            ? Colors.red.shade600
            : isCancelling
                ? Colors.grey.shade600
                : const Color(0xFF0EA5E9);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── HEADER ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                    bottom:
                        BorderSide(color: themeColor.withOpacity(0.15))),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.13),
                      shape: BoxShape.circle),
                  child: Icon(_headerIcon(isCompleted, isError, hasWarning),
                      color: themeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headerTitle(isCompleted, isError,
                            isCancelling, isInit, hasWarning),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _headerSub(isCompleted, isError,
                            isCancelling, isInit),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (_isCard && isCompleted) _cardBadge(),
              ]),
            ),

            // ── BODY ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(children: [

                // Totale dovuto
                _moneyRow('Totale dovuto', _amountToPay,
                    const Color(0xFF0F172A), 17),
                Divider(height: 20, color: Colors.grey.shade100),

                // Inserito — si aggiorna live
                _moneyRow(
                  'Inserito',
                  _amountPaid,
                  _amountPaid == 0
                      ? Colors.grey.shade400
                      : _amountPaid >= _amountToPay
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                  22,
                  bold: true,
                ),

                // Rimanente
                if (isPending && _remaining > 0) ...[
                  Divider(height: 20, color: Colors.grey.shade100),
                  _moneyRow('Rimanente', _remaining,
                      Colors.red.shade400, 15),
                ],

                // Resto erogato
                if (isCompleted && _amountRest > 0) ...[
                  Divider(height: 20, color: Colors.grey.shade100),
                  _moneyRow(
                    'Resto erogato',
                    _amountRest,
                    hasWarning
                        ? Colors.orange.shade600
                        : Colors.green.shade700,
                    17,
                    bold: true,
                  ),
                ],

                // ── AVVISO RESTO NON EROGATO ─────────────────────────────
                if (hasWarning) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Resto non disponibile',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.orange.shade800)),
                              const SizedBox(height: 4),
                              Text(
                                '€ ${_changeNotDispensed.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange.shade800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Restituire manualmente al cliente.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Errore
                if (isError && _errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade700)),
                      ),
                    ]),
                  ),
                ],

                // Progress bar
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: isCompleted || isError
                        ? 1.0
                        : isPending
                            ? _progress
                            : null,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isError
                          ? Colors.red.shade400
                          : hasWarning
                              ? Colors.orange.shade600
                              : isCompleted
                                  ? Colors.green.shade600
                                  : const Color(0xFF0EA5E9),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    isCompleted
                        ? (hasWarning ? 'Attenzione!' : 'Completato ✓')
                        : isError
                            ? 'Errore'
                            : isCancelling
                                ? 'Annullamento…'
                                : '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isError
                            ? Colors.red.shade500
                            : hasWarning
                                ? Colors.orange.shade700
                                : isCompleted
                                    ? Colors.green.shade600
                                    : Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),

            // ── FOOTER ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Column(children: [

                if (isCompleted || isError)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _chiudi(success: isCompleted),
                      icon: Icon(isCompleted && !hasWarning
                          ? Icons.check_rounded
                          : Icons.close_rounded),
                      label: const Text('Chiudi',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),

                if (isPending)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _annulla,
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red, size: 18),
                      label: const Text('Annulla pagamento',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                if (isInit || isCancelling) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: themeColor)),
                      const SizedBox(width: 8),
                      Text(
                        isCancelling
                            ? 'Annullamento in corso…'
                            : 'Avvio transazione…',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String label, double amount, Color color, double size,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Text('€ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize:   size,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color:      color)),
      ],
    );
  }

  Widget _cardBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color:        Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.credit_card, size: 13, color: Colors.blueAccent),
          SizedBox(width: 4),
          Text('Carta',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent)),
        ]),
      );

  IconData _headerIcon(bool done, bool err, bool warning) {
    if (done) return warning ? Icons.warning_amber_rounded : Icons.check_circle_rounded;
    if (err)  return Icons.error_rounded;
    return Icons.payments_outlined;
  }

  String _headerTitle(bool done, bool err, bool cancel, bool init, bool warn) {
    if (done)   return warn ? 'Resto parziale' : 'Pagamento completato';
    if (err)    return 'Errore pagamento';
    if (cancel) return 'Annullamento…';
    if (init)   return 'Connessione…';
    return 'In attesa di pagamento';
  }

  String _headerSub(bool done, bool err, bool cancel, bool init) {
    if (done)   return 'Transazione conclusa';
    if (err)    return 'Operazione non riuscita';
    if (cancel) return 'Rimborso in corso…';
    if (init)   return 'Avvio transazione…';
    return 'Inserire il contante nella macchina';
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// VNE WITHDRAWAL — Tastierino selezione importo + Modal erogazione
// Protocollo: tipo 10 (start) → tipo 11 poll → tipo 12 end
// ═══════════════════════════════════════════════════════════════════════════

class VneWithdrawalResult {
  final bool    success;
  final double  amount;
  final String? errorMessage;

  const VneWithdrawalResult({
    required this.success,
    this.amount       = 0,
    this.errorMessage,
  });
}

Future<VneWithdrawalResult> showVneWithdrawalDialog(
  BuildContext context, {
  required String ipMacchina,
  String          opName = 'CASSA01',
}) async {
  final result = await showDialog<VneWithdrawalResult>(
    context:            context,
    barrierDismissible: false,
    builder: (_) => _VneWithdrawalDialog(
      ip:     ipMacchina,
      opName: opName,
    ),
  );
  return result ?? const VneWithdrawalResult(success: false);
}

// ─────────────────────────────────────────────────────────────────────────────

class _VneWithdrawalDialog extends StatefulWidget {
  final String ip;
  final String opName;

  const _VneWithdrawalDialog({required this.ip, required this.opName});

  @override
  State<_VneWithdrawalDialog> createState() => _VneWithdrawalDialogState();
}

class _VneWithdrawalDialogState extends State<_VneWithdrawalDialog> {
  late final VneService _service;

  // ── Fase 1: tastierino ────────────────────────────────────────────────
  String _buffer    = '0';
  double get _inputAmount => double.tryParse(_buffer) ?? 0.0;

  // ── Fase 2: erogazione ────────────────────────────────────────────────
  bool    _inWithdrawal = false;   // true = mostra modal erogazione
  String  _wStatus      = 'INIT'; // INIT · PENDING · COMPLETED · ERROR
  double  _wAmount      = 0.0;
  bool    _isPolling    = false;
  String? _activeId;
  String  _errorMsg     = '';

  static const List<double>  _presets = [5, 10, 20, 50, 100, 200];
  static const List<String>  _keys    = ['1','2','3','4','5','6','7','8','9','C','0','DEL'];

  @override
  void initState() {
    super.initState();
    _service = VneService(widget.ip,opName: widget.opName);
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  // ── Tastierino ────────────────────────────────────────────────────────
  void _keyInput(String val) {
    setState(() {
      if (val == 'C') {
        _buffer = '0';
      } else if (val == 'DEL') {
        _buffer = _buffer.length > 1
            ? _buffer.substring(0, _buffer.length - 1)
            : '0';
      } else if (val == '.') {
        if (!_buffer.contains('.')) _buffer += '.';
      } else {
        if (_buffer == '0') {
          _buffer = val;
        } else {
          if (_buffer.contains('.') && _buffer.split('.')[1].length >= 2) return;
          _buffer += val;
        }
      }
    });
  }

  void _selectPreset(double amount) {
    setState(() => _buffer = amount.toStringAsFixed(2));
  }

  // ── Avvia prelievo — identico a startWithdrawalTransaction() ─────────
  Future<void> _startWithdrawal() async {
    if (_inputAmount <= 0) return;
    final int cents = (_inputAmount * 100).round();

    setState(() {
      _wAmount      = _inputAmount;
      _wStatus      = 'INIT';
      _errorMsg     = '';
      _inWithdrawal = true;
    });

    try {
      final res = await _service.startWithdrawal(cents);
      if (!mounted) return;

      if (res['req_status'] == 1) {
        _activeId  = res['id']?.toString();
        _isPolling = true;
        setState(() => _wStatus = 'PENDING');
        _pollLoop();
      } else {
        setState(() {
          _wStatus  = 'ERROR';
          _errorMsg = res['mess']?.toString() ?? 'NACK avvio prelievo';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _wStatus  = 'ERROR';
        _errorMsg = e.toString();
      });
    }
  }

  // ── Polling — identico a _pollWithdrawalLoop() ────────────────────────
  Future<void> _pollLoop() async {
    if (!_isPolling || _activeId == null || !mounted) return;

    try {
      final poll = await _service.pollWithdrawal(_activeId!);
      if (!mounted) return;

      if (poll['req_status'] == 1) {
        // withdraw_status: 1 = completato, -1 = errore erogazione
        final int wStatus = poll['withdraw_status'] ?? 0;

        if (wStatus == 1) {
          // Chiama tipo 12 endWithdrawal
          _isPolling = false;
          try { await _service.endWithdrawal(); } catch (_) {}
          if (!mounted) return;
          setState(() => _wStatus = 'COMPLETED');
          // chiusura automatica dopo 3s
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _chiudi(success: true);
          });
          return;

        } else if (wStatus == -1) {
          // Errore durante l'erogazione
          _isPolling = false;
          setState(() {
            _wStatus  = 'ERROR';
            _errorMsg = poll['mess']?.toString() ?? "Errore interno durante l'erogazione.";
          });
          return;
        }
        // wStatus == 0 → ancora in corso, continua polling

      } else {
        // NACK → macchina ha interrotto
        _isPolling = false;
        setState(() {
          _wStatus  = 'ERROR';
          _errorMsg = poll['mess']?.toString() ?? 'La macchina ha interrotto l\'operazione.';
        });
        return;
      }
    } catch (e) {
      debugPrint('VNE withdrawal poll (continuo): $e');
    }

    await Future.delayed(const Duration(seconds: 1));
    _pollLoop();
  }

  void _chiudi({required bool success}) {
    if (!mounted) return;
    Navigator.of(context).pop(VneWithdrawalResult(
      success:      success,
      amount:       _wAmount,
      errorMessage: _errorMsg.isEmpty ? null : _errorMsg,
    ));
  }

  // ═════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: _inWithdrawal ? _buildWithdrawalPhase() : _buildKeypadPhase(),
      ),
    );
  }

  // ── FASE 1: Tastierino ────────────────────────────────────────────────
  Widget _buildKeypadPhase() {
    final bool canConfirm = _inputAmount > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withOpacity(0.07),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
                bottom: BorderSide(
                    color: const Color(0xFF0EA5E9).withOpacity(0.15))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.13),
                  shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFF0EA5E9), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prelievo Operatore',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Seleziona o inserisci l\'importo',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(children: [

            // Display importo
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: canConfirm
                        ? const Color(0xFF0EA5E9).withOpacity(0.4)
                        : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('IMPORTO',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2)),
                  Text(
                    '€ ${double.tryParse(_buffer)?.toStringAsFixed(2) ?? _buffer}',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: canConfirm
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preset rapidi
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _presets[i];
                  final bool selected =
                      (_inputAmount - p).abs() < 0.01;
                  return GestureDetector(
                    onTap: () => _selectPreset(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF0EA5E9)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF0EA5E9)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '€ ${p.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade700),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Tastierino numerico
            GridView.count(
              shrinkWrap:       true,
              physics:          const NeverScrollableScrollPhysics(),
              crossAxisCount:   3,
              mainAxisSpacing:  8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: _keys.map((k) {
                final bool isCancel = k == 'C';
                final bool isDel    = k == 'DEL';
                return Material(
                  color: isCancel
                      ? Colors.red.shade50
                      : isDel
                          ? Colors.grey.shade100
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _keyInput(k),
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: isDel
                          ? Icon(Icons.backspace_outlined,
                              size: 18, color: Colors.grey.shade600)
                          : Text(k,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isCancel
                                      ? Colors.red.shade600
                                      : const Color(0xFF334155))),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ]),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(
                        const VneWithdrawalResult(success: false)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Annulla',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canConfirm ? _startWithdrawal : null,
                icon: const Icon(Icons.outbond),
                label: const Text('Preleva',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ── FASE 2: Erogazione in corso ───────────────────────────────────────
  Widget _buildWithdrawalPhase() {
    final bool isCompleted  = _wStatus == 'COMPLETED';
    final bool isError      = _wStatus == 'ERROR';
    final bool isPending    = _wStatus == 'PENDING';
    final bool isInit       = _wStatus == 'INIT';

    final Color themeColor = isCompleted
        ? Colors.green.shade600
        : isError
            ? Colors.red.shade600
            : const Color(0xFF0EA5E9);

    final IconData icon = isCompleted
        ? Icons.check_circle_rounded
        : isError
            ? Icons.error_rounded
            : Icons.account_balance_wallet_outlined;

    final String title = isCompleted
        ? 'Prelievo completato'
        : isError
            ? 'Errore prelievo'
            : 'Erogazione in corso…';

    final String subtitle = isCompleted
        ? 'Il contante è stato erogato'
        : isError
            ? 'Operazione non riuscita'
            : 'Attendere l\'erogazione del contante';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.07),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
                bottom:
                    BorderSide(color: themeColor.withOpacity(0.15))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.13),
                  shape: BoxShape.circle),
              child: Icon(icon, color: themeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ]),
        ),

        // Body
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(children: [

            // Importo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Importo richiesto',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF64748B))),
                Text('€ ${_wAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: themeColor)),
              ],
            ),

            // Errore
            if (isError && _errorMsg.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMsg,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700)),
                  ),
                ]),
              ),
            ],

            // Spinner / animazione
            const SizedBox(height: 24),
            if (isPending || isInit)
              Column(children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isInit
                      ? 'Avvio prelievo…'
                      : 'La macchina sta erogando il contante…',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ]),

            if (isCompleted)
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 64),

            const SizedBox(height: 24),
          ]),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          child: (isCompleted || isError)
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _chiudi(success: isCompleted),
                    icon: Icon(isCompleted
                        ? Icons.check_rounded
                        : Icons.close_rounded),
                    label: const Text('Chiudi',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:flutter/material.dart';

// =============================================================================
// CASHLOGY TCP PROTOCOL - ENTERPRISE IMPLEMENTATION v2.5
// Based on CashlogyConnector Integration Manual v2.5
// =============================================================================

/// Cashlogy operation types for advanced integration
enum CashlogyOperation {
  // Express Integration
  initialize,
  close,
  charge,
  backoffice,
  
  // Advanced Charging
  startAcceptance,
  seeAmountAccepted,
  stopAcceptance,
  dispense,
  
  // Change & Closure Operations
  addChange,
  giveChange,
  withdrawCash,
  dispenseByDenomination,
  collectStacker,
  closureCashFloat,
  
  // Accounting Operations
  status,
  totalAmount,
  quantityByValues,
  amountOfAllValues,
  getCapacity,
  getAuxiliarInfo,
  absoluteStatistics,
  relativeStatistics,
  
  // Maintenance Operations
  cancel,
  reset,
  completeEmptying,
  getVersions,
  maintenance,
  maintenanceNoScreen,
  seeLogs,
  setCoinsToZero,
  problemSolvingInfo,
  troubleshooting,
  
  // Error Management
  showErrors,
  getError,
  getErrorDetails,
}

/// Error codes returned by CashlogyConnector
class CashlogyError {
  static const String success = '#0#';
  static const String warningLevel = '#WR:LEVEL#';
  static const String warningCancel = '#WR:CANCEL#';
  static const String errorGeneric = '#ER:GENERIC#';
  static const String errorBusy = '#ER:BUSY#';
  static const String errorBadData = '#ER:BAD_DATA#';
  static const String errorIllegal = '#ER:ILLEGAL#';
}

/// Transaction result data
class TransactionResult {
  final bool success;
  final bool isPartial;
  final String errorCode;
  final int amountCharged;
  final int amountReturned;
  final int amountManual;
  final int amountChangeAdded;
  final String message;

  TransactionResult({
    required this.success,
    this.isPartial = false,
    required this.errorCode,
    this.amountCharged = 0,
    this.amountReturned = 0,
    this.amountManual = 0,
    this.amountChangeAdded = 0,
    this.message = '',
  });

  double get changeAmount => (amountReturned / 100.0);
  double get totalCharged => (amountCharged / 100.0);
}

/// Backoffice result data
class BackofficeResult {
  final bool success;
  final String errorCode;
  final int amountBefore;
  final int amountAfter;
  final int amountInserted;
  final int amountWithdrawn;
  final int amountNotDispensed;
  final int amountConsolidated;

  BackofficeResult({
    required this.success,
    required this.errorCode,
    this.amountBefore = 0,
    this.amountAfter = 0,
    this.amountInserted = 0,
    this.amountWithdrawn = 0,
    this.amountNotDispensed = 0,
    this.amountConsolidated = 0,
  });
}

/// Accounting data structure
class AccountingData {
  final Map<int, int> coinQuantities;
  final Map<int, int> noteQuantities;
  final int totalAmount;

  AccountingData({
    required this.coinQuantities,
    required this.noteQuantities,
    required this.totalAmount,
  });
}

/// Log event for tracking operations
class LogEvent {
  final String time;
  final String message;
  final Color color;
  final String category;
  final DateTime timestamp;

  LogEvent(this.message, this.color, {this.category = 'INFO'})
      : time = DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8),
        timestamp = DateTime.now();
}

// =============================================================================
// CASHLOGY SERVICE - TCP/IP COMMUNICATION LAYER
// =============================================================================

class ControllerCashlogy extends ChangeNotifier {
  bool   _isConnected = false;
  String _mainStatus = 'OFFLINE';
  bool _isTransactionActive = false;
  int _amountToPayCents = 0;
  int _amountInsertedCents = 0;
  bool _hasLevelWarning = false;
  final List<LogEvent> _logs = [];
  int _pageIndex = 0;
  TransactionResult? _lastResult;
  bool _isProcessing = false;
  Timer? _pollingTimer;
  int _pendingChangeCents = 0;
  bool _isCancelling = false;
  int _targetDispenseCents = 0;
  bool _transactionWarning = false;

}

class CashlogyService extends ControllerCashlogy {
  final String ip;
  final int port;
  
  // CashlogyService({this.ip = '2.44.124.227', this.port = 8092});
  CashlogyService({
    required this.ip,
    required this.port,
  });

  static CashlogyService? instance;
  static CashlogyService getInstance(String ip, int port) => instance ??=  CashlogyService(ip: ip, port: port);

  Socket? _socket;
  StreamSubscription? _subscription;
  String _buffer = '';
  
  // Track last command sent so we can properly parse responses
  String _lastCommand = '';
  
  // Flag: only fire onStopAcceptanceComplete when we actually sent #J#
  bool _awaitingStopResponse = false;
  
  // Protocol version
  String protocolVersion = '2.5';

  // Track intended payout for error reporting
  int _targetPayoutCents = 0;
  
  // Connection state
  bool get isConnected => _socket != null;
  
  // Callbacks
  Function(String msg, Color color, {String category})? onLog;
  Function(bool isConnected)? onConnectionChange;
  Function(int inserted)? onCashInserted;
  Function(TransactionResult result)? onTransactionComplete;
  Function(int amount)? onDispenseComplete;
  Function(int amount)? onCancelComplete;
  Function(int amount)? onStopAcceptanceComplete;
  Function(String warning)? onWarning;
  Function(String error)? onError;

  

  /// Connect to CashlogyConnector
  Future<bool> connect() async {
    if (_socket != null) {
      _log('Already connected', Colors.orange);
      return true;
    }

    try {
      _log('Connecting to $ip:$port...', Colors.grey, category: 'SYSTEM');
      _socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      _notifyConnection(true);
      _log('Connected successfully', Colors.green, category: 'SYSTEM');

      _subscription = _socket!.listen(
        _onData,
        onError: _onSocketError,
        onDone: _onSocketDone,
      );

      // Initialize device
      await Future.delayed(const Duration(milliseconds: 300));
      await initialize();
      
      return true;
    } catch (e) {
      _log('Connection failed: $e', Colors.red, category: 'ERROR');
      _notifyConnection(false);
      return false;
    }
  }

  /// Disconnect from CashlogyConnector
  Future<void> disconnect() async {
    if (_socket != null) {
      try {
        await closeConnection();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        _log('Error during close: $e', Colors.orange);
      }
    }
    _disconnectInternal();
    _log('Disconnected', Colors.grey, category: 'SYSTEM');
  }

  void _disconnectInternal() {
    _subscription?.cancel();
    _socket?.destroy();
    _socket = null;
    _buffer = '';
    _notifyConnection(false);
  }

  void _onData(List<int> data) {
    try {
      final chunk = utf8.decode(data);
      print('DEBUG RX RAW: $chunk');
      _log('RX: $chunk', Colors.teal, category: 'RX');
      _buffer += chunk;
      _processBuffer();
    } catch (e) {
      print('DEBUG ERROR DECODE: $e');
      _log('Decode error: $e', Colors.red, category: 'ERROR');
    }
  }

  void _onSocketError(dynamic error) {
    _log('Socket error: $error', Colors.red, category: 'ERROR');
    _disconnectInternal();
  }

  void _onSocketDone() {
    _log('Connection closed by server', Colors.orange, category: 'SYSTEM');
    _disconnectInternal();
  }

  /// Process incoming data buffer
  void _processBuffer() {
    while (_buffer.contains('#')) {
      bool handled = false;

      // ===== ERROR / WARNING responses (check FIRST - they have unique prefixes) =====

      // Warning: Cancel - #WR:CANCEL#amount#
      if (_buffer.contains('#WR:CANCEL#')) {
        final cancelMatch = RegExp(r'#WR:CANCEL#(\d+)#').firstMatch(_buffer);
        if (cancelMatch != null) {
          final amount = int.parse(cancelMatch.group(1)!);
          _log('Cancel confirmed - €${(amount / 100).toStringAsFixed(2)} in machine, dispensing back...', Colors.orange, category: 'CANCEL');
          onCancelComplete?.call(amount);
          _buffer = _buffer.replaceFirst(cancelMatch.group(0)!, '');
          handled = true;
        } else {
          _buffer = _buffer.replaceFirst('#WR:CANCEL#', '');
          onCancelComplete?.call(0);
          handled = true;
        }
      }

      // Error: Any #ER:CODE# response
      else if (_buffer.contains('#ER:')) {
        // Try to match the most specific GENERIC variants first
        final match4 = RegExp(r'#ER:GENERIC#(-?\d+)#(-?\d+)#(-?\d+)#(-?\d+)#').firstMatch(_buffer);
        final match2 = RegExp(r'#ER:GENERIC#(-?\d+)#(-?\d+)#').firstMatch(_buffer);
        final matchGeneric = RegExp(r'#ER:GENERIC#').firstMatch(_buffer);
        final matchAny = RegExp(r'#ER:([A-Z0-9_:]+)#').firstMatch(_buffer);

        String errorMsg = 'Machine Error';
        String errorCode = '#ER:GENERIC#';
        int p1 = 0, p2 = 0, p3 = 0, p4 = 0;
        String matchedString = '';

        if (match4 != null) {
          matchedString = match4.group(0)!;
          p1 = int.parse(match4.group(1)!); // dispensed
          p2 = int.parse(match4.group(2)!); // missing
          p3 = int.parse(match4.group(3)!); // manual
          p4 = int.parse(match4.group(4)!); // added
          if (p1 == 0 && p2 == 0 && p3 == 0 && p4 == 0) {
            errorMsg = 'CRITICO: Dispositivo spento o scollegato.';
          } else {
            final double disp = p1 / 100;
            final int totalIntended = _targetPayoutCents > 0 ? _targetPayoutCents : (p1 + p2);
            final double total = totalIntended / 100;
            final double missing = (totalIntended - p1) / 100;
            
            if (missing > 0) {
              errorMsg = 'Erogazione Parziale: €${disp.toStringAsFixed(2)} di €${total.toStringAsFixed(2)} erogati.\nRIMBORSARE MANUALMENTE: €${missing.toStringAsFixed(2)}';
            } else {
              errorMsg = 'Erogati €${disp.toStringAsFixed(2)} di €${total.toStringAsFixed(2)} previsti. Il resto è bloccato, controllare la macchina.';
            }
            _targetPayoutCents = 0;
          }
        } else if (match2 != null) {
          matchedString = match2.group(0)!;
          p1 = int.parse(match2.group(1)!); // dispensed
          p2 = int.parse(match2.group(2)!); // missing
          if (p1 == 0 && p2 == 0) {
            errorMsg = 'CRITICO: Macchina spenta o non collegata.';
          } else {
            final double disp = p1 / 100;
            final int totalIntended = _targetPayoutCents > 0 ? _targetPayoutCents : (p1 + p2);
            final double total = totalIntended / 100;
            final double missing = (totalIntended - p1) / 100;
            
            if (missing > 0) {
              errorMsg = 'Erogazione Parziale: €${disp.toStringAsFixed(2)} di €${total.toStringAsFixed(2)} erogati.\nRIMBORSARE MANUALMENTE: €${missing.toStringAsFixed(2)}';
            } else {
              errorMsg = 'Errore erogazione: Erogati €${disp.toStringAsFixed(2)} di €${total.toStringAsFixed(2)} previsti. Il resto è bloccato, controllare la macchina.';
            }
            _targetPayoutCents = 0;
          }
        } else if (matchGeneric != null) {
          matchedString = matchGeneric.group(0)!;
          errorMsg = 'CRITICO: Macchina SPENTA o scollegata. Verificare il dispositivo.';
        } else if (matchAny != null) {
          matchedString = matchAny.group(0)!;
          errorCode = matchAny.group(1)!;
          if (errorCode == 'BUSY') errorMsg = 'La macchina è occupata in un\'altra operazione';
          else if (errorCode == 'BAD_DATA') errorMsg = 'Comando non valido inviato alla macchina';
          else if (errorCode == 'ILLEGAL') errorMsg = 'Operazione non consentita nello stato attuale';
          else errorMsg = 'Errore hardware: $errorCode';
        }

        if (matchedString.isNotEmpty) {
          // If it's a generic dispense error, we treat it as partial success/warning
          // because the machine has already accepted the payment.
          final bool isPartial = matchedString.contains('GENERIC') && (p1 > 0 || p2 > 0);
          
          print('DEBUG MATCH ERROR: $matchedString -> $errorMsg');
          _log(isPartial ? 'WARNING: $errorMsg' : 'ERROR: $errorMsg ($matchedString)', 
               isPartial ? Colors.orange : Colors.red, category: isPartial ? 'WARNING' : 'ERROR');
          
          final result = TransactionResult(
            success: isPartial, // Show as "success" with warning for any dispense-related issue
            isPartial: isPartial,
            errorCode: errorCode,
            amountCharged: 0,
            amountReturned: p1, // amount already dispensed
            amountManual: p3,
            amountChangeAdded: p4,
            message: errorMsg,
          );
          onTransactionComplete?.call(result);
          onError?.call(errorMsg);
          _buffer = _buffer.replaceFirst(matchedString, '');
          handled = true;
        } else {
          // If we found #ER: but couldn't match a full packet, wait for more data
          break;
        }
      }

      // Warning: Level
      else if (_buffer.contains('#WR:LEVEL#')) {
        // Could be standalone #WR:LEVEL# or #WR:LEVEL#amount#
        final levelMatch = RegExp(r'#WR:LEVEL#(\d+)#').firstMatch(_buffer);
        if (levelMatch != null) {
          // #WR:LEVEL#amount# - response with amount (from #Q#, #J#, #P#, etc.)
          final amount = int.parse(levelMatch.group(1)!);
          print('DEBUG MATCH LEVEL: ${levelMatch.group(0)} (Amount: $amount)');
          _log('Level warning - Amount: €${(amount / 100).toStringAsFixed(2)}', Colors.orange, category: 'WARNING');
          onWarning?.call('LEVEL_WARNING');
          // Route the amount based on last command (treat same as #0#amount#)
          if (_lastCommand == 'J' && _awaitingStopResponse) {
            // Stop acceptance completed with a level warning - still process it
            _awaitingStopResponse = false;
            _log('Acceptance stopped (with level warning) - Total: €${(amount / 100).toStringAsFixed(2)}', Colors.blue, category: 'ACCEPT');
            onStopAcceptanceComplete?.call(amount);
          } else if (_lastCommand == 'P') {
            // Dispense completed with a level warning - still process it
            _log('Change dispensed (with level warning): €${(amount / 100).toStringAsFixed(2)}', Colors.green, category: 'DISPENSE');
            onDispenseComplete?.call(amount);
          } else if (_lastCommand == 'Q' || _lastCommand == 'J') {
            onCashInserted?.call(amount);
          }
          _buffer = _buffer.replaceFirst(levelMatch.group(0)!, '');
          handled = true;
        } else {
          _log('Level warning', Colors.orange, category: 'WARNING');
          onWarning?.call('LEVEL_WARNING');
          _buffer = _buffer.replaceFirst('#WR:LEVEL#', '');
          handled = true;
        }
      }

      // Cash insertion update: #I:amount#
      else if (_buffer.contains(RegExp(r'#I:(\d+)#'))) {
        final match = RegExp(r'#I:(\d+)#').firstMatch(_buffer);
        if (match != null) {
          final amount = int.parse(match.group(1)!);
          onCashInserted?.call(amount);
          _buffer = _buffer.replaceFirst(match.group(0)!, '');
          handled = true;
        }
      }

      // ===== SUCCESS responses - route based on _lastCommand =====

      // #C# Charge response: #0#charged#returned#manual#changeAdded# (4 numbers)
      else if (_buffer.contains(RegExp(r'#0#(\d+)#(\d+)#(\d+)#(\d+)#'))) {
        final m = RegExp(r'#0#(\d+)#(\d+)#(\d+)#(\d+)#').firstMatch(_buffer);
        if (m != null) {
          _log('Charge complete', Colors.green, category: 'SUCCESS');
          final result = TransactionResult(
            success: true,
            errorCode: '#0#',
            amountCharged: int.parse(m.group(1)!),
            amountReturned: int.parse(m.group(2)!),
            amountManual: int.parse(m.group(3)!),
            amountChangeAdded: int.parse(m.group(4)!),
          );
          onTransactionComplete?.call(result);
          _targetPayoutCents = 0;
          _buffer = _buffer.replaceFirst(m.group(0)!, '');
          handled = true;
        }
      }

      // Initialization success: #0#version#
      else if (_buffer.contains(RegExp(r'#0#\d\.\d+#'))) {
        final match = RegExp(r'#0#(\d\.\d+)#').firstMatch(_buffer);
        if (match != null) {
          protocolVersion = match.group(1)!;
          _log('Initialized - Protocol v$protocolVersion', Colors.green, category: 'INIT');
          _buffer = _buffer.replaceFirst(match.group(0)!, '');
          handled = true;
        }
      }

      // #0#amount# - context-dependent response
      else if (_buffer.contains(RegExp(r'#0#(\d+)#'))) {
        final match = RegExp(r'#0#(\d+)#').firstMatch(_buffer);
        if (match != null) {
          final amount = int.parse(match.group(1)!);
          
          if (_lastCommand == 'Q') {
            // #Q# See amount accepted response
            if (amount > 0) {
              onCashInserted?.call(amount);
            }
          } else if (_lastCommand == 'J' && _awaitingStopResponse) {
            // #J# Stop acceptance response - final amount
            _awaitingStopResponse = false;
            _log('Acceptance stopped - Total: \u20ac${(amount / 100).toStringAsFixed(2)}', Colors.blue, category: 'ACCEPT');
            onStopAcceptanceComplete?.call(amount);
          } else if (_lastCommand == 'J' && !_awaitingStopResponse) {
            // Stale response from #Q# that arrived after #J# was sent, treat as poll
            if (amount > 0) {
              onCashInserted?.call(amount);
            }
          } else if (_lastCommand == 'P') {
            // #P# Dispense response - amount returned (with 0 change added)
            _log('Change dispensed: \u20ac${(amount / 100).toStringAsFixed(2)}', Colors.green, category: 'DISPENSE');
            onDispenseComplete?.call(amount);
            _targetPayoutCents = 0;
          } else {
            _log('Response: $amount (cmd=$_lastCommand)', Colors.blue, category: 'DATA');
          }
          
          _buffer = _buffer.replaceFirst(match.group(0)!, '');
          handled = true;
        }
      }
      
      // Simple #0# success ack
      else if (_buffer.startsWith('#0#')) {
        if (_lastCommand == 'B') {
          _log('Acceptance started', Colors.green, category: 'ACCEPT');
        } else if (_lastCommand == '!') {
          _log('No running operation to cancel', Colors.grey, category: 'ACK');
        } else {
          _log('Command acknowledged', Colors.green, category: 'ACK');
        }
        _buffer = _buffer.replaceFirst('#0#', '');
        handled = true;
      }

      if (!handled) {
        if (_buffer.length > 1000) {
          _log('Buffer overflow - clearing', Colors.red, category: 'ERROR');
          _buffer = '';
        }
        break;
      }
    }
  }

  /// Send command to CashlogyConnector
  void _sendCommand(String command) {
    if (_socket == null) {
      _log('Cannot send - not connected', Colors.red, category: 'ERROR');
      return;
    }


    
    // Track the command letter for response routing
    // Commands are like #X#... so extract the letter(s)
    final cmdMatch = RegExp(r'^#([A-Z!?]+)#').firstMatch(command);
    if (cmdMatch != null) {
      _lastCommand = cmdMatch.group(1)!;
    }
    
    print('DEBUG TX: $command');
    _log('TX: $command', Colors.blueGrey, category: 'TX');
    _socket!.write(command);
  }

    Future<void> recoverFromBusy() async {
      _log('BUSY recovery: sending #!# + #Z#', Colors.orange, category: 'RECOVERY');
      _sendCommand('#!#');                                    // cancella op. in corso
      await Future.delayed(const Duration(milliseconds: 400));
      _sendCommand('#Z#');                                    // reset
      await Future.delayed(const Duration(milliseconds: 600));
      _log('BUSY recovery complete — ready', Colors.green, category: 'RECOVERY');
      // Qui puoi notificare l'UI che la macchina è pronta
      onConnectionChange?.call(true);
    }

  // =========================================================================
  // EXPRESS INTEGRATION COMMANDS
  // =========================================================================

  /// #I# Initialize the machine
  Future<void> initialize() async {
    _log('Initializing device...', Colors.blue, category: 'INIT');
    _sendCommand('#I#');
  }

  /// #E# Close connection
  Future<void> closeConnection() async {
    _log('Closing connection...', Colors.grey, category: 'CLOSE');
    _sendCommand('#E#');
  }

  /// #C# Charging - Express Integration
  /// Full payment operation with automatic change calculation
  void charge({
    required int amountCents,
    String operationNumber = '1',
    String tillCode = '1',
    bool showSecondScreen = false,
    int secondScreenX = 0,
    int secondScreenY = 0,
    bool showAcceptButton = false,
    bool allowPartialCharge = false,
    bool screenAlwaysOnTop = true,
    bool showManualCents = false,
    bool allowManualDeposit = false,
  }) {
    final cmd = '#C#$operationNumber#$tillCode#$amountCents#'
        '${showSecondScreen ? 1 : 0}#$secondScreenX#$secondScreenY#'
        '${showAcceptButton ? 1 : 0}#${allowPartialCharge ? 1 : 0}#'
        '${screenAlwaysOnTop ? 1 : 0}#${showManualCents ? 1 : 0}#'
        '${allowManualDeposit ? 1 : 0}#';
    
    _log('Starting charge: €${(amountCents / 100).toStringAsFixed(2)}', Colors.blue, category: 'CHARGE');
    _targetPayoutCents = amountCents;
    _sendCommand(cmd);
  }

  /// #G# Backoffice - Express Integration
  /// Opens backoffice menu with configurable options
  void backoffice({
    bool showStatus = true,
    bool showAddChange = true,
    bool showAddChange1Cent = false,
    bool showRemoveCash = true,
    bool showRemoveStacker = true,
    bool showCompleteEmpty = true,
    bool showGiveChange = true,
    bool showCloseTill = true,
    bool showSeeLogs = false,
    bool showSetCoinsZero = false,
    bool showStatistics = true,
    bool screenAlwaysOnTop = true,
    bool showMaintenance = false,
    int showResolveSelfProtection = 0,
    bool showResolveAccountingMismatch = false,
  }) {
    final cmd = '#G#${showStatus ? 1 : 0}#${showAddChange ? 1 : 0}#'
        '${showAddChange1Cent ? 1 : 0}#${showRemoveCash ? 1 : 0}#'
        '${showRemoveStacker ? 1 : 0}#${showCompleteEmpty ? 1 : 0}#'
        '${showGiveChange ? 1 : 0}#${showCloseTill ? 1 : 0}#'
        '${showSeeLogs ? 1 : 0}#${showSetCoinsZero ? 1 : 0}#'
        '${showStatistics ? 1 : 0}#${screenAlwaysOnTop ? 1 : 0}#'
        '${showMaintenance ? 1 : 0}#$showResolveSelfProtection#'
        '${showResolveAccountingMismatch ? 1 : 0}#';
    
    _log('Opening backoffice', Colors.purple, category: 'BACKOFFICE');
    _sendCommand(cmd);
  }

  // =========================================================================
  // ADVANCED CHARGING COMMANDS
  // =========================================================================

  /// #B# Start acceptance
  void startAcceptance({
    bool screenAlwaysOnTop = true,
    int secondScreenX = 0,
    int secondScreenY = 0,
  }) {
    final cmd = '#B#${screenAlwaysOnTop ? 1 : 0}#$secondScreenX#$secondScreenY#';
    _log('Starting cash acceptance', Colors.blue, category: 'ACCEPT');
    _sendCommand(cmd);
  }

  /// #Q# See amount accepted
  void seeAmountAccepted() {
    _sendCommand('#Q#');
  }

  /// #J# Stop acceptance
  void stopAcceptance() {
    _awaitingStopResponse = true;
    _log('Stopping acceptance', Colors.orange, category: 'ACCEPT');
    _sendCommand('#J#');
  }

  /// #P# Dispense change
  void dispense({
    required int amountCents,
    bool screenAlwaysOnTop = false,
    bool showScreen = false,
    bool coinsOnly = false,
  }) {
    _targetPayoutCents = amountCents;
    final cmd = '#P#$amountCents#${screenAlwaysOnTop ? 1 : 0}#'
        '${showScreen ? 1 : 0}#${coinsOnly ? 1 : 0}#';
    _log('Dispensing: €${(amountCents / 100).toStringAsFixed(2)}', Colors.green, category: 'DISPENSE');
    _sendCommand(cmd);
  }

  // =========================================================================
  // CHANGE & CLOSURE OPERATIONS
  // =========================================================================

  /// #A# Add change
  void addChange({int screenMode = 1}) {
    final cmd = '#A#$screenMode#';
    _log('Adding change', Colors.blue, category: 'CHANGE');
    _sendCommand(cmd);
  }

  /// #H# Give change
  void giveChange({bool screenAlwaysOnTop = true}) {
    final cmd = '#H#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Give change operation', Colors.blue, category: 'CHANGE');
    _sendCommand(cmd);
  }

  /// #R# Withdraw cash
  void withdrawCash({bool screenAlwaysOnTop = true}) {
    final cmd = '#R#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Withdrawing cash', Colors.orange, category: 'WITHDRAW');
    _sendCommand(cmd);
  }

  /// #U# Dispense by denomination
  void dispenseByDenomination({
    required String denominations,
    bool notesToStacker = false,
    bool screenAlwaysOnTop = true,
    bool showDispenseScreen = false,
  }) {
    final cmd = '#U#$denominations#${notesToStacker ? 1 : 0}#'
        '${screenAlwaysOnTop ? 1 : 0}#${showDispenseScreen ? 1 : 0}#';
    _log('Dispensing by denomination', Colors.green, category: 'DISPENSE');
    _sendCommand(cmd);
  }

  /// #S# Collect stacker
  void collectStacker({int screenMode = 1}) {
    final cmd = '#S#$screenMode#';
    _log('Collecting stacker', Colors.purple, category: 'STACKER');
    _sendCommand(cmd);
  }

  /// #F# Closure / Cash float
  void closureCashFloat({bool screenAlwaysOnTop = true}) {
    final cmd = '#F#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Cash float/closure operation', Colors.purple, category: 'CLOSURE');
    _sendCommand(cmd);
  }

  // =========================================================================
  // ACCOUNTING OPERATIONS
  // =========================================================================

  /// #D# Status (accounting)
  void getStatus({bool screenAlwaysOnTop = true}) {
    final cmd = '#D#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Getting status', Colors.blue, category: 'ACCOUNTING');
    _sendCommand(cmd);
  }

  /// #T# Total amount of cash
  void getTotalAmount() {
    _log('Getting total amount', Colors.blue, category: 'ACCOUNTING');
    _sendCommand('#T#');
  }

  /// #X# Quantity by values
  void getQuantityByValues() {
    _log('Getting quantity by values', Colors.blue, category: 'ACCOUNTING');
    _sendCommand('#X#');
  }

  /// #Y# Amount of all values
  void getAmountOfAllValues() {
    _log('Getting amount of all values', Colors.blue, category: 'ACCOUNTING');
    _sendCommand('#Y#');
  }

  /// #GC# Get capacity
  void getCapacity() {
    _log('Getting capacity info', Colors.blue, category: 'ACCOUNTING');
    _sendCommand('#GC#');
  }

  /// #GI# Get auxiliar info
  void getAuxiliarInfo() {
    _log('Getting auxiliar info', Colors.blue, category: 'ACCOUNTING');
    _sendCommand('#GI#');
  }

  /// #M# Absolute statistics
  void getAbsoluteStatistics({bool screenAlwaysOnTop = true}) {
    final cmd = '#M#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Getting absolute statistics', Colors.blue, category: 'STATS');
    _sendCommand(cmd);
  }

  /// #N# Relative statistics
  void getRelativeStatistics({bool screenAlwaysOnTop = true}) {
    final cmd = '#N#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Getting relative statistics', Colors.blue, category: 'STATS');
    _sendCommand(cmd);
  }

  // =========================================================================
  // MAINTENANCE OPERATIONS
  // =========================================================================

  /// #!# Cancel current operation
  void cancel() {
    _log('Cancelling operation', Colors.red, category: 'CANCEL');
    _sendCommand('#!#');
  }

  /// #Z# Reset device
  void reset() {
    _log('Resetting device', Colors.orange, category: 'RESET');
    _sendCommand('#Z#');
  }

  /// #V# Complete emptying
  void completeEmptying({
    int screenMode = 1,
    bool notesToStacker = false,
    bool coinsToExit = true,
  }) {
    final cmd = '#V#$screenMode#${notesToStacker ? 1 : 0}#${coinsToExit ? 1 : 0}#';
    _log('Complete emptying', Colors.red, category: 'MAINTENANCE');
    _sendCommand(cmd);
  }

  /// #GV# Get versions
  void getVersions() {
    _log('Getting version info', Colors.blue, category: 'INFO');
    _sendCommand('#GV#');
  }

  /// #O# Maintenance (with screens)
  void maintenance({bool screenAlwaysOnTop = true}) {
    final cmd = '#O#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Opening maintenance', Colors.purple, category: 'MAINTENANCE');
    _sendCommand(cmd);
  }

  /// #W# Maintenance (without screens)
  void maintenanceNoScreen() {
    _log('Maintenance mode (no screen)', Colors.purple, category: 'MAINTENANCE');
    _sendCommand('#W#');
  }

  /// #L# See logs
  void seeLogs({bool screenAlwaysOnTop = true}) {
    final cmd = '#L#${screenAlwaysOnTop ? 1 : 0}#';
    _log('Opening logs', Colors.grey, category: 'LOGS');
    _sendCommand(cmd);
  }

  /// #K# Set coins to zero
  void setCoinsToZero({int screenMode = 1}) {
    final cmd = '#K#$screenMode#';
    _log('Setting coins to zero', Colors.orange, category: 'MAINTENANCE');
    _sendCommand(cmd);
  }

  /// #INFO# Problem solving information
  void getProblemSolvingInfo() {
    _log('Getting problem solving info', Colors.blue, category: 'INFO');
    _sendCommand('#INFO#');
  }

  /// #RI# Troubleshooting
  void troubleshooting({
    int selfProtection = 0,
    int accountingMismatch = 0,
    int screenMode = 2,
  }) {
    final cmd = '#RI#$selfProtection#$accountingMismatch#$screenMode#';
    _log('Troubleshooting', Colors.orange, category: 'MAINTENANCE');
    _sendCommand(cmd);
  }

  // =========================================================================
  // ERROR MANAGEMENT
  // =========================================================================

  /// #?#SHOW# Show errors
  void showErrors() {
    _log('Showing errors', Colors.orange, category: 'ERROR');
    _sendCommand('#?#SHOW#');
  }

  /// #?# Get error status
  void getError() {
    _sendCommand('#?#');
  }

  /// #?#error1,error2# Get error details
  void getErrorDetails(List<String> errorCodes) {
    final cmd = '#?#${errorCodes.join(',')}#';
    _log('Getting error details', Colors.orange, category: 'ERROR');
    _sendCommand(cmd);
  }

  // =========================================================================
  // UTILITY METHODS
  // =========================================================================

  void _log(String msg, Color color, {String category = 'INFO'}) {
    onLog?.call(msg, color, category: category);
  }

  void _notifyConnection(bool connected) {
    onConnectionChange?.call(connected);
  }
}

/// Apre la modal di versamento e gestisce tutto il flusso
Future<void> apriVersamento(BuildContext context, CashlogyService service) async {
  if (!service.isConnected) {
    final connected = await service.connect();
    if (!connected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile connettersi alla macchina contanti'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
  }
  final insertedNotifier = ValueNotifier<int>(0);
  bool isAccepting = false;
  bool isStopping  = false;

  // Callbacks temporanei salvati per ripristinarli dopo
  final prevOnCashInserted        = service.onCashInserted;
  final prevOnStopAcceptanceComplete = service.onStopAcceptanceComplete;
  final prevOnError               = service.onError;
  final prevOnWarning             = service.onWarning;

  // Resetta il contatore
  insertedNotifier.value = 0;

  // Override callbacks per questa operazione
  service.onCashInserted = (amount) {
    insertedNotifier.value = amount;
  };

  service.onStopAcceptanceComplete = (amount) {
    insertedNotifier.value = amount;
    isStopping = false;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(amount);
  };

  service.onError = (msg) {
    isStopping = false;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Errore versamento: $msg'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  };

  service.onWarning = (msg) {
    // warning livelli — non blocchiamo il versamento
  };

  // Avvia accettazione
  service.startAcceptance(screenAlwaysOnTop: false);
  isAccepting = true;

  // Polling ogni 300ms
  Timer? pollingTimer;
  pollingTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
    if (isAccepting) service.seeAmountAccepted();
  });

  // Apri modal
  final int? totalVersato = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _VersamentoDialog(
      insertedNotifier: insertedNotifier,
      onTermina: () async {
        if (isStopping) return;
        isStopping  = true;
        isAccepting = false;
        pollingTimer?.cancel();
        service.stopAcceptance(); // #J# → risposta gestita da onStopAcceptanceComplete
      },
      onAnnulla: () async {
        if (isStopping) return;
        isStopping  = true;
        isAccepting = false;
        pollingTimer?.cancel();
        service.cancel(); // #!#
        if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(null);
      },
    ),
  );

  // Cleanup timer residuo
  pollingTimer?.cancel();

  // Ripristina i callbacks originali
  service.onCashInserted           = prevOnCashInserted;
  service.onStopAcceptanceComplete = prevOnStopAcceptanceComplete;
  service.onError                  = prevOnError;
  service.onWarning                = prevOnWarning;

  // Risultato
  if (totalVersato != null && totalVersato > 0) {
    final euro = (totalVersato / 100).toStringAsFixed(2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Versamento completato: €$euro'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _VersamentoDialog extends StatelessWidget {
  final ValueNotifier<int> insertedNotifier;
  final VoidCallback       onTermina;
  final VoidCallback       onAnnulla;

  const _VersamentoDialog({
    required this.insertedNotifier,
    required this.onTermina,
    required this.onAnnulla,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── ICONA + TITOLO ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    size: 42,
                    color: Colors.green.shade700,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Versamento',
                  style: TextStyle(
                    fontSize:   24,
                    fontWeight: FontWeight.bold,
                    color:      theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Inserire il contante nella cassa.\nPremere "Termina" al termine.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:    theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),

                const SizedBox(height: 28),

                // ── IMPORTO INSERITO (live) ─────────────────────────
                Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color:        Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Importo inserito',
                        style: TextStyle(
                          fontSize: 13,
                          color:    Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: insertedNotifier,
                        builder: (_, cents, __) {
                          final euro = (cents / 100).toStringAsFixed(2);
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Text(
                              '€ $euro',
                              key: ValueKey(cents),
                              style: TextStyle(
                                fontSize:   48,
                                fontWeight: FontWeight.bold,
                                color:      Colors.green.shade700,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── INDICATORE ATTIVITÀ ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width:  14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'In attesa di contante...',
                      style: TextStyle(
                        fontSize: 13,
                        color:    theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── BOTTONE TERMINA ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTermina,
                    icon:  const Icon(Icons.check_circle_outline, size: 22),
                    label: const Text(
                      'Termina versamento',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── BOTTONE ANNULLA ──────────────────────────────────
                TextButton(
                  onPressed: onAnnulla,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Apre la modal di prelievo e gestisce tutto il flusso
Future<void> apriPrelievo(BuildContext context, CashlogyService service) async {
  final dispensedNotifier = ValueNotifier<int>(0);
  bool isStopping = false;

  // Salva callbacks originali
  final prevOnDispenseComplete = service.onDispenseComplete;
  final prevOnError            = service.onError;
  final prevOnWarning          = service.onWarning;

  // Override callbacks per questa operazione
  service.onDispenseComplete = (amount) {
    dispensedNotifier.value = amount;
    isStopping = false;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(amount);
  };

  service.onError = (msg) {
    isStopping = false;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text('Errore prelievo: $msg'),
        backgroundColor: Colors.red,
        behavior:        SnackBarBehavior.floating,
      ),
    );
  };

  service.onWarning = (msg) {
    // warning livelli — non blocchiamo il prelievo
  };

  // Apri modal per inserire l'importo
  final int? totalPrelevato = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PrelievoDialog(
      dispensedNotifier: dispensedNotifier,
      onConferma: (int amountCents) {
        if (isStopping || amountCents <= 0) return;
        isStopping = true;
        service.dispense(
          amountCents:      amountCents,
          screenAlwaysOnTop: false,
          showScreen:        false,
          coinsOnly:         false,
        );
      },
      onAnnulla: () {
        if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(null);
      },
    ),
  );

  // Ripristina callbacks originali
  service.onDispenseComplete = prevOnDispenseComplete;
  service.onError            = prevOnError;
  service.onWarning          = prevOnWarning;

  // Risultato
  if (totalPrelevato != null && totalPrelevato > 0) {
    final euro = (totalPrelevato / 100).toStringAsFixed(2);
    LogService.instance().saveLog('Prelievo', 'Prelevati $euro','');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text('✅ Prelievo completato: €$euro'),
        backgroundColor: Colors.green,
        behavior:        SnackBarBehavior.floating,
        duration:        const Duration(seconds: 4),
      ),
    );
  }
}

class _PrelievoDialog extends StatefulWidget {
  final ValueNotifier<int> dispensedNotifier;
  final void Function(int amountCents) onConferma;
  final VoidCallback onAnnulla;

  const _PrelievoDialog({
    required this.dispensedNotifier,
    required this.onConferma,
    required this.onAnnulla,
  });

  @override
  State<_PrelievoDialog> createState() => _PrelievoDialogState();
}

class _PrelievoDialogState extends State<_PrelievoDialog> {
  final TextEditingController _ctrl = TextEditingController();

  // Fase: 'input' → l'utente digita l'importo
  //       'dispensing' → la macchina sta erogando
  //       'done' → erogazione completata
  String _fase = 'input';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _conferma() {
    final text   = _ctrl.text.replaceAll(',', '.');
    final double? euro = double.tryParse(text);
    if (euro == null || euro <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Inserire un importo valido'),
          backgroundColor: Colors.orange,
          behavior:        SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int cents = (euro * 100).round();

    setState(() => _fase = 'dispensing');

    // Ascolta il completamento per aggiornare la fase
    widget.dispensedNotifier.addListener(_onDispensed);

    widget.onConferma(cents);
  }

  void _onDispensed() {
    if (widget.dispensedNotifier.value > 0) {
      widget.dispensedNotifier.removeListener(_onDispensed);
      if (mounted) setState(() => _fase = 'done');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _fase == 'input'
                  ? _buildInput(theme)
                  : _fase == 'dispensing'
                      ? _buildDispensing(theme)
                      : _buildDone(theme),
            ),
          ),
        ),
      ),
    );
  }

  // ── FASE 1: INPUT IMPORTO ────────────────────────────────────
  Widget _buildInput(ThemeData theme) {
    return Column(
      key: const ValueKey('input'),
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:  Colors.orange.shade50,
            shape:  BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_circle_up_outlined,
            size:  42,
            color: Colors.orange.shade700,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Prelievo',
          style: TextStyle(
            fontSize:   24,
            fontWeight: FontWeight.bold,
            color:      theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Inserire l\'importo da prelevare.\nLa cassa erogherà il contante richiesto.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color:    theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),

        const SizedBox(height: 28),

        // ── CAMPO IMPORTO ──────────────────────────────────────
        TextField(
          controller:  _ctrl,
          autofocus:   true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign:   TextAlign.center,
          style: TextStyle(
            fontSize:   36,
            fontWeight: FontWeight.bold,
            color:      theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixText:  '€ ',
            prefixStyle: TextStyle(
              fontSize:   36,
              fontWeight: FontWeight.bold,
              color:      Colors.orange.shade600,
            ),
            hintText:  '0,00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.orange.shade400,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical:   18,
            ),
          ),
          onSubmitted: (_) => _conferma(),
        ),

        const SizedBox(height: 24),

        // ── BOTTONI ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onAnnulla,
                icon:  const Icon(Icons.close, size: 20),
                label: const Text('Annulla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _conferma,
                icon:  const Icon(Icons.arrow_circle_up, size: 20),
                label: const Text(
                  'Preleva',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── FASE 2: EROGAZIONE IN CORSO ──────────────────────────────
  Widget _buildDispensing(ThemeData theme) {
    return Column(
      key: const ValueKey('dispensing'),
      mainAxisSize: MainAxisSize.min,
      children: [

        const SizedBox(height: 12),

        SizedBox(
          width:  72,
          height: 72,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            color: Colors.orange.shade600,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Erogazione in corso...',
          style: TextStyle(
            fontSize:   22,
            fontWeight: FontWeight.bold,
            color:      theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Attendere il contante dalla cassa.',
          style: TextStyle(
            fontSize: 14,
            color:    theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),

        const SizedBox(height: 12),

        // Importo richiesto
        Text(
          '€ ${(double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize:   42,
            fontWeight: FontWeight.bold,
            color:      Colors.orange.shade600,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── FASE 3: COMPLETATO ───────────────────────────────────────
  Widget _buildDone(ThemeData theme) {
    return Column(
      key: const ValueKey('done'),
      mainAxisSize: MainAxisSize.min,
      children: [

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size:  52,
            color: Color(0xFF16A34A),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Prelievo completato',
          style: TextStyle(
            fontSize:   24,
            fontWeight: FontWeight.bold,
            color:      theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        ValueListenableBuilder<int>(
          valueListenable: widget.dispensedNotifier,
          builder: (_, cents, __) => Text(
            '€ ${(cents / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize:   46,
              fontWeight: FontWeight.bold,
              color:      Color(0xFF16A34A),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Ritirare il contante dalla cassa.',
          style: TextStyle(
            fontSize: 14,
            color:    theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(widget.dispensedNotifier.value),
            icon:  const Icon(Icons.check, size: 22),
            label: const Text(
              'Chiudi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}



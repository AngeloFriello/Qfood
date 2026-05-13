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
  final Map<String, dynamic> hopperDetails;
  final Map<String, dynamic> dispenserDetails;
  final Map<String, dynamic> coinDispDetails;
  final Map<String, dynamic> raw;

  MachineLevels({
    this.totalRecycler = 0,
    this.recyclerDetails = const {},
    this.hopperDetails = const {},
    this.dispenserDetails = const {},
    this.coinDispDetails = const {},
    this.raw = const {},
  });

  factory MachineLevels.fromJson(Map<String, dynamic> json) {
    final recycler = json['recycler'] is Map<String, dynamic>
        ? json['recycler'] as Map<String, dynamic>
        : <String, dynamic>{};
    final hopper = json['hopper'] is Map<String, dynamic>
        ? json['hopper'] as Map<String, dynamic>
        : <String, dynamic>{};
    final dispenser = json['dispenser'] is Map<String, dynamic>
        ? json['dispenser'] as Map<String, dynamic>
        : <String, dynamic>{};
    final coinDisp = json['coinDisp'] is Map<String, dynamic>
        ? json['coinDisp'] as Map<String, dynamic>
        : <String, dynamic>{};
    return MachineLevels(
      totalRecycler: recycler['totalInRecycle'] ?? 0,
      recyclerDetails: recycler,
      hopperDetails: hopper,
      dispenserDetails: dispenser,
      coinDispDetails: coinDisp,
      raw: json,
    );
  }
}

typedef DenominationMap = Map<String, int>;
typedef RefillMap = Map<String, int>;
typedef ConfigMap = Map<String, dynamic>;

// ============================================================================
// 3. SERVICE LAYER (VNE PROTOCOL 3.04)
// ============================================================================

class VneService {
  final String ipAddress;
  final String opName;
  final http.Client _client;

  VneService(this.ipAddress, {this.opName = "CASSA_01", http.Client? client})
    : _client =
          client ??
          IOClient(
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

  void _ensureRange(String name, int value, int min, int max) {
    if (value < min || value > max) {
      throw ArgumentError('$name must be between $min and $max.');
    }
  }

  void _ensureWaitTimeout(String value) {
    if (value == '0') return;
    if (value.startsWith('0:')) {
      final secondsText = value.substring(2);
      final seconds = int.tryParse(secondsText);
      if (seconds == null || seconds < 1 || seconds > 59) {
        throw ArgumentError('waitTimeout seconds must be 01-59.');
      }
      return;
    }
    final minutes = int.tryParse(value);
    if (minutes == null) {
      throw ArgumentError('waitTimeout must be 0, 0:SS, or minutes 1-60.');
    }
    _ensureRange('waitTimeout minutes', minutes, 1, 60);
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

  // [Source 197] Type 5: Pending Payments List
  Future<Map<String, dynamic>> listPendingPayments({
    String? opNameOverride,
  }) async {
    return _send({"tipo": 5, "opName": opNameOverride ?? opName});
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

  // [Source 222] Type 13: Withdrawal by Denomination
  Future<Map<String, dynamic>> startWithdrawalByDenomination(
    int amountCents,
    DenominationMap listDenom, {
    String? comment,
    int? prelIncassato,
    String? opNameOverride,
  }) async {
    if (prelIncassato != null) {
      _ensureRange('prelIncassato', prelIncassato, 0, 1);
    }
    return _send({
      "tipo": 13,
      "importo": amountCents,
      "opName": opNameOverride ?? opName,
      if (comment != null) "commento": comment,
      if (prelIncassato != null) "prelIncassato": prelIncassato,
      "listDenom": listDenom,
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

  // [Source 357] Type 30: Start Refill
  Future<Map<String, dynamic>> startRefill({
    int? acceptAll,
    String? opNameOverride,
  }) async {
    if (acceptAll != null) {
      _ensureRange('acceptAll', acceptAll, 0, 1);
    }
    return _send({
      "tipo": 30,
      "opName": opNameOverride ?? opName,
      if (acceptAll != null) "acceptAll": acceptAll,
    });
  }

  // [Source 384] Type 31: End Refill
  Future<Map<String, dynamic>> endRefill({String? opNameOverride}) async {
    return _send({"tipo": 31, "opName": opNameOverride ?? opName});
  }

  // [Source 413] Type 32: Manual Refill
  Future<Map<String, dynamic>> manualRefill(
    RefillMap refill, {
    String? opNameOverride,
  }) async {
    return _send({
      "tipo": 32,
      "opName": opNameOverride ?? opName,
      "refill": refill,
    });
  }

  // [Source 458] Type 33: Polling Refill
  Future<Map<String, dynamic>> pollRefill() async {
    return _send({"tipo": 33});
  }

  // [Source 491] Type 40: Operator Login
  Future<Map<String, dynamic>> login({String? opNameOverride}) async {
    return _send({"tipo": 40, "opName": opNameOverride ?? opName});
  }

  // [Source 505] Type 41: Operator Logout
  Future<Map<String, dynamic>> logout({String? opNameOverride}) async {
    return _send({"tipo": 41, "opName": opNameOverride ?? opName});
  }

  // [Source 526] Type 50: Hopper Emptying
  Future<Map<String, dynamic>> startHopperEmptying({
    int? full,
    String? opNameOverride,
  }) async {
    if (full != null) {
      _ensureRange('full', full, 0, 1);
    }
    return _send({
      "tipo": 50,
      "opName": opNameOverride ?? opName,
      if (full != null) "full": full,
    });
  }

  // [Source 546] Type 51: Recycler Emptying
  Future<Map<String, dynamic>> startRecyclerEmptying({
    int? full,
    String? opNameOverride,
  }) async {
    if (full != null) {
      _ensureRange('full', full, 0, 1);
    }
    return _send({
      "tipo": 51,
      "opName": opNameOverride ?? opName,
      if (full != null) "full": full,
    });
  }

  // [Source 571] Type 52: Stacker Cancellation
  Future<Map<String, dynamic>> stackerCancellation(
    int peripheral, {
    String? opNameOverride,
  }) async {
    _ensureRange('peripheral', peripheral, 0, 2);
    return _send({
      "tipo": 52,
      "peripheral": peripheral,
      "opName": opNameOverride ?? opName,
    });
  }

  // [Source 592] Type 53: Emptying Polling
  Future<Map<String, dynamic>> pollEmptying() async {
    return _send({"tipo": 53});
  }

  // [Source 609] Type 54: Coin Dispenser Emptying
  Future<Map<String, dynamic>> startCoinDispenserEmptying(
    int num, {
    String? opNameOverride,
  }) async {
    _ensureRange('num', num, 1, 2);
    return _send({"tipo": 54, "num": num, "opName": opNameOverride ?? opName});
  }

  // [Source 628] Type 55: Door Opening
  Future<Map<String, dynamic>> openDoor({
    String? waitTimeout,
    int? port,
    String? opNameOverride,
  }) async {
    if (waitTimeout != null) {
      _ensureWaitTimeout(waitTimeout);
    }
    if (port != null) {
      _ensureRange('port', port, 1, 2);
    }
    return _send({
      "tipo": 55,
      "opName": opNameOverride ?? opName,
      if (waitTimeout != null) "wait_timeout": waitTimeout,
      if (port != null) "port": port,
    });
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

  // [Source 752] Type 70: Withdrawals List
  Future<Map<String, dynamic>> listWithdrawals(
    int startDate,
    int endDate, {
    String? opNameOverride,
  }) async {
    return _send({
      "tipo": 70,
      "start_date": startDate,
      "end_date": endDate,
      "opName": opNameOverride ?? opName,
    });
  }

  // [Source 773] Type 71: Payments List
  Future<Map<String, dynamic>> listPayments(
    int startDate,
    int endDate, {
    String? opNameOverride,
  }) async {
    return _send({
      "tipo": 71,
      "start_date": startDate,
      "end_date": endDate,
      "opName": opNameOverride ?? opName,
    });
  }

  // [Source 806] Type 72: Openings List
  Future<Map<String, dynamic>> listOpenings(
    int startDate,
    int endDate, {
    String? opNameOverride,
  }) async {
    return _send({
      "tipo": 72,
      "start_date": startDate,
      "end_date": endDate,
      "opName": opNameOverride ?? opName,
    });
  }

  // [Source 826] Type 73: Cash Closing List
  Future<Map<String, dynamic>> listCashClosings(
    int startDate,
    int endDate, {
    String? opNameOverride,
  }) async {
    return _send({
      "tipo": 73,
      "start_date": startDate,
      "end_date": endDate,
      "opName": opNameOverride ?? opName,
    });
  }

  // [Source 850] Type 80: Access Configuration Menu
  Future<Map<String, dynamic>> openConfigMenu(
    int userLevel, {
    String? opNameOverride,
    String? password,
  }) async {
    _ensureRange('userLevel', userLevel, 0, 2);
    return _send({
      "tipo": 80,
      "userLevel": userLevel,
      "opName": opNameOverride ?? opName,
      if (password != null) "password": password,
    });
  }

  // [Source 879] Type 81: Reboot/Shutdown
  Future<Map<String, dynamic>> rebootOrShutdown({
    required int restart,
    String? opNameOverride,
  }) async {
    _ensureRange('restart', restart, 0, 1);
    return _send({
      "tipo": 81,
      "opName": opNameOverride ?? opName,
      "restart": restart,
    });
  }

  // [Source 893] Type 82: Machine Version
  Future<Map<String, dynamic>> getVersion({String? opNameOverride}) async {
    return _send({"tipo": 82, "opName": opNameOverride ?? opName});
  }

  // [Source 924] Type 90: Peripherals Configuration
  Future<Map<String, dynamic>> configurePeripherals(
    ConfigMap config, {
    String? opNameOverride,
  }) async {
    return _send({
      "tipo": 90,
      "opName": opNameOverride ?? opName,
      "config": config,
    });
  }

  // [Source 959] Type 91: Software Configuration
  Future<Map<String, dynamic>> configureSoftware(
    ConfigMap config, {
    String? opNameOverride,
  }) async {
    return _send({
      "tipo": 91,
      "opName": opNameOverride ?? opName,
      "config": config,
    });
  }

  // [Source 994] Type 92: Petty Cash Setting
  Future<Map<String, dynamic>> setPettyCash(
    int pettyCashCents, {
    String? opNameOverride,
  }) async {
    final normalized = (pettyCashCents ~/ 100) * 100;
    return _send({
      "tipo": 92,
      "opName": opNameOverride ?? opName,
      "pettycash": normalized,
    });
  }

  // [Source 1013] Type 93: End Petty Cash Restore
  Future<Map<String, dynamic>> endPettyCashRestore() async {
    return _send({"tipo": 93});
  }

  // [Source 1031] Type 24: Reset Peripherals in Error
  Future<Map<String, dynamic>> resetPeripheralsInError(int periph) async {
    _ensureRange('periph', periph, 0, 1);
    return _send({"tipo": 24, "periph": periph});
  }
}

// ============================================================================
// 4. STATE MANAGEMENT
// ============================================================================

class VnePosState extends ChangeNotifier {
  final SharedPreferences _prefs;
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

  // Admin/maintenance results
  String adminResult = "";

  // Admin busy state — shown while any admin operation is in flight
  bool adminBusy = false;
  String adminBusyLabel = "";
  bool _adminCancelled = false;

  // Typed result caches — populated after each list/poll action
  List<Map<String, dynamic>> resultWithdrawals = [];
  List<Map<String, dynamic>> resultPayments = [];
  List<Map<String, dynamic>> resultOpenings = [];
  List<Map<String, dynamic>> resultClosings = [];
  List<String> resultPendingIds = [];
  Map<String, dynamic>? resultRefillPoll;
  Map<String, dynamic>? resultEmptyingPoll;
  Map<String, dynamic>? resultVersion;
  Map<String, dynamic>? resultCashClose;

  MachineLevels? machineStatus;
  final List<LogEntry> logs = [];
  bool _isPolling = false; // Flag to control recursive polling

  VnePosState(this._prefs) {
    machineIp = "127.0.0.1";

    _checkConnectivity();
  }

  VneService _service() => VneService(machineIp);

  String _prettyJson(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value?.toString() ?? "";
    }
  }

  void _setAdminResult(String text) {
    adminResult = text;
    notifyListeners();
  }

  Future<void> _runAdminAction(
    String label,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    adminBusy = true;
    adminBusyLabel = label;
    _adminCancelled = false;
    notifyListeners();
    addLog("$label...", type: LogType.network);
    try {
      final res = await action();
      if (_adminCancelled) return;
      if (res['req_status'] == 1) {
        addLog("$label OK", type: LogType.success);
      } else {
        addLog(
          "$label NACK: ${res['mess'] ?? 'Sconosciuto'}",
          type: LogType.error,
        );
      }
      _setAdminResult(_prettyJson(res));
    } catch (e) {
      if (_adminCancelled) return;
      addLog("$label Errore: $e", type: LogType.error);
      _setAdminResult("Errore: $e");
    } finally {
      adminBusy = false;
      adminBusyLabel = "";
      notifyListeners();
    }
  }

  /// Returns the result map, or null if cancelled/error.
  Future<Map<String, dynamic>?> _runAdminActionWithResult(
    String label,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    adminBusy = true;
    adminBusyLabel = label;
    _adminCancelled = false;
    notifyListeners();
    addLog("$label...", type: LogType.network);
    try {
      final res = await action();
      if (_adminCancelled) return null;
      if (res['req_status'] == 1) {
        addLog("$label OK", type: LogType.success);
      } else {
        addLog(
          "$label NACK: ${res['mess'] ?? 'Sconosciuto'}",
          type: LogType.error,
        );
      }
      _setAdminResult(_prettyJson(res));
      return res;
    } catch (e) {
      if (_adminCancelled) return null;
      addLog("$label Errore: $e", type: LogType.error);
      _setAdminResult("Errore: $e");
      return null;
    } finally {
      adminBusy = false;
      adminBusyLabel = "";
      notifyListeners();
    }
  }

  void cancelAdminOp() {
    _adminCancelled = true;
    adminBusy = false;
    adminBusyLabel = "";
    addLog("Operazione annullata.", type: LogType.warning);
    notifyListeners();
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
    machineIp = ip;
    _prefs.setString('vne_ip', ip);
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
      final service = VneService(machineIp);
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
        addLog(
          "Prelievo creato ID: $activeWithdrawalId",
          type: LogType.success,
        );

        // Start polling for withdrawal
        _isPolling = true;
        _pollWithdrawalLoop(service);
        return true;
      } else {
        withdrawalStatus = "ERROR";
        withdrawalErrorMessage =
            "Errore Codice ${res['mess'] ?? 'Sconosciuto'}";
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
          withdrawalErrorMessage =
              poll['mess'] ?? "Errore interno durante l'erogazione.";
          addLog(
            "Errore Prelievo: $withdrawalErrorMessage",
            type: LogType.error,
          );
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
    final res = await _runAdminActionWithResult(
      "Chiusura Cassa (Z-Report)",
      () => _service().closeCash(),
    );
    if (res != null && res['req_status'] == 1) {
      resultCashClose = res;
      notifyListeners();
      final totalIn = (res['total_in'] ?? 0) / 100.0;
      final totalOut = (res['total_out'] ?? 0) / 100.0;
      addLog(
        "Chiusura OK. Entrate: €${totalIn.toStringAsFixed(2)}, Uscite: €${totalOut.toStringAsFixed(2)}",
        type: LogType.success,
      );
    }
  }

  Future<void> operatorLogin({String? opNameOverride}) async {
    await _runAdminAction(
      "Login Operatore",
      () => _service().login(opNameOverride: opNameOverride),
    );
  }

  Future<void> operatorLogout({String? opNameOverride}) async {
    await _runAdminAction(
      "Logout Operatore",
      () => _service().logout(opNameOverride: opNameOverride),
    );
  }

  Future<void> startRefillAction({
    int? acceptAll,
    String? opNameOverride,
  }) async {
    await _runAdminAction(
      "Avvio Refill",
      () => _service().startRefill(
        acceptAll: acceptAll,
        opNameOverride: opNameOverride,
      ),
    );
  }

  Future<void> endRefillAction({String? opNameOverride}) async {
    await _runAdminAction(
      "Fine Refill",
      () => _service().endRefill(opNameOverride: opNameOverride),
    );
  }

  Future<void> manualRefillAction(
    RefillMap refill, {
    String? opNameOverride,
  }) async {
    await _runAdminAction(
      "Refill Manuale",
      () => _service().manualRefill(refill, opNameOverride: opNameOverride),
    );
  }

  Future<void> pollRefillAction() async {
    addLog("Polling Refill...", type: LogType.network);
    adminBusy = true;
    adminBusyLabel = "Polling Refill";
    _adminCancelled = false;
    notifyListeners();
    try {
      final res = await _service().pollRefill();
      if (_adminCancelled) return;
      _setAdminResult(_prettyJson(res));
      resultRefillPoll = res;
      if (res['req_status'] == 1) {
        final refillOn = res['refillOn'] ?? 0;
        final amountCents = res['amountRefill'] ?? 0;
        final amount = (amountCents / 100).toStringAsFixed(2);
        addLog(
          refillOn == 1
              ? "Refill in corso: € $amount"
              : "Refill completato: € $amount",
          type: LogType.success,
        );
      } else {
        addLog(
          "Polling Refill NACK: ${res['mess'] ?? 'Sconosciuto'}",
          type: LogType.error,
        );
      }
    } catch (e) {
      if (_adminCancelled) return;
      addLog("Polling Refill Errore: $e", type: LogType.error);
      _setAdminResult("Errore: $e");
    } finally {
      adminBusy = false;
      adminBusyLabel = "";
      notifyListeners();
    }
  }

  Future<void> startHopperEmptyingAction({int? full}) async {
    await _runAdminAction(
      "Svuotamento Hopper",
      () => _service().startHopperEmptying(full: full),
    );
  }

  Future<void> startRecyclerEmptyingAction({int? full}) async {
    await _runAdminAction(
      "Svuotamento Recycler",
      () => _service().startRecyclerEmptying(full: full),
    );
  }

  Future<void> startCoinDispenserEmptyingAction(int num) async {
    final res = await _runAdminActionWithResult(
      "Svuotamento Coin Dispenser",
      () => _service().startCoinDispenserEmptying(num),
    );

    if (res == null || res['req_status'] == 1) return;

    final mess = int.tryParse('${res['mess'] ?? ''}');
    if (mess == 101 || mess == 102) {
      addLog(
        "Tipo 54 non supportato dalla macchina/firmware. Provo fallback su Svuotamento Hopper.",
        type: LogType.warning,
      );
      await _runAdminAction(
        "Svuotamento Hopper (fallback)",
        () => _service().startHopperEmptying(full: 0),
      );
    }
  }

  Future<void> stackerCancellationAction(int peripheral) async {
    await _runAdminAction(
      "Reset Stacker",
      () => _service().stackerCancellation(peripheral),
    );
  }

  Future<void> pollEmptyingAction() async {
    addLog("Polling Svuotamento...", type: LogType.network);
    adminBusy = true;
    adminBusyLabel = "Polling Svuotamento";
    _adminCancelled = false;
    notifyListeners();
    try {
      final res = await _service().pollEmptying();
      if (_adminCancelled) return;
      _setAdminResult(_prettyJson(res));
      resultEmptyingPoll = res;
      if (res['req_status'] == 1) {
        final emptyStatus = res['empty_status'] ?? 0;
        addLog(
          emptyStatus == 1 ? "Svuotamento in corso" : "Svuotamento completato",
          type: LogType.success,
        );
      } else {
        addLog(
          "Polling Svuotamento NACK: ${res['mess'] ?? 'Sconosciuto'}",
          type: LogType.error,
        );
      }
    } catch (e) {
      if (_adminCancelled) return;
      addLog("Polling Svuotamento Errore: $e", type: LogType.error);
      _setAdminResult("Errore: $e");
    } finally {
      adminBusy = false;
      adminBusyLabel = "";
      notifyListeners();
    }
  }

  Future<void> openDoorAction({String? waitTimeout, int? port}) async {
    await _runAdminAction(
      "Apertura Porta",
      () => _service().openDoor(waitTimeout: waitTimeout, port: port),
    );
  }

  Future<void> openConfigMenuAction(
    int userLevel, {
    String? opNameOverride,
    String? password,
  }) async {
    await _runAdminAction(
      "Menu Configurazione",
      () => _service().openConfigMenu(
        userLevel,
        opNameOverride: opNameOverride,
        password: password,
      ),
    );
  }

  Future<void> rebootOrShutdownAction({required int restart}) async {
    await _runAdminAction(
      restart == 1 ? "Riavvio Sistema" : "Spegnimento Sistema",
      () => _service().rebootOrShutdown(restart: restart),
    );
  }

  Future<void> getVersionAction({String? opNameOverride}) async {
    final res = await _runAdminActionWithResult(
      "Versione Macchina",
      () => _service().getVersion(opNameOverride: opNameOverride),
    );
    if (res != null) {
      resultVersion = res;
      notifyListeners();
    }
  }

  Future<void> configurePeripheralsAction(
    ConfigMap config, {
    String? opNameOverride,
  }) async {
    await _runAdminAction(
      "Configura Periferiche",
      () => _service().configurePeripherals(
        config,
        opNameOverride: opNameOverride,
      ),
    );
  }

  Future<void> configureSoftwareAction(
    ConfigMap config, {
    String? opNameOverride,
  }) async {
    await _runAdminAction(
      "Configura Software",
      () =>
          _service().configureSoftware(config, opNameOverride: opNameOverride),
    );
  }

  Future<void> setPettyCashAction(int pettyCashCents) async {
    await _runAdminAction(
      "Imposta Petty Cash",
      () => _service().setPettyCash(pettyCashCents),
    );
  }

  Future<void> endPettyCashRestoreAction() async {
    await _runAdminAction(
      "Fine Ripristino Petty Cash",
      () => _service().endPettyCashRestore(),
    );
  }

  Future<void> pollRefundAction(String id) async {
    addLog("Polling Rimborso ID: $id...", type: LogType.network);
    try {
      final res = await _service().pollRefund(id);
      _setAdminResult(_prettyJson(res));
      if (res['req_status'] == 1) {
        final status = res['refund_status'] ?? '';
        final refunded = (res['refunded'] ?? 0) / 100.0;
        final toRefund = (res['toRefund'] ?? 0) / 100.0;
        addLog(
          "Rimborso $status — Rimborsato: €${refunded.toStringAsFixed(2)} / €${toRefund.toStringAsFixed(2)}",
          type: status == 'completed' ? LogType.success : LogType.info,
        );
      } else {
        addLog(
          "Polling Rimborso NACK: ${res['mess'] ?? 'Sconosciuto'}",
          type: LogType.error,
        );
      }
    } catch (e) {
      addLog("Polling Rimborso Errore: $e", type: LogType.error);
      _setAdminResult("Errore: $e");
    }
  }

  Future<void> resetPeripheralsInErrorAction(int periph) async {
    await _runAdminAction(
      "Reset Periferica in Errore",
      () => _service().resetPeripheralsInError(periph),
    );
  }

  Future<void> listPendingPaymentsAction() async {
    final res = await _runAdminActionWithResult(
      "Pagamenti in Attesa",
      () => _service().listPendingPayments(),
    );
    if (res != null) {
      final list = res['pending_list'];
      if (list is Map) {
        resultPendingIds = list.values.map((v) => v.toString()).toList();
      } else {
        resultPendingIds = [];
      }
      notifyListeners();
    }
  }

  Future<void> listWithdrawalsAction(int startDate, int endDate) async {
    final res = await _runAdminActionWithResult(
      "Lista Prelievi",
      () => _service().listWithdrawals(startDate, endDate),
    );
    if (res != null) {
      final list = res['withdrawals'];
      resultWithdrawals = list is List
          ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
      notifyListeners();
    }
  }

  Future<void> listPaymentsAction(int startDate, int endDate) async {
    final res = await _runAdminActionWithResult(
      "Lista Pagamenti",
      () => _service().listPayments(startDate, endDate),
    );
    if (res != null) {
      final list = res['payments'];
      resultPayments = list is List
          ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
      notifyListeners();
    }
  }

  Future<void> listOpeningsAction(int startDate, int endDate) async {
    final res = await _runAdminActionWithResult(
      "Lista Aperture",
      () => _service().listOpenings(startDate, endDate),
    );
    if (res != null) {
      final list = res['openings'];
      resultOpenings = list is List
          ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
      notifyListeners();
    }
  }

  Future<void> listCashClosingsAction(int startDate, int endDate) async {
    final res = await _runAdminActionWithResult(
      "Lista Chiusure",
      () => _service().listCashClosings(startDate, endDate),
    );
    if (res != null) {
      final list = res['closings'];
      resultClosings = list is List
          ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
      notifyListeners();
    }
  }

  Future<void> startWithdrawalByDenominationAction(
    double amount,
    DenominationMap listDenom, {
    String? comment,
    int? prelIncassato,
    String? opNameOverride,
  }) async {
    final cents = (amount * 100).round();
    await _runAdminAction(
      "Prelievo per Taglio",
      () => _service().startWithdrawalByDenomination(
        cents,
        listDenom,
        comment: comment,
        prelIncassato: prelIncassato,
        opNameOverride: opNameOverride,
      ),
    );
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
          addLog(
            "Fallback Windows: avvio tramite shell...",
            type: LogType.warning,
          );
          await Process.run('start', [urlStr], runInShell: true);
        } else {
          addLog(
            "Impossibile aprire il browser per: $urlStr",
            type: LogType.error,
          );
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
    return isAuthenticated ? const MainLayout() : MainLayout();
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
          // ── Sidebar navigation ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: NavigationRail(
              selectedIndex: state.selectedTab,
              onDestinationSelected: state.setTab,
              backgroundColor: Colors.transparent,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 16),
                child: Column(
                  children: const [
                    Icon(Icons.point_of_sale, size: 34, color: Colors.white),
                    SizedBox(height: 4),
                    Text(
                      "SDS POS",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 26,
              ),
              unselectedIconTheme: const IconThemeData(
                color: Colors.white54,
                size: 24,
              ),
              indicatorColor: Colors.white24,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('Cassa'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Prelievo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Report'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.build_circle_outlined),
                  selectedIcon: Icon(Icons.build_circle),
                  label: Text('Tecnico'),
                ),
              ],
            ),
          ),
          // ── Main content area ────────────────────────────────────────────
          Expanded(
            flex: 7,
            child: IndexedStack(
              index: state.selectedTab,
              children: const [
                SalesScreen(),
                WithdrawalScreen(),
                ReportsScreen(),
                AdminScreen(),
              ],
            ),
          ),
          // ── Status sidebar ───────────────────────────────────────────────
          const SizedBox(width: 280, child: StatusSidebar()),
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

// ============================================================================
// REPORTS SCREEN — operator-facing daily operations
// ============================================================================

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // ── Progress / date-range helpers (mirrored from AdminScreen) ──────────
  Future<void> _runWithProgress(
    BuildContext context, {
    required Future<void> Function() action,
    Widget Function(BuildContext)? resultBuilder,
  }) async {
    final state = context.read<VnePosState>();
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _VneProgressDialog(),
      );
    }
    await action();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (state.adminBusy) return;
    if (resultBuilder != null && context.mounted) {
      showDialog(context: context, builder: resultBuilder);
    }
  }

  Future<void> _pickDatesAndRun(
    BuildContext context, {
    required String title,
    required void Function(int start, int end) onSubmit,
  }) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
      helpText: title,
    );
    if (picked == null || !context.mounted) return;
    final startTs = picked.start.millisecondsSinceEpoch ~/ 1000;
    final endTs =
        picked.end
            .add(const Duration(hours: 23, minutes: 59, seconds: 59))
            .millisecondsSinceEpoch ~/
        1000;
    onSubmit(startTs, endTs);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                "Report",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _ConnectionChip(online: state.isMachineOnline),
            ],
          ),
          const SizedBox(height: 24),

          // ── Chiusura giornaliera ─────────────────────────────────────────
          _ReportCard(
            icon: Icons.receipt_long,
            iconColor: Colors.orange,
            title: "Chiusura Cassa (Z-Report)",
            subtitle:
                "Chiude il periodo contabile corrente e genera il riepilogo "
                "di entrate, uscite e incasso netto.",
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text("ESEGUI CHIUSURA CASSA"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: state.isMachineOnline
                    ? () => _runWithProgress(
                        context,
                        action: () => state.closeDay(),
                        resultBuilder: (ctx) =>
                            _CashCloseResultDialog(state: state),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Pagamenti in attesa ─────────────────────────────────────────
          _ReportCard(
            icon: Icons.pending_actions,
            iconColor: Colors.red,
            title: "Pagamenti in Attesa",
            subtitle:
                "Verifica se ci sono pagamenti avviati ma non ancora "
                "completati o annullati.",
            child: OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Controlla pagamenti sospesi"),
              onPressed: state.isMachineOnline
                  ? () => _runWithProgress(
                      context,
                      action: () => state.listPendingPaymentsAction(),
                      resultBuilder: (ctx) =>
                          _PendingPaymentsResultDialog(state: state),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // ── Storico ─────────────────────────────────────────────────────
          Text(
            "STORICO",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HistoryCard(
                icon: Icons.payments,
                label: "Lista Pagamenti",
                description: "Tutti i pagamenti nel periodo selezionato",
                color: Colors.green,
                enabled: state.isMachineOnline,
                onTap: () => _pickDatesAndRun(
                  context,
                  title: "Periodo pagamenti",
                  onSubmit: (s, e) => _runWithProgress(
                    context,
                    action: () => state.listPaymentsAction(s, e),
                    resultBuilder: (ctx) => _PaymentsResultDialog(state: state),
                  ),
                ),
              ),
              _HistoryCard(
                icon: Icons.account_balance_wallet,
                label: "Lista Prelievi",
                description: "Prelievi operatore nel periodo selezionato",
                color: Colors.blue,
                enabled: state.isMachineOnline,
                onTap: () => _pickDatesAndRun(
                  context,
                  title: "Periodo prelievi",
                  onSubmit: (s, e) => _runWithProgress(
                    context,
                    action: () => state.listWithdrawalsAction(s, e),
                    resultBuilder: (ctx) =>
                        _WithdrawalsResultDialog(state: state),
                  ),
                ),
              ),
              _HistoryCard(
                icon: Icons.receipt,
                label: "Lista Chiusure",
                description: "Chiusure cassa precedenti",
                color: Colors.deepPurple,
                enabled: state.isMachineOnline,
                onTap: () => _pickDatesAndRun(
                  context,
                  title: "Periodo chiusure",
                  onSubmit: (s, e) => _runWithProgress(
                    context,
                    action: () => state.listCashClosingsAction(s, e),
                    resultBuilder: (ctx) =>
                        _CashClosingsResultDialog(state: state),
                  ),
                ),
              ),
              _HistoryCard(
                icon: Icons.meeting_room,
                label: "Lista Aperture",
                description: "Aperture porta e accessi registrati",
                color: Colors.blueGrey,
                enabled: state.isMachineOnline,
                onTap: () => _pickDatesAndRun(
                  context,
                  title: "Periodo aperture",
                  onSubmit: (s, e) => _runWithProgress(
                    context,
                    action: () => state.listOpeningsAction(s, e),
                    resultBuilder: (ctx) => _OpeningsResultDialog(state: state),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card used in the Reports screen for a major action.
class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Small grid card for history date-filtered lists.
class _HistoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _HistoryCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: enabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: enabled
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? Colors.grey.shade400 : Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADMIN SCREEN — maintenance / technical operations only
// ============================================================================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _refundIdCtrl = TextEditingController();
  final _refundPollCtrl = TextEditingController();

  @override
  void dispose() {
    _refundIdCtrl.dispose();
    _refundPollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                "Manutenzione Tecnica",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _ConnectionChip(online: state.isMachineOnline),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Funzioni riservate al personale tecnico e agli operatori autorizzati.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Accesso Operatore ────────────────────────────────────────────
          _TechSection(
            title: "ACCESSO OPERATORE",
            children: [
              _TechBtn(
                icon: Icons.login,
                label: "Login",
                color: Colors.green,
                onTap: state.isMachineOnline
                    ? () => _showOperatorDialog(context, isLogin: true)
                    : null,
              ),
              _TechBtn(
                icon: Icons.logout,
                label: "Logout",
                color: Colors.orange,
                onTap: state.isMachineOnline
                    ? () => _showOperatorDialog(context, isLogin: false)
                    : null,
              ),
              _TechBtn(
                icon: Icons.lock_open,
                label: "Apri Porta",
                color: Colors.indigo,
                onTap: state.isMachineOnline
                    ? () => _showOpenDoorDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.settings_applications,
                label: "Menu Config",
                color: Colors.blueGrey,
                onTap: state.isMachineOnline
                    ? () => _showConfigMenuDialog(context)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Refill ───────────────────────────────────────────────────────
          _TechSection(
            title: "RIFORNIMENTO (REFILL)",
            children: [
              _TechBtn(
                icon: Icons.play_circle_fill,
                label: "Avvia Refill",
                color: Colors.green,
                onTap: state.isMachineOnline
                    ? () => _showStartRefillDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.stop_circle_outlined,
                label: "Termina Refill",
                color: Colors.orange,
                onTap: state.isMachineOnline
                    ? () => _runWithProgress(
                        context,
                        action: () => state.endRefillAction(),
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.playlist_add,
                label: "Refill Manuale",
                color: Colors.teal,
                onTap: state.isMachineOnline
                    ? () => _showManualRefillDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.radar,
                label: "Stato Refill",
                color: Colors.blue,
                onTap: state.isMachineOnline
                    ? () => _runWithProgress(
                        context,
                        action: () => state.pollRefillAction(),
                        resultBuilder: (ctx) =>
                            _RefillPollResultDialog(state: state),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Svuotamento ──────────────────────────────────────────────────
          _TechSection(
            title: "SVUOTAMENTO",
            children: [
              _TechBtn(
                icon: Icons.cleaning_services,
                label: "Svuota Hopper",
                color: Colors.deepOrange,
                onTap: state.isMachineOnline
                    ? () => _showEmptyingDialog(
                        context,
                        title: "Svuotamento Hopper",
                        onSubmit: (full) =>
                            state.startHopperEmptyingAction(full: full),
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.cleaning_services_outlined,
                label: "Svuota Recycler",
                color: Colors.deepOrange,
                onTap: state.isMachineOnline
                    ? () => _showEmptyingDialog(
                        context,
                        title: "Svuotamento Recycler",
                        onSubmit: (full) =>
                            state.startRecyclerEmptyingAction(full: full),
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.currency_exchange,
                label: "Svuota Monete",
                color: Colors.deepOrange,
                onTap: state.isMachineOnline
                    ? () => _showCoinDispenserDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.radar,
                label: "Stato Svuotamento",
                color: Colors.blue,
                onTap: state.isMachineOnline
                    ? () => _runWithProgress(
                        context,
                        action: () => state.pollEmptyingAction(),
                        resultBuilder: (ctx) =>
                            _EmptyingPollResultDialog(state: state),
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.restore_page,
                label: "Reset Stacker",
                color: Colors.red,
                onTap: state.isMachineOnline
                    ? () => _showStackerDialog(context)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Rimborso ─────────────────────────────────────────────────────
          _TechSection(
            title: "RIMBORSO",
            children: [
              _TechBtn(
                icon: Icons.replay,
                label: "Avvia Rimborso",
                color: Colors.red,
                onTap: state.isMachineOnline
                    ? () => _showRefundDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.savings,
                label: "Imposta Petty Cash",
                color: Colors.green,
                onTap: state.isMachineOnline
                    ? () => _showPettyCashDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.flag,
                label: "Fine Petty Cash",
                color: Colors.teal,
                onTap: state.isMachineOnline
                    ? () => _runWithProgress(
                        context,
                        action: () => state.endPettyCashRestoreAction(),
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.payments_outlined,
                label: "Prelievo per Taglio",
                color: Colors.teal,
                onTap: state.isMachineOnline
                    ? () => _showWithdrawalByDenomDialog(context)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Periferiche e Sistema ────────────────────────────────────────
          _TechSection(
            title: "PERIFERICHE E SISTEMA",
            children: [
              _TechBtn(
                icon: Icons.restart_alt_sharp,
                label: "Reset Periferica",
                color: Colors.redAccent,
                onTap: state.isMachineOnline
                    ? () => _showResetPeripheralDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.info_outline,
                label: "Versione SW",
                color: Colors.blue,
                onTap: state.isMachineOnline
                    ? () => _runWithProgress(
                        context,
                        action: () => state.getVersionAction(),
                        resultBuilder: (ctx) =>
                            _VersionResultDialog(state: state),
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.settings_input_component,
                label: "Config. Periferiche",
                color: Colors.blueGrey,
                onTap: state.isMachineOnline
                    ? () => _showConfigDialog(
                        context,
                        title: "Configura Periferiche",
                        onSubmit: (config) =>
                            state.configurePeripheralsAction(config),
                        hintText:
                            '{"cassette_denom_1": 500, "hopper_min_level_20": 300}',
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.settings_suggest,
                label: "Config. Software",
                color: Colors.blueGrey,
                onTap: state.isMachineOnline
                    ? () => _showConfigDialog(
                        context,
                        title: "Configura Software",
                        onSubmit: (config) =>
                            state.configureSoftwareAction(config),
                        hintText: '{"allow_refund": 1, "single_payment": 2}',
                      )
                    : null,
              ),
              _TechBtn(
                icon: Icons.sync,
                label: "Aggiorna Stato",
                color: Colors.blue,
                onTap: () => _runWithProgress(
                  context,
                  action: () => state.refreshStatus(),
                ),
              ),
              _TechBtn(
                icon: Icons.power_settings_new,
                label: "Riavvia / Spegni",
                color: Colors.red,
                onTap: state.isMachineOnline
                    ? () => _showRebootDialog(context)
                    : null,
              ),
              _TechBtn(
                icon: Icons.settings_ethernet,
                label: "Configura IP",
                color: Colors.grey,
                onTap: () => _showIpDialog(context),
              ),
              _TechBtn(
                icon: Icons.open_in_browser,
                label: "Tool Web VNE",
                color: Colors.purple,
                onTap: () => state.openWebTool(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PROGRESS DIALOG HELPER
  // Wraps any admin action: shows loading dialog with cancel, then shows
  // a result dialog when done.
  // -------------------------------------------------------------------------
  Future<void> _runWithProgress(
    BuildContext context, {
    required Future<void> Function() action,
    Widget Function(BuildContext)? resultBuilder,
  }) async {
    final state = context.read<VnePosState>();
    // Show the loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _VneProgressDialog(),
      );
    }
    // Run the action
    await action();
    // Close the loading dialog
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    // If cancelled, stop
    if (state.adminBusy) return;
    // Show result dialog if provided
    if (resultBuilder != null && context.mounted) {
      showDialog(context: context, builder: resultBuilder);
    }
  }

  void _showStartRefillDialog(BuildContext context) {
    int acceptAll = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Start Refill"),
          content: InputDecorator(
            decoration: const InputDecoration(
              labelText: "acceptAll",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButton<int>(
              value: acceptAll,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text("0 - Solo riciclabili")),
                DropdownMenuItem(value: 1, child: Text("1 - Accetta tutto")),
              ],
              onChanged: (val) => setState(() => acceptAll = val ?? 0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _runWithProgress(
                  context,
                  action: () => context.read<VnePosState>().startRefillAction(
                    acceptAll: acceptAll,
                  ),
                );
              },
              child: const Text("Avvia"),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualRefillDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text:
          '{"cassette_refill_1": 10, "hopper_refill_100": 50, "disp_refill_1": 200}',
    );
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Refill Manuale"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: "refill (JSON)",
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Valori = numero pezzi per tag. Es: hopper_refill_100",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final refill = _parseIntMap(ctrl.text);
                  Navigator.pop(ctx);
                  _runWithProgress(
                    context,
                    action: () =>
                        context.read<VnePosState>().manualRefillAction(refill),
                  );
                } catch (e) {
                  setState(() => errorText = e.toString());
                }
              },
              child: const Text("Invia"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmptyingDialog(
    BuildContext context, {
    required String title,
    required void Function(int full) onSubmit,
  }) {
    int full = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Modalita",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButton<int>(
              value: full,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text("0 - Totale")),
                DropdownMenuItem(value: 1, child: Text("1 - A petty cash")),
              ],
              onChanged: (val) => setState(() => full = val ?? 0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _runWithProgress(context, action: () async => onSubmit(full));
              },
              child: const Text("Avvia"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoinDispenserDialog(BuildContext context) {
    int num = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Svuota Coin Dispenser"),
          content: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Hopper",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButton<int>(
              value: num,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 1, child: Text("Hopper 1")),
                DropdownMenuItem(value: 2, child: Text("Hopper 2")),
              ],
              onChanged: (val) => setState(() => num = val ?? 1),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _runWithProgress(
                  context,
                  action: () => context
                      .read<VnePosState>()
                      .startCoinDispenserEmptyingAction(num),
                );
              },
              child: const Text("Avvia"),
            ),
          ],
        ),
      ),
    );
  }

  void _showStackerDialog(BuildContext context) {
    int peripheral = 2;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Reset Stacker"),
          content: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Periferica",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButton<int>(
              value: peripheral,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text("Cashbox Monete")),
                DropdownMenuItem(value: 1, child: Text("Stacker Banconote")),
                DropdownMenuItem(value: 2, child: Text("Entrambi")),
              ],
              onChanged: (val) => setState(() => peripheral = val ?? 2),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _runWithProgress(
                  context,
                  action: () => context
                      .read<VnePosState>()
                      .stackerCancellationAction(peripheral),
                );
              },
              child: const Text("Reset"),
            ),
          ],
        ),
      ),
    );
  }

  void _showOperatorDialog(BuildContext context, {required bool isLogin}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLogin ? "Login Operatore" : "Logout Operatore"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: "opName (opzionale)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              final opName = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
              Navigator.pop(ctx);
              _runWithProgress(
                context,
                action: isLogin
                    ? () => context.read<VnePosState>().operatorLogin(
                        opNameOverride: opName,
                      )
                    : () => context.read<VnePosState>().operatorLogout(
                        opNameOverride: opName,
                      ),
              );
            },
            child: Text(isLogin ? "Login" : "Logout"),
          ),
        ],
      ),
    );
  }

  void _showOpenDoorDialog(BuildContext context) {
    final waitCtrl = TextEditingController(text: "0");
    final portCtrl = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Apertura Porta"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: waitCtrl,
                decoration: InputDecoration(
                  labelText: "wait_timeout (0, 0:SS, minuti)",
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portCtrl,
                decoration: const InputDecoration(
                  labelText: "port (1 o 2, opzionale)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final waitTimeout = waitCtrl.text.trim();
                final port = portCtrl.text.trim().isEmpty
                    ? null
                    : int.tryParse(portCtrl.text.trim());
                if (waitTimeout.isEmpty) {
                  setState(() => errorText = "wait_timeout obbligatorio");
                  return;
                }
                if (portCtrl.text.trim().isNotEmpty && port == null) {
                  setState(() => errorText = "port non valido");
                  return;
                }
                Navigator.pop(ctx);
                _runWithProgress(
                  context,
                  action: () => context.read<VnePosState>().openDoorAction(
                    waitTimeout: waitTimeout,
                    port: port,
                  ),
                );
              },
              child: const Text("Apri"),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfigMenuDialog(BuildContext context) {
    int userLevel = 0;
    final opCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Menu Configurazione"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: "userLevel",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButton<int>(
                  value: userLevel,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("0 - Base")),
                    DropdownMenuItem(value: 1, child: Text("1 - Refill")),
                    DropdownMenuItem(value: 2, child: Text("2 - Admin")),
                  ],
                  onChanged: (val) => setState(() => userLevel = val ?? 0),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: opCtrl,
                decoration: const InputDecoration(
                  labelText: "opName",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "password (solo livello 1/2)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final opName = opCtrl.text.trim().isEmpty
                    ? null
                    : opCtrl.text.trim();
                final pwd = pwdCtrl.text.trim().isEmpty
                    ? null
                    : pwdCtrl.text.trim();
                Navigator.pop(ctx);
                _runWithProgress(
                  context,
                  action: () =>
                      context.read<VnePosState>().openConfigMenuAction(
                        userLevel,
                        opNameOverride: opName,
                        password: pwd,
                      ),
                );
              },
              child: const Text("Apri"),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPeripheralDialog(BuildContext context) {
    int periph = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Reset Periferica in Errore"),
          content: InputDecorator(
            decoration: const InputDecoration(
              labelText: "periph",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButton<int>(
              value: periph,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text("0 - Monete")),
                DropdownMenuItem(value: 1, child: Text("1 - Banconote")),
              ],
              onChanged: (val) => setState(() => periph = val ?? 0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _runWithProgress(
                  context,
                  action: () => context
                      .read<VnePosState>()
                      .resetPeripheralsInErrorAction(periph),
                );
              },
              child: const Text("Reset"),
            ),
          ],
        ),
      ),
    );
  }

  void _showRebootDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reboot / Spegnimento"),
        content: const Text(
          "Confermare l'operazione. La macchina potrebbe interrompere le operazioni in corso.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runWithProgress(
                context,
                action: () => context
                    .read<VnePosState>()
                    .rebootOrShutdownAction(restart: 1),
              );
            },
            child: const Text("Riavvia"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runWithProgress(
                context,
                action: () => context
                    .read<VnePosState>()
                    .rebootOrShutdownAction(restart: 0),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Spegni"),
          ),
        ],
      ),
    );
  }

  void _showPettyCashDialog(BuildContext context) {
    final ctrl = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Imposta Petty Cash"),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: "Importo (euro)",
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(ctrl.text.trim());
                if (amount == null || amount <= 0) {
                  setState(() => errorText = "Importo non valido");
                  return;
                }
                final cents = (amount * 100).round();
                Navigator.pop(ctx);
                _runWithProgress(
                  context,
                  action: () =>
                      context.read<VnePosState>().setPettyCashAction(cents),
                );
              },
              child: const Text("Salva"),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfigDialog(
    BuildContext context, {
    required String title,
    required void Function(Map<String, dynamic>) onSubmit,
    required String hintText,
  }) {
    final ctrl = TextEditingController(text: hintText);
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: "config (JSON)",
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final config = _parseConfigMap(ctrl.text);
                  Navigator.pop(ctx);
                  _runWithProgress(
                    context,
                    action: () async => onSubmit(config),
                  );
                } catch (e) {
                  setState(() => errorText = e.toString());
                }
              },
              child: const Text("Invia"),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawalByDenomDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final mapCtrl = TextEditingController(
      text: '{"banconota_2000": 2, "monete_100": 5}',
    );
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Prelievo per Taglio"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                decoration: InputDecoration(
                  labelText: "Importo (euro)",
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mapCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "listDenom (JSON)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  setState(() => errorText = "Importo non valido");
                  return;
                }
                try {
                  final map = _parseIntMap(mapCtrl.text);
                  Navigator.pop(ctx);
                  _runWithProgress(
                    context,
                    action: () => context
                        .read<VnePosState>()
                        .startWithdrawalByDenominationAction(amount, map),
                  );
                } catch (e) {
                  setState(() => errorText = e.toString());
                }
              },
              child: const Text("Avvia"),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _parseIntMap(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw ArgumentError(
        "JSON deve essere un oggetto con coppie chiave/valore",
      );
    }
    final result = <String, int>{};
    decoded.forEach((key, value) {
      if (key is! String) {
        throw ArgumentError("Chiave non valida: $key");
      }
      if (value is int) {
        result[key] = value;
        return;
      }
      if (value is num) {
        result[key] = value.round();
        return;
      }
      final parsed = int.tryParse(value.toString());
      if (parsed == null) {
        throw ArgumentError("Valore non valido per $key");
      }
      result[key] = parsed;
    });
    return result;
  }

  Map<String, dynamic> _parseConfigMap(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw ArgumentError(
        "JSON deve essere un oggetto con coppie chiave/valore",
      );
    }
    final result = <String, dynamic>{};
    decoded.forEach((key, value) {
      if (key is! String) {
        throw ArgumentError("Chiave non valida: $key");
      }
      if (value is num) {
        result[key] = value.round();
        return;
      }
      final parsed = int.tryParse(value.toString());
      result[key] = parsed ?? value.toString();
    });
    return result;
  }

  void _showRefundDialog(BuildContext context) {
    final idCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Avvia Rimborso"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                labelText: "ID Transazione (lasciare vuoto per l'ultima)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Il sistema restituirà il contante inserito nella transazione.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text("Avvia Rimborso"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              final id = idCtrl.text.trim();
              Navigator.pop(ctx);
              _runWithProgress(
                context,
                action: () => context.read<VnePosState>().startRefundFlow(id),
              );
            },
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

// ── _TechSection ─────────────────────────────────────────────────────────────
/// Groups related tech buttons under a labelled section.
class _TechSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _TechSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Wrap(spacing: 10, runSpacing: 10, children: children),
      ],
    );
  }
}

// ── _TechBtn ──────────────────────────────────────────────────────────────────
/// A compact action button used in the Manutenzione screen.
class _TechBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _TechBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: 160,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: enabled ? color : Colors.grey,
          side: BorderSide(
            color: enabled
                ? color.withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashTile extends StatelessWidget {
  final String name;
  final int value;
  final int qty;
  final int alert;
  final bool isCoins;
  const _CashTile({
    required this.name,
    required this.value,
    required this.qty,
    this.alert = 0,
    this.isCoins = false,
  });

  @override
  Widget build(BuildContext context) {
    Color alertColor = Colors.green;
    IconData alertIcon = Icons.check_circle_outline;
    if (alert == 1) {
      alertColor = Colors.orange;
      alertIcon = Icons.warning_amber_outlined;
    } else if (alert == 2) {
      alertColor = Colors.red;
      alertIcon = Icons.error_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      color: Colors.grey.shade50,
      child: ListTile(
        dense: true,
        leading: Icon(
          isCoins ? Icons.toll_outlined : Icons.savings_outlined,
          color: const Color(0xFF1976D2),
        ),
        title: Text(name, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          isCoins
              ? "Taglio: ${value >= 100 ? '€${(value / 100).toStringAsFixed(value % 100 == 0 ? 0 : 2)}' : '$value¢'}"
              : "Taglio: €${(value / 100).toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(alertIcon, color: alertColor, size: 16),
            const SizedBox(width: 6),
            Chip(
              label: Text("$qty pz", style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
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
    if (state.withdrawalStatus == "COMPLETED" ||
        state.withdrawalStatus == "ERROR") {
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
    if( state.withdrawalStatus =='COMPLETED')  LogService.instance().saveLog('Prelievo cassa','Prelevati ${state.withdrawalAmount}','');

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
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // ── Machine status header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isMachineOnline
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.isMachineOnline
                            ? "Macchina connessa"
                            : "Macchina offline",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: state.isMachineOnline
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: "Aggiorna stato",
                      onPressed: () =>
                          context.read<VnePosState>().refreshStatus(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  "IP: ${state.machineIp}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Machine levels ───────────────────────────────────────────────
          if (state.machineStatus != null)
            _LevelsSummary(levels: state.machineStatus!)
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Dati macchina non disponibili.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),

          const Divider(height: 1),

          // ── Log header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.white,
            width: double.infinity,
            child: const Text(
              "Log di sistema",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),

          // ── Log list ────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: state.logs.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (ctx, i) {
                final log = state.logs[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(log.timestamp),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        log.message,
                        style: TextStyle(
                          fontSize: 11,
                          color: log.type == LogType.error
                              ? Colors.red.shade700
                              : log.type == LogType.success
                              ? Colors.green.shade700
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

          // ── Footer ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.white,
            child: const Text(
              "VNE Protocol 3.05",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact machine level summary shown in the sidebar.
class _LevelsSummary extends StatelessWidget {
  final MachineLevels levels;
  const _LevelsSummary({required this.levels});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Recycler
    if (levels.recyclerDetails.isNotEmpty) {
      rows.add(_sectionLabel("Recycler"));
      for (final k in levels.recyclerDetails.keys) {
        if (!k.startsWith('banconota_') || levels.recyclerDetails[k] is! Map) {
          continue;
        }
        final d = levels.recyclerDetails[k] as Map<String, dynamic>;
        rows.add(
          _CashTile(
            name: k.replaceAll('banconota_', '€ '),
            value: d['valore'] ?? 0,
            qty: d['quantita'] ?? 0,
            alert: d['alert'] ?? 0,
          ),
        );
      }
    }

    // Hopper
    if (levels.hopperDetails.isNotEmpty) {
      rows.add(_sectionLabel("Hopper Monete"));
      final denomKeys = levels.hopperDetails.keys.where(
        (k) => RegExp(r'^moneta_\d+$').hasMatch(k),
      );
      for (final k in denomKeys) {
        final qty = levels.hopperDetails[k] ?? 0;
        final denom = int.tryParse(k.replaceAll('moneta_', '')) ?? 0;
        rows.add(
          _CashTile(
            name: denom >= 100 ? '€${denom ~/ 100}' : '${denom}c',
            value: denom,
            qty: qty,
            isCoins: true,
          ),
        );
      }
    }

    // Dispenser
    if (levels.dispenserDetails.isNotEmpty) {
      rows.add(_sectionLabel("Dispenser"));
      for (final k in levels.dispenserDetails.keys) {
        if (!k.startsWith('banconota_') || levels.dispenserDetails[k] is! Map) {
          continue;
        }
        final d = levels.dispenserDetails[k] as Map<String, dynamic>;
        rows.add(
          _CashTile(
            name: k.replaceAll('banconota_', '€ '),
            value: d['valore'] ?? 0,
            qty: d['quantita'] ?? 0,
            alert: d['alert'] ?? 0,
          ),
        );
      }
    }

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          "Nessun livello disponibile.",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
          letterSpacing: 1.2,
        ),
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

// ============================================================================
// PROGRESS DIALOG — shown during any admin operation with a Cancel button
// ============================================================================
class _VneProgressDialog extends StatelessWidget {
  const _VneProgressDialog();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VnePosState>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              state.adminBusyLabel.isEmpty
                  ? "Operazione in corso..."
                  : state.adminBusyLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Attendere la risposta della macchina.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text("Annulla", style: TextStyle(color: Colors.red)),
              onPressed: () {
                context.read<VnePosState>().cancelAdminOp();
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RESULT DIALOGS — each operation type has a proper data display
// ============================================================================

/// Generic simple-info dialog used for operations that return no list data.
class _SimpleResultDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_InfoRow> rows;
  const _SimpleResultDialog({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 56),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...rows.map((r) => _buildInfoRow(r)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Chiudi"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          Text(
            row.value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: row.valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final Color valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor = Colors.black87});
}

/// Safely converts any API value (num or String) to a num.
num _toNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

/// Formats an integer cent value (e.g. 1500 → "€ 15.00").
String _fmtCents(dynamic v) => "€ ${(_toNum(v) / 100).toStringAsFixed(2)}";

/// Formats a Unix timestamp (seconds) to an Italian date-time string.
String _fmtTs(dynamic ts) {
  if (ts == null) return "-";
  final ms = _toNum(ts).toInt() * 1000;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateFormat('dd/MM/yyyy HH:mm').format(dt);
}

// --- Cash Closing result ---
class _CashCloseResultDialog extends StatelessWidget {
  final VnePosState state;
  const _CashCloseResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final r = state.resultCashClose;
    if (r == null) {
      return _SimpleResultDialog(
        title: "Chiusura Cassa",
        icon: Icons.error_outline,
        iconColor: Colors.red,
        rows: [const _InfoRow("Risultato", "Nessun dato disponibile")],
      );
    }
    return _SimpleResultDialog(
      title: "Chiusura Cassa (Z)",
      icon: Icons.receipt_long,
      iconColor: Colors.orange,
      rows: [
        _InfoRow("Data chiusura", _fmtTs(r['date'])),
        _InfoRow("Periodo dal", _fmtTs(r['start_date'])),
        _InfoRow(
          "Totale incassato",
          _fmtCents(r['total_in']),
          valueColor: Colors.green.shade700,
        ),
        _InfoRow(
          "Totale resto erogato",
          _fmtCents(r['total_out']),
          valueColor: Colors.red.shade700,
        ),
        _InfoRow("Totale pagamenti", _fmtCents(r['total_payments'])),
        _InfoRow("Refill operatori", _fmtCents(r['total_operator_in'])),
        _InfoRow("Prelievi operatori", _fmtCents(r['total_operator_out'])),
        _InfoRow("Contenuto totale", _fmtCents(r['total_content'])),
        _InfoRow(
          "Fondo cassa",
          "€ ${r['petty_cash'] ?? '-'}",
          valueColor: Colors.blue.shade700,
        ),
        _InfoRow("Incasso netto", _fmtCents(r['cash_income'])),
      ],
    );
  }
}

// --- Version result ---
class _VersionResultDialog extends StatelessWidget {
  final VnePosState state;
  const _VersionResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final r = state.resultVersion;
    return _SimpleResultDialog(
      title: "Versione Software",
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      rows: [
        _InfoRow(
          "Versione",
          r?['version']?.toString() ?? 'N/D',
          valueColor: Colors.blue.shade700,
        ),
        _InfoRow("IP Macchina", state.machineIp),
      ],
    );
  }
}

// --- Refill poll result ---
class _RefillPollResultDialog extends StatelessWidget {
  final VnePosState state;
  const _RefillPollResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final r = state.resultRefillPoll;
    final inProgress = _toNum(r?['refillOn']).toInt() == 1;
    final amount = (r?['amountRefill'] ?? 0);
    return _SimpleResultDialog(
      title: "Stato Refill",
      icon: inProgress ? Icons.hourglass_top : Icons.check_circle_outline,
      iconColor: inProgress ? Colors.orange : Colors.green,
      rows: [
        _InfoRow(
          "Stato",
          inProgress ? "In corso" : "Completato",
          valueColor: inProgress ? Colors.orange : Colors.green,
        ),
        _InfoRow("Importo inserito", _fmtCents(amount)),
      ],
    );
  }
}

// --- Emptying poll result ---
class _EmptyingPollResultDialog extends StatelessWidget {
  final VnePosState state;
  const _EmptyingPollResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final r = state.resultEmptyingPoll;
    final inProgress = _toNum(r?['empty_status']).toInt() == 1;
    return _SimpleResultDialog(
      title: "Stato Svuotamento",
      icon: inProgress ? Icons.hourglass_top : Icons.check_circle_outline,
      iconColor: inProgress ? Colors.orange : Colors.green,
      rows: [
        _InfoRow(
          "Stato",
          inProgress ? "In corso" : "Completato",
          valueColor: inProgress ? Colors.orange : Colors.green,
        ),
      ],
    );
  }
}

// --- Pending payments result ---
class _PendingPaymentsResultDialog extends StatelessWidget {
  final VnePosState state;
  const _PendingPaymentsResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final ids = state.resultPendingIds;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Pagamenti in Attesa (${ids.length})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (ids.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "Nessun pagamento in attesa.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: ids.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(
                        Icons.receipt,
                        color: Color(0xFF1976D2),
                      ),
                      title: Text("ID: ${ids[i]}"),
                      subtitle: Text("Posizione in coda: ${i + 1}"),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Chiudi"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Withdrawals list result ---
class _WithdrawalsResultDialog extends StatelessWidget {
  final VnePosState state;
  const _WithdrawalsResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final list = state.resultWithdrawals;
    return _ListResultDialog(
      title: "Lista Prelievi",
      icon: Icons.account_balance_wallet,
      iconColor: Colors.blue,
      count: list.length,
      emptyMessage: "Nessun prelievo nel periodo selezionato.",
      itemBuilder: (_, i) {
        final w = list[i];
        final date = _fmtTs(w['date']);
        final value = _fmtCents(w['value']);
        final op = w['operator']?.toString() ?? '-';
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(Icons.arrow_upward, color: Colors.blue, size: 20),
          ),
          title: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
          subtitle: Text("$date  •  Operatore: $op"),
        );
      },
      total: list.fold<int>(0, (sum, w) => sum + _toNum(w['value']).toInt()),
    );
  }
}

// --- Payments list result ---
class _PaymentsResultDialog extends StatelessWidget {
  final VnePosState state;
  const _PaymentsResultDialog({required this.state});

  static Color _statusColor(String? s) {
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'returned':
      case 'deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String _statusLabel(String? s) {
    switch (s) {
      case 'completed':
        return 'Completato';
      case 'partial':
        return 'Parziale';
      case 'returned':
        return 'Restituito';
      case 'deleted':
        return 'Eliminato';
      case 'pending':
        return 'In attesa';
      default:
        return s ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = state.resultPayments;
    return _ListResultDialog(
      title: "Lista Pagamenti",
      icon: Icons.payments,
      iconColor: Colors.green,
      count: list.length,
      emptyMessage: "Nessun pagamento nel periodo selezionato.",
      itemBuilder: (_, i) {
        final p = list[i];
        final status = p['status']?.toString();
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _statusColor(status).withValues(alpha: 0.15),
            child: Icon(Icons.payment, color: _statusColor(status), size: 20),
          ),
          title: Row(
            children: [
              Text(
                _fmtCents(p['amount']),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            "${_fmtTs(p['date'])}  •  Ins: ${_fmtCents(p['inserted'])}  Resto: ${_fmtCents(p['rest'])}",
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: false,
        );
      },
      total: list
          .where((p) => p['status'] == 'completed' || p['status'] == 'partial')
          .fold<int>(0, (sum, p) => sum + _toNum(p['amount']).toInt()),
    );
  }
}

// --- Openings list result ---
class _OpeningsResultDialog extends StatelessWidget {
  final VnePosState state;
  const _OpeningsResultDialog({required this.state});

  static String _typeLabel(int t) {
    switch (t) {
      case 0:
        return 'Porta aperta fisicamente';
      case 1:
        return 'Porta chiusa fisicamente';
      case 2:
        return 'Autorizzazione apertura';
      default:
        return 'Tipo $t';
    }
  }

  static IconData _typeIcon(int t) {
    switch (t) {
      case 0:
        return Icons.door_back_door_outlined;
      case 1:
        return Icons.door_front_door;
      case 2:
        return Icons.verified_user_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = state.resultOpenings;
    return _ListResultDialog(
      title: "Lista Aperture",
      icon: Icons.meeting_room,
      iconColor: Colors.blueGrey,
      count: list.length,
      emptyMessage: "Nessuna apertura nel periodo selezionato.",
      showTotal: false,
      itemBuilder: (_, i) {
        final o = list[i];
        final t = _toNum(o['type']).toInt();
        return ListTile(
          leading: Icon(_typeIcon(t), color: Colors.blueGrey),
          title: Text(_typeLabel(t)),
          subtitle: Text(
            "${_fmtTs(o['date'])}  •  Operatore: ${o['operator'] ?? '-'}",
          ),
        );
      },
    );
  }
}

// --- Cash closings list result ---
class _CashClosingsResultDialog extends StatelessWidget {
  final VnePosState state;
  const _CashClosingsResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final list = state.resultClosings;
    return _ListResultDialog(
      title: "Lista Chiusure Cassa",
      icon: Icons.receipt_long,
      iconColor: Colors.deepPurple,
      count: list.length,
      emptyMessage: "Nessuna chiusura nel periodo selezionato.",
      showTotal: false,
      itemBuilder: (_, i) {
        final c = list[i];
        return ExpansionTile(
          leading: const Icon(Icons.receipt_long, color: Colors.deepPurple),
          title: Text(
            _fmtTs(c['date']),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "Incassato: ${_fmtCents(c['total_in'])}  Operatore: ${c['operator'] ?? '-'}",
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _DetailRow("Dal", _fmtTs(c['start_date'])),
                  _DetailRow("Totale incassato", _fmtCents(c['total_in'])),
                  _DetailRow("Totale resto", _fmtCents(c['total_out'])),
                  _DetailRow(
                    "Totale pagamenti",
                    _fmtCents(c['total_payments']),
                  ),
                  _DetailRow(
                    "Refill operatori",
                    _fmtCents(c['total_operator_in']),
                  ),
                  _DetailRow(
                    "Prelievi operatori",
                    _fmtCents(c['total_operator_out']),
                  ),
                  _DetailRow("Contenuto totale", _fmtCents(c['total_content'])),
                  _DetailRow("Fondo cassa", "€ ${c['petty_cash'] ?? '-'}"),
                  _DetailRow("Incasso netto", _fmtCents(c['cash_income'])),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Shared scrollable list dialog used by all list result dialogs.
class _ListResultDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final int count;
  final String emptyMessage;
  final IndexedWidgetBuilder itemBuilder;
  final int? total;
  final bool showTotal;

  const _ListResultDialog({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.emptyMessage,
    required this.itemBuilder,
    this.total,
    this.showTotal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      "$count elementi",
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: count == 0
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            emptyMessage,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: count,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: itemBuilder,
                    ),
            ),
            // Footer total + close
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  if (showTotal && total != null) ...[
                    Text(
                      "Totale: ${_fmtCents(total)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Chiudi"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

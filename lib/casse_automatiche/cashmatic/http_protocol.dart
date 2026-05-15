import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ==============================================================================
// 1. LOW LEVEL LOGIC (UNCHANGED FUNCTIONALITY)
// ==============================================================================

class CashMaticHTTPsOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

enum CashMaticOperation {
  newTransaction,
  cancelTransaction,
  withdrawal,
  setFloatLevelCoins,
  setFloatLevelNotes,
  setMaxLevelCoins,
  setMaxLevelNotes,
  refill,
  stopRefill,
  emptyAll,
  emptyCoins,
  emptyNotes,
  floatAll,
  floatCoins,
  floatNotes,
  emptyCashBoxAll,
  emptyCashboxCoins,
  emptyCashboxNotes,
}

abstract class CashmaticBase {
  String? endpoint;
  int? timeout;
  String? _authToken;
  DateTime? _tokenExpiry;
  String? _storedUsername;
  String? _storedPassword;
  
  Future<bool> authenticate(String username, String password);
  Future<bool> renewToken();
  Future<bool> ensureValidToken();
  Future<Map<String, dynamic>?> launchOperationAndWait(
    CashMaticOperation operation,
    Function(Map<String, dynamic>? dataStream) streamedDataDelegate, {
    Map<String, dynamic>? payload,
    int waitTime = 2,
    bool launchAndListenAsync = false,
  });
}

mixin CashmaticMixin on CashmaticBase {
  Future<Map<String, dynamic>?> request(
    String pathname, {
    Map<String, dynamic>? payload,
    bool isRetry = false,
  }) async {
    Map<String, dynamic>? data;
    try {
      String fullEndpoint = "${endpoint!}$pathname";
      
      // Build headers with auth token if available (per certification: no expired/invalid tokens)
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      
      http.Response response = await http
          .post(
            Uri.parse(fullEndpoint),
            headers: headers,
            body: payload != null ? json.encode(payload) : "{}",
          )
          .timeout(
            Duration(seconds: timeout!),
            onTimeout: () => http.Response('{"error": "timeout"}', 800),
          );

      // Handle 401 Unauthorized - token may be revoked/expired
      if (response.statusCode == 401 && !isRetry) {
        if (kDebugMode) print('Token unauthorized (401), attempting re-login...');
        bool reAuthSuccess = await renewToken();
        if (reAuthSuccess) {
          // Retry the request with new token
          return await request(pathname, payload: payload, isRetry: true);
        }
      }
      
      if (response.statusCode == 200 || response.statusCode == 800) {
        data = json.decode(response.body);
        
        // Check for token-related errors in response body and retry
        if (data != null && !isRetry) {
          final String? message = data['message']?.toString().toLowerCase();
          final int? code = data['code'];
          
          // Common token error indicators
          if (code != 0 && message != null && 
              (message.contains('token') || 
               message.contains('unauthorized') ||
               message.contains('not authorized') ||
               message.contains('session expired') ||
               message.contains('authentication'))) {
            if (kDebugMode) print('Token error detected: $message, attempting re-login...');
            bool reAuthSuccess = await renewToken();
            if (reAuthSuccess) {
              // Retry the request with new token
              return await request(pathname, payload: payload, isRetry: true);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return data;
  }
}


class Cashmatic extends CashmaticBase with CashmaticMixin {
  Cashmatic({required String endpoint, required int timeout}) {
    super.endpoint = endpoint;
    super.timeout = timeout;
  }

  static Cashmatic? _instance;
  static Cashmatic instance(String endpoint, int timeout) {
    if (_instance == null) {
      _instance = Cashmatic(endpoint: endpoint, timeout: timeout);
    } else {
      _instance!.timeout = timeout; // aggiorna solo il timeout
    }
    return _instance!;
  }

  @override
  Future<bool> authenticate(String username, String password) async {
    bool isAuthenticated = false;
    try {
      // Store credentials for token renewal
      _storedUsername = username;
      _storedPassword = password;
      
      Map<String, dynamic>? response = await request(
        "/api/user/Login",
        payload: {"username": username, "password": password},
      );
      
      if (response != null && response['code'] == 0) {
        isAuthenticated = true;
        _authToken = response['data']?['token'];
        // Set token expiry (typically tokens last ~1 hour, renew at 50 minutes)
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return isAuthenticated;
  }
  
  /// Re-authenticate using stored credentials (just login again)
  @override
  Future<bool> renewToken() async {
    // Simply re-authenticate with stored credentials
    if (_storedUsername != null && _storedPassword != null) {
      if (kDebugMode) print('Re-authenticating with stored credentials...');
      return await authenticate(_storedUsername!, _storedPassword!);
    }
    return false;
  }
  
  /// Ensure we have a valid token before making API calls
  @override
  Future<bool> ensureValidToken() async {
    if (_authToken == null) return false;
    
    // Check if token is about to expire or already expired
    if (_tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!)) {
      return await renewToken();
    }
    return true;
  }

  @override
  Future<Map<String, dynamic>?> launchOperationAndWait(
    CashMaticOperation operation,
    Function(Map<String, dynamic>? dataStream) streamedDataDelegate, {
    Map<String, dynamic>? payload,
    int waitTime = 2,
    bool launchAndListenAsync = false,
  }) async {
    Map<String, dynamic>? data;
    try {
      late String pathname;
      switch (operation) {
        case CashMaticOperation.newTransaction:
          pathname = "/api/transaction/StartPayment";
          break;
        case CashMaticOperation.cancelTransaction:
          pathname = "/api/transaction/CancelPayment";
          break;
        case CashMaticOperation.withdrawal:
          pathname = "/api/transaction/StartWithdrawal";
          break;
        case CashMaticOperation.refill:
          pathname = "/api/transaction/StartRefill";
          break;
        case CashMaticOperation.stopRefill:
          pathname = "/api/transaction/StopRefill";
          break;
        case CashMaticOperation.emptyCoins:
          pathname = "/api/transaction/StartEmptyCoins";
          break;
        case CashMaticOperation.emptyNotes:
          pathname = "/api/transaction/StartEmptyNotes"; //TRASFERISCE NEL BOX DI RISERVA
          break;
        case CashMaticOperation.emptyAll:
          pathname = "/api/transaction/StartEmptyAll";
          break;
        case CashMaticOperation.emptyCashBoxAll:
          pathname = "/api/transaction/StartEmptyCashboxAll";
          break;
        case CashMaticOperation.emptyCashboxCoins:
          pathname = "/api/transaction/StartEmptyCashboxCoins";
          break;
        case CashMaticOperation.emptyCashboxNotes:
          pathname = "/api/transaction/StartEmptyCashboxNotes"; // Fixed: was incorrectly using StartEmptyCashboxAll
          break;
        case CashMaticOperation.setFloatLevelCoins:
          pathname = "/api/device/SetFloatLevelCoins";
          break;
        case CashMaticOperation.setFloatLevelNotes:
          pathname = "/api/device/SetFloatLevelNotes";
          break;
        case CashMaticOperation.setMaxLevelCoins:
          pathname = "/api/device/SetMaxLevelCoins";
          break;
        case CashMaticOperation.setMaxLevelNotes:
          pathname = "/api/device/SetMaxLevelNotes";
          break;
        case CashMaticOperation.floatAll:
          pathname = "/api/transaction/StartFloatAll";
          break;
        case CashMaticOperation.floatCoins:
          pathname = "/api/transaction/StartFloatCoins";
          break;
        case CashMaticOperation.floatNotes:
          pathname = "/api/transaction/StartFloatNotes";
          break;
      }

      // Ensure token is valid before making API calls
      await ensureValidToken();
      
      Map<String, dynamic>? response;
      bool asyncRequestSucceeded = false;
      
      if (launchAndListenAsync) {
        // For async mode, still await the initial request to check for errors
        // This prevents polling ActiveTransaction when the initial request fails
        response = await request(pathname, payload: payload);
        if (response != null && response['code'] == 0) {
          asyncRequestSucceeded = true;
        } else if (response != null && response['code'] != 0) {
          // Return error immediately - don't poll ActiveTransaction for failed requests
          return {
            'error': true,
            'code': response['code'],
            'message': response['message'] ?? 'Unknown error',
            'data': response['data'],
          };
        }
      } else {
        response = await request(pathname, payload: payload);
        
        // Handle API errors and return error information
        if (response != null && response['code'] != 0) {
          return {
            'error': true,
            'code': response['code'],
            'message': response['message'] ?? 'Unknown error',
            'data': response['data'],
          };
        }
      }

      if (asyncRequestSucceeded || (response != null && response['code'] == 0)) {
        bool stillRunning = true;
        int safeLoopValue = 50;
        int loops = 0;

        await Future.delayed(Duration(seconds: waitTime));

        while (stillRunning && (loops < safeLoopValue)) {
          Map<String, dynamic>? activeTransactionData = await request(
            "/api/device/ActiveTransaction",
          );
          if (activeTransactionData == null ||
              activeTransactionData['code'] != 0) {
            throw Error();
          }

          if (activeTransactionData['data']['operation'] == "idle") {
            stillRunning = false;
          } else {
            streamedDataDelegate(activeTransactionData);
          }
          await Future.delayed(Duration(seconds: 1));
          loops++;
        }
        data = await request("/api/device/LastTransaction");
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return data;
  }
}

// ==============================================================================
// 2. MODERN UI WIDGETS (TOUCH FRIENDLY POS)
// ==============================================================================

/// A custom numeric keypad for touchscreens (No keyboard needed)
class POSNumpad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final Function() onBackspace;
  final Function() onClear;
  final bool isDecimalMode;

  const POSNumpad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onClear,
    this.isDecimalMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow(['C', '0', '<']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (key == 'C' || key == '<')
                      ? Colors.red.shade50
                      : Colors.white,
                  foregroundColor: (key == 'C' || key == '<')
                      ? Colors.red
                      : Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  if (key == '<') {
                    onBackspace();
                  } else if (key == 'C') {
                    onClear();
                  } else {
                    onKeyPressed(key);
                  }
                },
                child: key == '<'
                    ? Icon(Icons.backspace_outlined)
                    : Text(
                        key,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A card widget for dashboard actions
class DashboardActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.3,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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

class CashMaticHttpProtocolPage extends StatefulWidget {
  const CashMaticHttpProtocolPage({super.key});

  @override
  CashMaticHttpProtocolPageState createState() =>
      CashMaticHttpProtocolPageState();
}

class CashMaticHttpProtocolPageState extends State<CashMaticHttpProtocolPage> {
  // Configurable settings (per certification requirement: lines 9-10)
  String endpoint = "https://127.0.0.1:50301";
  String username = "cashmatic";
  String password = "admin";
  int timeout = 20;

  bool isAuthenticated = false;
  bool isLoading = false;
  String statusMessage = "Disconnesso";
  
  // Device error state - to disable payments (per certification: lines 22-23)
  bool hasDeviceError = false;
  String? deviceErrorMessage;
  
  // Payment queue management (per certification: line 26)
  List<Map<String, dynamic>> paymentQueue = [];
  bool isProcessingQueue = false;

  // Currency Formatter Helper
  String formatCurrency(int cents) {
    return "€ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}";
  }

  @override
  void initState() {
    super.initState();
    // Auto-login on startup (Optional for UX)
    _performLogin();
  }

  Future<void> _performLogin() async {
    setState(() {
      isLoading = true;
      statusMessage = "Connessione in corso...";
    });

    bool auth = await Cashmatic.instance(
      endpoint,
      timeout,
    ).authenticate(username, password);

    if (mounted) {
      setState(() {
        isLoading = false;
        isAuthenticated = auth;
        statusMessage = auth ? "Connesso a CashMatic" : "Errore Autenticazione";
      });

      if (!auth) {
        _showErrorSnack("Impossibile connettersi alla macchina.");
      }
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Show error popup dialog for API errors (per Cashmatic certification requirements)
  void _showErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 50),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  
  /// Show not dispensed popup when machine couldn't dispense full amount
  void _showNotDispensedPopup(int notDispensedAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
        title: const Text("Importo Non Erogato"),
        content: Text(
          "Attenzione: La macchina non è riuscita ad erogare ${formatCurrency(notDispensedAmount)}.\n\n"
          "Si prega di verificare la disponibilità di contanti nella macchina.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CHIUDI"),
          ),
        ],
      ),
    );
  }
  
  /// Show withdrawal result popup (success or failure)
  void _showWithdrawalResultPopup({
    required bool success,
    int? dispensedAmount,
    int? notDispensedAmount,
    String? errorMessage,
  }) {
    if (success) {
      LogService.instance().saveLog('Prelievo', 'Prelevati $dispensedAmount','');
      // Success popup with green check and dispensed amount
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          title: const Text("Prelievo Completato"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Il prelievo è stato completato con successo!",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      "Importo Erogato",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      formatCurrency(dispensedAmount ?? 0),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (notDispensedAmount != null && notDispensedAmount > 0) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Importo non erogato: ${formatCurrency(notDispensedAmount)}",
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    } else {
      // Failure popup with red error icon
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error, color: Colors.red, size: 60),
          title: const Text("Prelievo Fallito"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Si è verificato un errore durante il prelievo:",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  errorMessage ?? "Errore sconosciuto",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CHIUDI",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  /// Handle API error responses and show appropriate popups (per certification: line 13-14)
  /// Handles: "Other operation active", "Device error", "User not allowed", etc.
  void _handleApiError(Map<String, dynamic>? response) {
    if (response == null) return;
    
    final String errorMessage = response['message'] ?? 'Errore sconosciuto';
    final int errorCode = response['code'] ?? -1;
    
    // Check for device error - disable payments (per certification: line 22-23)
    if (errorMessage.toLowerCase().contains('device error') || 
        errorMessage.toLowerCase().contains('errore dispositivo')) {
      setState(() {
        hasDeviceError = true;
        deviceErrorMessage = errorMessage;
      });
      _showErrorPopup(
        "Errore Dispositivo",
        "$errorMessage\n\nI pagamenti sono stati disabilitati. Contattare l'assistenza tecnica.",
      );
      return;
    }
    
    // Handle specific error types
    if (errorMessage.toLowerCase().contains('other operation active') ||
        errorMessage.toLowerCase().contains('altra operazione attiva')) {
      _showErrorPopup(
        "Operazione in Corso",
        "Un'altra operazione è già attiva. Attendere il completamento prima di procedere.",
      );
    } else if (errorMessage.toLowerCase().contains('user not allowed') ||
               errorMessage.toLowerCase().contains('utente non autorizzato')) {
      _showErrorPopup(
        "Accesso Negato",
        "L'utente non è autorizzato ad eseguire questa operazione.",
      );
    } else if (errorMessage.toLowerCase().contains('cannot process command') ||
               errorMessage.toLowerCase().contains('impossibile elaborare')) {
      _showErrorPopup(
        "Comando Non Eseguibile",
        errorMessage,
      );
    } else {
      // Generic error popup
      _showErrorPopup(
        "Errore API (Codice: $errorCode)",
        errorMessage,
      );
    }
  }
  
  /// Show settings configuration dialog (per certification: line 9-10)
  void _showSettingsDialog() {
    final TextEditingController ipController = TextEditingController(text: endpoint);
    final TextEditingController userController = TextEditingController(text: username);
    final TextEditingController passController = TextEditingController(text: password);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.indigo),
            SizedBox(width: 10),
            Text("Configurazione CashMatic"),
          ],
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: InputDecoration(
                  labelText: "Indirizzo IP / Endpoint",
                  hintText: "https://192.168.1.100:50301",
                  prefixIcon: Icon(Icons.computer),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ANNULLA"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                endpoint = ipController.text.trim();
                username = userController.text.trim();
                password = passController.text;
                // Reset instance to apply new settings
                Cashmatic._instance = null;
                isAuthenticated = false;
              });
              Navigator.pop(context);
              _performLogin(); // Re-authenticate with new settings
            },
            child: Text("SALVA E CONNETTI"),
          ),
        ],
      ),
    );
  }
  
  /// Clear device error and re-enable payments
  void _clearDeviceError() {
    setState(() {
      hasDeviceError = false;
      deviceErrorMessage = null;
    });
    _showErrorSnack("Pagamenti riabilitati");
  }
  
  /// Add payment to queue (per certification: line 26)
  void _addToPaymentQueue(int amount, {Map<String, dynamic>? metadata}) {
    setState(() {
      paymentQueue.add({
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata,
        'status': 'pending',
      });
    });
  }
  
  /// Process next payment in queue
  Future<void> _processPaymentQueue() async {
    if (isProcessingQueue || paymentQueue.isEmpty) return;
    if (hasDeviceError) {
      _showErrorPopup(
        "Pagamenti Disabilitati",
        "I pagamenti sono disabilitati a causa di un errore del dispositivo.",
      );
      return;
    }
    
    setState(() => isProcessingQueue = true);
    
    final payment = paymentQueue.first;
    await runTransactionUI(payment['amount']);
    
    setState(() {
      paymentQueue.removeAt(0);
      isProcessingQueue = false;
    });
    
    // Continue processing if more in queue
    if (paymentQueue.isNotEmpty) {
      _processPaymentQueue();
    }
  }

  // --- UI ACTIONS ---

  // 1. New Transaction Logic
  void startTransactionFlow() {
    // Check for device error - payments disabled (per certification: line 22-23)
    if (hasDeviceError) {
      _showErrorPopup(
        "Pagamenti Disabilitati",
        "I pagamenti sono stati disabilitati a causa di un errore del dispositivo.\n\n"
        "Errore: ${deviceErrorMessage ?? 'Dispositivo non disponibile'}",
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AmountInputModal(
        title: "Nuova Transazione",
        confirmLabel: "PAGA",
        onConfirmed: (int amountCents) async {
          Navigator.pop(context); // Close input
          await runTransactionUI(amountCents);
        },
      ),
    );
  }

  // 2. Withdrawal Logic
  void _startWithdrawalFlow() {
    // Check for device error - payments disabled (per certification: line 22-23)
    if (hasDeviceError) {
      _showErrorPopup(
        "Pagamenti Disabilitati",
        "I pagamenti sono stati disabilitati a causa di un errore del dispositivo.\n\n"
        "Errore: ${deviceErrorMessage ?? 'Dispositivo non disponibile'}",
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AmountInputModal(
        title: "Prelievo",
        confirmLabel: "PRELEVA",
        isWithdrawal: true,
        onConfirmed: (int amountCents) async {
          Navigator.pop(context); // Close input
          await _runDispenseUI(
            CashMaticOperation.withdrawal,
            payload: {"amount": amountCents},
            title: "Erogazione Prelievo",
          );
        },
      ),
    );
  }

  // 3. Generic Action Wrappers (Refilled/Empty)
  Future<void> runTransactionUI( int amount ) async {
    int insertedAmount = 0;
    int dispensedAmount = 0;
    int notDispensedAmount = 0;
    bool isCancelled = false;
    bool operationStarted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateModal) {
            // Trigger operation once when dialog opens
            if (!operationStarted && !isCancelled) {
              operationStarted = true;
              Cashmatic.instance(endpoint, timeout).launchOperationAndWait(
                CashMaticOperation.newTransaction,
                (data) {
                  if (data != null && data['data'] != null && dialogContext.mounted) {
                    setStateModal(() {
                      insertedAmount = data['data']['inserted'] ?? 0;
                      dispensedAmount = data['data']['dispensed'] ?? 0;
                      notDispensedAmount = data['data']['notDispensed'] ?? 0;
                    });
                  }
                },
                payload: {"amount": amount},
                launchAndListenAsync: true, // Async so UI updates
              ).then((finalData) {
                if (!isCancelled && dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Close modal on finish
                  
                  // Handle API errors with popup (per certification: line 13-14)
                  if (finalData != null && finalData['error'] == true) {
                    if (mounted) _handleApiError(finalData);
                    return;
                  }
                  
                  // Show notDispensed popup if there's an undispensed amount (per certification requirements)
                  final int finalNotDispensed = finalData?['data']?['notDispensed'] ?? 0;
                  if (finalNotDispensed > 0 && mounted) {
                    _showNotDispensedPopup(finalNotDispensed);
                  }
                  
                  // Show Summary
                  if (mounted) _showTransactionResult(finalData);
                }
              });
            }

            int remainingToPay = amount - insertedAmount;
            if (remainingToPay < 0) remainingToPay = 0;
            
            // Per certification: Cannot cancel if requested amount has been reached
            bool canCancel = insertedAmount < amount;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.all(20),
              content: Container(
                width: 500,
                height: 450,
                child: Column(
                  children: [
                    Text(
                      "Pagamento in Corso",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildStatusRow(
                      "Totale da Pagare",
                      formatCurrency(amount),
                      true,
                    ),
                    Divider(),
                    _buildStatusRow(
                      "Inserito",
                      formatCurrency(insertedAmount),
                      false,
                      Colors.green,
                    ),
                    _buildStatusRow(
                      "Mancante",
                      formatCurrency(remainingToPay),
                      false,
                      Colors.red,
                    ),
                    _buildStatusRow(
                      "Resto Erogato",
                      formatCurrency(dispensedAmount),
                      false,
                      Colors.blue,
                    ),
                    if (notDispensedAmount > 0)
                      _buildStatusRow(
                        "Non Erogato",
                        formatCurrency(notDispensedAmount),
                        false,
                        Colors.orange,
                      ),
                    Spacer(),
                    // Cancel button - disabled when amount is reached (per certification)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canCancel ? Colors.red : Colors.grey,
                        ),
                        onPressed: canCancel ? () async {
                          isCancelled = true;
                          
                          // Close the current payment dialog
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          
                          // Show cancellation/dispense dialog to track money being returned
                          // This ensures the user sees their inserted amount being dispensed
                          if (mounted) await _showCancellationDispenseDialog(insertedAmount);
                        } : null,
                        child: Text(
                          canCancel 
                            ? "ANNULLA TRANSAZIONE" 
                            : "IMPORTO RAGGIUNTO - ANNULLAMENTO NON DISPONIBILE",
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: canCancel ? 18 : 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a dialog during cancellation to display the amount being dispensed back to user
  /// This ensures that when a user cancels (e.g., inserted 1€ for a 2€ payment),
  /// they see their money being returned
  Future<void> _showCancellationDispenseDialog(int insertedAmount) async {
    int dispensedAmount = 0;
    int notDispensedAmount = 0;
    bool operationStarted = false;
    bool operationCompleted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateModal) {
            // Trigger cancellation operation once
            if (!operationStarted) {
              operationStarted = true;
              Cashmatic.instance(endpoint, timeout).launchOperationAndWait(
                CashMaticOperation.cancelTransaction,
                (data) {
                  if (data != null && data['data'] != null && dialogContext.mounted) {
                    setStateModal(() {
                      dispensedAmount = data['data']['dispensed'] ?? 0;
                      notDispensedAmount = data['data']['notDispensed'] ?? 0;
                    });
                  }
                },
              ).then((result) {
                if (dialogContext.mounted) {
                  // Handle errors
                  if (result != null && result['error'] == true) {
                    final errorMessage = result['message'] ?? 'Errore sconosciuto';
                    Navigator.pop(dialogContext);
                    if (mounted) _showErrorPopup("Impossibile Annullare", errorMessage);
                    return;
                  }
                  
                  // Get final values from result
                  final int finalDispensed = result?['data']?['dispensed'] ?? dispensedAmount;
                  final int finalNotDispensed = result?['data']?['notDispensed'] ?? 0;
                  
                  setStateModal(() {
                    dispensedAmount = finalDispensed;
                    notDispensedAmount = finalNotDispensed;
                    operationCompleted = true;
                  });
                  
                  // Show warning if not all money was dispensed
                  if (finalNotDispensed > 0) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        if (mounted) _showNotDispensedPopup(finalNotDispensed);
                      }
                    });
                  }
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.all(20),
              content: Container(
                width: 450,
                height: 350,
                child: Column(
                  children: [
                    Icon(
                      operationCompleted ? Icons.check_circle : Icons.cancel_outlined,
                      size: 60,
                      color: operationCompleted ? Colors.green : Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      operationCompleted 
                          ? "Transazione Annullata" 
                          : "Annullamento in Corso...",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      operationCompleted
                          ? "La transazione è stata annullata"
                          : "Restituzione importo inserito...",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 30),
                    if (insertedAmount > 0) ...[
                      _buildStatusRow(
                        "Importo Inserito",
                        formatCurrency(insertedAmount),
                        false,
                        Colors.blue,
                      ),
                      Divider(),
                    ],
                    _buildStatusRow(
                      "Importo Restituito",
                      formatCurrency(dispensedAmount),
                      false,
                      Colors.green,
                    ),
                    if (notDispensedAmount > 0)
                      _buildStatusRow(
                        "Non Restituito",
                        formatCurrency(notDispensedAmount),
                        false,
                        Colors.red,
                      ),
                    Spacer(),
                    if (!operationCompleted)
                      CircularProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            "CHIUDI",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runDispenseUI(
    CashMaticOperation op, {
    Map<String, dynamic>? payload,
    required String title,
  }) async {
    int dispensed = 0;
    int notDispensedAmount = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateModal) {
            // Trigger once
            if (dispensed == 0) {
              Cashmatic.instance(endpoint, timeout).launchOperationAndWait(
                op,
                (data) {
                  if (data != null && data['data'] != null && dialogContext.mounted) {
                    setStateModal(() {
                      dispensed = data['data']['dispensed'] ?? 0;
                      notDispensedAmount = data['data']['notDispensed'] ?? 0;
                    });
                  }
                },
                payload: payload,
                launchAndListenAsync: true,
              ).then((finalData) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  
                  // Handle API errors with failure popup
                  if (finalData != null && finalData['error'] == true) {
                    if (mounted) {
                      _showWithdrawalResultPopup(
                        success: false,
                        errorMessage: finalData['message'] ?? 'Errore sconosciuto',
                      );
                    }
                    return;
                  }
                  
                  // Get final values
                  final int finalDispensed = finalData?['data']?['dispensed'] ?? dispensed;
                  final int finalNotDispensed = finalData?['data']?['notDispensed'] ?? 0;
                  
                  // Show success popup with dispensed amount
                  if (mounted) {
                    _showWithdrawalResultPopup(
                      success: true,
                      dispensedAmount: finalDispensed,
                      notDispensedAmount: finalNotDispensed,
                    );
                  }
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Container(
                width: 400,
                height: 300,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text("Erogato", style: TextStyle(color: Colors.grey)),
                    Text(
                      formatCurrency(dispensed),
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runRefillUI() async {
    int inserted = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            // Trigger start
            if (inserted == 0) {
              Cashmatic.instance(endpoint, timeout).launchOperationAndWait(
                CashMaticOperation.refill,
                (data) {
                  if (data != null && data['data'] != null) {
                    setStateModal(() {
                      inserted = data['data']['inserted'] ?? 0;
                    });
                  }
                },
                launchAndListenAsync: true,
                waitTime: 3,
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Container(
                width: 400,
                height: 350,
                child: Column(
                  children: [
                    Text(
                      "Ricarica (Versamento)",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Inserire monete e banconote",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Spacer(),
                    Text(
                      formatCurrency(inserted),
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          Cashmatic.instance(
                            endpoint,
                            timeout,
                          ).launchOperationAndWait(
                            CashMaticOperation.stopRefill,
                            (_) {},
                          );
                          Navigator.pop(context);
                        },
                        child: Text(
                          "TERMINA VERSAMENTO",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionResult(Map<String, dynamic>? data) {
    if (data == null) return;
    int requested = data['data']['requested'] ?? 0;
    int inserted = data['data']['inserted'] ?? 0;
    bool success = inserted >= requested;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? "Pagamento Riuscito" : "Pagamento Incompleto"),
        icon: Icon(
          success ? Icons.check_circle : Icons.warning,
          color: success ? Colors.green : Colors.orange,
          size: 50,
        ),
        content: Text(
          success
              ? "L'operazione è stata completata con successo."
              : "L'importo inserito non copre il totale richiesto.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CHIUDI"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value, [
    bool isTotal = false,
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 20 : 18,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      // Login Screen with Settings (per certification: line 9-10)
      return Scaffold(
        backgroundColor: const Color(0xFF1976D2),
        body: Stack(
          children: [
            // Settings button in top right
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 32),
                tooltip: "Configurazione connessione",
                onPressed: _showSettingsDialog,
              ),
            ),
            // Main login card
            Center(
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
                      const SizedBox(height: 16),
                      // Show current endpoint
                      Text(
                        endpoint,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 32),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.login),
                              label: const Text("CONNETTI"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 20,
                                ),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: _performLogin,
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.settings, size: 18),
                              label: const Text("Configura Connessione"),
                              onPressed: _showSettingsDialog,
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Text(statusMessage, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Main Dashboard
    return Scaffold(
      appBar: AppBar(
        backgroundColor: hasDeviceError ? Colors.red : Colors.indigo,
        title: Text(
          hasDeviceError ? "⚠️ PAGAMENTI DISABILITATI" : "Cassa Principale", 
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Device error indicator and reset button
          if (hasDeviceError)
            TextButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Riabilita", style: TextStyle(color: Colors.white)),
              onPressed: _clearDeviceError,
            ),
          // Queue indicator
          if (paymentQueue.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.queue, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${paymentQueue.length}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          // Status indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: hasDeviceError ? Colors.red.shade700 : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hasDeviceError ? "Errore" : "Online",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: "Configurazione",
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Operations
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  DashboardActionCard(
                    title: "Incasso / Vendita",
                    icon: Icons.payments,
                    color: Colors.green,
                    onTap: startTransactionFlow,
                  ),
                  DashboardActionCard(
                    title: "Prelievo",
                    icon: Icons.money_off,
                    color: Colors.orange,
                    onTap: _startWithdrawalFlow,
                  ),
                  DashboardActionCard(
                    title: "Versamento / Ricarica",
                    icon: Icons.input,
                    color: Colors.blue,
                    onTap: _runRefillUI,
                  ),
                  DashboardActionCard(
                    title: "Annulla Ultima",
                    icon: Icons.cancel,
                    color: Colors.red,
                    onTap: () {
                      Cashmatic.instance(
                        endpoint,
                        timeout,
                      ).launchOperationAndWait(
                        CashMaticOperation.cancelTransaction,
                        (_) {},
                      );
                      _showErrorSnack("Comando annullamento inviato");
                    },
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Maintenance / Admin
          Container(
            width: 300,
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Manutenzione CashBox",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Divider(),
                SizedBox(height: 10),
                _buildMenuButton(
                  "Svuota Cassetto (Tutto)",
                  Icons.delete_forever,
                  Colors.red,
                  () {
                    _runDispenseUI(
                      CashMaticOperation.emptyCashBoxAll,
                      title: "Svuotamento Totale",
                    );
                  },
                ),
                _buildMenuButton(
                  "Svuota Banconote",
                  Icons.money,
                  Colors.grey,
                  () {
                    _runDispenseUI(
                      CashMaticOperation.emptyCashboxNotes,
                      title: "Svuotamento Banconote",
                    );
                  },
                ),
                _buildMenuButton(
                  "Svuota Monete",
                  Icons.monetization_on,
                  Colors.grey,
                  () {
                    _runDispenseUI(
                      CashMaticOperation.emptyCashboxCoins,
                      title: "Svuotamento Monete",
                    );
                  },
                ),
                Spacer(),
                _buildMenuButton(
                  "Disconnetti",
                  Icons.logout,
                  Colors.blueGrey,
                  () {
                    setState(() {
                      isAuthenticated = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: OutlinedButton.icon(
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: Colors.black87)),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.all(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        onPressed: onTap,
      ),
    );
  }
}

// ==============================================================================
// 4. AMOUNT INPUT MODAL (REPLACES KEYBOARD)
// ==============================================================================

class AmountInputModal extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final Function(int) onConfirmed;
  final bool isWithdrawal;

  const AmountInputModal({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onConfirmed,
    this.isWithdrawal = false,
  });

  @override
  State<AmountInputModal> createState() => _AmountInputModalState();
}

class _AmountInputModalState extends State<AmountInputModal> {
  String _currentInput = "";

  void _onKeyPressed(String key) {
    if (_currentInput.length > 7) return; // Max limit
    setState(() {
      _currentInput += key;
    });
  }

  void _onBackspace() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _currentInput = "";
    });
  }

  int get _amountCents {
    if (_currentInput.isEmpty) return 0;
    return int.parse(_currentInput);
  }

  String get _formattedDisplay {
    if (_currentInput.isEmpty) return "€ 0,00";
    double val = int.parse(_currentInput) / 100.0;
    return "€ ${val.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 600,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: Text(
                _formattedDisplay,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: POSNumpad(
                onKeyPressed: _onKeyPressed,
                onBackspace: _onBackspace,
                onClear: _onClear,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                    ),
                    child: Text("ANNULLA"),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _amountCents > 0
                        ? () => widget.onConfirmed(_amountCents)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.isWithdrawal ? Colors.orange : Colors.green,
                      padding: EdgeInsets.all(16),
                    ),
                    child: Text(
                      widget.confirmLabel,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

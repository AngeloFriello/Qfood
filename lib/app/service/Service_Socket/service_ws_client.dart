import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ControllerWsClient extends ChangeNotifier {
  bool _connected = false;
  bool get connected => _connected;

  bool _disposed = false;
  bool get disposed => _disposed;

  String? _serverUrl;
  String? get serverUrl => _serverUrl;

  final StreamController<String> _messagesController = StreamController<String>.broadcast();
  Stream<String> get messages => _messagesController.stream;

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;

  void setConnected(bool c) {
    if (_disposed) return;
    if (_connected == c) return;
    _connected = c;
    _connectionController.add(_connected);
    notifyListeners();
  }

  void send(String message) {}
  Future<void> connect();
  Future<void> disconnect();
  Future<void> destroy();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    disconnect();
    _messagesController.close();
    _connectionController.close();
    super.dispose();
  }
}

class ServiceWsClient extends ControllerWsClient {
  static ServiceWsClient? _instance;
  static ServiceWsClient instance() => _instance ??= ServiceWsClient._();
  ServiceWsClient._();

  WebSocket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;

  @override
  Future<void> connect() async {
    final pref = await SharedPreferences.getInstance();
    final devicePref = jsonDecode(pref.getString('device') ?? '{}') as Map<String, dynamic>;

    final ip = '192.168.1.141'; // o devicePref['serverIp']   //192.168.2.46 dabliu  10.103.171.187   //192.168.1.30
    final port = 4040;         // o devicePref['serverPort']
    _serverUrl = 'ws://$ip:$port';

    await _socket?.close();
    _socket = null;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    _connectOnce();
  }

  @override
  Future<void> destroy() async {
    if (disposed) return;
    _reconnectTimer?.cancel();
    await _socket?.close(1000, 'Destroy');
    _socket = null;
    _reconnectAttempts = 0;
    _instance = null;
    dispose();
  }

  void _connectOnce() async {
    if (disposed) return;
    try {
      _socket = await WebSocket.connect(_serverUrl!);
      setConnected(true);
      _reconnectAttempts = 0;

      _socket!.listen(
        (data) {
          try {
            if (data is String && !_messagesController.isClosed) {
              _messagesController.add(data);
            }

            final message = jsonDecode(data);
            //SnackBarForcedClosure('Il server dice: ${ (data as String).length > 110 ? data : (data as String).substring(0,100)}', Colors.deepOrange);
            switch (message['type']) {
              case 'exitTable':
                if (vistaTableKey.currentState == null || !vistaTableKey.currentState!.mounted) return;
                vistaTableKey.currentState!.exitTable(message['tables']);
                break;
              case 'opendTable':
                if (vistaTableKey.currentState == null || !vistaTableKey.currentState!.mounted) return;
                final t = tableByServerForClient.firstWhere((t_) => t_.id == message['idTable']);
                vistaTableKey.currentState!.apriPaginaColorata(t);
                break;
              case 'connected':
                send(
                  jsonEncode(
                    {
                      'idOperator': operatorLogged != null ? operatorLogged!.id : 0,
                      'type': 'clientInfo',
                      'deviceType': deviceCurrent['deviceType']
                    }
                ));
                break;
              case 'tables':
                try{
                  final tables = (message['tables'] as List?)?.take(50).toList() ?? [];
                  tableByServerForClient = tables.map((t) => TableModel.fromMap(t)).toList();
                  if (vistaTableKey.currentState?.mounted ?? false) {
                    vistaTableKey.currentState!.setTableByServer();
                  }
                }catch( err ){
                  debugPrint( err.toString() );
                }
                break;
              default:
                break;
            }
          } catch (_) {}
        },
        onError: _handleDisconnect,
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect([dynamic error]) {
    if (disposed) return;
    setConnected(false);
    _socket = null;

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 3);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, _connectOnce);
    }
  }

  @override
  void send(String message) {
    if (connected && _socket != null) {
      _socket!.add(message);
    }
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _socket?.close(1000, 'Manual disconnect');
    _socket = null;
    setConnected(false);
    _reconnectAttempts = 0;
  }
}

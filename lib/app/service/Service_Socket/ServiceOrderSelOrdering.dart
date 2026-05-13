import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ServiceOrderSelOrdering {
  static ServiceOrderSelOrdering? _instance;
  static ServiceOrderSelOrdering instance() =>
      _instance ??= ServiceOrderSelOrdering();

  IO.Socket? _socket;
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");

      if (istanza == null || istanza.isEmpty) {
        debugPrint('[ServiceOrderSelOrdering] Istanza non configurata');
        return;
      }

      if (token == null || token.isEmpty) {
        debugPrint('[ServiceOrderSelOrdering] Token non configurato');
        return;
      }

      final url = 'wss://$istanza-api.qfood.it';
      debugPrint('[ServiceOrderSelOrdering] Connessione Socket.IO a: $url');

      _socket = IO.io(
        url,
        <String, dynamic>{
          'transports': ['polling', 'websocket'],
          'autoConnect': false,
          'forceNew': true,
          'reconnection': false,
          'auth': {
            'authorization': 'Bearer $token',
          },
        },
      );

      _socket!.onConnect((_) {
        debugPrint('[ServiceOrderSelOrdering] Connesso a Socket.IO');
      });

      _socket!.on('newOrderOnStore', (data) {
        debugPrint('[ServiceOrderSelOrdering] Nuovo ordine ricevuto: $data');
      });

      _socket!.onConnectError((err) {
        debugPrint('[ServiceOrderSelOrdering] Connect error: $err');
        _scheduleReconnect();
      });

      _socket!.onError((err) {
        debugPrint('[ServiceOrderSelOrdering] Socket error: $err');
        _scheduleReconnect();
      });

      _socket!.onDisconnect((_) {
        debugPrint('[ServiceOrderSelOrdering] Socket disconnessa');
        _scheduleReconnect();
      });

      _socket!.connect();
    } catch (err) {
      debugPrint('[ServiceOrderSelOrdering] Eccezione connessione: $err');
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    _socket?.dispose();
    _socket = null;
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_client.dart';

/// Classe client: ogni metodo invia un messaggio WS al server.
/// Passa sempre idOperatoreLoggato → il server salva nel DB entrambi i campi.
class TurnoLavoroWsClient {

  // ─── lastShiftOpened ────────────────────────────────────────────────────────
  static Future<bool> lastShiftOpened() async {
    if (operatorLogged == null) return false;
    final completer = Completer<bool>();

    final sub = ServiceWsClient.instance().messages.listen((data) {
      try {
        final msg = jsonDecode(data);
        if (msg['type'] == 'lastShiftOpenedResponse' && !completer.isCompleted) {
          completer.complete(msg['isOpen'] as bool);
        }
      } catch (_) {}
    });

    ServiceWsClient.instance().send(jsonEncode({
      'type':               'lastShiftOpened',
      'idOperatoreLoggato': operatorLogged!.id,
    }));

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.complete(false);
    });

    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  // ─── openShift ──────────────────────────────────────────────────────────────
  /// Apertura turno: idOperatoreLoggato == idOperatoreApertura (stessa persona)
  static Future<int> openShift({
    required String nomeTurno,
    required double fondoCassaIniziale,
  }) async {
    if (operatorLogged == null) return 0;
    final completer = Completer<int>();

    final sub = ServiceWsClient.instance().messages.listen((data) {
      try {
        final msg = jsonDecode(data);
        if (msg['type'] == 'openShiftResponse' && !completer.isCompleted) {
          completer.complete(msg['id'] as int? ?? 0);
        }
      } catch (_) {}
    });

    ServiceWsClient.instance().send(jsonEncode({
      'type':               'openShift',
      'nomeTurno':          nomeTurno,
      'fondoCassaIniziale': fondoCassaIniziale,
      'idOperatoreLoggato': operatorLogged!.id,
      // idOperatoreApertura == idOperatoreLoggato all'apertura
      'idOperatoreApertura': operatorLogged!.id,
    }));

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.complete(0);
    });

    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  // ─── closeShift ─────────────────────────────────────────────────────────────
  /// Chiusura turno: idOperatoreLoggato = chi chiude (può differire da chi ha aperto)
  static Future<bool> closeShift({
    required double fondoCassaFinale,
    String? chiusuraCassa,
  }) async {
    if (operatorLogged == null) return false;
    final completer = Completer<bool>();

    final sub = ServiceWsClient.instance().messages.listen((data) {
      try {
        final msg = jsonDecode(data);
        if (msg['type'] == 'closeShiftResponse' && !completer.isCompleted) {
          completer.complete(msg['success'] as bool? ?? false);
        }
      } catch (_) {}
    });

    ServiceWsClient.instance().send(jsonEncode({
      'type':               'closeShift',
      'fondoCassaFinale':   fondoCassaFinale,
      'chiusuraCassa':      chiusuraCassa,
      'idOperatoreLoggato': operatorLogged!.id,
      // idOperatoreApertura viene recuperato dal DB lato server
    }));

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.complete(false);
    });

    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  // ─── addDocumentToShift ─────────────────────────────────────────────────────
  /// Aggiunge documento: idOperatoreLoggato = chi emette il documento
  static Future<bool> addDocumentToShift({
    required String tipoDocumento,
    required double totaleDocumento,
    double contanti       = 0,
    double elettronico    = 0,
    double tickets        = 0,
    double assegno        = 0,
    double amountFood     = 0,
    double amountBeverage = 0,
    double amountAltro    = 0,
    double? sconto,
    String? provenienza,
  }) async {
    if (operatorLogged == null) return false;
    final completer = Completer<bool>();

    final sub = ServiceWsClient.instance().messages.listen((data) {
      try {
        final msg = jsonDecode(data);
        if (msg['type'] == 'addDocumentResponse' && !completer.isCompleted) {
          completer.complete(msg['success'] as bool? ?? false);
        }
      } catch (_) {}
    });

    ServiceWsClient.instance().send(jsonEncode({
      'type':               'addDocumentToShift',
      'tipoDocumento':      tipoDocumento,
      'totaleDocumento':    totaleDocumento,
      'contanti':           contanti,
      'elettronico':        elettronico,
      'tickets':            tickets,
      'assegno':            assegno,
      'amountFood':         amountFood,
      'amountBeverage':     amountBeverage,
      'amountAltro':        amountAltro,
      'sconto':             sconto,
      'provenienza':        provenienza,
      'idOperatoreLoggato': operatorLogged!.id,
      // idOperatoreApertura viene recuperato dal DB lato server
    }));

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.complete(false);
    });

    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  // ─── getTotalsByDocumentType ────────────────────────────────────────────────
  static Future<Map<String, double>> getTotalsByDocumentType({
    bool lastClosedShift = false,
    bool lastLogin       = false,
    String? fromTime,
    String? tipoReport,
    String? uuidTurno,
    DateTime? from,
    DateTime? to,
    int? idOperator,
  }) async {
    final completer = Completer<Map<String, double>>();

    final sub = ServiceWsClient.instance().messages.listen((data) {
      try {
        final msg = jsonDecode(data);
        if (msg['type'] == 'getTotalsResponse' && !completer.isCompleted) {
          final raw = msg['totals'] as Map<String, dynamic>? ?? {};
          completer.complete(raw.map((k, v) => MapEntry(k, (v as num).toDouble())));
        }
      } catch (_) {}
    });

    ServiceWsClient.instance().send(jsonEncode({
      'type':               'getTotalsByDocumentType',
      'lastClosedShift':    lastClosedShift,
      'lastLogin':          lastLogin,
      'fromTime':           fromTime,
      'tipoReport':         tipoReport,
      'uuidTurno':          uuidTurno,
      'from':               from?.toIso8601String(),
      'to':                 to?.toIso8601String(),
      'idOperator':         idOperator,
      'idOperatoreLoggato': operatorLogged?.id,
    }));

    Future.delayed(const Duration(seconds: 8), () {
      if (!completer.isCompleted) completer.complete({});
    });

    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  // ─── getTurniUltimi6Mesi ────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getTurniUltimi6Mesi() async {
    final completer = Completer<List<Map<String, dynamic>>>();

    final sub = ServiceWsClient.instance().messages.listen((data) {
      try {
        final msg = jsonDecode(data);
        if (msg['type'] == 'getTurniResponse' && !completer.isCompleted) {
          final list = (msg['turni'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          completer.complete(list);
        }
      } catch (_) {}
    });

    ServiceWsClient.instance().send(jsonEncode({
      'type':               'getTurniUltimi6Mesi',
      'idOperatoreLoggato': operatorLogged?.id,
    }));

    Future.delayed(const Duration(seconds: 8), () {
      if (!completer.isCompleted) completer.complete([]);
    });

    final result = await completer.future;
    await sub.cancel();
    return result;
  }
}
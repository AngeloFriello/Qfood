import 'dart:convert';
import 'dart:io';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Entry point: chiamato dal listener WS del server per i messaggi relativi ai turni.
/// Da aggiungere nello switch del ServiceWsServer:
///
///   case 'lastShiftOpened':
///   case 'openShift':
///   case 'closeShift':
///   case 'addDocumentToShift':
///     handleTurnoLavoroMessage(ws, message);
///     break;
Future<void> handleTurnoLavoroMessage(WebSocket ws, Map message) async {
  switch (message['type']) {
    case 'lastShiftOpened':
      await _handleLastShiftOpened(ws, message);
      break;
    case 'openShift':
      await _handleOpenShift(ws, message);
      break;
    case 'closeShift':
      await _handleCloseShift(ws, message);
      break;
    case 'addDocumentToShift':
      await _handleAddDocumentToShift(ws, message);
      break;
  }
}
// ─── lastShiftOpened ──────────────────────────────────────────────────────────
Future<void> _handleLastShiftOpened(WebSocket ws, Map message) async {
  try {
    final int idOperatoreLoggato = message['idOperatoreLoggato'] as int;
    final db = await LocalDB.instance();

    // Step 1: trova l'uuid dell'ultimo turno aperto da questo operatore
    final lastShift = await db.query(
      'turno_lavoro',
      columns: ['uuid_turno'],
      where: 'id_operatore_apertura = ?',
      whereArgs: [idOperatoreLoggato],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (lastShift.isEmpty) {
      ws.add(jsonEncode({'type': 'lastShiftOpenedResponse', 'isOpen': false}));
      return;
    }

    final String uuid = lastShift.first['uuid_turno'] as String;

    // Step 2: verifica se esiste una riga di chiusura
    final closedRow = await db.query(
      'turno_lavoro',
      columns: ['id'],
      where: 'uuid_turno = ? AND turno_chiuso = ?',
      whereArgs: [uuid, 1],
      limit: 1,
    );

    ws.add(jsonEncode({
      'type':   'lastShiftOpenedResponse',
      'isOpen': closedRow.isEmpty,
    }));
  } catch (err) {
    debugPrint(err.toString());
    ws.add(jsonEncode({'type': 'lastShiftOpenedResponse', 'isOpen': false}));
  }
}

// ─── openShift ────────────────────────────────────────────────────────────────
Future<void> _handleOpenShift(WebSocket ws, Map message) async {
  try {
    final db = await LocalDB.instance();
    final String uuid = const Uuid().v4();

    // Il client manda entrambi i campi (all'apertura coincidono)
    final int idOperatoreLoggato  = message['idOperatoreLoggato']  as int;
    final int idOperatoreApertura = message['idOperatoreApertura'] as int;
    final String nome = message['nomeTurno'] as String;
    final double fondo = (message['fondoCassaIniziale'] as num).toDouble();

    final int id = await db.insert(
      'turno_lavoro',
      {
        'uuid_turno':            uuid,
        'nome_turno':            nome,
        'id_operatore_apertura': idOperatoreApertura, // chi ha aperto
        'id_operatore_loggato':  idOperatoreLoggato,  // chi è loggato
        'fondo_cassa_iniziale':  fondo,
        'fondo_cassa_trovato':   fondo,
      },
    );

    ws.add(jsonEncode({'type': 'openShiftResponse', 'id': id, 'uuidTurno': uuid}));
    debugPrint('Turno "$nome" aperto dal client — uuid: $uuid | operatore: $idOperatoreLoggato');
  } catch (err) {
    debugPrint(err.toString());
    ws.add(jsonEncode({'type': 'openShiftResponse', 'id': 0}));
  }
}

// ─── closeShift ───────────────────────────────────────────────────────────────
Future<void> _handleCloseShift(WebSocket ws, Map message) async {
  try {
    final db = await LocalDB.instance();
    final int idOperatoreLoggato = message['idOperatoreLoggato'] as int;
    final double fondoFin  = (message['fondoCassaFinale'] as num).toDouble();
    final String? chiusura = message['chiusuraCassa'] as String?;

    // Cerca l'ultimo turno aperto da questo operatore
    final result = await db.query(
      'turno_lavoro',
      columns: ['uuid_turno', 'nome_turno', 'id_operatore_apertura', 'fondo_cassa_iniziale'],
      where: 'turno_chiuso = ? AND id_operatore_apertura = ?',
      whereArgs: [0, idOperatoreLoggato],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      debugPrint('Nessun turno aperto per operatore $idOperatoreLoggato');
      ws.add(jsonEncode({'type': 'closeShiftResponse', 'success': false}));
      return;
    }

    final String uuid              = result.first['uuid_turno'] as String;
    final String nome              = result.first['nome_turno'] as String;
    final int idOperatoreApertura  = result.first['id_operatore_apertura'] as int; // dal DB
    final double fondoIniz         = (result.first['fondo_cassa_iniziale'] as num).toDouble();

    await db.insert(
      'turno_lavoro',
      {
        'uuid_turno':            uuid,
        'nome_turno':            nome,
        'id_operatore_apertura': idOperatoreApertura, // preservato dal DB
        'id_operatore_loggato':  idOperatoreLoggato,  // chi sta chiudendo
        'fondo_cassa_finale':    fondoFin,
        'fondo_cassa_iniziale':  fondoIniz,
        'chiusura_cassa':        chiusura,
        'turno_chiuso':          1,
      },
    );

    ws.add(jsonEncode({'type': 'closeShiftResponse', 'success': true}));
    debugPrint('Turno "$nome" chiuso dal client — uuid: $uuid | loggato: $idOperatoreLoggato | apertura: $idOperatoreApertura');
  } catch (err) {
    debugPrint(err.toString());
    ws.add(jsonEncode({'type': 'closeShiftResponse', 'success': false}));
  }
}

// ─── addDocumentToShift ───────────────────────────────────────────────────────
Future<void> _handleAddDocumentToShift(WebSocket ws, Map message) async {
  try {
    final db = await LocalDB.instance();
    final int idOperatoreLoggato = message['idOperatoreLoggato'] as int;

    // Recupera il turno aperto corrente con il suo id_operatore_apertura
    final result = await db.query(
      'turno_lavoro',
      columns: ['uuid_turno', 'nome_turno', 'id_operatore_apertura', 'fondo_cassa_iniziale'],
      where: 'turno_chiuso = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      debugPrint('Nessun turno aperto trovato');
      ws.add(jsonEncode({'type': 'addDocumentResponse', 'success': false}));
      return;
    }

    final String uuid             = result.first['uuid_turno'] as String;
    final String nome             = result.first['nome_turno'] as String;
    final int idOperatoreApertura = result.first['id_operatore_apertura'] as int; // dal DB
    final double? fondoIniz       = (result.first['fondo_cassa_iniziale'] as num?)?.toDouble();

    await db.insert(
      'turno_lavoro',
      {
        'uuid_turno'           : uuid,
        'nome_turno'           : nome,
        'id_operatore_apertura': idOperatoreApertura, // preservato dal DB
        'id_operatore_loggato' : idOperatoreLoggato,  // chi ha emesso il documento
        'fondo_cassa_iniziale' : fondoIniz,
        'tipo_documento'       : message['tipoDocumento'],
        'totale_documento'     : (message['totaleDocumento']  as num).toDouble(),
        'turno_chiuso'         : 0,
        'contanti'             : (message['contanti']         as num? ?? 0).toDouble(),
        'elettronico'          : (message['elettronico']      as num? ?? 0).toDouble(),
        'tickets'              : (message['tickets']          as num? ?? 0).toDouble(),
        'assegno'              : (message['assegno']          as num? ?? 0).toDouble(),
        'amount_food'          : (message['amountFood']       as num? ?? 0).toDouble(),
        'amount_beverage'      : (message['amountBeverage']   as num? ?? 0).toDouble(),
        'amount_altro'         : (message['amountAltro']      as num? ?? 0).toDouble(),
        'sconto'               : message['sconto'],
        'provenienza'          : message['provenienza'],
      },
    );

    ws.add(jsonEncode({'type': 'addDocumentResponse', 'success': true}));
    debugPrint('Doc "${message['tipoDocumento']}" → turno "$nome" | loggato: $idOperatoreLoggato | apertura: $idOperatoreApertura');
  } catch (err) {
    debugPrint(err.toString());
    ws.add(jsonEncode({'type': 'addDocumentResponse', 'success': false}));
  }
}

// ─── getTotalsByDocumentType ──────────────────────────────────────────────────
Future<void> _handleGetTotals(WebSocket ws, Map message) async {
  try {
    // Riutilizza la logica identica al server locale — risultato inviato via WS
    // (implementazione omessa per brevità: replica getTotalsByDocumentTypeLastShift)
    ws.add(jsonEncode({'type': 'getTotalsResponse', 'totals': {}}));
  } catch (err) {
    debugPrint(err.toString());
    ws.add(jsonEncode({'type': 'getTotalsResponse', 'totals': {}}));
  }
}

// ─── getTurniUltimi6Mesi ──────────────────────────────────────────────────────
Future<void> _handleGetTurni(WebSocket ws, Map message) async {
  try {
    // Riutilizza la logica identica al server locale — risultato inviato via WS
    // (implementazione omessa per brevità: replica getTurniUltimi6Mesi)
    ws.add(jsonEncode({'type': 'getTurniResponse', 'turni': []}));
  } catch (err) {
    debugPrint(err.toString());
    ws.add(jsonEncode({'type': 'getTurniResponse', 'turni': []}));
  }
}

/// Restituisce l'uuid dell'ultimo turno se è ancora aperto (turno_chiuso = 0),
/// altrimenti null.
Future<String?> getUuidUltimoTurnoAperto() async {
  final db = await LocalDB.instance();

  final result = await db.rawQuery('''
    SELECT uuid_turno
    FROM turno_lavoro
    WHERE id = (SELECT MAX(id) FROM turno_lavoro)
      AND turno_chiuso = 0
  ''');

  if (result.isNotEmpty) {
    return result.first['uuid_turno'] as String?;
  }
  return null;
}
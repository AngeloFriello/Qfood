import 'dart:convert';
import 'dart:io';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine_stato.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine_tipo.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/widget/header_footer/footer_navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

int orderTestNumber = 0;

class ClientWebSocket {
  final WebSocket ws;
  final int idOperator;
  final String deviceType;

  ClientWebSocket({
    required this.ws,
    required this.idOperator,
    required this.deviceType,
  });
}


abstract class ControllerWsServer extends ChangeNotifier {
  bool _serverOpened = false;
  bool get serverOpened => _serverOpened;

  List<ClientWebSocket> _clients = [];
  List<ClientWebSocket> get clients => _clients;

  void setConnected(bool c) {
    if (_serverOpened == c) return;
    _serverOpened = c;
    notifyListeners();
  }

  void clearClients() {
    _clients = [];
    notifyListeners();
  }

  void addClient(WebSocket wsc, int idOperator, String deviceType_) {
    _clients.add(ClientWebSocket(ws: wsc, idOperator: idOperator, deviceType: deviceType_));
    notifyListeners();
  }

  void removeClient(WebSocket ws) {
    try {
      _clients = clients.where((c) => c.ws != ws).toList();
      notifyListeners();
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> stopForTest();
  Future<void> reset();
  Future<bool> lookTableServer(int idTable);
  Future<void> unLookTableServer(int idTable);
  Future<void> openTableServer(int idTable, int coversInTable);
  Future<void> setNoteTableServer(int idTable, String note);
  Future<void> impegnaTableServer(int idTable, String note, int numberCovers);
  Future<void> resetTableServer(int idTable);
  Future<void> updateTableServer(int idTable, TableModel table);
  Future<void> moveTableServer(TableModel tableFrom, TableModel tableTo);
  Future<void> joinTablesServer(TableModel parentTable, List<TableModel> tablesChildren);
  Future<void> unjoinTablesServer(List<TableModel> idChildren, TableModel parent);
  void sendAllClients(String msg);
}


class ServiceWsServer extends ControllerWsServer {
  static ServiceWsServer? _instance;
  static ServiceWsServer instance() => _instance ??= ServiceWsServer();

  HttpServer? _server;
  bool _shouldRun = false;

  @override
  void sendAllClients(String msg) {
    for (final c in clients) {
      c.ws.add(jsonEncode(msg));
    }
  }

  @override
  Future<void> stopForTest() async {
    setConnected(false);
    for (final c in clients) {
      try { await c.ws.close(); } catch (_) {}
    }
    clearClients();
    try { await _server?.close(force: true); } catch (_) {}
    _server = null;
  }

  @override
  Future<void> reset() async {
    _shouldRun = false;
    setConnected(false);
    for (final c in clients) {
      try { await c.ws.close(); } catch (_) {}
    }
    clearClients();
    try { await _server?.close(force: true); } catch (_) {}
    _server = null;
    _instance = null;
  }

  @override
  Future<bool> lookTableServer(int idTable) async {
    bool lock = false;
    try {
      lock = await TableModel.blockTable(idTable);
      getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
      lock = true;
    } finally {
      return lock;
    }
  }

  @override
  Future<void> moveTableServer(TableModel tableFrom, TableModel tableTo) async {
    try {
      await TableModel.moveTable(tableFrom, tableTo);
      getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> openTableServer(int idTable, int coversInTable) async {
    try {
      await TableModel.openTable(idTable, operatorLogged!.id, coversInTable);
      await getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> joinTablesServer(TableModel parentTable, List<TableModel> tablesChildren) async {
    try {
      await TableModel.joinedTablesWithParent(parentTable, tablesChildren);
      await getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> unjoinTablesServer(List<TableModel> idsChildren, TableModel parent) async {
    try {
      await TableModel.resetMultiTables(idsChildren, parent);
      await getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> setNoteTableServer(int idTable, String note) async {
    try {
      await TableModel.setNoteTable(idTable, note);
      await getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> resetTableServer(int idTable) async {
    try {
      await TableModel.resetTable(idTable);
      await getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> impegnaTableServer(int idTable, String note, int numberCover) async {
    try {
      await TableModel.impegnaTable(idTable, note, numberCover);
      await getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> unLookTableServer(int idTable) async {
    try {
      await TableModel.unLock(idTable);
      for (final c in clients) {
        c.ws.add(jsonEncode({'type': 'exitTable', 'tables': idTable}));
      }
      getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  Future<void> updateTableServer(int idTable, TableModel table) async {
    try {
      await TableModel.updateTable(idTable, table, operatorLogged!.id);
      getALLTablesDecodebleForClient(clients);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> start() async {
    final pref   = await SharedPreferences.getInstance();
    final device = jsonDecode(pref.getString('device') ?? '{}') as Map<String, dynamic>;

    if (device.isEmpty ||
        device['deviceServer'] == 0 ||
        device['serverIp']   == null ||
        device['serverPort'] == null) return;

    if (_shouldRun) return;
    _shouldRun = true;

    var delay = const Duration(seconds: 1);

    while (_shouldRun) {
      try {
        final ip   = device['serverIp']   as String;
        final port = device['serverPort'] as int;

        _server = await HttpServer.bind('10.3.6.52', 4040);
        setConnected(true);
        debugPrint('Server avviato — ws://$ip:$port');
        delay = const Duration(seconds: 1);

        await for (final req in _server!) {
          if (req.method == 'POST') {
            await _handleHttpPost(req);
            continue;
          }

          if (!WebSocketTransformer.isUpgradeRequest(req)) {
            req.response
              ..statusCode = HttpStatus.badRequest
              ..write('WebSocket endpoint only')
              ..close();
            continue;
          }

          final ws = await WebSocketTransformer.upgrade(req);
          ws.add(jsonEncode({'type': 'connected'}));

          ws.listen(
            (msg) {
              if (int.tryParse(msg) != null) {
                testLook(int.parse(msg), clients);
                ws.add('Ciao');
                return;
              }

              final Map message = jsonDecode(msg);
              debugPrint('msg client: $msg');
              SnackBarForcedClosure('Il client dice: $msg', Colors.blueAccent);

              switch (message['type']) {
                case 'clientInfo':
                  addClient(ws, message['idOperator'], message['deviceType']);
                  break;
                case 'getTables':
                  getTablesDecodebleForClient(ws, message['idRoom']);
                  break;
                case 'lockTable':
                  lockTablesForClient(ws, message['idTable'], clients);
                  break;
                case 'unLockTable':
                  unLockTablesForClient(ws, message['idTable'], clients);
                  break;
                case 'openTable':
                  openTable(ws, message['idTable'], message['idOperator'], message['coversInTable'], clients);
                  break;
                case 'updateTable':
                  updateTable(ws, message['idTable'], TableModel.fromMap(message['table']), message['idOperator'], clients);
                  break;
                case 'noteTable':
                  setNoteTable(ws, message['idTable'], message['note'], clients);
                  break;
                case 'impegnaTable':
                  impegnaTable(ws, message['idTable'], message['note'], clients, message['numberCover']);
                  break;
                case 'resetTable':
                  resetTable(ws, message['idTable'], clients);
                  break;
                case 'moveTable':
                  moveTable(ws, TableModel.fromMap(message['tableFrom']), TableModel.fromMap(message['tableTo']), clients);
                  break;
                case 'joinTables':
                  joinTables(
                    clients,
                    TableModel.fromMap(message['parent']),
                    (message['children'] as List).map((c) => TableModel.fromMap(c)).toList(),
                  );
                  break;
                case 'unJoinParentTables':
                  unJoinTables(
                    clients,
                    (message['children'] as List).map((t) => TableModel.fromMap(t)).toList(),
                    TableModel.fromMap(message['parent']),
                  );
                  break;
                case 'lastShiftOpened':
                  _handleLastShiftOpened(ws, message);
                  break;
                case 'openShift':
                  _handleOpenShift(ws, message);
                  break;
                case 'closeShift':
                  _handleCloseShift(ws, message);
                  break;
                case 'addDocumentToShift':
                  _handleAddDocumentToShift(ws, message);
                  break;
                default:
                  break;
              }
            },
            onError: (e) {
              removeClient(ws);
              debugPrint('WS errore: $e');
            },
            onDone: () {
              removeClient(ws);
              debugPrint('WS disconnesso');
            },
            cancelOnError: true,
          );
        }

        setConnected(false);
      } catch (e) {
        setConnected(false);
        debugPrint('Server errore: $e');
      } finally {
        try { await _server?.close(force: true); } catch (_) {}
        _server = null;
      }

      if (!_shouldRun) break;
      await Future.delayed(delay);
      delay = const Duration(seconds: 5);
    }
  }

  Future<void> stop() async {
    _shouldRun = false;
    setConnected(false);
    try { await _server?.close(force: true); } catch (_) {}
    _server = null;
  }

  // ---- HTTP POST router -------------------------------------------------------

  Future<void> _handleHttpPost(HttpRequest req) async {
    final body = await utf8.decoder.bind(req).join();

    req.response.headers
      ..set('Content-Type', 'application/json')
      ..set('Access-Control-Allow-Origin', '*');

    try {
      final Map<String, dynamic> data = jsonDecode(body);

      switch (req.uri.path) {
        case '/shift':
          await _routeShift(req, data);
          break;
        case '/tables':
          await _handleTablesHttp(req, data);
          break;
        case '/totemOrder':
          await ordineTotem(req, data);
          break;
        default:
          req.response
            ..statusCode = HttpStatus.notFound
            ..write(jsonEncode({'error': 'endpoint non trovato: ${req.uri.path}'}))
            ..close();
      }
    } catch (err) {
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'error': err.toString()}))
        ..close();
    }
  }

  Future<void> _routeShift(HttpRequest req, Map<String, dynamic> data) async {
    switch (data['type'] ?? '') {
      case 'lastShiftOpened':
        await _handleLastShiftOpenedHttp(req, data);
        break;
      case 'openShift':
        await _handleOpenShiftHttp(req, data);
        break;
      case 'closeShift':
        await _handleCloseShiftHttp(req, data);
        break;
      case 'addDocumentToShift':
        await _handleAddDocumentToShiftHttp(req, data);
        break;
      default:
        req.response
          ..statusCode = HttpStatus.badRequest
          ..write(jsonEncode({'error': 'type "${data['type']}" non riconosciuto'}))
          ..close();
    }
  }

  // ---- /totemOrder -----------------------------------------------------------

  Future<void> ordineTotem(HttpRequest req, Map<String, dynamic> data) async {
    try {
      final OrdineTipo tipo = typeOrderFromString(data['tipo'] ?? 'mangiaQui');
      final DateTime   data_ = data['data'] != null
          ? DateTime.tryParse(data['data']) ?? DateTime.now()
          : DateTime.now();

      final List<ProdottoCarrello> articles = ((data['articles'] ?? []) as List).map((p) {
        p = Map<String, dynamic>.from(p);
        if (p['article'] is Map) {
          p['article'] = ArticleWhitPriceListModel.fromJson(Map<String, Object?>.from(p['article']));
        }
        for (final key in ['variationsMinus', 'variationsPlus', 'variationsInfo', 'variationsFree']) {
          if (p[key] is List) {
            p[key] = (p[key] as List).map((v) {
              v = Map<String, dynamic>.from(v);
              if (v['article'] is Map) {
                v['article'] = ArticleWhitPriceListModel.fromJson(Map<String, Object?>.from(v['article']));
              }
              return ProdottoCarrello.fromJson(v);
            }).toList();
          }
        }
        return ProdottoCarrello.fromJson(p);
      }).toList();

      final ordine = Ordine(
        nomeCliente    : data['nomeCliente']    as String?,
        cliente        : null,
        tipo           : tipo,
        stato          : OrdineStato.nuovo,
        data           : data_,
        articles       : articles,
        paid           : (data['paid']          as int?)    ?? 0,
        indirizzo      : data['indirizzo']       as String?,
        telefono       : data['telefono']        as String?,
        note           : data['note']            as String?,
        callerPager    : data['callerPager']     as String?,
        idRider        : data['idRaider']        as int?,
        change         : (data['change']         as num?)?.toDouble(),
        receiptPrinted : (data['receiptPrinted'] as int?)   ?? 0,
      );

      final db       = await LocalDB.instance();
      final idOrdine = await db.insert('orders', ordine.forDb());

      debugPrint('ordine totem salvato — id: $idOrdine | ${ordine.titleCustomer} | €${ordine.totaleCarrello}');

      messengerKey.currentContext?.read<ControllerNuovoOrdine>().setNuovo(true);

      req.response
        ..statusCode = HttpStatus.created
        ..write(jsonEncode({'success': true, 'idOrdine': idOrdine, 'totale': ordine.totaleCarrello}))
        ..close();
    } catch (err, st) {
      debugPrint('ordineTotem errore: $err\n$st');
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'success': false, 'error': err.toString()}))
        ..close();
    }
  }

  // ---- /shift HTTP -----------------------------------------------------------

  Future<void> _handleLastShiftOpenedHttp(HttpRequest req, Map data) async {
    final db          = await LocalDB.instance();
    final int idOp    = data['idOperatoreLoggato'] as int;

    final rows = await db.query(
      'turno_lavoro',
      columns  : ['uuid_turno'],
      where    : 'id_operatore_apertura = ?',
      whereArgs: [idOp],
      orderBy  : 'id DESC',
      limit    : 1,
    );

    if (rows.isEmpty) {
      req.response..write(jsonEncode({'isOpen': false}))..close();
      return;
    }

    final closed = await db.query(
      'turno_lavoro',
      columns  : ['id'],
      where    : 'uuid_turno = ? AND turno_chiuso = ?',
      whereArgs: [rows.first['uuid_turno'], 1],
      limit    : 1,
    );

    req.response..write(jsonEncode({'isOpen': closed.isEmpty}))..close();
  }

  Future<void> _handleOpenShiftHttp(HttpRequest req, Map data) async {
    final db   = await LocalDB.instance();
    final uuid = const Uuid().v4();

    final id = await db.insert('turno_lavoro', {
      'uuid_turno'           : uuid,
      'nome_turno'           : data['nomeTurno'],
      'id_operatore_apertura': data['idOperatoreApertura'],
      'id_operatore_loggato' : data['idOperatoreLoggato'],
      'fondo_cassa_iniziale' : (data['fondoCassaIniziale'] as num).toDouble(),
      'fondo_cassa_trovato'  : (data['fondoCassaIniziale'] as num).toDouble(),
    });

    req.response..write(jsonEncode({'id': id, 'uuidTurno': uuid}))..close();
  }

  Future<void> _handleCloseShiftHttp(HttpRequest req, Map data) async {
    final db    = await LocalDB.instance();
    final int idOp = data['idOperatoreLoggato'] as int;

    final rows = await db.query(
      'turno_lavoro',
      columns  : ['uuid_turno', 'nome_turno', 'id_operatore_apertura', 'fondo_cassa_iniziale'],
      where    : 'turno_chiuso = ? AND id_operatore_apertura = ?',
      whereArgs: [0, idOp],
      orderBy  : 'id DESC',
      limit    : 1,
    );

    if (rows.isEmpty) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'success': false, 'error': 'Nessun turno aperto'}))
        ..close();
      return;
    }

    await db.insert('turno_lavoro', {
      'uuid_turno'           : rows.first['uuid_turno'],
      'nome_turno'           : rows.first['nome_turno'],
      'id_operatore_apertura': rows.first['id_operatore_apertura'],
      'id_operatore_loggato' : idOp,
      'fondo_cassa_finale'   : (data['fondoCassaFinale'] as num).toDouble(),
      'fondo_cassa_iniziale' : rows.first['fondo_cassa_iniziale'],
      'chiusura_cassa'       : data['chiusuraCassa'],
      'turno_chiuso'         : 1,
    });

    req.response..write(jsonEncode({'success': true}))..close();
  }

  Future<void> _handleAddDocumentToShiftHttp(HttpRequest req, Map data) async {
    final db   = await LocalDB.instance();

    final rows = await db.query(
      'turno_lavoro',
      columns  : ['uuid_turno', 'nome_turno', 'id_operatore_apertura', 'fondo_cassa_iniziale'],
      where    : 'turno_chiuso = ?',
      whereArgs: [0],
      orderBy  : 'id DESC',
      limit    : 1,
    );

    if (rows.isEmpty) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'success': false, 'error': 'Nessun turno aperto'}))
        ..close();
      return;
    }

    await db.insert('turno_lavoro', {
      'uuid_turno'           : rows.first['uuid_turno'],
      'nome_turno'           : rows.first['nome_turno'],
      'id_operatore_apertura': rows.first['id_operatore_apertura'],
      'id_operatore_loggato' : data['idOperatoreLoggato'],
      'fondo_cassa_iniziale' : rows.first['fondo_cassa_iniziale'],
      'tipo_documento'       : data['tipoDocumento'],
      'totale_documento'     : (data['totaleDocumento']  as num).toDouble(),
      'turno_chiuso'         : 0,
      'contanti'             : (data['contanti']         as num? ?? 0).toDouble(),
      'elettronico'          : (data['elettronico']      as num? ?? 0).toDouble(),
      'tickets'              : (data['tickets']          as num? ?? 0).toDouble(),
      'assegno'              : (data['assegno']          as num? ?? 0).toDouble(),
      'amount_food'          : (data['amountFood']       as num? ?? 0).toDouble(),
      'amount_beverage'      : (data['amountBeverage']   as num? ?? 0).toDouble(),
      'amount_altro'         : (data['amountAltro']      as num? ?? 0).toDouble(),
      'sconto'               : data['sconto'],
      'provenienza'          : data['provenienza'],
    });

    req.response..write(jsonEncode({'success': true}))..close();
  }

  Future<void> _handleTablesHttp(HttpRequest req, Map data) async {
    await getALLTablesDecodebleForClient(clients);
    req.response..write(jsonEncode({'success': true}))..close();
  }

  // ---- WS turno handlers -----------------------------------------------------

  Future<void> _handleLastShiftOpened(WebSocket ws, Map msg) async {
    try {
      final db   = await LocalDB.instance();
      final int idOp = msg['idOperatoreLoggato'] as int;

      final rows = await db.query(
        'turno_lavoro',
        columns  : ['uuid_turno'],
        where    : 'id_operatore_apertura = ?',
        whereArgs: [idOp],
        orderBy  : 'id DESC',
        limit    : 1,
      );

      if (rows.isEmpty) {
        ws.add(jsonEncode({'type': 'lastShiftOpenedResponse', 'isOpen': false}));
        return;
      }

      final closed = await db.query(
        'turno_lavoro',
        columns  : ['id'],
        where    : 'uuid_turno = ? AND turno_chiuso = ?',
        whereArgs: [rows.first['uuid_turno'], 1],
        limit    : 1,
      );

      ws.add(jsonEncode({'type': 'lastShiftOpenedResponse', 'isOpen': closed.isEmpty}));
    } catch (err) {
      debugPrint(err.toString());
      ws.add(jsonEncode({'type': 'lastShiftOpenedResponse', 'isOpen': false}));
    }
  }

  Future<void> _handleOpenShift(WebSocket ws, Map msg) async {
    try {
      final db   = await LocalDB.instance();
      final uuid = const Uuid().v4();

      final id = await db.insert('turno_lavoro', {
        'uuid_turno'           : uuid,
        'nome_turno'           : msg['nomeTurno'],
        'id_operatore_apertura': msg['idOperatoreApertura'],
        'id_operatore_loggato' : msg['idOperatoreLoggato'],
        'fondo_cassa_iniziale' : (msg['fondoCassaIniziale'] as num).toDouble(),
        'fondo_cassa_trovato'  : (msg['fondoCassaIniziale'] as num).toDouble(),
      });

      ws.add(jsonEncode({'type': 'openShiftResponse', 'id': id, 'uuidTurno': uuid}));
    } catch (err) {
      debugPrint(err.toString());
      ws.add(jsonEncode({'type': 'openShiftResponse', 'id': 0}));
    }
  }

  Future<void> _handleCloseShift(WebSocket ws, Map msg) async {
    try {
      final db   = await LocalDB.instance();
      final int idOp = msg['idOperatoreLoggato'] as int;

      final rows = await db.query(
        'turno_lavoro',
        columns  : ['uuid_turno', 'nome_turno', 'id_operatore_apertura', 'fondo_cassa_iniziale'],
        where    : 'turno_chiuso = ? AND id_operatore_apertura = ?',
        whereArgs: [0, idOp],
        orderBy  : 'id DESC',
        limit    : 1,
      );

      if (rows.isEmpty) {
        ws.add(jsonEncode({'type': 'closeShiftResponse', 'success': false}));
        return;
      }

      await db.insert('turno_lavoro', {
        'uuid_turno'           : rows.first['uuid_turno'],
        'nome_turno'           : rows.first['nome_turno'],
        'id_operatore_apertura': rows.first['id_operatore_apertura'],
        'id_operatore_loggato' : idOp,
        'fondo_cassa_finale'   : (msg['fondoCassaFinale'] as num).toDouble(),
        'fondo_cassa_iniziale' : rows.first['fondo_cassa_iniziale'],
        'chiusura_cassa'       : msg['chiusuraCassa'],
        'turno_chiuso'         : 1,
      });

      ws.add(jsonEncode({'type': 'closeShiftResponse', 'success': true}));
    } catch (err) {
      debugPrint(err.toString());
      ws.add(jsonEncode({'type': 'closeShiftResponse', 'success': false}));
    }
  }

  Future<void> _handleAddDocumentToShift(WebSocket ws, Map msg) async {
    try {
      final db   = await LocalDB.instance();
      final int idOp = msg['idOperatoreLoggato'] as int;

      final rows = await db.query(
        'turno_lavoro',
        columns  : ['uuid_turno', 'nome_turno', 'id_operatore_apertura', 'fondo_cassa_iniziale'],
        where    : 'turno_chiuso = ?',
        whereArgs: [0],
        orderBy  : 'id DESC',
        limit    : 1,
      );

      if (rows.isEmpty) {
        ws.add(jsonEncode({'type': 'addDocumentResponse', 'success': false}));
        return;
      }

      await db.insert('turno_lavoro', {
        'uuid_turno'           : rows.first['uuid_turno'],
        'nome_turno'           : rows.first['nome_turno'],
        'id_operatore_apertura': rows.first['id_operatore_apertura'],
        'id_operatore_loggato' : idOp,
        'fondo_cassa_iniziale' : rows.first['fondo_cassa_iniziale'],
        'tipo_documento'       : msg['tipoDocumento'],
        'totale_documento'     : (msg['totaleDocumento']  as num).toDouble(),
        'turno_chiuso'         : 0,
        'contanti'             : (msg['contanti']         as num? ?? 0).toDouble(),
        'elettronico'          : (msg['elettronico']      as num? ?? 0).toDouble(),
        'tickets'              : (msg['tickets']          as num? ?? 0).toDouble(),
        'assegno'              : (msg['assegno']          as num? ?? 0).toDouble(),
        'amount_food'          : (msg['amountFood']       as num? ?? 0).toDouble(),
        'amount_beverage'      : (msg['amountBeverage']   as num? ?? 0).toDouble(),
        'amount_altro'         : (msg['amountAltro']      as num? ?? 0).toDouble(),
        'sconto'               : msg['sconto'],
        'provenienza'          : msg['provenienza'],
      });

      ws.add(jsonEncode({'type': 'addDocumentResponse', 'success': true}));
    } catch (err) {
      debugPrint(err.toString());
      ws.add(jsonEncode({'type': 'addDocumentResponse', 'success': false}));
    }
  }
}


// ---- tabelle globali ---------------------------------------------------------

Future<void> getTablesDecodebleForClient(WebSocket ws, int idRoom) async {
  final tables = await TableModel.listTableForRoom(idRoom);
  ws.add(jsonEncode({'type': 'tables', 'tables': tables}));
  if (vistaTableKey.currentState != null) {
    vistaTableKey.currentState!.setTableByServer();
  }
}

Future<void> getALLTablesDecodebleForClient(List<ClientWebSocket> clients) async {
  try {
    final tables = await TableModel.listAllTable();
    for (final c in clients) {
      c.ws.add(jsonEncode({'type': 'tables', 'tables': tables}));
    }
    tableByServerForClient = tables.map((t) => TableModel.fromMap(t)).toList();
    if (vistaTableKey.currentState != null && vistaTableKey.currentState!.mounted) {
      vistaTableKey.currentState!.setTableByServer();
    }
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> lockTablesForClient(WebSocket ws, int idTable, List<ClientWebSocket> clients) async {
  try {
    final lock = await TableModel.blockTable(idTable);
    if (!lock) {
      ws.add(jsonEncode({'type': 'opendTable', 'idTable': idTable}));
      getALLTablesDecodebleForClient(clients);
    }
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> unLockTablesForClient(WebSocket ws, int idTable, List<ClientWebSocket> clients) async {
  try {
    await TableModel.unLockTable(idTable);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> openTable(WebSocket ws, int idTable, int idOperator, int covers, List<ClientWebSocket> clients) async {
  try {
    await TableModel.openTable(idTable, idOperator, covers);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> moveTable(WebSocket ws, TableModel from, TableModel to, List<ClientWebSocket> clients) async {
  try {
    await TableModel.moveTable(from, to);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> updateTable(WebSocket ws, int idTable, TableModel table, int idOperator, List<ClientWebSocket> clients) async {
  try {
    await TableModel.updateTable(idTable, table, idOperator);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> setNoteTable(WebSocket ws, int idTable, String note, List<ClientWebSocket> clients) async {
  try {
    await TableModel.setNoteTable(idTable, note);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> impegnaTable(WebSocket ws, int idTable, String note, List<ClientWebSocket> clients, int covers) async {
  try {
    await TableModel.impegnaTable(idTable, note, covers);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> resetTable(WebSocket ws, int idTable, List<ClientWebSocket> clients) async {
  try {
    await TableModel.resetTable(idTable);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> testLook(int idTable, List<ClientWebSocket> clients) async {
  try {
    await TableModel.blockTable(idTable);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> joinTables(List<ClientWebSocket> clients, TableModel parent, List<TableModel> children) async {
  try {
    await TableModel.joinedTablesWithParent(parent, children);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}

Future<void> unJoinTables(List<ClientWebSocket> clients, List<TableModel> children, TableModel parent) async {
  try {
    await TableModel.resetMultiTables(children, parent);
    getALLTablesDecodebleForClient(clients);
  } catch (err) {
    debugPrint(err.toString());
  }
}


// ---- test totem order --------------------------------------------------------

Future<void> testTotemOrderPost() async {
  try {
    final article = ArticleWhitPriceListModel(
      id         : 1,
      articleType: ArticleType.product,
      code       : 'TEST001',
      title      : 'Pizza Margherita Test',
      price      : '8.50',
      rateValue  : '10',
      idVatRate  : 1,
    );

    final prodotto = ProdottoCarrello(
      uuid               : const Uuid().v4(),
      isVariant          : false,
      exit               : 1,
      article            : article,
      quantity           : 2,
      unitPrice          : 8.50,
      percentageDiscount : 0,
      valueDiscount      : 0,
      variationsMinus    : [],
      variationsPlus     : [],
      variationsInfo     : [],
      variationsFree     : [],
      nameOperator       : 'Totem',
      idOperator         : 0,
      printed            : 0,
      discountPercentageRow: 0,
    );

    final ordine = Ordine( //order
      nomeCliente    : 'Cliente Totem',
      cliente        : null,
      tipo           : OrdineTipo.ritiro,
      stato          : OrdineStato.nuovo,
      data           : DateTime.now(),
      articles       : [prodotto],
      paid           : 0,
      telefono       : '3331234567',
      note           : 'ordine di test',
      callerPager    : orderTestNumber.toString(),
      idRider        : null,
      change         : null,
      receiptPrinted : 0,
    );
    orderTestNumber ++;
    final uri = Uri.parse('http://10.3.6.52:4040/totemOrder');

    final resp = await HttpClient().postUrl(uri).then((r) {
      final bytes = utf8.encode(jsonEncode(ordine.toJson()));
      r.headers
        ..set('Content-Type', 'application/json')
        ..set('Content-Length', bytes.length.toString());
      r.add(bytes);
      return r.close();
    });

    final body = await resp.transform(utf8.decoder).join();
    debugPrint('test totem — ${resp.statusCode} $body');
  } catch (err) {
    debugPrint('test totem errore: $err');
  }
}
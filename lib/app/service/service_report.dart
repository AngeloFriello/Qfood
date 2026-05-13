import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/turno_client.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';


class TurnoLavoro {
  final int? id;
  final String uuidTurno;
  final String nomeTurno;
  final int idOperatoreApertura;
  final int idOperatoreLoggato;
  final double? fondoCassaIniziale;
  final double? fondoCassaFinale;
  final double? fondoCassaTrovato;
  final String? dataOraCreazione;
  final String? tipoDocumento;
  final double? totaleDocumento;
  final String? chiusuraCassa;
  final int turnoChiuso;
  final double? sconto;
  final String? provenienza;
  final double? amountFood;
  final double? amountBeverage;
  final double? amountAltro;
  final double contanti;
  final double elettronico;
  final double tickets;
  final double assegno;


  const TurnoLavoro({
    this.id,
    required this.uuidTurno,
    required this.nomeTurno,
    required this.idOperatoreApertura,
    required this.idOperatoreLoggato,
    this.fondoCassaIniziale,
    this.fondoCassaFinale,
    this.fondoCassaTrovato,
    this.dataOraCreazione,
    this.tipoDocumento,
    this.totaleDocumento,
    this.chiusuraCassa,
    this.turnoChiuso = 0,
    this.sconto,
    this.provenienza,
    this.amountFood,
    this.amountBeverage,
    this.amountAltro,
    this.contanti = 0,
    this.elettronico = 0,
    this.tickets = 0,
    this.assegno = 0,
  });


  factory TurnoLavoro.fromMap(Map<String, dynamic> map) {
    return TurnoLavoro(
      id: map['id'] as int?,
      uuidTurno: map['uuid_turno'] as String,
      nomeTurno: map['nome_turno'] as String,
      idOperatoreApertura: map['id_operatore_apertura'] as int,
      idOperatoreLoggato: map['id_operatore_loggato'] as int,
      fondoCassaIniziale: (map['fondo_cassa_iniziale'] as num?)?.toDouble(),
      fondoCassaFinale: (map['fondo_cassa_finale'] as num?)?.toDouble(),
      fondoCassaTrovato: (map['fondo_cassa_trovato'] as num?)?.toDouble(),
      dataOraCreazione: map['data_ora_creazione'] as String?,
      tipoDocumento: map['tipo_documento'] as String?,
      totaleDocumento: (map['totale_documento'] as num?)?.toDouble(),
      chiusuraCassa: map['chiusura_cassa'] as String?,
      turnoChiuso: map['turno_chiuso'] as int,
      sconto: (map['sconto'] as num?)?.toDouble(),
      provenienza: map['provenienza'] as String?,
      amountFood: (map['amount_food'] as num?)?.toDouble(),
      amountBeverage: (map['amount_beverage'] as num?)?.toDouble(),
      amountAltro: (map['amount_altro'] as num?)?.toDouble(),
      contanti: (map['contanti'] as num).toDouble(),
      elettronico: (map['elettronico'] as num).toDouble(),
      tickets: (map['tickets'] as num).toDouble(),
      assegno: (map['assegno'] as num).toDouble(),
    );
  }


  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'uuid_turno'           : uuidTurno,
    'nome_turno'           : nomeTurno,
    'id_operatore_apertura': idOperatoreApertura,
    'id_operatore_loggato' : idOperatoreLoggato,
    'fondo_cassa_iniziale' : fondoCassaIniziale,
    'fondo_cassa_finale'   : fondoCassaFinale,
    'fondo_cassa_trovato'  : fondoCassaTrovato,
    'tipo_documento'       : tipoDocumento,
    'totale_documento'     : totaleDocumento,
    'chiusura_cassa'       : chiusuraCassa,
    'turno_chiuso'         : turnoChiuso,
    'sconto'               : sconto,
    'provenienza'          : provenienza,
    'amount_food'          : amountFood,
    'amount_beverage'      : amountBeverage,
    'amount_altro'         : amountAltro,
    'contanti'             : contanti,
    'elettronico'          : elettronico,
    'tickets'              : tickets,
    'assegno'              : assegno,
  };


  bool get isChiuso => turnoChiuso == 1;


  // ─────────────────────────────────────────────────────────────────────────────
  static Future<bool> lastShiftOpened() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    dynamic device = jsonDecode(pref.getString('device') ?? '{}');
    if (device == null || device.isEmpty) return false;

    if (device['deviceServer'] == 1) {
      if (operatorLogged == null) return false;

      final db = await LocalDB.instance();

      // Step 1: trova l'uuid dell'ultimo turno di questo operatore
      final lastShift = await db.query(
        'turno_lavoro',
        columns: ['uuid_turno'],
        where: 'id_operatore_apertura = ?',
        whereArgs: [operatorLogged!.id],
        orderBy: 'id DESC',
        limit: 1,
      );

      if (lastShift.isEmpty) return false;

      final String uuid = lastShift.first['uuid_turno'] as String;

      // Step 2: verifica se esiste una riga di chiusura per quell'uuid
      final closedRow = await db.query(
        'turno_lavoro',
        columns: ['id'],
        where: 'uuid_turno = ? AND turno_chiuso = ?',
        whereArgs: [uuid, 1],
        limit: 1,
      );

      // Se NON esiste la riga di chiusura → turno ancora aperto
      return closedRow.isEmpty;

    } else {
      // CLIENT → chiede al server via WebSocket
      return await TurnoLavoroWsClient.lastShiftOpened();
    }
  }

  static Future<double> fondoIniziale( String? uuidTurno ) async {
    double fondo = 0;
    try{
      String query =  'SELECT * FROM turno_lavoro';
      if( uuidTurno != null ) query +=  ' WHERE uuid_turno = "$uuidTurno"';
      final resp = await LocalDB.query(query);
      if( resp.isNotEmpty ){
        fondo = resp.first['fondo_cassa_iniziale'];
      }

    }catch( err ){
      debugPrint( err.toString() );
    }finally{
      return fondo;
    }
  }

  static Future<double> fondoInizialeOggiGenerale() async {
  double totale = 0;
  try {
    final String oggi = DateTime.now().toIso8601String().substring(0, 10);

    // Somma fondo_cassa_iniziale di tutti i turni aperti oggi
    // (una riga per turno = la riga di apertura, cioè turno_chiuso = 0)
    final String query = '''
      SELECT SUM(fondo_cassa_iniziale) as totale_fondo
      FROM turno_lavoro
      WHERE DATE(data_ora_creazione) = "$oggi"
        AND turno_chiuso = 0
        AND id IN (
          SELECT MIN(id) FROM turno_lavoro
          WHERE DATE(data_ora_creazione) = "$oggi"
          GROUP BY uuid_turno
        )
    ''';

    final resp = await LocalDB.query(query);

    if (resp.isNotEmpty && resp.first['totale_fondo'] != null) {
      totale = (resp.first['totale_fondo'] as num).toDouble();
    }
  } catch (err) {
    debugPrint(err.toString());
  }
  return totale;
}

  static Future<double> fondoFinale( String? uuidTurno ) async {
    double fondo = 0;
    try{
      String query =  'SELECT * FROM turno_lavoro WHERE fondo_cassa_finale IS NOT NULL';
      if( uuidTurno != null ) query +=  ' AND uuid_turno = "$uuidTurno"';
      final resp = await LocalDB.query(query);
      if( resp.isNotEmpty ){
        fondo = resp.first['fondo_cassa_finale'];
      }

    }catch( err ){
      debugPrint( err.toString() );
    }finally{
      return fondo;
    }
  }

  static Future<double> fondoFinaleOggi() async {
  double totale = 0;
  try {
    final String oggi = DateTime.now().toIso8601String().substring(0, 10);

    // Somma i fondi finali di tutti i turni chiusi oggi
    // (solo righe dove fondo_cassa_finale è valorizzato = turni chiusi)
    final String query = '''
      SELECT SUM(fondo_cassa_finale) as totale_fondo
      FROM turno_lavoro
      WHERE DATE(data_ora_creazione) = "$oggi"
        AND fondo_cassa_finale IS NOT NULL
        AND turno_chiuso = 1
    ''';

    final resp = await LocalDB.query(query);

    if (resp.isNotEmpty && resp.first['totale_fondo'] != null) {
      totale = (resp.first['totale_fondo'] as num).toDouble();
    }
  } catch (err) {
    debugPrint(err.toString());
  }
  return totale;
}


  // ─────────────────────────────────────────────────────────────────────────────
  static Future<int> openShift({
    required String nomeTurno,
    required double fondoCassaIniziale,
  }) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    dynamic device = jsonDecode(pref.getString('device') ?? '{}');
    if (device == null || device.isEmpty) return 0;

    if (device['deviceServer'] == 1) {
      final db = await LocalDB.instance();
      final String uuidTurno = const Uuid().v4();

      final int id = await db.insert(
        'turno_lavoro',
        {
          'uuid_turno':            uuidTurno,
          'nome_turno':            nomeTurno,
          'id_operatore_apertura': operatorLogged!.id,
          'id_operatore_loggato':  operatorLogged!.id,
          'fondo_cassa_iniziale':  fondoCassaIniziale,
          'fondo_cassa_trovato':   fondoCassaIniziale,
        },
      );

      return id;

    } else {
      // CLIENT → invia la richiesta di apertura turno al server via WebSocket
      return await TurnoLavoroWsClient.openShift(
        nomeTurno:          nomeTurno,
        fondoCassaIniziale: fondoCassaIniziale,
      );
    }
  }


  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> closeShift({
    required double fondoCassaFinale,
    String? chiusuraCassa,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      dynamic device = jsonDecode(pref.getString('device') ?? '{}');
      if (device == null || device.isEmpty) return;

      if (device['deviceServer'] == 1) {
        final db = await LocalDB.instance();

        final result = await db.query(
          'turno_lavoro',
          columns: ['uuid_turno', 'nome_turno', 'id_operatore_apertura', 'fondo_cassa_iniziale'],
          where: 'turno_chiuso = ? AND id_operatore_apertura = ?',
          whereArgs: [0, operatorLogged!.id],
          orderBy: 'id DESC',
          limit: 1,
        );

        if (result.isEmpty) {
          debugPrint('Nessun turno aperto trovato');
          return;
        }

        final String uuidTurno          = result.first['uuid_turno'] as String;
        final String nomeTurno          = result.first['nome_turno'] as String;
        final int idOratorOpenedTurn    = result.first['id_operatore_apertura'] as int;
        final double fondoCassaIniziale = result.first['fondo_cassa_iniziale'] as double;

        await db.insert(
          'turno_lavoro',
          {
            'uuid_turno':            uuidTurno,
            'nome_turno':            nomeTurno,
            'id_operatore_apertura': idOratorOpenedTurn,
            'id_operatore_loggato':  operatorLogged!.id,
            'fondo_cassa_finale':    fondoCassaFinale,
            'fondo_cassa_iniziale':  fondoCassaIniziale,
            'chiusura_cassa':        chiusuraCassa,
            'turno_chiuso':          1,
          },
        );

        debugPrint('Turno $nomeTurno chiuso con uuid: $uuidTurno');

      } else {
        // CLIENT → invia la richiesta di chiusura turno al server via WebSocket
        await TurnoLavoroWsClient.closeShift(
          fondoCassaFinale: fondoCassaFinale,
          chiusuraCassa:    chiusuraCassa,
        );
      }

    } catch (err) {
      debugPrint(err.toString());
    }
  }


  // ─────────────────────────────────────────────────────────────────────────────
  /// tipoDocumento: receipt, invoice, cancel_receipt, credit_note, simulation
  static Future<void> addDocumentToShift({
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
    SharedPreferences pref = await SharedPreferences.getInstance();
    dynamic device = jsonDecode(pref.getString('device') ?? '{}');
    if (device == null || device.isEmpty) return;

    if (device['deviceServer'] == 1) {
      final db = await LocalDB.instance();

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
        return;
      }

      final String uuidTurno           = result.first['uuid_turno'] as String;
      final String nomeTurno           = result.first['nome_turno'] as String;
      final int idOperatoreApertura    = result.first['id_operatore_apertura'] as int;
      final double? fondoCassaIniziale = (result.first['fondo_cassa_iniziale'] as num?)?.toDouble();

      await db.insert(
        'turno_lavoro',
        {
          'uuid_turno'           : uuidTurno,
          'nome_turno'           : nomeTurno,
          'id_operatore_apertura': idOperatoreApertura,
          'id_operatore_loggato' : operatorLogged!.id,
          'fondo_cassa_iniziale' : fondoCassaIniziale,
          'tipo_documento'       : tipoDocumento,
          'totale_documento'     : totaleDocumento,
          'turno_chiuso'         : 0,
          'contanti'             : contanti,
          'elettronico'          : elettronico,
          'tickets'              : tickets,
          'assegno'              : assegno,
          'amount_food'          : amountFood,
          'amount_beverage'      : amountBeverage,
          'amount_altro'         : amountAltro,
          'sconto'               : sconto,
          'provenienza'          : provenienza,
        },
      );

      debugPrint('Documento $tipoDocumento aggiunto al turno $nomeTurno');

    } else {
      // CLIENT → invia il documento al server via WebSocket
      await TurnoLavoroWsClient.addDocumentToShift(
        tipoDocumento:   tipoDocumento,
        totaleDocumento: totaleDocumento,
        contanti:        contanti,
        elettronico:     elettronico,
        tickets:         tickets,
        assegno:         assegno,
        amountFood:      amountFood,
        amountBeverage:  amountBeverage,
        amountAltro:     amountAltro,
        sconto:          sconto,
        provenienza:     provenienza,
      );
    }
  }


  // ─────────────────────────────────────────────────────────────────────────────
  static Future<Map<String, double>> getTotalsByDocumentTypeLastShift({
    bool lastClosedShift = false,
    bool lastLogin       = false,
    String? fromTime,
    String? tipoReport,
    String? uuidTurno,
    DateTime? from,
    DateTime? to,
    int? idOperator,
  }) async {
    final db = await LocalDB.instance();
    SharedPreferences pref = await SharedPreferences.getInstance();
    dynamic device = jsonDecode(pref.getString('device') ?? '{}');
    if (device == null || device.isEmpty) return {};

    if (device['deviceServer'] == 1) {
      // ── uuidTurno bypassa tutto il resto ──────────────────────────────────
      if (uuidTurno != null) {
        final byType = await db.rawQuery('''
          SELECT
            tipo_documento,
            COUNT(*)              AS num_documenti,
            SUM(totale_documento) AS totale
          FROM turno_lavoro
          WHERE uuid_turno = ?
            AND tipo_documento IS NOT NULL
            AND totale_documento IS NOT NULL
          GROUP BY tipo_documento
        ''', [uuidTurno]);

        final globals = await db.rawQuery('''
          SELECT
            SUM(amount_food)      AS totale_food,
            SUM(amount_beverage)  AS totale_beverage,
            SUM(amount_altro)     AS totale_altro,
            SUM(contanti)         AS totale_contanti,
            SUM(elettronico)      AS totale_elettronico,
            SUM(tickets)          AS totale_tickets,
            SUM(assegno)          AS totale_assegno,
            SUM(sconto)           AS totale_sconto
          FROM turno_lavoro
          WHERE uuid_turno = ?
        ''', [uuidTurno]);

        return _buildResult(byType, globals);
      }

      // ── fromTime bypassa tutto il resto ───────────────────────────────────
      if (fromTime != null) {
        final now = DateTime.now();
        final todayFrom = DateTime.parse(
          '${now.toIso8601String().substring(0, 10)}T$fromTime',
        );

        final byType = await db.rawQuery('''
          SELECT
            tipo_documento,
            COUNT(*)              AS num_documenti,
            SUM(totale_documento) AS totale
          FROM turno_lavoro
          WHERE data_ora_creazione >= ?
            AND data_ora_creazione <= ?
            AND tipo_documento IS NOT NULL
            AND totale_documento IS NOT NULL
          GROUP BY tipo_documento
        ''', [todayFrom.toIso8601String(), now.toIso8601String()]);

        final globals = await db.rawQuery('''
          SELECT
            SUM(amount_food)      AS totale_food,
            SUM(amount_beverage)  AS totale_beverage,
            SUM(amount_altro)     AS totale_altro,
            SUM(contanti)         AS totale_contanti,
            SUM(elettronico)      AS totale_elettronico,
            SUM(tickets)          AS totale_tickets,
            SUM(assegno)          AS totale_assegno,
            SUM(sconto)           AS totale_sconto
          FROM turno_lavoro
          WHERE data_ora_creazione >= ?
            AND data_ora_creazione <= ?
        ''', [todayFrom.toIso8601String(), now.toIso8601String()]);

        return _buildResult(byType, globals);
      }

      // ── lastLogin bypassa tutto il resto ──────────────────────────────────
      if (lastLogin) {
        final lastRow = await db.query(
          'turno_lavoro',
          columns: ['id', 'id_operatore_loggato'],
          orderBy: 'id DESC',
          limit: 1,
        );
        if (lastRow.isEmpty) return {};

        final idOperatoreLoggato = lastRow.first['id_operatore_loggato'] as int?;
        if (idOperatoreLoggato == null) return {};

        final lastId = lastRow.first['id'] as int;

        final firstDifferent = await db.rawQuery('''
          SELECT id FROM turno_lavoro
          WHERE id < ?
            AND (id_operatore_loggato != ? OR id_operatore_loggato IS NULL)
          ORDER BY id DESC
          LIMIT 1
        ''', [lastId, idOperatoreLoggato]);

        final minId = firstDifferent.isNotEmpty
            ? (firstDifferent.first['id'] as int) + 1
            : 0;

        final byType = await db.rawQuery('''
          SELECT
            tipo_documento,
            COUNT(*)              AS num_documenti,
            SUM(totale_documento) AS totale
          FROM turno_lavoro
          WHERE id_operatore_loggato = ?
            AND id >= ?
            AND tipo_documento IS NOT NULL
            AND totale_documento IS NOT NULL
          GROUP BY tipo_documento
        ''', [idOperatoreLoggato, minId]);

        final globals = await db.rawQuery('''
          SELECT
            SUM(amount_food)      AS totale_food,
            SUM(amount_beverage)  AS totale_beverage,
            SUM(amount_altro)     AS totale_altro,
            SUM(contanti)         AS totale_contanti,
            SUM(elettronico)      AS totale_elettronico,
            SUM(tickets)          AS totale_tickets,
            SUM(assegno)          AS totale_assegno,
            SUM(sconto)           AS totale_sconto
          FROM turno_lavoro
          WHERE id_operatore_loggato = ?
            AND id >= ?
        ''', [idOperatoreLoggato, minId]);

        return _buildResult(byType, globals);
      }

      // ── from/to con filtro operatore e tipoReport opzionali ───────────────
      if (from != null || to != null) {
        final List<String> whereParts = [];
        final List<dynamic> whereArgs = [];

        if (from != null) {
          whereParts.add("data_ora_creazione >= ?");
          whereArgs.add(from.toIso8601String());
        }
        if (to != null) {
          final endOfDay = to.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
          whereParts.add("data_ora_creazione <= ?");
          whereArgs.add(endOfDay.toIso8601String());
        }
        if (idOperator != null) {
          whereParts.add("id_operatore_loggato = ?");
          whereArgs.add(idOperator);
        }
        if (tipoReport == "Simulazione") {
          whereParts.add("tipo_documento = ?");
          whereArgs.add("simulation");
        } else if (tipoReport == "Vendite") {
          whereParts.add("tipo_documento != ?");
          whereArgs.add("simulation");
        }

        final whereClause = 'WHERE ${whereParts.join(' AND ')}';

        final byType = await db.rawQuery('''
          SELECT
            tipo_documento,
            COUNT(*)              AS num_documenti,
            SUM(totale_documento) AS totale
          FROM turno_lavoro
          $whereClause
            AND tipo_documento IS NOT NULL
            AND totale_documento IS NOT NULL
          GROUP BY tipo_documento
        ''', whereArgs);

        final globals = await db.rawQuery('''
          SELECT
            SUM(amount_food)      AS totale_food,
            SUM(amount_beverage)  AS totale_beverage,
            SUM(amount_altro)     AS totale_altro,
            SUM(contanti)         AS totale_contanti,
            SUM(elettronico)      AS totale_elettronico,
            SUM(tickets)          AS totale_tickets,
            SUM(assegno)          AS totale_assegno,
            SUM(sconto)           AS totale_sconto
          FROM turno_lavoro
          $whereClause
        ''', whereArgs);

        return _buildResult(byType, globals);
      }

      // ── Logica turno (default) ────────────────────────────────────────────
      final List<String> whereParts = [];
      final List<dynamic> whereArgs = [];

      if (lastClosedShift) {
        whereParts.add('turno_chiuso = ?');
        whereArgs.add(1);
      }

      final lastShift = await db.query(
        'turno_lavoro',
        columns: ['uuid_turno'],
        where: whereParts.isNotEmpty ? whereParts.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'id DESC',
        limit: 1,
      );

      if (lastShift.isEmpty) return {};

      final String lastUuidTurno = lastShift.first['uuid_turno'] as String;

      final byType = await db.rawQuery('''
        SELECT
          tipo_documento,
          COUNT(*)              AS num_documenti,
          SUM(totale_documento) AS totale
        FROM turno_lavoro
        WHERE uuid_turno = ?
          AND tipo_documento IS NOT NULL
          AND totale_documento IS NOT NULL
        GROUP BY tipo_documento
      ''', [lastUuidTurno]);

      final globals = await db.rawQuery('''
        SELECT
          SUM(amount_food)      AS totale_food,
          SUM(amount_beverage)  AS totale_beverage,
          SUM(amount_altro)     AS totale_altro,
          SUM(contanti)         AS totale_contanti,
          SUM(elettronico)      AS totale_elettronico,
          SUM(tickets)          AS totale_tickets,
          SUM(assegno)          AS totale_assegno,
          SUM(sconto)           AS totale_sconto
        FROM turno_lavoro
        WHERE uuid_turno = ?
      ''', [lastUuidTurno]);

      return _buildResult(byType, globals);

    } else {
      // CLIENT → chiede i totali al server via WebSocket
      return await TurnoLavoroWsClient.getTotalsByDocumentType(
        lastClosedShift: lastClosedShift,
        lastLogin:       lastLogin,
        fromTime:        fromTime,
        tipoReport:      tipoReport,
        uuidTurno:       uuidTurno,
        from:            from,
        to:              to,
        idOperator:      idOperator,
      );
    }
  }


  // ─────────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getTurniUltimi6Mesi() async {
    final db = await LocalDB.instance();
    final sevenMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    SharedPreferences pref = await SharedPreferences.getInstance();
    dynamic device = jsonDecode(pref.getString('device') ?? '{}');
    if (device == null || device.isEmpty) return [];

    if (device['deviceServer'] == 1) {
      final uuids = await db.rawQuery('''
        SELECT uuid_turno
        FROM turno_lavoro
        WHERE data_ora_creazione >= ?
        GROUP BY uuid_turno
        ORDER BY MIN(id) DESC
      ''', [sevenMonthsAgo.toIso8601String()]);

      if (uuids.isEmpty) return [];

      final List<Map<String, dynamic>> result = [];

      for (final row in uuids) {
        final uuid = row['uuid_turno'] as String;

        final firstRow = await db.query(
          'turno_lavoro',
          columns: ['nome_turno', 'data_ora_creazione'],
          where: 'uuid_turno = ?',
          whereArgs: [uuid],
          orderBy: 'id ASC',
          limit: 1,
        );

        final closedRow = await db.query(
          'turno_lavoro',
          columns: ['data_ora_creazione'],
          where: 'uuid_turno = ? AND turno_chiuso = 1',
          whereArgs: [uuid],
          orderBy: 'id ASC',
          limit: 1,
        );

        if (firstRow.isEmpty) continue;

        result.add({
          'nomeTurno': "${firstRow.first['nome_turno']} - ${formatDate(firstRow.first['data_ora_creazione'].toString())} / ${closedRow.isNotEmpty ? formatDate(closedRow.first['data_ora_creazione'].toString()) : 'in corso'} ",
          'uuidTurno':       uuid,
          'dataInizioTurno': firstRow.first['data_ora_creazione'],
          'dataFineTurno':   closedRow.isNotEmpty ? closedRow.first['data_ora_creazione'] : null,
        });
      }

      return result;

    } else {
      // CLIENT → chiede la lista dei turni al server via WebSocket
      return await TurnoLavoroWsClient.getTurniUltimi6Mesi();
    }
  }


  // ─────────────────────────────────────────────────────────────────────────────
  static String formatDate(String? isoDate) {
    if (isoDate == null) return 'in corso';
    final dt = DateTime.parse(isoDate);
    return '${dt.day.toString().padLeft(2, '0')}-'
           '${dt.month.toString().padLeft(2, '0')}-'
           '${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }


  // ─────────────────────────────────────────────────────────────────────────────
  /// Helper interno: costruisce la Map<String, double> dai risultati SQL.
  static Map<String, double> _buildResult(
    List<Map<String, Object?>> byType,
    List<Map<String, Object?>> globals,
  ) {
    final Map<String, double> result = {};

    for (final row in byType) {
      final tipo = row['tipo_documento'] as String;
      result['amount_$tipo'] = (row['totale'] as num).toDouble();
      result['number_$tipo'] = (row['num_documenti'] as num).toDouble();
    }

    final g = globals.first;
    result['totale_food']        = (g['totale_food']        as num? ?? 0).toDouble();
    result['totale_beverage']    = (g['totale_beverage']    as num? ?? 0).toDouble();
    result['totale_altro']       = (g['totale_altro']       as num? ?? 0).toDouble();
    result['totale_contanti']    = (g['totale_contanti']    as num? ?? 0).toDouble();
    result['totale_elettronico'] = (g['totale_elettronico'] as num? ?? 0).toDouble();
    result['totale_tickets']     = (g['totale_tickets']     as num? ?? 0).toDouble();
    result['totale_assegno']     = (g['totale_assegno']     as num? ?? 0).toDouble();
    result['totale_sconto']      = (g['totale_sconto']      as num? ?? 0).toDouble();

    final totaleDocs = result.entries
        .where((e) => e.key.startsWith('amount_'))
        .fold(0.0, (sum, e) => sum + e.value);

    final totaleSimulation = result['amount_simulation'] ?? 0.0;

    result['percentuale_simulation'] = totaleDocs > 0
        ? (totaleSimulation / totaleDocs) * 100
        : 0.0;
    result['totale_vendite'] = totaleDocs;

    return result;
  }

  static Future<void> delete(int idMov) async {
    final db = await LocalDB.instance();
    await db.update(
      'movimenti_cassa',
      {'deleted': 1},
      where: 'id = ?',
      whereArgs: [idMov],
    );
  }

    static Future<Map<String, dynamic>> getCurrentCashStatus() async {
  const Map<String, dynamic> zero = {
    'uuidTurno'            : null,
    'nomeTurno'            : null,
    'fondoIniziale'        : 0.0,
    'totaleDocumenti'      : 0.0,
    'totaleEntrate'        : 0.0,
    'totaleUscite'         : 0.0,
    'totaleCassa'          : 0.0,
    'fondoFinalePrecedente': 0.0,
  };

  SharedPreferences pref = await SharedPreferences.getInstance();
  dynamic device = jsonDecode(pref.getString('device') ?? '{}');
  if (device == null || device.isEmpty) return zero;

  if (device['deviceServer'] == 1) {
    final db = await LocalDB.instance();

    // 1) ultimo turno per operatore
    final lastShift = await db.query(
      'turno_lavoro',
      columns: ['uuid_turno', 'nome_turno'],
      where: 'id_operatore_apertura = ?',
      whereArgs: [operatorLogged!.id],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (lastShift.isEmpty) return zero;

    final String uuidTurno = lastShift.first['uuid_turno'] as String;
    final String nomeTurno = lastShift.first['nome_turno'] as String;

    // 2) se esiste riga di chiusura → tutto a 0, uuidTurno = null
    final closedRow = await db.query(
      'turno_lavoro',
      columns: ['id'],
      where: 'uuid_turno = ? AND turno_chiuso = 1',
      whereArgs: [uuidTurno],
      limit: 1,
    );

    if (closedRow.isNotEmpty) {
      return {
        'uuidTurno'            : null,
        'nomeTurno'            : nomeTurno,
        'fondoIniziale'        : 0.0,
        'totaleDocumenti'      : 0.0,
        'totaleEntrate'        : 0.0,
        'totaleUscite'         : 0.0,
        'totaleCassa'          : 0.0,
        'fondoFinalePrecedente': 0.0,
      };
    }

    // 3) fondo cassa iniziale (prima riga del turno)
    final firstRow = await db.query(
      'turno_lavoro',
      columns: ['fondo_cassa_iniziale'],
      where: 'uuid_turno = ?',
      whereArgs: [uuidTurno],
      orderBy: 'id ASC',
      limit: 1,
    );

    final double fondoIniziale =
        (firstRow.first['fondo_cassa_iniziale'] as num?)?.toDouble() ?? 0.0;

    // 4) somma dei CONTANTI del turno (da turno_lavoro)
    final sumResult = await db.rawQuery('''
      SELECT SUM(contanti) AS totale_contanti_turno
      FROM turno_lavoro
      WHERE uuid_turno = ?
        AND contanti IS NOT NULL
    ''', [uuidTurno]);

    final double totaleDocumenti =
        (sumResult.first['totale_contanti_turno'] as num?)?.toDouble() ?? 0.0;

    // 5) entrate e uscite da movimenti_cassa per questo turno (solo contanti)
    final movimentiResult = await db.rawQuery('''
      SELECT
        tipo_movimento,
        SUM(importo) AS totale_importo
      FROM movimenti_cassa
      WHERE uuid_turno = ?
        AND metodo_pagamento = 'contanti'
        AND deleted = 0
        AND tipo_movimento IN ('entrata', 'uscita')
      GROUP BY tipo_movimento
    ''', [uuidTurno]);

    double totaleEntrate = 0.0;
    double totaleUscite  = 0.0;

    for (final row in movimentiResult) {
      final tipo    = row['tipo_movimento'] as String;
      final importo = (row['totale_importo'] as num?)?.toDouble() ?? 0.0;
      if (tipo == 'entrata') totaleEntrate = importo;
      if (tipo == 'uscita')  totaleUscite  = importo;
    }

    // 6) totale cassa = fondo iniziale + contanti turno + entrate - uscite
    final double totaleCassa =
        fondoIniziale + totaleDocumenti + totaleEntrate - totaleUscite;

    // 7) fondo cassa finale turno precedente (ultimo turno chiuso)
    final lastClosed = await db.query(
      'turno_lavoro',
      columns: ['fondo_cassa_finale'],
      where: 'turno_chiuso = 1 AND id_operatore_apertura = ?',
      whereArgs: [operatorLogged!.id],
      orderBy: 'id DESC',
      limit: 1,
    );

    final double fondoFinalePrecedente =
        (lastClosed.isNotEmpty
                ? (lastClosed.first['fondo_cassa_finale'] as num?)
                : null)
            ?.toDouble() ??
        0.0;

    return {
      'uuidTurno'            : uuidTurno,
      'nomeTurno'            : nomeTurno,
      'fondoIniziale'        : fondoIniziale,
      'totaleDocumenti'      : totaleDocumenti,
      'totaleEntrate'        : totaleEntrate,
      'totaleUscite'         : totaleUscite,
      'totaleCassa'          : totaleCassa,
      'fondoFinalePrecedente': fondoFinalePrecedente,
    };
  } else {
    return {
      'uuidTurno'            : null,
      'nomeTurno'            : '',
      'fondoIniziale'        : 0.0,
      'totaleDocumenti'      : 0.0,
      'totaleEntrate'        : 0.0,
      'totaleUscite'         : 0.0,
      'totaleCassa'          : 0.0,
      'fondoFinalePrecedente': 0.0,
    };
  }
}
}
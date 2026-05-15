import 'package:dashboard/Global.dart';
import 'package:uuid/uuid.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';

class MovimentoCassa {
  final int? id;
  final String uuidMovimento;
  final String uuidTurno;
  final int idOperatore;
  final String dataOraCreazione;

  final String tipoMovimento;            // 'entrata' | 'uscita'
  final String categoria;                // es. 'pagamento_fornitore', 'versamento_banca', ...

  final String? descrizione;
  final double importo;                  // importo > 0, direzione data da tipoMovimento
  final String metodoPagamento;          // 'contanti', 'elettronico', 'assegno', 'tickets', ...

  final String? contropartitaNome;
  final String? contropartitaRiferimento;
  final String? provenienza;
  final String? note;

  final String? deviceId;
  final int sincronizzatoServer;         // 0 = no, 1 = sì
  final int deleted;                     // 0 = attivo, 1 = eliminato

  const MovimentoCassa({
    this.id,
    required this.uuidMovimento,
    required this.uuidTurno,
    required this.idOperatore,
    required this.dataOraCreazione,
    required this.tipoMovimento,
    required this.categoria,
    this.descrizione,
    required this.importo,
    required this.metodoPagamento,
    this.contropartitaNome,
    this.contropartitaRiferimento,
    this.provenienza,
    this.note,
    this.deviceId,
    this.sincronizzatoServer = 0,
    this.deleted = 0,
  });

  factory MovimentoCassa.fromMap(Map<String, dynamic> map) {
    return MovimentoCassa(
      id: map['id'] as int?,
      uuidMovimento: map['uuid_movimento'] as String,
      uuidTurno: map['uuid_turno'] as String,
      idOperatore: map['id_operatore'] as int,
      dataOraCreazione: map['data_ora_creazione'] as String,
      tipoMovimento: map['tipo_movimento'] as String,
      categoria: map['categoria'] as String,
      descrizione: map['descrizione'] as String?,
      importo: (map['importo'] as num).toDouble(),
      metodoPagamento: map['metodo_pagamento'] as String,
      contropartitaNome: map['contropartita_nome'] as String?,
      contropartitaRiferimento: map['contropartita_riferimento'] as String?,
      provenienza: map['provenienza'] as String?,
      note: map['note'] as String?,
      deviceId: map['device_id'] as String?,
      sincronizzatoServer: (map['sincronizzato_server'] as num?)?.toInt() ?? 0,
      deleted: (map['deleted'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid_movimento'           : uuidMovimento,
      'uuid_turno'               : uuidTurno,
      'id_operatore'             : idOperatore,
      'data_ora_creazione'       : dataOraCreazione,
      'tipo_movimento'           : tipoMovimento,
      'categoria'                : categoria,
      'descrizione'              : descrizione,
      'importo'                  : importo,
      'metodo_pagamento'         : metodoPagamento,
      'contropartita_nome'       : contropartitaNome,
      'contropartita_riferimento': contropartitaRiferimento,
      'provenienza'              : provenienza,
      'note'                     : note,
      'device_id'                : deviceId,
      'sincronizzato_server'     : sincronizzatoServer,
      'deleted'                  : deleted,
    };
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// Inserisce un movimento nella tabella `movimenti_cassa` e ritorna l'id.
  ///
  /// Usa:
  /// - uuidTurno: uuid del turno a cui agganciare il movimento
  /// - idOperatore: chi effettua l’operazione (es. operatorLogged!.id)
  static Future<int> insert({
    required String uuidTurno,
    required String tipoMovimento,       // 'entrata' | 'uscita' | 'neutro'
    required String categoria,           // es. 'pagamento_fornitore'
    String? descrizione,
    required double importo,
    required String metodoPagamento,     // 'contanti', 'elettronico', ...
    String? contropartitaNome,
    String? contropartitaRiferimento,
    String? provenienza,
    String? note,
    String? deviceId,
  }) async {
    final db = await LocalDB.instance();
    final nowIso = DateTime.now().toIso8601String();
    final uuid = const Uuid().v4();

    final movimento = MovimentoCassa(
      uuidMovimento: uuid,
      uuidTurno: uuidTurno,
      idOperatore: operatorLogged!.id,
      dataOraCreazione: nowIso,
      tipoMovimento: tipoMovimento,
      categoria: categoria,
      descrizione: descrizione,
      importo: importo,
      metodoPagamento: metodoPagamento,
      contropartitaNome: contropartitaNome,
      contropartitaRiferimento: contropartitaRiferimento,
      provenienza: provenienza,
      note: note,
      deviceId: deviceId,
      sincronizzatoServer: 0,
      deleted: 0,
    );

    final id = await db.insert(
      'movimenti_cassa',
      movimento.toMap(),
    );

    return id;
  }
}
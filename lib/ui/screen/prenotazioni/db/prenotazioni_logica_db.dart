import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/model_prenotazione.dart';
import '../model/prenotazione_channel.dart';
import '../model/prenotazione_stato.dart';

import 'prenotazioni_dao.dart';
import 'clienti_dao.dart';
import 'db_prenotazioni.dart';


/*
Logica DB: trasforma righe DB Prenotazione
salva prenotazione + cliente + tavoli
unica classe che conosce DAO + MODEL
 */
class PrenotazioniLogicaDb {
  final PrenotazioniDao _dao = PrenotazioniDao();
  final ClientiDao _clientiDao = ClientiDao();

  // CARICA E LEGGE IL DB
  Future<List<Prenotazione>> loadAll() async {
    debugPrint('[DB-LOGICA] LOAD ALL → START');

    final rows = await _dao.fetchAll();
    debugPrint('[DB-LOGICA] RIGHE LETTE → ${rows.length}');

    final prenotazioni = rows.map((r) {
      final start = DateTime.fromMillisecondsSinceEpoch(r['data']);

      final tavoli = (r['tavoli'] as String?)
          ?.split(',')
          .where((e) => e.isNotEmpty)
          .map(int.parse)
          .toList() ??
          [];

      final p = Prenotazione(
        id: r['id'],
        data: DateTime(start.year, start.month, start.day),
        orario: TimeOfDay.fromDateTime(start),
        durata: Duration(minutes: r['durata']),
        pax: r['pax'],

        clienteId: r['cliente_id'] ?? 0,
        clienteNome: r['cliente_nome'] ?? 'Cliente',
        telefono: r['cliente_telefono'],
        email: r['cliente_email'],
        note: r['note'] as String?,

        stato: PrenotazioneStato.values.firstWhere(
              (e) => e.name == r['stato'],
          orElse: () => PrenotazioneStato.daConfermare,
        ),
        channel: PrenotazioneChannel.values.firstWhere(
              (e) => e.name == r['canale'],
          orElse: () => PrenotazioneChannel.manuale,
        ),
        tavoli: tavoli,
      );

      debugPrint(
        '[DB-LOGICA] PRENOTAZIONE → '
            'ID=${p.id} | Cliente=${p.clienteNome} | '
            'Ora=${p.orario.hour.toString().padLeft(2, '0')}:'
            '${p.orario.minute.toString().padLeft(2, '0')} | '
            'Tavoli=${p.tavoli}',
      );

      return p;
    }).toList();

    debugPrint('[DB-LOGICA] LOAD ALL → END');
    return prenotazioni;
  }

  // FUNZIONE SALVA USATA DAL CONTROLLER
  Future<void> save(Prenotazione p) async {
    debugPrint('[DB-LOGICA] SAVE → START');

    // CLIENTE
    int clienteId;

    if (p.clienteId > 0) {
      clienteId = p.clienteId;
      debugPrint('[DB-LOGICA] CLIENTE DA UI → ID=$clienteId');
    } else {
      final cliente = await _clientiDao.findByContatto(
        telefono: p.telefono,
        email: p.email,
      );

      if (cliente != null) {
        clienteId = cliente['id'];
        debugPrint('[DB-LOGICA] CLIENTE TROVATO → ID=$clienteId');
      } else {
        clienteId = await _clientiDao.insertCliente(
          nome: p.clienteNome,
          telefono: p.telefono,
          email: p.email,
        );
        debugPrint('[DB-LOGICA] CLIENTE CREATO → ID=$clienteId');
      }
    }

    //SALVATAGGIO DELLA PRENOTAZIONE
    final int prenotazioneId = await _dao.insertPrenotazione({
      'data': p.startDateTime.millisecondsSinceEpoch,
      'durata': p.durata.inMinutes,
      'scadenza': p.end.millisecondsSinceEpoch,
      'pax': p.pax,

      'cliente_id': clienteId,
      'cliente_nome': p.clienteNome,
      'cliente_telefono': p.telefono,
      'cliente_email': p.email,
      'note': p.note,

      'canale': p.channel.name,
      'stato': p.stato.name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,

    });

    debugPrint('[DB-LOGICA] PRENOTAZIONE INSERITA → ID=$prenotazioneId');

    // TAVOLI
    if (p.tavoli.isNotEmpty) {
      await _dao.insertPrenotazioneTavoli(prenotazioneId, p.tavoli);
      debugPrint('[DB-LOGICA] TAVOLI ASSOCIATI → ${p.tavoli}');
    }

    debugPrint('[DB-LOGICA] SAVE → END');
  }

  // ELIMINAZIONE
  Future<void> delete(int id) async {
    debugPrint('[DB-LOGICA] DELETE → ID=$id');

    final db = await AppDatabase.instance;

    await db.transaction((txn) async {
      await txn.delete(
        'prenotazioni_tavoli',
        where: 'prenotazione_id = ?',
        whereArgs: [id],
      );

      await txn.delete(
        'prenotazioni',
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    debugPrint('[DB-LOGICA] DELETE COMPLETATO');
  }

  // SYNC
  Future<void> markAsSynced(int id, {int? remoteId}) async {
    await _dao.markAsSynced(id, remoteId: remoteId);
  }
}

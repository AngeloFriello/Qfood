import 'db_prenotazioni.dart';

/*
DAO prenotazioni
insert / delete
join prenotazioni, tavoli
markAsSynced
 */
class PrenotazioniDao {
  Future<int> insertPrenotazione(Map<String, dynamic> data) async {
    final db = await AppDatabase.instance;
    return await db.insert('prenotazioni', data);
  }

  Future<void> insertPrenotazioneTavoli(
      int prenotazioneId,
      List<int> tavoli,
      ) async {
    final db = await AppDatabase.instance;

    for (final t in tavoli) {
      await db.insert('prenotazioni_tavoli', {
        'prenotazione_id': prenotazioneId,
        'tavolo_id': t,
      });
    }
  }


  Future<void> deletePrenotazioneTavoli(int prenotazioneId) async {
    final db = await AppDatabase.instance;

    await db.delete(
      'prenotazioni_tavoli',
      where: 'prenotazione_id = ?',
      whereArgs: [prenotazioneId],
    );
  }




  Future<void> deletePrenotazione(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('prenotazioni', where: 'id = ?', whereArgs: [id]);
  }


  Future<void> markAsSynced(int id, {int? remoteId}) async {
    final db = await AppDatabase.instance;

    await db.update(
      'prenotazioni',
      {
        'synced': 1,
        'remote_id': remoteId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  //LETTURA DAL DB
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final db = await AppDatabase.instance;

    return await db.rawQuery('''
    SELECT
      p.id,
      p.data,
      p.durata,
      p.scadenza,
      p.pax,
      p.stato,
      p.canale,

      --  SNAPSHOT CLIENTE (DA PRENOTAZIONI)
      p.cliente_id,
      p.cliente_nome,
      p.cliente_telefono,
      p.cliente_email,
      p.note,

      GROUP_CONCAT(pt.tavolo_id) AS tavoli
    FROM prenotazioni p
    LEFT JOIN prenotazioni_tavoli pt
      ON pt.prenotazione_id = p.id
    GROUP BY p.id
    ORDER BY p.data ASC
  ''');
  }



}

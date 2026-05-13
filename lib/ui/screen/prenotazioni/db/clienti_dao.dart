import 'db_prenotazioni.dart';

/*
Persistenza locale (SQLite)
Accesso DB clienti, cerca cliente per telefono/email, inserisce nuovi clienti solo query, zero logica
 */
class ClientiDao {
  Future<Map<String, dynamic>?> findByContatto({
    String? telefono,
    String? email,
  }) async {
    final db = await AppDatabase.instance;

    final res = await db.query(
      'clienti',
      where: 'telefono = ? OR email = ?',
      whereArgs: [telefono, email],
      limit: 1,
    );

    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertCliente({
    required String nome,
    String? telefono,
    String? email,
  }) async {
    final db = await AppDatabase.instance;

    return await db.insert('clienti', {
      'nome': nome,
      'telefono': telefono,
      'email': email,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'migrazioni.dart';

/*
Gestione database SQLite
Apre il DB, versioning, create / upgrade, entry point unico del DB
 */
class AppDatabase {
  static Database? _db;

  static const int _version = 3;

  static Future<Database> get instance async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, 'prenotazioni.db');

    debugPrint('-> DATABASE PATH: $fullPath');

    _db = await openDatabase(
      fullPath,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        debugPrint('-> DB APERTO');
      },
    );

    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    debugPrint('-> CREAZIONE DB v$version');

    await db.execute(Migrations.createClienti);
    await db.execute(Migrations.createPrenotazioni);
    await db.execute(Migrations.createTavoli);
    await db.execute(Migrations.createPrenotazioniTavoli);
    await db.execute(Migrations.createIndexes);

    debugPrint('-> TABELLE CREATE');
  }

  static Future<void> closeAndReset() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      debugPrint('-> DB CHIUSO E RESETTATO');
    }
  }

  static Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    debugPrint('-> UPGRADE DB $oldVersion → $newVersion');

    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE prenotazioni ADD COLUMN cliente_nome TEXT;',
      );
      await db.execute(
        'ALTER TABLE prenotazioni ADD COLUMN cliente_telefono TEXT;',
      );
      await db.execute(
        'ALTER TABLE prenotazioni ADD COLUMN cliente_email TEXT;',
      );
      await db.execute(
        'ALTER TABLE prenotazioni ADD COLUMN note TEXT;',
      );

      debugPrint('-> COLONNE CLIENTE AGGIUNTE A PRENOTAZIONI');
    }
  }

}

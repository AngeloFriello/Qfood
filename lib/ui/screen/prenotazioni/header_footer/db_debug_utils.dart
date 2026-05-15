import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../db/db_prenotazioni.dart';

class DbDebugUtils {
  static const String dbName = 'prenotazioni.db';

  /// RESET COMPLETO DB

  static Future<void> resetDb() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/prenotazioni.db';

    debugPrint('[DB-DEBUG] RESET DB');

    //  chiude connessione viva
    await AppDatabase.closeAndReset();

    // elimina file
    if (await File(path).exists()) {
      await deleteDatabase(path);
      debugPrint('[DB-DEBUG] DB ELIMINATO');
    }
  }




  /// EXPORT DB
  static Future<void> exportDb() async {
    final dbPath = await getDatabasesPath();
    final source = File('$dbPath/$dbName');

    if (!await source.exists()) {
      debugPrint('[DB-DEBUG] DB NON ESISTE');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/$dbName');

    await source.copy(target.path);

    debugPrint('[DB-DEBUG] DB ESPORTATO → ${target.path}');

    await Share.shareXFiles(
      [XFile(target.path)],
      text: 'Export DB prenotazioni',
    );
  }
}

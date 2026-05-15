import 'package:dashboard/modelli/cartModelSaledSuspended.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';

class SuspendedCheckoutDB {

  // GET ALL
  static Future<List<CartModelSaledSuspended>> getAll() async {
    try{
      final db   = await LocalDB.instance();
      final rows = await db.query(
        "cartsSuspended",
        orderBy: "createAt DESC",
      );

      return rows.map((r) {
        //Map<String,dynamic> temp = {...r};
        return CartModelSaledSuspended.fromJson(r);
      }).toList();
     }catch( err ){
      debugPrint(err.toString());
      return [];
    }
  }

  // DELETE
  static Future<void> delete(int id) async {
    final db =  await LocalDB.instance();
    await db.delete(
      "cartsSuspended",
      where: "id = ?",
      whereArgs: [id],
    );
  }
}

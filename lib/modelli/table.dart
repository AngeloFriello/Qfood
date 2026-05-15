import 'dart:convert';

import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/foundation.dart';



class TableModel {
  final int                     id;
  final String                  title;
  final int                     positionX;
  final int                     positionY; 
  final int                     idRoom;
  final int                     cover; 
  final int                     enabled;
  final String?                 status;
  final String?                 dateStartTable;
  final int?                    idOperatorOpenTable;
  final List<ProdottoCarrello>  products;
  final int?                    idCustomer;
  List< dynamic >?              joinedTables; //idTable, title
  final String?                 note;
  final int                     blocked;
  final int                     lastExit;
  final int?                    idListPrice;
  int                     coversInTable;
  Map<String,dynamic>?          idJoinedParent; //idTable, title


  TableModel({
    required this.id,
    required this.title,
    required this.positionX,
    required this.positionY,
    required this.idRoom,
    required this.cover,
    this.idCustomer,
    this.dateStartTable,
    this.idOperatorOpenTable,
    required this.enabled,
    this.status,
    this.joinedTables,
    required this.products,
    this.note,
    required this.blocked,
    required this.lastExit,
    required this.idListPrice,
    required this.coversInTable,
    this.idJoinedParent
  });

  factory TableModel.fromMap(Map<String, dynamic> map) {
    List<ProdottoCarrello> prods = [];
    if( map['products'] is List<dynamic>){
      prods = (map['products'] as List).map((p) => ProdottoCarrello.fromJson(p)).toList();
    }

    if( map['products'] is String ){
      dynamic json = jsonDecode( map['products'] );
      prods  = ( json as List ).map((p) => ProdottoCarrello.fromJson(p)).toList() ;
    }
    debugPrint(prods.toString());
    return TableModel(
                id                  : map['id'] as int,
                title               : map['title'] as String,
                positionX           : map['positionX'] as int,
                positionY           : map['positionY'] as int,
                idRoom              : map['idRoom'] as int,
                cover               : map['cover'] as int,
                enabled             : map['enabled'] as int,
                status              : map['status'] as String?,
                dateStartTable      : map['dateStartTable'] as String?,
                idOperatorOpenTable : map['idOperatorOpenTable'] as int?,
                products            : prods,
                idCustomer          : map['idCustomer'] as int?,
                joinedTables        : (map['joinedTables'] is String) ? jsonDecode(map['joinedTables']) : map['joinedTables'] == null ? null : map['joinedTables'],
                note                : map['note'] as String?,
                blocked             : map['blocked']  ?? 0,
                lastExit            : map['lastExit'] ?? 0,
                idListPrice         : map['idListPrice'] ?? null,
                coversInTable       : map['coversInTable'] ?? 0,
                idJoinedParent      :( map['idJoinedParent'] is String) ?  jsonDecode(map['idJoinedParent']) : map['idJoinedParent'] == null ? null : map['idJoinedParent']         
    );

  }

  Map<String, dynamic> toMap() => {
    'id'                  : id,
    'title'               : title,
    'positionX'           : positionX,
    'positionY'           : positionY,
    'idRoom'              : idRoom,
    'cover'               : cover,
    'enabled'             : enabled,
    'status'              : status,
    'idOperatorOpenTable' : idOperatorOpenTable,
    'products'            : products.map((p) => p.toMap()).toList(),
    'idCustomer'          : idCustomer,
    'joinedTables'        : joinedTables,
    'note'                : note,
    'blocked'             : blocked,
    'lastExit'            : lastExit,
    'idListPrice'         : idListPrice,
    'coversInTable'       : coversInTable,
    'idJoinedParent'      : idJoinedParent,
    'dateStartTable'      : dateStartTable
  };

    Map<String, dynamic> toMapForLocalDb() => {
    'id'                  : id,
    'title'               : title,
    'positionX'           : positionX,
    'positionY'           : positionY,
    'idRoom'              : idRoom,
    'cover'               : cover,
    'enabled'             : enabled,
    'status'              : status,
    'dateStartTable'      : dateStartTable,
    'idOperatorOpenTable' : idOperatorOpenTable,
    'products'            : jsonEncode(products.map((p) => p.toMap() ).toList()) ,
    'idCustomer'          : idCustomer,
    'joinedTables'        : joinedTables,
    'note'                : note,
    'blocked'             : blocked,
    'lastExit'            : lastExit,
    'idListPrice'         : idListPrice,
    'coversInTable'       : coversInTable,
    'idJoinedParent'      : idJoinedParent
  };

  static Future<bool> blockTable(int idTable) async {
    bool blocked = false;
    try{
      final resp       = await LocalDB.query('SELECT * FROM tables WHERE id = $idTable');
      if( resp.isNotEmpty ){
        TableModel table = TableModel.fromMap( resp[0] );
        //SE IL TAVOLO é BLOCCATO RISPONDO CON TRUE E BLOCCO UN ACCESSO IN CONTEMPORANEA ALTRIMENTI BLOCCO E FACCIO ACCEDERE
        if( table.blocked == 1 ) blocked = true;
        if( table.blocked == 0 ){
          int resp = await LocalDB.queryUpdate('UPDATE tables SET blocked = 1 WHERE id = $idTable');
          if( resp == idTable) blocked = false;
        } 
      }else{
        blocked = true;
      } 
    }catch( err ){
      blocked = true;
      debugPrint(err.toString());
    }finally{
      return blocked;
    }
  }

  static Future<void> unLockTable(int idTable) async {
    try{
      final resp       = await LocalDB.query('SELECT * FROM tables WHERE id = $idTable');
      if( resp.isNotEmpty ){
        int resp = await LocalDB.queryUpdate('UPDATE tables SET blocked = 0 WHERE id = $idTable');
      }else{
      } 
    }catch( err ){
      debugPrint(err.toString());
    }finally{

    }
  }

    static Future<bool> unLock(int idTable) async {
      bool success = false;
      try{
        final resp       = await LocalDB.queryUpdate('UPDATE tables SET blocked = 0 WHERE id = $idTable');
        if( resp == idTable) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }

    static Future<bool> openTable(int idTable, int idOperator, int coversInTable) async {
      bool success = false;
      String openDate = DateTime.now().toIso8601String();
      try{ 
        String query = 'UPDATE tables SET dateStartTable = "$openDate", status = "impegnato", idOperatorOpenTable = $idOperator, coversInTable = ${coversInTable}  WHERE id = $idTable';
        final resp       = await LocalDB.queryUpdate(query);
        if( resp == idTable) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }

    static Future<bool> updateTable(int idTable, TableModel table, int idOperator) async {
      bool success = false;
      try{
        String productsEncoded = jsonEncode( table.products.map((p) => p.toMap()).toList() ) ;
        String? status = table.status;
        
        if( table.coversInTable   > 0 ) status = 'impegnato';
        if( table.products.length > 0 ) status = 'occupato';
        

        /* 
            Map<String,dynamic>?          idJoinedParent; 
         */

        final db       = await LocalDB.instance();     
        final resp     = await db.update(
                                    'tables', 
                                    {
                                      'status':              status,
                                      'idCustomer':          table.idCustomer,
                                      'products':            productsEncoded, 
                                      'joinedTables':        table.joinedTables != null ? jsonEncode( table.joinedTables ) : null,
                                      'idListPrice':         table.idListPrice,
                                      'lastExit':            table.lastExit,
                                      'note':                table.note,
                                      'coversInTable':       table.coversInTable,
                                      'positionX':           table.positionX,
                                      'positionY':           table.positionY,
                                      'idJoinedParent':      table.idJoinedParent != null ? jsonEncode( table.idJoinedParent ) : null,
                                    },
                                    where: 'id = ?',
                                    whereArgs: [idTable]
                                  );
      
        if( resp == idTable) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }

    static Future<bool> resetTable(int idTable) async {
      bool success = false;
      try{
        final db = await LocalDB.instance();     
        final resp     = await db.update(
                                    'tables', 
                                    {
                                      'status': null,
                                      'idCustomer': null,
                                      'products': null, 
                                      'joinedTables': null,  //joinedTables da fare
                                      'idListPrice': null,
                                      'lastExit': 0,
                                      'note': null,
                                      'coversInTable': 0,
                                      'idOperatorOpenTable': null,
                                      'dateStartTable': null,
                                      'blocked': 0,
                                      'idJoinedParent' : null
                                    },
                                    where: 'id = ?',
                                    whereArgs: [idTable]
                                  );
      
        if( resp == idTable) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }


    static Future<bool> articlesSetPrinted( TableModel table, List<ProdottoCarrello> productsPrinted ) async {
      bool success = false;
      List<ProdottoCarrello>   productsPrinted_ = [...productsPrinted];
      try{
        List<ProdottoCarrello> notPrinted = table.products.where((p) => !productsPrinted.contains(p)).toList();
        productsPrinted_.forEach((p) => p.printed = 1);

        List<ProdottoCarrello> newList = [...notPrinted, ...productsPrinted_]; 


        final db = await LocalDB.instance();     
        final resp     = await db.update(
                                    'tables', 
                                    {
                                      'products': jsonEncode( newList.map((p) => p.toMap()).toList() ) , 
                                    },
                                    where: 'id = ?',
                                    whereArgs: [table.id]
                                  );
      
        if( resp == table.id) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }


    static Future<bool> resetMultiTablesForJoined(List<int> idTables, Map<String,dynamic>? parent) async {
      bool success = false;
      try{
        final db = await LocalDB.instance();
        String placeholders = idTables.map((_) => '?').join(','); 
        final resp     = await db.update(
                                    'tables', 
                                    {
                                      'status': null,
                                      'idCustomer': null,
                                      'products': null, 
                                      'joinedTables': null,  //joinedTables da fare
                                      'idListPrice': null,
                                      'lastExit': 0,
                                      'note': null,
                                      'coversInTable': 0,
                                      'idOperatorOpenTable': null,
                                      'dateStartTable': null,
                                      'blocked': 0,
                                      'idJoinedParent' :  parent != null ? jsonEncode(parent) : null
                                    },
                                    where: 'id IN ($placeholders)',
                                    whereArgs: idTables
                                  );
      
        if( success = resp > 0 ) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }
    
    static Future<bool> resetMultiTables(List<TableModel> tables, TableModel parent ) async {
      bool success = false;
      try{
        final db = await LocalDB.instance();
        //String placeholders = tables.map((_) => _.id).join(',');
        List<int> idTables  = tables.map((t) => t.id).toList(); 

        for (final table in tables) {
            await db.update(
              'tables',
              {
                'status': null,
                'idCustomer': null,
                'products': null,
                'joinedTables': null,
                'idListPrice': null,
                'lastExit': 0,
                'note': null,
                'coversInTable': 0,
                'idOperatorOpenTable': null,
                'dateStartTable': null,
                'blocked': 0,
                'idJoinedParent': null
              },
              where: 'id = ?',
              whereArgs: [table.id],  // ← 1 parametro solo per volta
            );
          }

        List<dynamic> childrenNew = [];
        parent.joinedTables!.forEach((j) { if(!idTables.contains( j['id'])) childrenNew.add(j); }  );

        final respParent     = await db.update(
                                    'tables', 
                                    {
                                      'joinedTables': childrenNew.isEmpty ? null : jsonEncode(childrenNew),  //joinedTables da fare
                                    },
                                    where: 'id = ?',
                                    whereArgs: [parent.id]
                                  );
      
       // if( success = resp > 0 ) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }


    static Future<bool> setNoteTable( int idTable, String note ) async {
      bool success = false;
      try{
        final db = await LocalDB.instance();     
        final resp     = await db.update(
                                    'tables', 
                                    {
                                      'note': note,
                                    },
                                    where: 'id = ?',
                                    whereArgs: [idTable]
                                  );
      
        if( resp == idTable) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }

    static Future<bool> moveTable( TableModel tablelFrom, TableModel tablelTo, ) async {
      bool success = false;
      try{
        final db        = await LocalDB.instance();
        List<ProdottoCarrello>  allCovers    = [...tablelFrom.products,...tablelTo.products].where((p) => p.article.articleType == ArticleType.cover ).toList();
        List<ProdottoCarrello>  allArticles  = [...tablelFrom.products,...tablelTo.products].where((p) => p.article.articleType != ArticleType.cover ).toList();
        
        ProdottoCarrello? covers;
        if( allCovers.isNotEmpty ){
          covers = allCovers.first;
          double qtaCover = 0;
          allCovers.forEach((c) => qtaCover += c.quantity);
          covers.setQuantity(qtaCover);
          allArticles.add(covers);
        }
        
        String products =  jsonEncode(allArticles.map((p) => p.toMap() ).toList());    
        final resp      = await db.update(
                                    'tables', 
                                    {
                                      'coversInTable'            : tablelFrom.coversInTable + tablelTo.coversInTable,
                                      'dateStartTable'           : tablelFrom.dateStartTable,
                                      'idCustomer'               : tablelFrom.idCustomer,
                                      'idListPrice'              : tablelFrom.idListPrice,
                                      'idOperatorOpenTable'      : tablelFrom.idOperatorOpenTable,
                                      'lastExit'                 : tablelFrom.lastExit,
                                      'status'                   : tablelFrom.status,
                                      'products'                 : products,
                                      'note'                     : tablelFrom.note,
                                    },
                                    where: 'id = ?',
                                    whereArgs: [tablelTo.id]
                                  );
        if( resp == tablelTo.id) success = true;
        await resetTable(tablelFrom.id);
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }


    static Future<bool> joinedTablesWithParent( TableModel parentTable, List<TableModel> tablesChildren, ) async {
      bool success = false;
      try{
        final db        = await LocalDB.instance();
        List<ProdottoCarrello>  productsChildren = [];
        tablesChildren.forEach((child) => child.products.forEach((p) => productsChildren.add(p) ) );
        List<ProdottoCarrello>  allCovers    = [...parentTable.products,...productsChildren].where((p) => p.article.articleType == ArticleType.cover ).toList();
        List<ProdottoCarrello>  allArticles  = [...parentTable.products,...productsChildren].where((p) => p.article.articleType != ArticleType.cover ).toList();
        
        ProdottoCarrello? covers;
        if( allCovers.isNotEmpty ){
          covers = allCovers.first;
          double qtaCover = 0;
          allCovers.forEach((c) => qtaCover += c.quantity);
          covers.setQuantity(qtaCover);
          allArticles.add(covers);
        }
        
        String products =  jsonEncode(allArticles.map((p) => p.toMap() ).toList());    
        final resp      = await db.update(
                                    'tables', 
                                    {
                                      'coversInTable'            : covers == null ? 0 : covers.quantity,
                                      'dateStartTable'           : parentTable.dateStartTable,
                                      'idCustomer'               : parentTable.idCustomer,
                                      'idListPrice'              : parentTable.idListPrice,
                                      'idOperatorOpenTable'      : parentTable.idOperatorOpenTable,
                                      'lastExit'                 : parentTable.lastExit,
                                      'status'                   : parentTable.status,
                                      'products'                 : products,
                                      'note'                     : parentTable.note,
                                      'joinedTables'             : jsonEncode(tablesChildren.map((c) => {'id': c.id, 'title': c.title}).toList())
                                    },
                                    where: 'id = ?',
                                    whereArgs: [parentTable.id]
                                  );
        if( resp == parentTable.id) success = true;
        await resetMultiTablesForJoined(tablesChildren.map((t) => t.id).toList(), {'id': parentTable.id, 'title': parentTable.title});
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }

    static Future<bool> impegnaTable( int idTable, String note, int numberCover ) async {
      bool success = false;
      try{
        final db = await LocalDB.instance();     
        final resp     = await db.update(
                                    'tables', 
                                    {
                                      'note': note,
                                      'status': 'impegnato',
                                      'coversInTable': numberCover
                                    },
                                    where: 'id = ?',
                                    whereArgs: [idTable]
                                  );
      
        if( resp == idTable) success = true;
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success;
      }
    }

    static Future<List> listTableForRoom ( int idRoom ) async {
      List table = [];
      try{
        final resp = await LocalDB.query('SELECT * FROM tables WHERE idRoom = $idRoom');
        table = resp;
      }catch( err ){
        debugPrint(err.toString());
      }finally{
        return table;
      }
    }

    static Future<List> listAllTable () async {
      List table = [];
      try{
        final resp = await LocalDB.query('SELECT * FROM tables');
        table = resp;
      }catch( err ){
        debugPrint(err.toString());
      }finally{
        return table;
      }
    }
}

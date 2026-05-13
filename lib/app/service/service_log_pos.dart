

import 'dart:convert';

import 'package:dashboard/Global.dart';
import 'package:dashboard/config/costanti.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LogOperatorModel {
  final int? id;
  final int sendToBackOffice;
  final String element;
  final String action;
  final String info;
  final String device;
  final String store;
  final String operator;

  LogOperatorModel({
    this.id,
    required this.sendToBackOffice,
    required this.element,
    required this.action,
    required this.info,
    required this.device,
    required this.operator,
    required this.store,
  });

}




class LogService {
  static LogService? _instance;
  static LogService instance () => _instance ??= LogService();


  Future<void> saveLog( String element, String action , String info ) async {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");
      final idStore = prefs.getInt("idStore");
      final device  = prefs.getString("device");
      final store   = prefs.getString("store");
    try{
      

      if( [ istanza, token, idStore, device, store ].contains( null ) ) return;

      final now = DateTime.now();
      final utc = now.toUtc();                       
      final iso = utc.toIso8601String();

      final uri = Uri.parse("https://$istanza-api.qfood.it/api/v1/helper/storeLogTrace730958b90b61");
      final respLog = await http.post( 
        uri,
        headers: {
          "x-api-key": posApiKey,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        }, 
        body: jsonEncode({
                          "content": jsonEncode({
                                                  "element" : element,
                                                  "action"  : action,
                                                  "info"    : info,
                                                  "operator": operatorLogged!.toMap(),
                                                  "device"  : device,
                                                  "store"   : store
                                                }),
                          "channel": "pos_app",
                          "registeredAt": iso,
                          "level": "info"
                        })
      );
      
      int sendToBackOffice = 0;

      if( respLog.statusCode == 201 ){
        final json = jsonDecode(respLog.body);
        if( json['success'] ) sendToBackOffice = 1;
      } 

      //SALVA SOLO SE NON INVIATO E GESTIRE NEL SERVIZIO AUTOMATICO DI INVIO AL SERVER
      if( sendToBackOffice ==  0 ) LocalDB.query("""INSERT INTO logs ( sendToBackOffice, element, action, info, device, store, operator )
                        VALUES ( '$sendToBackOffice', '$element', '$action', '$info', '$device', '$store', '${jsonEncode( operatorLogged!.toMap() )}'  )           
                    """);
    }catch( err ){
      debugPrint( err.toString() );
      LocalDB.query("""INSERT INTO logs ( sendToBackOffice, element, action, info, device, store, operator )
                        VALUES ( 0, '$element', '$action', '$info', '$device', '$store', '${jsonEncode( operatorLogged!.toMap() )}'  )           
                    """);
    }
  }
}
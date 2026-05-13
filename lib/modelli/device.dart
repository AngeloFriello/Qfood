import 'dart:convert';

import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';

class Device {
  final int id;
  final String title;
  final Map<String,dynamic>? server;

  Device({
    required this.id,
    required this.title,
    this.server
  });

  Map<String, dynamic> toMap() {
    return (
      {
        'id'     : id,
        'title'  : title,
        'server' : server != null ? jsonEncode(server) : null
      }
    );
  }

  factory Device.fromMap(Map<String, dynamic> map){
    return Device(
      id:     map['id'] , 
      title:  map['title'],
      server: map['server']
    );
  }

  static Future<List<Device>> devices() async {
    List<Device> list = [];
    try{
      final respDbLocal = await LocalDB.query('SELECT * FROM devices');
      list = respDbLocal.map((d) => Device.fromMap(d)).toList();
    }catch( err ){

    }finally{
      return list;
    }
  }
}
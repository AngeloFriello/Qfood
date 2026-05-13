import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';

class ListPriceModel{
  final int id;
  final String title;
  final String? counterpart;
  final int? enabled;
  final int? trashed;
  final String? lastSync;

  const ListPriceModel({
    required this.id,
    required this.title,
    this.counterpart,
    this.enabled,
    this.trashed,
    this.lastSync
  });

  factory ListPriceModel.fromJson(Map<String, dynamic> json) {
    return ListPriceModel(
      id: json['id'] as int,
      title: json['title'] as String,
      counterpart: json['counterpart'] as String?,
      enabled: json['enabled'] as int?,
      trashed: json['trashed'] as int?,
      lastSync: json['lastSync'] as String?
    );}

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'counterpart': counterpart,
      'enabled'    : enabled,
      'trashed'    : trashed,
      'lastSync'   : lastSync
  };}

  static Future<List<ListPriceModel>> getByDb () async {
      try{
        final  raw = await LocalDB.query('SELECT * FROM listPrice');
        return raw.map<ListPriceModel>((d) => ListPriceModel.fromJson(d)).toList();
      }catch( err ){
        debugPrint(err.toString());
        return [];
      }
    }
} 
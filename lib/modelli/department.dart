import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/rendering.dart';

class DepartmentModel{
  final int id ;
  final String title;
  final int? departmentNumber;
  final String? titleRate;
  final String? nature;
  final String valueRate;
  final int idRate;

  DepartmentModel({
    required this.id,
    required this.title,
    required this.valueRate,
    required this.idRate,
    this.departmentNumber,
    this.nature,
    this.titleRate,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as int,
      title: json['title'] as String,
      valueRate: json['valueRate'] as String,
      idRate: json['idRate'] as int,
      departmentNumber: json['departmentNumber'] as int?,
      nature: json['nature'] as String?,
      titleRate: json['titleRate'] as String?,
    );}

    Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'valueRate':valueRate,
      'idRate':idRate,
      'departmentNumber': departmentNumber,
      'nature'    : nature,
      'titleRate'    : titleRate,
    };}

    static Future<List<DepartmentModel>> getByDb () async {
      try{
        final  raw = await LocalDB.query('SELECT * FROM vatDepartments');
        return raw.map<DepartmentModel>((d) => DepartmentModel.fromJson(d)).toList();
      }catch( err ){
        debugPrint(err.toString());
        return [];
      }
    }
}
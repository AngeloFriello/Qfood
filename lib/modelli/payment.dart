import 'package:dashboard/Global.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentModel {
  final int id;
  final String title;
  final int? cashPayment;
  final String? revenueAgencyType;
  final int? usedForPos;
  final int? tend;
  final int? subtend;
  final int? trashed;
  final int? enabled;
  final String? lastSync;

  PaymentModel({
    required this.id,
    required this.title,
    this.cashPayment,
    this.revenueAgencyType,
    this.usedForPos,
    this.tend,
    this.subtend,
    this.trashed,
    this.enabled,
    this.lastSync,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      "id" : id,
      "title" : title,
      "cashPayment" : cashPayment,
      "revenueAgencyType" : revenueAgencyType,
      "usedForPos" : usedForPos,
      "tend" : tend,
      "subtend" : subtend,
      "trashed" : trashed,
      "enabled" : enabled,
      "lastSync" : lastSync
    };
  }

  factory PaymentModel.fromJson(Map<String, Object?> json) {
    return PaymentModel(
      id: json['id'] as int,
      title: json['title'] as String,
      cashPayment: json['cashPayment'] as int?,
      revenueAgencyType: json['revenueAgencyType'] as String?,
      usedForPos: json['usedForPos'] as int?,
      tend: json['tend'] as int?,
      subtend: json['subtend'] as int?,
      trashed: json['trashed'] as int?,
      enabled: json['enabled'] as int?,
      lastSync: json['lastSync'] as String?,
    );
  }

  static Future<List<PaymentModel>> getPayments() async {
    try{
        final  raw = await LocalDB.query('SELECT * FROM payments');
        return raw.map<PaymentModel>((d) => PaymentModel.fromJson(d)).toList();
      }catch( err ){
        debugPrint(err.toString());
        return [];
      }
    }

    static Future<PaymentModel?> getCashPayment() async {
      try{
          final  raw = await LocalDB.query('SELECT * FROM payments WHERE cashPayment = 1 AND usedForPos = 1');
          List<PaymentModel> result = raw.map<PaymentModel>((d) => PaymentModel.fromJson(d)).toList();
          if( result.isNotEmpty ) return result[0];
          SnackBarForcedClosure('Nessun pagamento contanti presente', Colors.red);
          return null;
        }catch( err ){
          SnackBarForcedClosure('Errore recupero pagamento', Colors.red);
          debugPrint(err.toString());
          return null;
        }
    }
static List<Map<String, dynamic>> CodeTypePayment = [
  {"value": "MP01", "title": "Contanti (MP01)", "icon": LucideIcons.banknote},
  {"value": "MP02", "title": "Assegno (MP02)", "icon": LucideIcons.fileCheck},
  {"value": "MP03", "title": "Assegno circolare (MP03)", "icon": LucideIcons.fileCheck2},
  {"value": "MP04", "title": "Contanti presso Tesoreria (MP04)", "icon": LucideIcons.coins},
  {"value": "MP05", "title": "Bonifico (MP05)", "icon": LucideIcons.receipt},
  {"value": "MP06", "title": "Vaglia cambiario (MP06)", "icon": LucideIcons.banknote},
  {"value": "MP07", "title": "Bollettino bancario (MP07)", "icon": LucideIcons.receipt},
  {"value": "MP08", "title": "Carta di credito (MP08)", "icon": LucideIcons.creditCard},
  {"value": "MP09", "title": "RID (MP09)", "icon": LucideIcons.repeat},
  {"value": "MP10", "title": "RID utenze (MP10)", "icon": LucideIcons.repeat1},
  {"value": "MP11", "title": "RID veloce (MP11)", "icon": LucideIcons.fastForward},
  {"value": "MP12", "title": "Riba (MP12)", "icon": LucideIcons.banknote},
  {"value": "MP13", "title": "MAV (MP13)", "icon": LucideIcons.receipt},
  {"value": "MP14", "title": "Quietanza erario stato (MP14)", "icon": LucideIcons.fileSignature},
  {"value": "MP15", "title": "Giroconto su conti di contabilità speciale (MP15)", "icon": LucideIcons.shuffle},
  {"value": "MP16", "title": "Domiciliazione bancaria (MP16)", "icon": LucideIcons.repeat},
  {"value": "MP17", "title": "Domiciliazione postale (MP17)", "icon": LucideIcons.repeat}
];


}

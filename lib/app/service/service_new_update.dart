import 'dart:convert';

import 'package:dashboard/config/costanti.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;



class ControllerLastUpdate extends ChangeNotifier {
  
  String _lastUpdate = '';
  String get lastUpdate => _lastUpdate;
  bool   _newSync = false;
  bool get newSync => _newSync;

  void setLastUpdate( String newDate ) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    _lastUpdate = pref.getString('lastUpdate') ?? '';

    if( _lastUpdate == newDate ) return;
    _lastUpdate = newDate;
    pref.setString('lastUpdate', newDate);
    _newSync    = true;
    notifyListeners();
  }

  void reset( ){
    _newSync    = false;
    notifyListeners();
  }
}

class ServiceNewUpdate extends ControllerLastUpdate {
  static ServiceNewUpdate? _instance;
  static ServiceNewUpdate instance() => _instance ??= ServiceNewUpdate();

  Future<void> checkNewUpdate() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token =   prefs.getString("token");
      final istanza = prefs.getString("istanza");

      final url = "https://$istanza-api.qfood.it/api/v1/helper/getLastUpdate/2e482d7d5048";
      final resp = await http.get(
            Uri.parse(url),
            headers: {
              "Authorization": "Bearer $token",
              "x-api-key": defaultApiKey,
            },
          );
      if( resp.statusCode == 200 ){
        final json = jsonDecode(resp.body);
        if( json['success'] ?? false ){
          setLastUpdate(json['data']['lastUpdate']);
        }

      }
      
    }catch( err ){

    }finally{
      await Future.delayed(Duration(seconds: 10 ));
      await checkNewUpdate();
    }
  }
}
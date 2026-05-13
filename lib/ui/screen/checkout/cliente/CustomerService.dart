import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/costanti.dart';
import 'CustomerResponse.dart';

class CustomerService {
  static const String baseUrl =
      "https://instance1-api.qfood.it/api/v1/customer";

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("posToken");

    if (token == null || token.isEmpty) {
      throw Exception("❌ POS TOKEN NON PRESENTE");
    }

    return token;
  }



}

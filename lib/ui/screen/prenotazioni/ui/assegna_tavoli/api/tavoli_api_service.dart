import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/tavolo.dart';

class TavoliApiService {
  final String baseUrl;

  TavoliApiService(this.baseUrl);

  Future<List<Tavolo>> loadTavoli() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final companyHex = prefs.getString('idCompanyHex');

    if (token == null || companyHex == null) {
      throw Exception('Token o companyHex mancanti');
    }

    final url = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r"/+$"), "")}'
          '/api/v1/tables/$companyHex',
    );

    debugPrint('[TAVOLI] GET → $url');

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('[TAVOLI] STATUS → ${res.statusCode}');
    debugPrint('[TAVOLI] BODY → ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Errore caricamento tavoli');
    }

    final decoded = jsonDecode(res.body);

    final List list = decoded['data'] ?? [];

    return list.map((e) => Tavolo.fromJson(e)).toList();
  }
}

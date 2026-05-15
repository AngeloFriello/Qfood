import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../model/model_prenotazione.dart';
import 'prenotazione_api_mapper.dart';

/*
Chiamata API prenotazioni
POST /reservation/bookTable/{companyHex}
gestisce errori backend
è quello che parla col server
 */
class PrenotazioniApiService {
  final String baseUrl;

  PrenotazioniApiService(this.baseUrl);

  Future<void> creaPrenotazione(Prenotazione p) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final companyHex = prefs.getString('idCompanyHex');

    if (token == null) {
      throw Exception('Token mancante');
    }
    if (companyHex == null) {
      throw Exception('companyHex mancante');
    }

    final Uri url = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r"/+$"), "")}'
          '/api/v1/reservation/bookTable/$companyHex',
    );

    final body = PrenotazioneApiMapper.toApi(p);


    debugPrint('');
    debugPrint('════════════════════════════════════');
    debugPrint('→ PRENOTAZIONE – REQUEST');
    debugPrint('URL    → $url');
    debugPrint('METHOD → POST');
    debugPrint('BODY   →');
    debugPrint(const JsonEncoder.withIndent('  ').convert(body));
    debugPrint('════════════════════════════════════');

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    debugPrint('');
    debugPrint('════════════════════════════════════');
    debugPrint('→ PRENOTAZIONE – RESPONSE');
    debugPrint('STATUS → ${res.statusCode}');
    debugPrint('BODY   →');
    try {
      debugPrint(
        const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body)),
      );
    } catch (_) {
      debugPrint(res.body);
    }
    debugPrint('════════════════════════════════════');


    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Errore HTTP ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded['success'] != true) {
      throw Exception(
        decoded['verboseError'] ??
            decoded['errors']?.join(', ') ??
            'Errore prenotazione',
      );
    }

    debugPrint('-> PRENOTAZIONE CONFERMATA');
  }
}


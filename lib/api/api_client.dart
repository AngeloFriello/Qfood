import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/costanti.dart';

class ApiClient {
  static String istanza = defaultInstance;

  ///  JWT BACKOFFICE ()
  static String? bearerToken;

  // =========================
  // GET
  // =========================
  static Future<http.Response> get(
      String path, {
        Map<String, String>? query,
      }) {
    final uri = Uri.parse("$apiBaseUrl$path")
        .replace(queryParameters: query);

    return http.get(
      uri,
      headers: _headers(),
    );
  }

  // =========================
  // POST
  // =========================
  static Future<http.Response> post(
      String path, {
        Map<String, dynamic>? body,
      }) {
    final uri = Uri.parse("$apiBaseUrl$path");

    return http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
  }

  // =========================
  // HEADERS
  // =========================
  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",

      //  POS API KEY
      "X-API-KEY": posApiKey,

      //  JWT OBBLIGATORIO
      if (bearerToken != null)
        "Authorization": "Bearer $bearerToken",
    };
  }
}

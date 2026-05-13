import 'dart:async';
import 'dart:convert';
import 'package:dashboard/config/costanti.dart';
import 'package:http/http.dart' as http;

class PosFetch {
  // ignore: non_constant_identifier_names
  static Future<http.Response?> Pos(String url, Map body) async {
    try {
      final uri = Uri.parse("https://$defaultInstance-api.qfood.it" + url);

      return await http
          .post(
        uri,
        headers: {
          "x-api-key": defaultApiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('');
        },
      );
    } catch (err) {
      //debugPrint(err.toString());
      return null;
    }
  }
}

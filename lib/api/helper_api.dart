import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/costanti.dart';

class HelperApi {
  static Future<Map<String, dynamic>?> isValidVatNumber({
    required String vatNumber,
    bool useVies = true,
    bool useCerved = false,
  }) async {
    final Uri url = Uri.parse(
      "$helperBaseUrl/isValidVatNumber/2342671e370d"
          "?vatNumber=$vatNumber"
          "&useVies=${useVies ? 1 : 0}"
          "&useCerved=${useCerved ? 1 : 0}",
    );

    debugPrint("🌍 CHECK P.IVA → $url");

    final res = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": apiKeyForInstance(defaultInstance),
      },
    );

    debugPrint("⬅️ STATUS ${res.statusCode}");
    debugPrint("⬅️ BODY ${res.body}");

    if (res.statusCode != 200) return null;

    final decoded = jsonDecode(res.body);
    if (decoded["success"] != true) return null;

    return decoded["data"];
  }
}

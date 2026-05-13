import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../api/api_client.dart';
import '../../../../config/costanti.dart';
import 'CustomerDetailModel.dart';

class CustomerApi {
  static Future<CustomerDetailModel?> getCustomerById({
    required int idCustomer,
  }) async {
    final url =
        "$customerBaseUrl/getCustomerById/9fec663e8ba0?idFilter=$idCustomer";

    debugPrint("🌍 GET CUSTOMER BY ID → $url");

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer ${ApiClient.bearerToken}",
        "x-api-key": apiKeyForInstance(defaultInstance),
        "Content-Type": "application/json",
      },
    );

    debugPrint("⬅️ STATUS ${res.statusCode}");
    debugPrint("⬅️ BODY ${res.body}");

    if (res.statusCode != 200) return null;

    final decoded = jsonDecode(res.body);
    if (decoded["success"] != true) return null;

    // 🔥 QUESTO È IL PUNTO GIUSTO
    return CustomerDetailModel.fromJson(
      decoded["data"]["record"]["detail"],
    );
  }

}

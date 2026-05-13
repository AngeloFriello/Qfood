import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../ui/screen/checkout/cliente/CustomerDetailModel.dart';
import 'api_client.dart';
import '../config/costanti.dart';

class CustomerApi {

  // =========================
// GET DETTAGLIO CLIENTE
// =========================
  static Future<CustomerDetailModel?> getCustomerById({
    required int idCustomer,
  }) async {
    final url = Uri.parse(
      "$customerBaseUrl/getCustomerById/$customerGuidGet?idFilter=$idCustomer",
    );


    debugPrint("🌍 GET CUSTOMER BY ID → $url");

    final res = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": posApiKey,
        "Authorization": "Bearer ${ApiClient.bearerToken}",
      },
    );

    debugPrint("⬅️ STATUS ${res.statusCode}");
    debugPrint("⬅️ BODY ${res.body}");

    if (res.statusCode != 200) return null;

    final decoded = jsonDecode(res.body);

    if (decoded["success"] != true) return null;

    //  JSON REALE: data → record → detail
    final detailJson = decoded["data"]?["record"]?["detail"];
    if (detailJson == null) return null;

    return CustomerDetailModel.fromJson(detailJson);
  }


  // =========================
  // CREA TESTA CLIENTE
  // =========================
  static Future<int?> createCustomer({
    required String title,
    required String businessType,
    required String token,
    required String istanza,
    int discountPercentage = 0,
  }) async {
    final url = Uri.parse(
      "https://$istanza-api.qfood.it/api/v1/customer/create/$customerGuidCreate",
    );
    final body = {
      "id": 0,
      "title": title,
      "businessType": businessType,
      "discountPercentage": discountPercentage,
    };


    debugPrint("🌍 CUSTOMER CREATE → $url");
    debugPrint("📤 BODY → $body");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": posApiKey,
        "Authorization": "Bearer ${token}",
      },
      body: jsonEncode(body),
    );

    debugPrint("⬅️ STATUS ${res.statusCode}");
    debugPrint("⬅️ BODY ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) return null;

    final decoded = jsonDecode(res.body);
    return decoded["data"]?["id"];
  }


  // =========================
  // CREA DETTAGLI CLIENTE
  // =========================
  static Future<bool> createCustomerDetail({
    required int idCustomer,
    required Map<String, dynamic> detail,
    required String token,
    required String istanza,
  }) async {
    final url = Uri.parse(
      "https://$istanza-api.qfood.it/api/v1/customer/createCustomerDetail/$customerGuidDetail",
    );

    detail["idCustomer"] = idCustomer;

    debugPrint("🌍 CUSTOMER DETAIL → $url");
    debugPrint("📤 DETAIL → $detail");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": posApiKey,
        "Authorization": "Bearer ${token}",
      },
      body: jsonEncode(detail),
    );

    debugPrint("⬅️ STATUS ${res.statusCode}");
    debugPrint("⬅️ BODY ${res.body}");
    if( res.statusCode == 200 || res.statusCode == 201 ){
      dynamic json = jsonDecode(res.body);
      return json['success'];
    }
    
    return false;
  }



  static Future<Map<String, dynamic>?> isValidVatNumber({
    required String vatNumber,
    bool useVies = true,
    bool useCerved = false,
  }) async {
    final url = Uri.parse(
      "$helperBaseUrl/isValidVatNumber/2342671e370d"
          "?vatNumber=$vatNumber"
          "&useVies=${useVies ? 1 : 0}"
          "&useCerved=${useCerved ? 1 : 0}",
    );

    debugPrint("🌍 CHECK PIVA → $url");

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

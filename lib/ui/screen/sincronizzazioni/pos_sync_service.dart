import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/costanti.dart';

class PosSyncService {
  static Future<String> _base(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final istanza = prefs.getString("istanza") ?? "instance1";
    return "https://$istanza-api.qfood.it/api/v1/pos/$endpoint";
  }

  static Future<Map<String, dynamic>> _postArticles(String endpoint) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token   = prefs.getString("token") ?? "";
      final idStore = prefs.getInt("idStore");
      Map<String, dynamic>  results   = {
                                          "articles":[],
                                          "articlesCategories":[],
                                          "articlesAllergens":[],
                                          "articlesBarcodes":[],
                                          "articlesBundles":[],
                                          "articlesFixedMenu":[],
                                          "articlesVariations":[],
                                          "articlesVariationsCategories":[],
                                          "articlesPrices":[],
                                        };
      

      if (idStore == null) {
        throw Exception("⛔ idStore non trovato. Devi selezionare lo store prima della sincronizzazione.");
      }

      int   skip      = 0;
      bool  more = true;
      
      do {
          final url = await _base(endpoint);
          final res = await http.post(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $token",
            "x-api-key": posApiKey,
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "skip": skip,
            "lastSync": null,
            "idStore": idStore,
            "getTipologies" : 1
          }),
        );

        final body = jsonDecode(res.body);
      
        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ BODY: ${res.body}");
          throw Exception("Errore HTTP ${res.statusCode} → $endpoint");
        }
        
        skip++;

        (results['articles'] as List)            .addAll( body['data']['articles'] ) ;
        (results['articlesCategories'] as List)  .addAll( body['data']['articlesCategories'] ) ;
        (results['articlesAllergens'] as List)   .addAll( body['data']['articlesAllergens'] ) ;
        (results['articlesBarcodes'] as List)    .addAll( body['data']['articlesBarcodes'] ) ;
        (results['articlesBundles'] as List)     .addAll( body['data']['articlesBundles'] ) ;
        (results['articlesFixedMenu'] as List)   .addAll( body['data']['articlesFixedMenu'] ) ;
        (results['articlesVariations'] as List)  .addAll( body['data']['articlesVariations'] ) ;
        (results['articlesVariationsCategories'] as List).addAll( body['data']['articlesVariationsCategories'] ) ;
        (results['articlesPrices'] as List)      .addAll( body['data']['articlesPrices'] ) ;
        
        if( (body['data']['articles'] as List).length == 0 ) more = false;

        body["data"] is Map ? body["data"] : {};
        
      } while (more);

      return results;

    }catch( err ){
      debugPrint(err.toString());
      return {};
    }
  }

  static Future<Map<String, dynamic>> _postCategories(String endpoint) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token   = prefs.getString("token") ?? "";
      final idStore = prefs.getInt("idStore");
      Map<String, dynamic>  results   = {
                                          "categories":[],
                                          "categoriesVariations":[],
                                          "categoriesStoreDepartmentProduction":[],
                                        };
      

      if (idStore == null) {
        throw Exception("⛔ idStore non trovato. Devi selezionare lo store prima della sincronizzazione.");
      }

      int   skip      = 0;
      bool  more = true;
      do {
          final url = await _base(endpoint);
          final res = await http.post(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $token",
            "x-api-key": posApiKey,
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "skip": skip,
            "lastSync": null,
            "idStore": idStore,
          }),
        );

        final body = jsonDecode(res.body);
      
        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ BODY: ${res.body}");
          throw Exception("Errore HTTP ${res.statusCode} → $endpoint");
        }
        
        skip++;

        (results['categories'] as List)                           .addAll( body['data']['categories'] ) ;
        (results['categoriesVariations'] as List)                 .addAll( body['data']['categoriesVariations'] ) ;
        (results['categoriesStoreDepartmentProduction'] as List)  .addAll( body['data']['categoriesStoreDepartmentProduction'] ) ;
        
        if( (body['data']['categories'] as List).length == 0 ) more = false;

        body["data"] is Map ? body["data"] : {};
        
      } while (more);

      return results;

    }catch( err ){
      debugPrint(err.toString());
      return {};
    }
  }

  // API ufficiali POS
  static Future<Map<String, dynamic>> syncCategories() =>
      _postCategories("syncCategories/b0dd9f9ec9bd");

  static Future<Map<String, dynamic>> syncArticles() =>
      _postArticles("syncArticle/ae311ca96936");
}

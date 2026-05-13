import 'dart:convert';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:flutter/cupertino.dart';
import '../databasesql_lite/local_db.dart';

class ArticoloService {

  static Future<List<ArticleWhitPriceListModel>> getVariations( ProdottoCarrello article, int? idPriceList ) async {
    List<ArticleWhitPriceListModel> variants = [];
    try{
      final query = """SELECT 
                      a.*,
                      ap.*,
                      IFNULL(subQ.joinType, 'default') joinTypeVariation
                    FROM (
                      SELECT 
                        v.id,
                        v.code,
                        v.title,
                        artv.joinType
                      FROM articlesVariations AS artv
                      INNER JOIN articles v on v.id = artv.idVariation
                      WHERE artv.idArticle = ${article.article.id}
                      UNION 
                      SELECT 
                        a.id,
                        a.code,
                        a.title,
                        av.joinType
                      FROM articlesVariationsCategories avs 
                      INNER JOIN categoriesVariations cv ON cv.idCategory = avs.idCategory
                      INNER JOIN articles a ON a.id = cv.idVariation
                      LEFT JOIN articlesVariations av ON av.idArticle = ${article.article.id} AND av.idVariation = cv.idVariation
                      WHERE avs.idArticle = ${article.article.id}
                    ) AS subQ 
                    INNER JOIN articlesPrices ap ON ap.idArticle = subQ.id AND ap.idPriceList = ${idPriceList}
                    INNER JOIN articles a ON a.id = subQ.id
                    WHERE joinTypeVariation <> 'excluded'
                    ORDER BY a.title ASC
                  """;
      
      final respDb = await LocalDB.query(query).catchError((err) => err.toString());

      variants = respDb.map((artDb) => ArticleWhitPriceListModel.fromJson(artDb)).toList();

      //FIX DUPLICATI
      List<ArticleWhitPriceListModel> temp = [];
      variants.forEach((v) {
        final esiste = temp.indexWhere((vv) => vv.id == v.id && vv.variationType == v.variationType );
        if( esiste == -1 ) temp.add(v);
      });

      variants = temp;     

    }catch(err){
      debugPrint(err.toString());
    }finally{
      return variants;
    }
  }

  //DA RIMUOVERE
  static Future<Map<String, dynamic>?> getArticoloCompleto(int idArticle) async {
    final db = await LocalDB.instance();

    // 1. Articolo base (GIÀ COMPLETO)
    final articolo = await db.query(
      "articles",
      where: "id = ?",
      whereArgs: [idArticle],
    );
    if (articolo.isEmpty) return null;

    // ✅ VARIANTI (JSON STRING → LIST)
    final rawVariants = (articolo.first["variants"] as String?) ?? "[]";
    final List<dynamic> parsedVariants = jsonDecode(rawVariants);

    debugPrint("🧪 VARIANTI DAL DB → ${parsedVariants.length}");

    return {
      "id": articolo.first["id"],
      "title": articolo.first["title"],
      "price": articolo.first["price"],          // ✅ GIÀ QUI
      "idVatRate": articolo.first["idVatRate"],  // ✅ GIÀ QUI
      "vatValue": articolo.first["vatValue"],    // ✅ GIÀ QUI
      "variants": parsedVariants,
    };
  }
}

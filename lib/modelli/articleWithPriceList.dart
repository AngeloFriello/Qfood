import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';

enum ArticleType {
  rawMaterial,
  semiFinished,
  product,
  variation,
  cover,
  gambling,
  tobaccos,
  monopoly,
  bundle,
  fixedMenu,
  taxFree,
  poke,
  generic,
  scratchAndWin,
  revenueStamps,
  free_variation,
  ticket;

  String get value => name;

  static ArticleType fromValue(String value) {
    return ArticleType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ArticleType.generic,
    );
  }
}

class ArticleWhitPriceListModel {
  final int id;
  final ArticleType articleType;
  final String code;
  String title;
  final String? posTitle;
  final String? shortDescription;
  final String? longDescription;
  final int? preferred;
  final int? position;
  final int? availableForScale;
  final String? scalePlus;
  final String? scaleType;
  final String? variationType;
  final String? variationPricePercentagePlus;
  final String? variationPricePercentageMinus;
  final int? trashed;
  final int? enabled;
  final int? availableForPos;
  final String? lastSync;
  final String? price;
  final String? discountPercentage;
  final String? rateValue;
  final int?    idVatRate;
  final String? validFromDate;
  final String? validToDate;
  final String? validHourDayStart;
  final String? validHourDayEnd;
  final String? weekDay;
  final String? validityPriceForQuantity;
  final String? maximumSellableQuantity;
  final String? joinTypeVariation;
  final int? generic;
  String? colorFirstCategory;

  ArticleWhitPriceListModel({
    required this.id,
    required this.articleType,
    required this.code,
    required this.title,
    this.posTitle,
    this.shortDescription,
    this.longDescription,
    this.preferred,
    this.position,
    this.availableForScale,
    this.scalePlus,
    this.scaleType,
    this.variationType,
    this.variationPricePercentagePlus,
    this.variationPricePercentageMinus,
    this.trashed,
    this.enabled,
    this.availableForPos,
    this.lastSync,
    this.price,
    this.discountPercentage,
    this.rateValue,
    this.idVatRate,
    this.validFromDate,
    this.validToDate,
    this.validHourDayStart,
    this.validHourDayEnd,
    this.weekDay,
    this.validityPriceForQuantity,
    this.maximumSellableQuantity,
    this.joinTypeVariation,
    this.generic
  });


  void setTitle ( String newTitle ){
    title = newTitle;
  }

  Map<String, dynamic> toJson() {
  return {
    'id': id,
    'articleType': articleType.value,  // Enum → stringa
    'code': code,
    'title': title,
    'posTitle': posTitle,
    'shortDescription': shortDescription,
    'longDescription': longDescription,
    'preferred': preferred,
    'position': position,
    'availableForScale': availableForScale,
    'scalePlus': scalePlus,
    'scaleType': scaleType,
    'variationType': variationType,
    'variationPricePercentagePlus': variationPricePercentagePlus,
    'variationPricePercentageMinus': variationPricePercentageMinus,
    'trashed': trashed,
    'enabled': enabled,
    'availableForPos': availableForPos,
    'lastSync': lastSync,
    'price': price,
    'discountPercentage': discountPercentage,
    'rateValue': rateValue,
    'idVatRate': idVatRate,
    'validFromDate': validFromDate,
    'validToDate': validToDate,
    'validHourDayStart': validHourDayStart,
    'validHourDayEnd': validHourDayEnd,
    'weekDay': weekDay,
    'validityPriceForQuantity': validityPriceForQuantity,
    'maximumSellableQuantity': maximumSellableQuantity,
    'joinTypeVariation': joinTypeVariation,
    'generic': generic,
  };
}


  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'articleType': articleType.value,
      'code': code,
      'title': title,
      'posTitle': posTitle ?? '',
      'shortDescription': shortDescription ?? '',
      'longDescription': longDescription ?? '',
      'preferred': preferred ?? 0,
      'position': position ?? 0,
      'availableForScale': availableForScale ?? 0,
      'scalePlus': scalePlus ?? "0.0",
      'scaleType': scaleType ?? '',
      'variationType': variationType ?? '',
      'variationPricePercentagePlus': variationPricePercentagePlus ?? "0.0",
      'variationPricePercentageMinus': variationPricePercentageMinus ?? "0.0",
      'trashed': trashed ?? 0,
      'enabled': enabled ?? 1,
      'availableForPos': availableForPos ?? 0,
      'lastSync': lastSync ?? '',
      'price': price,
      'discountPercentage': discountPercentage,
      'rateValue': rateValue,
      'idVatRate': idVatRate,
      'validFromDate': validFromDate ?? '',
      'validToDate': validToDate ?? '',
      'validHourDayStart': validHourDayStart ?? '',
      'validHourDayEnd': validHourDayEnd ?? '',
      'weekDay': weekDay ?? '',
      'validityPriceForQuantity': validityPriceForQuantity,
      'maximumSellableQuantity': maximumSellableQuantity,
      'joinTypeVariation' : joinTypeVariation,
      'generic': generic,
    };
  }

  factory ArticleWhitPriceListModel.fromJson(Map<String, Object?> json) {
    return ArticleWhitPriceListModel(
      id: json['id'] as int,
      articleType: ArticleType.fromValue(json['articleType'] as String),
      code: json['code'] as String,
      title: json['title'] as String,
      posTitle: json['posTitle'] as String?,
      shortDescription: json['shortDescription'] as String?,
      longDescription: json['longDescription'] as String?,
      preferred: json['preferred'] as int?,
      position: json['position'] as int?,
      availableForScale: json['availableForScale'] as int?,
      scalePlus: json['scalePlus'] as String?,
      scaleType: json['scaleType'] as String?,
      variationType: json['variationType'] as String?,
      variationPricePercentagePlus: json['variationPricePercentagePlus'] as String?,
      variationPricePercentageMinus: json['variationPricePercentageMinus'] as String?,
      trashed: json['trashed'] as int?,
      enabled: json['enabled'] as int?,
      availableForPos: json['availableForPos'] as int?,
      lastSync: json['lastSync'] as String?,
      price: json['price'] as String?,
      discountPercentage: json['discountPercentage'] as String?,
      rateValue: json['rateValue'] as String?,
      idVatRate: json['idVatRate'] as int?,
      validFromDate: json['validFromDate'] as String?,
      validToDate: json['validToDate'] as String?,
      validHourDayStart: json['validHourDayStart'] as String?,
      validHourDayEnd: json['validHourDayEnd'] as String?,
      weekDay: json['weekDay'] as String?,
      validityPriceForQuantity: json['validityPriceForQuantity'] as String?,
      maximumSellableQuantity: json['maximumSellableQuantity'] as String?,
      joinTypeVariation: json['joinTypeVariation'] as String?,
      generic: json['generic'] as int?,
    );
  }


    static Future<List<ArticleWhitPriceListModel>> getCovers (int idPriceList) async {
      List<ArticleWhitPriceListModel> covers = [];
      try{
        //QUERY PER ARTICOLO CON ABBINAMENTO LISTINO E CATEGORIA
        String queryArticleListPriceCategory = """SELECT 
                        art.*,
                        lp.*
                      FROM articles art
                      INNER JOIN articlesPrices lp  ON art.id = lp.idArticle AND lp.idPriceList = ${idPriceList}
                      ORDER BY art.title""";

        final respDbArticles   = await LocalDB.query(queryArticleListPriceCategory);

        covers  = respDbArticles.map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb)).toList().where((a) => a.articleType == ArticleType.cover).toList();

      }catch( err ){
        debugPrint( err.toString() );
      }finally{
        return covers;
      }
  }

  ArticleWhitPriceListModel copyWith({
  int?         id,
  ArticleType? articleType,
  String?      code,
  String?      title,
  String?      posTitle,
  String?      shortDescription,
  String?      longDescription,
  int?         preferred,
  int?         position,
  int?         availableForScale,
  String?      scalePlus,
  String?      scaleType,
  String?      variationType,
  String?      variationPricePercentagePlus,
  String?      variationPricePercentageMinus,
  int?         trashed,
  int?         enabled,
  int?         availableForPos,
  String?      lastSync,
  String?      price,
  String?      discountPercentage,
  String?      rateValue,
  int?         idVatRate,
  String?      validFromDate,
  String?      validToDate,
  String?      validHourDayStart,
  String?      validHourDayEnd,
  String?      weekDay,
  String?      validityPriceForQuantity,
  String?      maximumSellableQuantity,
  String?      joinTypeVariation,
  int?         generic,
  String?      colorFirstCategory,
}) {
  return ArticleWhitPriceListModel(
    id:                            id                           ?? this.id,
    articleType:                   articleType                  ?? this.articleType,
    code:                          code                         ?? this.code,
    title:                         title                        ?? this.title,
    posTitle:                      posTitle                     ?? this.posTitle,
    shortDescription:              shortDescription             ?? this.shortDescription,
    longDescription:               longDescription              ?? this.longDescription,
    preferred:                     preferred                    ?? this.preferred,
    position:                      position                     ?? this.position,
    availableForScale:             availableForScale            ?? this.availableForScale,
    scalePlus:                     scalePlus                    ?? this.scalePlus,
    scaleType:                     scaleType                    ?? this.scaleType,
    variationType:                 variationType                ?? this.variationType,
    variationPricePercentagePlus:  variationPricePercentagePlus ?? this.variationPricePercentagePlus,
    variationPricePercentageMinus: variationPricePercentageMinus?? this.variationPricePercentageMinus,
    trashed:                       trashed                      ?? this.trashed,
    enabled:                       enabled                      ?? this.enabled,
    availableForPos:               availableForPos              ?? this.availableForPos,
    lastSync:                      lastSync                     ?? this.lastSync,
    price:                         price                        ?? this.price,
    discountPercentage:            discountPercentage           ?? this.discountPercentage,
    rateValue:                     rateValue                    ?? this.rateValue,
    idVatRate:                     idVatRate                    ?? this.idVatRate,
    validFromDate:                 validFromDate                ?? this.validFromDate,
    validToDate:                   validToDate                  ?? this.validToDate,
    validHourDayStart:             validHourDayStart            ?? this.validHourDayStart,
    validHourDayEnd:               validHourDayEnd              ?? this.validHourDayEnd,
    weekDay:                       weekDay                      ?? this.weekDay,
    validityPriceForQuantity:      validityPriceForQuantity     ?? this.validityPriceForQuantity,
    maximumSellableQuantity:       maximumSellableQuantity      ?? this.maximumSellableQuantity,
    joinTypeVariation:             joinTypeVariation            ?? this.joinTypeVariation,
    generic:                       generic                      ?? this.generic,
  )..colorFirstCategory =          colorFirstCategory           ?? this.colorFirstCategory;
}
}

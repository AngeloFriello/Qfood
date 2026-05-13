import 'dart:convert';

import 'package:dashboard/modelli/articleWithPriceList.dart';

class ArticleModel {
  final int id;
  final ArticleType articleType;
  final String code;
  final String title;
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
  final int? generic;
  final List<String> tipologies;

  ArticleModel({
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
    this.generic,
    required this.tipologies
  });

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
      'generic' : generic ?? 0,
      'tipologies' : jsonEncode( tipologies ) 
    };
  }

  factory ArticleModel.fromJson(Map<String, Object?> json) {
    return ArticleModel(
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
      generic: json['generic'] as int?,
      tipologies: ( json['tipologies'] is List )  ? (json['tipologies'] as List<dynamic> ).cast<String>() : [],
    );
  }



}

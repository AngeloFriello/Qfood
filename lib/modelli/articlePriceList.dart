class ArticlePricesListModel {
  final int idArticle;
  final int idPriceList;
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
  final int?    preferred;

  ArticlePricesListModel({
    required this.idArticle,
    required this.idPriceList,
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
    this.preferred,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'idArticle': idArticle,
      'idPriceList': idPriceList,
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
      'preferred': preferred,
    };
  }

  factory ArticlePricesListModel.fromJson(Map<String, Object?> json) {
    return ArticlePricesListModel(
      idArticle: json['idArticle'] as int,
      idPriceList: json['idPriceList'] as int,
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
      preferred: json['preferred'] as int?,
    );
  }
}

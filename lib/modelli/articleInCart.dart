import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/printer.dart';
import 'package:uuid/uuid.dart';



class ProdottoCarrello{
  String uuid; //univoco per riga del carrello
  String? rowGuidReference;
  final bool   isVariant;
  final String? variationType; //'minus' 'plus' 'plus_minus' 'info'
  final ArticleWhitPriceListModel article;
  double quantity;
  int? exit;
  double unitPrice;
  final double percentageDiscount;
  final double valueDiscount;
  final List<ProdottoCarrello> variationsMinus;
  final List<ProdottoCarrello> variationsPlus;
  final List<ProdottoCarrello> variationsInfo;
  final List<ProdottoCarrello> variationsFree;
  final String                 nameOperator; 
  final int                    idOperator;
  int                          printed;
  String? deletionNote;
  PrinterForArticle?           printsDestination;
  double discountPercentageRow;

  
  ProdottoCarrello({
    required this.uuid,
    required this.isVariant,
    required this.exit,
    this.rowGuidReference,
    this.variationType,
    required this.article,
    required this.quantity,
    required this.unitPrice,
    required this.percentageDiscount,
    required this.valueDiscount,
    required this.variationsMinus,
    required this.variationsPlus,
    required this.variationsInfo,
    required this.variationsFree,
    required this.nameOperator,
    required this.idOperator,
    required this.printed,
    this.deletionNote,
    required this.discountPercentageRow
  });
  
  Map<String, dynamic> toJsonEncodable() {
    return {
      'uuid': uuid,
      'exit' : exit,
      'rowGuidReference': rowGuidReference,
      'isVariant': isVariant,
      'variationType': variationType,
      'article': article.toJson(),  // Article → JSON ready
      'quantity': quantity,
      'unitPrice': unitPrice,
      'percentageDiscount': percentageDiscount,
      'valueDiscount':   valueDiscount,
      'variationsMinus': variationsMinus.map((e) => e.toJsonEncodable()).toList(),
      'variationsPlus':  variationsPlus.map((e) => e.toJsonEncodable()).toList(),
      'variationsInfo':  variationsInfo.map((e) => e.toJsonEncodable()).toList(),
      'variationsFree':  variationsFree.map((e) => e.toJsonEncodable()).toList(),
      'printed'       : printed,
      'deletionNote'  : deletionNote,
      'discountPercentageRow' : discountPercentageRow
    };
  }

  void setUuid(String uuid_){
    uuid = uuid_;
  }

  void setExit(int e){
    exit = e;
  }

  void setDiscountPercentageRow (double d ){
    discountPercentageRow = d;
  }

  void setGuidReference(String guid){
    rowGuidReference = guid;
  }

 static List<ProdottoCarrello> parseNullListProdottoCarrello(dynamic list){
    List<ProdottoCarrello> c = [];
    if( list is List<ProdottoCarrello> ){
      return list;
    }
    if( list is List ){
      return list.map((p) => ProdottoCarrello.fromJson((p as Map<String,dynamic>))).toList();
    }
    if( list is! List<ProdottoCarrello> ){
      return c;
    }
    return c;
  }

  void incrementQuantity() {
    quantity ++;
  }

  void setQuantity( double qta ) {
    quantity = qta;
  }

  void setUnitPrice( double p ) {
    unitPrice = p;
  }

  void setRowPrice( double p ) {
    unitPrice = p / quantity;
  }

  void refreshGuid () {
    uuid = Uuid().v4();
    [...variationsFree, ...variationsInfo, ...variationsMinus, ...variationsPlus ].forEach((v) {
      v.setUuid( Uuid().v4() );
      v.setGuidReference(uuid);
    });
  }

  factory ProdottoCarrello.fromJson(Map<String, dynamic> json) {
    return ProdottoCarrello(
      exit: json['exit'] as int?,
      uuid: json['uuid'] as String,
      rowGuidReference: json['rowGuidReference'] as String?,
      isVariant: json['isVariant'] as bool,
      variationType: json['variationType'] as String?,
      article: (json['article'] is ArticleWhitPriceListModel) ? json['article'] : ArticleWhitPriceListModel.fromJson(json['article']),
      quantity: json['quantity'] as double,
      unitPrice: json['unitPrice'] as double,
      percentageDiscount: json['percentageDiscount'] as double,
      valueDiscount:   json['valueDiscount'] as double,
      variationsMinus: parseNullListProdottoCarrello(json['variationsMinus']),
      variationsPlus:  parseNullListProdottoCarrello(json['variationsPlus'] ),
      variationsInfo:  parseNullListProdottoCarrello(json['variationsInfo']),
      variationsFree:  parseNullListProdottoCarrello(json['variationsFree']),
      nameOperator:    json['nameOperator'] ?? 'manca operatore',
      idOperator:      json['idOperator']   ?? 0,
      printed:         json['printed']      ?? 0,
      deletionNote :   json['deletionNote'],
      discountPercentageRow : json['discountPercentageRow'] ?? 0
    );
  }

    Map<String, Object?> toMap() {
    return <String, Object?>{
      'exit' : exit,
      'uuid': uuid,
      'rowGuidReference': rowGuidReference,
      'isVariant': isVariant,
      'variationType' : variationType,
      'article': article,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'percentageDiscount' : percentageDiscount,
      'valueDiscount' : valueDiscount,
      'variationsMinus': variationsMinus,
      'variationsPlus' : variationsPlus,
      'variationsInfo' : variationsInfo,
      'variationsFree' : variationsFree,
      'nameOperator': nameOperator,
      'idOperator'  : idOperator,
      'printed'     : printed,
      'deletionNote': deletionNote,
      'discountPercentageRow' : discountPercentageRow
    };}




  Map<String, dynamic> toJson() =>{
      'exit': exit,
      'uuid': uuid,
      'rowGuidReference': rowGuidReference,
      'isVariant': isVariant,
      'variationType' : variationType,
      'article': article,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'percentageDiscount' : percentageDiscount,
      'valueDiscount' : valueDiscount,
      'variationsMinus': variationsMinus,
      'variationsPlus' : variationsPlus,
      'variationsInfo' : variationsInfo,
      'variationsFree' : variationsFree,
      'nameOperator'   : nameOperator,
      'idOperator'     : idOperator,
      'printed'        : printed,
      'deletionNote'   : deletionNote,
      'discountPercentageRow' : discountPercentageRow
  };

  double get  priceUnitOrigin => double.parse(article.price ?? '0');
  double get  vatValue  => double.parse(article.rateValue ?? '0');

  double get priceRowCart => unitPrice * quantity;

  // valore netto (senza iva)
  double get priceNet    => unitPrice / (1 + vatValue / 100);

   // valore netto riga (senza iva)
  double get priceNetRow => (priceNet / (1 + vatValue / 100)) * quantity;

   // tasse
  double get taxRow => priceRowCart - priceNetRow;

  // iva unitaria
  double get vatUnit  => priceUnitOrigin - priceNet;

  double get priceRowWithVariant  {
    final allVariants = [...variationsFree,...variationsMinus,...variationsInfo, ...variationsPlus];
    double priceAllVariants = allVariants.fold(0.0, (sum, item) => sum + item.priceRowCart);
    return  priceRowCart + priceAllVariants;
  }


  double get priceNetRowWithVariant  {
    final allVariants = [...variationsFree,...variationsMinus,...variationsInfo, ...variationsPlus];
    double priceAllVariants = allVariants.fold(0.0, (sum, item) => sum + item.priceRowCart);
    return  ( priceRowCart + priceAllVariants ) / ( 1 + vatValue / 100 );
  }
}
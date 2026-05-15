import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum VariantsType {
  plusMinus,
  plus,
  minus,
  info,
  free
}


class VariantsController extends ChangeNotifier{
  List<ArticleWhitPriceListModel> allVariants            = [];
  ProdottoCarrello? currentArticle;
  VariantsType typeSelected                              = VariantsType.plusMinus;
  String?      titleFilter;
  double       quantity                                      = 1;
  double       quantityArticlesInCart                        = 1;
  List  <ArticleWhitPriceListModel>    variants_selected_free = [];
  List  <ArticleWhitPriceListModel>    variant_selected_plus  = [];
  List  <ArticleWhitPriceListModel>    variant_selected_minus = [];
  List  <ArticleWhitPriceListModel>    variant_selected_info  = [];
  TextEditingController controllerSearch = TextEditingController();

  void reset(){
    quantity = 1;
    quantityArticlesInCart  = 1;
    variant_selected_info   = [];
    variant_selected_minus  = [];
    variant_selected_plus   = [];
    variants_selected_free  = [];
    currentArticle          = null;
    allVariants             = [];
    titleFilter             = '';
  }

  List<ProdottoCarrello> convertVariantForCart ( List<ArticleWhitPriceListModel> variants, String type ){
    return variants.map((var_) => ProdottoCarrello(
                                                  exit: 0,
                                                  uuid: Uuid().v4(), 
                                                  isVariant: true, 
                                                  article: var_, 
                                                  quantity: quantity, 
                                                  unitPrice: double.parse(var_.price ?? '0') , 
                                                  percentageDiscount: 0, 
                                                  valueDiscount: 0, 
                                                  variationsMinus: [], 
                                                  variationsPlus:  [],
                                                  variationsInfo:  [],
                                                  variationsFree:  [],
                                                  variationType: type,
                                                  idOperator: operatorLogged!.id,
                                                  nameOperator: (operatorLogged!.firstname ?? '' ) +' '+(operatorLogged!.lastname ?? '' ),
                                                  printed: 0,
                                                  discountPercentageRow : 0
                                                )).toList();
  }

  void addInSelectedInfo(  ArticleWhitPriceListModel variant ){
    bool check = variant_selected_info.any((v) => v.id == variant.id);
    if( check ){
      variant_selected_info.removeWhere((v) => v.id == variant.id);
    }else{
      variant_selected_info.add(variant);
    }
    notifyListeners();
  }

  void addInSelectedFree( String title, String price ) async {

    final articleGeneric_ = await getGenericProduct();
    if( articleGeneric_ == null ) return;
    variants_selected_free.add(ArticleWhitPriceListModel(
                                                          id: articleGeneric_['id'], 
                                                          articleType: ArticleType.fromValue("free_variation"), 
                                                          code: articleGeneric_['code'], 
                                                          rateValue: currentArticle?.article.rateValue,
                                                          idVatRate: currentArticle?.article.idVatRate,
                                                          title: title,
                                                          price:( double.parse(price) ).toStringAsFixed(2)
                                                        ));
    notifyListeners();
  }

  void removeInSelectedFree( ArticleWhitPriceListModel variant ){
    variants_selected_free.remove(variant);
    notifyListeners();
  }

  void addInSelectedMinus( ArticleWhitPriceListModel variant ){
    bool check = variant_selected_minus.any((v) => v.id == variant.id);
    if( check ){
      variant_selected_minus.removeWhere((v) => v.id == variant.id);
    }else{
      variant_selected_minus.add(variant);
    }
    variant_selected_plus.removeWhere((v) => v.id == variant.id);
    notifyListeners();
  }

  void addInSelectedPlus(  ArticleWhitPriceListModel variant ){
    bool check = variant_selected_plus.any((v) => v.id == variant.id);
    if( check ){
      variant_selected_plus.removeWhere((v) => v.id == variant.id);
    }else{
      variant_selected_plus.add(variant);
    }
    variant_selected_minus.removeWhere((v) => v.id == variant.id);
    notifyListeners();
  }

  void setTab (VariantsType type){
    typeSelected = type;
    titleFilter  = '';
    notifyListeners();
  }

  void setQuantity (double qta){
    quantity = qta;
    notifyListeners();
  }

  void setQuantityArticleInRow (double qta){
    quantityArticlesInCart = qta;
    notifyListeners();
  }

  void setQuantityPlus (){
    if( ( quantity + 1 ) > quantityArticlesInCart ) return;
    quantity++;
    notifyListeners();
  }

  void setQuantityMinus (){
    if( quantity == 1 ) return;
    quantity--;
    notifyListeners();
  }

  void setTitleFilter (String text ){
    titleFilter = text;
    notifyListeners();
  }

  void setArticleCurrent (ProdottoCarrello art){
    currentArticle = art;
    variant_selected_info   = art.variationsInfo.map((e) => e.article,).toList();
    variants_selected_free  = art.variationsFree.map((e) => e.article,).toList();
    variant_selected_plus   = art.variationsPlus.map((e) => e.article,).toList();
    variant_selected_minus  = art.variationsMinus.map((e) => e.article,).toList();
    notifyListeners();
  }

  void setAllVariants (List<ArticleWhitPriceListModel> variants) {
    allVariants = variants;
    notifyListeners();
  }

  List<ArticleWhitPriceListModel> get variantsMinus {
    return allVariants.where((variants) => variants.variationType == 'minus' && ( variants.title + (variants.posTitle ?? '') ).toLowerCase().contains(titleFilter ?? '')).toList();
  }

  List<ArticleWhitPriceListModel> get variantsPlus {
    return allVariants.where((variants) => variants.variationType == 'plus' && ( variants.title + (variants.posTitle ?? '') ).toLowerCase().contains(titleFilter ?? '')).toList();
  }

  List<ArticleWhitPriceListModel> get variantsPlusMinus {
    return allVariants.where((variants) => variants.variationType == 'plus_minus' && ( variants.title + (variants.posTitle ?? '') ).toLowerCase().contains(titleFilter ?? '')).toList();
  }

  List<ArticleWhitPriceListModel> get variantsInfo {
    return allVariants.where((variants) => variants.variationType == 'info' && ( variants.title + (variants.posTitle ?? '') ).toLowerCase().contains(titleFilter ?? '')).toList();
  }

}
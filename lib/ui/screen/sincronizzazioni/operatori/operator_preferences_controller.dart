import 'package:flutter/material.dart';

import '../../../../modelli/listPrice.dart';

class OperatorPreferencesController extends ChangeNotifier {
  /// =========================
  /// BOOLEAN
  /// =========================
  bool smallProductName = false;
  bool discountBenchTable = false;
  bool extendedCart = false;
  bool rapidButtonCash = false;
  bool displayAmountLastSale = false;
  bool rapidPriceListChangeButton = false;
  bool displayProductReduced = false;
  bool useDarkMode = false;
  bool printDefaultCommandFromBench = false;
  bool displayBigCategory = false;
  bool tableOpeningInCommand = false;
  bool sendOrderNoExitTable = false;
  bool valueWithoutSeparator = false;
  bool paginatedArticle = false;
  bool displayTableReduced = false;
  bool displayUserTable = false;
  ListPriceModel? selectedListino;
  int rapidPriceListId = 0;

  /// =========================
  /// ENUM / STRING
  /// =========================
  String productNameSize = 'M';        // S | M | L
  String productSmallNameSize = 'M';   // S | M | L
  String uiSide = 'R';                 // R | L

  /// =========================
  /// NUMBER
  /// =========================
  int rapidDiscountButtonPercentage = 0;

  /// =========================
  /// HELPERS SICURI
  /// =========================
  bool _b(dynamic v) => v == 1 || v == true;
  int _i(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v.split('.').first) ?? 0;
    return 0;
  }

  String _size(dynamic v) {
    if (v == 'small') return 'S';
    if (v == 'medium') return 'M';
    if (v == 'large') return 'L';
    if (v == 'S' || v == 'M' || v == 'L') return v;
    return 'M';
  }

  String _side(dynamic v) => v == 'ltr' || v == 'L' ? 'L' : 'R';

  /// =========================
  /// PARSE DA API (FIX TOTALE)
  /// =========================
  void loadFromApi(Map<String, dynamic> json) {
    smallProductName              = _b(json['smallProductName']);
    discountBenchTable            = _b(json['discountBenchTable']);
    extendedCart                  = _b(json['extendedCart']);
    rapidButtonCash               = _b(json['rapidButtonCash']);
    displayAmountLastSale         = _b(json['displayAmountLastSale']);
    rapidPriceListChangeButton    = _b(json['rapidPriceListChangeButton']);
    displayProductReduced         = _b(json['displayProductReduced']);
    useDarkMode                   = _b(json['useDarkMode']);
    printDefaultCommandFromBench  = _b(json['printDefaultCommandFromBench']);
    displayBigCategory            = _b(json['displayBigCategory']);
    tableOpeningInCommand         = _b(json['tableOpeningInCommand']);
    sendOrderNoExitTable          = _b(json['sendOrderNoExitTable']);
    valueWithoutSeparator         = _b(json['valueWithoutSeparator']);
    paginatedArticle              = _b(json['paginatedArticle']);
    displayTableReduced           = _b(json['displayTableReduced']);
    displayUserTable              = _b(json['displayUserTable']);

    productNameSize               = _size(json['productNameSize']);
    productSmallNameSize          = _size(json['productSmallNameSize']);
    uiSide                        = _side(json['uiSide']);

    rapidDiscountButtonPercentage =
        _i(json['rapidDiscountButtonPercentage']);

    notifyListeners();
  }
}

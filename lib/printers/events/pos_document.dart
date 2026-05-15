import 'package:dashboard/printers/fiscal/fiscal_model.dart';
import 'package:dashboard/printers/utilis.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class PosDocumentLine {

  late String rowGuid;
  late String title;
  late double price;
  late int    quantity;
  late double amount;
  double?     weight;
  String?     note;

}

class PosDocument {

  static PosDocument? _instance;
  static PosDocument instance () => _instance ??= PosDocument();

  List<PosDocumentLine>   _articles = [];
  double                  _amount   = 0.00;
  double                  _discount = 0.00;
  String?                 _trailerLine;

  newDocument(){
    _articles     = [];
    _amount       = 0.00;
    _discount     = 0.00;
    _trailerLine  = null;
  } 

  /// Vendi articolo
  saleArticle({required String title, required double price, required int quantity, required int departmentNumber, double? weight, String? note}){
    double fixedPrice = price.fixDecimal();
    _articles.add(
      PosDocumentLine()
      ..rowGuid   = Uuid().v4()
      ..title     = title
      ..price     = fixedPrice
      ..quantity  = quantity
      ..weight    = weight
      ..note      = note
      ..amount    = (fixedPrice * quantity).fixDecimal()
    );
    _calculateAmount();
  }

  /// Rimuovi articolo
  removeArticle(String guid){
    _articles.removeWhere((a) => a.rowGuid == guid);
    _calculateAmount();
  }

  /// Pulizia vendita
  cleanSale(){
    _articles     = [];
    _amount       = 0.00;
    _discount     = 0.00;
    _trailerLine  = null;
  }

  /// Applica sconto
  bool applyDiscount(double value){
    if( (_amount - value) >= 0 ) {
      _discount = value;
      return true;
    }
    return false;
  }

  /// Remove discount
  removeDiscount(){
    _discount = 0;
  }

  /// Calcolo totale
  _calculateAmount(){
    _amount = 0.00;
    for(PosDocumentLine article in _articles){
      _amount += article.amount;
    }
    if(_discount > 0.00){
      _amount -= _discount.fixDecimal();
    }
    return _amount.fixDecimal();
  }

  /// Prepare receipt
  FiscalReceipt prepareReceipt(String payTitle, int tend, int subtend, double amount, {int? sTend, int? sSubTend, String? sPayTitle, double? sAmount}){

    FiscalReceipt receipt = FiscalReceipt();
    receipt.lines         = [];
    receipt.payments      = [];

    try{

      if(_discount > 0){
        receipt.discount = _discount;
      }

      for (PosDocumentLine line in _articles){
        receipt.lines.add(
          FiscalReceiptLine()
          ..title             = line.title
          ..departmentNumber  = 1
          ..price             = line.price
          ..quantity          = line.quantity
        );
      }

      receipt.payments.add(
        FiscalPayment()
        ..amount    = amount
        ..tend      = tend
        ..subTend   = subtend
        ..title     = payTitle
      );

      if(sTend != null){
        receipt.payments.add(
          FiscalPayment()
          ..amount    = sAmount!
          ..tend      = sTend
          ..subTend   = sSubTend!
          ..title     = sPayTitle!
        );
      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }

    return receipt;
  }

  // Getters
  List<PosDocumentLine> get articles    => _articles;
  double                get amount      => _amount;
  double                get amountDisc  => (_amount - _discount);
  double                get discount    => _discount;
  String?               get trailerLine => _trailerLine;
  bool                  get hasDiscount => _discount > 0;
  bool                  get isCartEmpty => _articles.isEmpty;

}
import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/article.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/cartModelSaledSuspended.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CartSummary {
  late double vatValue;
  late double amountTaxable;
  late double amountTax;
}

class CarrelloController extends ChangeNotifier {
  TableModel? _table;
  TableModel? get table => _table;
  CartModelSaledSuspended? cartSuspended;
  bool riscontro = false;
  final ScrollController scrollControllerCart = ScrollController();
  final List<ProdottoCarrello> _prodotti = [];
  List<Payment> _payments = [];
  // NOVITÀ: restituisco lista non modificabile
  List<Payment> get getPayments => List.unmodifiable(_payments);
  double cashCustomer = 0.0;
  double _remainder = 0.0; // RESTO AL CLIENTE
  double get remainder => _remainder;
  ScontoTipo? discountType;
  double _discount = 0.0;
  double get discount => _discount;
  String _discountReason = '';
  String get discountReason => _discountReason;

  double tips = 0.0;
  String _note = '';
  String get note => _note;
  String _nomeClienteOrdine = '';
  String get nomeClienteOrdine => _nomeClienteOrdine;
  bool splitPayment = false;
  double _ricevuto = 0;
  double get ricevuto => _ricevuto;
  OperatoreModel? _rider = null;
  OperatoreModel? get rider => _rider;
  double _chargeRider = 0;
  double get chargeRider => _chargeRider;
  int? _ordineScontrinoStampato;
  int? get ordineScontrinoStampato => _ordineScontrinoStampato;
  ScontoTipo? _tipoMaggiorazione;
  ScontoTipo? get tipoMaggiorazione => _tipoMaggiorazione;
  double percentualevaloreMaggiorazione = 0;
  //bool nonRiscosso = false;
  double? totaleForzatoCheckout; //per gestire il totale dalla divisione conto

  int divisioneContoPersone = 1;

  void setDivisioneContoPersone(int value) {

    if (value <= 0) value = 1;

    divisioneContoPersone = value;

    notifyListeners();
  }

  void setTipoMaggiorazione (ScontoTipo t ){
    _tipoMaggiorazione = t;
    notifyListeners();
  }

  void rimuoviMaggiorazione ( BuildContext context ){
    final carrello = context.read<CarrelloController>();
    int exist = prodotti.indexWhere((p) => p.article.title == ' Maggiorazione ');
    if( exist > -1 ){
          carrello.removeArticleByUuid(uuid: prodotti[exist].uuid);
    }
    notifyListeners();
  }

  double get totalWithTipsAndDiscount {

    //  DIVISIONE CONTO
    if (totaleForzatoCheckout != null) {

      double totale = totaleForzatoCheckout!;

      totale += tips;

      totale -= discount;

      if (totale < 0) {
        totale = 0;
      }

      return double.parse(
        totale.toStringAsFixed(2),
      );
    }

    // LOGICA STANDARD
    double totale = totaleCarrello;

    totale += tips;

    totale -= discount;

    if (totale < 0) {
      totale = 0;
    }

    return double.parse(
      totale.toStringAsFixed(2),
    );
  }

  void maggiorazione ( BuildContext context, ScontoTipo tipo, String valueInput ) async {
    try{
      final carrello = context.read<CarrelloController>();
      int exist = prodotti.indexWhere((p) => p.article.title == ' Maggiorazione ');

      //Se esiste Elimino e aggiungo uno nuovo
      if( exist > -1 ){
        carrello.removeArticleByUuid(uuid: prodotti[exist].uuid);
      }
      double? valueInputDouble = double.tryParse(valueInput);
      double? prezzoProdotto = 0;

      _tipoMaggiorazione = tipo;

      double totaleCarrello = carrello.totaleCarrello;

      if( valueInputDouble != null && valueInputDouble != 0 ){
        switch (tipo) {
          case ScontoTipo.importo:
            prezzoProdotto = valueInputDouble;
            percentualevaloreMaggiorazione = 0;
          break;
          case ScontoTipo.percentuale:
            prezzoProdotto = double.parse( ((totaleCarrello / 100) * valueInputDouble!).toStringAsFixed(2) );
            percentualevaloreMaggiorazione = valueInputDouble;
          break;
          default:
        }
      }


      //se maggiorazione è 0 non proseguo perchè eliminata sopra
      if( valueInputDouble == null || valueInputDouble == 0 ) return;

      dynamic articleGeneric_ = await getGenericProduct();
      ProdottoCarrello? firstProduct = prodotti.isEmpty ? null : prodotti.first;
      if( articleGeneric_ == null || firstProduct == null || tastierinoKey.currentState?.mounted != true ) return;
      ArticleWhitPriceListModel artDeperment = ArticleWhitPriceListModel(
                                                                          articleType: ArticleType.product,code: articleGeneric_['code'],
                                                                          id:         articleGeneric_['id'],
                                                                          title:     ' Maggiorazione ',
                                                                          idVatRate: firstProduct.article.idVatRate,
                                                                          rateValue: firstProduct.article.rateValue
                                                                        );
      //AGGIUNGO LA MAGGIORAZIONE
      (tastierinoKey.currentWidget as TastierinoCompattoFisso).applicaProdotto(  artDeperment, carrello, true, genericQta: 1, genericPrice: prezzoProdotto, );

      notifyListeners();
    }catch(err){
      debugPrint(err.toString());
    }
  }

  void setDiscountValue ( double v){
    _discount = v;
    notifyListeners();
  }

  void setScontrinoOrdineStampato (int? v ){
    _ordineScontrinoStampato = v;
    notifyListeners();
  }


  void setTotaleForzatoCheckout(double? value) {

    totaleForzatoCheckout = value;

    _ricalcola();
  }

  double get totalCheckoutFinal {

    double totale =
        totaleForzatoCheckout ??
            totalWithTipsAndDiscount;

    return double.parse(
      totale.toStringAsFixed(2),
    );
  }


  void serChargeRider ( double cc ){
    _chargeRider = cc;
    notifyListeners();
  }

  void serRider ( OperatoreModel? op ){
    _rider = op;
    notifyListeners();
  }
  // NOVITÀ: stato carrello esteso
  bool extendedCartOpen = false;
  void setNomeCLiente(String n) {
    _nomeClienteOrdine = n;
    notifyListeners();
  }

  /// ✅ Aggiorna in una sola transazione tutti i dati ordine + inOrder e
  /// notifica una volta sola. Evita rebuild parziali in release mode.
  void applyOrderData({
    required String phone,
    required String address,
    required String caller,
    required String nomeCliente,
    required String note,
    bool inOrder = true,
  }) {
    phoneNumber  = phone;
    addressOrder = address;
    callerPager  = caller;
    _nomeClienteOrdine = nomeCliente;
    _note = note;
    this.inOrder = inOrder;
    notifyListeners();
  }

  /// ✅ Imposta cliente + telefono + indirizzo in una sola transazione atomica.
  /// Evita desincronizzazioni tra cliente e dati contatto.
  void setClienteWithContacts({
    required CustomerModel cliente,
    required String telefono,
    required String indirizzo,
  }) {
    _cliente = cliente;
    phoneNumber  = telefono;
    addressOrder = indirizzo;
    notifyListeners();
  }

  void toggleExtendedCart() {
    extendedCartOpen = !extendedCartOpen;
    notifyListeners();
  }

  void closeExtendedCart() {
    extendedCartOpen = false;
    notifyListeners();
  }

  void openExtendedCart() {
    extendedCartOpen = true;
    notifyListeners();
  }

  void setRicevuto(double r) {
    _ricevuto = r;
    notifyListeners();
  }

  void scrollCartToTop() {
    if (scrollControllerCart.hasClients) {
      scrollControllerCart.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void setNote(String n) {
    _note = n;
    notifyListeners();
  }

  ///////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////ORDINI/////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  bool inOrder = false;
  int? orderinEdit = null;
  String phoneNumber = '';
  String addressOrder = '';
  String callerPager = '';
  String? _tipoOrdine; // takeAway - delivery - eatHere
  String? get tipoOrdine => _tipoOrdine;
  CustomerModel? _cliente;
  CustomerModel? get cliente => _cliente;
  DateTime? dataOrdine;
  int _orderPaid = 0;
  int get orderPaid => _orderPaid;

  // PER GESTIRE LA SELEZIONE DEL CLIENTE / ELIMINA
  void setCliente(CustomerModel? cliente) {
    _cliente = cliente;
    notifyListeners();
  }

  void setTipoOrdine(String? tipoOrdine) {
    _tipoOrdine = tipoOrdine;
    notifyListeners();
  }

  void setPaid(int paid) {
    _orderPaid = paid;
    notifyListeners();
  }

  void clearCliente() {
    _cliente = null;
    if (inOrder) {
      inOrder = false;
    }
    notifyListeners();
  }

  void addArticlesFromOrderInEdit(
    List<ProdottoCarrello> productsOrder,
  ) {
    _prodotti.addAll(productsOrder);
    resetDiscount();
    _ricalcola();
    notifyListeners();
  }

  void changeProductsInCart(
    List<ProdottoCarrello> newProducts,
  ) {
    _prodotti.clear();
    _prodotti.addAll(newProducts);
    notifyListeners();
  }

  void setTable(TableModel t) {
    _table = t;
    notifyListeners();
  }

  void setRemainder( double r ) {
    _remainder = r;
    notifyListeners();
  }

  void setDiscountReason(String r) {
    _discountReason = r;
  }

  /// Castelletto IVA
  List<CartSummary> getSummary() {
    final List<CartSummary> summary = [];

    try {
      for (final p in prodotti) {
        final double grossPriceRow = p.priceRowWithVariant;
        final double netPriceRow = p.priceNetRowWithVariant;
        final double taxRow = grossPriceRow - netPriceRow;

        final indexSummary = summary.indexWhere(
          (s) => s.vatValue == p.vatValue,
        );
        if (indexSummary > -1) {
          summary[indexSummary].amountTaxable += netPriceRow;
          summary[indexSummary].amountTax += taxRow;
        } else {
          final cs = CartSummary()
            ..amountTax = taxRow
            ..amountTaxable = netPriceRow
            ..vatValue = p.vatValue;

          summary.add(cs);
        }
      }
    } catch (err) {
      debugPrint(err.toString());
    } finally {
      return summary;
    }
  }

  /////////////////////////////////////////////////////////
  // FUNZIONI DI RESET PER IL CARRELLO
  /////////////////////////////////////////////////////////
  void clearCart() {
    percentualevaloreMaggiorazione = 0;
    _ordineScontrinoStampato = 0;
    _chargeRider = 0;
    _rider = null;
    _discountReason = '';
    _table = null;
    totaleForzatoCheckout = null;
    cartSuspended = null;
    _prodotti.clear();
    orderinEdit = null;
    _payments = [];
    _note = '';
    setRemainder(0);
    cashCustomer = 0.0;
    tips = 0.0;
    riscontro = false;
    inOrder = false;
    phoneNumber = '';
    addressOrder = '';
    callerPager = '';
    _tipoOrdine = null;
    dataOrdine = null;
    _orderPaid = 0;
    _nomeClienteOrdine = '';
    _tipoMaggiorazione = null;
    //nonRiscosso = false;
    clearCliente();
    resetDiscount();
    notifyListeners();
  }

  void resetDiscount() {
    _discount = 0.0;
    discountType = null;
    notifyListeners();
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////

  void setTips(double tips_) {
    tips = tips_;
    notifyListeners();
  }

  /// Map<String, double> food, beverage, altro
  Map<String, double> getAmountSplitTypeProduct() {
    final Map<String, double> summary = {
      "food": 0,
      "beverage": 0,
      "altro": 0,
    };

    try {
      for (final p in prodotti) {
        final amount = p.priceRowWithVariant;
        final ArticleModel? art = allArticles
            .firstWhereOrNull((a) => a.id == p.article.id);
        if (art == null) continue;

        if (art.tipologies.contains('food')) {
          summary['food'] =
              (summary['food'] ?? 0) + amount;
          continue;
        }

        if (art.tipologies.contains('beverage')) {
          summary['beverage'] =
              (summary['beverage'] ?? 0) + amount;
          continue;
        }

        summary['altro'] =
            (summary['altro'] ?? 0) + amount;
      }
    } catch (err) {
      debugPrint(err.toString());
    } finally {
      return summary;
    }
  }

  /////////////////////////////////////////////// SCONTO E CALCOLI ///////////////////////////////////////////////////
  int get discountIdVatRate {
    final temp = [...prodotti];
    temp.sort(
      (a, b) => double
          .parse(a.article.rateValue ?? '0')
          .compareTo(
            double.parse(b.article.rateValue ?? '0'),
          ),
    );
    if (temp.isEmpty) return 0;
    return temp[0].article.idVatRate!;
  }

  String get discountVatRateValue {
    final temp = [...prodotti];
    temp.sort(
      (a, b) => double
          .parse(a.article.rateValue ?? '0')
          .compareTo(
            double.parse(b.article.rateValue ?? '0'),
          ),
    );
    if (temp.isEmpty) return '0';
    return temp[0].article.rateValue!;
  }

  double get discountTaxable {
    if (discount == 0) return 0.0;
    final vatValueDiscount =
        double.parse(discountVatRateValue) / 100;
    return discount / (1 + vatValueDiscount);
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  // =========================
  // STATO CHECKOUT
  // =========================
  double coperti() {
    final cover = _prodotti.firstWhereOrNull(
      (p) => p.article.articleType == ArticleType.cover,
    );
    if (cover == null) return 0;
    return cover.quantity;
  }

  void removeArticleByUuid({required String uuid}) {
    final index = _prodotti.indexWhere(
      (prodInCart) => prodInCart.uuid == uuid,
    );
    if (index != -1) {
      _prodotti.removeAt(index);
      _ricalcola();
      notifyListeners();
    }
  }

  void setPayments(List<Payment> pp) {
    _payments = pp;
  }

  void resetPayments() {
    _payments = [];
    notifyListeners();
  }

  void addPayment(Payment p) {
    final pp = _payments.firstWhereOrNull(
      (p_) => p_.idPayment == p.idPayment,
    );
    if (pp != null) {
      _payments.remove(pp);
      _payments.add(p);
      return;
    }
    _payments.add(p);
  }

  void removePayment(Payment p) {
    _payments.remove(p);
  }

  // ===========================
  //  TOTALE CARRELLO
  // ===========================
  double get totaleCarrello {
    return prodotti.fold(
      0.0,
      (sum, p) {
        // mantengo logica vecchia che ignora la mancia
        final isTip = p.article.title.toUpperCase().contains('MANCIA');
        if (isTip) {
          return sum +
              totalVariants([
                ...p.variationsFree,
                ...p.variationsInfo,
                ...p.variationsMinus,
                ...p.variationsPlus,
              ]);
        }
        return sum +
            (p.unitPrice * p.quantity) +
            totalVariants([
              ...p.variationsFree,
              ...p.variationsInfo,
              ...p.variationsMinus,
              ...p.variationsPlus,
            ]);
      },
    );
  }

  double totalVariants(List<ProdottoCarrello>? variants) {
    return variants?.fold<double>(
          0.0,
          (sum, v) => sum + v.unitPrice * v.quantity,
        ) ??
        0.0;
  }

  // ===========================
  //  TOTALE CARRELLO IMPONIBILE
  // ===========================
  double totalVariantsImponibile(
    List<ProdottoCarrello>? variants,
  ) {
    return variants?.fold<double>(
          0.0,
          (sum, p) {
            final ivaPerc = double.tryParse(
                  p.article.rateValue ?? '0',
                ) ??
                0.0;
            final prezzoRiga =
                p.unitPrice * p.quantity;
            final imponibileRiga =
                prezzoRiga / (1 + ivaPerc / 100);
            return sum + imponibileRiga;
          },
        ) ??
        0.0;
  }

  double get totaleCarrelloImponibile {
    return prodotti.fold(
      0.0,
      (sum, p) {
        final ivaPerc = double.tryParse(
              p.article.rateValue ?? '0',
            ) ??
            0.0;
        final prezzoRiga =
            p.unitPrice * p.quantity;
        final imponibileRiga =
            prezzoRiga / (1 + ivaPerc / 100);
        return sum +
            imponibileRiga +
            totalVariantsImponibile([
              ...p.variationsFree,
              ...p.variationsInfo,
              ...p.variationsMinus,
              ...p.variationsPlus,
            ]);
      },
    );
  }

  // ================================================================
  // AGGIUNGI COPERTO
  // ================================================================
  void addCoverInCart(
    ArticleWhitPriceListModel a,
    double quantity,
    double? priceUnit,
  ) {
    final uuid = const Uuid().v4();
    final cover = _prodotti.firstWhereOrNull(
      (art) => art.article.articleType == ArticleType.cover,
    );
    if (cover != null) {
      upgradeQuantityRowCart(
        cover.uuid,
        cover.quantity + quantity,
      );
    } else {
      _prodotti.insert(
        0,
        ProdottoCarrello(
          article: a,
          exit: 0,
          isVariant: false,
          percentageDiscount: 0,
          unitPrice:
              priceUnit ?? double.parse(a.price ?? '0'),
          valueDiscount: 0,
          uuid: uuid,
          variationsFree: [],
          variationsInfo: [],
          variationsMinus: [],
          variationsPlus: [],
          quantity: quantity,
          idOperator: operatorLogged!.id,
          nameOperator:
              (operatorLogged!.firstname ?? '') +
                  ' ' +
                  (operatorLogged!.lastname ?? ''),
          printed: 0,
          discountPercentageRow: 0
        ),
      );
    }
    resetDiscount();
    _ricalcola();
    notifyListeners();
  }

  // ================================================================
  // AGGIUNGI ARTICOLO AL CARRELLO
  // ================================================================
  void addArticleInCart(
    ArticleWhitPriceListModel a,
    double quantity,
    double? priceUnit,
    bool genericArticleFromDepartment,
  ) {
    if (a.articleType == ArticleType.cover) {
      addCoverInCart(a, quantity, priceUnit);
    } else {
      // se generico dal reparto → sempre nuova riga
      if (genericArticleFromDepartment ||
          a.generic == 1) {
        final uuid = const Uuid().v4();
        _prodotti.add(
          ProdottoCarrello(
            exit: 0,
            article: a,
            isVariant: false,
            percentageDiscount: 0,
            unitPrice:
                priceUnit ?? double.parse(a.price ?? '0'),
            valueDiscount: 0,
            uuid: uuid,
            variationsFree: [],
            variationsInfo: [],
            variationsMinus: [],
            variationsPlus: [],
            quantity: quantity,
            idOperator: operatorLogged!.id,
            nameOperator:
                (operatorLogged!.firstname ?? '') +
                    ' ' +
                    (operatorLogged!.lastname ?? ''),
            printed: 0,
            discountPercentageRow : 0
          ),
        );
      } else {
        // controllo se esiste nel carrello e non ha varianti
        final prodExistInCart =
            _prodotti.indexWhere((p) => p.article.code == a.code &&
                p.variationsFree.isEmpty &&
                p.variationsInfo.isEmpty &&
                p.variationsMinus.isEmpty &&
                p.variationsPlus.isEmpty);
        if (prodExistInCart != -1) {
          _prodotti[prodExistInCart]
              .incrementQuantity();
        } else {
          final uuid = const Uuid().v4();
          _prodotti.add(
            ProdottoCarrello(
              exit: 0,
              article: a,
              isVariant: false,
              percentageDiscount: 0,
              unitPrice:
                  priceUnit ?? double.parse(a.price ?? '0'),
              valueDiscount: 0,
              uuid: uuid,
              variationsFree: [],
              variationsInfo: [],
              variationsMinus: [],
              variationsPlus: [],
              quantity: quantity,
              idOperator: operatorLogged!.id,
              nameOperator:
                  (operatorLogged!.firstname ?? '') +
                      ' ' +
                      (operatorLogged!.lastname ?? ''),
              printed: 0,
              discountPercentageRow : 0
            ),
          );
        }
      }
    }
    resetDiscount();
    _ricalcola();
    notifyListeners();
  }

  // ================================================================
  // MODIFICA PREZZO
  // ================================================================
  void upgradePriceRowCart(String uuid, double newPriceRow) {
    final index = _prodotti.indexWhere(
      (prodInCart) => prodInCart.uuid == uuid,
    );
    if (index < 0) return;
    final temp = _prodotti[index];
    final newUnitPrice = newPriceRow / temp.quantity;
    _prodotti[index] = ProdottoCarrello(
      exit: 0,
      uuid: uuid,
      percentageDiscount: temp.percentageDiscount,
      unitPrice: newUnitPrice,
      valueDiscount: temp.valueDiscount,
      variationsFree: temp.variationsFree,
      variationsInfo: temp.variationsInfo,
      variationsMinus: temp.variationsMinus,
      variationsPlus: temp.variationsPlus,
      article: temp.article,
      quantity: temp.quantity,
      isVariant: false,
      idOperator: operatorLogged!.id,
      nameOperator:
          (operatorLogged!.firstname ?? '') +
              ' ' +
              (operatorLogged!.lastname ?? ''),
      printed: 0,
      discountPercentageRow : 0
    );
    _ricalcola();
    resetDiscount();
    segnaOrdineModificato();
    notifyListeners();
  }

  // ================================================================
  // MODIFICA VARIANTI SU RIGA ARTICOLO
  // ================================================================
  void upgradeVariantsRowCart(
    String uuid,
    List<ProdottoCarrello>? free,
    List<ProdottoCarrello>? minus,
    List<ProdottoCarrello>? plus,
    List<ProdottoCarrello>? info,
    double qta,
    bool genericArticleFromDepartment,
  ) {
    final index = _prodotti.indexWhere(
      (prodInCart) => prodInCart.uuid == uuid,
    );
    if (index < 0) return;
    final temp = _prodotti[index];

    _prodotti[index] = ProdottoCarrello(
      exit: 0,
      uuid: uuid,
      percentageDiscount: temp.percentageDiscount,
      unitPrice: temp.unitPrice,
      valueDiscount: temp.valueDiscount,
      variationsFree: free ?? temp.variationsFree,
      variationsInfo: info ?? temp.variationsInfo,
      variationsMinus: minus ?? temp.variationsMinus,
      variationsPlus: plus ?? temp.variationsPlus,
      article: temp.article,
      quantity: qta,
      isVariant: false,
      idOperator: operatorLogged!.id,
      nameOperator:
          (operatorLogged!.firstname ?? '') +
              ' ' +
              (operatorLogged!.lastname ?? ''),
      printed: 0,
      discountPercentageRow : 0
    );

    // se non applico le varianti a tutta la riga → splitto
    if ((temp.quantity - qta) != 0) {
      addArticleInCart(
        temp.article,
        (temp.quantity - qta),
        temp.unitPrice,
        genericArticleFromDepartment,
      );
    }
    resetDiscount();
    _ricalcola();
    segnaOrdineModificato();
    notifyListeners();
  }

  // ================================================================
  // MODIFICA QUANTITÀ
  // ================================================================
  void upgradeQuantityRowCart(
    String uuid,
    double newQuantity,
  ) {
    final index = _prodotti.indexWhere(
      (prodInCart) => prodInCart.uuid == uuid,
    );
    if (index < 0) return;
    final temp = _prodotti[index];
    _prodotti[index] = ProdottoCarrello(
      exit: 0,
      isVariant: false,
      percentageDiscount: temp.percentageDiscount,
      unitPrice: temp.unitPrice,
      valueDiscount: temp.valueDiscount,
      variationsFree: temp.variationsFree,
      variationsInfo: temp.variationsInfo,
      variationsMinus: temp.variationsMinus,
      variationsPlus: temp.variationsPlus,
      uuid: uuid,
      article: temp.article,
      quantity: newQuantity,
      idOperator: operatorLogged!.id,
      nameOperator:
          (operatorLogged!.firstname ?? '') +
              ' ' +
              (operatorLogged!.lastname ?? ''),
      printed: 0,
      discountPercentageRow : 0
    );

    resetDiscount();
    _ricalcola();
    segnaOrdineModificato();
    notifyListeners();
  }


   // ================================================================
  // MODIFICA QUANTITÀ
  // ================================================================
  void upgradeDiscountRowCart(
    String uuid,
    double discount,
  ) {
    final index = _prodotti.indexWhere((prodInCart) => prodInCart.uuid == uuid,);
    if (index < 0) return;
    final temp = _prodotti[index];
    double? priceOrigin = double.tryParse(temp.article.price ?? '');
    if( priceOrigin == null ) return;
    double newPriceUnit = priceOrigin  - (( priceOrigin / 100) * discount);

    _prodotti[index] = ProdottoCarrello(
      exit: 0,
      isVariant: false,
      percentageDiscount: temp.percentageDiscount,
      unitPrice: newPriceUnit,
      valueDiscount: temp.valueDiscount,
      variationsFree: temp.variationsFree,
      variationsInfo: temp.variationsInfo,
      variationsMinus: temp.variationsMinus,
      variationsPlus: temp.variationsPlus,
      uuid: uuid,
      article: temp.article,
      quantity: temp.quantity,
      idOperator: operatorLogged!.id,
      nameOperator:
          (operatorLogged!.firstname ?? '') +
              ' ' +
              (operatorLogged!.lastname ?? ''),
      printed: 0,
      discountPercentageRow : discount
    );

    resetDiscount();
    _ricalcola();
    segnaOrdineModificato();
    notifyListeners();
  }

  // =========================
  // APPLICO LO SCONTO DA PERCENTUALE
  // =========================
  void applyDiscount(
    String value,
    ScontoTipo type,
    ControllerModuloPagamenti ctrModuloPagamenti,
    BuildContext context,
  ) {
    discountType = type;
    value = value == '' ? '0' : value;
    switch (type) {
      case ScontoTipo.percentuale:
        final percentage_ = double.parse(
          value.replaceAll(',', '.'),
        );
        final totalCart = totaleCarrello;
        if (percentage_ > 100 || percentage_ == 0) {
          _discount = 0;
          break;
        }
        final disc = (totalCart / 100) * percentage_;
        _discount = disc;
        break;
      case ScontoTipo.importo:
        final total = double.parse(value.replaceAll(',', '.'));
        if (total > totaleCarrello) {
          _discount = totaleCarrello;
          break;
        }
        _discount = total;
        break;
      case ScontoTipo.totale:
        final total = double.parse(value.replaceAll(',', '.'));
        final currentTotal = totaleCarrello;
        if( total == 0 ) _discount = 0;
        if( total > 0 )  _discount = currentTotal - total;

        break;
    }
    // mantengo la logica vecchia sul resto
    if ( ricevuto >= totalWithTipsAndDiscount && totalWithTipsAndDiscount > 0 )  setRemainder(  ricevuto - totalWithTipsAndDiscount );

    ctrModuloPagamenti
        .setFirstTotalForCaschAndResetOthersPayments(
      context,
    );
    notifyListeners();
  }

  void resetCaricamentoCheckout() {
    /*  _ordineCaricatoPerCheckout = false; */
  }

  // data e ora dell'ordine
  void setDataOrdine(DateTime value) {
    dataOrdine = value;
    notifyListeners();
  }

  // =======================================================
  // MODALITÀ MODIFICA ORDINE (FIX DEFINITIVO)
  // =======================================================

  bool _ordineInModifica = false;
  bool get ordineInModifica => _ordineInModifica;

  void setOrdineInModifica(bool v) {
    _ordineInModifica = v;
    notifyListeners();
  }

  bool _ordineModificato = false;
  bool get ordineModificato => _ordineModificato;

  void segnaOrdineModificato() {
    if (_ordineInModifica) {
      _ordineModificato = true;
      notifyListeners();
    }
  }

  void resetModifica() {
    _ordineInModifica = false;
    _ordineModificato = false;
    notifyListeners();
  }

  bool _nonRiscosso = false;
  bool _nessunaStampa = false;
  bool get nessunaStampa => _nessunaStampa;

  void setNonRiscosso(bool v) {
    _nonRiscosso = v;

    // REGOLA: se non riscosso, niente stampa
    if (_nonRiscosso) {
      _nessunaStampa = true;
    }

    notifyListeners();
  }

  void setNessunaStampa(bool v) {
    _nessunaStampa = v;
    notifyListeners();
  }

  // =============================================================
  // AGGIUNGE PRODOTTI DA CHECKOUT SALVATO (MERGE)
  // =============================================================
  void aggiungiDaCheckoutSalvato(
    Map<String, dynamic> payload,
  ) {
    /* ... codice commentato originale ... */
  }

  void loadFromJson(Map<String, dynamic> json) {
    _prodotti.clear();

    final List items = json["items"] ?? [];

    /* caricamento prodotti commentato */

    // CLIENTE
    if (json["cliente"] != null) {
      _cliente = CustomerModel.fromJson(
        Map<String, dynamic>.from(json["cliente"]),
      );
    } else {
      _cliente = null;
    }

    // RICALCOLO FINALE
    _ricalcola();
    notifyListeners();
  }

  double get daPagare => _totale;

  double _totale = 0.0;
  double _totaleLordo = 0.0;
  double _scontoPercentuale = 0.0;
  bool readonly = false;
  List<ProdottoCarrello> get prodotti => _prodotti;
  double get totale => _totale;
  double get totaleLordo => _totaleLordo;
  double get sconto => _scontoPercentuale;

  /// Totale imponibile su tutto il carrello
  double get totaleImponibile =>
      0; // _prodotti.fold(0.0, (sum, p) => sum + p.totaleNetto);

  /// Totale IVA su tutto il carrello
  double get ivaTotale =>
      0; // _prodotti.fold(0.0, (sum, p) => sum + p.totaleIva);

  Future<bool> caricaUltimoCheckout() async {
    if (prodotti.isEmpty) return false;

    readonly = true;
    notifyListeners();
    return true;
  }

  // RICALCOLO
  void _ricalcola() {

    double nuovoTotale = 0.0;

    // USA TOTALE FORZATO SE PRESENTE
    if (totaleForzatoCheckout != null) {

      nuovoTotale = totaleForzatoCheckout!;

    } else {

      for (final p in _prodotti) {

        final varianti =
        totalVariants([
          ...p.variationsFree,
          ...p.variationsInfo,
          ...p.variationsMinus,
          ...p.variationsPlus,
        ]);

        nuovoTotale +=
            (p.unitPrice * p.quantity) + varianti;
      }
    }

    // APPLICO MANCIA
    nuovoTotale += tips;

    // APPLICO SCONTO
    nuovoTotale -= discount;

    if (nuovoTotale < 0) {
      nuovoTotale = 0;
    }

    _totale = double.parse(
      nuovoTotale.toStringAsFixed(2),
    );

    _totaleLordo = _totale;

    notifyListeners();
  }

  // ================================================================
  // AGGIORNA PREZZO
  // ================================================================
  void aggiornaPrezzo(
    ProdottoCarrello riga,
    double nuovoPrezzo,
  ) {
    /* vecchia logica commentata */
  }

  // ================================================================
  // SCONTO
  // ================================================================
  void applicaSconto(double percentuale) {
    /* vecchia logica commentata */
  }

  void rimuoviSconto() {
    /* vecchia logica commentata */
  }

  /// CHECKOUT COMPLETO (POS LOGIC)
  bool get checkoutCompleto {
    /* logica completa commentata */
    return true;
  }
}
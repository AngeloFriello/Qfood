import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/modelli/printer.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

class ControllerTableOpened extends ChangeNotifier{
  TextEditingController controllerNote = TextEditingController();

  int _coverSelected = 0;
  int get coverSelected => _coverSelected;

  int _serviceTable = 0;
  int get serviceTable => _serviceTable;

  int _numberCoverSelected   = 0;
  int get numberCoverSelected => _numberCoverSelected;
  
  TableModel?  _table;
  TableModel? get table => _table;

  CustomerModel? _customer;
  CustomerModel? get customer => _customer;

  int? _idPriceList;
  int? get idPriceList => _idPriceList;
  
  String _note = '';
  String get note => _note;

  int    _fullteMeal = 0;
  int   get fullMeal => _fullteMeal;

  List<ProdottoCarrello> _products = [];
  List<ProdottoCarrello> get products => _products;

  int _exitSelectedForProduct = 0;
  int get exitSelectedForProduct => _exitSelectedForProduct;

  int _lastExit = 0;
  int get lastExist => _lastExit;

  void setCoverInCartTable() async {
    if( idPriceList == null ) return;
    //RIMUOVO I VECCHI COPERTI
    _products = _products.where((p) => p.article.articleType != ArticleType.cover ).toList();
    List<ArticleWhitPriceListModel> cov = await ArticleWhitPriceListModel.getCovers(idPriceList!);
    
    if( cov.isNotEmpty ){
      ProdottoCarrello prodCover = ProdottoCarrello(
                                    uuid: Uuid().v4(), 
                                    isVariant: false, 
                                    exit: 1, 
                                    article: cov[0], 
                                    quantity: double.parse( numberCoverSelected.toString() ) , 
                                    unitPrice: double.parse( cov[0].price ?? '0') , 
                                    percentageDiscount: 0, 
                                    valueDiscount: 0, 
                                    variationsMinus: [], 
                                    variationsPlus: [], 
                                    variationsInfo: [], 
                                    variationsFree: [], 
                                    nameOperator: operatorLogged?.title ?? 'nessun nome', 
                                    idOperator: operatorLogged?.id ?? 0,
                                    printed: 0,
                                    discountPercentageRow : 0
                                  );
      _products.add(prodCover);
    }
    notifyListeners();
    debugPrint( cov.toString() );
  }

  void changeExitProduct( List<ProdottoCarrello> prodotti, int exit_ ){
    prodotti.forEach((p) {
      if( p.printed == 1 ) return;
      p.exit = exit_;
    });
    notifyListeners();
  }


  void setLastExit (int ext ){
    _lastExit = ext;
    notifyListeners();
  }

    void setServiceTable (int serv ){
    _serviceTable = serv;
    notifyListeners();
  }

  void setExitSelectedForProcuct (int ext ){
    _exitSelectedForProduct = ext;
    notifyListeners();
  }

  void setNumberCoverSelected( int ncs ){
    _numberCoverSelected = ncs;
    setCoverInCartTable();
  }

  void setCovers (int cc ){
    table!.coversInTable = cc;
    notifyListeners();
  }

  void setNote( String n ){
    _note = n;
    notifyListeners();
  }

  void setFullMeal( int fm ){
    _fullteMeal = fm;
    notifyListeners();
  }

  void setCustomer( CustomerModel? c ){
    _customer = c;
    notifyListeners();
  }

   void setTable( TableModel? tab ){
    _table = tab;
    notifyListeners();
  }

  void setIdPriceList( int? id ){
    _idPriceList = id;
    setCoverInCartTable();
  }

  void openTable( TableModel table  ) async {
    final respCustomer      = await LocalDB.query("SELECT * FROM customers WHERE id = ${table.idCustomer}");
    CustomerModel? c        = respCustomer.isNotEmpty ? CustomerModel.fromMap(respCustomer[0])  : null;
    _coverSelected          = table.coversInTable;
    _customer = c;
    _table    = table;
    _lastExit = table.lastExit;
    _note     = table.note ?? '';
    _products = table.products ?? [];
    _idPriceList = table.idListPrice;
    controllerNote.text = table.note ?? '';
    setTable(table);
    notifyListeners();
  }


  void clearTable(){
    _note = '';
    _table = null;
    _customer = null;
    _fullteMeal = 0;
    _products = [];
    _lastExit = 0;
    _idPriceList = null;
    _coverSelected   = 0;
    _idPriceList = null;
    _exitSelectedForProduct = 0;
    setCovers(0);
    notifyListeners();
  }

  String getStatus (){
    String status_ = '';
    try{
      if( products.where((p) => p.article.articleType != ArticleType.cover).length > 0 ){
        status_ = 'impegnato';
      }

    }catch( err ){

    }finally{
      return status_;
    }
  }

  TableModel? getTable (){
    try{
      return TableModel( 
        id:             table!.id, 
        title:          table!.title, 
        positionX:      table!.positionX, 
        positionY:      table!.positionY, 
        idRoom:         table!.idRoom, 
        cover:          table!.cover, 
        enabled:        table!.enabled, 
        products:       products, 
        blocked:        table!.blocked, 
        lastExit:       lastExist, 
        idListPrice:    idPriceList,
        idCustomer:     customer?.id,
        joinedTables:   table!.joinedTables,
        note:           controllerNote.text,
        status:         getStatus(),
        idOperatorOpenTable: table!.idOperatorOpenTable,
        coversInTable:  coverSelected,
        idJoinedParent: table!.idJoinedParent,
      );
    }catch( err ){

    }
  }

  void removeArticleByUuid({ required String uuid }) {
    final index = _products.indexWhere((prodInCart) => prodInCart.uuid == uuid );
    if (index != -1) {
      _products.removeAt(index);
      notifyListeners();
    }
  }

    // ================================================================
  // MODIFICA VARIANTI SU RIGA ARTICOLO
  // ================================================================
  void upgradeVariantsRowTable (
                                String uuid, 
                                List<ProdottoCarrello>? free, 
                                List<ProdottoCarrello>? minus, 
                                List<ProdottoCarrello>? plus, 
                                List<ProdottoCarrello>? info,
                                double qta,
                                bool genericArticleFromDepartment
                              ){
    final index = _products.indexWhere((prodInCart ) => prodInCart.uuid == uuid);
    if( index < 0 ) return;
    ProdottoCarrello temp = _products[index];
  
   _products[index] = ProdottoCarrello(
                                          exit: 0,
                                          uuid: uuid,
                                          percentageDiscount: temp.percentageDiscount,
                                          unitPrice:          temp.unitPrice,
                                          valueDiscount:      temp.valueDiscount,
                                          variationsFree:     free  ?? temp.variationsFree,
                                          variationsInfo:     info  ?? temp.variationsInfo,
                                          variationsMinus:    minus ?? temp.variationsMinus,
                                          variationsPlus:     plus  ?? temp.variationsPlus,
                                          article:            temp.article, 
                                          quantity:           qta,
                                          isVariant: false,
                                          idOperator: operatorLogged!.id,
                                          nameOperator: (operatorLogged!.firstname ?? '' ) +' '+(operatorLogged!.lastname ?? '' ),
                                          printed: 0,
                                          discountPercentageRow : 0
                                        );
    //CONTROLLO SE STO APPLICANDO LE VARIANTI A TUTTA LA RIGA. IN CASO CONTRARIO SPLITTO
    if( (temp.quantity - qta) != 0 ){
      addArticleInCart( temp.article, (temp.quantity - qta), temp.unitPrice, genericArticleFromDepartment );
    }
    notifyListeners(); 
  }


  //DIVIDI IL CARRELLO PER REPARTI STAMPA
  Future< Map< String, List<ProdottoCarrello>>  > splitProductsForDeparment( bool isBanch ,List<ProdottoCarrello> products_ ) async {
    List<ProdottoCarrello> copyProducts = [...products_];
     Map< String, List<ProdottoCarrello>>  mapForPrint = {};
    try{
      final futures = copyProducts.map( (p) async {
        String query = "SELECT * FROM articlePrinter WHERE idArticle = ${ p.article.id }";
        final resp   = await LocalDB.query(query);
        if( resp.isEmpty ) return;
        p.printsDestination = PrinterForArticle.fromLocalDb(resp[0]);
      });

      await Future.wait(futures);

      copyProducts.forEach((p) {
        PrinterForArticle? prints_ = p.printsDestination;
        if( prints_ == null ) return;

        if( isBanch ){
          //SE SIAMO IN SUL PUNTO CASSA
          if(  prints_.printersBench.isEmpty ) return;
            prints_.printersBench.forEach((pRomm)  {
            String addressBanch = pRomm.ipAddress +':'+ pRomm.port.toString();
            if( mapForPrint.containsKey( addressBanch ) ) {
              mapForPrint[addressBanch]!.add(p);
            }else{
              mapForPrint[addressBanch] = [];
              mapForPrint[addressBanch]!.add(p);
            }
          });
        }else{
          //SE SIAMO IN UN TAVOLO
          if(  prints_.printersRoom.isEmpty ) return;
          prints_.printersRoom.forEach((pRomm)  {
            String addressRoom = pRomm.ipAddress +':'+ pRomm.port.toString();
            if( mapForPrint.containsKey( addressRoom ) ) {
              mapForPrint[addressRoom]!.add(p);
            }else{
              mapForPrint[addressRoom] = [];
              mapForPrint[addressRoom]!.add(p);
            }
          });
        }
      });

    }catch( err ){  
      debugPrint( err.toString() );
    }finally{
      return mapForPrint;
    }
  }

    // ================================================================
  // AGGIUNGI ARTICOLO Al Tavolo
  // ================================================================
  void addArticleInCart(ArticleWhitPriceListModel a, double quantity, double? priceUnit, bool genericArticleFromDepartment) {
      if( a.articleType == ArticleType.cover ){
        addCoverInCart(a, quantity, priceUnit);
      }else{
        //SE ARRIVA DAL REPARTO QUINDI GENERICO AGGIUNGO SEMPRE UNA RIGA NUOVA PERCHE IL CODE é SEMPRE UGUALE
        if( genericArticleFromDepartment ){
            String uuid = Uuid().v4();
            _products.add(
              ProdottoCarrello(
                exit: 0,
                article: a,
                isVariant: false,
                percentageDiscount: 0,
                unitPrice: priceUnit ?? double.parse(a.price ?? '0'),
                valueDiscount: 0,
                uuid: uuid,
                variationsFree: [],
                variationsInfo: [],
                variationsMinus: [],
                variationsPlus: [],
                quantity: quantity,
                idOperator: operatorLogged!.id,
                nameOperator: (operatorLogged!.firstname ?? '' ) +' '+(operatorLogged!.lastname ?? '' ),
                printed: 0,
                discountPercentageRow : 0
              ),
            );
        }else{
           //CONTROLLO SE ESISTE NEL CARRELLO E NON HA VARIANTI ABBINATE
          int prodExistInCart = _products.indexWhere((p) => p.article.code == a.code
                                                          && p.article.articleType == a.articleType 
                                                          && p.variationsFree.isEmpty 
                                                          && p.variationsInfo.isEmpty 
                                                          && p.variationsMinus.isEmpty 
                                                          && p.variationsPlus.isEmpty 
                                                          );
          if(prodExistInCart != -1){
            _products[prodExistInCart].incrementQuantity();
          }else{
          String uuid = Uuid().v4();
            _products.add(
              ProdottoCarrello(
                exit: 0,
                article: a,
                isVariant: false,
                percentageDiscount: 0,
                unitPrice: priceUnit ?? double.parse(a.price ?? '0'),
                valueDiscount: 0,
                uuid: uuid,
                variationsFree: [],
                variationsInfo: [],
                variationsMinus: [],
                variationsPlus: [],
                quantity: quantity,
                idOperator: operatorLogged!.id,
                nameOperator: (operatorLogged!.firstname ?? '' ) +' '+(operatorLogged!.lastname ?? '' ),
                printed: 0,
                discountPercentageRow : 0
              ),
            );
        }}}


    notifyListeners();
  }


    // ================================================================
  // AGGIUNGI COPERTO
  // ================================================================
  void addCoverInCart(ArticleWhitPriceListModel a, double quantity, double? priceUnit) {
      String uuid = Uuid().v4();
      ProdottoCarrello? cover = _products.firstWhereOrNull((art) => art.article.articleType == ArticleType.cover);
      if( cover != null ){
        upgradeQuantityRowCart(cover.uuid, cover.quantity + quantity );
      }else{
       _products.insert(0,
        ProdottoCarrello(
          article: a,
          exit: 0,
          isVariant: false,
          percentageDiscount: 0,
          unitPrice: priceUnit ?? double.parse(a.price ?? '0'),
          valueDiscount: 0,
          uuid: uuid,
          variationsFree: [],
          variationsInfo: [],
          variationsMinus: [],
          variationsPlus: [],
          quantity: quantity,
          idOperator: operatorLogged!.id,
          nameOperator: (operatorLogged!.firstname ?? '' ) +' '+(operatorLogged!.lastname ?? '' ),
          printed: 0,
          discountPercentageRow : 0
        ),
      );
      }
    notifyListeners();
  }

    // ================================================================
  // MODIFICA QUANTITÀ
  // ================================================================
  void upgradeQuantityRowCart(String uuid, double newQuantity) {
    final index = _products.indexWhere((prodInCart ) => prodInCart.uuid == uuid);
    if( index < 0 ) return;
    ProdottoCarrello temp = _products[index];
    _products[index] = ProdottoCarrello(
                                          exit: 0,
                                          isVariant: false, 
                                          percentageDiscount: temp.percentageDiscount, 
                                          unitPrice: temp.unitPrice,
                                          valueDiscount: temp.valueDiscount,
                                          variationsFree:     temp.variationsFree,
                                          variationsInfo:     temp.variationsInfo,
                                          variationsMinus:    temp.variationsMinus,
                                          variationsPlus:     temp.variationsPlus,
                                          uuid: uuid, 
                                          article: temp.article,
                                          quantity: newQuantity,
                                          idOperator: operatorLogged!.id,
                                          nameOperator: (operatorLogged!.firstname ?? '' ) +' '+(operatorLogged!.lastname ?? '' ),
                                          printed: 0,
                                          discountPercentageRow : 0
                                        );

    notifyListeners(); 
  }

    // ===========================
  //  TOTALE CARRELLO
  // ===========================
  double get totaleCarrello {
   return _products.fold( 0.0, (sum, p) => sum + (p.unitPrice * p.quantity) + totalVariants(
                                                                                              [
                                                                                                ...p.variationsFree,
                                                                                                ...p.variationsInfo,
                                                                                                ...p.variationsMinus,
                                                                                                ...p.variationsPlus
                                                                                              ]) ,) ;
  }

  double totalVariants(List<ProdottoCarrello>? variants) {
    return variants?.fold<double>(0.0, (sum, v) => sum + v.unitPrice * v.quantity) ?? 0.0;
  }
}
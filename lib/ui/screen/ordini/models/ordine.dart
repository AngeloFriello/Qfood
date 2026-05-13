
import 'dart:convert';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'ordine_item.dart';
import 'ordine_stato.dart';
import 'ordine_tipo.dart';


class Ordine {
  final int? id;
  final String? nomeCliente;
  final CustomerModel? cliente;
  final OrdineTipo tipo;
  final OrdineStato stato;
  final DateTime data;
  final List<ProdottoCarrello> articles;
  final String? indirizzo;
  final String? telefono;
  final String? note;
  final String? callerPager;
  final int    paid;
  final int?   idRider;
  final double? change; 
  final int?     receiptPrinted;

  const Ordine({
    this.id,
    required this.nomeCliente,
    required this.cliente,
    required this.tipo,
    required this.stato,
    required this.data,
    required this.articles,
    required this.paid,
    this.indirizzo,
    this.telefono,
    this.note,
    this.callerPager,
    this.idRider,
    this.change,
    this.receiptPrinted
  });


  

  //TITOLO CLIENTE

  String get titleCustomer {
    if( cliente == null ) return nomeCliente ?? '';
    return cliente?.businessName ?? ('${cliente?.personalFirstname ?? ''} ${cliente?.personalLastname ?? ''}');
  } 

  // ===========================
  //  TOTALE CARRELLO
  // ===========================
  double totalVariants(List<ProdottoCarrello>? variants) {
    return variants?.fold<double>(0.0, (sum, v) => sum + v.unitPrice * v.quantity) ?? 0.0;
  }


  double get totaleCarrello {
   return articles.fold( 0.0, (sum, p) => sum + (p.unitPrice * p.quantity) + totalVariants(
                                                                                              [
                                                                                                ...p.variationsFree,
                                                                                                ...p.variationsInfo,
                                                                                                ...p.variationsMinus,
                                                                                                ...p.variationsPlus
                                                                                              ]) ,) ;
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'cliente': cliente == null ? null : jsonEncode(cliente?.toMap()) ,
    'nomeCLiente' : nomeCliente,
    'tipo': tipo.name,
    'stato': stato.name,
    'data': data.toIso8601String(),
    'telefono': telefono,
    'indirizzo': indirizzo,
    'note': note,
    'articles': articles.map((e) => e.toJson()).toList(),
    'callerPager' : callerPager,
    'paid'        : paid,
    'idRaider'    : idRider,
    'change'      : change,
    'receiptPrinted' : receiptPrinted
  };


  Ordine copyWith({
    OrdineStato? stato,
    CustomerModel? cliente,
    List<OrdineItem>? items,
    String? indirizzo,
    String? telefono,
    String? note,
    int?   paid,
    String? nomeCLiente_,
    double? change_,
    int? idRaider_,
    int? receiptPrinted_
  }) {
    return Ordine(
      paid: paid ?? 0,
      nomeCliente: nomeCLiente_,
      cliente: cliente ?? this.cliente,
      tipo: tipo,
      stato: stato ?? this.stato,
      data: data,
      articles: articles,
      indirizzo: indirizzo ?? this.indirizzo,
      telefono: telefono ?? this.telefono,
      note: note ?? this.note,
      change: change_ ?? this.change,
      idRider: idRaider_ ?? this.idRider,
      receiptPrinted : receiptPrinted_ ?? receiptPrinted
    );
  }

  Map<String,dynamic>  forDb({ dynamic respDbCurrentOrder } ) => {
    'id'        : respDbCurrentOrder != null ? respDbCurrentOrder['id']: id,
    'cliente'   : cliente == null ? null : jsonEncode( cliente?.toMap() ),
    'nomeCliente' : nomeCliente,
    'tipo'      : tipo == OrdineTipo.consegna ? 'delivery' : tipo == OrdineTipo.mangiaQui  ? 'eatHere' : 'takeAway',  //eatHere
    'stato'     : respDbCurrentOrder != null ? respDbCurrentOrder['stato'] : stato.label,
    'data'      : data.toIso8601String(),
    'articles'  : jsonEncode(articles.map((art) => art.toJson()).toList()) ,
    'indirizzo' : indirizzo,
    'telefono'       :  telefono,
    'note'           :  note,
    'callerPager'    :  callerPager,
    'lastUpdate'     :  DateTime.now().millisecondsSinceEpoch,
    'createAt'       :  respDbCurrentOrder != null ? respDbCurrentOrder['createAt'] : DateTime.now().millisecondsSinceEpoch,
    'paid'           :  respDbCurrentOrder != null ? respDbCurrentOrder['paid'] : paid,
    'change'         :  respDbCurrentOrder != null ? respDbCurrentOrder['change'] : change,
    'idRaider'       :  respDbCurrentOrder != null ? respDbCurrentOrder['idRaider'] : idRider,
    'receiptPrinted' :  respDbCurrentOrder != null ? respDbCurrentOrder['receiptPrinted'] : receiptPrinted,
  }; 

  static Future<bool> addOrderInDb ( BuildContext context ) async {
    bool success = true;
    try{
      final db   = await LocalDB.instance();
      
      final carrello   = context.read<CarrelloController>();
      OrdineTipo tipo_ =  carrello.tipoOrdine == 'delivery' ? OrdineTipo.consegna  : carrello.tipoOrdine == 'takeAway' ? OrdineTipo.ritiro  : OrdineTipo.mangiaQui;
      Map<String,dynamic> order = Ordine(
                            nomeCliente: carrello.nomeClienteOrdine,
                            paid: carrello.orderPaid,
                            cliente: carrello.cliente, 
                            tipo: tipo_,  
                            stato: OrdineStato.nuovo, 
                            data: carrello.dataOrdine ?? DateTime.now(), 
                            articles: carrello.prodotti,
                            indirizzo: carrello.addressOrder,
                            note: carrello.note,
                            telefono: carrello.phoneNumber ,
                            callerPager: carrello.callerPager,
                            idRider: carrello.rider != null ? carrello.rider!.id : null,
                            change: carrello.chargeRider,
                            receiptPrinted: 0
                          ).forDb();
    debugPrint(order.toString());
    final resp = await db.insert('orders', order);
    debugPrint(resp.toString());
    }catch( err ){
      success = false;
      debugPrint(err.toString());
    }finally{
      return success; 
    }
  }


    static Future<bool> updateOrderInDb ( BuildContext context ) async {
    bool success = true;
    try{
      
      final carrello   = context.read<CarrelloController>();
      final respCurrentOrder = await LocalDB.query('SELECT * FROM orders WHERE id = ${carrello.orderinEdit}');
      OrdineTipo tipo_ =  carrello.tipoOrdine == 'delivery' ? OrdineTipo.consegna  : carrello.tipoOrdine == 'takeAway' ? OrdineTipo.ritiro  : OrdineTipo.mangiaQui;

      Map<String,dynamic> order = Ordine(
                            nomeCliente: carrello.nomeClienteOrdine,
                            paid: carrello.orderPaid,
                            cliente: carrello.cliente ?? null, 
                            tipo: tipo_, 
                            stato: OrdineStato.nuovo, 
                            data: carrello.dataOrdine ?? DateTime.now(), 
                            articles: carrello.prodotti,
                            indirizzo: carrello.addressOrder,
                            note: carrello.note,
                            telefono: carrello.phoneNumber , 
                            callerPager: carrello.callerPager,
                            idRider: carrello.rider != null ? carrello.rider!.id : null,
                            change:  carrello.chargeRider,
                            receiptPrinted: carrello.orderPaid
                          ).forDb(respDbCurrentOrder: respCurrentOrder.isEmpty ? null : respCurrentOrder[0]);
    debugPrint(order.toString());
    final db   = await LocalDB.instance();
    final resp = await db.update('orders', order,where: 'id = ?', whereArgs: [carrello.orderinEdit]);
    debugPrint(resp.toString());
    }catch( err ){
      success = false;
      debugPrint(err.toString());
    }finally{
      return success; 
    }
  }


  static Future<bool> changeStatus ( int orderId, String newStatus ) async {
      bool success = true;
      try{
        String query = """UPDATE orders SET 
                          stato = '$newStatus', 
                          lastUpdate = ${DateTime.now().millisecondsSinceEpoch}
                        WHERE id = $orderId""";

        final resp   = await LocalDB.query(query);
        debugPrint(resp.toString());
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success; 
      }
  }

  static Future<bool> changePaid ( int orderId, int paid ) async {  
    bool success = true;
    try{
      String query = """UPDATE orders SET 
                        paid = $paid, 
                        lastUpdate = ${DateTime.now().millisecondsSinceEpoch}
                      WHERE id = $orderId""";

      final resp   = await LocalDB.query(query);
      debugPrint(resp.toString());
    }catch( err ){
      success = false;
      debugPrint(err.toString());
    }finally{
      return success; 
    }
  }

  static Future<bool> uploadChange( double v, int orderId ) async {
    bool success = true;
    try{
      String query = """UPDATE orders SET 
                        change = $v, 
                        lastUpdate = ${DateTime.now().millisecondsSinceEpoch}
                      WHERE id = $orderId""";

      final resp   = await LocalDB.query(query);
      debugPrint(resp.toString());
    }catch( err ){
      success = false;
      debugPrint(err.toString());
    }finally{
      return success; 
    }
  }

  static Future<bool> uploadReceiptToPrinted(  int orderId ) async {
    bool success = true;
    try{
      String query = """UPDATE orders SET 
                        receiptPrinted = 1, 
                        lastUpdate = ${DateTime.now().millisecondsSinceEpoch}
                      WHERE id = $orderId""";

      final resp   = await LocalDB.query(query);
      debugPrint(resp.toString());
    }catch( err ){
      success = false;
      debugPrint(err.toString());
    }finally{
      return success; 
    }
  }


  static Future<bool> uploadRider( int? idRaider, int orderId ) async {
    bool success = true;
    try{
      String query = """UPDATE orders SET 
                        idRaider = $idRaider, 
                        lastUpdate = ${DateTime.now().millisecondsSinceEpoch}
                      WHERE id = $orderId""";

      final resp   = await LocalDB.query(query);
      debugPrint(resp.toString());
    }catch( err ){
      success = false;
      debugPrint(err.toString());
    }finally{
      return success; 
    }
  }


  
  static Future<bool> delete ( int orderId ) async {
      bool success = true;
      try{
        final db   = await LocalDB.instance();
        final respdb = await db.delete('orders', where: 'id = ?', whereArgs: [orderId]);
        debugPrint(respdb.toString());
      }catch( err ){
        success = false;
        debugPrint(err.toString());
      }finally{
        return success; 
      }
  }


  static Future<List<Ordine>> getAllOrder ( ) async {
    List<Ordine> orders = [];

    try{
    final respDb = await LocalDB.query('SELECT * FROM orders');
    orders = respDb.map((ordDb) {
      CustomerModel? cliente        = ordDb['cliente'] == null ? null : CustomerModel.fromJson(jsonDecode(ordDb['cliente']));
      OrdineTipo tipo               = typeOrderFromString(ordDb['tipo']);
      OrdineStato stato             = typeStateOrderFromString(ordDb['stato']);
      List<dynamic> articlesInOrder = jsonDecode(ordDb['articles']);
      articlesInOrder.forEach((p) {
        p['article']         = ArticleWhitPriceListModel.fromJson(p['article']);
        p['variationsMinus'] = (p['variationsMinus'] as List).map((v) {
          v['article'] = ArticleWhitPriceListModel.fromJson(v['article']);
          return ProdottoCarrello.fromJson(v);
        }).toList(); 
        p['variationsPlus']  = (p['variationsPlus']  as List).map((v){ 
          v['article'] = ArticleWhitPriceListModel.fromJson(v['article']);
          return ProdottoCarrello.fromJson(v);
        }).toList();
        p['variationsInfo']  = (p['variationsInfo']  as List).map((v){
          v['article'] = ArticleWhitPriceListModel.fromJson(v['article']);
          return ProdottoCarrello.fromJson(v);
        }).toList();
        p['variationsFree']  = (p['variationsFree']  as List).map((v) {
          v['article'] = ArticleWhitPriceListModel.fromJson(v['article']);
          return ProdottoCarrello.fromJson(v);}).toList();
      });
      List<ProdottoCarrello> articles = articlesInOrder.map((a) => ProdottoCarrello.fromJson(a),).toList();
      return Ordine( 
                      nomeCliente: ordDb['nomeCliente'],
                      id:ordDb['id'],
                      paid: ordDb['paid'],
                      cliente:cliente, 
                      tipo: tipo, 
                      stato: stato, 
                      data: DateTime.parse(ordDb['data']),
                      articles: articles,
                      callerPager: ordDb['callerPager'],
                      indirizzo: ordDb['indirizzo'],
                      note: ordDb['note'],
                      telefono: ordDb['telefono'],
                      idRider: ordDb['idRaider'],
                      change:  ordDb['change'],
                      receiptPrinted: ordDb['receiptPrinted']
                    );
    } ).toList();
    debugPrint(orders.toString()); 
    }catch( err ){
      orders = [];
      debugPrint(err.toString());
    }finally{
      return orders; 
    }
  }
}

import 'dart:convert';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/state/controller_carrello.dart';

class CartModelSaledSuspended {
  int?           id;
  final String         title;
  final List<ProdottoCarrello> products;
  final String         note;
  final CustomerModel? customer;
  final String         createAt;
  final String         total;


  CartModelSaledSuspended({
    this.id,
    required this.title,
    required this.products,
    required this.note,
    this.customer,
    required this.createAt,
    required this.total
  });

  void setId (int id_ ){
    id = id_;
  }

  factory CartModelSaledSuspended.fromJson( Map<String,dynamic> json ){
    List products = ( jsonDecode( json['products'] ) as List);
    products.forEach((p) => p['article'] = ArticleWhitPriceListModel.fromJson(p['article']) );

    return(
      CartModelSaledSuspended(
        id      : json['id'] as int?,
        title   : json['title'] as String,
        createAt: json['createAt'] as String,
        note:     json['note'] as String,
        products: products.map((p) => ProdottoCarrello.fromJson(p) ).toList(),
        total:    json['total'] as String,
        customer: json['customer'] != null ? CustomerModel.fromJson( jsonDecode( json['customer']) ) : null
      )
    );
  }

  factory CartModelSaledSuspended.fromCartController( CarrelloController ctrl , String title_  ){
    return(
      CartModelSaledSuspended(
        title    : title_ ,
        createAt : DateTime.now().toIso8601String(),
        note     : ctrl.note,
        products : ctrl.prodotti,
        total    : ctrl.totaleCarrello.toString(),
        customer : ctrl.cliente
      )
    );
  }

  Map<String, dynamic> toMapForDb (){
    return {
      "id": id,
      "title" : title,
      "products": jsonEncode( products.map((p)=> p.toJsonEncodable()).toList() ),
      "note": note,
      "total": total,
      "createAt": createAt,
      "customer": customer != null ? jsonEncode(customer!.toMap()) : null,
    };
  }

  void suspendedInCart ( CarrelloController ctrCart ){
    ctrCart.clearCart();
    ctrCart.cartSuspended = this;
    ctrCart.addArticlesFromOrderInEdit(products);
    ctrCart.setNote(note);
    ctrCart.setCliente(customer);
    ctrCart.notifyListeners();
  }

}
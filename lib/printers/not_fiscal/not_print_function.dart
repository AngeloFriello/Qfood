import 'dart:convert';

import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/printers/not_fiscal/esc_pos.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int  maxChars = 42;
String formatRigaPreconto(
  String descrizione,
  String quantita,
  String prezzoRiga,
) {
   // 80 mm font A
  final String totale = prezzoRiga;

  final String quantitaStr = '${double.parse(quantita).toStringAsFixed(0) } '.padRight(6, ' ');

  final String left = '$quantitaStr$descrizione'.trim();

  // Limita la parte sinistra
  final String truncatedLeft   = left.length > 38 ? '${left.substring(0, 38 - 1)}.' : left;

  // Formatta il prezzo con 2 decimali
  final String right = totale;

  // Costruisci la riga: sinistra + spazi + destra
  final int padding   = maxChars - truncatedLeft.length - right.length;
  final String spaces = ' ' * padding.clamp(0, 99);

  return '$truncatedLeft$spaces$right\n';
}


String formatRigaPrecontoVariante(
  String descrizione,
  String prezzoRiga,
  String type
) {
  String sign = type == 'free' ? '+ ' : type == 'minus' ? '- ' : type == 'plus' ? '+ ' : type == 'info' ? '+ ' : '';
  String paddingLeft = '        ';
  return paddingLeft+sign+descrizione;
}

Future<List<String>> getHeadReceipt () async {
  try{
    SharedPreferences pref = await SharedPreferences.getInstance();
    final storeString = pref.getString('store');
    final companyString = pref.getString('company');
    if( storeString != null && companyString != null ){
      final store   = jsonDecode(storeString);
      final company = jsonDecode(companyString);

      String nameStore        = store['title'] ?? '';
      String businessName     = company['title'] ?? '';
      String address          = store['detail']['address'] ?? '';
      String zipCode          = store['detail']['zipCode']    ?? company['detail']['zipCode']    ?? '---';
      String collective       = store['detail']['collective'] ?? company['detail']['collective'] ?? '---';
      String province         = store['detail']['province']   ?? company['detail']['province']   ?? '---';
      String vatNumber        = company['detail']['vatNumber'] ?? '---';
      
      return [nameStore,businessName,address,(zipCode+' '+collective+'($province)'),('P.IVA '+vatNumber)];
    } 

    return [''];
  }catch(err){
    debugPrint(err.toString());
    return [''];
  }
}
  


Future<bool> printNotFiscalEscPos( BuildContext context , Ordine? ordine ) async {
  try{
      final controllerCart = context.read<CarrelloController>();
      if( controllerCart.prodotti.isEmpty && ordine != null && ordine.articles.isEmpty ) return false;
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? devicePref = pref.getString('device');
      if( devicePref == null ) return false;
      Map device = jsonDecode(devicePref);

      String? host       = device['noFiscalPrinterIpv4'];
      int? port          = device['noFiscalPrinterPort'];
      List<String> lines = [];
      List<String> linesHead = await getHeadReceipt();

      if( host != null && port != null  ){
        (ordine == null ? controllerCart.prodotti : ordine.articles).forEach((art)  {
          List<ProdottoCarrello> vars = [
                                          ...art.variationsFree,
                                          ...art.variationsInfo,
                                          ...art.variationsMinus,
                                          ...art.variationsPlus
                                        ];

          lines.add(formatRigaPreconto(art.article.title,art.quantity.toString(),art.priceRowWithVariant.toStringAsFixed(2)));
          if( vars.isNotEmpty ){
            vars.forEach((var_) => lines.add(formatRigaPrecontoVariante(var_.article.title, var_.priceRowCart.toStringAsFixed(2), var_.variationType ?? '' )));
          }
        } );
      }
     final respPrintNotFiscal = await EscPos().printReceipt( host! , port!,linesHead, lines, controllerCart);
     return respPrintNotFiscal;
  }catch( err ){
    debugPrint( err.toString());
    return false;
  }
} 
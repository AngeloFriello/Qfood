import 'dart:convert';
import 'dart:io';
import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/turno_server.dart';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:dashboard/config/costanti.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine_tipo.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../state/controller_carrello.dart';

class ScontrinoService {

  static Future<bool>   sendPrint ( Documento doc ) async {
    bool success = true;
    try{
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");
    
      final url = "https://$istanza-api.qfood.it/api/v1/pos/storeTransaction/a142c96c915a";
      Map<String, dynamic> body = doc.toJsonForSendBackoffice();
      final res = await http.post(
        Uri.parse(url),
        headers: {
          "X-API-KEY": posApiKey,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode != 201) {
        success = false;
      }
      final json = jsonDecode(res.body);
      if( json['success'] ){
          int idBackoffice = json['data']['queueResponse']['idDocument'];
          int docNumber    = json['data']['queueResponse']['assignedDocumentNumber'];
          
          // ASSEGNO L id del backoffice e il numero di documento assegnato
          await LocalDB.query("""UPDATE documents 
                                SET idReal = $idBackoffice, 
                                    assignedDocumentNumber = $docNumber 
                                WHERE id = ${doc.id}""");
          //SALVO LOG MOTIVO SCONTO                      
          if( (doc.discountReason ?? '').length > 0){
            LogService.instance().saveLog('Sconto doc. ${docNumber}', doc.discountReason ?? '', 'Documento: ${docNumber}');
          }
          
      }else{
        debugPrint('errore salvataggio documento in backoffice');
      }
    }catch( err ){
      success = false;
      debugPrint(err.toString());
    }finally{

      return success;
    }
  }

  static Future<void> archiveCancelReceiptInLocalDb(  Documento doc, String? overrideMovementType , { String? receiptNumber, String? closureReceipt }) async {
    try{
      final prefs   = await SharedPreferences.getInstance();
      Map device    = jsonDecode(prefs.getString('device') ?? '{}');
      List<ProdottoCarrello> listProducts = []; 
      String platform = Platform.operatingSystem;
      String currentDateToIso = DateTime.now().toUtc().toIso8601String();

      //Preparo il carrello con i rowguid
      doc.copyCart.forEach((p) {
        listProducts.add(p);
        p.setUuid(Uuid().v4());
        [...p.variationsFree, ...p.variationsInfo, ...p.variationsMinus, ...p.variationsPlus ].forEach((variant) {
          ProdottoCarrello temp    = variant;
          variant.rowGuidReference = p.uuid;
          listProducts.add(temp);
        });
      });

      final total          = doc.amount;
      final totalTaxable   = doc.amountTaxable;
      final totalTax       = totalTaxable;
      Map<String, dynamic> body = {
                                  "title":    currentDateToIso,
                                  "realDate": currentDateToIso,
                                  "jobDate":  currentDateToIso,
                                  "documentRtNumber": receiptNumber,
                                  "documentRtCloseNumber": closureReceipt,
                                  "amount": total,
                                  "amountTaxable":totalTaxable,
                                  "amountTax": totalTax,
                                  "amountRt": total, //Da valutare con antonio
                                  "receiptRounding": 0,
                                  "tips": doc.tips,
                                  "remainder": doc.remainder, //RESTO AL CLIENTE
                                  "platform": platform,
                                  "printed": 1,
                                  "printedAt": DateTime.now().toIso8601String(),
                                  "idDevice": device['id'],
                                  "idOperator": operatorLogged!.id,
                                  "idCustomer": doc.idCustomer,
                                  "lines": listProducts.map((prodCart) =>   {
                                                                                  "rowGuid"    : prodCart.uuid,
                                                                                  "idArticle"  : prodCart.article.id,
                                                                                  "title"      : prodCart.article.title,
                                                                                  "price"      : prodCart.priceRowCart / prodCart.quantity,
                                                                                  "quantity"   : prodCart.quantity,
                                                                                  "idVatRate"  : prodCart.article.idVatRate,
                                                                                  "rowGuidReference": prodCart.rowGuidReference ?? null
                                                                                } ).toList(), 
                                  "payments":     doc.payments.map((p) => p.toJson()).toList(),
                                  "footDiscount": doc.footDiscount,
                                  "idRateFootDiscount": doc.idRateFootDiscount, //SE ESISTE UNO SCONTO GLI APPLICO L'IVA PIU BASSA
                                  "overrideMovementType": 'cancel_rt',
                                  "idDocumentReference": doc.id,
                                  "copyCart": doc.copyCart,
                                  "idTable" : doc.idTable,
                                  "deleteNumber": [doc.documentRtNumber, doc.documentRtCloseNumber].join('/')
                                };


      final db   = await LocalDB.instance();
      final resp = await db.insert('documents', Documento.fromJson(body).toJson());
      final respUpdateDeletedDocument = await LocalDB.query("UPDATE documents SET deletedBy = '${[receiptNumber,closureReceipt].join('/')}' WHERE id = ${doc.id}");
      debugPrint(resp.toString());
    }catch( err ){
      debugPrint(err.toString());
    }finally{

    }
  }


  static Future<void> archiveCreditNoteLocalDb(  Documento doc ) async {
    try{
      final prefs   = await SharedPreferences.getInstance();
      Map device    = jsonDecode(prefs.getString('device') ?? '{}');
      List<ProdottoCarrello> listProducts = []; 
      String platform = Platform.operatingSystem;
      String currentDateToIso = DateTime.now().toUtc().toIso8601String();

      //Preparo il carrello con i rowguid
      doc.copyCart.forEach((p) {
        listProducts.add(p);
        p.setUuid(Uuid().v4());
        [...p.variationsFree, ...p.variationsInfo, ...p.variationsMinus, ...p.variationsPlus ].forEach((variant) {
          ProdottoCarrello temp    = variant;
          variant.rowGuidReference = p.uuid;
          listProducts.add(temp);
        });
      });

      final total          = doc.amount;
      final totalTaxable   = doc.amountTaxable;
      final totalTax       = totalTaxable;
      Map<String, dynamic> body = {
                                  "title":    currentDateToIso,
                                  "realDate": currentDateToIso,
                                  "jobDate":  currentDateToIso,
                                  "documentRtNumber": null,
                                  "documentRtCloseNumber": null,
                                  "amount": total,
                                  "amountTaxable":totalTaxable,
                                  "amountTax": totalTax,
                                  "amountRt": total, //Da valutare con antonio
                                  "receiptRounding": 0,
                                  "tips": doc.tips,
                                  "remainder": doc.remainder, //RESTO AL CLIENTE
                                  "platform": platform,
                                  "printed": 1,
                                  "printedAt": DateTime.now().toIso8601String(),
                                  "idDevice": device['id'],
                                  "idOperator": operatorLogged!.id,
                                  "idCustomer": doc.idCustomer,
                                  "lines": listProducts.map((prodCart) =>   {
                                                                                  "rowGuid"    : prodCart.uuid,
                                                                                  "idArticle"  : prodCart.article.id,
                                                                                  "title"      : prodCart.article.title,
                                                                                  "price"      : prodCart.priceRowCart / prodCart.quantity,
                                                                                  "quantity"   : prodCart.quantity,
                                                                                  "idVatRate"  : prodCart.article.idVatRate,
                                                                                  "rowGuidReference": prodCart.rowGuidReference ?? null
                                                                                } ).toList(), 
                                  "payments":     doc.payments.map((p) => p.toJson()).toList(),
                                  "footDiscount":       doc.footDiscount,
                                  "idRateFootDiscount": doc.idRateFootDiscount, //SE ESISTE UNO SCONTO GLI APPLICO L'IVA PIU BASSA
                                  "overrideMovementType": 'credit_note',
                                  "idDocumentReference": doc.id,
                                  "copyCart": doc.copyCart,
                                  "idTable" : doc.idTable,
                                  "deleteNumber": doc.id.toString(),
                                  "credit_note_exclude_total_report": doc.credit_note_exclude_total_report
                                };


      final db   = await LocalDB.instance();
      final resp = await db.insert('documents', Documento.fromJson(body).toJson());
      final respUpdateDeletedDocument = await LocalDB.query("UPDATE documents SET deletedBy = '${resp.toString()}' WHERE id = ${doc.id}");
      debugPrint(resp.toString());
    }catch( err ){
      debugPrint(err.toString());
    }finally{
      SnackBarForcedClosure('Nota di credito salvata', Colors.green);
    }
  }
  


  static Future<bool> archiveDocumentInLocalDb(  CarrelloController ctrCart, String? overrideMovementType ,  { String? receiptNumber, String? closureReceipt, bool? notCleanCart} ) async {
    bool success = true;
    String? uuid_turno;
    
    uuid_turno = await getUuidUltimoTurnoAperto();
    try{
      final prefs   = await SharedPreferences.getInstance();
      Map device    = jsonDecode(prefs.getString('device') ?? '{}');
      List<ProdottoCarrello> listProducts = []; 
      String platform = Platform.operatingSystem;
      String currentDateToIso = DateTime.now().toUtc().toIso8601String();

      //Preparo il carrello con i rowguid
      ctrCart.prodotti.forEach((p) {
        listProducts.add(p);
        [...p.variationsFree, ...p.variationsInfo, ...p.variationsMinus, ...p.variationsPlus ].forEach((variant) {
          ProdottoCarrello temp    = variant;
          variant.rowGuidReference = p.uuid;
          listProducts.add(temp);
        });
      });

      final total          = ctrCart.totaleCarrello - ctrCart.discount;
      final totalTaxable   = (ctrCart.totaleCarrelloImponibile - ctrCart.discountTaxable);
      final totalTax       = (ctrCart.totaleCarrello - ctrCart.totaleCarrelloImponibile) + (ctrCart.discount - ctrCart.discountTaxable);
      List<Payment>   payments__  = [ ...ctrCart.getPayments ];
      if( overrideMovementType == 'simulation' && payments__.isNotEmpty ){
        payments__[0] = Payment(title: payments__.first.title, idPayment: payments__.first.idPayment, amount: payments__.first.amount + (ctrCart.tips ?? 0 ), tend: payments__.first.tend);
      } 
      List< Map<String, dynamic>>  payments  = payments__.map((p) => p.toJson()).toList();
      List<Ordine> orders  = await  Ordine.getAllOrder();
      Ordine? order = orders.firstWhereOrNull((o) => o.id == ctrCart.orderinEdit );
      Map<String, dynamic> body = {
                                  "title":    currentDateToIso,
                                  "realDate": currentDateToIso,
                                  "jobDate":  currentDateToIso,
                                  "documentRtNumber": receiptNumber,
                                  "documentRtCloseNumber": closureReceipt,
                                  "amount": total,
                                  "amountTaxable":totalTaxable,
                                  "amountTax": totalTax,
                                  "amountRt": total, //Da valutare con antonio
                                  "receiptRounding": 0,
                                  "tips": ctrCart.tips,
                                  "remainder": ctrCart.remainder, //RESTO AL CLIENTE
                                  "platform": platform,
                                  "printed": 1,
                                  "printedAt": DateTime.now().toIso8601String(),
                                  "idDevice": device['id'],
                                  "idOperator": operatorLogged!.id,
                                  "idCustomer": (ctrCart.cliente?.id) ?? null,
                                  "lines": listProducts.map((prodCart) =>   {
                                                                                  "rowGuid"    : prodCart.uuid,
                                                                                  "idArticle"  : prodCart.article.id,
                                                                                  "title"      : prodCart.article.title,
                                                                                  "price"      : prodCart.priceRowCart / prodCart.quantity,
                                                                                  "quantity"   : prodCart.quantity,
                                                                                  "idVatRate"  : prodCart.article.idVatRate,
                                                                                  "rowGuidReference": prodCart.rowGuidReference ?? null
                                                                                } ).toList(), 
                                  "payments":     payments,
                                  "footDiscount": ctrCart.discount * -1,
                                  "idRateFootDiscount": ctrCart.discount > 0 ? ctrCart.discountIdVatRate : null, //SE ESISTE UNO SCONTRO GLI APPLICO L'IVA PIU BASSA
                                  "overrideMovementType": overrideMovementType,
                                  "idDocumentReference": null,
                                  "copyCart": ctrCart.prodotti,
                                  "idTable" : ctrCart.table != null ? ctrCart.table!.id : null,
                                  "discountReason"  : ctrCart.discountReason,
                                  "uuid_riga_turno" : uuid_turno,
                                  "deliveryService" : order != null ? labelTipoOrdine( order.tipo ) : null
                                };


      final db   = await LocalDB.instance();
      final resp = await db.insert('documents', Documento.fromJson(body).toJson());
      if( resp == 0 ) success = false;
      debugPrint(resp.toString());
    }catch( err ){
      debugPrint( err.toString() );
      success = false;
    }finally{
      if( success && notCleanCart != true ){
        ctrCart.clearCart();
      }

      return success;
    }
  }

  static Future<int> lastId () async {
    int id = 0;
    try{
      List< Map<String, dynamic> >  resp = await  LocalDB.query('select id from documents order by id desc limit 1');
      if( resp.isNotEmpty ) id = resp[0]['id'];
    }catch( err ){

    }finally{
      return id;
    }
  }


  static Future<int> archiveInvoiceDocumentInLocalDb(  CarrelloController ctrCart, String? overrideMovementType , { String? receiptNumber, String? closureReceipt, bool? notCleanCart}) async {
    int success = 0;

    try{
      final prefs   = await SharedPreferences.getInstance();
      Map device    = jsonDecode(prefs.getString('device') ?? '{}');
      List<ProdottoCarrello> listProducts = []; 
      String platform = Platform.operatingSystem;
      String currentDateToIso = DateTime.now().toUtc().toIso8601String();
      String? uuid_turno = await getUuidUltimoTurnoAperto();
      //Preparo il carrello con i rowguid
      ctrCart.prodotti.forEach((p) {
        listProducts.add(p);
        [...p.variationsFree, ...p.variationsInfo, ...p.variationsMinus, ...p.variationsPlus ].forEach((variant) {
          ProdottoCarrello temp    = variant;
          variant.rowGuidReference = p.uuid;
          listProducts.add(temp);
        });
      });

      final total          = ctrCart.totaleCarrello - ctrCart.discount;
      final totalTaxable   = (ctrCart.totaleCarrelloImponibile - ctrCart.discountTaxable);
      final totalTax       = (ctrCart.totaleCarrello - ctrCart.totaleCarrelloImponibile) + (ctrCart.discount - ctrCart.discountTaxable);
      Map<String, dynamic> body = {
                                  "title":    currentDateToIso,
                                  "realDate": currentDateToIso,
                                  "jobDate":  currentDateToIso,
                                  "documentRtNumber": receiptNumber,
                                  "documentRtCloseNumber": closureReceipt,
                                  "amount": total,
                                  "amountTaxable":totalTaxable,
                                  "amountTax": totalTax,
                                  "amountRt": total, //Da valutare con antonio
                                  "receiptRounding": 0,
                                  "tips": ctrCart.tips,
                                  "remainder": ctrCart.remainder, //RESTO AL CLIENTE
                                  "platform": platform,
                                  "printed": 1,
                                  "printedAt": DateTime.now().toIso8601String(),
                                  "idDevice": device['id'],
                                  "idOperator": operatorLogged!.id,
                                  "idCustomer": (ctrCart.cliente?.id) ?? null,
                                  "lines": listProducts.map((prodCart) =>   {
                                                                                  "rowGuid"    : prodCart.uuid,
                                                                                  "idArticle"  : prodCart.article.id,
                                                                                  "title"      : prodCart.article.title,
                                                                                  "price"      : prodCart.priceRowCart / prodCart.quantity,
                                                                                  "quantity"   : prodCart.quantity,
                                                                                  "idVatRate"  : prodCart.article.idVatRate,
                                                                                  "rowGuidReference": prodCart.rowGuidReference ?? null
                                                                                } ).toList(), 
                                  "payments":     ctrCart.getPayments.map((p) => p.toJson()).toList(),
                                  "footDiscount": ctrCart.discount * -1,
                                  "idRateFootDiscount": ctrCart.discount > 0 ? ctrCart.discountIdVatRate : null, //SE ESISTE UNO SCONTRO GLI APPLICO L'IVA PIU BASSA
                                  "overrideMovementType": overrideMovementType,
                                  "idDocumentReference": null,
                                  "copyCart": ctrCart.prodotti,
                                  "idTable" : ctrCart.table != null ? ctrCart.table!.id : null,
                                  "uuid_riga_turno" : uuid_turno,
                                };


      final db   = await LocalDB.instance();
      success = await db.insert('documents', Documento.fromJson(body).toJson());
    }catch( err ){
      debugPrint( err.toString() );
      success = 0;
    }finally{
      return success;
    }
  }

}

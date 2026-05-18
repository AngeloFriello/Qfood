import 'dart:convert';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/modelli/payment.dart';
import 'package:dashboard/printers/fiscal/fiscal_base.dart';
import 'package:dashboard/printers/fiscal/fiscal_custom.dart';
import 'package:dashboard/printers/fiscal/fiscal_epson.dart';
import 'package:dashboard/printers/fiscal/fiscal_factory.dart';
import 'package:dashboard/printers/fiscal/fiscal_model.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceReceipt {

  static ServiceReceipt? _instance;
  static ServiceReceipt instance () => _instance ??= ServiceReceipt();


  /// Apri cassetto
  Future<void> openDrawer() async {
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      Map<String,dynamic>                  device = jsonDecode(pref.getString('device') ?? '{}');
      String? fiscalPrinterModel           = device['fiscalPrinterModel'];
      String? fiscalPrinterIpv4            = device['fiscalPrinterIpv4'];
      String? fiscalPrinterSerialNumber    = device['fiscalPrinterSerialNumber'];
      if (device.isEmpty ||
          fiscalPrinterSerialNumber == null ||
          fiscalPrinterIpv4 == null ||
          fiscalPrinterModel == null) {
        return;
      }

      FiscalBase fiscalPrinter = 
        FiscalFactory.getFiscal(
          fiscalPrinterModel == 'epson' ? FiscalType.epson : FiscalType.custom, 
          fiscalPrinterIpv4, 
          fiscalPrinterSerialNumber, 
          10
        );

      fiscalPrinter.openDrawer();
      
    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{

    }
  }

  /// Chiusura fiscale
  Future<bool> fiscalClosure() async {
    bool resp_ = true;
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      Map<String,dynamic>                  device = jsonDecode(pref.getString('device') ?? '{}');
      String? fiscalPrinterModel           = device['fiscalPrinterModel'];
      String? fiscalPrinterIpv4            = device['fiscalPrinterIpv4'];
      String? fiscalPrinterSerialNumber    = device['fiscalPrinterSerialNumber'];
      if(device.isEmpty || fiscalPrinterSerialNumber == null || fiscalPrinterIpv4 == null || fiscalPrinterModel == null ){
        resp_ = false;
      }else{
        FiscalBase fiscalPrinter = 
        FiscalFactory.getFiscal(
          fiscalPrinterModel == 'epson' ? FiscalType.epson : FiscalType.custom, 
          fiscalPrinterIpv4, 
          fiscalPrinterSerialNumber, 
          10
        );

        resp_ = await fiscalPrinter.fiscalClosure();
      }
      
    }catch(e){
      if(kDebugMode){
        print(e);
      }
      resp_ = false;
    }finally{
      return resp_;
    }

  }
  /// annullo scontrino /// 
  Future<void> cancelReceipt( Documento receipt, Function(String number, String close) printed, Function(String cause) notPrinted ) async {
    String? e;
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      Map<String,dynamic>                  device = jsonDecode(pref.getString('device') ?? '{}');
      String? fiscalPrinterModel           = device['fiscalPrinterModel'];
      String? fiscalPrinterIpv4            = device['fiscalPrinterIpv4'];
      String? fiscalPrinterSerialNumber    = device['fiscalPrinterSerialNumber'];

      if( fiscalPrinterModel == 'epson' ){
        FiscalReceiptResponse resp = await FiscalEpson(ip: fiscalPrinterIpv4!, serialNumber: fiscalPrinterSerialNumber!, timeout: 20 ).cancelReceipt(fiscalPrinterSerialNumber!, receipt.documentRtNumber!, receipt.documentRtCloseNumber!, receipt.realDate);
        if( resp.fiscalClosure != null && resp.fiscalNumber != null ){
          printed(resp.fiscalNumber ?? '', resp.fiscalClosure ?? '');
        }else{
          e = "error";
        }
      }

      if( fiscalPrinterModel == 'custom' ){
        FiscalReceiptResponse resp = await FiscalCustom(ip: fiscalPrinterIpv4!, serialNumber: fiscalPrinterSerialNumber!, timeout: 20 ).cancelReceipt(fiscalPrinterSerialNumber!, receipt.documentRtNumber!, receipt.documentRtCloseNumber!, receipt.realDate);
        if( resp.fiscalClosure != null && resp.fiscalNumber != null ){
          printed(resp.fiscalNumber ?? '', resp.fiscalClosure ?? '');
        }else{
          e = "error";
        }
      }

    }catch( err ){
      e = "in_catch";
      if(kDebugMode){
        print(err);
      }
    }finally{
      if(e != null){
        notPrinted(e);
      }
    }
  }

  /// Stampa sontrino
  Future<void> printReceipt(BuildContext context, Function(String number, String close) printed, Function(String cause) notPrinted) async {
    CarrelloController cart = context.read<CarrelloController>();
    String? e;
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      Map<String,dynamic>                  device = jsonDecode(pref.getString('device') ?? '{}');
      String? fiscalPrinterModel           = device['fiscalPrinterModel'];
      String? fiscalPrinterIpv4            = device['fiscalPrinterIpv4'];
      String? fiscalPrinterSerialNumber    = device['fiscalPrinterSerialNumber'];
      if(device.isEmpty || fiscalPrinterSerialNumber == null || fiscalPrinterIpv4 == null || fiscalPrinterModel == null ){
        e = "device not found in SharedPreferences";
        return;
      }

      // Carrello vuoto
      if(cart.prodotti.isEmpty){
        e = "empty_cart";
        return;
      }

      FiscalBase fiscalPrinter = 
        FiscalFactory.getFiscal(
          fiscalPrinterModel == 'epson' ? FiscalType.epson : FiscalType.custom, 
          fiscalPrinterIpv4, 
          fiscalPrinterSerialNumber, 
          10
        );

      FiscalReceipt receipt = FiscalReceipt();
      receipt.lines         = [];
      receipt.payments      = [];
      receipt.discount      = cart.discount > 0 ? double.parse( (cart.discount).toStringAsFixed(2) ) : null;

      await Future.forEach(cart.prodotti, (product) async {

        int departmentNumber = 1;
        if(product.article.idVatRate != null){
          List<Map<String, dynamic>> dataDepartment = 
            await LocalDB.query(
              "SELECT IFNULL(departmentNumber, 1) departmentNumber FROM vatRates WHERE id = ${product.article.idVatRate}"
            );
          if(dataDepartment.isNotEmpty){
            departmentNumber = dataDepartment.first['departmentNumber'] ?? 1;
          }
        }

        receipt.lines.add(
          FiscalReceiptLine()
          ..departmentNumber  = departmentNumber 
          ..price             = product.unitPrice
          ..quantity          = int.parse(product.quantity.toStringAsFixed(0)) 
          ..title             = product.article.title
        );

      });
      
      PaymentModel? paymentCash = await PaymentModel.getCashPayment();
      if( paymentCash == null ) return;
      if(cart.getPayments.isEmpty){ // Metti contanti default
        receipt.payments.add(
          FiscalPayment()
          ..title = " Contanti"
          ..tend = 1
          ..subTend = 1
          ..amount = (cart.totaleCarrello ) - cart.discount
        );
        cart.addPayment(Payment(title: paymentCash.title, tend: paymentCash.tend ?? 1, idPayment: paymentCash.id, amount: ( cart.totaleCarrello ) - cart.discount));
      }else{
        cart.getPayments.forEach((payment){
          receipt.payments.add(
            FiscalPayment()
            ..title   = payment.title
            ..tend    = payment.tend
            ..subTend = payment.subTend ?? 1
            ..amount  = payment.amount
          );
        });
      }

      // Lancia scontrino
      FiscalReceiptResponse response = await fiscalPrinter.printReceipt(receipt);
      if(!response.success){
        e = "error_during_print";
        return;
      }

      // Scontrino stampato!
      printed(response.fiscalNumber ?? "0000", response.fiscalClosure ?? "0000");

    }catch(err){
      e = "in_catch";
      if(kDebugMode){
        print(err);
      }
    }finally{
      if(e != null){
        notPrinted(e);
      }
    }

  }


    /// Stampa sontrino
  Future<void> printInvoice(BuildContext context, Function(bool success) printed, Function(String cause) notPrinted) async {
    bool success = true;
    CarrelloController cart = context.read<CarrelloController>();
    String? e;
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      Map<String,dynamic>                  device = jsonDecode(pref.getString('device') ?? '{}');
      String? fiscalPrinterModel           = device['fiscalPrinterModel'];
      String? fiscalPrinterIpv4            = device['fiscalPrinterIpv4'];
      String? fiscalPrinterSerialNumber    = device['fiscalPrinterSerialNumber'];
      if(device.isEmpty || fiscalPrinterSerialNumber == null || fiscalPrinterIpv4 == null || fiscalPrinterModel == null ){
        e = "device not found in SharedPreferences";
        return;
      }

      // Carrello vuoto
      if(cart.prodotti.isEmpty){
        e = "empty_cart";
        return;
      }

      FiscalBase fiscalPrinter = 
        FiscalFactory.getFiscal(
          fiscalPrinterModel == 'epson' ? FiscalType.epson : FiscalType.custom, 
          fiscalPrinterIpv4, 
          fiscalPrinterSerialNumber, 
          10
        );
      
      
      fiscalPrinter.printNotFiscal([]);
      // Scontrino stampato!
      printed( success );

    }catch(err){
      e = "in_catch";
      if(kDebugMode){
        print(err);
      }
    }finally{
      if(e != null){
        notPrinted(e);
      }
    }

  }
}
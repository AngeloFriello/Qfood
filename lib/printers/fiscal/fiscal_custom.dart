import 'dart:convert';
import 'package:dashboard/printers/fiscal/fiscal_base.dart';
import 'package:dashboard/printers/fiscal/fiscal_mixin.dart';
import 'package:dashboard/printers/fiscal/fiscal_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class FiscalCustom extends FiscalBase with FiscalMixin {

  String ip;
  String serialNumber;
  int    timeout;

  FiscalCustom({required this.ip, required this.serialNumber, required this.timeout});

  @override
  Map<String, String> httpHeaders() {
    return 
      {
        'Content-Type'  : 'application/xml',
        'Accept'        : 'application/xml',
        'Authorization' : 'Basic ${base64.encode(utf8.encode("$serialNumber:$serialNumber"))}'
      };
  }

  /// Chiusura fiscale
  @override
  Future<bool> fiscalClosure() async {
    
    bool completed          = false;
    String payload          = "";
    String responsePrinter  = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'printerFiscalReport',
        nest: (){
          builder.element('printZReport');
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body;
      if(response.statusCode == 200){
        XmlDocument document = XmlDocument.parse(responsePrinter);
        completed = document.getElement("response")!.getAttribute("success") == "true";
      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

    return completed;
  }

  /// Lettura fiscale
  @override
  Future<bool> fiscalReading() async {
    
    bool completed          = false;
    String payload          = "";
    String responsePrinter  = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'printerFiscalReport',
        nest: (){
          builder.element('printXReport');
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body;
      if(response.statusCode == 200){
        XmlDocument document = XmlDocument.parse(responsePrinter);
        completed = document.getElement("response")!.getAttribute("success") == "true";
      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

    return completed;
  }

  /// Stato stampante fiscale
  @override
  Future<FiscalPrinterStatus> fiscalStatus() async {
    
    FiscalPrinterStatus status  = FiscalPrinterStatus.unknown;
    String payload              = "";
    String responsePrinter      = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'printerCommand',
        nest: (){
          builder.element('queryPrinterStatus');
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body;
      if(response.statusCode == 200){
        XmlDocument document = XmlDocument.parse(responsePrinter);
        String responseStatus = document.getElement("response")!.getElement("addInfo")!.getElement("printerStatus")!.innerText;
        switch(responseStatus){
          case "00000": {
            status = FiscalPrinterStatus.ready;
          } break;
          case "01100": {
            status = FiscalPrinterStatus.paperEnd;
          } break;
          case "00100": {
            status = FiscalPrinterStatus.paperEnding;
          } break;
          case "11000": { 
            status = FiscalPrinterStatus.coveredOpened;
          } break;
          case "11100": {
            status = FiscalPrinterStatus.receiptOpened;
          } break;
          case "01000": {
            status = FiscalPrinterStatus.paperError;
          } break;
        }
      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

    return status;
  }

  /// Stampa messaggio su display
  @override
  Future<void> displayMessageOnViewer(String message) async {

    String payload         = "";
    String responsePrinter = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'printerNotFiscal',
        nest: (){
          builder.element(
            'displayText',
            attributes: { "data": message } 
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body; // Non loggare, ha poco significato

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

  }

  /// Apri cassetto
  @override
  Future<void> openDrawer() async {
    
    String payload         = "";
    String responsePrinter = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'printerNotFiscal',
        nest: (){
          builder.element('openDrawer');
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body; // Non loggare, ha poco significato

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

  }

  /// Stampa scontrino
  @override
  Future<FiscalReceiptResponse> printReceipt(FiscalReceipt receipt) async {

    FiscalReceiptResponse   response        = FiscalReceiptResponse();
    String                  payload         = "";
    String                  responsePrinter = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element(
        'printerFiscalReceipt',
        nest: (){
                  
          builder.element('beginFiscalReceipt');

          for (FiscalReceiptLine line in receipt.lines) {
            builder.element(
              'printRecItem',
              attributes: {
                'description'     : line.title,
                'quantity'        : (line.quantity * 1000).toString(),
                'unitPrice'       : (line.price * 100).toString(),
                'department'      : line.departmentNumber.toString(),
                'idVat'           : '0'
              }
            );
          }

          if(receipt.discount != null){
            builder.element(
              'printRecSubtotalAdjustment',
              attributes: {
                'adjustmentType': '3',
                'description'   : 'SCONTO',
                'amount'        : receipt.discount!.toString(),
              }
            );
          }

          builder.element('printRecSubtotal');

          if(receipt.barcode != null){
            builder.element(
              'printBarCode',
              attributes: {
                'hRIPosition'   : '1',
                'codeType'      : '3',
                'barCodeHeight' : '9',
                'code'          : receipt.barcode!.padLeft(13, '0')
              }
            );
          }

          for(FiscalPayment payment in receipt.payments){
            builder.element(
              'printRecTotal',
              attributes: {
                'description' : payment.title,
                'payment'     : payment.amount.toString(),
                'paymentType' : payment.tend.toString(),
              }
            );
          }

          builder.element('endFiscalReceiptCut');

        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = responseReceipt.body;
      if(responseReceipt.statusCode == 200){

        XmlDocument document        = XmlDocument.parse(responsePrinter);
        XmlElement elementResponse  = document.getElement("response")!;

        if(elementResponse.getAttribute("success") == "true"){
          
          XmlElement infoElement  = elementResponse.getElement("addInfo")!;
          String fiscalNumber     = infoElement.getElement("fiscalDoc")!.innerText.padLeft(4, '0');
          String fiscalClosure    = infoElement.getElement("nClose")!.innerText.padLeft(4, '0');

          // Stampa completata
          // Numero chiusura e documento
          // devono essere salvati per annullo e reso
          response.success        = true;
          response.fiscalClosure  = fiscalClosure;
          response.fiscalNumber   = fiscalNumber; 

        }

      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

    return response;
  }

  /// Se reso disponibile
  Future<bool> isRefundAvailable(String serialNumber, String documentNumber, String documentClose, String enDate) async {

    bool isAvailable        = false;
    String payload          = "";
    String responsePrinter  = "";

    try{

      String customDate = enDate.split("-").reversed.join("").substring(0, 4) + enDate.substring(2, 4);

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element(
        'printerFiscalReceipt',
        nest: (){
          builder.element(
            'beginRtDocRefund',
            attributes: {
              'docRefZ'     : documentClose,
              'docRefNumber': documentNumber,
              'docDate'     : customDate
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = responseReceipt.body;
      if(responseReceipt.statusCode == 200){

        XmlDocument document        = XmlDocument.parse(responsePrinter);
        XmlElement elementResponse  = document.getElement("response")!;

        if(elementResponse.getAttribute("success") == "true"){
          isAvailable = true;
        }

      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

    return isAvailable;
  }   

  /// Reso scontrino
  @override
  Future<FiscalReceiptResponse> refundReceipt(FiscalReceipt receipt, String serialNumber, String documentNumber, String documentClose, String enDate) async {


    FiscalReceiptResponse   response        = FiscalReceiptResponse();
    String                  payload         = "";
    String                  responsePrinter = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element(
        'printerFiscalReceipt',
        nest: (){

          for (FiscalReceiptLine line in receipt.lines) {
            builder.element(
              'printRecItem',
              attributes: {
                'description'     : line.title,
                'quantity'        : (line.quantity * 1000).toString(),
                'unitPrice'       : (line.price * 100).toString(),
                'department'      : line.departmentNumber.toString(),
                'idVat'           : '0'
              }
            );
          }

          builder.element('endFiscalReceiptCut');

        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      // Lancia prima check reso, se disponibile!
      if(!await isRefundAvailable(serialNumber, documentNumber, documentClose, enDate)){
        throw new ErrorDescription("refund_not_available");
      }

      // Ok, trovato. Stampa lo scontrino di reso!

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = responseReceipt.body;
      if(responseReceipt.statusCode == 200){

        XmlDocument document        = XmlDocument.parse(responsePrinter);
        XmlElement elementResponse  = document.getElement("response")!;

        if(elementResponse.getAttribute("success") == "true"){
          
          XmlElement infoElement  = elementResponse.getElement("addInfo")!;
          String fiscalNumber     = infoElement.getElement("nClose")!.innerText.padLeft(4, '0');
          String fiscalClosure    = infoElement.getElement("fiscalDoc")!.innerText.padLeft(4, '0');

          // Stampa completata
          // Numero chiusura e documento
          // devono essere salvati per annullo e reso
          response.success        = true;
          response.fiscalClosure  = fiscalClosure;
          response.fiscalNumber   = fiscalNumber; 

        }

      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

    return response;
  }

  /// Annullo scontrino
  @override
  Future<FiscalReceiptResponse> cancelReceipt(String serialNumber, String documentNumber, String documentClose, String enDate) async {

    FiscalReceiptResponse   response        = FiscalReceiptResponse();
    String                  payload         = "";
    String                  responsePrinter = "";

    try{
      
      String y = enDate.split("T")[0].split('-').reversed.toList().last.substring(2);
      String customDate = enDate.split("T")[0].split('-').reversed.toList().join('').substring(0,4) + y;

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'printerFiscalReceipt',
        nest: (){
          builder.element(
            'beginRtDocAnnulment',
            attributes: {
              'docRefZ'     : documentClose.toString().padLeft(4, '0'),
              'docRefNumber': documentNumber.toString().padLeft(4, '0'),
              'docDate'     : customDate
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = responseReceipt.body;
      if(responseReceipt.statusCode == 200){

        XmlDocument document        = XmlDocument.parse(responsePrinter);
        XmlElement elementResponse  = document.getElement("response")!;

        if(elementResponse.getAttribute("success") == "true"){
          
          XmlElement infoElement  = elementResponse.getElement("addInfo")!;
          String fiscalNumber     = infoElement.getElement("nClose")!.innerText.padLeft(4, '0');
          String fiscalClosure    = infoElement.getElement("fiscalDoc")!.innerText.padLeft(4, '0');

          // Stampa completata
          // Numero chiusura e documento
          // devono essere salvati per annullo e reso
          response.success        = true;
          response.fiscalClosure  = fiscalClosure;
          response.fiscalNumber   = fiscalNumber; 

        }

      }

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

    return response;
  }

  /// Stampa scontrino non fiscale
  @override
  Future<void> printNotFiscal(List<String> lines) async {
    
    String payload          = "";
    String responsePrinter  = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element(
        'printerNotFiscal',
        nest: (){
          builder.element('beginNotFiscal');
          builder.element('printNotFiscalHeader');
          lines.forEach((line){
            builder.element(
              'printNormal',
              attributes: {
                'font': '2',
                'data': line
              }
            );
          });
          builder.element('endNotFiscal');
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'xml/printer.htm'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = responseReceipt.body;

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

  }

}
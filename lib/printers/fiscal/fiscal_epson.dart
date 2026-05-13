import 'package:dashboard/printers/fiscal/fiscal_base.dart';
import 'package:dashboard/printers/fiscal/fiscal_mixin.dart';
import 'package:dashboard/printers/fiscal/fiscal_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

class FiscalEpson extends FiscalBase with FiscalMixin {

  String ip;
  String serialNumber;
  int    timeout;

  FiscalEpson({required this.ip, required this.serialNumber, required this.timeout});

  @override
  Map<String, String> httpHeaders() {
    return {
      "Content-Type"      : "text/xml; charset=UTF-8",
      "If-Modified-Since" : "Thu, 01 Jan 1970 00:00:00 GMT",
      "SOAPAction"        : '""'
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
        'soapenv:Envelope',
        attributes: { "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/" },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerFiscalReport',
                nest: (){
                  builder.element(
                    'printZReport', 
                    attributes: { "Ope": "1" }
                  );
                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
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
        completed = document.getElement("soapenv:Envelope")!.getElement("soapenv:Body")!.getElement("response")!.getAttribute("success") == "true";
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
        'soapenv:Envelope',
        attributes: { "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/" },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerFiscalReport',
                nest: (){
                  builder.element(
                    'printXReport', 
                    attributes: { "Ope": "1" }
                  );
                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
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
        completed = document.getElement("soapenv:Envelope")!.getElement("soapenv:Body")!.getElement("response")!.getAttribute("success") == "true";
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
        'soapenv:Envelope',
        attributes: { "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/" },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerCommand',
                nest: (){
                  builder.element(
                    'queryPrinterStatus', 
                    attributes: { "operator": "1", "statusType": '0' }
                  );
                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
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
        String responseStatus = document.getElement("soapenv:Envelope")!.getElement("soapenv:Body")!.getElement("response")!.getElement("addInfo")!.getElement("fpStatus")!.innerText;
        status = responseStatus == "00110" ? FiscalPrinterStatus.ready : FiscalPrinterStatus.inError;
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

  /// Mostra messaggio visore
  @override
  Future<void> displayMessageOnViewer(String message) async {

    String payload          = "";
    String responsePrinter  = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'soapenv:Envelope',
        attributes: { "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/" },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerTicket',
                nest: (){
                  builder.element(
                    'displayText', 
                    attributes: { "operator": "1", "data": message }
                  );
                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body; // Non loggare superfluo

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

    String payload          = "";
    String responsePrinter  = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');

      builder.element(
        'soapenv:Envelope',
        attributes: { "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/" },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerTicket',
                nest: (){
                  builder.element(
                    'openDrawer', 
                    attributes: { "operator": "1" }
                  );
                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body; // Non loggare superfluo

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

    FiscalReceiptResponse   response          = FiscalReceiptResponse();
    String                  payload           = "";
    String                  responsePrinter   = "";

    try{

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element(
        'soapenv:Envelope',
        attributes: {
          'xmlns:soapenv': 'http://schemas.xmlsoap.org/soap/envelope/'
        },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerFiscalReceipt',
                nest: (){
                  
                  builder.element(
                    'beginFiscalReceipt',
                    attributes: {
                      'Ope': "1"
                    }
                  );

                  for (FiscalReceiptLine line in receipt.lines) {
                    builder.element(
                      'printRecItem',
                      attributes: {
                        'Text'    : line.title,
                        'Qty'     : line.quantity.toString(),
                        'UnitCost': line.price.toString(),
                        'Dep'     : line.departmentNumber.toString(),
                        'Just'    : '1'
                      }
                    );
                  }

                  if(receipt.discount != null){
                    builder.element(
                      'printRecSubtotalAdjustment',
                      attributes: {
                        'Type'    : '1',
                        'Text'    : 'SCONTO',
                        'Amount'  : receipt.discount!.toString(),
                        'Dep'     : '1',
                        'Ope'     : '3',
                        'Just'    : '1'
                      }
                    );
                  }

                  builder.element(
                    'printRecSubtotal',
                    attributes: {
                      'Ope': "1",
                      'Type': '0'
                    }
                  );

                  if(receipt.barcode != null){
                    builder.element(
                      'printBarCode',
                      attributes: {
                        'operator'    : '1',
                        'position'    : '901',
                        'width'       : '2',
                        'height'      : '66',
                        'hRIPosition' : '3',
                        'hRIFont'     : 'C',
                        'codeType'    : 'CODE39',
                        'code'        : receipt.barcode!.padLeft(13, '0')
                      }
                    );
                  }

                  for(FiscalPayment payment in receipt.payments){
                    builder.element(
                      'printRecTotal',
                      attributes: {
                        'Ope'     : '1',
                        'Text'    : payment.title,
                        'Amount'  : payment.amount.toString(),
                        'Type'    : payment.tend.toString(),
                        'Index'   : (payment.subTend ?? 1).toString()
                      }
                    );
                  }

                  builder.element(
                    'endFiscalReceipt',
                    attributes: {
                      'Ope': "1"
                    }
                  );

                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
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
        XmlElement elementResponse  = document.getElement("soapenv:Envelope")!.getElement("soapenv:Body")!.getElement("response")!;

        if(elementResponse.getAttribute("success") == "true"){
          
          XmlElement infoElement  = elementResponse.getElement("addInfo")!;
          String fiscalNumber     = infoElement.getElement("fiscalReceiptNumber")!.innerText.padLeft(4, '0');
          String fiscalClosure    = infoElement.getElement("zRepNumber")!.innerText.padLeft(4, '0');

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

    FiscalReceiptResponse   response          = FiscalReceiptResponse();
    String                  payload           = "";
    String                  responsePrinter   = "";

    try{
      String isoToDate(String isoString) {
        DateTime date = DateTime.parse(isoString);
        return DateFormat('dd-MM-yyyy').format(date).split('-').join();
      }
      String epsonDateFormat = isoToDate(enDate);

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element(
        'soapenv:Envelope',
        attributes: {
          'xmlns:soapenv': 'http://schemas.xmlsoap.org/soap/envelope/'
        },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerFiscalReceipt',
                nest: (){
                  builder.element(
                    'printRecMessage',
                    attributes: {
                      'operator'    : '1',
                      'message'     : 'VOID $documentClose $documentNumber $epsonDateFormat $serialNumber',
                      'messageType' : '4'
                    }
                  );
                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
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
        XmlElement elementResponse  = document.getElement("soapenv:Envelope")!.getElement("soapenv:Body")!.getElement("response")!;

        if(elementResponse.getAttribute("success") == "true"){
          
          XmlElement infoElement  = elementResponse.getElement("addInfo")!;
          String fiscalNumber     = infoElement.getElement("fiscalReceiptNumber")!.innerText.padLeft(4, '0');
          String fiscalClosure    = infoElement.getElement("zRepNumber")!.innerText.padLeft(4, '0');

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

  /// Reso scontrino
  @override
  Future<FiscalReceiptResponse> refundReceipt(FiscalReceipt receipt, String serialNumber, String documentNumber, String documentClose, String enDate) async {


    FiscalReceiptResponse   response          = FiscalReceiptResponse();
    String                  payload           = "";
    String                  responsePrinter   = "";

    try{

      String epsonDateFormat = enDate.split("-").reversed.join("");

      XmlBuilder builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element(
        'soapenv:Envelope',
        attributes: {
          'xmlns:soapenv': 'http://schemas.xmlsoap.org/soap/envelope/'
        },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerFiscalReceipt',
                nest: (){
                  
                  builder.element(
                    'printRecMessage',
                    attributes: {
                      'operator'    : '1',
                      'message'     : 'REFUND $documentClose $documentNumber $epsonDateFormat',
                      'messageType' : '4'
                    }
                  );

                  builder.element(
                    'beginFiscalReceipt',
                    attributes: {
                      'Ope': "1"
                    }
                  );

                  for (FiscalReceiptLine line in receipt.lines) {
                    builder.element(
                      'printRecRefund',
                      attributes: {
                        'Text'    : line.title,
                        'Qty'     : line.quantity.toString(),
                        'UnitCost': line.price.toString(),
                        'Dep'     : line.departmentNumber.toString(),
                        'Just'    : '1'
                      }
                    );
                  }

                  builder.element(
                    'printRecTotal',
                    attributes: {
                      'operator': '1'
                    }
                  );

                  builder.element(
                    'endFiscalReceipt',
                    attributes: {
                      'Ope': "1"
                    }
                  );

                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response responseReceipt = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
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
        XmlElement elementResponse  = document.getElement("soapenv:Envelope")!.getElement("soapenv:Body")!.getElement("response")!;

        if(elementResponse.getAttribute("success") == "true"){
          
          XmlElement infoElement  = elementResponse.getElement("addInfo")!;
          String fiscalNumber     = infoElement.getElement("fiscalReceiptNumber")!.innerText.padLeft(4, '0');
          String fiscalClosure    = infoElement.getElement("zRepNumber")!.innerText.padLeft(4, '0');

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
        'soapenv:Envelope',
        attributes: { "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/" },
        nest: (){
          builder.element(
            'soapenv:Body',
            nest: (){
              builder.element(
                'printerNonFiscal',
                nest: (){
                  builder.element(
                    'Printer',
                    attributes: {
                      'Num': '1'
                    }
                  );
                  builder.element(
                    'beginNonFiscal',
                    attributes: {
                      'Ope': '1'
                    }
                  );
                  lines.forEach((line){
                    builder.element(
                      'printNormal',
                      attributes: {
                        'Font': '1',
                        'Ope' : '1',
                        'Text': line
                      }
                    );
                  });
                  builder.element('endNonFiscal');
                }
              );
            }
          );
        }
      );
      payload = builder.buildDocument().toXmlString(pretty: true);

      http.Response response = 
        await http.post(
          httpEndpoint(ip, 'cgi-bin/fpmate.cgi?devid=local_printer'),
          headers: httpHeaders(),
          body: payload
        )
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('timeout', 800),
        );

      responsePrinter = response.body; // Non loggare superfluo

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      logReceipt(payload, responsePrinter);
    }

  }

}
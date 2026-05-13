/* import 'dart:convert';

import 'package:dashboard/printers/fiscal/fiscal_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PosEvent {

  /// Display message
  static void displayMessage(BuildContext context, String message) {
    showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          backgroundColor: Colors.amber,
          title: Text("Messaggio", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          content: Text(message, style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Ok", style: TextStyle(color: Colors.amber))
            )
          ],
        );
      }
    );
  }


  /// Configure pos params
  static Future<void> configureParams(
    BuildContext context,
    String? fiscalPrinterModel,
    TextEditingController controllerIp, 
    TextEditingController controllerSerial, 
    TextEditingController controllerTimeout
  ) async {

    try{

      if(!RegExp(r'^((25[0-5]|(2[0-4]\d|1\d\d|[1-9]?\d))\.){3}(25[0-5]|(2[0-4]\d|1\d\d|[1-9]?\d))$').hasMatch(controllerIp.text)){
        displayMessage(context, "IP non valido");
        return;
      }

      if(controllerSerial.text.trim().isEmpty){
        displayMessage(context, "Compilare numero seriale");
        return;
      }

      int? timeout;
      if((timeout = int.tryParse(controllerTimeout.text)) == null){
        displayMessage(context, "Timeout non valido");
        return;
      }
      if(timeout! <= 0){
        displayMessage(context, "Il timeout deve essere maggiore di zero!");
        return;
      }

      SharedPreferences prefences = await SharedPreferences.getInstance();
      if(fiscalPrinterModel != null){
        prefences.setString("fiscal_printer", fiscalPrinterModel);
      }else{
        prefences.remove("fiscal_printer");
      }

      String ip     = controllerIp.text.trim();
      String serial = controllerSerial.text.trim().toUpperCase();

      prefences.setString("ip_address", ip);
      prefences.setString("serial", serial);
      prefences.setInt("timeout", timeout);
      displayMessage(context, "Parametri configurati!");

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }

  }

  /// Parametri correttamente configurati
  static Future<bool> isConfiguredCorrectlyParams({bool compiledFiscalPrinter = true, bool showMessage = false, BuildContext? context}) async {
    
    SharedPreferences prefences = await SharedPreferences.getInstance();
    String? fiscalPrinter       = prefences.getString("fiscal_printer");
    String? ipAddress           = prefences.getString("ip_address");
    String? serial              = prefences.getString("serial");
    int? timeout                = prefences.getInt("timeout");

    if(compiledFiscalPrinter){
      if(fiscalPrinter == null){
        if(context != null && showMessage){
          displayMessage(context, "Compilare stampante fiscale");
        }
        return false;
      }
    }

    bool isValid = ipAddress != null && serial != null && timeout != null;
    if(!isValid){
      if(context != null && showMessage){
        displayMessage(context, "Compilare correttamente i campi");
      }
    }else{

      // Override variabili

    }

    return isValid;
  }

  /// Evento chiusura fiscale
  static Future<void> fiscalCloseEvt(BuildContext context) async {
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }
/*     await FiscalFactory.getFiscal(
      FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
      Constants.fiscalPrinterIp!, 
      Constants.fiscalPrinterSerial!, 
      Constants.fiscalPrinterTimeout!
    ).fiscalClosure(); */
  }

  /// Evento di lettura fiscale
  static Future<void> fiscalReadingEvt(BuildContext context) async {
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }
    /* await FiscalFactory.getFiscal(
      FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
      Constants.fiscalPrinterIp!, 
      Constants.fiscalPrinterSerial!, 
      Constants.fiscalPrinterTimeout!
    ).fiscalReading(); */
  }

  /// Evento di stato stampante
  static Future<void> fiscalStatus(BuildContext context) async {
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }
    /* FiscalPrinterStatus status =
      await FiscalFactory.getFiscal(
        FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
        Constants.fiscalPrinterIp!, 
        Constants.fiscalPrinterSerial!, 
        Constants.fiscalPrinterTimeout!
      ).fiscalStatus(); */
    String verboseStatus = FiscalFactory.getFiscalVerboseStatusFromKey(status);
    displayMessage(context, verboseStatus);
  }

  /// Evento di messaggio al visore
  static Future<void> displayMessageOnViewer(BuildContext context) async {
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }
 /*    await FiscalFactory.getFiscal(
      FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
      Constants.fiscalPrinterIp!, 
      Constants.fiscalPrinterSerial!, 
      Constants.fiscalPrinterTimeout!
    ).displayMessageOnViewer("Hello word!"); */
  }

  /// Evento di messaggio apertura cassetto
  static Future<void> openDrawer(BuildContext context) async {
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }
 /*    await FiscalFactory.getFiscal(
      FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
      Constants.fiscalPrinterIp!, 
      Constants.fiscalPrinterSerial!, 
      Constants.fiscalPrinterTimeout!
    ).openDrawer(); */
  }


  /// Rimuovi sconto
  static Future<void> removeDiscount(BuildContext context, PosState state) async {

    showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          backgroundColor: Constants.primaryColor,
          title: Text("Attenzione", style: TextStyle(color: Colors.white)),
          content: Text("Sicuro di voler rimuovere lo sconto?", style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("No", style: TextStyle(color: Constants.secondaryColor))
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await PosDocument.instance().removeDiscount();
                if(state.viewerState.mounted){
                  state.viewerState.setState((){

                  });
                }
              }, 
              child: Text("Si", style: TextStyle(color: Constants.secondaryColor))
            )
          ],
        );
      }
    );
  }

  /// Stampa scontrino contante
  static Future<void> printCashReceipt(BuildContext context, PosState state) async {
    
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }

    if(PosDocument.instance().isCartEmpty){
      displayMessage(context, "Carrello vuoto");
      return;
    }

    FiscalReceipt receipt = PosDocument.instance().prepareReceipt("Contanti", 1, 1, PosDocument.instance().amountDisc);
    if(receipt.lines.isEmpty || receipt.payments.isEmpty){
      displayMessage(context, "Errore durante la produzione dello scontrino");
      return;
    }

    FiscalReceiptResponse response = 
      await FiscalFactory.getFiscal(
        FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
        Constants.fiscalPrinterIp!, 
        Constants.fiscalPrinterSerial!, 
        Constants.fiscalPrinterTimeout!
      ).printReceipt(receipt);

    if(!response.success){
      displayMessage(context, "Stampa scontrino fallita");
      return;
    }

    displayMessage(context, "Scontrino ${response.fiscalClosure}-${response.fiscalNumber} stampato con successo");

    // Pulisci carrello
    await PosDocument.instance().cleanSale();
    if(state.viewerState.mounted){
      state.viewerState.setState((){

      });
    }

  }

  /// Stampa scontrino contante
  static Future<void> printCreditCardReceipt(BuildContext context, PosState state) async {
    
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }

    if(PosDocument.instance().isCartEmpty){
      displayMessage(context, "Carrello vuoto");
      return;
    }

    FiscalReceipt receipt = PosDocument.instance().prepareReceipt("Carta di credito", 2, 1, PosDocument.instance().amountDisc);
    if(receipt.lines.isEmpty || receipt.payments.isEmpty){
      displayMessage(context, "Errore durante la produzione dello scontrino");
      return;
    }

    FiscalReceiptResponse response = 
      await FiscalFactory.getFiscal(
        FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
        Constants.fiscalPrinterIp!, 
        Constants.fiscalPrinterSerial!, 
        Constants.fiscalPrinterTimeout!
      ).printReceipt(receipt);

    if(!response.success){
      displayMessage(context, "Stampa scontrino fallita");
      return;
    }

    displayMessage(context, "Scontrino ${response.fiscalClosure}-${response.fiscalNumber} stampato con successo");

    // Pulisci carrello
    await PosDocument.instance().cleanSale();
    if(state.viewerState.mounted){
      state.viewerState.setState((){

      });
    }

  }

  /// Evento annullo scontrino
  static Future<void> fiscalCancel(BuildContext context) async {
    
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }

    TextEditingController controllerFiscalNumber  = TextEditingController();
    TextEditingController controllerFiscalClose   = TextEditingController();
    TextEditingController controllerDate          = TextEditingController();

    bool canCancel = false;
    await showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          title: Text("Annullo scontrino", style: TextStyle(color: Colors.white)),
          backgroundColor: Constants.primaryColor,
          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: controllerFiscalNumber,
                  cursorColor: Colors.white,
                  autofocus: true,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Constants.secondaryColor)
                    ),
                    label: Text("Numero documento", style: TextStyle(color: Colors.white))
                  ),
                  style: TextStyle(color: Colors.white)
                ),

                Container(height: 10),

                TextField(
                  controller: controllerFiscalClose,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Constants.secondaryColor)
                    ),
                    label: Text("Numero chiusura", style: TextStyle(color: Colors.white))
                  ),
                  style: TextStyle(color: Colors.white)
                ),

                Container(height: 10),

                InkWell(
                  onTap: () async {
                    DateTime? date = await showDatePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime.now());
                    if(date != null){
                      controllerDate.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    }
                  },
                  child: TextField(
                    enabled: false,
                    controller: controllerDate,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Constants.secondaryColor)
                      ),
                      label: Text("Data scontrino", style: TextStyle(color: Colors.white))
                    ),
                    style: TextStyle(color: Colors.white)
                  ),
                ),

                Container(height: 10)

              ]
            )
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.pop(context);
              }, 
              child: Text("Annulla", style: TextStyle(color: Colors.white))
            ),
            TextButton(
              onPressed: () async {
                
                if(int.tryParse( controllerFiscalNumber.text ) == null){
                  displayMessage(context, "Compilare correttamente numero scontrino");
                  return;
                }
                if(int.tryParse( controllerFiscalClose.text ) == null){
                  displayMessage(context, "Compilare correttamente numero chiusura");
                  return;
                }
                if(controllerDate.text.isEmpty){
                  displayMessage(context, "Compilare correttamente la data dello scontrino");
                  return;
                }

                Navigator.pop(context);

                // Fai partire annullo scontrino
                canCancel = true;

              }, 
              child: Text("Ok", style: TextStyle(color: Constants.secondaryColor))
            )
          ],
        );
      }
    );

    if(canCancel){
      FiscalReceiptResponse responseCancel = 
        await FiscalFactory.getFiscal(
          FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
          Constants.fiscalPrinterIp!, 
          Constants.fiscalPrinterSerial!, 
          Constants.fiscalPrinterTimeout!
        ).cancelReceipt(
          Constants.fiscalPrinterSerial!.trim().toUpperCase(),
          controllerFiscalNumber.text.trim().padLeft(4, '0'),
          controllerFiscalClose.text.trim().padLeft(4, '0'),
          controllerDate.text.trim()
        );
      if(!responseCancel.success){
        displayMessage(context, "Si è verificato un errore durante l'annullo");
        return;
      }
      displayMessage(context, "Scontrino annullato. Numero documento di annullo ${responseCancel.fiscalClosure}-${responseCancel.fiscalNumber}");
    }

  }

  /// Evento reso scontrino
  static Future<void> fiscalRefund(BuildContext context) async {
    
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }

    if(PosDocument.instance().isCartEmpty){
      displayMessage(context, "Carrello vuoto");
      return;
    }

    FiscalReceipt receipt = PosDocument.instance().prepareReceipt("Reso", 0, 1, 0.00);
    if(receipt.lines.isEmpty || receipt.payments.isEmpty){
      displayMessage(context, "Errore durante la produzione dello scontrino");
      return;
    }

    TextEditingController controllerFiscalNumber  = TextEditingController();
    TextEditingController controllerFiscalClose   = TextEditingController();
    TextEditingController controllerDate          = TextEditingController();

    bool canRefund = false;
    await showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          title: Text("Reso scontrino", style: TextStyle(color: Colors.white)),
          backgroundColor: Constants.primaryColor,
          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: controllerFiscalNumber,
                  cursorColor: Colors.white,
                  autofocus: true,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Constants.secondaryColor)
                    ),
                    label: Text("Numero documento", style: TextStyle(color: Colors.white))
                  ),
                  style: TextStyle(color: Colors.white)
                ),

                Container(height: 10),

                TextField(
                  controller: controllerFiscalClose,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Constants.secondaryColor)
                    ),
                    label: Text("Numero chiusura", style: TextStyle(color: Colors.white))
                  ),
                  style: TextStyle(color: Colors.white)
                ),

                Container(height: 10),

                InkWell(
                  onTap: () async {
                    DateTime? date = await showDatePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime.now());
                    if(date != null){
                      controllerDate.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    }
                  },
                  child: TextField(
                    enabled: false,
                    controller: controllerDate,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Constants.secondaryColor)
                      ),
                      label: Text("Data scontrino", style: TextStyle(color: Colors.white))
                    ),
                    style: TextStyle(color: Colors.white)
                  ),
                ),

                Container(height: 10)

              ]
            )
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.pop(context);
              }, 
              child: Text("Annulla", style: TextStyle(color: Colors.white))
            ),
            TextButton(
              onPressed: () async {
                
                if(int.tryParse( controllerFiscalNumber.text ) == null){
                  displayMessage(context, "Compilare correttamente numero scontrino");
                  return;
                }
                if(int.tryParse( controllerFiscalClose.text ) == null){
                  displayMessage(context, "Compilare correttamente numero chiusura");
                  return;
                }
                if(controllerDate.text.isEmpty){
                  displayMessage(context, "Compilare correttamente la data dello scontrino");
                  return;
                }

                Navigator.pop(context);

                // Fai partire annullo scontrino
                canRefund = true;

              }, 
              child: Text("Ok", style: TextStyle(color: Constants.secondaryColor))
            )
          ],
        );
      }
    );

    if(canRefund){
      FiscalReceiptResponse responseRefund = 
        await FiscalFactory.getFiscal(
          FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
          Constants.fiscalPrinterIp!, 
          Constants.fiscalPrinterSerial!, 
          Constants.fiscalPrinterTimeout!
        ).refundReceipt(
          receipt,
          Constants.fiscalPrinterSerial!.trim().toUpperCase(),
          controllerFiscalNumber.text.trim().padLeft(4, '0'),
          controllerFiscalClose.text.trim().padLeft(4, '0'),
          controllerDate.text.trim()
        );
      if(!responseRefund.success){
        displayMessage(context, "Si è verificato un errore durante il reso");
        return;
      }
      displayMessage(context, "Scontrino annullato. Numero documento di reso ${responseRefund.fiscalClosure}-${responseRefund.fiscalNumber}");
    }

  }

  /// Evento di stampa non fiscale
  static Future<void> notFiscal(BuildContext context) async {
    if(!await isConfiguredCorrectlyParams(showMessage: true, context: context)){
      return;
    }
    await FiscalFactory.getFiscal(
      FiscalFactory.getFiscalTypeFromString(Constants.fiscalPrinterModel!), 
      Constants.fiscalPrinterIp!, 
      Constants.fiscalPrinterSerial!, 
      Constants.fiscalPrinterTimeout!
    ).printNotFiscal(
      [
        "--------------------",
        "Questo è un esempio di scontrino",
        "non fiscale",
        "--------------------",
      ]
    );
  }

  /// Esc POS
  static Future<void> escPos(BuildContext context, {bool isForQr = false}) async {

    TextEditingController controllerIp = TextEditingController();

    await showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          title: Text("ESC/POS Testo", style: TextStyle(color: Colors.white)),
          backgroundColor: Constants.primaryColor,
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: controllerIp,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Constants.secondaryColor)
                    ),
                    label: Text("IP non fiscale", style: TextStyle(color: Colors.white))
                  ),
                  style: TextStyle(color: Colors.white)
                )
              ]
            )
          ),
          actions: [
            TextButton(
              onPressed: () async{
                Navigator.pop(context);
                if(controllerIp.text.isNotEmpty){
                  if(!isForQr){
                    EscPos().printReceipt(
                      controllerIp.text.trim(), 
                      9100, 
                      [
                        "Esempio scontrino non fiscale ESC/POS"
                      ]
                    );
                    return;
                  }
                  EscPos().printQrCode(
                    controllerIp.text.trim(), 
                    9100, 
                    "Esempio QRCODE"
                  );
                }
              }, 
              child: Text("Ok", style: TextStyle(color: Constants.secondaryColor))
            )
          ],
        );
      }
    );

  }

} */
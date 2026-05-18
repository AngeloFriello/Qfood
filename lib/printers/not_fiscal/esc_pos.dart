import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:intl/intl.dart';

abstract class EscPosBase {
  Future<void> printReceipt(String host, int port,List<String> linesHead, List<String> lines, CarrelloController ctr);
  Future<void> printQrCode(String host, int port, String content);
}


class EscPos extends EscPosBase {


  Future<bool> printReceiptInvoice(String host, int port, List<String> linesHead, List<String> lines, CarrelloController ctr, int documentNumber )async {
    bool success = true;
    Socket? socket;

    try{
      int maxCharts = 42;
      socket = await Socket.connect(host, port).timeout(Duration(seconds: 6));
      List<int> bytes           = [];
      CapabilityProfile profile = await CapabilityProfile.load();
      Generator generator       = Generator(PaperSize.mm80, profile);
      CustomerModel? customer = ctr.cliente;
      if( customer == null ) return false;

      bytes += [0x1B, 0x40]; //RESET
      bytes += [0x1B, 0x46];
      bytes += [0x1B, 0x33, 0x10]; //INTERLINEA STRETTA modificare il 10
      bytes += generator.emptyLines(2);

      //INTESTAZIONE PUNTO VENDITA
      bytes += [27, 97, 1];     // CENTRA IL TESTO
      bytes += [0x1B, 0x45, 0x01];
      bytes += generator.text(linesHead[0]);
      bytes += [0x1B, 0x45, 0x00];
      bytes += generator.text(linesHead[1]);
      bytes += generator.text(linesHead[2]);
      bytes += generator.text(linesHead[3]);
      bytes += generator.text(linesHead[4]);
      bytes += [27, 97, 0];   // TESTO a sinistra

      bytes += generator.emptyLines(5);
      
      if( documentNumber > 0 )   bytes += generator.text("Futtura N ${documentNumber}\n");
      //if( documentNumber == 0 )  bytes += generator.text("\n");
      //CLIENTE
      bytes += generator.text("Cliente: ${customer.titleCustomer}\n");
      bytes += generator.text("PIVA: ${customer.businessVatNumber ?? customer.businessFiscalCode ?? ''}\n");

      bytes += generator.emptyLines(5);

      bytes += [0x1B, 0x45, 0x01]; // ATTIVA GRATTETTO
      bytes += generator.text("QT    DESCRIZIONE                   Prezzo\n");
      bytes += [0x1B, 0x45, 0x00];  // DISATTIVA GRASSETTO GRATTETTO

      //RIGHE CARRELLO
      lines.forEach((l){
        bytes += generator.text(l);
      });
      
      //TOTALE
      bytes += generator.emptyLines(3);
      double totCart  = ctr.totaleCarrello;
      double discount = ctr.discount;
      String totNet   = ( totCart - discount ).toStringAsFixed(2);
      String padding  = ' ' * (maxCharts - ("TOTALE"+totCart.toStringAsFixed(2)).length).clamp(0, 99);

      ProdottoCarrello? tips = ctr.prodotti.firstWhereOrNull((p) => p.article.title.trim().toUpperCase().contains('mancia'.toUpperCase()));
      totNet = (double.parse(totNet) + (tips != null ? tips.priceRowCart : 0)).toStringAsFixed(2);

      if( ctr.discount > 0 ){
        bytes += [0x1B, 0x21, 0x10]; //LARGHEZZA DOPPIA
        bytes += generator.text("TOTALE"+padding+totCart.toStringAsFixed(2));
        bytes += [0x1B, 0x21, 0x00]; //DISATTIVA LARGHEZZA DOPPIA
        String paddingDiscount  = ' ' * (maxCharts - ("Sconto applicato sul totale"+discount.toStringAsFixed(2)).length).clamp(0, 99);
        bytes += generator.text("Sconto applicato sul totale"+paddingDiscount+discount.toStringAsFixed(2));
      }

      bytes += generator.emptyLines(5);


      bytes += [0x1B, 0x45, 0x01]; // ATTIVA GRATTETTO
      bytes += generator.text("IVA    Impon.    Imposta");
      bytes += [0x1B, 0x45, 0x00];  // DISATTIVA GRASSETTO GRATTETTO
      ctr.getSummary().forEach((s)  {
        bytes += generator.text('${s.vatValue.toStringAsFixed(2).padRight(7,' ')}${s.amountTaxable.toStringAsFixed(2).padRight(10,' ')}${s.amountTax.toStringAsFixed(2)}');
      });

   
      bytes += generator.emptyLines(3);
      String paddingTotalNet  = ' ' * (maxCharts - ( "TOTALE COMPLESSIVO"+(totNet ) ).length ).clamp(0, 99);
      bytes += [0x1B, 0x21, 0x10]; //LARGHEZZA DOPPIA
      bytes += generator.text("TOTALE COMPLESSIVO"+paddingTotalNet+totNet);
      bytes += [0x1B, 0x21, 0x00]; //DISATTIVA LARGHEZZA DOPPIA


      bytes += generator.emptyLines(5);
      
      //DATA/ORA
      final DateTime now = DateTime.now();
      final String dateStr = DateFormat('dd/MM/yyyy').format(now);
      final String timeStr = DateFormat('HH:mm:ss').format(now);
      String paddingDate   = ' ' * (maxCharts - (( dateStr+', '+timeStr ).length) ).clamp(0, 99);
      bytes += generator.text(paddingDate.substring(paddingDate.length ~/ 2)+dateStr+', '+timeStr+paddingDate.substring(paddingDate.length ~/ 2));

      //CHIUSURA
      bytes += generator.emptyLines(10);
      bytes += generator.cut();

      socket.add(bytes);
      await socket.flush();
      
    }catch(e){
      SnackBarForcedClosure('Errore stampante non fiscale!', Colors.red);
      success = false;
      if(kDebugMode){
        print(e);
      }
    }finally{
      if(socket != null){
        await socket.close();
      }
      return success;
    }

  }

  @override
  Future<bool> printReceipt(String host, int port, List<String> linesHead,  List<String> lines, CarrelloController ctr) async {
    bool success = true;
    Socket? socket;

    try{
      int maxCharts = 42;
      socket = await Socket.connect(host, port).timeout(Duration(seconds: 6));
      List<int> bytes           = [];
      CapabilityProfile profile = await CapabilityProfile.load();
      Generator generator       = Generator(PaperSize.mm80, profile);
      bytes += [0x1B, 0x40]; //RESET
      bytes += [0x1B, 0x46];
      bytes += [0x1B, 0x33, 0x10]; //INTERLINEA STRETTA modificare il 10
      bytes += generator.emptyLines(2);

      //INTESTAZIONE PUNTO VENDITA
      bytes += [27, 97, 1];     // CENTRA IL TESTO
      bytes += [0x1B, 0x45, 0x01];
      bytes += generator.text(linesHead[0]);
      bytes += [0x1B, 0x45, 0x00];
      bytes += generator.text(linesHead[1]);
      bytes += generator.text(linesHead[2]);
      bytes += generator.text(linesHead[3]);
      bytes += generator.text(linesHead[4]);
      bytes += [27, 97, 0];   // TESTO a sinistra

      bytes += generator.emptyLines(5);

      bytes += [0x1B, 0x45, 0x01]; // ATTIVA GRATTETTO
      bytes += generator.text("QT    DESCRIZIONE                   Prezzo\n");
      bytes += [0x1B, 0x45, 0x00];  // DISATTIVA GRASSETTO GRATTETTO

      //RIGHE CARRELLO
      [...lines].forEach((line){
        bytes += generator.text(line);
      });
      
      //TOTALE
      bytes += generator.emptyLines(3);
      double totCart  = ctr.totaleCarrello;
      double discount = ctr.discount;
      String totNet   = ( totCart - discount ).toStringAsFixed(2);
      String padding  = ' ' * (maxCharts - ("TOTALE"+totCart.toStringAsFixed(2)).length).clamp(0, 99);

      if( ctr.discount > 0 ){
        bytes += [0x1B, 0x21, 0x10]; //LARGHEZZA DOPPIA
        bytes += generator.text("TOTALE"+padding+totCart.toStringAsFixed(2));
        bytes += [0x1B, 0x21, 0x00]; //DISATTIVA LARGHEZZA DOPPIA
        String paddingDiscount  = ' ' * (maxCharts - ("Sconto applicato sul totale"+discount.toStringAsFixed(2)).length).clamp(0, 99);
        bytes += generator.text("Sconto applicato sul totale"+paddingDiscount+discount.toStringAsFixed(2));
      }

      
      bytes += generator.emptyLines(3);
      String paddingTotalNet  = ' ' * (maxCharts - ( "TOTALE COMPLESSIVO"+totNet ).length ).clamp(0, 99);
      bytes += [0x1B, 0x21, 0x10]; //LARGHEZZA DOPPIA
      bytes += generator.text("TOTALE COMPLESSIVO"+paddingTotalNet+totNet);
      bytes += [0x1B, 0x21, 0x00]; //DISATTIVA LARGHEZZA DOPPIA
      bytes += generator.emptyLines(3);

      //DIVISIONE CONTO
      final coverInCart = ctr.coperti();
      if( coverInCart > 0 ){
        String totalSplitForCover = (double.parse(totNet) / coverInCart).toStringAsFixed(2);
        bytes += [0x1B, 0x21, 0x10]; //LARGHEZZA DOPPIA
        bytes += generator.text("Divisione per ${coverInCart.toStringAsFixed(0)}: "+totalSplitForCover);
        bytes += [0x1B, 0x21, 0x00]; //DISATTIVA LARGHEZZA DOPPIA
        bytes += generator.emptyLines(3);
      }

      //DATA/ORA
      final DateTime now = DateTime.now();
      final String dateStr = DateFormat('dd/MM/yyyy').format(now);
      final String timeStr = DateFormat('HH:mm:ss').format(now);
      String paddingDate   = ' ' * (maxCharts - (( dateStr+', '+timeStr ).length) ).clamp(0, 99);
      bytes += generator.text(paddingDate.substring(paddingDate.length ~/ 2)+dateStr+', '+timeStr+paddingDate.substring(paddingDate.length ~/ 2));

      //CHIUSURA
      bytes += generator.emptyLines(10);
      bytes += generator.cut();

      socket.add(bytes);
      await socket.flush();
      
    }catch(e){
      SnackBarForcedClosure('Errore stampante non fiscale!', Colors.red);
      success = false;
      if(kDebugMode){
        print(e);
      }
    }finally{
      if(socket != null){
        await socket.close();
      }
      return success;
    }

  }

  @override
  Future<void> printQrCode(String host, int port, String content) async {

    Socket? socket;

    try{
      
      socket = await Socket.connect(host, port);
      
      List<int> bytes           = [];
      CapabilityProfile profile = await CapabilityProfile.load();
      Generator generator       = Generator(PaperSize.mm80, profile);

      bytes += generator.qrcode(content);
      bytes += generator.emptyLines(5);
      bytes += generator.cut();

      socket.add(bytes);
      await socket.flush();

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }finally{
      if(socket != null){
        await socket.close();
      }
    }

  }


  Future<bool> printOrderToDepartment( 
    String host, 
    int port, 
    OperatoreModel operator,
    String deviceName,
    String? tableName, 
    List<ProdottoCarrello> lines, 
    int coperti,
    TableModel? table,
    Ordine? ordine,
  ) async {
    bool    success = true;
    Socket? socket;
    final List<ProdottoCarrello> onlyNoPrinted = lines.where((p) => p.printed != 1).toList();
    if( onlyNoPrinted.isEmpty )return false;
    try{
      int maxCharts = 42;
      socket = await Socket.connect(host, port).timeout(Duration(seconds: 6));
      List<int> bytes           = [];
      CapabilityProfile profile = await CapabilityProfile.load();
      Generator generator       = Generator(PaperSize.mm80, profile);


      //DATA/ORA
      final DateTime now = DateTime.now();
      final String dateStr = DateFormat('dd/MM/yyyy').format(now);
      final String timeStr = DateFormat('HH:mm:ss').format(now);
      

      bytes += [0x1B, 0x40];             //RESET
      bytes += [0x1B, 0x46];
      bytes += [0x1B, 0x33, 0x10];       //INTERLINEA STRETTA modificare il 10
      bytes += generator.emptyLines(2);

      //INTESTAZIONE
      bytes += generator.text((tableName != null ? 'TAVOLO: ' + tableName : ordine != null ? ( 'Ordine: '+ordine.titleCustomer) : 'Banco'),
                              styles: PosStyles(
                                        bold: true,
                                        height: PosTextSize.size2, // da 1 a 8
                                        width:  PosTextSize.size1,  // da 1 a 8
                                      ),
                              );
      bytes += generator.text('------------------------------------------');
      bytes += generator.text('Data: ' +dateStr+', '+timeStr);
      bytes += generator.text('Utente: ' +operator.title);
      bytes += generator.text('Dispositivo : ' +deviceName);
      if( tableName != null ) bytes += generator.text('Coperti: ' +coperti.toInt().toString());
      if( ordine != null)     bytes += generator.text('Nota: ' + (ordine.note ?? ''));
      bytes += generator.text('------------------------------------------');


      bytes += generator.emptyLines(5);

      //RIGHE CARRELLO
      [...onlyNoPrinted].forEach((p){
        String l = p.quantity.toInt().toString() + '  ' + p.article.title;
        List<ProdottoCarrello> variants = [...p.variationsFree,...p.variationsInfo,...p.variationsPlus];
        bytes  += generator.text(l,styles:  PosStyles(
                                        bold: true,
                                        height: PosTextSize.size2, // da 1 a 8
                                        width:  PosTextSize.size1,  // da 1 a 8
                                      ),);
        variants.forEach((v) {
          String l = '   '+'+ '+v.article.title;
          bytes  += generator.text(l);
          bytes += generator.emptyLines(1); // SPAZIO TRA UN ARTICOLO E L ALTRO
        });

        p.variationsMinus.forEach((v) {
          String l = '   '+'- '+v.article.title;
          bytes  += generator.text(l);
          bytes += generator.emptyLines(1); // SPAZIO TRA UN ARTICOLO E L ALTRO
        });
        bytes += generator.emptyLines(3); // SPAZIO TRA UN ARTICOLO E L ALTRO
      });
      
      
      bytes += generator.text('------------------------------------------');
       bytes += generator.text((tableName != null ? 'TAVOLO: ' + tableName : ordine != null ? ( 'Ordine: '+ordine.titleCustomer) : 'Banco'),
                              styles: PosStyles(
                                        bold: true,
                                        height: PosTextSize.size2,   // da 1 a 8
                                        width:  PosTextSize.size1,  // da 1 a 8
                                      ),
                              );

      //CHIUSURA
      bytes += generator.emptyLines(20);
      bytes += generator.cut();

      socket.add(bytes);
      await socket.flush();
      
    }catch(e){
      SnackBarForcedClosure('Errore stampante non fiscale!', Colors.red);
      success = false;
      if(kDebugMode){
        print(e);
      }
    }finally{
      if(socket != null){
        await socket.close();
      }

     if( success && table != null ){
        //SE é ANDATO BENE SETTA TUTTI GLI ARTICOLI COME STAMPATI
        TableModel.articlesSetPrinted(table, onlyNoPrinted);
        //INVIARE DATI AI CLIENTS

      }  

      return success;
    }

  }

}
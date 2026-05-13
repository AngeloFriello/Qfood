
import 'package:dashboard/printers/fiscal/fiscal_base.dart';
import 'package:dashboard/printers/fiscal/fiscal_custom.dart';
import 'package:dashboard/printers/fiscal/fiscal_epson.dart';

enum FiscalType {
  custom, epson
}

class FiscalFactory {

  /// Metodo per ottenere stampante fiscale
  static FiscalBase getFiscal(FiscalType type, String ip, String serialNumber, int timeout){

    String cleanIp      = ip.trim();
    String cleanSerial  = serialNumber.trim().toUpperCase();

    switch(type){
      case FiscalType.custom: {
        return FiscalCustom(ip: cleanIp, serialNumber: cleanSerial, timeout: timeout);
      }
      case FiscalType.epson: {
        return FiscalEpson(ip: cleanIp, serialNumber: cleanSerial, timeout: timeout);
      }
    }

  }

  /// Ottieni enum da stringa
  static getFiscalTypeFromString(String value){
    switch(value){
      case "custom": {
        return FiscalType.custom;
      }
      case "epson": {
        return FiscalType.epson;
      }
    }
  }

  /// Ottieni in maniera verbosa gli stati della stampante
  static getFiscalVerboseStatusFromKey(FiscalPrinterStatus status){
    switch(status){
      case FiscalPrinterStatus.unknown: {
        return "Non è stato possibile recuperare lo stato della stampante";
      }
      case FiscalPrinterStatus.paperEnd: {
        return "La carta è terminata";
      }
      case FiscalPrinterStatus.paperEnding: {
        return "La carta sta per terminare";
      }
      case FiscalPrinterStatus.receiptOpened: {
        return "Uno scontrino è aperto";
      }
      case FiscalPrinterStatus.coveredOpened: {
        return "Coperchio aperto";
      }
      case FiscalPrinterStatus.paperError: {
        return "Errore carta";
      }
      case FiscalPrinterStatus.ready: {
        return "Stampante pronta!";
      }
      case FiscalPrinterStatus.inError: {
        return "Stampante in stato di errore!";
      }
    }
  }

}
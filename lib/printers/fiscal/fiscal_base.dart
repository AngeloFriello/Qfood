
import 'package:dashboard/printers/fiscal/fiscal_model.dart';

enum FiscalPrinterStatus { unknown, paperEnd, paperEnding, coveredOpened, receiptOpened, paperError, ready, inError }

abstract class FiscalBase {

  /// Get endpoint
  Uri httpEndpoint(String ip, String pathname, {String? queryParams, bool https = false}){
    return Uri.parse( "http${https ? 's' : ''}://$ip/$pathname${queryParams ?? ""}" );
  }

  /// Componi header di chiamata
  Map<String, String> httpHeaders();

  /// Chiusura fiscale
  Future<bool> fiscalClosure();

  /// Lettura fiscale
  Future<bool> fiscalReading();

  /// Ottieni stato stampante fiscale
  Future<FiscalPrinterStatus> fiscalStatus();

  /// Mostra messaggio sul visore
  Future<void> displayMessageOnViewer(String message);

  /// Open drawer
  Future<void> openDrawer();

  /// Stampa dello scontrino
  Future<FiscalReceiptResponse> printReceipt(FiscalReceipt receipt);

  /// Reso dello scontrino
  Future<FiscalReceiptResponse> refundReceipt(FiscalReceipt receipt, String serialNumber, String documentNumber, String documentClose, String enDate);

  /// Annullo dello scontrino
  Future<FiscalReceiptResponse> cancelReceipt(String serialNumber, String documentNumber, String documentClose, String enDate);

  /// Stampa non fiscale
  Future<void> printNotFiscal(List<String> lines);

}
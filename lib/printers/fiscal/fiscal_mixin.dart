import 'dart:io';
import 'package:dashboard/printers/fiscal/fiscal_base.dart';
import 'package:dashboard/printers/fiscal/fiscal_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

mixin FiscalMixin on FiscalBase {

  /// Logga scontrino e risposta
  Future<void> logReceipt(String payload, String response, {String? overrideFilename}) async {

    try{

      String date           = FiscalHelper.instance().getDateFromTimestamp();
      String basePath       = "${(await getApplicationDocumentsDirectory()).path}/qfood-receipts/$date";
      Directory dirReceipts = Directory(basePath);

      if(!dirReceipts.existsSync()){
        dirReceipts.createSync(recursive: true);
      }

      String payloadContent = "INPUT\n\n$payload\n\n-----------------\n\nRESPONSE\n\n$response";

      String filename = overrideFilename ?? FiscalHelper.instance().getTimestampFileName();
      File("$basePath/$filename.txt").writeAsString(payloadContent);

    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }

  }


}
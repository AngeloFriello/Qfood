import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MbP17 {

  late final String   _terminalId;
  late final String   _ecr;
  Socket?             _socket;

  MbP17(this._terminalId, this._ecr);

  Future<bool> openConnection(String ip, int port) async {
    try{
      _socket = await Socket.connect(ip, port);
    }catch(e){

    }
    return _socket != null;
  }

  Future<void> _closeConnection() async {
    if(_socket != null){
      await _socket!.close();
    }
  }

  Future<void> forceCloseConnection() async {
    if(_socket != null){
      await _socket!.close();
    }
  }

  Future<void> payAndWait(
    {
      required int                      timeout,
      required double                   amount, 
      required bool                     useLegacy, 
      required bool                     printerFooter,
      String?                           offsetBytes,
      required Function()               onTimeout,
      required Function()               paymentFailed,
      required Function(String? output) paymentDone,
      bool?                             isSumup,
      String?                           idSumup,
      bool?                             isNexi,
      String?                           idNexi,
      String?                           nexiTerminalId
    }
  ) async {

    try{

      SharedPreferences preferences = await SharedPreferences.getInstance();
      bool printPosReceipt          = preferences.getBool("stampa_ricevuta_pos") ?? false;

      

      StringBuffer stringBuffer = StringBuffer();
      stringBuffer.write(_terminalId.padLeft(8, '0'));
      stringBuffer.write("0");
      stringBuffer.write(useLegacy ? 'P' : 'X');
      stringBuffer.write(_ecr.padLeft(8, '0'));
      stringBuffer.write("0");
      stringBuffer.write("00");
      stringBuffer.write("0");
      stringBuffer.write("0");

      String formattedAmount = amount.toStringAsFixed(2).replaceAll(".", "").padLeft(8 ,'0');
      stringBuffer.write(formattedAmount);
      stringBuffer.write(printerFooter ? '1' : '0');

      if(offsetBytes != null && offsetBytes.trim().isNotEmpty){
        stringBuffer.write(offsetBytes); // Some pos uses this type of footer end!
      }

      Uint8List payload     = ascii.encode(stringBuffer.toString());
      List<int> fullPacket  = [0x02, ...payload, 0x03];

      // Get LRC
      int lrc = 0x7F;
      for(int b in fullPacket){
        lrc ^= b;
      }
      fullPacket.add(lrc);

      Uint8List packet = Uint8List.fromList(fullPacket);

      // Send
      if(_socket != null){


        // Start timer for timeout of payment
        Timer timeoutChecker = 
          Timer(
            Duration(seconds: timeout), 
            (){
              _closeConnection();
              onTimeout();
            }
          );

        // Start reading stream
        bool getFirstAckCom = false;
        _socket!.listen((bytesFromIngenico){

          String stringReprestentation = ascii.decode(bytesFromIngenico);

          String normalizedResponse    = stringReprestentation.trim().toLowerCase();

          if(normalizedResponse.trim().toLowerCase().contains("annullata")){
            paymentFailed();
            _closeConnection();
            return;
          }

          bool exclude = normalizedResponse.contains("operazione") || normalizedResponse.contains("in corso");

          if(!exclude){
            if(!getFirstAckCom){
              getFirstAckCom = true;
              if(bytesFromIngenico[0] != 6){
                timeoutChecker.cancel();
                paymentFailed();
                _closeConnection();
              }
            }else{

              timeoutChecker.cancel();
              _closeConnection();


              // Response payment
              bool completedPayment = false;
              if(stringReprestentation.length >= 44){
                String letterStatus = stringReprestentation.substring(10, 11);
                String paid         = stringReprestentation.substring(11, 13);
                completedPayment    = letterStatus == "E" && paid == "00";
              }

              if(completedPayment){
                String? output = stringReprestentation;
                if(!printPosReceipt){
                  output = null;
                }
                paymentDone(output);
              }else{
                paymentFailed();
              }

            }
          }

        });

        _socket!.add(packet);
        await _socket!.flush();

      }

    }catch(e){
      debugPrint(e.toString());
    }

  }

  Future<void> reverseAndWait(
    {
      required int        timeout,
      required Function() onTimeout,
      required Function() reverseFailed,
      required Function() reverseDone
    }
  ) async {

    try{

      StringBuffer stringBuffer = StringBuffer();
      stringBuffer.write(_terminalId.padLeft(8, '0'));
      stringBuffer.write("0");
      stringBuffer.write('S');
      stringBuffer.write(_ecr.padLeft(8, '0'));
      stringBuffer.write('00000005'); // Stan
      stringBuffer.write('0');
      stringBuffer.write('0');

      Uint8List payload     = ascii.encode(stringBuffer.toString());
      List<int> fullPacket  = [0x02, ...payload, 0x03];

      // Get LRC
      int lrc = 0x7F;
      for(int b in fullPacket){
        lrc ^= b;
      }
      fullPacket.add(lrc);

      Uint8List packet = Uint8List.fromList(fullPacket);

      // Send
      if(_socket != null){

        // Start timer for timeout of payment
        Timer timeoutChecker = 
          Timer(
            Duration(seconds: timeout), 
            (){
              _closeConnection();
              onTimeout();
            }
          );

        // Start reading stream
        bool getFirstAckCom = false;
        _socket!.listen((bytesFromIngenico){

          String stringReprestentation = ascii.decode(bytesFromIngenico);
          

          if(!getFirstAckCom){
            getFirstAckCom = true;
            if(bytesFromIngenico[0] != 6){
              timeoutChecker.cancel();
              reverseFailed();
              _closeConnection();
            }
          }else{

            timeoutChecker.cancel();
            _closeConnection();

            // Response payment
            bool completedReverse = false;
            if(stringReprestentation.length >= 44){
              String letterStatus     = stringReprestentation.substring(10, 11);
              String reversed         = stringReprestentation.substring(11, 13);
              completedReverse        = letterStatus == "E" && reversed == "00";
            }

            if(completedReverse){
              reverseDone();
            }else{
              reverseFailed();
            }

          }

        });

        _socket!.add(packet);
        await _socket!.flush();

      }

    }catch(e){
      debugPrint(e.toString());
    }

  }

}

String decodeP17Sale(String raw, double amountPayment) {
  
  String output = "";

  try{

    String clean      = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    String terminalId = clean.substring(0, 8);
    //String fixed      = clean.substring(8, 9);
    //String mexCode    = clean.substring(9, 10);
    String statusTxn  = clean.substring(10, 12);
    String pan        = clean.substring(12, 31);
    String type       = clean.substring(31, 34);
    String authCode   = clean.substring(34, 40);
    String time       = clean.substring(40, 47);
    String cardType   = clean.substring(47, 48);
    String idAcquirer = clean.substring(48, 59);
    String stan       = clean.substring(59, 65);
    String onlineCode = clean.substring(65, 71);

    output = """
===============================
TRANSAZIONE ${statusTxn == "00" ? "APPROVATA" : "RIFIUTATA"}
===============================
Codice terminale: $terminalId
Codice auth     : $authCode
PAN             : $pan
Tipo transazione: $type
Tipo carta      : $cardType
ID acquirer     : $idAcquirer
Codice stan     : $stan
Numero online   : $onlineCode
Data            : ${time.substring(1, 3)}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year} ${time.substring(3, 5)}:${time.substring(5, 7)}
""";

  }catch(e){

    debugPrint(e.toString());
  }

  return output;
}
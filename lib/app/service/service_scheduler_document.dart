import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/ui/screen/scontrino/scontrino_service.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';

bool initServiceScheduler = false;

class ServiceSchedulerDocument {

  static ServiceSchedulerDocument? _instance;
  static ServiceSchedulerDocument instance () => _instance ??= ServiceSchedulerDocument();

  Future<void> schedule() async {

    try{
      //RECUPERO I DOCUMENTI NON INVIATI DAL DB LOCALE E TENTO L INVIO AL BACKOFFICE
      List<Map<String, dynamic>> docForSendToDB = await  LocalDB.query('SELECT * FROM documents WHERE idReal is NULL');
      List<Documento> documents = docForSendToDB.map((d) => Documento.fromJsonLocaDB(d)).toList();

      documents.forEach((d) async {
        if( d.overrideMovementType == 'cancel_rt'){
          //CONTROLLARE SE ALLO SCONTRINO ORIGINALE é STATO ASSEGNATO UN IDREAL
          final resp = await LocalDB.query('SELECT * FROM documents WHERE id = ${d.idDocumentReference}');
          if( resp.isNotEmpty && resp[0]['idReal'] != null ){
            //AGGIORNO IL RIFERIMENTO REALE DELLO SCONTRINO CANCELLATO
            final respUpdate = await LocalDB.queryUpdate('UPDATE documents SET idDocumentReference = ${resp[0]['idReal']} WHERE id = ${d.id}');
            if(respUpdate > 0 ){
              d.idDocumentReference = resp[0]['idReal'];
              ScontrinoService.sendPrint(d);
            }
          }
          return;
        }

        if( d.overrideMovementType == 'credit_note'){
          //CONTROLLARE SE ALLA FATTURA ORIGINALE é STATO ASSEGNATO UN IDREAL
          final resp = await LocalDB.query('SELECT * FROM documents WHERE id = ${d.idDocumentReference}');
          if( resp.isNotEmpty && resp[0]['idReal'] != null ){
            //AGGIORNO IL RIFERIMENTO REALE DELLA FATTURA CANCELLATA CANCELLATO
            final respUpdate = await LocalDB.queryUpdate('UPDATE documents SET idDocumentReference = ${resp[0]['idReal']} WHERE id = ${d.id}');
            if(respUpdate > 0 ){
              d.idDocumentReference = resp[0]['idReal'];
              ScontrinoService.sendPrint(d);
            }
          }
          return;
        }
        ScontrinoService.sendPrint(d);
      });
    
      // ... Operazione
      debugPrint("Servizio documenti...");

    }catch(e){
      debugPrint(e.toString());
    }finally{
      await Future.delayed(Duration(seconds: 3));
      await schedule();
    }
  }

}
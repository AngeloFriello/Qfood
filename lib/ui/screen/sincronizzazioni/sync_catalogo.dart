import 'dart:async';
import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/modelli/article.dart';
import 'package:dashboard/modelli/articlePriceList.dart';
import 'package:dashboard/modelli/category.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/modelli/department.dart';
import 'package:dashboard/modelli/device.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/modelli/payment.dart';
import 'package:dashboard/modelli/pos.dart';
import 'package:dashboard/modelli/printer.dart';
import 'package:dashboard/modelli/room.dart';
import 'package:dashboard/modelli/settingPos.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/modelli/vatRate.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../config/costanti.dart';
import 'databasesql_lite/local_db.dart';
import 'pos_sync_service.dart';

  class SyncController extends ChangeNotifier {
    List<String>    errors            = [];
    int     currentGlobalStep = 0;
    int     totalGlobalSteps  = 16; // pos server, syncOperatori, Categorie, VatRates, Pagamenti, Articoli, Departments, SettingStore, PriceList,Dispositivo corrente, articolo generico, sale, stampanti
    String? currentGlobalTask;
    bool    isSyncing = false;
    VoidCallback? onSyncComplete;
    double _globalProgress = 0.0;
    double get globalProgress => _globalProgress;
    
    void finishSync() {
      Timer(Duration(seconds: 3), ()=> {
        notifyListeners(),
        _globalProgress   = 0.0,
        currentGlobalStep = 0,
        if( errors.isEmpty ){
          onSyncComplete?.call()
        }
      });
    }

    void startSyncAll() {
      errors.clear();
      isSyncing = true;
      currentGlobalStep = 0;
      notifyListeners();
    }
    
    void nextGlobalStep(String taskName) {
      currentGlobalTask = taskName;
      currentGlobalStep++;
      _globalProgress = totalGlobalSteps > 0 ? currentGlobalStep / totalGlobalSteps : 0.0;
      notifyListeners();
    }

    void addError(String error){
      errors.add(error);
      notifyListeners();
    }
    
  }


class SyncCatalogo {
  static List safeList(dynamic s) => (s is List) ? s : [];

  // ===============================================================
  //  SYNC COMPLETO
  // ===============================================================
  static Future<void> syncAll(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final syncController = context.read<SyncController>();

    // IMPORTANTE: serve per operatori   + pagamenti
    final idStore   = prefs.getInt("idStore");
    final idDevice  = prefs.getInt("idDevice");
    if (idStore == null || idDevice == null ) {
      Navigator.pushNamedAndRemoveUntil(context,'/',(route) => false);
      debugPrint(
          "❌ ERRORE: idStore NON impostato! Devi chiamare prefs.setInt('idStore', ID) prima di syncAll().");
      return;
    }

    syncController.startSyncAll();
    await syncOperatori( syncController );
    syncController.nextGlobalStep("Operatori");
    await syncCategorie( syncController );
    syncController.nextGlobalStep("Categorie");
    await syncVatRates( syncController );
    syncController.nextGlobalStep("Aliquote");
    await syncPagamenti( syncController );
    syncController.nextGlobalStep("Pagamenti");
    await syncArticoli( syncController );
    syncController.nextGlobalStep("Articoli");
    await syncDepartments( syncController );
    syncController.nextGlobalStep("Reparti");
    await syncSettingStore( syncController );
    syncController.nextGlobalStep("Impostazioni punto vendita");
    await syncPriceList( syncController );
    syncController.nextGlobalStep("Listini");
    await syncCustomer( syncController );
    syncController.nextGlobalStep("Clienti");
    await _getDeviceDetails( idDevice , syncController);
    syncController.nextGlobalStep("Dispositivo corrente");
    await syncGenericArticle(syncController);
    syncController.nextGlobalStep("Articolo generico");
    await syncRooms(syncController);
    syncController.nextGlobalStep("Sale e tavoli");
    await caricaDispositivi();
    syncController.nextGlobalStep("Dispositivi");
    await syncPrinterForArticle(syncController);
    syncController.nextGlobalStep("Stampanti");
    await startServer(syncController);
    syncController.nextGlobalStep("Avvio server");
    await syncPos(syncController);
    syncController.nextGlobalStep("Dispositivi di pagamento");
    syncController.finishSync();

    listsPrice = await ListPriceModel.getByDb();
  }



  //START SERVER
 static Future<void> startServer( SyncController ? controllerSync )async{
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      dynamic device   = jsonDecode(pref.getString('device') ?? '{}');
      if( device == null || device.isEmpty ) return;
      int isServer = device['deviceServer']; 

      //START DEL SERVER SE SI TRATTA DI UN SERVER
      if( isServer == 1 ){
        await ServiceWsServer.instance().reset();
        ServiceWsServer.instance().start(); 
      }
      
    }catch( err ){
      debugPrint(err.toString());
    }
  }

      // ===============================================================
  // POS
  // ===============================================================
  static Future<void> syncPos( SyncController ? controllerSync ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      final idStore = prefs.getInt("idStore");
      if (istanza == null || token == null) {
        debugPrint("❌ Istanza o token mancanti");
        return;
      }

        final url = "https://$istanza-api.qfood.it/api/v1/posEcr17/listPos/ac6f0972c813?idStore=${idStore}";
        final res = await http.get(
          Uri.parse(url),
          headers: {
            "x-api-key": posApiKey,
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ Errore SYNC STAMPANTI HTTP");
          controllerSync?.addError("Errore  SYNC STAMPANTI HTTP");
          return;
        }
      final decoded = jsonDecode(res.body);
      final List<dynamic> ecr17    = safeList(decoded["data"]['ecr17'] ?? []);
      final List<dynamic> dojo     = safeList(decoded["data"]['dojo']  ?? []);
      List<PosModel> pos = [];
      posGlobal = pos;
      ecr17.forEach((ec) {
        pos.add(PosModel.fromJson(ec,'ecr17'));
      });

      dojo.forEach((d) {
        if( ["Offline"].contains(d["status"]) ) return;
        pos.add(PosModel.fromJson(d,'dojo'));
      });
      
      final List<Map<String, dynamic>> pos_  = pos.map((o) => o.toMap() ).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI 
      if( pos_.isNotEmpty ) await LocalDB.replaceTable("pos",   pos_).catchError(  (err) { debugPrint(err.toString()); controllerSync?.addError(err.toString());} );
    } catch (e, s) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncPOS: $e");
      debugPrint("$s");
    }
  }


    // ===============================================================
  // STAMPANTI DI RIFERIMENTO PER OGNI ARTICOLO se LA CATEGORIA NON HA LA STAMPANTE LA PRENDE DEL PRODOTTO
  // ===============================================================
  static Future<void> syncPrinterForArticle( SyncController ? controllerSync ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      final idStore = prefs.getInt("idStore");
      if (istanza == null || token == null) {
        debugPrint("❌ Istanza o token mancanti");
        return;
      }

        final url = "https://$istanza-api.qfood.it/api/v1/pos/syncArticlePrinter/f23c3172b9e9?idStore=${idStore}";
        final res = await http.get(
          Uri.parse(url),
          headers: {
            "x-api-key": posApiKey,
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ Errore SYNC STAMPANTI HTTP");
          controllerSync?.addError("Errore  SYNC STAMPANTI HTTP");
          return;
        }

      final decoded = jsonDecode(res.body);
      final List<dynamic> dataPrinters  = safeList(decoded["data"] ?? []);
      List<PrinterForArticle> temp = dataPrinters.map((o) => PrinterForArticle.fromMap(o) ).toList();
      final List<Map<String, dynamic>> printers  = dataPrinters.map((o) => PrinterForArticle.fromMap(o).toMap() ).toList();
      printersArticle = temp;
      //SE VUOTO NON SOVRASCRIVO I DATI 
      if( printers.isNotEmpty ) await LocalDB.replaceTable("articlePrinter",   printers).catchError(  (err) => debugPrint(err.toString()) );
    } catch (e, s) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncArticlePrinter: $e");
      debugPrint("$s");
    }
  }


  static  Future<void> caricaDispositivi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token =   prefs.getString("token");
      final istanza = prefs.getString("istanza");
      final idStore = prefs.getInt("idStore");
      List<Map<String, dynamic>>   allDevices = [];
      int   skip       = 0; 
      bool  more       = true;

      if (token == null || istanza == null || idStore == null) {

        return;
      }


      do {
        try{
        
          final url = "https://$istanza-api.qfood.it/api/v1/device/listDevice/1f0dd933c331?skip=$skip&take=100&idStoreFilter=${idStore}";
          debugPrint("💻 Recupero dispositivi → $url");

          final res = await http.get(
            Uri.parse(url),
            headers: {
              "Authorization": "Bearer $token",
              "x-api-key": defaultApiKey,
            },
          );

          skip++;

          debugPrint("📦 Device response ${res.statusCode}: ${res.body}");

          if (res.statusCode != 200) {

            return;
          }

          final json    = jsonDecode(res.body);
          if( json['data'] != null && json['data']['records'] != null && json['data']['records'].length == 0){
            more = false;
          }else{
            final lista = List<Map<String, dynamic>>.from(json['data']['records']);
            allDevices.addAll( lista );
          }

          }catch(err){
            more = false;
          }
      } while (more);
      
      if( allDevices.isNotEmpty ) LocalDB.replaceTable('devices', allDevices.map((d) => Device(id: d['id'], title: d['title'], server: d['server']).toMap() ).toList( ));

    } catch (e) {

    }
  }

   // ===============================================================
  //  SYNC ROOMS
  // ===============================================================
  static Future<void> syncRooms( SyncController ? controllerSync ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      final idStore = prefs.getInt("idStore");
      if (istanza == null || token == null) {
        debugPrint("❌ Istanza o token mancanti");
        return;
      }

        final url = "https://$istanza-api.qfood.it/api/v1/pos/syncRoomAndTables/9da799514b5e?idStore=${idStore}";
        final res = await http.get(
          Uri.parse(url),
          headers: {
            "x-api-key": posApiKey,
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ Errore SYNC Clienti HTTP");
          controllerSync?.addError("Errore SYNC Clienti HTTP");
          return;
        }

      final decoded = jsonDecode(res.body);
      final List dataRooms  = safeList( decoded["data"]['rooms'] ?? [] );
      final List dataTables = safeList( decoded["data"]['tables'] ?? [] );


      
      //GLI ATTUALI TAVOLI IN DB PER EVITARE LA CANCELLAZIONE 
      final respTablesInLocalDB = await LocalDB.query("SELECT * FROM tables");
     List<Map<String, dynamic>> tableInLocalDB = respTablesInLocalDB.map((t) => TableModel.fromMap(t).toMapForLocalDb() ).toList();
      
      List<Map<String, dynamic>> rooms  = dataRooms.map<Map<String,  dynamic>>((o)  => Room.fromMap(o).toMap() ).toList();
      List<Map<String, dynamic>> tables = dataTables.map<Map<String, dynamic>>((o)  => TableModel.fromMap(o).toMapForLocalDb() ).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( rooms.isNotEmpty )  await LocalDB.replaceTable("rooms",   rooms).catchError(  (err) => debugPrint(err.toString()) );


      final List<Map<String, dynamic>> tablesNew = tables.where((t) { dynamic exist = tableInLocalDB.any((tt) => tt['id'] == t['id'] );
        if(!exist) return true;
        return false;
      }).toList();

      
      final db =  await LocalDB.instance();
        await db.transaction ((txn) async {
        for (final row in tablesNew) {
          await txn.insert(
            'tables',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      
      //if( tables.isNotEmpty ) await LocalDB.replaceTable("tables", tables).catchError(  (err) => debugPrint(err.toString()) );
    } catch (e, s) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncOperatori: $e");
      debugPrint("$s");
    }
  }

  // ============================================================
  // RECUPERO ARTICOLO GENERICO 
  // ============================================================

  static Future<void> syncGenericArticle(SyncController ? controllerSync ) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");

      final url = "https://$istanza-api.qfood.it/api/v1/article/getGenericArticle/e6e762e354d4";

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "x-api-key": posApiKey,
          "Content-Type": "application/json",
          },
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ Errore syncGenericArticle");
          controllerSync?.addError("Errore syncStoreSetting");
          return;
        }

      final json = jsonDecode(res.body);
      if( !json['success'] || json['data'].isEmpty ){
        debugPrint("❌ Errore syncGenericArticle");
        controllerSync?.addError("Errore syncStoreSetting");
        return;
      }
      debugPrint( json.toString() );
      //LO SALVO IN LOCAL STORAGE
      prefs.setString('genericArticle', jsonEncode(json['data']));
    } catch (e) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncGenericArticle: $e");
    }
  }


  

  // ============================================================
  // RECUPERO DEVICE
  // ============================================================
  static Future<void> _getDeviceDetails(int idDevice_, SyncController? controllerSync) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final istanza = prefs.getString("istanza");

      if (token == null || istanza == null) {
        throw Exception("Token o istanza non trovati");
      }

      final url = "https://$istanza-api.qfood.it/api/v1/device/getDeviceById/3523afc211bf?idFilter=$idDevice_";

      debugPrint("🔍 Recupero dettagli device → $url");

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "x-api-key": defaultApiKey,
        },
      );

      if (res.statusCode != 200) {
        controllerSync?.addError("Errore syncDevice");
        throw Exception("Errore getDeviceById → HTTP ${res.statusCode}");
      }

      final json = jsonDecode(res.body);

      if (json["success"] != true) {
        throw Exception("Device non trovato");
      }

      // FOCUS: il device è dentro data.record
      final record = json["data"]?["record"]; 
      if (record == null) throw Exception("Record mancante nel device");

      final record_ = Map<String, dynamic>.from(record);
      final int idDevice      = record["id"];
      final String nomeDevice = record["title"] ?? "Device";

      // =========================
      // 2️⃣ PERSISTENZA
      // =========================
      
      //Salvo intero device
      await prefs.setString('device', jsonEncode(record_));
      deviceCurrent = record_;
      //Usati da marco verificare eliminazione
      await prefs.setInt("idDevice", idDevice);
      await prefs.setString("deviceName", nomeDevice);
      await prefs.setBool("deviceSelected", true);
    
    }catch( err ){
      controllerSync?.addError("Errore syncDevice");
    }
  }

  // ===============================================================
  //  SYNC IMPOSTAZIONI PUNTO VENDITA  OK
  // ===============================================================
  static Future<void> syncSettingStore(SyncController ? controllerSync ) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");
      final idStore = prefs.getInt("idStore");

      final url = "https://$istanza-api.qfood.it/api/v1/pos/getStoreSettings/7eedb360c605?idStore=$idStore";

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "x-api-key": posApiKey,
          "Content-Type": "application/json",
          },
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ Errore syncStoreSetting");
          controllerSync?.addError("Errore syncStoreSetting");
          return;
        }

      final json = jsonDecode(res.body);
      SettingStoreModel setting = SettingStoreModel.fromJson( json['data'] );
      settingStore = setting;
      prefs.setString('settingStore', jsonEncode(setting));
    } catch (e) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncSettingStore: $e");
    }
  }

  // ===============================================================
  //  SYNC LISTINI DISPONIBILI  OK
  // ===============================================================
  static Future<void> syncPriceList(SyncController ? controllerSync ) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");

      final url = "https://$istanza-api.qfood.it/api/v1/pos/syncPriceList/8eb4e540a537";


      final res = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "x-api-key": posApiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode(
            { 
              "skip": 0, 
              "lastSync": null, 
              "idStore": prefs.getInt("idStore")
            }),
      );


      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint("❌ Errore syncListini");
        controllerSync?.addError("Errore sync Listini");
        return;
      }

      final json = jsonDecode(res.body);
      List list  = safeList(json["data"] ?? []) ;
      List<Map<String, Object?>>  rows  = list.map((list) => ListPriceModel.fromJson(list).toMap()).toList();

      //SE VUOTO NON SOVRASCRIVO I DATI
      if( rows.isNotEmpty ) await LocalDB.replaceTable("listPrice", rows)
                      .catchError((error) => debugPrint(error.toString()));

    } catch (e) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncListini: $e");
    }
  }

  // ===============================================================
  //  SYNC PAGAMENTI  OK
  // ===============================================================
  static Future<void> syncPagamenti(SyncController ? controllerSync ) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");

      // GUID CORRETTO (da tua cURL)
      const guid = "dfbb0dabfc9d";

      final url = "https://$istanza-api.qfood.it/api/v1/pos/syncPayments/$guid";

      debugPrint("💳 SYNC PAGAMENTI → POST $url");

      final res = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "x-api-key": posApiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode(
            {"skip": 0, "lastSync": null, "idStore": prefs.getInt("idStore")}),
      );

      debugPrint("📥 RISPOSTA PAGAMENTI: ${res.statusCode}");
      debugPrint("📥 BODY: ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint("❌ Errore syncPagamenti");
        controllerSync?.addError("Errore syncPagamenti");
        return;
      }

      final json = jsonDecode(res.body);
      List list  = safeList(json["data"] ?? []) ;

      List<Map<String, Object?>>  rows  = list.map((pay) => PaymentModel.fromJson(pay).toMap()).toList();

      //SE VUOTO NON SOVRASCRIVO I DATI
      if( rows.isNotEmpty ) await LocalDB.replaceTable("payments", rows);

      debugPrint("💳 Pagamenti salvati in DB: ${rows.length}");
    } catch (e) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncPagamenti: $e");
    }
  }

  // ===============================================================
  //  SYNC CLIENTI ok Skip
  // ===============================================================
  static Future<void> syncCustomer( SyncController ? controllerSync ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      int  skip = 0;
      List results = [];
      bool more   = true;

      if (istanza == null || token == null) {
        debugPrint("❌ Istanza o token mancanti");
        return;
      }

      do {
        final url =
            "https://$istanza-api.qfood.it/api/v1/pos/syncCustomers/74a42b1c09b2";

        final res = await http.post(
          Uri.parse(url),
          headers: {
            "x-api-key": posApiKey,
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "skip": skip,
            "lastSync": null,
          }),
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ Errore SYNC Clienti HTTP");
          controllerSync?.addError("Errore SYNC Clienti HTTP");
          return;
        }
        
        skip++;

        final decoded = jsonDecode(res.body);

        final List data = safeList( decoded["data"]['customers'] ?? [] );

        if( data.isEmpty ) more = false;
        results.addAll(data);
      } while (more);

      final List<Map<String, dynamic>> customers = results.map<Map<String, dynamic>>((o) => CustomerModel.fromJson(o).toMap() ).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( customers.isNotEmpty ) await LocalDB.replaceTable("customers", customers).catchError( (err) => debugPrint(err.toString()) );
 
    } catch (e, s) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncOperatori: $e");
      debugPrint("$s");
    }
  }

  // ===============================================================
  //  SYNC OPERATORI ok Skip
  // ===============================================================
  static Future<void> syncOperatori( SyncController ? controllerSync ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      int  skip = 0;
      List results = [];
      bool more   = true;

      if (istanza == null || token == null) {
        debugPrint("❌ Istanza o token mancanti");
        return;
      }

      do {
        const guid = "1f37de1a46b6";
        final url = "https://$istanza-api.qfood.it/api/v1/pos/syncOperators/$guid";

        final res = await http.post(
          Uri.parse(url),
          headers: {
            "x-api-key": posApiKey,
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "skip": skip,
            "lastSync": null,
            "idStore": prefs.getInt("idStore") ?? 0,
          }),
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          debugPrint("❌ Errore SYNC OPERATORI HTTP");
          controllerSync?.addError("Errore SYNC OPERATORI HTTP");
          return;
        }
        
        skip++;

        final decoded = jsonDecode(res.body);

        final List data = safeList( decoded["data"] ?? [] );

        if( data.isEmpty ) more = false;

        results.addAll(data);
      } while (more);

      final List<Map<String, dynamic>> operatoriCompleti = results.map<Map<String, dynamic>>((o) => OperatoreModel.fromJson(o).toMap() ).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( operatoriCompleti.isNotEmpty ) await LocalDB.replaceTable("operators", operatoriCompleti)
                          .catchError( (err)=> debugPrint(err.toString()) );

    } catch (e, s) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncOperatori: $e");
      debugPrint("$s");
    }
  }

  // ===============================================================
  //  SYNC CATEGORIE  OK Skip
  // ===============================================================
  static Future<void> syncCategorie(SyncController ? controllerSync ) async {
    try {
      final raw  = await PosSyncService.syncCategories();
      final list = safeList(raw["categories"]);
      final categoriesVariations = safeList(raw["categoriesVariations"]);
      final categoriesStoreDepartmentProduction = safeList(raw["categoriesStoreDepartmentProduction"]);

      List<Map<String, Object?>> categories = list.map((row) => CategoryModel.fromJson(row).toMap()).toList();

      //VARIANTI ABBINATE ALLE CATEGORIE
      List<Map<String, Object?>> categoriesVariationsForDb = categoriesVariations.map((row) => { 
                                                                                                  "idCategory" : row['idCategory'], 
                                                                                                  "idVariation" : row['idVariation'],  
                                                                                              }).toList();

      //STAMPANTI ABBINATE ALLA CATEGORIA PER SALA E BANCO. printFor= room | bench
      List<Map<String, Object?>> categoriesStoreDepartmentProductionForDb = categoriesStoreDepartmentProduction.map((row) => { 
                                                                                              "idCategory" : row['idCategory'], 
                                                                                              "idDepartmentProduction" : row['idDepartmentProduction'], 
                                                                                              "printFor" : row['printFor'],  
                                                                                              }).toList();

      //SE VUOTO NON SOVRASCRIVO I DATI
      if( categories.isNotEmpty ) await LocalDB.replaceTable("categories", categories);
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( categoriesVariationsForDb.isNotEmpty ) await LocalDB.replaceTable("categoriesVariations", categoriesVariationsForDb);
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( categoriesStoreDepartmentProductionForDb.isNotEmpty ) await LocalDB.replaceTable("categoriesStoreDepartmentProduction", categoriesStoreDepartmentProductionForDb);
      debugPrint("📦 Categorie salvate in DB: ${categories.length}");

    } catch (e) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncCategorie: $e");
    }
  }

  // ===============================================================
  //  SYNC IVA  OK
  // ===============================================================
  static Future<void> syncVatRates( SyncController ? controllerSync  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      final idStore = prefs.getInt("idStore");

      // GUID corretto fornito da te
      const guid = "355ba80ae161";

      final url = "https://$istanza-api.qfood.it/api/v1/pos/syncVatRate/$guid";

      debugPrint("🧾 SYNC VAT RATE → POST $url");

      final res = await http.post(
        Uri.parse(url),
        headers: {
          "x-api-key": posApiKey, // CHIAVE POS OK
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "skip": 0,
          "lastSync": "2025-01-01 00:00:00",
          "idStore": idStore, // aggiunto per coerenza QFood
        }),
      );

      debugPrint("📥 VAT response: ${res.statusCode}");
      debugPrint("📥 BODY → ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint("❌ Errore syncVatRates");
        controllerSync?.addError("Errore syncVatRates");
        return;
      }

      final json = jsonDecode(res.body);
      final list = safeList(json["data"] ?? []);
      List<Map<String,Object?>> vats = list.map((vat) => VatRateModel.fromJson(vat).toMap()).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( vats.isNotEmpty ) await LocalDB.replaceTable("vatRates", vats);

    } catch (e) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncVatRates: $e");
    }
  }

  // ===============================================================
  //  SYNC REPARTI  OK
  // ===============================================================
  static Future<void> syncDepartments(SyncController ? controllerSync ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      final idStore = prefs.getInt("idStore");
      final url = "https://$istanza-api.qfood.it/api/v1/pos/syncVatDepartments/f64a0f89259e?idStore=${idStore}";

      final res = await http.post(
        Uri.parse(url),
        headers: {
          "x-api-key": posApiKey, // CHIAVE POS OK
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint("❌ Errore syncDepartment");
        controllerSync?.addError("Errore syncDepartment");
        return;
      }

      final json = jsonDecode(res.body);
      final list = safeList(json["data"] ?? []);
      List<Map<String,Object?>> vats = list.map((vat) => DepartmentModel.fromJson(vat).toMap()).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( vats.isNotEmpty ) await LocalDB.replaceTable("vatDepartments", vats);

    } catch (e) {
      controllerSync?.addError(e.toString());
      debugPrint("❌ Errore syncDepartments: $e");
    }
  }

// ===============================================================
//  SYNC ARTICOLI OK skip
// ===============================================================

  static Future<void> syncArticoli(SyncController ? controllerSync ) async {
    try {
      final raw    = await PosSyncService.syncArticles();
      final list   = safeList(raw['articles']);
      List<Map<String, Object?>> articles = list.map((row) => ArticleModel.fromJson(row).toMap()).toList();
      List<ArticleModel> all =  list.map((row) => ArticleModel.fromJson(row)).toList();
      if( all.isNotEmpty ) allArticles = all;
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( articles.isNotEmpty ) await LocalDB.replaceTable("articles", articles);
     
      
      //POPOLO TABELLA CATEGORIA ARTICOLO idCategory id Article
      final listCatart   = safeList(raw['articlesCategories']);
      List<Map<String, Object?>> listCategoryArticle = listCatart.map((row) => { "idCategory": row['idCategory'],"idArticle": row['idArticle'] }).toList();
      if( listCategoryArticle.isEmpty ) return;
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( listCategoryArticle.isNotEmpty ) await LocalDB.replaceTable("articlesCategories", listCategoryArticle);

      //POPOLO TABELLA LISTINI
      final listPrice_   = safeList(raw['articlesPrices']);
      List<Map<String, Object?>> listprices = listPrice_.map((row) => ArticlePricesListModel.fromJson(row).toMap()).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( listprices.isNotEmpty ) await LocalDB.replaceTable("articlesPrices", listprices);

      //POPOLO TABELLA ABBINAMENTO ARTICOLI CON VARIANTI CATEGORIE
      final variationsArticleCategoriesList = safeList(raw['articlesVariationsCategories']);
      List<Map<String, Object?>> variationsArticleCategories = variationsArticleCategoriesList.map((row) => { "idArticle": row['idArticle'], "idCategory": row["idCategory"] }).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( variationsArticleCategories.isNotEmpty ) await LocalDB.replaceTable("articlesVariationsCategories", variationsArticleCategories);

       //POPOLO TABELLA ABBINAMENTO ARTICOLI CON VARIANTI 'default', 'mandatory', 'excluded'
      final variationsArticlesList = safeList(raw['articlesVariations']);
      List<Map<String, Object?>> variationsArticle = variationsArticlesList.map((row) => { 
                                                                                            "idArticle"   : row['idArticle'], 
                                                                                            "idVariation" : row["idVariation"], 
                                                                                            "joinType"    : row["joinType"],    //'default', 'mandatory', 'excluded'
                                                                                          }).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( variationsArticle.isNotEmpty ) await LocalDB.replaceTable("articlesVariations", variationsArticle);

      //POPOLO TABELLA ABBINAMENTO ARTICOLI ALLERGENI
      final articlesAllergensList = safeList(raw['articlesAllergens']);
      List<Map<String, Object?>> articlesAllergens = articlesAllergensList.map((row) => { 
                                                                                            "idArticle"   : row['idArticle'], 
                                                                                            "allergen"    : row["allergen"],
                                                                                          }).toList();
      //SE VUOTO NON SOVRASCRIVO I DATI
      if( articlesAllergens.isNotEmpty ) await LocalDB.replaceTable("articlesAllergens", articlesAllergens);
      return;

    } catch (e, s) {
      controllerSync?.addError(e.toString());
      controllerSync?.addError(s.toString());
      debugPrint("❌ Errore syncArticoli: $e");
      debugPrint(s.toString());
    }
  }

}

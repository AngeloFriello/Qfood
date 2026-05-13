// ============================================================
// STORE DEVICE SELECTOR — VERSIONE FINALE CORRETTA
// ============================================================

import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/device.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/costanti.dart';
import '../../../state/app_session_controller.dart';
import '../sincronizzazioni/sync_vista.dart';
import 'company_selector_vista.dart';
import 'package:provider/provider.dart';
import 'package:unique_device_identifier/unique_device_identifier.dart';

@RoutePage()
class StoreDeviceSelectorVista extends StatefulWidget {
  final int idStore;
  final String nomeStore;



  const StoreDeviceSelectorVista({
    super.key,
    required this.idStore,
    required this.nomeStore,
  });

  @override
  State<StoreDeviceSelectorVista> createState() =>
      _StoreDeviceSelectorVistaState();
}

class _StoreDeviceSelectorVistaState extends State<StoreDeviceSelectorVista> {
  List<Map<String, dynamic>> devices = [];
  bool loading = true;
  String? errore;

  @override
  void initState() {
    super.initState();
    caricaDispositivi();
  }

  // ============================================================
  // CARICO I DISPOSITIVI CON lookUpDevice
  // ============================================================
  Future<void> caricaDispositivi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final istanza = prefs.getString("istanza");
      List<Map<String, dynamic>>   allDevices = [];
      int   skip       = 0; 
      bool  more       = true;

      if (token == null || istanza == null) {
        setState(() {
          errore = "Token o istanza mancanti — rifai login.";
          loading = false;
        });
        return;
      }


      do {
        try{

        
          final url = "https://$istanza-api.qfood.it/api/v1/device/listDevice/1f0dd933c331?skip=$skip&take=100&idStoreFilter=${widget.idStore}";
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
            setState(() {
              errore = "Errore HTTP ${res.statusCode}";
              loading = false;
            });
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
 

      debugPrint("✅ Dispositivi trovati per store ${widget.idStore}: ${allDevices.length}");
      if( allDevices.isNotEmpty ) LocalDB.replaceTable('devices', allDevices.map((d) => Device(id: d['id'], title: d['title']).toMap() ).toList( ));
      setState(() {
        devices = allDevices;
        loading = false;
      });

      // Se vuoto → avvisa
      if (allDevices.isEmpty) {
        errore = "Nessun dispositivo associato a questo store.\n"
            "Controllare configurazione POS su QFOOD.";
      } 

    } catch (e) {
      setState(() {
        errore = "Errore durante il recupero dispositivi: $e";
        loading = false;
      });
    }
  }


  // ============================================================
  // RECUPERO DETTAGLI REALE DEL DEVICE
  // ============================================================
  Future<Map<String, dynamic>> _getDeviceDetails( int idDevice ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final istanza = prefs.getString("istanza");

    if (token == null || istanza == null) {
      throw Exception("Token o istanza non trovati");
    }

    final url = "https://$istanza-api.qfood.it/api/v1/device/getDeviceById/3523afc211bf?idFilter=$idDevice";

    debugPrint("🔍 Recupero dettagli device → $url");

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "x-api-key": defaultApiKey,
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Errore getDeviceById → HTTP ${res.statusCode}");
    }

    final json = jsonDecode(res.body);

    if (json["success"] != true) {
      throw Exception("Device non trovato");
    }

    // FOCUS: il device è dentro data.record
    final record = json["data"]?["record"];
    if (record == null) throw Exception("Record mancante nel device");

    return Map<String, dynamic>.from(record);
  }


  // ============================================================
  // 3ASSOCIA IDENTIFICATORE — FUNZIONA
  // ============================================================
  Future<bool> assignIdentifierToDevice( int idDevice ) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token = prefs.getString("token");
      final String? identifier = await UniqueDeviceIdentifier().getUniqueIdentifier();
    
      final url =
          "https://$istanza-api.qfood.it/api/v1/pos/assignIdentifierToDevice/721e70a5be69";

      final res = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
           "X-API-KEY": posApiKey,
        },
        body: jsonEncode({
          "identifier": identifier,
          "idDevice"  : idDevice,
        }),
      );

      if (![200, 201].contains(res.statusCode)) {
        return false;
      }
      return true;
    }catch(err){
      return false;
    }
  }


  Future<void> selezionaOperatoreCorretto() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString("operatori");

    if (raw == null) {
      debugPrint("⚠️ Nessun operatore scaricato");
      return;
    }

    final ops = List<Map<String, dynamic>>.from(jsonDecode(raw));

    final validi = ops.where((op) =>
    ( op["enabled"] == 1) && (op["trashed"] == 0 ) ).toList();

    if (validi.isEmpty) {
      debugPrint("❌ Nessun operatore valido nel POS!");
      return;
    }

    final idOp = validi.first["id"];

    await prefs.setInt("idOperator", idOp);
    debugPrint("👤 Operatore POS selezionato → $idOp");
  }


  // ============================================================
  //  SELEZIONE DEVICE
  // ============================================================
  Future<void> _selezionaDevice(Map<String, dynamic> device) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      bool assigned = await assignIdentifierToDevice(device['id']);
      if( !assigned ){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Errore abbinamento device")),
        );
        return;
      }
      // =========================
      // 1️⃣ DETTAGLI DEVICE 
      // =========================
      final record = await _getDeviceDetails(device["id"]);

      final int idDevice      = record["id"];
      final String nomeDevice = record["title"] ?? "Device";

      // =========================
      // 2️⃣ PERSISTENZA
      // =========================
      
      //Salvo intero device
      await prefs.setString('device', jsonEncode(record));
      deviceCurrent = record;
      //Usati da marco verificare eliminazione
      await prefs.setInt("idDevice", idDevice);
      await prefs.setString("deviceName", nomeDevice);
      await prefs.setBool("deviceSelected", true);

      debugPrint("🟢 Device selezionato → $nomeDevice ($idDevice)");

      // =========================
      // 3️⃣ SESSIONE GLOBALE
      // =========================
      context.read<AppSessionController>().setDevice(
        id: idDevice,
        name: nomeDevice,
      );

      final session = context.read<AppSessionController>();
      debugPrint(
        "SESSION → store=${session.storeName}, device=${session.deviceName}",
      );

      // =========================
      // 4️⃣ VAI ALLA SCHERMATA DI SYNC
      // =========================
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SyncVista(
            endpoints: [
              "syncOperators/1f37de1a466b",
              "syncPayments/dfbb0dabfc9d",
              "syncCategories/b0dd9f9ec9bd",
              "syncVatRate/355ba80ae161",
              "syncArticle/ae311ca96936",
            ],
          ),
        ),
      );
    } catch (e, s) {
      debugPrint("❌ Errore selezione device: $e");
      debugPrint("$s");
    }
  }




  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF181818) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BC540),
        centerTitle: true,
        title: Text(
          "Dispositivi — ${widget.nomeStore}",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/logosuverde.png' //  dark mode
                  : 'assets/logosuverde.png', // ️ light mode

              height: 60,
            ),
          ),
        ],



        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CompanySelectorVista()),
            );
          },
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errore != null
          ? Center(
        child: Text(
          errore!,
          style: TextStyle(
            color: dark ? Colors.red[300] : Colors.red[800],
            fontSize: 16,
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: devices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
            MediaQuery.of(context).size.width < 600 ? 1 : 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, i) {
            final d = devices[i];
            return _DeviceCard(
              nome: d["title"] ?? "Sconosciuto",
              tipo: d["deviceType"] ?? "—",
              id: d["id"].toString(),
              onTap: () => _selezionaDevice(d),
              identifier: d['identifier'],
            );
          },
        ),
      ),
    );
  }
}

String getTitleTyperDevice ( String type ){
  switch (type) {
    case 'cash_pos':   return 'Postazione cassa';
    case 'waiter_pos': return 'Palmare cameriere';
    case 'room_pos':   return 'Postazione sala';
    case 'external_display': return 'Display esterno';
    case 'self_ordering': return 'Self ordering';
    case 'kiosk' : return 'Totem';
    case 'waiting_list' : return 'Lista attesa';
    default: return '';
  }
}

// ============================================================
// CARD DEVICE
// ============================================================
class _DeviceCard extends StatelessWidget {
  final String nome;
  final String tipo;
  final String id;
  final VoidCallback onTap;
  final String? identifier;

  const _DeviceCard({
    required this.nome,
    required this.tipo,
    required this.id,
    required this.onTap,
    this.identifier
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: dark ? const Color(0xFF262626) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.devices, size: 32, color: Colors.blue),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                nome,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                getTitleTyperDevice(tipo),
                style: TextStyle(
                  fontSize: 13,
                  color: dark ? Colors.white60 : Colors.grey[700],
                ),
              ),
              const Spacer(),
              Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ID: $id"),
                  Text("Dispositivo: "+ (identifier ?? 'Non abbinato') ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

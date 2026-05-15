import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:dashboard/state/app_session_controller.dart';
import 'package:dashboard/ui/screen/store_e_dispositivi/store_device_selector_vista.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/costanti.dart';
import 'company_selector_vista.dart';
import 'package:provider/provider.dart';

@RoutePage()
class StoreSelectorVista extends StatefulWidget {
  final int idAzienda;
  final String nomeAzienda;

  const StoreSelectorVista({
    super.key,
    required this.idAzienda,
    required this.nomeAzienda,
  });

  @override
  State<StoreSelectorVista> createState() => _StoreSelectorVistaState();
}

class _StoreSelectorVistaState extends State<StoreSelectorVista> {
  List<Map<String, dynamic>> stores = [];
  bool loading = true;
  String? errore;

  @override
  void initState() {
    super.initState();
    _caricaPuntiVendita();
  }

  Future<void> _caricaPuntiVendita() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final istanza = prefs.getString("istanza");

      if (token == null || istanza == null) {
        setState(() {
          errore = "Token o istanza mancanti — rifai login.";
          loading = false;
        });
        return;
      }

      final url =
          "https://$istanza-api.qfood.it/api/v1/store/listStore/44b4abc2556d?skip=0&take=100&filterIdCompany=${widget.idAzienda}";
      debugPrint("🏪 Richiesta punti vendita → $url");

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "x-api-key": defaultApiKey,
        },
      );

      debugPrint("📦 Store response ${res.statusCode}: ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final records = json["data"]?["records"];

        if (json["success"] == true && records != null) {
          final list = List<Map<String, dynamic>>.from(records);
          // ID azienda scelto nella schermata precedente
          final int idAzienda = widget.idAzienda;


          debugPrint("🏪 Store totali: ${list.length}");
          debugPrint(
              "🏪 Store filtrati per azienda $idAzienda → ${list.length}");

        // aggiorniamo la UI
          setState(() {
            stores = list;
            loading = false;
          });
        } else {
          setState(() {
            errore = json["verboseMessage"] ?? "Nessun punto vendita trovato.";
            loading = false;
          });
        }
      } else {
        setState(() {
          errore = "❌ Errore HTTP ${res.statusCode}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errore = "❌ Errore durante la richiesta: $e";
        loading = false;
      });
    }
  }

  Future<void> _selezionaStore(Map<String, dynamic> store) async {
    final prefs = await SharedPreferences.getInstance();

    final int idStore = store["id"] ?? 0;
    final String nomeStore = store["title"] ?? "Senza nome";
    final String guidStore = store["guid"]?.toString() ?? "";

    // =========================
    // SALVATAGGIO STORE (PERSISTENZA)
    // =========================
    ///api/v1/store/getDefaultPriceListStore/d0c6115d4330?idStore=104 // CHIAMATA PER RECUPERARE LISTINI DEFAULT
    final istanza = prefs.getString("istanza");
    final token = prefs.getString("token");

    final url = "https://$istanza-api.qfood.it/api/v1/store/getDefaultPriceListStore/d0c6115d4330?idStore=${idStore}";
        final resListPriceDefault = await http.get(
          Uri.parse(url),
          headers: {
            "x-api-key": posApiKey,
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

    dynamic listPricesDefault;
    if( resListPriceDefault.statusCode == 200 ){
      final body = jsonDecode(resListPriceDefault.body);
      listPricesDefault = body['data'];
    } ;


    Map<String, dynamic> storeAndListPrice = {...store, ...listPricesDefault };
    prefs.setString('store',jsonEncode(storeAndListPrice));

    //Salvati da marco non so se vendono utilizzati
    await prefs.setInt("idStore", idStore);
    await prefs.setString("storeTitle", nomeStore);
    await prefs.setString("storeGuid", guidStore);
    await prefs.setBool("storeSelected", true);

    debugPrint("🏪 Store selezionato → $nomeStore ($idStore)");

    // =========================
    //  FIX CHIAVE: SESSIONE GLOBALE
    // =========================
    context.read<AppSessionController>().setStore(
          id: idStore,
          name: nomeStore,
        );

    final s = context.read<AppSessionController>();
    debugPrint("SESSION → store=${s.storeName}, device=${s.deviceName}");

    // =========================
    // 1) SINCRONIZZO OPERATORI
    // =========================
    //  await SyncCatalogo.syncOperatori();

    // =========================
    // 2) LEGGO operatori salvati
    // =========================

    // =========================
    // VAI A SELEZIONE DEVICE
    // =========================
    //  lo fai scegliere DOPO la sync completa
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDeviceSelectorVista(
          idStore: idStore,
          nomeStore: nomeStore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BC540), // 💚 verde C50 M0 Y100 K0
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                reverseTransitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const CompanySelectorVista(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0); // 👈 entra da sinistra
                  const end = Offset.zero;
                  final tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: Curves.easeInOutCubicEmphasized));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
        ),

        title: const Text(
          "Seleziona Store",
          style: TextStyle(
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
                  ? 'assets/logosuverde.png' // 🌙 dark mode
                  : 'assets/logosuverde.png', // ☀️ light mode

              height: 60,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errore != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      errore!,
                      style: TextStyle(
                        color: dark ? Colors.red[300] : Colors.red[800],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 3;
                      if (constraints.maxWidth < 900) crossAxisCount = 2;
                      if (constraints.maxWidth < 600) crossAxisCount = 1;

                      return GridView.builder(
                        itemCount: stores.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, i) {
                          final s = stores[i];
                          final id = s["idStore"] ?? s["id"] ?? "-";
                          final nome = s["title"] ?? s["name"] ?? "Senza nome";
                          final indirizzo = s["address"] ?? "";

                          return _StoreCard(
                            nome: nome,
                            id: id.toString(),
                            indirizzo: indirizzo,
                            dark: dark,
                            onTap: () => _selezionaStore(s),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final String nome;
  final String id;
  final String indirizzo;
  final bool dark;
  final VoidCallback onTap;

  const _StoreCard({
    required this.nome,
    required this.id,
    required this.indirizzo,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color verdeFlex = const Color(0xFF95C01F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: verdeFlex.withOpacity(dark ? 0.05 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: verdeFlex.withOpacity(0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: verdeFlex.withOpacity(0.15),
                  radius: 22,
                  child: Icon(
                    Icons.storefront_rounded,
                    color: verdeFlex,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: dark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              nome,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
            if (indirizzo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  indirizzo,
                  style: TextStyle(
                    fontSize: 13,
                    color: dark ? Colors.white60 : Colors.grey[700],
                  ),
                ),
              ),
            const Spacer(),
            Divider(color: dark ? Colors.white10 : Colors.grey[200]),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 15),
                const SizedBox(width: 4),
                Text(
                  "ID: $id",
                  style: TextStyle(
                    fontSize: 13,
                    color: dark ? Colors.white70 : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

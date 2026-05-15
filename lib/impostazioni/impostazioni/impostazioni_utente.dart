/* 
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/sync_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Global.dart';
import '../../app/theme/controllers/theme_controller.dart';
import '../../config/costanti.dart';
import '../../modelli/listPrice.dart';
import '../../state/controller_impostazioni.dart';
import '../../ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import '../../ui/screen/sincronizzazioni/operatori/operator_preferences_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../ui/widget/header_footer/ControllerListPriceSelected.dart';



class ImpostazioniUtente extends StatefulWidget {
  const ImpostazioniUtente({super.key});

  @override
  State<ImpostazioniUtente> createState() => _ImpostazioniUtenteState();
}


class _ImpostazioniUtenteState extends State<ImpostazioniUtente> {
 /*  List<ListPriceModel> listini = []; */

  @override
  void initState() {
    super.initState();
   /*  _loadListini(); */
  }

/*   Future<void> _loadListini() async {
    listini = await ListPriceModel.getByDb();
    setState(() {});
  } */

  @override
  Widget build(BuildContext context) {
    final imp = context.watch<ImpostazioniController>();

    final op = context.watch<OperatorPreferencesController>();

    final isDark = imp.darkMode || Theme.of(context).brightness == Brightness.dark;
    const verde = Color(0xFF95C01F);
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF7F7F2);
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;
    final controllerListPrice = context.watch<ControllerListPriceSelected>();
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: verde,
        title: const Text("Impostazioni utente",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),

      body: imp.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(18),
        children: [

          // =====================================================
          // CONFIGURAZIONE GENERALE
          // =====================================================
// =====================================================
// CONFIGURAZIONE GENERALE
// =====================================================
          _titolo("Configurazione generale", text),

          _switch(
            "Nome breve prodotti",
            imp.nomeBreveProdotti,
                (v) {
              imp.aggiorna('nomeBreveProdotti', v);
              op.smallProductName = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          _dropdown(
            "Grandezza nome prodotti",
            imp.grandezzaNomeProdotti,
            ["S", "M", "L"],
                (v) async {
              if (v == null) return;

              await imp.aggiorna('grandezzaNomeProdotti', v);

              //  QUESTO È LA CHIAVE
              imp.notifyListeners();
            },
            card,
            text,
          ),

          _dropdown(
            "Grandezza nome breve prodotti",
            imp.grandezzaNomeBreveProdotti,
            ["S", "M", "L"],
            imp.nomeBreveProdotti
                ? (v) => imp.aggiorna('grandezzaNomeBreveProdotti', v)
                : null,
            card,
            text,
          ),

          _dropdown(
            "Lato interfaccia",
            imp.uiSide,
            ["R", "L"],
                (v) {
              imp.aggiorna('uiSide', v ?? "R");
            },
            card,
            text,
          ),

          _switch(
            "Carrello esteso",
            imp.carrelloInvertito,
                (v) {
              imp.carrelloInvertito = v;
              imp.notifyListeners();

              imp.aggiorna('carrelloInvertito', v);
            },
            card,
            text,
            verde,
          ),

          _switch(
            "Stampa comande di default da banco",
            imp.stampaComandeBanco,
                (v) => imp.aggiorna('stampaComandeBanco', v),
            card,
            text,
            verde,
          ),

          const SizedBox(height: 18),

// =====================================================
// FUNZIONALITÀ POS
// =====================================================
          _titolo("Funzionalità POS", text),

          _switch(
            "Sconto su banco/tavoli",
            op.discountBenchTable,
                (v) {
              op.discountBenchTable = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          _switch(
            "Pulsante rapido contanti",
            op.rapidButtonCash,
                (v) {
              op.rapidButtonCash = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          Card(
            color: card,
            child: ListTile(
              title: Text("Cambio rapido listino", style: TextStyle(color: text)),

              trailing: DropdownButton<ListPriceModel?>(
                value: listsPrice.contains(controllerListPrice.listPriceSelected) ? controllerListPrice.listPriceSelected : null,
                hint: const Text("Seleziona listino"),
                underline: const SizedBox(),

                items:[ 
                  DropdownMenuItem<ListPriceModel?>(
                    value: null,
                    child: Text('Seleziona listino'),
                  ), 
                  ...listsPrice.where((list) => list.counterpart == 'customer').toList().map((list) {
                    return DropdownMenuItem<ListPriceModel>(
                      value: list,
                      child: Text(list.title),
                    );
                  }).toList(),],

                onChanged: (ListPriceModel? selected_) async {
                  if (selected_ == null) return;
                  /* final controllerCart      = context.read<CarrelloController>(); */
                  controllerListPrice.listPriceSelected  = selected_;
                  /* bool confirm = true;
                  if (controllerCart.prodotti.isNotEmpty) {
                    List<ProdottoCarrello> oldProducts = [...controllerCart.prodotti];
                    String query = """SELECT 
                              art.*, 
                              lp.*  
                            FROM articles art
                            INNER JOIN articlesPrices lp 
                              ON lp.idArticle = art.id 
                              AND lp.idPriceList = ${selected_.id}
                          """;
                    final resp = await LocalDB.query(query).catchError((_) => []);

                    List<ArticleWhitPriceListModel> articles =
                    resp.map((e) => ArticleWhitPriceListModel.fromJson(e)).toList();

                    bool priceZero = false;

                    for (var oldProd in oldProducts) {
                      final exist = articles.where(
                            (a) => a.id == oldProd.article.id,
                      ).isNotEmpty
                          ? articles.firstWhere((a) => a.id == oldProd.article.id)
                          : null;

                      if (exist == null) {
                        oldProd.setRowPrice(0);

                        if (!priceZero) {
                          priceZero = true;

                          showDialog(
                            context: context,
                            builder: (_) => const AlertDialog(
                              icon: Icon(Icons.warning),
                              title: Text(
                                'Attenzione: prodotti a prezzo zero nel nuovo listino',
                              ),
                            ),
                          );
                        }
                        continue;
                      }

                      double newPrice =
                          double.parse(exist.price ?? '0') * oldProd.quantity;

                      oldProd.setRowPrice(newPrice);
                    }

                    controllerCart.changeProductsInCart(oldProducts);
                  }

                  if (!confirm) return;

                  //  SINCRONIZZAZIONE GLOBALE
                  controllerListPrice.listPriceSelected = selected_;

                  op.selectedListino = selected_;
                  op.rapidPriceListId = selected_.id;

                  op.notifyListeners();

                  widget.key;

                  setState(() {}); */
                },
              ),
            ),
          ),

          _switch(
            "Visualizza valore ultima vendita",
            op.displayAmountLastSale,
                (v) {
              op.displayAmountLastSale = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          _slider(
            "Sconto rapido %",
            op.rapidDiscountButtonPercentage,
            enabled: true,
            onChanged: (v) {
              op.rapidDiscountButtonPercentage = v.toInt();
              op.notifyListeners();
            },
          ),

          const SizedBox(height: 18),

// =====================================================
// VISUALIZZAZIONE
// =====================================================
          _titolo("Visualizzazione", text),

          _switch(
            "Prodotti ridotti",
            imp.visualizzazioneProdottiRidotta,
                (v) => imp.aggiorna('visualizzazioneProdottiRidotta', v),
            card,
            text,
            verde,
          ),

          _switch(
            "Categorie grandi",
            imp.visualizzazioneCategorieIngrandita,
                (v) => imp.aggiorna('visualizzazioneCategorieIngrandita', v),
            card,
            text,
            verde,
          ),

          _switch(
            "Paginazione prodotti",
            op.paginatedArticle,
                (v) {
              op.paginatedArticle = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          _switch(
            "Tavoli ridotti",
            op.displayTableReduced,
                (v) {
              op.displayTableReduced = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          _switch(
            "Visualizza utente tavolo",
            op.displayUserTable,
                (v) {
              op.displayUserTable = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          const SizedBox(height: 18),

// =====================================================
// ASPETTO
// =====================================================
          _titolo("Aspetto grafico", text),

          _switch(
            "Dark Mode",
            imp.darkMode,
                (v) async {
              final op = context.read<OperatorPreferencesController>();
              final themeController = context.read<ThemeController>();

              // UI
              themeController.setThemeMode(
                v ? ThemeMode.dark : ThemeMode.light,
              );

              // SALVA
              await imp.aggiorna('darkMode', v);

              // API SYNC
              op.useDarkMode = v;
              op.notifyListeners();
            },
            card,
            text,
            verde,
          ),

          const SizedBox(height: 80),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: verde,
        child: FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Salva impostazioni"),
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();

                final token = prefs.getString("token");
                final instance = prefs.getString("istanza") ?? defaultInstance;

                if (token == null) throw Exception("Token mancante");

                final operatorGuid = "549b7fd64941";
                final operatorId = operatorLogged?.id ?? 68;

                final url = Uri.parse(
                  "https://${instance}-api.qfood.it/api/v1/pos/updateOperatorPermission/$operatorGuid",
                );

                // =========================
                // MAPPING SIZE
                // =========================
                String mapSize(String v) {
                  switch (v) {
                    case "S":
                      return "small";
                    case "M":
                      return "medium";
                    case "L":
                      return "large";
                    default:
                      return "medium";
                  }
                }

                // =========================
                // BODY COMPLETO (FIXATO)
                // =========================
                final body = {
                  "idOperator": operatorId,

                  "smallProductName": imp.nomeBreveProdotti ? 1 : 0,
                  "productNameSize": mapSize(imp.grandezzaNomeProdotti),
                  "productSmallNameSize": mapSize(imp.grandezzaNomeBreveProdotti),
                  "uiSide": imp.uiSide == "L" ? "rtl" : "ltr",

                  "rapidDiscountButtonPercentage": op.rapidDiscountButtonPercentage,
                  "discountBenchTable": op.discountBenchTable ? 1 : 0,
                  "extendedCart": imp.carrelloInvertito ? 1 : 0,
                  "rapidButtonCash": op.rapidButtonCash ? 1 : 0,
                  "displayAmountLastSale": op.displayAmountLastSale ? 1 : 0,
                  "rapidPriceListId": op.rapidPriceListId,
                  "displayProductReduced": imp.visualizzazioneProdottiRidotta ? 1 : 0,
                  "displayBigCategory": imp.visualizzazioneCategorieIngrandita ? 1 : 0,
                  "paginatedArticle": op.paginatedArticle ? 1 : 0,
                  "displayTableReduced": op.displayTableReduced ? 1 : 0,
                  "displayUserTable": op.displayUserTable ? 1 : 0,

                  "useDarkMode": imp.darkMode ? 1 : 0,
                  "printDefaultCommandFromBench": imp.stampaComandeBanco ? 1 : 0,
                  "tableOpeningInCommand": op.tableOpeningInCommand ? 1 : 0,
                  "sendOrderNoExitTable": op.sendOrderNoExitTable ? 1 : 0,
                  "valueWithoutSeparator": op.valueWithoutSeparator ? 1 : 0,

                  // "paymentCheck": op.paymentCheck ? 1 : 0,
                  // "paymentWireTransfer": op.paymentWireTransfer ? 1 : 0,
                };

                debugPrint("-> SEND API");
                debugPrint("URL → $url");
                debugPrint("BODY → ${jsonEncode(body)}");

                final response = await http.patch(
                  url,
                  headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer $token",
                    "x-api-key": posApiKey,
                  },
                  body: jsonEncode(body),
                );

                debugPrint("STATUS → ${response.statusCode}");
                debugPrint("RESPONSE → ${response.body}");

                if (!context.mounted) return;


                ScaffoldMessenger.of(context).clearSnackBars();

                if (response.statusCode == 200) {

                  // ✅ NON PARSARE LA RISPOSTA (NON SERVE)

                  final impCtrl = context.read<ImpostazioniController>();
                  await impCtrl.salvaTutte();
                  //aggiorno l'operatore loggato
                  final syncController = context.read<SyncController>();
                  await SyncCatalogo.syncOperatori( syncController );

                  final resQuery = await LocalDB.query('SELECT * FROM operators WHERE id = "${ operatorLogged?.id ?? 0 }"')
                        .catchError((err) => writeLogOnFile("catchError query login", err.toString(), trace: StackTrace.current));
                  List<OperatoreModel> operator = resQuery.map((e) => OperatoreModel.fromJson(e)).toList();
                  if(operator.isNotEmpty) operatorLogged = operator[0];
                  //////////////////////////////////////////////////////////////////////////////////////////////////////
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF00A651),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Settaggi aggiornati con successo",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  throw Exception(response.body);
                }

              } catch (e) {
                debugPrint("❌ ERRORE → $e");

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text("Errore: ${e.toString()}"),
                  ),
                );
              }
            }
        ),
      ),
    );
  }

  // =====================================================
  // HELPERS
  // =====================================================
  Widget _titolo(String t, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(t.toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c.withOpacity(.6))),
  );

  Widget _switch(String t, bool v, ValueChanged<bool>? c, Color card, Color text, Color verde) =>
      Card(color: card, child: SwitchListTile(title: Text(t, style: TextStyle(color: text)), value: v, onChanged: c));

  Widget _dropdown(String t, String v, List<String> opts, ValueChanged<String?>? c, Color card, Color text) =>
      Card(color: card, child: ListTile(title: Text(t, style: TextStyle(color: text)),
          trailing: DropdownButton(value: v, underline: const SizedBox(), items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: c)));

  Widget _slider(String t, int v, {required bool enabled, required ValueChanged<double> onChanged}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("$t ($v%)"),
        Slider(value: v.toDouble(), min: 0, max: 100, divisions: 100, onChanged: enabled ? onChanged : null),
      ]);


}

 */


import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/sync_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Global.dart';
import '../../app/theme/controllers/theme_controller.dart';
import '../../config/costanti.dart';
import '../../modelli/listPrice.dart';
import '../../state/controller_impostazioni.dart';
import '../../ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import '../../ui/screen/sincronizzazioni/operatori/operator_preferences_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../ui/widget/header_footer/ControllerListPriceSelected.dart';

class ImpostazioniUtente extends StatefulWidget {
  const ImpostazioniUtente({super.key});

  @override
  State<ImpostazioniUtente> createState() => _ImpostazioniUtenteState();
}

class _ImpostazioniUtenteState extends State<ImpostazioniUtente> {
  /*  List<ListPriceModel> listini = []; */

  @override
  void initState() {
    super.initState();
    /*  _loadListini(); */
  }

  /*   Future<void> _loadListini() async {
    listini = await ListPriceModel.getByDb();
    setState(() {});
  } */

  @override
  Widget build(BuildContext context) {
    final imp = context.watch<ImpostazioniController>();
    final op = context.watch<OperatorPreferencesController>();

    final isDark =
        imp.darkMode || Theme.of(context).brightness == Brightness.dark;
    const verde = Color(0xFF95C01F);
    final bg =
        isDark ? const Color(0xFF111111) : const Color(0xFFF7F7F2);
    final card =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text =
        isDark ? Colors.white : Colors.black87;
    final controllerListPrice =
        context.watch<ControllerListPriceSelected>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: verde,
        title: const Text(
          "Impostazioni utente",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: imp.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // =====================================================
                // CONFIGURAZIONE GENERALE
                // =====================================================
                _titolo("Configurazione generale", text),

                _switch(
                  "Nome breve prodotti",
                  imp.nomeBreveProdotti,
                  (v) {
                    imp.aggiorna('nomeBreveProdotti', v);
                    op.smallProductName = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                _dropdown(
                  "Grandezza nome prodotti",
                  imp.grandezzaNomeProdotti,
                  ["S", "M", "L"],
                  (v) async {
                    if (v == null) return;
                    await imp.aggiorna('grandezzaNomeProdotti', v);
                    // forza rebuild
                    imp.notifyListeners();
                  },
                  card,
                  text,
                ),

                _dropdown(
                  "Grandezza nome breve prodotti",
                  imp.grandezzaNomeBreveProdotti,
                  ["S", "M", "L"],
                  imp.nomeBreveProdotti
                      ? (v) => imp.aggiorna(
                          'grandezzaNomeBreveProdotti',
                          v,
                        )
                      : null,
                  card,
                  text,
                ),

                _dropdown(
                  "Lato interfaccia",
                  imp.uiSide,
                  ["R", "L"],
                  (v) {
                    imp.aggiorna('uiSide', v ?? "R");
                  },
                  card,
                  text,
                ),

                _switch(
                  "Carrello esteso",
                  op.extendedCart,
                  (v) async {
                    // stato runtime
                    op.extendedCart = v;
                    op.notifyListeners();
                    // persistenza in impostazioni (riuso chiave esistente)
                    await imp.aggiorna('carrelloInvertito', v);
                  },
                  card,
                  text,
                  verde,
                ),

                _switch(
                  "Stampa comande di default da banco",
                  imp.stampaComandeBanco,
                  (v) =>
                      imp.aggiorna('stampaComandeBanco', v),
                  card,
                  text,
                  verde,
                ),

                const SizedBox(height: 18),

                // =====================================================
                // FUNZIONALITÀ POS
                // =====================================================
                _titolo("Funzionalità POS", text),

                _switch(
                  "Sconto su banco/tavoli",
                  op.discountBenchTable,
                  (v) {
                    op.discountBenchTable = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                _switch(
                  "Pulsante rapido contanti",
                  op.rapidButtonCash,
                  (v) {
                    op.rapidButtonCash = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                Card(
                  color: card,
                  child: ListTile(
                    title: Text(
                      "Cambio rapido listino",
                      style: TextStyle(color: text),
                    ),
                    trailing: DropdownButton<ListPriceModel?>(
                      value: listsPrice.contains(
                              controllerListPrice
                                  .listPriceSelected)
                          ? controllerListPrice
                              .listPriceSelected
                          : null,
                      hint: const Text("Seleziona listino"),
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem<
                            ListPriceModel?>(
                          value: null,
                          child: Text('Seleziona listino'),
                        ),
                        ...listsPrice
                            .where((list) =>
                                list.counterpart == 'customer')
                            .toList()
                            .map(
                              (list) =>
                                  DropdownMenuItem<ListPriceModel>(
                                value: list,
                                child: Text(list.title),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged:
                          (ListPriceModel? selected_) async {
                        if (selected_ == null) return;
                        controllerListPrice
                            .listPriceSelected = selected_;

                        /* ESEMPIO BLOCCO COMPLETO (lasciato commentato)
                        final controllerCart = context.read<CarrelloController>();
                        bool confirm = true;
                        if (controllerCart.prodotti.isNotEmpty) {
                          List<ProdottoCarrello> oldProducts = [...controllerCart.prodotti];
                          String query = """SELECT 
                                art.*, 
                                lp.*  
                              FROM articles art
                              INNER JOIN articlesPrices lp 
                                ON lp.idArticle = art.id 
                                AND lp.idPriceList = ${selected_.id}
                              """;
                          final resp = await LocalDB.query(query).catchError((_) => []);
                          List<ArticleWhitPriceListModel> articles =
                              resp.map((e) => ArticleWhitPriceListModel.fromJson(e)).toList();

                          bool priceZero = false;

                          for (var oldProd in oldProducts) {
                            final exist = articles.where(
                              (a) => a.id == oldProd.article.id,
                            ).isNotEmpty
                                ? articles.firstWhere((a) => a.id == oldProd.article.id)
                                : null;

                            if (exist == null) {
                              oldProd.setRowPrice(0);
                              if (!priceZero) {
                                priceZero = true;
                                showDialog(
                                  context: context,
                                  builder: (_) => const AlertDialog(
                                    icon: Icon(Icons.warning),
                                    title: Text(
                                      'Attenzione: prodotti a prezzo zero nel nuovo listino',
                                    ),
                                  ),
                                );
                              }
                              continue;
                            }

                            double newPrice =
                                double.parse(exist.price ?? '0') * oldProd.quantity;
                            oldProd.setRowPrice(newPrice);
                          }

                          controllerCart.changeProductsInCart(oldProducts);
                        }

                        if (!confirm) return;

                        controllerListPrice.listPriceSelected = selected_;
                        op.selectedListino = selected_;
                        op.rapidPriceListId = selected_.id;
                        op.notifyListeners();
                        setState(() {});
                        */
                      },
                    ),
                  ),
                ),

                _switch(
                  "Visualizza valore ultima vendita",
                  op.displayAmountLastSale,
                  (v) {
                    op.displayAmountLastSale = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                _slider(
                  "Sconto rapido %",
                  op.rapidDiscountButtonPercentage,
                  enabled: true,
                  onChanged: (v) {
                    op.rapidDiscountButtonPercentage =
                        v.toInt();
                    op.notifyListeners();
                  },
                ),

                const SizedBox(height: 18),

                // =====================================================
                // VISUALIZZAZIONE
                // =====================================================
                _titolo("Visualizzazione", text),

                _switch(
                  "Prodotti ridotti",
                  imp.visualizzazioneProdottiRidotta,
                  (v) => imp.aggiorna(
                    'visualizzazioneProdottiRidotta',
                    v,
                  ),
                  card,
                  text,
                  verde,
                ),

                _switch(
                  "Categorie grandi",
                  imp.visualizzazioneCategorieIngrandita,
                  (v) => imp.aggiorna(
                    'visualizzazioneCategorieIngrandita',
                    v,
                  ),
                  card,
                  text,
                  verde,
                ),

                _switch(
                  "Paginazione prodotti",
                  op.paginatedArticle,
                  (v) {
                    op.paginatedArticle = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                _switch(
                  "Tavoli ridotti",
                  op.displayTableReduced,
                  (v) {
                    op.displayTableReduced = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                _switch(
                  "Visualizza utente tavolo",
                  op.displayUserTable,
                  (v) {
                    op.displayUserTable = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                const SizedBox(height: 18),

                // =====================================================
                // ASPETTO
                // =====================================================
                _titolo("Aspetto grafico", text),

                _switch(
                  "Dark Mode",
                  imp.darkMode,
                  (v) async {
                    final op =
                        context.read<OperatorPreferencesController>();
                    final themeController =
                        context.read<ThemeController>();

                    // UI
                    themeController.setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );

                    // SALVA
                    await imp.aggiorna('darkMode', v);

                    // API SYNC
                    op.useDarkMode = v;
                    op.notifyListeners();
                  },
                  card,
                  text,
                  verde,
                ),

                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: verde,
        child: FilledButton.icon(
          icon: const Icon(Icons.save),
          label: const Text("Salva impostazioni"),
          onPressed: () async {
            try {
              final prefs =
                  await SharedPreferences.getInstance();

              final token = prefs.getString("token");
              final instance =
                  prefs.getString("istanza") ?? defaultInstance;

              if (token == null) {
                throw Exception("Token mancante");
              }

              final operatorGuid = "549b7fd64941";
              final operatorId =
                  operatorLogged?.id ?? 68;

              final url = Uri.parse(
                "https://${instance}-api.qfood.it/api/v1/pos/updateOperatorPermission/$operatorGuid",
              );

              // mapping size
              String mapSize(String v) {
                switch (v) {
                  case "S":
                    return "small";
                  case "M":
                    return "medium";
                  case "L":
                    return "large";
                  default:
                    return "medium";
                }
              }

              // BODY COMPLETO
              final body = {
                "idOperator": operatorId,
                "smallProductName":
                    imp.nomeBreveProdotti ? 1 : 0,
                "productNameSize":
                    mapSize(imp.grandezzaNomeProdotti),
                "productSmallNameSize":
                    mapSize(imp.grandezzaNomeBreveProdotti),
                "uiSide": imp.uiSide == "L"
                    ? "rtl"
                    : "ltr",
                "rapidDiscountButtonPercentage":
                    op.rapidDiscountButtonPercentage,
                "discountBenchTable":
                    op.discountBenchTable ? 1 : 0,
                // usa preferenze operatore per extendedCart
                "extendedCart":
                    op.extendedCart ? 1 : 0,
                "rapidButtonCash":
                    op.rapidButtonCash ? 1 : 0,
                "displayAmountLastSale":
                    op.displayAmountLastSale ? 1 : 0,
                "rapidPriceListId": op.rapidPriceListId,
                "displayProductReduced":
                    imp.visualizzazioneProdottiRidotta ? 1 : 0,
                "displayBigCategory":
                    imp.visualizzazioneCategorieIngrandita ? 1 : 0,
                "paginatedArticle":
                    op.paginatedArticle ? 1 : 0,
                "displayTableReduced":
                    op.displayTableReduced ? 1 : 0,
                "displayUserTable":
                    op.displayUserTable ? 1 : 0,
                "useDarkMode":
                    imp.darkMode ? 1 : 0,
                "printDefaultCommandFromBench":
                    imp.stampaComandeBanco ? 1 : 0,
                "tableOpeningInCommand":
                    op.tableOpeningInCommand ? 1 : 0,
                "sendOrderNoExitTable":
                    op.sendOrderNoExitTable ? 1 : 0,
                "valueWithoutSeparator":
                    op.valueWithoutSeparator ? 1 : 0,
                // eventuali payment* se li riattivi
              };

              debugPrint("-> SEND API");
              debugPrint("URL → $url");
              debugPrint("BODY → ${jsonEncode(body)}");

              final response = await http.patch(
                url,
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token",
                  "x-api-key": posApiKey,
                },
                body: jsonEncode(body),
              );

              debugPrint(
                "STATUS → ${response.statusCode}",
              );
              debugPrint(
                "RESPONSE → ${response.body}",
              );

              if (!context.mounted) return;

              ScaffoldMessenger.of(context)
                  .clearSnackBars();

              if (response.statusCode == 200) {
                final impCtrl =
                    context.read<ImpostazioniController>();
                await impCtrl.salvaTutte();

                final syncController =
                    context.read<SyncController>();
                await SyncCatalogo.syncOperatori(
                  syncController,
                );

                final resQuery = await LocalDB
                    .query(
                      'SELECT * FROM operators WHERE id = "${operatorLogged?.id ?? 0}"',
                    )
                    .catchError(
                      (err) => writeLogOnFile(
                        "catchError query login",
                        err.toString(),
                        trace: StackTrace.current,
                      ),
                    );

                List<OperatoreModel> operator =
                    resQuery
                        .map(
                          (e) =>
                              OperatoreModel.fromJson(e),
                        )
                        .toList();
                if (operator.isNotEmpty) {
                  operatorLogged = operator[0];
                }

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    backgroundColor:
                        const Color(0xFF00A651),
                    behavior: SnackBarBehavior
                        .floating,
                    duration: const Duration(
                      seconds: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    content: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Settaggi aggiornati con successo",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                throw Exception(response.body);
              }
            } catch (e) {
              debugPrint("❌ ERRORE → $e");

              if (!context.mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    "Errore: ${e.toString()}",
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // =====================================================
  // HELPERS
  // =====================================================
  Widget _titolo(String t, Color c) => Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          t.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: c.withOpacity(.6),
          ),
        ),
      );

  Widget _switch(
    String t,
    bool v,
    ValueChanged<bool>? c,
    Color card,
    Color text,
    Color verde,
  ) =>
      Card(
        color: card,
        child: SwitchListTile(
          title: Text(t, style: TextStyle(color: text)),
          value: v,
          onChanged: c,
        ),
      );

  Widget _dropdown(
    String t,
    String v,
    List<String> opts,
    ValueChanged<String?>? c,
    Color card,
    Color text,
  ) =>
      Card(
        color: card,
        child: ListTile(
          title: Text(
            t,
            style: TextStyle(color: text),
          ),
          trailing: DropdownButton(
            value: v,
            underline: const SizedBox(),
            items: opts
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: c,
          ),
        ),
      );

  Widget _slider(
    String t,
    int v, {
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$t ($v%)"),
          Slider(
            value: v.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      );
}
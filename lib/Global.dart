import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dashboard/modelli/article.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/modelli/pos.dart';
import 'package:dashboard/modelli/printer.dart';
import 'package:dashboard/modelli/settingPos.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/screen/login_opertore/login_operatore_vista.dart';
import 'package:dashboard/ui/screen/tavoli/tavoli_vista.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

String? usernameStore;

int  tabAttivo = 2; // 0 = Categorie, 1 = Reparti , 2 = Preferiti
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
SettingStoreModel?        settingStore; //storeData: "insightStartHour" -> "21:00:00" "insightEndHour" -> "21:00:00" ORARI STATISTICHE
OperatoreModel?           operatorLogged;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState>           messengerKey           = GlobalKey();
final GlobalKey<TastierinoCompattoFissoState>     tastierinoKey          = GlobalKey();
final GlobalKey<TavoliVistaState>                 vistaTableKey          = GlobalKey();
final GlobalKey<LoginOperatorVistaState>          logInOperatorGlobalKey = GlobalKey();

List<PosModel> posGlobal = [];
PosModel? posSelected;
dynamic   deviceCurrent;
List<TableModel> tableByServerForClient = [];
List<ListPriceModel> listsPrice         = [];
List<ArticleWhitPriceListModel>   covers             = [];
List<PrinterForArticle> printersArticle  = [];
List<ArticleModel> allArticles = [];

//ARTICOLO GENERICO PER VARIABILI LIBERE E PRODOTTI AGGIUNTI DA REPARTO
Future<dynamic> getGenericProduct() async {
  try{
    SharedPreferences pref = await SharedPreferences.getInstance();
    final genericArticle = pref.getString('genericArticle');

    if( genericArticle == null ){
      SnackBarForcedClosure('Articolo generico non presente', Colors.orange);
      return;
    }

    return jsonDecode(genericArticle);

  }catch(err){
    debugPrint(err.toString());
  }
}

void SnackBarForcedClosure (String message, Color bgColor) {
  Future.delayed(Duration(seconds: 0), () {
    messengerKey.currentState?.showSnackBar( 
                                            SnackBar( 
                                              content: Text( message ),
                                              backgroundColor: bgColor,
                                              ));
  });
}

Future<ListPriceModel?> getListPriceSelected() async {
  try{
    SharedPreferences pref = await SharedPreferences.getInstance();
    final list = pref.getString('listPriceSelected');
    if( list == null ) return null;
    ListPriceModel listFinal = ListPriceModel.fromJson(jsonDecode(list));
    return listFinal;
  }catch( err ){
    debugPrint(err.toString());
  }

}

Future<void> setListPriceSelected(ListPriceModel listPrice) async {
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('listPriceSelected', jsonEncode(listPrice.toMap()));
    }catch( err ){
      debugPrint(err.toString());
    }
}

Future<void> writeLogOnFile(String level, String content, {StackTrace ? trace}) async {

  try{
    String path = (await getApplicationDocumentsDirectory()).path;
    String filename = "log_$level${Uuid().v4().replaceAll("-", "_")}.txt";
    Directory dir = Directory("$path/qfood/logs");
    if(!dir.existsSync()){
      dir.createSync(recursive: true);
    }
    await File("$path/qfood/logs/$filename").writeAsString("LEVEL=>$level\n\nCONTENT=>\n$content\n\nSTACK TRACE=>$trace");
  }catch(e){
    if(kDebugMode){
      print(e);
    }
  }
}

  Future<bool> modalDiscountReason ( BuildContext context ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    TextEditingController ctrReason = TextEditingController();
    final carrello = context.read<CarrelloController>();

    if( operatorLogged!.discountReason == 0 ) return true;
    if( carrello.discount == 0 )              return true;

    final result = await showDialog(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(
              'Motivo sconto',
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: TextFormField(
              controller: ctrReason,
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("ANNULLA",
                    style: TextStyle(
                        color: const Color(0xFF95C01F), fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                onPressed: () {
                  if( ctrReason.text.trim().length < 5 ){
                    SnackBarForcedClosure('Minimo 5 caratteri', Colors.orange);
                    return;
                  }
                  carrello.setDiscountReason( ctrReason.text.trim() );
                  Navigator.pop(context, true );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF95C01F),
                  foregroundColor: Colors.white,
                ),
                child: Text('Procedi', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  void ModalConfirm(
      BuildContext context, {
        required String titolo,
        required String messaggio,
        required String confermaLabel,
        required Color colorePrimario,
        required VoidCallback onConferma,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(
              titolo,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: Text(
              messaggio,
              style: TextStyle(color: textColor.withOpacity(0.9)),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ANNULLA",
                    style: TextStyle(
                        color: colorePrimario, fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConferma();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorePrimario,
                  foregroundColor: Colors.white,
                ),
                child: Text(confermaLabel.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  const List<Map<String, String>> provinceIT = [
      {'sigla': 'AG', 'nome': 'Agrigento'},
      {'sigla': 'AL', 'nome': 'Alessandria'},
      {'sigla': 'AN', 'nome': 'Ancona'},
      {'sigla': 'AO', 'nome': 'Aosta'},
      {'sigla': 'AR', 'nome': 'Arezzo'},
      {'sigla': 'AP', 'nome': 'Ascoli Piceno'},
      {'sigla': 'AT', 'nome': 'Asti'},
      {'sigla': 'AV', 'nome': 'Avellino'},
      {'sigla': 'BA', 'nome': 'Bari'},
      {'sigla': 'BT', 'nome': 'Barletta-Andria-Trani'},
      {'sigla': 'BL', 'nome': 'Belluno'},
      {'sigla': 'BN', 'nome': 'Benevento'},
      {'sigla': 'BG', 'nome': 'Bergamo'},
      {'sigla': 'BI', 'nome': 'Biella'},
      {'sigla': 'BO', 'nome': 'Bologna'},
      {'sigla': 'BZ', 'nome': 'Bolzano'},
      {'sigla': 'BS', 'nome': 'Brescia'},
      {'sigla': 'BR', 'nome': 'Brindisi'},
      {'sigla': 'CA', 'nome': 'Cagliari'},
      {'sigla': 'CL', 'nome': 'Caltanissetta'},
      {'sigla': 'CB', 'nome': 'Campobasso'},
      {'sigla': 'CE', 'nome': 'Caserta'},
      {'sigla': 'CT', 'nome': 'Catania'},
      {'sigla': 'CZ', 'nome': 'Catanzaro'},
      {'sigla': 'CH', 'nome': 'Chieti'},
      {'sigla': 'CO', 'nome': 'Como'},
      {'sigla': 'CS', 'nome': 'Cosenza'},
      {'sigla': 'CR', 'nome': 'Cremona'},
      {'sigla': 'KR', 'nome': 'Crotone'},
      {'sigla': 'CN', 'nome': 'Cuneo'},
      {'sigla': 'EN', 'nome': 'Enna'},
      {'sigla': 'FM', 'nome': 'Fermo'},
      {'sigla': 'FE', 'nome': 'Ferrara'},
      {'sigla': 'FI', 'nome': 'Firenze'},
      {'sigla': 'FG', 'nome': 'Foggia'},
      {'sigla': 'FC', 'nome': 'Forlì-Cesena'},
      {'sigla': 'FR', 'nome': 'Frosinone'},
      {'sigla': 'GE', 'nome': 'Genova'},
      {'sigla': 'GO', 'nome': 'Gorizia'},
      {'sigla': 'GR', 'nome': 'Grosseto'},
      {'sigla': 'IM', 'nome': 'Imperia'},
      {'sigla': 'IS', 'nome': 'Isernia'},
      {'sigla': 'AQ', 'nome': "L'Aquila"},
      {'sigla': 'SP', 'nome': 'La Spezia'},
      {'sigla': 'LT', 'nome': 'Latina'},
      {'sigla': 'LE', 'nome': 'Lecce'},
      {'sigla': 'LC', 'nome': 'Lecco'},
      {'sigla': 'LI', 'nome': 'Livorno'},
      {'sigla': 'LO', 'nome': 'Lodi'},
      {'sigla': 'LU', 'nome': 'Lucca'},
      {'sigla': 'MC', 'nome': 'Macerata'},
      {'sigla': 'MN', 'nome': 'Mantova'},
      {'sigla': 'MS', 'nome': 'Massa-Carrara'},
      {'sigla': 'MT', 'nome': 'Matera'},
      {'sigla': 'ME', 'nome': 'Messina'},
      {'sigla': 'MI', 'nome': 'Milano'},
      {'sigla': 'MO', 'nome': 'Modena'},
      {'sigla': 'MB', 'nome': 'Monza e della Brianza'},
      {'sigla': 'NA', 'nome': 'Napoli'},
      {'sigla': 'NO', 'nome': 'Novara'},
      {'sigla': 'NU', 'nome': 'Nuoro'},
      {'sigla': 'OR', 'nome': 'Oristano'},
      {'sigla': 'PD', 'nome': 'Padova'},
      {'sigla': 'PA', 'nome': 'Palermo'},
      {'sigla': 'PR', 'nome': 'Parma'},
      {'sigla': 'PV', 'nome': 'Pavia'},
      {'sigla': 'PG', 'nome': 'Perugia'},
      {'sigla': 'PU', 'nome': 'Pesaro e Urbino'},
      {'sigla': 'PE', 'nome': 'Pescara'},
      {'sigla': 'PC', 'nome': 'Piacenza'},
      {'sigla': 'PI', 'nome': 'Pisa'},
      {'sigla': 'PT', 'nome': 'Pistoia'},
      {'sigla': 'PN', 'nome': 'Pordenone'},
      {'sigla': 'PZ', 'nome': 'Potenza'},
      {'sigla': 'PO', 'nome': 'Prato'},
      {'sigla': 'RG', 'nome': 'Ragusa'},
      {'sigla': 'RA', 'nome': 'Ravenna'},
      {'sigla': 'RC', 'nome': 'Reggio Calabria'},
      {'sigla': 'RE', 'nome': "Reggio Emilia"},
      {'sigla': 'RI', 'nome': 'Rieti'},
      {'sigla': 'RN', 'nome': 'Rimini'},
      {'sigla': 'RM', 'nome': 'Roma'},
      {'sigla': 'RO', 'nome': 'Rovigo'},
      {'sigla': 'SA', 'nome': 'Salerno'},
      {'sigla': 'SS', 'nome': 'Sassari'},
      {'sigla': 'SV', 'nome': 'Savona'},
      {'sigla': 'SI', 'nome': 'Siena'},
      {'sigla': 'SR', 'nome': 'Siracusa'},
      {'sigla': 'SO', 'nome': 'Sondrio'},
      {'sigla': 'SU', 'nome': 'Sud Sardegna'},
      {'sigla': 'TA', 'nome': 'Taranto'},
      {'sigla': 'TE', 'nome': 'Teramo'},
      {'sigla': 'TR', 'nome': 'Terni'},
      {'sigla': 'TO', 'nome': 'Torino'},
      {'sigla': 'TP', 'nome': 'Trapani'},
      {'sigla': 'TN', 'nome': 'Trento'},
      {'sigla': 'TV', 'nome': 'Treviso'},
      {'sigla': 'TS', 'nome': 'Trieste'},
      {'sigla': 'UD', 'nome': 'Udine'},
      {'sigla': 'VA', 'nome': 'Varese'},
      {'sigla': 'VE', 'nome': 'Venezia'},
      {'sigla': 'VB', 'nome': 'Verbano-Cusio-Ossola'},
      {'sigla': 'VC', 'nome': 'Vercelli'},
      {'sigla': 'VR', 'nome': 'Verona'},
      {'sigla': 'VV', 'nome': 'Vibo Valentia'},
      {'sigla': 'VI', 'nome': 'Vicenza'},
      {'sigla': 'VT', 'nome': 'Viterbo'},
    ];


Future<bool> showConfermaDialogDiscount({
  required BuildContext context,
  String titolo = 'Conferma',
  String messaggio = 'Sei sicuro di voler applicare lo sconto?',
  String labelApplica = 'Applica',
  String labelAnnulla = 'Annulla',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // tap fuori non chiude
    builder: (ctx) => AlertDialog(
      title: Text(titolo),
      content: Text(messaggio),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(labelAnnulla),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(labelApplica),
        ),
      ],
    ),
  );

  return result ?? false; // se chiude in altro modo → false
}







Future<double?> mostraDialogSconto(
  BuildContext context, {
  double? initialValue, // in percentuale, es. 10 = 10%
}) async {
  final ctrl = TextEditingController(
    text: initialValue != null
        ? initialValue.toStringAsFixed(
            initialValue.truncateToDouble() == initialValue ? 0 : 2,
          ).replaceAll(".", ",")
        : "",
  );
  final theme = Theme.of(context);

  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 440,
              maxHeight: 620,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Inserisci sconto (%)",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (_, __) {
                        final text = ctrl.text.isEmpty ? "" : ctrl.text;
                        return Text(
                          "$text %",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    const Divider(),
                    Flexible(
                      child: _TastierinoSconto(
                        controller: ctrl,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Annulla"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TastierinoSconto extends StatefulWidget {
  final TextEditingController controller;

  const _TastierinoSconto({
    required this.controller,
  });

  @override
  State<_TastierinoSconto> createState() => _TastierinoScontoState();
}

class _TastierinoScontoState extends State<_TastierinoSconto> {
  void _tap(String value) {
    setState(() {
      if (value == "⌫") {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.text =
              widget.controller.text.substring(
            0,
            widget.controller.text.length - 1,
          );
        }
        return;
      }

      if (value == ",") {
        if (!widget.controller.text.contains(",")) {
          widget.controller.text += ",";
        }
        return;
      }

      widget.controller.text += value;
    });
  }

  void _conferma() {
    final testo = widget.controller.text.replaceAll(",", ".");
    final valore = double.tryParse(testo);

    /* if (valore == null) return;

    if (valore < 0 || valore > 100) {
      // qui potresti mostrare un messaggio di errore
      return;
    } */

    Navigator.pop<double>(context, valore ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<String> keys = [
      "7",
      "8",
      "9",
      "4",
      "5",
      "6",
      "1",
      "2",
      "3",
      "0",
      "00",
      ",",
    ];

    return Column(
      children: [
        SizedBox(
          height: 340, // per evitare overflow
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (_, i) {
              final k = keys[i];
              return ElevatedButton(
                onPressed: () => _tap(k),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface
                      .withOpacity(0.05),
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  k,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _tap("⌫"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.close, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _conferma,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC540),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class TastierinoNumericoGenerico extends StatefulWidget {
  final TextEditingController controller;

  const TastierinoNumericoGenerico({
    required this.controller,
  });

  @override
  State<TastierinoNumericoGenerico> createState() => TastierinoNumericoGenericoState();
}

class TastierinoNumericoGenericoState extends State<TastierinoNumericoGenerico> {
  void _tap(String value) {
    setState(() {
      if (value == "⌫") {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.text =
              widget.controller.text.substring(
            0,
            widget.controller.text.length - 1,
          );
        }
        return;
      }

      if (value == ",") {
        if (!widget.controller.text.contains(",")) {
          widget.controller.text += ",";
        }
        return;
      }

      widget.controller.text += value;
    });
  }

  void _conferma() {
    final testo = widget.controller.text.replaceAll(",", ".");
    final valore = double.tryParse(testo);

    if (valore == null) return;

    // opzionale: vincolo 0–100%
    if (valore < 0 || valore > 100) {
      // qui potresti mostrare un messaggio di errore
      return;
    }

    // ritorna la percentuale di sconto
    Navigator.pop<double>(context, valore);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<String> keys = [
      "7",
      "8",
      "9",
      "4",
      "5",
      "6",
      "1",
      "2",
      "3",
      "0",
      "00",
      ",",
    ];

    return Column(
      children: [
        SizedBox(
          height: 340, 
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (_, i) {
              final k = keys[i];
              return ElevatedButton(
                onPressed: () => _tap(k),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface
                      .withOpacity(0.05),
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  k,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _tap("⌫"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.close, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            /* Expanded(
              child: ElevatedButton(
                onPressed: _conferma,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC540),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 30,
                ),
              ),
            ), */
          ],
        ),
      ],
    );
  }
}
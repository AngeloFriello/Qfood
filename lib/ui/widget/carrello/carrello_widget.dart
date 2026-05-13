/* import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/cartModelSaledSuspended.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/widget/header_footer/ControllerListPriceSelected.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:dashboard/varianti/state/variants_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screen/sincronizzazioni/articoli/articolo_service.dart';
import '../../screen/ordini/state/ordine_attivo_controller.dart';
import '../../screen/ordini/ux/widgets/inserisci_ordine_dialog.dart';
import '../../../state/controller_carrello.dart';
import '../../../varianti/ui/varianti_dialog.dart';


class CarrelloWidget extends StatelessWidget {
  final VoidCallback onEditCliente;
  final ListPriceModel? listPrice;

  const CarrelloWidget({
    super.key,
    required this.onEditCliente,
    required this.listPrice,
  });


  Color getColorBgVariantRow(String type){
    switch (type) {
      case 'minus':
        return Colors.red;
      case 'plus':
        return Colors.green;
      case 'free':
        return Colors.green;
      case 'info':
        return Colors.lightBlue;
      default: return Colors.black;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carrello = context.watch<CarrelloController>();
    final prodotti = carrello.prodotti.reversed.toList();
    final isDark = theme.brightness == Brightness.dark;
    final crtTastierinoVisibile = context.watch<ControllerTastierinoAperto>();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [

          // =========================
          // HEADER CLIENTE / ORDINE
          // =========================

          
          if (carrello.cliente != null)
            carrello.inOrder
                ? const _OrdineAttivoHeader()
                : _ClienteHeader(
                    cliente: carrello.cliente!,
                    onEdit: onEditCliente,
                  ),




          // =========================
          // LISTA PRODOTTI / STATO VUOTO
          // =========================
          Expanded(
            child: prodotti.isEmpty
                ? Center(
              child: Text(
                "Aggiungi prodotti",
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withOpacity(.5),
                ),
              ),
            )
            : ListView.builder( //LISTA PRODOTTI CARRELLO
              itemCount: prodotti.length,
              controller: carrello.scrollControllerCart,
              itemBuilder: (ctx, i) {
                final p = prodotti[i];
                return Dismissible(
                  key: ValueKey(p.uuid),
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) =>  context.read<CarrelloController>().removeArticleByUuid(uuid: p.uuid),
                  // ============================
                  // RIGA PRODOTTO (IDENTICA ALLA TUA)
                  // ============================
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // =========================
                        // RIGA PRODOTTO PRINCIPALE
                        // =========================
                        Row(
                          children: [
                            // NOME PRODOTTO
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onLongPress: () {
                                  if( p.article.generic == 0 ) return;
                                  editTitleArticle(ctx, p);
                                },
                                onTap: () {
                                  _apriVarianti(context, p);
                                },
                                child: Text(
                                  p.article.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // QUANTITÀ
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () async {
                                  final nuovaQt = await _modificaQuantita(context, p);
                                  if (nuovaQt != null) {
                                    context
                                        .read<CarrelloController>()
                                        .upgradeQuantityRowCart(p.uuid, nuovaQt);
                                  }
                                },
                                child: Box(
                                  text: p.quantity.toString(),
                                ),
                              ),
                            ),

                            // PREZZO
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () async {
                                  final nuovoPrezzo = await _modificaPrezzo(context, p);
                                  if (nuovoPrezzo != null) {
                                   
                                    context
                                        .read<CarrelloController>()
                                        .aggiornaPrezzo(p, nuovoPrezzo);
                                  }
                                },
                                child: Box(
                                  text: (p.priceRowCart).toStringAsFixed(2).replaceAll('.', ','),
                                  alignRight: true,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // =========================
                        // VARIANTI SOTTO AL PRODOTTO
                        // =========================
                        ...[ 
                          ...p.variationsFree,
                          ...p.variationsInfo,
                          ...p.variationsMinus,
                          ...p.variationsPlus
                        ].map(
                                  (v) => Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: Row(
                                  children: [

                                    // =========================
                                    // NOME VARIANTE
                                    // =========================
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getColorBgVariantRow(v.variationType!),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: getColorBgVariantRow(v.variationType!),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            "${v.variationType == 'minus' ? '-' : '+'} ${v.article.title}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // =========================
                                    // QUANTITÀ (sempre 1)
                                    // =========================
                                    Expanded(
                                      flex: 1,
                                      child: Box(
                                        text: v.quantity.toString(),
                                        small: true,
                                      ),
                                    ),

                                    // =========================
                                    // PREZZO VARIANTE
                                    // =========================
                                    Expanded(
                                      flex: 1,
                                      child: Box(
                                        text: v.priceRowCart 
                                            .toStringAsFixed(2)
                                            .replaceAll('.', ','),
                                        small: true,
                                        alignRight: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).toList(),
                          ]
                    ),), );
              },
            ),
          ),
          //L'ho messa perchè spariscono i prodotti nel carrello dietro al tastierino
          SizedBox(
            height: ( MediaQuery.of(context).size.height / 100 ) * ( crtTastierinoVisibile.tastierinoVisibile ? 40 : 20)
          )
        ],
      ),

    );
  }

  TextStyle _header(ThemeData theme) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: theme.colorScheme.onSurface,
    );
  }


  void editTitleArticle ( BuildContext context, ProdottoCarrello pro ) {
    TextEditingController _ctrTitle = TextEditingController();
    _ctrTitle.text = pro.article.title;

    // ✅ Cattura il controller PRIMA del showDialog (context valido).
    final ctrlCart = context.read<CarrelloController>();

    showDialog(
      context: context, 
      builder:(dialogCtx) {
        // ⚠️ NON wrappare con ChangeNotifierProvider.value:
        // CarrelloController è già fornito dal MultiProvider in main.dart.
        // Ri-fornirlo in un sotto-scope può rompere le subscription dei
        // widget esterni in release mode.
        return AlertDialog(
            title: Text('Modifica nome articolo'),
            content: Container(
              child: TextField(
                controller: _ctrTitle,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: (){
                  pro.article.setTitle(_ctrTitle.text);
                  ctrlCart.notifyListeners();
                  Navigator.pop(dialogCtx);
                },
                child: Text('Salva')
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Annulla')
              )
            ],
          );
      },
      );
  }


// ================================
// MODALE PER CAMBIARE PREZZO
// ================================
  Future<double?> _modificaPrezzo(
      BuildContext context, ProdottoCarrello p) async {

    final ctrl = TextEditingController();
    final theme = Theme.of(context);
     

    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // ⚠️ NON wrappare con ChangeNotifierProvider.value
        // (vedi commento in editTitleArticle).
        return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                  maxHeight: 620, //
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(22),
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                      ///  TITOLO
                      Text(
                        "Inserisci prezzo totale",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 4),

                      ///  NOME PRODOTTO
                      Text(
                        p.article.title,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface.withOpacity(.7),
                        ),
                      ),

                      const SizedBox(height: 10),

                      ///  PREZZO DIGITATO
                      AnimatedBuilder(
                        animation: ctrl,
                        builder: (_, __) {
                          return Text(
                            ctrl.text.isEmpty ? "" : ctrl.text,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 6),
                      Divider(),

                      ///  TASTIERINO
                      Expanded(
                        child: _TastierinoPrezzo(
                          controller: ctrl,
                          prodotto: p,
                        ),
                      ),


                      const SizedBox(height: 4),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                          child: const Text(
                            "Annulla",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _apriVarianti(BuildContext context, ProdottoCarrello prodotto) async {
    final controller                   = context.read<ControllerListPriceSelected>();
    final controllerVariantsController = context.read<VariantsController>();
    controllerVariantsController.reset();
    final variants                     = await ArticoloService.getVariations( prodotto, controller.listPriceSelected?.id );
    controllerVariantsController.setAllVariants(variants);
    controllerVariantsController.setQuantityArticleInRow( prodotto.quantity );
    controllerVariantsController.setArticleCurrent(prodotto);
    final ctrl = context.read<VariantsController>();
    ctrl.setQuantity(prodotto.quantity);
    showDialog(
      context: context,
      builder: (_) => VariantiDialog(
        prodotto: prodotto,
        varianti: variants,
        note: const [],
        inTable: false,
      ),
    );
  }


// ================================
// MODALE PER CAMBIARE QUANTITÀ (nuova versione)
// ================================
  Future<double?> _modificaQuantita(
      BuildContext context, ProdottoCarrello p) async {

    final ctrl = TextEditingController();
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
                maxHeight: 620, // stessa altezza del modulo prezzo
              ),
              child: Material(
                borderRadius: BorderRadius.circular(22),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// 🔹 TITOLO
                      Text(
                        "Inserisci quantità",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// 🔹 NOME PRODOTTO
                      Text(
                        p.article.title,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface.withOpacity(.7),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// 🔹 QUANTITÀ DIGITATA
                      AnimatedBuilder(
                        animation: ctrl,
                        builder: (_, __) {
                          return Text(
                            ctrl.text,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 6),
                      Divider(),

                      /// 🔹 TASTIERINO

                      Flexible(
                        fit: FlexFit.loose,
                        child: _TastierinoQuantita(
                          controller: ctrl,
                          prodotto: p,
                        ),
                      ),

                      const SizedBox(height: 4),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                        child: const Text(
                          "Annulla",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

}

class _ClienteHeader extends StatelessWidget {
  final CustomerModel cliente;
  final VoidCallback onEdit;

  const _ClienteHeader({
    required this.cliente,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            cliente.businessType == "company"
                ? Icons.business
                : Icons.person,
            size: 20,
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.businessName ?? ( [cliente.personalFirstname, cliente.personalLastname].contains(null) ? cliente.title ?? '' : ( cliente.personalFirstname! +' '+cliente.personalLastname! ) ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "edit") {
                onEdit(); // ✅ SOLO QUESTO
              }
              if (value == "delete") {
                context.read<CarrelloController>().clearCliente();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "edit", child: Text("Modifica")),
              PopupMenuItem(value: "delete", child: Text("Elimina")),
            ],
          ),
        ],
      ),
    );
  }
}


class _OrdineAttivoHeader extends StatelessWidget {
  const _OrdineAttivoHeader();

  @override
  Widget build(BuildContext context) {
    final carrello = context.watch<CarrelloController>();
    final theme = Theme.of(context);

    if (!carrello.inOrder || carrello.cliente == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ICONA TIPO
          Icon( //takeAway - delivery -eatHere
            carrello.tipoOrdine == 'delivery' ? Icons.delivery_dining : carrello.tipoOrdine == 'takeAway' ? Icons.storefront : Icons.restaurant_menu,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),

          // TESTI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carrello.cliente!.titleCustomer,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  carrello.cliente!.code ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                if (carrello.dataOrdine != null)
                  Text(
                    DateFormat('HH:mm d MMMM')
                        .format(carrello.dataOrdine!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          //  MENU 3 PUNTINI
          PopupMenuButton<_OrdineMenuAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == _OrdineMenuAction.delete) {
                _confermaEliminazione(context);
              }
              if (value == _OrdineMenuAction.edit) {
                _modificaOrdine(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _OrdineMenuAction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text(". consegna"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _OrdineMenuAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Elimina consegna"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================
  // ELIMINA ORDINE
  // ===============================
  void _confermaEliminazione(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Elimina consegna"),
          content: const Text(
            "Sei sicuro di voler eliminare questa consegna?\n"
                "L’ordine verrà annullato.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  // ===============================
  // MODIFICA ORDINE
  // ===============================
  void _modificaOrdine(BuildContext context) {
    final carrello = context.read<CarrelloController>();

    //  set ordine attivo (OBBLIGATORIO)
    final ordine = context.read<OrdineAttivoController>().ordine;
    if (ordine == null) return;

    //  reset SOLO per modifica

    // cliente
    carrello.setCliente(
      CustomerModel(
        id: ordine.cliente.id,
        title: ordine.cliente.businessName ?? 'manca nome',
        businessType: "physical_person",
        personalPhone: ordine.telefono,
        personalAddress: ordine.indirizzo,
      ),
    );

    carrello.setDataOrdine(ordine.data);

    // prodotti (NON segnano modifica)
    for (final item in ordine.articles) {
     /*  carrello.aggiungiConQuantitaPrezzo(
        id: item.nome.hashCode,
        nome: item.nome,
        prezzo: item.totale / item.quantita,
        quantita: item.quantita,
        idVatRate: 1,
        vatValue: 0.0,
      ); */
    }

    // apri sheet di modifica
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) {
          return const InserisciOrdineSheet();
        },
      ),
    );
  }

}

enum _OrdineMenuAction { edit, delete }




//tastierino quantità
class _TastierinoQuantita extends StatefulWidget {
  final TextEditingController controller;
  final ProdottoCarrello prodotto;

  const _TastierinoQuantita({
    required this.controller,
    required this.prodotto,
  });

  @override
  State<_TastierinoQuantita> createState() => _TastierinoQuantitaState();
}

class _TastierinoQuantitaState extends State<_TastierinoQuantita> {
  void _tap(String value) {
    setState(() {
      if (value == "⌫") {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.text =
              widget.controller.text.substring(0, widget.controller.text.length - 1);
        }
        return;
      }

      if (value == "00") {
        widget.controller.text += "00";
        return;
      }

      widget.controller.text += value;
    });
  }

  void _conferma() {
    final val =  double.tryParse(widget.controller.text);
    if (val == null) return;
    final carrello = context.read<CarrelloController>();
    carrello.upgradeQuantityRowCart(widget.prodotto.uuid, val);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<String> keys = [
      "7", "8", "9",
      "4", "5", "6",
      "1", "2", "3",
      "0", "00", "⌫",
    ];

    return Column(
      children: [
        SizedBox(
          height: 340, // PERFETTA per evitare overflow
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 1.65, // compattissimo
            ),
            itemBuilder: (_, i) {
              final k = keys[i];
              return ElevatedButton(
                onPressed: () => _tap(k),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
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

        // 🔵 RIGA PRINCIPALE (X + INVIO)
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _tap("⌫"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.arrow_back, size: 30),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

      ],
    );
  }
}




class _TastierinoPrezzo extends StatefulWidget {
  final TextEditingController controller;
  final ProdottoCarrello prodotto; // ← necessario per aggiornare il carrello

  const _TastierinoPrezzo({
    required this.controller,
    required this.prodotto,
  });

  @override
  State<_TastierinoPrezzo> createState() => _TastierinoPrezzoState();
}

class _TastierinoPrezzoState extends State<_TastierinoPrezzo> {
  void _tap(String value) {
    setState(() {
      if (value == "⌫") {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.text =
              widget.controller.text.substring(0, widget.controller.text.length - 1);
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
     //controlla se l'operatore puo ridurre e/o aumentare il prezzo
    bool decrementPrice = OperatoreModel.decrementPrice(widget.prodotto, valore);
    bool incrementPrice = OperatoreModel.incrementPrice(widget.prodotto, valore);
    if( [decrementPrice, incrementPrice].contains( false ) ) return;

    final carrello = context.read<CarrelloController>();

    // Aggiorna prezzo prodotto → il totale si aggiorna da solo
    carrello.upgradePriceRowCart(widget.prodotto.uuid, valore);
    // Chiudi modale
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<String> keys = [
      "7", "8", "9",
      "4", "5", "6",
      "1", "2", "3",
      "0", "00", ",",
    ];

    return Column(
      children: [
        SizedBox(
          height: 340, // PERFETTA per evitare overflow
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 1.65, // compattissimo
            ),
            itemBuilder: (_, i) {
              final k = keys[i];
              return ElevatedButton(
                onPressed: () => _tap(k),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
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

        /// RIGA FINALE (X + INVIO)
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _tap("⌫"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.arrow_back, size: 30),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class Box extends StatelessWidget {
  final String text;
  final bool small;
  final bool alignRight;

  const Box({
    required this.text,
    this.small = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: small ? 28 : 34,
      alignment:
      alignRight ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
 */

import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/widget/header_footer/ControllerListPriceSelected.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:dashboard/varianti/state/variants_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screen/sincronizzazioni/articoli/articolo_service.dart';
import '../../screen/ordini/state/ordine_attivo_controller.dart';
import '../../screen/ordini/ux/widgets/inserisci_ordine_dialog.dart';
import '../../../state/controller_carrello.dart';
import '../../../varianti/ui/varianti_dialog.dart';

// 🔥 STATEFUL con listener ESPLICITI: più robusto in release mode
class CarrelloWidget extends StatefulWidget {
  final VoidCallback onEditCliente;
  final ListPriceModel? listPrice;

  const CarrelloWidget({
    super.key,
    required this.onEditCliente,
    required this.listPrice,
  });

  @override
  State<CarrelloWidget> createState() => _CarrelloWidgetState();
}

class _CarrelloWidgetState extends State<CarrelloWidget> {
  late final CarrelloController _carrello;
  late final ControllerTastierinoAperto _crtTastierinoVisibile;
  bool _listenersAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenersAdded) {
      _listenersAdded = true;
      _carrello = context.read<CarrelloController>();
      _carrello.addListener(_rebuild);
      _crtTastierinoVisibile = context.read<ControllerTastierinoAperto>();
      _crtTastierinoVisibile.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _carrello.removeListener(_rebuild);
    _crtTastierinoVisibile.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Color getColorBgVariantRow(String type) {
    switch (type) {
      case 'minus':
        return Colors.red;
      case 'plus':
        return Colors.green;
      case 'free':
        return Colors.green;
      case 'info':
        return Colors.lightBlue;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final carrello = _carrello;
    final prodotti = carrello.prodotti.reversed.toList();
    final isDark   = theme.brightness == Brightness.dark;
    final crtTastierinoVisibile = _crtTastierinoVisibile;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // =========================
          // HEADER CLIENTE / ORDINE
          // =========================

          // IN CASO DI ORDINE SOSPESO (NOVITÀ)
          if (carrello.cartSuspended != null) Container(),
            /* Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: Color.fromARGB(255, 255, 173, 20),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.list),
                  const SizedBox(width: 8),
                  Text(
                    'Sospeso: ',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    carrello.cartSuspended!.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      try {
                        final ctrCart = context.read<CarrelloController>();
                        final cart = CartModelSaledSuspended.fromCartController(
                          ctrCart,
                          ctrCart.cartSuspended!.title,
                        );
                        final db = await LocalDB.instance();
                        final resp = await db.insert(
                          'cartsSuspended',
                          cart.toMapForDb(),
                        );
                        debugPrint(resp.toString());
                        ctrCart.clearCart();
                      } catch (err) {
                        debugPrint(err.toString());
                      }
                      context.read<CarrelloController>().clearCart();
                    },
                  ),
                ],
              ),
            ), */


          // =========================
          // LISTA PRODOTTI / STATO VUOTO
          // =========================
          Expanded(
            child: prodotti.isEmpty
                ? Center(
                    child: Text(
                      "Aggiungi prodotti",
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            theme.colorScheme.onSurface.withOpacity(.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    // LISTA PRODOTTI CARRELLO
                    itemCount: prodotti.length,
                    controller: carrello.scrollControllerCart,
                    itemBuilder: (ctx, i) {
                      final p = prodotti[i];
                      return Dismissible(
                        key: ValueKey(p.uuid),
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          //LOG ELIMINAZIONE
                          LogService.instance().saveLog(p.article.title, 'Eliminato dal carrello', '');
                          context.read<CarrelloController>().removeArticleByUuid(uuid: p.uuid);

                        },
                        // ============================
                        // RIGA PRODOTTO
                        // ============================
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // =========================
                              // RIGA PRODOTTO PRINCIPALE
                              // =========================
                              Row(
                                children: [
                                  // NOME PRODOTTO
                                  Expanded(
                                    flex: 3,
                                    child: InkWell(
                                      onLongPress: () {
                                        if (p.article.generic == 0) return;
                                        editTitleArticle(ctx, p);
                                      },
                                      onTap: () {
                                        _apriVarianti(context, p);
                                      },
                                      child: Text(
                                        p.article.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              theme.colorScheme.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // QUANTITÀ
                                  Expanded(
                                    flex: 1,
                                    child: InkWell(
                                      onTap: () async {
                                        final nuovaQt = await _modificaQuantita( context, p, );
                                        if (nuovaQt != null) {
                                          double oldQta = p.quantity;
                                          
                                          context.read<CarrelloController>().upgradeQuantityRowCart(
                                                p.uuid,
                                                nuovaQt,
                                              );
                                        }
                                      },
                                      child: Box(
                                        text: p.quantity.toString(),
                                      ),
                                    ),
                                  ),

                                  // PREZZO
                                  Expanded(
                                    flex: 1,
                                    child: InkWell(
                                      onTap: () async {
                                        final nuovoPrezzo =
                                            await _modificaPrezzo(
                                          context,
                                          p,
                                        );
                                        if (nuovoPrezzo != null) {
                                          context
                                              .read<CarrelloController>()
                                              .aggiornaPrezzo(
                                                p,
                                                nuovoPrezzo,
                                              );
                                        }
                                      },
                                      child: Box(
                                        text: (p.priceRowCart)
                                            .toStringAsFixed(2)
                                            .replaceAll('.', ','),
                                        alignRight: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // =========================
                              // VARIANTI SOTTO AL PRODOTTO
                              // =========================
                              ...[
                                ...p.variationsFree,
                                ...p.variationsInfo,
                                ...p.variationsMinus,
                                ...p.variationsPlus
                              ].map(
                                (v) => Padding(
                                  padding:
                                      const EdgeInsets.only(top: 0),
                                  child: Row(
                                    children: [
                                      // NOME VARIANTE
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(
                                            left: 12,
                                          ),
                                          child: Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  getColorBgVariantRow(
                                                v.variationType!,
                                              ),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              border: Border.all(
                                                color:
                                                    getColorBgVariantRow(
                                                  v.variationType!,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              "${v.variationType == 'minus' ? '-' : '+'} ${v.article.title}",
                                              style:
                                                  const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // QUANTITÀ VARIANTE
                                      Expanded(
                                        flex: 1,
                                        child: Box(
                                          text: v.quantity
                                              .toString(),
                                          small: true,
                                        ),
                                      ),

                                      // PREZZO VARIANTE
                                      Expanded(
                                        flex: 1,
                                        child: Box(
                                          text: v.priceRowCart
                                              .toStringAsFixed(2)
                                              .replaceAll('.', ','),
                                          small: true,
                                          alignRight: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // L'ho messa perché spariscono i prodotti nel carrello dietro al tastierino
          SizedBox(
            height: (MediaQuery.of(context).size.height / 100) *
                (crtTastierinoVisibile.tastierinoVisibile ? 40 : 20),
          ),
        ],
      ),
    );
  }

  TextStyle _header(ThemeData theme) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: theme.colorScheme.onSurface,
    );
  }

  void editTitleArticle(BuildContext context, ProdottoCarrello pro) {
    final _ctrTitle = TextEditingController();
    _ctrTitle.text = pro.article.title;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica nome articolo'),
          content: TextField(
            controller: _ctrTitle,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                pro.article.setTitle(_ctrTitle.text);
                final ctrlCart = context.read<CarrelloController>();
                ctrlCart.notifyListeners();
                Navigator.pop(context);
              },
              child: const Text('Salva'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  // ================================
  // MODALE PER CAMBIARE PREZZO
  // ================================
  Future<double?> _modificaPrezzo(
    BuildContext context,
    ProdottoCarrello p,
  ) async {
    final ctrl = TextEditingController();
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
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// TITOLO
                      Text(
                        "Inserisci prezzo totale",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// NOME PRODOTTO
                      Text(
                        p.article.title,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface
                              .withOpacity(.7),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// PREZZO DIGITATO
                      AnimatedBuilder(
                        animation: ctrl,
                        builder: (_, __) {
                          return Text(
                            ctrl.text.isEmpty ? "" : ctrl.text,
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

                      /// TASTIERINO
                      Expanded(
                        child: _TastierinoPrezzo(
                          controller: ctrl,
                          prodotto: p,
                        ),
                      ),

                      const SizedBox(height: 4),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: theme
                              .colorScheme.onSurface
                              .withOpacity(0.55),
                        ),
                        child: const Text(
                          "Annulla",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  void _apriVarianti(
    BuildContext context,
    ProdottoCarrello prodotto,
  ) async {
    final controller = context.read<ControllerListPriceSelected>();
    final controllerVariantsController =
        context.read<VariantsController>();
    controllerVariantsController.reset();
    final variants = await ArticoloService.getVariations(
      prodotto,
      controller.listPriceSelected?.id,
    );
    controllerVariantsController.setAllVariants(variants);
    controllerVariantsController
        .setQuantityArticleInRow(prodotto.quantity);
    controllerVariantsController.setArticleCurrent(prodotto);
    final ctrl = context.read<VariantsController>();
    ctrl.setQuantity(prodotto.quantity);
    showDialog(
      context: context,
      builder: (_) => VariantiDialog(
        prodotto: prodotto,
        varianti: variants,
        note: const [],
        inTable: false,
      ),
    );
  }

  // ================================
  // MODALE PER CAMBIARE QUANTITÀ
  // ================================
  Future<double?> _modificaQuantita(
    BuildContext context,
    ProdottoCarrello p,
  ) async {
    final ctrl = TextEditingController();
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
                maxHeight: 620, // stessa altezza del modulo prezzo
              ),
              child: Material(
                borderRadius: BorderRadius.circular(22),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// TITOLO
                      Text(
                        "Inserisci quantità",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// NOME PRODOTTO
                      Text(
                        p.article.title,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface
                              .withOpacity(.7),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// QUANTITÀ DIGITATA
                      AnimatedBuilder(
                        animation: ctrl,
                        builder: (_, __) {
                          return Text(
                            ctrl.text,
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

                      /// TASTIERINO
                      Flexible(
                        fit: FlexFit.loose,
                        child: _TastierinoQuantita(
                          controller: ctrl,
                          prodotto: p,
                        ),
                      ),

                      const SizedBox(height: 4),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: theme
                              .colorScheme.onSurface
                              .withOpacity(0.55),
                        ),
                        child: const Text(
                          "Annulla",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
}

class _ClienteHeader extends StatelessWidget {
  final CustomerModel cliente;
  final VoidCallback onEdit;

  const _ClienteHeader({
    required this.cliente,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            cliente.businessType == "company"
                ? Icons.business
                : Icons.person,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.businessName ??
                      ([cliente.personalFirstname,
                                  cliente.personalLastname]
                              .contains(null)
                          ? cliente.title ?? ''
                          : (cliente.personalFirstname! +
                              ' ' +
                              cliente.personalLastname!)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "edit") {
                onEdit();
              }
              if (value == "delete") {
                context
                    .read<CarrelloController>()
                    .clearCliente();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: "edit",
                child: Text("Modifica"),
              ),
              PopupMenuItem(
                value: "delete",
                child: Text("Elimina"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔥 STATEFUL con listener ESPLICITO: più robusto in release mode
class _OrdineAttivoHeader extends StatefulWidget {
  const _OrdineAttivoHeader();

  @override
  State<_OrdineAttivoHeader> createState() => _OrdineAttivoHeaderState();
}

class _OrdineAttivoHeaderState extends State<_OrdineAttivoHeader> {
  late final CarrelloController _carrello;
  bool _listenerAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _listenerAdded = true;
      _carrello = context.read<CarrelloController>();
      _carrello.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _carrello.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final carrello = _carrello;
    final theme = Theme.of(context);

    if (!carrello.inOrder || carrello.cliente == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ICONA TIPO
          Icon(
            // takeAway - delivery - eatHere
            carrello.tipoOrdine == 'delivery'
                ? Icons.delivery_dining
                : carrello.tipoOrdine == 'takeAway'
                    ? Icons.storefront
                    : Icons.restaurant_menu,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),

          // TESTI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carrello.cliente!.titleCustomer,
                  style:
                      theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  carrello.cliente!.code ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                if (carrello.dataOrdine != null)
                  Text(
                    DateFormat('HH:mm d MMMM')
                        .format(carrello.dataOrdine!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme
                          .colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // MENU 3 PUNTINI
          PopupMenuButton<_OrdineMenuAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == _OrdineMenuAction.delete) {
                _confermaEliminazione(context);
              }
              if (value == _OrdineMenuAction.edit) {
                _modificaOrdine(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _OrdineMenuAction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text(". consegna"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _OrdineMenuAction.delete,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text("Elimina consegna"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================
  // ELIMINA ORDINE
  // ===============================
  void _confermaEliminazione(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Elimina consegna"),
          content: const Text(
            "Sei sicuro di voler eliminare questa consegna?\n"
            "L’ordine verrà annullato.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  // ===============================
  // MODIFICA ORDINE
  // ===============================
  void _modificaOrdine(BuildContext context) {
    final carrello = context.read<CarrelloController>();

    // set ordine attivo (OBBLIGATORIO)
    final ordine =
        context.read<OrdineAttivoController>().ordine;
    if (ordine == null) return;

    // cliente
    carrello.setCliente(
      ordine.cliente == null ? null :
      CustomerModel(
        id: ordine.cliente!.id,
        title: ordine.cliente!.businessName ?? 'manca nome',
        businessType: "physical_person",
        personalPhone: ordine.telefono,
        personalAddress: ordine.indirizzo,
      ),
    );

    carrello.setDataOrdine(ordine.data);

    // prodotti (NON segnano modifica)
    for (final item in ordine.articles) {
      /*  carrello.aggiungiConQuantitaPrezzo(
        id: item.nome.hashCode,
        nome: item.nome,
        prezzo: item.totale / item.quantita,
        quantita: item.quantita,
        idVatRate: 1,
        vatValue: 0.0,
      ); */
    }

    // apri sheet di modifica
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) {
          return InserisciOrdineSheet(ordineTipo: null);
        },
      ),
    );
  }
}

enum _OrdineMenuAction { edit, delete }

// tastierino quantità
class _TastierinoQuantita extends StatefulWidget {
  final TextEditingController controller;
  final ProdottoCarrello prodotto;

  const _TastierinoQuantita({
    required this.controller,
    required this.prodotto,
  });

  @override
  State<_TastierinoQuantita> createState() =>
      _TastierinoQuantitaState();
}

class _TastierinoQuantitaState
    extends State<_TastierinoQuantita> {
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

      if (value == "00") {
        widget.controller.text += "00";
        return;
      }

      widget.controller.text += value;
    });
  }

  void _conferma() {
    final val = double.tryParse(widget.controller.text);
    if (val == null) return;
    //log decremento qta
    if( val < widget.prodotto.quantity ) LogService.instance().saveLog(widget.prodotto.article.title, 'decremento da ${widget.prodotto.quantity} a $val', '');
    final carrello = context.read<CarrelloController>();
    carrello.upgradeQuantityRowCart(
      widget.prodotto.uuid,
      val,
    );
    Navigator.pop(context);
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
      "⌫",
    ];

    return Column(
      children: [
        SizedBox(
          height: 340, // per evitare overflow
          child: GridView.builder(
            physics:
                const NeverScrollableScrollPhysics(),
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
                  backgroundColor: theme
                      .colorScheme.onSurface
                      .withOpacity(0.05),
                  foregroundColor:
                      theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
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
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child:
                    const Icon(Icons.close, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _conferma,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
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
        const SizedBox(height: 10),
      ],
    );
  }
}

class _TastierinoPrezzo extends StatefulWidget {
  final TextEditingController controller;
  final ProdottoCarrello prodotto;

  const _TastierinoPrezzo({
    required this.controller,
    required this.prodotto,
  });

  @override
  State<_TastierinoPrezzo> createState() => _TastierinoPrezzoState();
}

class _TastierinoPrezzoState extends State<_TastierinoPrezzo> {
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
    final testo =
        widget.controller.text.replaceAll(",", ".");
    final valore = double.tryParse(testo);

    if (valore == null) return;

    // controlla se l'operatore può ridurre/aumentare il prezzo
    final decrementPrice =
        OperatoreModel.decrementPrice(
      widget.prodotto,
      valore,
    );
    final incrementPrice =
        OperatoreModel.incrementPrice(
      widget.prodotto,
      valore,
    );
    if ([decrementPrice, incrementPrice].contains(false)) {
      return;
    }
    if( valore < widget.prodotto.priceRowCart ) LogService.instance().saveLog(widget.prodotto.article.title, 'Prezzo da ${widget.prodotto.priceRowCart } a $valore', '');
    final carrello = context.read<CarrelloController>();

    // Aggiorna prezzo prodotto → il totale si aggiorna da solo
    carrello.upgradePriceRowCart(
      widget.prodotto.uuid,
      valore,
    );

    Navigator.pop(context);
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
            physics:
                const NeverScrollableScrollPhysics(),
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
                  backgroundColor: theme
                      .colorScheme.onSurface
                      .withOpacity(0.05),
                  foregroundColor:
                      theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
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
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child:
                    const Icon(Icons.close, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _conferma,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF8BC540),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
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

class Box extends StatelessWidget {
  final String text;
  final bool small;
  final bool alignRight;

  const Box({
    required this.text,
    this.small = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: small ? 28 : 34,
      alignment:
          alignRight ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
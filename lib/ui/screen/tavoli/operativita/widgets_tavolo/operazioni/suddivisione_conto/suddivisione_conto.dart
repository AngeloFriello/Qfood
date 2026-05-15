
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../../../state/controller_carrello.dart';
import '../../../../../checkout/checkout_page.dart';
import '../../../../../checkout/controller_modulo_pagamenti.dart';
import '../../../../tavoli_vista.dart';
import '../../controllerTableOpened.dart';

const Color verdeQFood = Color(0xFF557C00);
const Color violaQFood = Color(0xFF557C00);
const Color bluHeader = Color(0xFF557C00);

class SuddivisioneContoDialog extends StatefulWidget {
  final double totale;
  final Function(List<QuotaDivisione>)? onConferma;

  const SuddivisioneContoDialog({
    super.key,
    required this.totale,
    this.onConferma,
  });

  @override
  State<SuddivisioneContoDialog> createState() =>
      _SuddivisioneContoDialogState();
}

class _SuddivisioneContoDialogState
    extends State<SuddivisioneContoDialog> {

  final TextEditingController divisioneCtrl =
  TextEditingController();

  final ScrollController scrollController =
  ScrollController();




  List<QuotaDivisione> quote = [];

  OverlayEntry? keypadOverlay;

  int? quotaEditing;

  @override
  void initState() {
    super.initState();

    quote = [];
  }

  @override
  void dispose() {
    keypadOverlay?.remove();
    divisioneCtrl.dispose();
    scrollController.dispose();
    super.dispose();
  }

  //==================================================
  // GENERA QUOTE
  //==================================================
  void generaQuote(int persone) {

    if (persone <= 0) {
      persone = 1;
    }

    //==================================================
    // SALVA DIVISIONE GLOBALE
    //==================================================

    context
        .read<CarrelloController>()
        .setDivisioneContoPersone(persone);

    final ctrlTable =
    context.read<ControllerTableOpened>();

    final double totale =
    ctrlTable.products.fold<double>(
      0,
          (sum, p) =>
      sum + (p.priceRowCart * p.quantity),
    );

    final quotaBase = double.parse(
      (totale / persone).toStringAsFixed(2),
    );

    double totaleAssegnato = 0;

    final nuove = <QuotaDivisione>[];

    for (int i = 0; i < persone; i++) {

      double importo = quotaBase;

      //==================================================
      // ULTIMA QUOTA FIX CENTESIMI
      //==================================================

      if (i == persone - 1) {

        importo = double.parse(
          (totale - totaleAssegnato)
              .toStringAsFixed(2),
        );
      }

      totaleAssegnato += importo;

      nuove.add(
        QuotaDivisione(
          index: i + 1,

          importo: importo,

          quantity: 1,

          pagata: false,

          selezionata: false,

          // SOLO LA PRIMA ATTIVA
          bloccata: i != 0,

          modificata: false,
        ),
      );
    }

    setState(() {

      quote = nuove;

      //==================================================
      // AGGIORNA INPUT DIVISIONE
      //==================================================

      divisioneCtrl.text = persone.toString();
    });
  }
  //==================================================
  // RESTANTE
  //==================================================

  double get restante {

    double totale = 0;

    for (final q in quote) {

      totale += q.importo;
    }

    return double.parse(
      totale.toStringAsFixed(2),
    );
  }
  //==================================================
  // SELEZIONATE
  //==================================================

  List<QuotaDivisione> get selezionate =>
      quote.where((e) => e.selezionata).toList();

  //==================================================
  // SBLOCCA
  //==================================================

  void sbloccaProssimaQuota() {

    for (final q in quote) {

      if (!q.pagata) {
        q.bloccata = false;
        break;
      }
    }
  }

  //==================================================
  // PAGA
  //==================================================

  void pagaQuota(QuotaDivisione quota) {

    setState(() {

      quota.pagata = true;
      quota.bloccata = true;
      quota.selezionata = false;

      sbloccaProssimaQuota();
    });
  }

  //==================================================
// UNISCI QUOTE FIX REALE
// -> CREA UNA SOLA CELLA VISIBILE
// -> SOMMA IMPORTI
// -> NASCONDE LE ALTRE
//==================================================
  void unisciQuote() {

    final items = quote
        .where(
          (q) =>
      q.selezionata &&
          !q.pagata,
    )
        .toList();

    if (items.length < 2) return;

    double totaleUnito = 0;

    for (final q in items) {
      totaleUnito += q.importo;
    }

    setState(() {

      //========================================
      // QUOTA PRINCIPALE
      //========================================

      final principale = items.first;

      principale.importo = double.parse(
        totaleUnito.toStringAsFixed(2),
      );

      principale.selezionata = false;
      principale.bloccata = false;

      //========================================
      // RIMUOVI LE ALTRE
      //========================================

      for (int i = 1; i < items.length; i++) {

        quote.removeWhere(
              (q) => q.index == items[i].index,
        );
      }

      //========================================
      // RIORDINA INDICI
      //========================================

      for (int i = 0; i < quote.length; i++) {

        quote[i].index = i + 1;
      }

      //========================================
      // AGGIORNA DIVISIONE
      //========================================

      divisioneCtrl.text = quote.length.toString();

      //========================================
      // SOLO PRIMA ATTIVA
      //========================================

      bool first = true;

      for (final q in quote) {

        if (!q.pagata) {

          q.bloccata = !first;

          first = false;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: violaQFood,
        content: Text(
          "Quote unite € ${totaleUnito.toStringAsFixed(2)}",
        ),
      ),
    );
  }


  void aggiungiQuota() {

    final ctrlTable =
    context.read<ControllerTableOpened>();

    final totale = ctrlTable.products.fold<double>(
      0,
          (sum, p) =>
      sum + (p.priceRowCart * p.quantity),
    );

    double totaleAttuale = 0;

    for (final q in quote) {
      totaleAttuale += q.importo;
    }

    final nuovaQuota = QuotaDivisione(
      index: quote.length + 1,
      importo: 0,
      quantity: 1,
      pagata: false,
      selezionata: false,
      bloccata: true,
      modificata: false,
    );

    setState(() {

      quote.add(nuovaQuota);

      divisioneCtrl.text = quote.length.toString();

      final quotaBase = double.parse(
        (totale / quote.length)
            .toStringAsFixed(2),
      );

      double assegnato = 0;

      for (int i = 0; i < quote.length; i++) {

        if (i == quote.length - 1) {

          quote[i].importo = double.parse(
            (totale - assegnato)
                .toStringAsFixed(2),
          );
        } else {

          quote[i].importo = quotaBase;
          assegnato += quotaBase;
        }
      }
    });
  }

  //==================================================
  // MODIFICA IMPORTO
  //==================================================
  void modificaImporto(
      QuotaDivisione quota,
      String value,
      ) {

    final ctrlTable =
    context.read<ControllerTableOpened>();

    final double totaleReale =
    ctrlTable.products.fold<double>(
      0,
          (sum, p) =>
      sum + (p.priceRowCart * p.quantity),
    );

    double nuovo = double.tryParse(
      value.replaceAll(",", "."),
    ) ??
        0;

    if (nuovo <= 0) return;

    //========================================
    // NON PUÒ SUPERARE IL TOTALE
    //========================================

    if (nuovo >= totaleReale) return;

    setState(() {

      //========================================
      // AGGIORNA QUOTA MODIFICATA
      //========================================

      quota.importo = double.parse(
        nuovo.toStringAsFixed(2),
      );

      quota.modificata = true;

      //========================================
      // TOTALE GIÀ OCCUPATO
      //========================================

      double totaleOccupato = 0;

      for (final q in quote) {

        if (q.modificata) {
          totaleOccupato += q.importo;
        }
      }

      //========================================
      // QUOTE NON MODIFICATE
      //========================================

      final nonModificate = quote.where(
            (q) => !q.modificata,
      ).toList();

      //========================================
      // RESTANTE DA DISTRIBUIRE
      //========================================

      double restante =
          totaleReale - totaleOccupato;

      if (restante < 0) {
        restante = 0;
      }

      //========================================
      // NESSUNA QUOTA DA AGGIORNARE
      //========================================

      if (nonModificate.isEmpty) return;

      //========================================
      // RIDISTRIBUZIONE
      //========================================

      final quotaBase = double.parse(
        (restante / nonModificate.length)
            .toStringAsFixed(2),
      );

      double assegnato = 0;

      for (int i = 0;
      i < nonModificate.length;
      i++) {

        final q = nonModificate[i];

        double importo = quotaBase;

        //========================================
        // ULTIMA QUOTA FIX CENTESIMI
        //========================================

        if (i == nonModificate.length - 1) {

          importo = double.parse(
            (restante - assegnato)
                .toStringAsFixed(2),
          );
        }

        q.importo = importo;

        assegnato += importo;
      }
    });
  }
  //==================================================
  // KEYPAD
  //==================================================

  void apriKeypad({
    required BuildContext context,
    required RenderBox renderBox,
    required QuotaDivisione quota,
  }) {

    chiudiKeypad();

    quotaEditing = quota.index;

    final overlay =
    Overlay.of(context).context.findRenderObject()
    as RenderBox;

    final position = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    keypadOverlay = OverlayEntry(
      builder: (_) {

        return Stack(
          children: [

            Positioned.fill(
              child: GestureDetector(
                onTap: chiudiKeypad,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            Positioned(
              left: position.dx - 40,
              top: position.dy + 60,
              child: _CustomKeypad(
                onValue: (v) {

                  String current =
                  quota.importo.toStringAsFixed(2);

                  if (v == "DEL") {

                    current = current.substring(
                      0,
                      current.length - 1,
                    );

                    if (current.isEmpty) {
                      current = "0";
                    }
                  } else {

                    if (current == "0.00") {
                      current = "";
                    }

                    current += v;
                  }

                  modificaImporto(
                    quota,
                    current,
                  );
                },
                onClose: chiudiKeypad,
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(keypadOverlay!);
  }

  void chiudiKeypad() {
    keypadOverlay?.remove();
    keypadOverlay = null;
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF171717)
        : const Color(0xFFF3F3F3);

    final card = isDark
        ? const Color(0xFF232323)
        : Colors.white;

    final text =
    isDark ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),

      child: Container(
        width: 1050,
        height: 760,

        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),

        child: Column(
          children: [

            //==================================================
            // HEADER
            //==================================================

            Container(
              height: 74,
              padding:
              const EdgeInsets.symmetric(horizontal: 18),

              decoration: const BoxDecoration(
                color: bluHeader,

                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),

              child: Row(
                children: [

                  InkWell(
                    onTap: () => Navigator.pop(context),

                    borderRadius:
                    BorderRadius.circular(10),

                    child: Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color:
                        Colors.black.withOpacity(.22),

                        borderRadius:
                        BorderRadius.circular(10),
                      ),

                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Text(
                      "Suddivisione conto",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Text(
                    "Restante: ${restante.toStringAsFixed(2)} €",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),

                child: Column(
                  children: [

                    //==================================================
                    // WARNING
                    //==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),

                      child: const Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Attenzione!",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "Suddividendo il conto non sarà possibile effettuare una rielaborazione del tavolo.",
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    //==================================================
                    // DIVISIONE
                    //==================================================
// DIVISIONE
//==================================================
                    GestureDetector(
                      onTap: () async {

                        final focusNode = FocusNode();

                        final ctrl = TextEditingController();

                        if (divisioneCtrl.text.isNotEmpty &&
                            divisioneCtrl.text != "0") {
                          ctrl.text = divisioneCtrl.text;
                        }

                        final theme = Theme.of(context);

                        final size = MediaQuery.of(context).size;

                        final bool isMobile = size.width < 700;

                        final value = await showDialog<int>(
                          context: context,
                          barrierDismissible: false,

                          builder: (_) {

                            WidgetsBinding.instance.addPostFrameCallback((_) {

                              focusNode.requestFocus();

                              ctrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: ctrl.text.length,
                              );
                            });

                            return Dialog(
                              backgroundColor: Colors.transparent,

                              insetPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 40,
                                vertical: 24,
                              ),

                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                    isMobile
                                        ? double.infinity
                                        : 460,

                                    maxHeight:
                                    size.height * .85,
                                  ),

                                  child: Material(
                                    borderRadius:
                                    BorderRadius.circular(28),

                                    color: theme.colorScheme.surface,

                                    child: Padding(
                                      padding:
                                      const EdgeInsets.fromLTRB(
                                        24,
                                        20,
                                        24,
                                        16,
                                      ),

                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,

                                        children: [

                                          //================================
                                          // TITOLO
                                          //================================

                                          Text(
                                            "Divisione conto",

                                            style: theme
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          //================================
                                          // SOTTOTITOLO
                                          //================================

                                          Text(
                                            "Inserisci numero persone",

                                            style: theme
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(.6),
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          //================================
                                          // NUMERO DIGITATO
                                          //================================

                                          SizedBox(
                                            height: 70,

                                            child: Center(
                                              child: SizedBox(
                                                width: 180,

                                                child: TextField(
                                                  controller: ctrl,
                                                  focusNode: focusNode,


                                                  keyboardType: TextInputType.number,

                                                  textAlign: TextAlign.center,

                                                  style: theme.textTheme.displaySmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),

                                                  cursorColor: verdeQFood,

                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,

                                                    hintText: "",
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          Divider(
                                            color: theme
                                                .colorScheme
                                                .outlineVariant,
                                          ),

                                          const SizedBox(height: 10),

                                          //================================
                                          // TASTIERINO
                                          //================================

                                          Flexible(
                                            child: GridView.builder(
                                              shrinkWrap: true,

                                              physics:
                                              const NeverScrollableScrollPhysics(),

                                              itemCount: 12,

                                              gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 12,
                                                crossAxisSpacing: 12,
                                                childAspectRatio: 1.35,
                                              ),

                                              itemBuilder: (_, i) {

                                                final items = [
                                                  "7","8","9",
                                                  "4","5","6",
                                                  "1","2","3",
                                                  "C","0","OK",
                                                ];

                                                final item = items[i];

                                                final isOk =
                                                    item == "OK";

                                                final isClear =
                                                    item == "C";

                                                return FilledButton(
                                                  style:
                                                  FilledButton.styleFrom(
                                                    elevation: 0,

                                                    backgroundColor:
                                                    isOk
                                                        ? verdeQFood
                                                        : theme
                                                        .colorScheme
                                                        .surfaceContainerHighest,

                                                    foregroundColor:
                                                    isOk
                                                        ? Colors.white
                                                        : theme
                                                        .colorScheme
                                                        .onSurface,

                                                    shape:
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        22,
                                                      ),
                                                    ),
                                                  ),

                                                  onPressed: () {

                                                    if (isClear) {
                                                      ctrl.clear();
                                                      return;
                                                    }

                                                    if (isOk) {

                                                      final value =
                                                          int.tryParse(
                                                            ctrl.text,
                                                          ) ??
                                                              0;

                                                      if (value <= 0) {
                                                        return;
                                                      }

                                                      Navigator.pop(
                                                        context,
                                                        value,
                                                      );

                                                      return;
                                                    }

                                                    if (ctrl.text == "0") {
                                                      ctrl.text = item;
                                                    } else {
                                                      ctrl.text += item;
                                                    }

                                                    ctrl.selection = TextSelection.fromPosition(
                                                      TextPosition(
                                                        offset: ctrl.text.length,
                                                      ),
                                                    );
                                                  },

                                                  child: Text(
                                                    item,

                                                    style: const TextStyle(
                                                      fontSize: 26,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                          const SizedBox(height: 14),

                                          //================================
                                          // BOTTONI AZIONE
                                          //================================

                                          Row(
                                            children: [

                                              // RESET

                                              Expanded(
                                                child: SizedBox(
                                                  height: 54,

                                                  child: FilledButton(
                                                    style:
                                                    FilledButton.styleFrom(
                                                      backgroundColor:
                                                      theme
                                                          .colorScheme
                                                          .surfaceContainerHighest,

                                                      foregroundColor:
                                                      theme
                                                          .colorScheme
                                                          .onSurface,

                                                      shape:
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                      ),
                                                    ),

                                                    onPressed: () {
                                                      ctrl.clear();
                                                    },

                                                    child: const Icon(
                                                      Icons.close,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 16),

                                              // CONFERMA

                                              Expanded(
                                                child: SizedBox(
                                                  height: 54,

                                                  child: FilledButton(
                                                    style:
                                                    FilledButton.styleFrom(
                                                      backgroundColor:
                                                      verdeQFood,

                                                      foregroundColor:
                                                      Colors.white,

                                                      shape:
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                      ),
                                                    ),

                                                    onPressed: () {

                                                      final value =
                                                          int.tryParse(
                                                            ctrl.text,
                                                          ) ??
                                                              0;

                                                      if (value <= 0) {
                                                        return;
                                                      }

                                                      Navigator.of(
                                                        context,
                                                      ).pop(value);
                                                    },

                                                    child: const Icon(
                                                      Icons.arrow_forward,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          //================================
                                          // ANNULLA
                                          //================================

                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },

                                            child: Text(
                                              "Annulla",

                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(.5),
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

                        if (value != null && value > 0) {

                          setState(() {

                            divisioneCtrl.text =
                                value.toString();
                          });

                          generaQuote(value);
                        }
                      },

                      child: Container(
                        height: 64,

                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),

                        decoration: BoxDecoration(
                          color: card,
                          borderRadius:
                          BorderRadius.circular(10),
                        ),

                        child: Row(
                          children: [

                            const Text(
                              "Divisione per",

                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(width: 30),

                            Text(
                              divisioneCtrl.text.isEmpty
                                  ? "-"
                                  : divisioneCtrl.text,

                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: verdeQFood,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    //==================================================
                    // LISTA
                    //==================================================
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: quote.isEmpty

                        //==================================================
                        // EMPTY STATE
                        //==================================================
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              Icon(
                                Icons.point_of_sale_rounded,
                                size: 58,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.black26,
                              ),

                              const SizedBox(height: 18),

                              Text(
                                "Inserisci il numero di divisioni",

                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "Premi su 'Divisione per' per iniziare",

                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        )

                        //==================================================
                        // LISTA QUOTE
                        //==================================================
                            : Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,

                          child: ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(10),

                            itemCount: quote.length,

                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12,
                            ),

                            itemBuilder: (_, index) {

                              final quota = quote[index];

                              final attiva =
                                  !quota.bloccata &&
                                      !quota.pagata;

                              return SizedBox(
                                height: 84,

                                child: Row(
                                  children: [

                                    //==================================================
                                    // CHECKBOX
                                    //==================================================

                                    SizedBox(
                                      width: 60,

                                      child: Checkbox(

                                        value: quota.selezionata,

                                        activeColor: verdeQFood,

                                        side: BorderSide(
                                          color: quota.bloccata
                                              ? Colors.white24
                                              : Colors.white,
                                          width: 2,
                                        ),

                                        onChanged:
                                        (quota.pagata || quota.bloccata)
                                            ? null
                                            : (v) {

                                          setState(() {

                                            quota.selezionata = v ?? false;

                                            final almenoUna = quote.any(
                                                  (q) => q.selezionata,
                                            );

                                            //==========================================
                                            // SELEZIONE MULTIPLA
                                            //==========================================

                                            if (almenoUna) {

                                              for (final q in quote) {

                                                if (!q.pagata) {
                                                  q.bloccata = false;
                                                }
                                              }
                                            }

                                            //==========================================
                                            // SOLO PRIMA DISPONIBILE
                                            //==========================================

                                            else {

                                              bool first = true;

                                              for (final q in quote) {

                                                if (!q.pagata) {

                                                  q.bloccata = !first;

                                                  first = false;
                                                }
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),

                                    //==================================================
                                    // QT
                                    //==================================================

                                    Expanded(
                                      flex: 4,

                                      child: GestureDetector(

                                        onTap: quota.pagata
                                            ? null
                                            : () async {

                                          final ctrl = TextEditingController(
                                            text: "1",
                                          );

                                          final value = await showDialog<int>(
                                            context: context,
                                            barrierDismissible: false,

                                            builder: (_) {

                                              return _NumericPadDialog(
                                                title: "Quantità",
                                                subtitle: "Inserisci quantità",
                                                controller: ctrl,
                                                isDecimal: false,
                                              );
                                            },
                                          );

                                          if (value == null) return;

                                          setState(() {

                                            quota.quantity = value;

                                            final totale =
                                            context
                                                .read<ControllerTableOpened>()
                                                .products
                                                .fold<double>(
                                              0,
                                                  (sum, p) =>
                                              sum + (p.priceRowCart * p.quantity),
                                            );

                                            //========================================
                                            // TOTALE PERSONE
                                            //========================================

                                            int totalePersone = 0;

                                            for (final q in quote) {
                                              totalePersone += q.quantity;
                                            }

                                            //========================================
                                            // VALORE SINGOLA PERSONA
                                            //========================================

                                            final quotaPersona =
                                                totale / totalePersone;

                                            //========================================
                                            // RICALCOLO TUTTE LE QUOTE
                                            //========================================

                                            double assegnato = 0;

                                            for (int i = 0; i < quote.length; i++) {

                                              final q = quote[i];

                                              double importo =
                                                  quotaPersona * q.quantity;

                                              if (i == quote.length - 1) {

                                                importo =
                                                    totale - assegnato;
                                              }

                                              q.importo = double.parse(
                                                importo.toStringAsFixed(2),
                                              );

                                              assegnato += q.importo;
                                            }
                                          });
                                        },

                                        child: Container(
                                          height: 58,

                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2C2C2C)
                                                : const Color(0xFFF8F8F8),

                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),

                                          child: Row(
                                            children: [

                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                  ),

                                                  child: Text(
                                                    "Qt",

                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: text,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              Container(
                                                width: 1,
                                                height: 34,
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.black12,
                                              ),

                                              SizedBox(
                                                width: 90,

                                                child: Center(
                                                  child: Text(
                                                    quota.quantity.toString(),

                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      color: text,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    //==================================================
                                    // IMPORTO
                                    //==================================================

                                    Expanded(
                                      flex: 4,

                                      child: GestureDetector(

                                        onTap: quota.pagata
                                            ? null
                                            : () async {

                                          final ctrl = TextEditingController(
                                            text: quota.importo
                                                .toStringAsFixed(2),
                                          );

                                          final value =
                                          await showDialog<double>(
                                            context: context,
                                            barrierDismissible: false,

                                            builder: (_) {

                                              return _NumericPadDialog(
                                                title: "Importo",
                                                subtitle: "Inserisci importo",
                                                controller: ctrl,
                                                isDecimal: true,
                                              );
                                            },
                                          );

                                          if (value == null) return;

                                          modificaImporto(
                                            quota,
                                            value.toString(),
                                          );
                                        },

                                        child: Container(
                                          height: 58,

                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 18,
                                          ),

                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2C2C2C)
                                                : const Color(0xFFF8F8F8),

                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),

                                          child: Row(
                                            children: [

                                              Text(
                                                "Imp.",

                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: text,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                ),
                                              ),

                                              const Spacer(),

                                              Text(
                                                quota.importo
                                                    .toStringAsFixed(2),

                                                style: TextStyle(
                                                  fontSize: 22,
                                                  color: quota.pagata
                                                      ? Colors.white38
                                                      : text,

                                                  fontWeight:
                                                  FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    //==================================================
                                    // BOTTONE CONTO
                                    //==================================================

                                    SizedBox(
                                      width: 120,
                                      height: 58,

                                      child: ElevatedButton(

                                        onPressed: attiva
                                            ? () async {

                                          final carrello =
                                          context.read<CarrelloController>();

                                          final ctrPagamenti =
                                          context.read<ControllerModuloPagamenti>();

                                          carrello.resetPayments();

                                          ctrPagamenti
                                              .resetPaymentSelectedInCheckout();

                                          carrello.setTotaleForzatoCheckout(
                                            quota.importo,
                                          );

                                          final result =
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                              const CheckoutPage(),
                                            ),
                                          );

                                          carrello
                                              .setTotaleForzatoCheckout(null);
                                          if (result == true) {

                                            setState(() {

                                              debugPrint("======================================");
                                              debugPrint("-> QUOTA PAGATA");
                                              debugPrint("-> Quota index: ${quota.index}");
                                              debugPrint("-> Importo: €${quota.importo}");
                                              debugPrint("======================================");

                                              //========================================
                                              // RIMUOVI QUOTA PAGATA
                                              //========================================

                                              quote.remove(quota);

                                              //========================================
                                              // RIORDINA INDICI
                                              //========================================

                                              for (int i = 0; i < quote.length; i++) {

                                                quote[i].index = i + 1;
                                              }

                                              //========================================
                                              // BLOCCA TUTTE
                                              //========================================

                                              for (final q in quote) {

                                                q.bloccata = true;
                                                q.selezionata = false;
                                              }

                                              //========================================
                                              // SBLOCCA SOLO LA PRIMA
                                              //========================================

                                              if (quote.isNotEmpty) {

                                                quote[0].bloccata = false;
                                              }

                                              //========================================
                                              // AGGIORNA INPUT
                                              //========================================

                                              divisioneCtrl.text =
                                                  quote.length.toString();

                                              debugPrint(
                                                "-> RESTANTE: €${restante.toStringAsFixed(2)}",
                                              );

                                              debugPrint(
                                                "-> QUOTE RIMANENTI: ${quote.length}",
                                              );

                                              debugPrint("======================================");
                                            });

                                            //========================================
                                            // TUTTE LE QUOTE PAGATE
                                            //========================================
// TUTTE LE QUOTE PAGATE

                                            //========================================
// TUTTE LE QUOTE PAGATE
//========================================
                                            //========================================
// TUTTE LE QUOTE PAGATE
//========================================
                                            if (quote.isEmpty) {

                                              debugPrint("======================================");
                                              debugPrint("-> TUTTE LE QUOTE PAGATE");
                                              debugPrint("-> RESET TAVOLO");
                                              debugPrint("======================================");

                                              // RESET CARRELLO
                                              context.read<CarrelloController>().clearCart();

                                              // RESET PAGAMENTI
                                              context
                                                  .read<ControllerModuloPagamenti>()
                                                  .resetPaymentSelectedInCheckout();

                                              // CHIUDE CHECKOUT + DIALOG
                                              Navigator.of(context, rootNavigator: true)
                                                  .popUntil((route) => route.isFirst);

                                              return;
                                            }
                                          }
                                        }
                                            : null,

                                        style:
                                        ElevatedButton.styleFrom(
                                          elevation: 0,

                                          backgroundColor:
                                          verdeQFood,

                                          disabledBackgroundColor:
                                          verdeQFood.withOpacity(.35),

                                          foregroundColor:
                                          Colors.white,

                                          padding: EdgeInsets.zero,

                                          shape:
                                          RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),

                                        child: const Center(
                                          child: Text(
                                            "Conto",

                                            maxLines: 1,

                                            overflow:
                                            TextOverflow.ellipsis,

                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight:
                                              FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    //==================================================
                    // UNISCI
                    //==================================================

                    if (selezionate.length >= 2)
                      Container(
                        height: 70,
                        margin:
                        const EdgeInsets.only(top: 12),

                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF557C00),
                              Color(0xFF557C00),
                            ],
                          ),

                          borderRadius:
                          BorderRadius.circular(8),
                        ),

                        child: Material(
                          color: Colors.transparent,

                          child: InkWell(
                            borderRadius:
                            BorderRadius.circular(8),

                            onTap: unisciQuote,

                            child: const Center(
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,

                                children: [

                                  Icon(
                                    Icons.device_hub,
                                    color: Colors.white,
                                  ),

                                  SizedBox(width: 10),

                                  Text(
                                    "Unisci",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight:
                                      FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
  }
}

//==================================================
// MODEL
//==================================================
//==================================================
// MODEL
//==================================================

class QuotaDivisione {

  int index;

  double importo;

  int quantity;

  bool pagata;

  bool selezionata;

  bool bloccata;

  bool modificata;

  QuotaDivisione({
    required this.index,
    required this.importo,
    required this.quantity,
    required this.pagata,
    required this.selezionata,
    required this.bloccata,
    required this.modificata,
  });
}

//==================================================
// NUMERIC PAD DIALOG
//==================================================

class _NumericPadDialog extends StatefulWidget {

  final String title;
  final String subtitle;

  final TextEditingController controller;

  final bool isDecimal;

  const _NumericPadDialog({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.isDecimal,
  });

  @override
  State<_NumericPadDialog> createState() =>
      _NumericPadDialogState();
}

//==================================================
// NUMERIC PAD DIALOG
// GRAFICA IDENTICA ALLA TUA
//==================================================


class _NumericPadDialogState
    extends State<_NumericPadDialog> {

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      focusNode.requestFocus();

      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  Widget _key(
      BuildContext context,
      String value,
      void Function(void Function()) refresh, {
        Color? bg,
        bool confirm = false,
      }) {

    return Expanded(
      child: SizedBox(
        height: 86,

        child: FilledButton(
          onPressed: () {

            //================================
            // CONFERMA
            //================================

            if (confirm) {

              if (widget.controller.text.isEmpty) {
                return;
              }

              if (widget.isDecimal) {

                Navigator.pop(
                  context,
                  double.tryParse(
                    widget.controller.text
                        .replaceAll(",", "."),
                  ),
                );

              } else {

                Navigator.pop(
                  context,
                  int.tryParse(
                    widget.controller.text,
                  ),
                );
              }

              return;
            }

            //================================
            // DECIMALE
            //================================

            if (value == ",") {

              if (!widget.isDecimal) {
                return;
              }

              if (widget.controller.text.contains(",")) {
                return;
              }
            }

            refresh(() {

              widget.controller.text += value;

              widget.controller.selection =
                  TextSelection.fromPosition(
                    TextPosition(
                      offset:
                      widget.controller.text.length,
                    ),
                  );
            });
          },

          style: FilledButton.styleFrom(
            elevation: 0,

            backgroundColor:
            bg ?? const Color(0xFF34382F),

            foregroundColor: Colors.white,

            padding: EdgeInsets.zero,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),

          child: Text(
            value,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final size = MediaQuery.of(context).size;

    final bool isMobile =
        size.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,

      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),

      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
            isMobile
                ? double.infinity
                : 460,
          ),

          child: Material(
            color: const Color(0xFF1E211B),

            borderRadius:
            BorderRadius.circular(34),

            child: Padding(
              padding: const EdgeInsets.all(22),

              child: StatefulBuilder(
                builder: (_, refresh) {

                  return Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Text(
                        widget.title,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        widget.subtitle,

                        style: TextStyle(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24),

                      //================================
                      // INPUT
                      //================================

                      SizedBox(
                        height: 90,

                        child: Center(
                          child: IntrinsicWidth(
                            child: TextField(
                              controller:
                              widget.controller,

                              focusNode: focusNode,

                              autofocus: true,

                              keyboardType:
                              widget.isDecimal
                                  ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                                  : TextInputType.number,

                              textAlign:
                              TextAlign.center,

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 72,
                                fontWeight:
                                FontWeight.w800,
                                height: 1,
                              ),

                              cursorColor:
                              verdeQFood,

                              decoration:
                              const InputDecoration(
                                border:
                                InputBorder.none,
                                isCollapsed: true,
                              ),

                              onChanged: (_) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      //================================
                      // KEYPAD
                      //================================

                      Column(
                        children: [

                          Row(
                            children: [

                              _key(context, "7", refresh),

                              const SizedBox(width: 14),

                              _key(context, "8", refresh),

                              const SizedBox(width: 14),

                              _key(context, "9", refresh),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [

                              _key(context, "4", refresh),

                              const SizedBox(width: 14),

                              _key(context, "5", refresh),

                              const SizedBox(width: 14),

                              _key(context, "6", refresh),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [

                              _key(context, "1", refresh),

                              const SizedBox(width: 14),

                              _key(context, "2", refresh),

                              const SizedBox(width: 14),

                              _key(context, "3", refresh),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [

                              _key(context, "0", refresh),

                              const SizedBox(width: 14),

                              _key(context, "00", refresh),

                              const SizedBox(width: 14),

                              // SOSTITUISCI TUTTO IL BLOCCO DELLA VIRGOLA CON QUESTO

                              Expanded(
                                child: SizedBox(
                                  height: 86,

                                  child: FilledButton(
                                    onPressed: () {

                                      //================================
                                      // SOLO UNA VIRGOLA
                                      //================================

                                      if (widget.controller.text.contains(",")) {
                                        return;
                                      }

                                      refresh(() {

                                        //================================
                                        // INPUT VUOTO
                                        //================================

                                        if (widget.controller.text.isEmpty) {

                                          widget.controller.text = "0,";

                                        } else {

                                          widget.controller.text += ",";
                                        }

                                        widget.controller.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset:
                                                widget.controller.text.length,
                                              ),
                                            );
                                      });
                                    },

                                    style: FilledButton.styleFrom(
                                      elevation: 0,

                                      backgroundColor:
                                      const Color(0xFF34382F),

                                      foregroundColor: Colors.white,

                                      padding: EdgeInsets.zero,

                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(28),
                                      ),
                                    ),

                                    child: const Text(
                                      ",",

                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          SizedBox(
                            height: 84,

                            child: Row(
                              children: [

                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {

                                      if (widget
                                          .controller
                                          .text
                                          .isEmpty) {
                                        return;
                                      }

                                      refresh(() {

                                        widget.controller.text =
                                            widget.controller.text.substring(
                                              0,
                                              widget.controller.text.length - 1,
                                            );

                                        widget.controller.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset:
                                                widget.controller.text.length,
                                              ),
                                            );
                                      });
                                    },

                                    style:
                                    FilledButton.styleFrom(
                                      elevation: 0,

                                      backgroundColor:
                                      const Color(
                                        0xFF34382F,
                                      ),

                                      foregroundColor:
                                      Colors.white,

                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                          28,
                                        ),
                                      ),
                                    ),

                                    child: const Icon(
                                      Icons.backspace_outlined,
                                      size: 34,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  flex: 2,

                                  child: SizedBox(
                                    height: 44,

                                    child: FilledButton(
                                      onPressed: () {

                                        if (widget.controller.text.isEmpty) {
                                          return;
                                        }

                                        if (widget.isDecimal) {

                                          Navigator.pop(
                                            context,

                                            double.tryParse(
                                              widget.controller.text
                                                  .replaceAll(",", "."),
                                            ),
                                          );
                                        } else {

                                          Navigator.pop(
                                            context,

                                            int.tryParse(
                                              widget.controller.text,
                                            ),
                                          );
                                        }
                                      },

                                      style:
                                      FilledButton.styleFrom(
                                        elevation: 0,

                                        backgroundColor:
                                        verdeQFood,

                                        foregroundColor:
                                        Colors.white,

                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                      ),

                                      child: const Icon(
                                        Icons.keyboard_return,
                                        size: 42,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: Text(
                          "Annulla",

                          style: TextStyle(
                            color:
                            Colors.white.withOpacity(.5),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}


//==================================================
// KEYPAD
//==================================================

class _CustomKeypad extends StatelessWidget {

  final Function(String value) onValue;

  final VoidCallback onClose;

  const _CustomKeypad({
    required this.onValue,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {

    final items = [
      "7","8","9",
      "4","5","6",
      "1","2","3",
      "0","00",",",
    ];

    return Material(
      elevation: 20,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        width: 320,
        height: 380,

        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),

        child: Column(
          children: [

            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                physics:
                const NeverScrollableScrollPhysics(),

                itemCount: items.length,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),

                itemBuilder: (_, i) {

                  final item = items[i];

                  return ElevatedButton(
                    onPressed: () => onValue(item),

                    style: ElevatedButton.styleFrom(
                      elevation: 0,

                      backgroundColor:
                      Colors.grey.shade100,

                      foregroundColor: Colors.black,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),

                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            Row(
              children: [

                Expanded(
                  child: SizedBox(
                    height: 52,

                    child: ElevatedButton(
                      onPressed: () => onValue("DEL"),

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF1B2340),

                        foregroundColor:
                        Colors.white,
                      ),

                      child: const Icon(Icons.close),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,

                    child: ElevatedButton(
                      onPressed: onClose,

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        violaQFood,

                        foregroundColor:
                        Colors.white,
                      ),

                      child: const Icon(
                        Icons.keyboard_return,
                      ),
                    ),
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


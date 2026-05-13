/* import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/casse_automatiche/settings_menu_automatic_checkout.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/state/controller_impostazioni.dart';
import 'package:dashboard/ui/screen/documents/documents_list.dart';
import 'package:dashboard/ui/screen/documents/documents_page.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/widget/categorie_e_prodotti/griglia_prodotti.dart';
import 'package:dashboard/ui/widget/header_footer/ControllerListPriceSelected.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelli/articleInCart.dart';
import '../state/controller_carrello.dart';
import '../state/product_search_controller.dart';
import '../ui/screen/checkout/cliente/InserisciClienteVista.dart';
import '../ui/screen/sincronizzazioni/articoli/articolo_service.dart';
import '../ui/screen/sincronizzazioni/operatori/operator_preferences_controller.dart';
import '../ui/widget/carrello/carrello_widget.dart';
import '../ui/widget/header_footer/footer_navbar.dart';
import '../ui/widget/categorie_e_prodotti/sidebar_categorie.dart';
import '../ui/widget/header_footer/header_inferiore.dart';
import '../ui/widget/header_footer/header_superiore.dart';
import '../ui/widget/header_footer/reparti/reparti_grid.dart';
import '../ui/widget/tastierino/tastierino_popup.dart';
import '../varianti/state/variants_controller.dart';
import '../varianti/ui/varianti_dialog.dart';

/// =====================================================
/// WRAPPER CON PROVIDER (FIX DEFINITIVA)
/// =====================================================
class HomeVista extends StatelessWidget {
  const HomeVista({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductSearchController>(
          create: (_) => ProductSearchController(),
        ),
      ],
      child: const _HomeVistaBody(),
    );
  }
}

/// =====================================================
/// BODY REALE DELLA HOME
/// =====================================================
class _HomeVistaBody extends StatefulWidget {
  const _HomeVistaBody();

  @override
  State<_HomeVistaBody> createState() => _HomeVistaBodyState();
}

class _HomeVistaBodyState extends State<_HomeVistaBody> {
  bool _loading = false;
  bool _advancedModeEnabled = false;
  int? repartoSelezionato;
  List categorie = [];
  List articoli = [];
  int? categoriaSelezionata;
  ListPriceModel? priceListSelected;
  bool showListDocuments = false;
  final keyListDocument = GlobalKey<DocumentsListState>();

  Future<void> setListPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final store = prefs.getString('store');
    int? listBenchDefaultId = null;
    if( store != null ){
      Map storeMap = jsonDecode(store);
      if( storeMap['priceListBench'] != null ){
         listBenchDefaultId = storeMap['priceListBench']['id'] ?? null;
      } 
    }

    listsPrice = await ListPriceModel.getByDb();

    listsPrice = listsPrice.where((list) => list.counterpart == 'customer',).toList();
    ListPriceModel? test = await getListPriceSelected();

    final check = listsPrice.where((element) => element.id == test?.id).toList();
    if (check.isNotEmpty) {
      final controllerListPrice =  context.read<ControllerListPriceSelected>();
      controllerListPrice.listPriceSelected = check[0];
      setState(() {
        priceListSelected = listsPrice.firstWhere((l) => l.id == listBenchDefaultId );
        //priceListSelected = check[0];
      });
      return;
    }

     priceListSelected = listsPrice.firstWhere((l) => l.id == listBenchDefaultId );
    setState(() {});
  }

  /// Layout centrale con extended cart
  Widget _layoutCentrale() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final imp = context.watch<ImpostazioniController>();
    final isLeft = imp.uiSide == "L";

    final carrello = context.watch<CarrelloController>();
    final prodotti = carrello.prodotti.reversed.toList();
    final op = context.watch<OperatorPreferencesController>();

    /// COLORI UI
    final bg = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final rowBg =
        isDark ? const Color(0xFF141414) : Colors.white;
    final headerBg =
        isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF7F7F7);
    final borderColor =
        isDark ? Colors.white10 : Colors.grey.shade200;
    final boxBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF1F1F1);
    final textColor =
        isDark ? Colors.white : Colors.black87;
    final subText =
        isDark ? Colors.white70 : Colors.grey;

    /// LEFT PANEL
    final leftPanel = Container(
      width: 260,
      color: colors.surfaceContainerHighest
          .withOpacity(0.3),
      child: _listaSottoTab(),
    );

    /// CENTER PANEL
    final centerPanel = Expanded(
      child: (carrello.extendedCartOpen && op.extendedCart)
          ? Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  /// HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: headerBg,
                      border: Border(
                        bottom: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 4,
                          child: SizedBox(),
                        ),

                        /// QTY
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Qty",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// % Sconto
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: Text(
                                "% Sconto",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// €
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Icon(
                              Icons.euro,
                              size: 16,
                              color: subText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// LISTA
                  Expanded(
                    child: prodotti.isEmpty
                        ? Center(
                            child: Text(
                              "Aggiungi prodotti",
                              style: TextStyle(color: subText),
                            ),
                          )
                        : ListView.builder(
                            controller:
                                carrello.scrollControllerCart,
                            itemCount: prodotti.length,
                            itemBuilder: (_, i) {
                              final p = prodotti[i];

                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: rowBg,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: InkWell(
                                        onTap: () =>
                                            apriVariantiGlobal(
                                          context,
                                          p,
                                        ),
                                        child: Text(
                                          p.article.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// QTY
                                    Expanded(
                                      flex: 1,
                                      child: InkWell(
                                        onTap: () async {
                                          final nuovaQt =
                                              await _modificaQuantita(
                                            context,
                                            p,
                                          );

                                        },
                                        child: Container(
                                          height: 38,
                                          alignment:
                                              Alignment.center,
                                          decoration:
                                              BoxDecoration(
                                            color: boxBg,
                                            borderRadius:
                                                BorderRadius
                                                    .circular(6),
                                          ),
                                          child: Text(
                                            p.quantity
                                                .toString(),
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    /// % placeholder
                                     Expanded(
                                        flex: 1,
                                        child: InkWell(
                                          onTap: () async {
                                           final d =  await mostraDialogSconto(context, initialValue: p.discountPercentageRow ?? 0);
                                           if( d == null) return;
                                           context.read<CarrelloController>().upgradeDiscountRowCart(p.uuid,d,);
                                          },
                                          child: Container(
                                            height: 38,
                                            alignment:
                                                Alignment.center,
                                            decoration:
                                                BoxDecoration(
                                              color: boxBg,
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(6),
                                            ),
                                            child: Text(
                                              "${p.discountPercentageRow} %",
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    

                                    const SizedBox(width: 10),

                                    /// PREZZO
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
                                            context.read<CarrelloController>().aggiornaPrezzo(p,nuovoPrezzo,);
                                          }
                                        },
                                        child: Container(
                                          height: 38,
                                          alignment: Alignment
                                              .centerRight,
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 10,
                                          ),
                                          decoration:
                                              BoxDecoration(
                                            color: boxBg,
                                            borderRadius:
                                                BorderRadius
                                                    .circular(6),
                                          ),
                                          child: Text(
                                            p.priceRowCart
                                                .toStringAsFixed(
                                                    2)
                                                .replaceAll(
                                                  '.',
                                                  ',',
                                                ),
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: textColor,
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
                ],
              ),
            )
          : GrigliaProdottiResponsive(
              contextVista: context,
              listPrice: priceListSelected,
              categoria: tabAttivo == 0
                  ? categoriaSelezionata
                  : null,
              reparto: repartoSelezionato,
              tastierinoKey: tastierinoKey,
              preferred:
                  tabAttivo == 2 ? true : null,
            ),
    );

    /// RIGHT PANEL (carrello classico)
    final rightPanel = Container(
      width: 340,
      color: colors.surfaceContainerHighest
          .withOpacity(0.4),
      child: CarrelloWidget(
        onEditCliente: () => apriPopupCliente(context),
        listPrice: priceListSelected,
      ),
    );

    return Row(
      children: isLeft
          ? [
              rightPanel,
              centerPanel,
              leftPanel,
            ]
          : [
              leftPanel,
              centerPanel,
              rightPanel,
            ],
    );
  }

  // modale quantità locale (esteso)
  Future<double?> _modificaQuantita(
    BuildContext context,
    ProdottoCarrello p,
  ) async {
    final ctrl = TextEditingController();
    final theme = Theme.of(context);

    return showDialog<double>(
      context: context,
      useRootNavigator: true,
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
                borderRadius:
                    BorderRadius.circular(22),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Inserisci quantità",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme
                              .colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.article.title,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme
                              .onSurface
                              .withOpacity(.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: ctrl,
                        builder: (_, __) {
                          return Text(
                            ctrl.text,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight:
                                  FontWeight.bold,
                              color: theme
                                  .colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      const Divider(),
                      Flexible(
                        child: TastierinoQuantita(
                          controller: ctrl,
                          p: p,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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

  // modale prezzo locale (esteso)
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
                borderRadius:
                    BorderRadius.circular(22),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Inserisci prezzo",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                          color: theme
                              .colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: ctrl,
                        builder: (_, __) {
                          return Text(
                            ctrl.text,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight:
                                  FontWeight.bold,
                              color: theme
                                  .colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      const Divider(),
                      Flexible(
                        child: _TastierinoPrezzo(
                          controller: ctrl,
                          prodotto: p,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context),
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

  // varianti globali (riusa VariantsController / VariantiDialog)
  Future<void> apriVariantiGlobal(
    BuildContext context,
    ProdottoCarrello prodotto,
  ) async {
    final controller =
        context.read<ControllerListPriceSelected>();
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
    controllerVariantsController
        .setArticleCurrent(prodotto);

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

  // versioni “global” dei tastierini (se ti servono altrove)
  Future<double?> modificaQuantitaGlobal(
    BuildContext context,
    ProdottoCarrello p,
  ) async {
    final ctrl = TextEditingController();

    return showDialog<double>(
      context: context,
      builder: (_) => Dialog(
        child: TastierinoQuantita(
          controller: ctrl,
          p: p,
        ),
      ),
    );
  }

  Future<double?> modificaPrezzoGlobal(
    BuildContext context,
    ProdottoCarrello p,
  ) async {
    final ctrl = TextEditingController();

    return showDialog<double>(
      context: context,
      builder: (_) => Dialog(
        child: _TastierinoPrezzo(
          controller: ctrl,
          prodotto: p,
        ),
      ),
    );
  }

  /// Sidebar categorie/reparti invariata
  Widget _listaSottoTab() {
    if (tabAttivo == 0 || tabAttivo == 2) {
      return SidebarCategorie(
        changeTabAttivo: () {
          setState(() {
            tabAttivo = 0;
          });
        },
        onCategoriaSelezionata: (id) {
          setState(() {
            categoriaSelezionata = id;
          });
        },
      );
    }
    if (tabAttivo == 1) {
      return RepartiList(
        tastierinoKey: tastierinoKey,
        onRepartoSelezionato: (id) {
          setState(() {
            repartoSelezionato = id;
            categoriaSelezionata = null;
          });
        },
      );
    }

    return Container();
  }

  @override
  void initState() {
    super.initState();
    setListPrices();
    DrawerAutomacitModel.getDrawers(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context).size;
    final isMobile = mq.width < 600;
    final isTablet =
        mq.width >= 600 && mq.width < 1024;
    final ctrLook =
        context.watch<ControllerLookPosInPrinder>();

    // per gestire lato mancino
    final imp = context.watch<ImpostazioniController>();
    final isLeft = imp.uiSide == "L";

    // extended cart: se l’operatore lo disabilita, chiudo lo stato
    final op = context.watch<OperatorPreferencesController>();
    final carrello = context.read<CarrelloController>();

    if (!op.extendedCart && carrello.extendedCartOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        carrello.closeExtendedCart();
      });
    }

    return AbsorbPointer(
      absorbing: ctrLook.inPrint,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  HeaderSuperiore(
                    setShowListDocuments: () =>
                        setState(() {
                      showListDocuments = true;
                      keyListDocument.currentState!
                          .allDocuments();
                    }),
                    listListPrices: listsPrice,
                    selected: priceListSelected ?? null,
                    onListPriceSelected: (value) {
                      setState(() {
                        priceListSelected = value;
                      });
                    },
                    advancedEnabled:
                        _advancedModeEnabled,
                    onAdvancedModeChanged: (value) {
                      setState(
                        () => _advancedModeEnabled =
                            value,
                      );
                    },
                  ),

                  /// Header inferiore
                  
                  /* Consumer<CarrelloController>(
                    builder: (_, carrello, __) {
                      return HeaderInferiore(
                        onTabChanged: (index) {
                          setState(() {
                            tabAttivo = index;
                          });
                        },
                      );
                    },
                  ), */

                  Builder(
                    builder:(context) {
                    context.watch<CarrelloController>();
                     return HeaderInferiore(
                        onTabChanged: (index) {
                          setState(() {
                            tabAttivo = index;
                          });
                        },
                      );
                  },),

                  Expanded(
                    child: _loading
                        ? const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        : _layoutCentrale(),
                  ),

                  const FooterNavbar(),
                ],
              ),
            ),

            // Tastierino
            Positioned(
              right:
                  isLeft ? null : (isMobile ? 12 : 0),
              left:
                  isLeft ? (isMobile ? 12 : 0) : null,
              bottom: isMobile
                  ? 70
                  : isTablet
                      ? 90
                      : 0,
              child: SizedBox(
                width: isMobile
                    ? mq.width * 0.88
                    : isTablet
                        ? 320
                        : 340,
                child: TastierinoCompattoFisso(
                  key: tastierinoKey,
                  advancedEnabled:
                      _advancedModeEnabled,
                ),
              ),
            ),

            // LISTA DOCUMENTI PER ANNULLO SCONTRINO
            AnimatedPositioned(
              duration:
                  const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              right: showListDocuments ? 0 : -500,
              bottom: 0,
              child: Material(
                elevation: 12,
                shadowColor: Colors.black54,
                borderRadius:
                    const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                  child: SizedBox(
                    width: 500,
                    height: MediaQuery.of(context)
                        .size
                        .height,
                    child: Container(
                      color: Colors.white,
                      child: DocumentsPage(
                        keyList: keyListDocument,
                        onClose: () {
                          setState(() {
                            showListDocuments = false;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP / TABLET legacy (lasciato intatto)
  // -------------------------------------------------------------
  Widget _layoutDesktop(bool isTablet) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 260,
          color: colors
              .surfaceContainerHighest
              .withOpacity(0.3),
          child: SidebarCategorie(
            changeTabAttivo: () {
              setState(() {
                tabAttivo = 0;
              });
            },
            onCategoriaSelezionata: (id) {
              setState(
                () => categoriaSelezionata = id,
              );
            },
          ),
        ),
        Expanded(
          flex: isTablet ? 3 : 4,
          child: GrigliaProdottiResponsive(
            contextVista: context,
            listPrice: priceListSelected,
            categoria: categoriaSelezionata,
            tastierinoKey: tastierinoKey,
          ),
        ),
        Consumer<CarrelloController>(
          builder: (_, carrello, __) {
            return Container(
              width: isTablet ? 260 : 340,
              color: colors
                  .surfaceContainerHighest
                  .withOpacity(0.4),
              child: CarrelloWidget(
                listPrice: priceListSelected,
                onEditCliente: () {
                  apriPopupCliente(context);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

void apriPopupCliente(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 820,
          height: 920,
          child: InserisciClienteSheet(
            onSelect: (cliente) {
              context
                  .read<CarrelloController>()
                  .setCliente(cliente);
              Navigator.pop(ctx);
            },
          ),
        ),
      );
    },
  );
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
} */

// lib/ui/screen/home/home_vista.dart

import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/casse_automatiche/settings_menu_automatic_checkout.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/state/controller_impostazioni.dart';
import 'package:dashboard/ui/screen/documents/documents_list.dart';
import 'package:dashboard/ui/screen/documents/documents_page.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/widget/categorie_e_prodotti/griglia_prodotti.dart';
import 'package:dashboard/ui/widget/header_footer/ControllerListPriceSelected.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelli/articleInCart.dart';
import '../state/controller_carrello.dart';
import '../state/product_search_controller.dart';
import '../ui/screen/checkout/cliente/InserisciClienteVista.dart';
import '../ui/screen/sincronizzazioni/articoli/articolo_service.dart';
import '../ui/screen/sincronizzazioni/operatori/operator_preferences_controller.dart';
import '../ui/widget/carrello/carrello_widget.dart';
import '../ui/widget/header_footer/footer_navbar.dart';
import '../ui/widget/categorie_e_prodotti/sidebar_categorie.dart';
import '../ui/widget/header_footer/header_inferiore.dart';
import '../ui/widget/header_footer/header_superiore.dart';
import '../ui/widget/header_footer/reparti/reparti_grid.dart';
import '../ui/widget/tastierino/tastierino_popup.dart';
import '../varianti/state/variants_controller.dart';
import '../varianti/ui/varianti_dialog.dart';
// ═══════════════════════════════════════════════════════════════
// WRAPPER — inietta ProductSearchController
// ═══════════════════════════════════════════════════════════════
class HomeVista extends StatelessWidget {
  const HomeVista({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductSearchController>(
          create: (_) => ProductSearchController(),
        ),
      ],
      child: const _HomeVistaBody(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BODY
// ═══════════════════════════════════════════════════════════════
class _HomeVistaBody extends StatefulWidget {
  const _HomeVistaBody();

  @override
  State<_HomeVistaBody> createState() => _HomeVistaBodyState();
}

class _HomeVistaBodyState extends State<_HomeVistaBody> {
  bool _loading = false;
  bool _advancedModeEnabled = false;

  int? repartoSelezionato;
  int? categoriaSelezionata;
  ListPriceModel? priceListSelected;

  bool showListDocuments = false;
  final keyListDocument = GlobalKey<DocumentsListState>();

  // ── init ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _setListPrices();
    DrawerAutomacitModel.getDrawers(context);
  }

  // ── listini ───────────────────────────────────────────────────
  Future<void> _setListPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final store = prefs.getString('store');

    int? listBenchDefaultId;
    if (store != null) {
      final storeMap = jsonDecode(store) as Map;
      listBenchDefaultId = storeMap['priceListBench']?['id'] as int?;
    }

    listsPrice = await ListPriceModel.getByDb();
    listsPrice = listsPrice
        .where((l) => l.counterpart == 'customer')
        .toList();

    final ListPriceModel? test = await getListPriceSelected();
    final check =
        listsPrice.where((e) => e.id == test?.id).toList();

    if (check.isNotEmpty) {
      // ignore: use_build_context_synchronously
      context
          .read<ControllerListPriceSelected>()
          .listPriceSelected = check[0];
    }

    if (!mounted) return;
    setState(() {
      try {
        priceListSelected = listBenchDefaultId != null
            ? listsPrice.firstWhere((l) => l.id == listBenchDefaultId)
            : (check.isNotEmpty ? check[0] : null);
      } catch (_) {
        priceListSelected = check.isNotEmpty ? check[0] : null;
      }
    });
  }

  // ── build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final mq       = MediaQuery.of(context).size;
    final isMobile = mq.width < 600;
    final isTablet = mq.width >= 600 && mq.width < 1024;

    final ctrLook = context.watch<ControllerLookPosInPrinder>();
    final imp     = context.watch<ImpostazioniController>();
    final isLeft  = imp.uiSide == 'L';

    // Se l'operatore disabilita extendedCart, chiudo lo stato
    final op       = context.watch<OperatorPreferencesController>();
    final carrello = context.read<CarrelloController>();
    if (!op.extendedCart && carrello.extendedCartOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        carrello.closeExtendedCart();
      });
    }

    return AbsorbPointer(
      absorbing: ctrLook.inPrint,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Stack(
          children: [
            // ── Layout principale ────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Header superiore
                  HeaderSuperiore(
                    setShowListDocuments: () => setState(() {
                      showListDocuments = true;
                      keyListDocument.currentState!.allDocuments();
                    }),
                    listListPrices: listsPrice,
                    selected: priceListSelected,
                    onListPriceSelected: (value) =>
                        setState(() => priceListSelected = value),
                    advancedEnabled: _advancedModeEnabled,
                    onAdvancedModeChanged: (value) =>
                        setState(() => _advancedModeEnabled = value),
                  ),

                  // Header inferiore (tab + azioni)
                  Builder(builder: (_) {
                    context.watch<CarrelloController>();
                    return HeaderInferiore(
                      onTabChanged: (index) =>
                          setState(() => tabAttivo = index),
                    );
                  }),

                  // Corpo centrale
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _layoutCentrale(),
                  ),

                  const FooterNavbar(),
                ],
              ),
            ),

            // ── Tastierino fisso ─────────────────────────────────
            Positioned(
              right: isLeft ? null : (isMobile ? 12 : 0),
              left:  isLeft ? (isMobile ? 12 : 0) : null,
              bottom: isMobile ? 70 : isTablet ? 90 : 0,
              child: SizedBox(
                width: isMobile
                    ? mq.width * 0.88
                    : isTablet
                        ? 320
                        : 340,
                child: TastierinoCompattoFisso(
                  key: tastierinoKey,
                  advancedEnabled: _advancedModeEnabled,
                ),
              ),
            ),

            // ── Panel documenti (slide da destra) ────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              right:  showListDocuments ? 0 : -500,
              bottom: 0,
              child: Material(
                elevation: 12,
                shadowColor: Colors.black54,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20)),
                  child: SizedBox(
                    width:  500,
                    height: mq.height,
                    child: ColoredBox(
                      color: Colors.white,
                      child: DocumentsPage(
                        keyList: keyListDocument,
                        onClose: () =>
                            setState(() => showListDocuments = false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layout centrale (3 colonne) ───────────────────────────────
  Widget _layoutCentrale() {
    final theme   = Theme.of(context);
    final colors  = theme.colorScheme;
    final isDark  = theme.brightness == Brightness.dark;
    final isLeft  = context.watch<ImpostazioniController>().uiSide == 'L';
    final carrello = context.watch<CarrelloController>();
    final op       = context.watch<OperatorPreferencesController>();

    // ── Colori per extendedCart ──────────────────────────────────
    final bg          = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final rowBg       = isDark ? const Color(0xFF141414) : Colors.white;
    final headerBg    = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF7F7F7);
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final boxBg       = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F1F1);
    final textColor   = isDark ? Colors.white : Colors.black87;
    final subText     = isDark ? Colors.white70 : Colors.grey;

    // ── Pannello sinistro ────────────────────────────────────────
    final leftPanel = Container(
      width: 260,
      color: colors.surfaceContainerHighest.withOpacity(0.3),
      child: _listaSottoTab(),
    );

    // ── Pannello centrale (griglia OR extended cart) ─────────────
    final centerPanel = Expanded(
      child: (carrello.extendedCartOpen && op.extendedCart)
          ? _extendedCartView(
              prodotti:    carrello.prodotti.reversed.toList(),
              bg:          bg,
              rowBg:       rowBg,
              headerBg:    headerBg,
              borderColor: borderColor,
              boxBg:       boxBg,
              textColor:   textColor,
              subText:     subText,
              isDark:      isDark,
            )
          : GrigliaProdottiResponsive(
              contextVista:  context,
              listPrice:     priceListSelected,
              categoria:     tabAttivo == 0 ? categoriaSelezionata : null,
              reparto:       repartoSelezionato,
              tastierinoKey: tastierinoKey,
              preferred:     tabAttivo == 2 ? true : null,
            ),
    );

    // ── Pannello destro (carrello classico) ──────────────────────
    final rightPanel = Container(
      width: 340,
      color: colors.surfaceContainerHighest.withOpacity(0.4),
      child: CarrelloWidget(
        onEditCliente: () => apriPopupCliente(context),
        listPrice: priceListSelected,
      ),
    );

    return Row(
      children: isLeft
          ? [rightPanel, centerPanel, leftPanel]
          : [leftPanel, centerPanel, rightPanel],
    );
  }

  // ── Extended cart view ────────────────────────────────────────
  Widget _extendedCartView({
    required List<ProdottoCarrello> prodotti,
    required Color bg,
    required Color rowBg,
    required Color headerBg,
    required Color borderColor,
    required Color boxBg,
    required Color textColor,
    required Color subText,
    required bool isDark,
  }) {
    Widget _badge(String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header colonne
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 4, child: SizedBox()),
                Expanded(
                    flex: 1, child: Center(child: _badge('Qty'))),
                Expanded(
                    flex: 1, child: Center(child: _badge('% Sconto'))),
                Expanded(
                  flex: 1,
                  child: Center(
                      child: Icon(Icons.euro, size: 16, color: subText)),
                ),
              ],
            ),
          ),

          // Lista righe
          Expanded(
            child: prodotti.isEmpty
                ? Center(
                    child: Text('Aggiungi prodotti',
                        style: TextStyle(color: subText)))
                : ListView.builder(
                    controller:
                        context.read<CarrelloController>().scrollControllerCart,
                    itemCount: prodotti.length,
                    itemBuilder: (_, i) {
                      final p = prodotti[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: rowBg,
                          border: Border(
                              bottom: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            // Nome prodotto → apre varianti
                            Expanded(
                              flex: 4,
                              child: InkWell(
                                onTap: () =>
                                    _apriVarianti(context, p),
                                child: Text(
                                  p.article.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),

                            // Quantità
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () =>
                                    _modificaQuantita(context, p),
                                child: _boxCell(
                                    p.quantity.toString(), boxBg,
                                    textColor),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Sconto %
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () async {
                                  final d = await mostraDialogSconto(
                                    context,
                                    initialValue:
                                        p.discountPercentageRow ?? 0,
                                  );
                                  if (d == null) return;
                                  // ignore: use_build_context_synchronously
                                  context
                                      .read<CarrelloController>()
                                      .upgradeDiscountRowCart(
                                          p.uuid, d);
                                },
                                child: _boxCell(
                                    '${p.discountPercentageRow} %',
                                    boxBg,
                                    textColor),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Prezzo
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () =>
                                    _modificaPrezzo(context, p),
                                child: Container(
                                  height: 38,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: boxBg,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.priceRowCart
                                        .toStringAsFixed(2)
                                        .replaceAll('.', ','),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
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
        ],
      ),
    );
  }

  Widget _boxCell(String text, Color bg, Color textColor) =>
      Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: textColor)),
      );

  // ── Sidebar sinistra ──────────────────────────────────────────
  Widget _listaSottoTab() {
    if (tabAttivo == 0 || tabAttivo == 2) {
      return SidebarCategorie(
        changeTabAttivo: () => setState(() => tabAttivo = 0),
        onCategoriaSelezionata: (id) =>
            setState(() => categoriaSelezionata = id),
      );
    }
    if (tabAttivo == 1) {
      return RepartiList(
        tastierinoKey: tastierinoKey,
        onRepartoSelezionato: (id) => setState(() {
          repartoSelezionato   = id;
          categoriaSelezionata = null;
        }),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Dialog: modifica quantità ─────────────────────────────────
  Future<void> _modificaQuantita(
      BuildContext context, ProdottoCarrello p) async {
    final ctrl  = TextEditingController();
    final theme = Theme.of(context);

    await showDialog<double>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: 440, maxHeight: 620),
            child: Material(
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.surface,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Inserisci quantità',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(p.article.title,
                        style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.onSurface
                                .withOpacity(.7))),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (_, __) => Text(ctrl.text,
                          style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color:
                                  theme.colorScheme.onSurface)),
                    ),
                    const SizedBox(height: 6),
                    const Divider(),
                    Flexible(
                        child: TastierinoQuantita(
                            controller: ctrl, p: p)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialog: modifica prezzo ───────────────────────────────────
  Future<void> _modificaPrezzo(
      BuildContext context, ProdottoCarrello p) async {
    final ctrl  = TextEditingController();
    final theme = Theme.of(context);

    await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: 440, maxHeight: 620),
            child: Material(
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.surface,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Inserisci prezzo',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (_, __) => Text(ctrl.text,
                          style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color:
                                  theme.colorScheme.onSurface)),
                    ),
                    const SizedBox(height: 6),
                    const Divider(),
                    Flexible(
                        child: _TastierinoPrezzo(
                            controller: ctrl, prodotto: p)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Apri varianti ─────────────────────────────────────────────
  Future<void> _apriVarianti(
      BuildContext context, ProdottoCarrello prodotto) async {
    final ctrlListPrice =
        context.read<ControllerListPriceSelected>();
    final ctrlVariants = context.read<VariantsController>();

    ctrlVariants.reset();

    final variants = await ArticoloService.getVariations(
      prodotto,
      ctrlListPrice.listPriceSelected?.id,
    );

    ctrlVariants.setAllVariants(variants);
    ctrlVariants.setQuantityArticleInRow(prodotto.quantity);
    ctrlVariants.setArticleCurrent(prodotto);

    if (!mounted) return;
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => VariantiDialog(
        prodotto: prodotto,
        varianti: variants,
        note: const [],
        inTable: false,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FUNZIONE GLOBALE — popup cliente
// ═══════════════════════════════════════════════════════════════
void apriPopupCliente(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width:  820,
        height: 920,
        child: InserisciClienteSheet(
          onSelect: (cliente) {
            context.read<CarrelloController>().setCliente(cliente);
            Navigator.pop(ctx);
          },
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// TASTIERINO PREZZO (privato al file)
// ═══════════════════════════════════════════════════════════════
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
      if (value == '⌫') {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.text = widget.controller.text
              .substring(0, widget.controller.text.length - 1);
        }
        return;
      }
      if (value == ',') {
        if (!widget.controller.text.contains(',')) {
          widget.controller.text += ',';
        }
        return;
      }
      widget.controller.text += value;
    });
  }

  void _conferma() {
    final testo  = widget.controller.text.replaceAll(',', '.');
    final valore = double.tryParse(testo);
    if (valore == null) return;

    if (OperatoreModel.decrementPrice(widget.prodotto, valore) == false) return;
    if (OperatoreModel.incrementPrice(widget.prodotto, valore) == false) return;

    context
        .read<CarrelloController>()
        .upgradePriceRowCart(widget.prodotto.uuid, valore);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const keys  = ['7','8','9','4','5','6','1','2','3','0','00',','];

    return Column(
      children: [
        SizedBox(
          height: 340,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:  3,
              crossAxisSpacing: 3,
              mainAxisSpacing:  3,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (_, i) {
              final k = keys[i];
              return ElevatedButton(
                onPressed: () => _tap(k),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.onSurface.withOpacity(0.05),
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _tap('⌫'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
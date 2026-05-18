import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/category.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../state/controller_carrello.dart';
import '../../../state/controller_impostazioni.dart';
import '../../screen/sincronizzazioni/operatori/operator_preferences_controller.dart';
import '../../screen/sincronizzazioni/sync_catalogo.dart';
import '../../../state/product_search_controller.dart';

import '../tastierino/tastierino_popup.dart';

enum BancoLayout { grande, piccolo }

class GrigliaProdottiResponsive extends StatefulWidget {
  final int? categoria;
  final ListPriceModel? listPrice;
  final BancoLayout layout;
  final GlobalKey tastierinoKey;
  final int?  reparto;
  final bool? preferred;
  final BuildContext  contextVista;

  const GrigliaProdottiResponsive({
    super.key,
    this.categoria,
    this.listPrice,
    this.layout = BancoLayout.grande,
    this.reparto,
    this.preferred,
    required this.contextVista,
    required this.tastierinoKey,
  });

  @override
  State<GrigliaProdottiResponsive> createState() =>
      _GrigliaProdottiResponsiveState();
}

class _GrigliaProdottiResponsiveState extends State<GrigliaProdottiResponsive> {
  List<ArticleWhitPriceListModel>    articoli          = [];
  List<CategoryModel>                categorie         = [];
  List<ArticleWhitPriceListModel>    articoliCategorie = [];
  List<ArticleWhitPriceListModel>    articoliFiltrati  = [];
  late final   ProductSearchController   _searchController;

  int pagina = 1;
  final int perPagina = 42;

  @override
  void initState() {
    super.initState();

    _searchController = context.read<ProductSearchController>();
    _searchController.addListener(searchProducts);

    _loadArticoli( widget.contextVista );
    _loadArticoliCategorie();
    _caricaCategorie();
  }

  Future<void> _caricaCategorie() async {
    final rawCategoriesDb = await LocalDB.getAll('categories');
    final categories = rawCategoriesDb.map((catDb) => CategoryModel.fromJson(catDb)).toList();
    if (categories.isEmpty) return;
    categorie = categories;
    categorie.sort((a, b) => a.position!.compareTo(b.position!));
    setState(() {});
  }

  Future<void> _loadArticoliCategorie() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("articlesCategories");
    if (raw == null) return;
    articoliCategorie = List<ArticleWhitPriceListModel>.from(jsonDecode(raw));
  }

  @override
  void didUpdateWidget(covariant GrigliaProdottiResponsive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoria != widget.categoria ||
        oldWidget.reparto   != widget.reparto   ||
        oldWidget.layout    != widget.layout    ||
        oldWidget.listPrice != widget.listPrice ||
        oldWidget.preferred != widget.preferred) {
      pagina = 1;
      _loadArticoli(widget.contextVista);
    }
  }

  void searchProducts() {
    if (!mounted) return;
    final text = _searchController.query;
    pagina = 1;
    _loadArticoli(widget.contextVista, search: text);
  }

  Future<void> _loadArticoli(BuildContext ctx, {String? search}) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      dynamic device = jsonDecode(pref.getString('device') ?? '{}');
      if (device == null || device.isEmpty) return;
      String deviceType = device['deviceType'];

      if (widget.listPrice == null) {
        return;
      }

      if (search != null && search != '') {
        String queryArticleName = """SELECT 
                                    art.*, 
                                    lp.*  
                                    FROM articles art
                                    INNER JOIN articlesPrices lp ON lp.idArticle = art.id AND lp.idPriceList = ${widget.listPrice?.id}
                                    WHERE  LOWER(COALESCE(title, '')) LIKE LOWER("%${search}%")
                                    OR LOWER(COALESCE(posTitle, ''))  LIKE LOWER("%${search}%")""";
        final respDbArticles = await LocalDB.query(queryArticleName).catchError((err) => []);
        List<ArticleWhitPriceListModel> articles = respDbArticles
            .map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb))
            .toList();
        if (deviceType == 'cash_pos') articles = articles.where((a) => a.availableForPos == 1).toList();
        if (mounted) setState(() => articoli = articles);
        return;
      }

      if (widget.preferred == true) {
        String queryPreferred = """SELECT 
                                    art.*, 
                                    lp.*  
                                    FROM articles art
                                    INNER JOIN articlesPrices lp ON lp.idArticle = art.id AND lp.idPriceList = ${widget.listPrice?.id}
                                    WHERE art.preferred = 1""";
        final respDbArticles = await LocalDB.query(queryPreferred).catchError((err) => []);
        List<ArticleWhitPriceListModel> articles = respDbArticles
            .map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb))
            .toList();

        final allCategories = await LocalDB.query("SELECT * FROM categories").catchError((err) => []);
        List<CategoryModel> categoriesList = allCategories
            .map((articleDb) => CategoryModel.fromJson(articleDb))
            .toList();

        final future = articles.map((art) async {
          String queryColorFirstCategory = "SELECT * FROM articlesCategories WHERE idArticle = ${art.id}";
          final respqueryCategoryFor = await LocalDB.query(queryColorFirstCategory).catchError((err) => []);
          if (respqueryCategoryFor.isEmpty) {
            art.colorFirstCategory = '#9E9E9E';
          } else {
            CategoryModel firstCatForColor =
                categoriesList.firstWhere((c) => c.id == respqueryCategoryFor[0]['idCategory']);
            art.colorFirstCategory = firstCatForColor.color;
          }
        });

        await Future.wait(future);
        if (deviceType == 'cash_pos') articles = articles.where((a) => a.availableForPos == 1).toList();
        if (mounted) setState(() => articoli = articles);
        return;
      }

      String queryArticleListPriceCategory = """SELECT 
                      art.*,
                      lp.*
                    FROM articlesCategories cat
                    INNER JOIN articles art ON art.id = cat.idArticle
                    INNER JOIN articlesPrices lp  ON art.id = lp.idArticle AND lp.idPriceList = ${widget.listPrice?.id}
                    WHERE cat.idCategory = ${widget.categoria}
                    ORDER BY art.title""";

      final respDbArticles = await LocalDB.query(queryArticleListPriceCategory).catchError((err) => []);
      List<ArticleWhitPriceListModel> articles = respDbArticles
          .map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb))
          .toList();
      if (deviceType == 'cash_pos') articles = articles.where((a) => a.availableForPos == 1).toList();
      if (mounted) setState(() => articoli = articles);

    } catch (err) {
      debugPrint(err.toString());
    }
    setState(() {});
  }

  // --------------------------------------------------------
  // VECCHIO — mantenuti ma non più chiamati in build()
  // --------------------------------------------------------
  int _getColumnCount() {
    final width = MediaQuery.of(context).size.width;
    if (width < 600)  return 2;
    if (width < 1400) return 5;
    return 7;
  }

  double _getAspectRatio() {
    final width = MediaQuery.of(context).size.width;
    if (width < 600)  return 1.05;
    if (width < 1400) return 1.25;
    return widget.layout == BancoLayout.grande ? 1.35 : 1.28;
  }

  // --------------------------------------------------------
  // FIX COLORE CATEGORIA
  // --------------------------------------------------------
  Color _getColoreProdotto() {
    if (widget.categoria == null || _searchController.query != '') {
      return const Color(0xFF9E9E9E);
    }
    final idCatSelezionata = widget.categoria;
    String hex = "#9E9E9E";
    final categoria = categorie.firstWhereOrNull((c) => c.id == idCatSelezionata);
    if (categoria != null && categoria.color != null) {
      hex = categoria.color!;
    }
    try {
      return Color(int.parse(hex.replaceFirst("#", "0xff")));
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Nessun dato trovato",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Effettua una sincronizzazione per caricare i prodotti.",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await SyncCatalogo.syncAll(context);
              await _loadArticoli(widget.contextVista);
              await _loadArticoliCategorie();
              setState(() {});
            },
            icon: const Icon(Icons.sync),
            label: const Text("Sincronizza ora"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imp = context.watch<ImpostazioniController>();
    final op  = context.watch<OperatorPreferencesController>();

    final bool ridotto = imp.visualizzazioneProdottiRidotta;

    final width = MediaQuery.of(context).size.width;

    // MERGE — breakpoint tablet a 1400 (dal nuovo, più generoso)
    final bool isMobile  = width < 600;
    final bool isTablet  = width >= 600 && width < 1400;
    final bool isDesktop = width >= 1400;

    // MOBILE
    if (isMobile) {
      if (articoli.isEmpty) return _emptyState(context);

      final bool paginazioneAttiva = !op.paginatedArticle;

      List<ArticleWhitPriceListModel> visibili;

      if (paginazioneAttiva) {
        final start = ((pagina - 1) * perPagina).clamp(0, articoli.length);
        final end   = (start + perPagina).clamp(0, articoli.length);
        visibili = articoli.sublist(start, end);
      } else {
        visibili = articoli;
      }

      if (operatorLogged != null && operatorLogged!.manageGeneric == 0) {
        visibili = visibili.where((a) => a.generic == 0).toList();
      }

      return GrigliaProdottiMobile(
        articoli: visibili,
        tastierinoKey: widget.tastierinoKey,
      );
    }

    if (articoli.isEmpty) return _emptyState(context);

    final int totale = articoli.length;
    if (totale == 0) return _emptyState(context);

    final maxPagina = (totale / perPagina).ceil();
    if (pagina > maxPagina) pagina = 1;

    final bool paginazioneAttiva = !op.paginatedArticle;

    List<ArticleWhitPriceListModel> visibili;

    if (paginazioneAttiva) {
      final start = ((pagina - 1) * perPagina).clamp(0, totale);
      final end   = (start + perPagina).clamp(0, totale);
      visibili = articoli.sublist(start, end);
    } else {
      visibili = articoli;
    }

    if (operatorLogged != null && operatorLogged!.manageGeneric == 0) {
      visibili = visibili.where((a) => a.generic == 0).toList();
    }

    return Column(
      children: [
        Expanded(
          child: isTablet

              // TABLET — semplificato come il vecchio, valori dal nuovo
              ? GridView.builder(
                  itemCount: visibili.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   ridotto ? 7 : 6,
                    mainAxisSpacing:  ridotto ? 0 : 6,
                    crossAxisSpacing: ridotto ? 0 : 6,
                    childAspectRatio: ridotto ? 0.85 : 0.9,
                  ),
                  itemBuilder: (_, i) => _cardProdotto(visibili[i]),
                )

              // DESKTOP — LayoutBuilder fisso stile POS
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final int colonneDesktop = ridotto ? 7 : 5;
                    final int righeDesktop   = ridotto ? 6 : 5;

                    // MERGE — ratio 1.7 (nuovo) invece di 2.0 (vecchio), più bilanciato
                    final double ratio = ridotto ? 1.4 : 1.7;

                    final maxItems = colonneDesktop * righeDesktop;
                    final items = visibili.take(maxItems).toList();

                    return GridView.builder(
                      itemCount: items.length,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: colonneDesktop,
                        childAspectRatio: ratio,
                      ),
                      itemBuilder: (_, i) => _cardProdotto(items[i]),
                    );
                  },
                ),
        ),

        const SizedBox(height: 8),

        if (paginazioneAttiva) ...[
          const SizedBox(height: 8),
          _paginationBar(),
        ],
      ],
    );
  }

  // --------------------------------------------------------
  // CARD PRODOTTO
  // --------------------------------------------------------
  Widget _cardProdotto(ArticleWhitPriceListModel p) {
    final colore = p.colorFirstCategory is String
        ? Color(int.parse(p.colorFirstCategory!.replaceFirst("#", "0xff")))
        : _getColoreProdotto();

    final double prezzo = double.tryParse(p.price?.toString() ?? "0") ?? 0.0;

    final imp = context.watch<ImpostazioniController>();

    final bool usaNomeBreve = imp.nomeBreveProdotti;

    final String nome = usaNomeBreve
        ? ((p.posTitle != null && p.posTitle!.trim().isNotEmpty)
            ? p.posTitle!
            : (p.title ?? ''))
        : (p.title ?? '');

    double fontSize;

    if (usaNomeBreve) {
      switch (imp.grandezzaNomeBreveProdotti) {
        case "S": fontSize = 10; break;
        case "L": fontSize = 14; break;
        default:  fontSize = 12;
      }
    } else {
      switch (imp.grandezzaNomeProdotti) {
        case "S": fontSize = 11; break;
        case "L": fontSize = 15; break;
        default:  fontSize = 13;
      }
    }

    final bool ridotto = imp.visualizzazioneProdottiRidotta;

    final int maxLines = ridotto ? 1 : 2;
    final FontWeight fontWeight = ridotto ? FontWeight.w400 : FontWeight.w500;

    return Card(
      elevation: ridotto ? 1 : 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      child: InkWell(
        onTap: () {
          final carrello = context.read<CarrelloController>();
          carrello.scrollCartToTop();
          if (p.generic == 1) {
            TextEditingController titleCtrl = TextEditingController();
            TextEditingController priceCtrl = TextEditingController();
            TextEditingController qtaCtrl   = TextEditingController();

            FocusNode focusTitle = FocusNode();
            FocusNode focusPrice = FocusNode();
            FocusNode focusQta   = FocusNode();

            qtaCtrl.text   = "1";
            titleCtrl.text = p.title ?? '';
            priceCtrl.text = '0';

            focusPrice.addListener(() {
              if (focusPrice.hasFocus) {
                priceCtrl.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: priceCtrl.text.length,
                );
              }
            });

            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      content: SizedBox(
                        width: 400,
                        height: 300,
                        child: Column(
                          children: [
                            TextField(
                              onTap: () {
                                titleCtrl.text = '';
                                modificaTesto(context, 'Descrizione', titleCtrl);
                              },
                              focusNode:  focusTitle,
                              controller: titleCtrl,
                              decoration: const InputDecoration(labelText: "Descrizione"),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              onTap: () => modificaQuantita(context, 'Prezzo', priceCtrl),
                              autofocus:  true,
                              focusNode:  focusPrice,
                              controller: priceCtrl,
                              decoration: const InputDecoration(labelText: "Prezzo"),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              onTap: () => modificaQuantita(context, 'Quantità', qtaCtrl),
                              focusNode:  focusQta,
                              controller: qtaCtrl,
                              decoration: const InputDecoration(labelText: "Quantità"),
                            ),
                            const SizedBox(height: 50),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                                    },
                                    child: const Text('Annulla'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      String priceString = priceCtrl.text.replaceAll(',', '.');
                                      double? price = double.tryParse(priceString);
                                      double? qta   = double.tryParse(qtaCtrl.text);
                                      if ([price, qta].contains(null)) return;
                                      ArticleWhitPriceListModel pCopy = p.copyWith();
                                      pCopy.setTitle(titleCtrl.text);
                                      final carrello = context.read<CarrelloController>();
                                      (widget.tastierinoKey.currentWidget as TastierinoCompattoFisso)
                                          .applicaProdotto(pCopy, carrello, false, genericPrice: price, genericQta: qta);
                                      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                                    },
                                    child: const Text('Conferma'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
            return;
          }

          (widget.tastierinoKey.currentWidget as TastierinoCompattoFisso)
              .applicaProdotto(p, carrello, false);
        },
        child: Column(
          children: [
            // BANDA COLORE
            Container(
              height: ridotto ? 8 : 13,
              decoration: BoxDecoration(
                color: colore,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              ),
            ),

            // NOME PRODOTTO
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(6, ridotto ? 10 : 14, 6, 6),
                child: Center(
                  child: Text(
                    nome.toUpperCase(),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    // maxLines: maxLines, // decommentare se si vuole limite righe
                    style: TextStyle(
                      color: const Color(0xFF0D0D0D),
                      fontSize: ridotto ? fontSize - 1 : fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // PREZZO
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "$prezzo €",
                style: const TextStyle(
                  color: Color(0xFF97D700),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: ridotto ? 4 : 6),
          ],
        ),
      ),
    );
  }

  Widget _paginationBar() {
    final totalePagine = (articoli.length / perPagina).ceil().clamp(1, 9999);
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: pagina > 1 ? () => setState(() => pagina--) : null,
            child: const Text("◀ Precedente"),
          ),
          const SizedBox(width: 20),
          Text("Pagina $pagina / $totalePagine", style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 20),
          TextButton(
            onPressed: pagina < totalePagine ? () => setState(() => pagina++) : null,
            child: const Text("Successivo ▶"),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// modificaQuantita
// ============================================================
modificaQuantita(BuildContext context, String title, TextEditingController ctrl) async {
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
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
            child: Material(
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (_, __) => Text(
                        ctrl.text,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Divider(),
                    Flexible(
                      fit: FlexFit.loose,
                      child: TastierinoQuantita(controller: ctrl, p: null),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                      child: const Text("Annulla", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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


// ============================================================
// modificaTesto
// ============================================================
modificaTesto(BuildContext context, String title, TextEditingController ctrl) async {
  final theme = Theme.of(context);
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, minWidth: 600),
            child: Material(
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (_, __) => Text(
                        ctrl.text,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Divider(),
                    Flexible(
                      fit: FlexFit.loose,
                      child: TastierinoTestoCustom(
                        controller: ctrl,
                        onConferma: () => Navigator.pop(context),
                        onAnnulla:  () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                      child: const Text("Annulla", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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


// ============================================================
// TastierinoQuantita
// ============================================================
class TastierinoQuantita extends StatefulWidget {
  final TextEditingController controller;
  final ProdottoCarrello? p;
  const TastierinoQuantita({required this.controller, required this.p});

  @override
  State<TastierinoQuantita> createState() => TastierinoQuantitaState();
}

class TastierinoQuantitaState extends State<TastierinoQuantita> {

  @override
  void initState() {
    super.initState();
    widget.controller.text = '';
  }

  void _tap(String value) {
    if (value == "⌫") {
      if (widget.controller.text.isNotEmpty) {
        widget.controller.text =
            widget.controller.text.substring(0, widget.controller.text.length - 1);
      }
      return;
    }
    widget.controller.text += value;
  }

  void _conferma() async {
    if (widget.p != null && double.tryParse(widget.controller.text) != null) {
      context.read<CarrelloController>().upgradeQuantityRowCart(
        widget.p!.uuid,
        double.tryParse(widget.controller.text)!,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<String> keys = [
      "7", "8", "9", "⌫",
      "4", "5", "6", "00",
      "1", "2", "3", ",",
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   4,
            crossAxisSpacing: 5,
            mainAxisSpacing:  5,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (_, i) {
            final k = keys[i];
            Color bg = theme.colorScheme.onSurface.withOpacity(0.06);
            Color fg = theme.colorScheme.onSurface;
            if (k == "⌫") { bg = Colors.red.shade100; fg = Colors.red.shade700; }
            if (k == "00" || k == ",") { bg = theme.colorScheme.onSurface.withOpacity(0.10); }
            return ElevatedButton(
              onPressed: () => _tap(k),
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(k, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
            );
          },
        ),
        const SizedBox(height: 5),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () => _tap("0"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                    foregroundColor: theme.colorScheme.onSurface,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text("0", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _conferma,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Icon(Icons.check, size: 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          child: const Text("Annulla", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}


// ============================================================
// TastierinoTestoCustom
// ============================================================
class TastierinoTestoCustom extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onConferma;
  final VoidCallback onAnnulla;

  const TastierinoTestoCustom({
    super.key,
    required this.controller,
    required this.onConferma,
    required this.onAnnulla,
  });

  @override
  State<TastierinoTestoCustom> createState() => _TastierinoTestoCustomState();
}

class _TastierinoTestoCustomState extends State<TastierinoTestoCustom> {
  bool _maiuscolo = true;
  bool _numeri    = false;

  static const List<String> _lettere = [
    'Q','W','E','R','T','Y','U','I','O','P',
    'A','S','D','F','G','H','J','K','L','_',
    '⇧','Z','X','C','V','B','N','M','⌫',
    '123',' ',' ',' ',' ',' ',' ','✓',
  ];

  static const List<String> _numeriLayout = [
    '1','2','3','4','5','6','7','8','9','0',
    '-','_','@','.','/',':',';','(',')',',',
    '!','?','&','%','€','#','+','=','⌫',
    'ABC',' ',' ',' ',' ',' ',' ','✓',
  ];

  void _tap(String val) {
    switch (val) {
      case '⇧': setState(() => _maiuscolo = !_maiuscolo); return;
      case '⌫': _backspace(); return;
      case '✓': widget.onConferma(); return;
      case '123': setState(() => _numeri = true); return;
      case 'ABC': setState(() => _numeri = false); return;
    }

    final text  = widget.controller.text;
    final sel   = widget.controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end   = sel.end   < 0 ? text.length : sel.end;

    final input   = _maiuscolo && !_numeri ? val.toUpperCase() : val.toLowerCase();
    final newText = text.replaceRange(start, end, input);
    final cursor  = start + input.length;

    widget.controller.value = TextEditingValue(
      text:      newText,
      selection: TextSelection.collapsed(offset: cursor),
    );

    if (_maiuscolo && !_numeri) setState(() => _maiuscolo = false);
  }

  void _backspace() {
    final text  = widget.controller.text;
    final sel   = widget.controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end   = sel.end   < 0 ? text.length : sel.end;

    if (text.isEmpty) return;

    String newText;
    int    cursor;

    if (start != end) {
      newText = text.replaceRange(start, end, '');
      cursor  = start;
    } else if (start > 0) {
      newText = text.replaceRange(start - 1, start, '');
      cursor  = start - 1;
    } else {
      return;
    }

    widget.controller.value = TextEditingValue(
      text:      newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys  = _numeri ? _numeriLayout : _lettere;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   10,
        crossAxisSpacing: 4,
        mainAxisSpacing:  4,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (_, i) {
        final k = keys[i];
        final isSpecial = ['⇧','⌫','✓','123','ABC',' '].contains(k);

        Color bg = theme.colorScheme.onSurface.withOpacity(0.07);
        Color fg = theme.colorScheme.onSurface;

        if (k == '⌫') { bg = Colors.red.shade100;  fg = Colors.red.shade700; }
        if (k == '✓') { bg = Colors.green.shade600; fg = Colors.white; }
        if (k == ' ') { bg = Colors.transparent; }

        return GestureDetector(
          onTap: () => _tap(k),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: k == ' '
                ? const SizedBox.shrink()
                : Text(
                    _maiuscolo && !_numeri ? k.toUpperCase() : k.toLowerCase(),
                    style: TextStyle(
                      fontSize: isSpecial ? 13 : 17,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
          ),
        );
      },
    );
  }
}


// ============================================================
// GrigliaProdottiMobile
// ============================================================
class GrigliaProdottiMobile extends StatelessWidget {
  final List<ArticleWhitPriceListModel> articoli;
  final GlobalKey tastierinoKey;

  const GrigliaProdottiMobile({
    super.key,
    required this.articoli,
    required this.tastierinoKey,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: articoli.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, i) {
        final p = articoli[i];

        final colore = p.colorFirstCategory != null
            ? Color(int.parse(p.colorFirstCategory!.replaceFirst("#", "0xff")))
            : const Color(0xFFE0E0E0);

        final prezzo = double.tryParse(p.price?.toString() ?? "0") ?? 0.0;

        return GestureDetector(
          onTap: () {
            (tastierinoKey.currentWidget as TastierinoCompattoFisso)
                .applicaProdotto(p, context.read<CarrelloController>(), false);
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (p.posTitle ?? p.title ?? "").toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E3A46),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${prezzo.toStringAsFixed(2).replaceAll('.', ',')} €",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: colore,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
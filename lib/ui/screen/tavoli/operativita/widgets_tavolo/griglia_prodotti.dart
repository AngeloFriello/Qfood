import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/category.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/state/controller_impostazioni.dart';
import 'package:dashboard/state/product_search_controller.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/sync_catalogo.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';


import '../../../sincronizzazioni/operatori/operator_preferences_controller.dart';


enum BancoLayout { grande, piccolo }


class GrigliaProdottiResponsiveTable extends StatefulWidget {
  final int? categoria;
  final ListPriceModel? listPrice;
  final BancoLayout layout;
  final GlobalKey tastierinoKey;
  final int?  reparto;
  final bool? preferred;
  final BuildContext  contextVista;
  final double gridWidth;

  const GrigliaProdottiResponsiveTable({
    super.key,
    this.categoria,
    this.listPrice,
    this.layout = BancoLayout.grande,
    this.reparto,
    this.preferred,
    required this.contextVista,
    required this.tastierinoKey,
    required this.gridWidth,
  });

  @override
  State<GrigliaProdottiResponsiveTable> createState() =>  _GrigliaProdottiResponsiveTableState();
}

class _GrigliaProdottiResponsiveTableState extends State<GrigliaProdottiResponsiveTable> {
  List<ArticleWhitPriceListModel>        articoli          = [];
  List<CategoryModel>                    categorie         = [];
  List<ArticleWhitPriceListModel>        articoliCategorie = [];
  List<ArticleWhitPriceListModel>        articoliFiltrati  = [];
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
    final categories =  rawCategoriesDb.map((catDb) => CategoryModel.fromJson(catDb)).toList();
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
  void didUpdateWidget(covariant GrigliaProdottiResponsiveTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoria != widget.categoria ||
        oldWidget.reparto   != widget.reparto   ||
        oldWidget.layout    != widget.layout    ||
        oldWidget.listPrice != widget.listPrice ||
        oldWidget.preferred != widget.preferred ) {
      pagina = 1;
      _loadArticoli(widget.contextVista);
    }
  }

  void searchProducts(){
    if(!mounted) return;
    final text = _searchController.query;
    pagina = 1;
    _loadArticoli(widget.contextVista, search: text);
  }

  Future<void> _loadArticoli( BuildContext ctx, {String? search, } ) async {
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      dynamic device   = jsonDecode(pref.getString('device') ?? '{}');
      if( device == null || device.isEmpty ) return;
      String deviceType = device['deviceType'];

      if( widget.listPrice == null ){
        return;
      }

      if( search != null && search != ''){
        String queryArticleName = """SELECT art.*, lp.* FROM articles art INNER JOIN articlesPrices lp ON lp.idArticle = art.id AND lp.idPriceList = ${widget.listPrice?.id} WHERE LOWER(COALESCE(title, '')) LIKE LOWER("%${search}%") OR LOWER(COALESCE(posTitle, '')) LIKE LOWER("%${search}%")""";
        final respDbArticles = await LocalDB.query(queryArticleName).catchError((err) => []);
        List<ArticleWhitPriceListModel> articles = respDbArticles.map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb)).toList();
        if( deviceType == 'cash_pos' ) articles = articles.where((a) => a.availableForPos == 1 ).toList();
        if( mounted ) setState(() => articoli = articles);
        return;
      }

      if( widget.preferred == true ){
        String queryPreferred = """SELECT art.*, lp.* FROM articles art INNER JOIN articlesPrices lp ON lp.idArticle = art.id AND lp.idPriceList = ${widget.listPrice?.id} WHERE art.preferred = 1""";
        final respDbArticles = await LocalDB.query(queryPreferred).catchError((err) => []);
        List<ArticleWhitPriceListModel> articles = respDbArticles.map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb)).toList();
        final allCategories = await LocalDB.query("""SELECT * FROM categories""").catchError((err) => []);
        List<CategoryModel> categoriesList = allCategories.map((articleDb) => CategoryModel.fromJson(articleDb)).toList();
        final future = articles.map((art) async {
          String queryColorFirstCategory = """SELECT * FROM articlesCategories WHERE idArticle = ${art.id}""";
          final respqueryCategoryFor = await LocalDB.query(queryColorFirstCategory).catchError((err) => []);
          if( respqueryCategoryFor.isEmpty ){
            art.colorFirstCategory = '#9E9E9E';
          }else{
            CategoryModel firstCatForColor = categoriesList.firstWhere((c) => c.id == respqueryCategoryFor[0]['idCategory']);
            art.colorFirstCategory = firstCatForColor.color;
          }
        });
        await Future.wait(future);
        if( deviceType == 'cash_pos' ) articles = articles.where((a) => a.availableForPos == 1 ).toList();
        if( mounted ) setState(() => articoli = articles);
        return;
      }

      String queryArticleListPriceCategory = """SELECT art.*, lp.* FROM articlesCategories cat INNER JOIN articles art ON art.id = cat.idArticle INNER JOIN articlesPrices lp ON art.id = lp.idArticle AND lp.idPriceList = ${widget.listPrice?.id} WHERE cat.idCategory = ${widget.categoria} ORDER BY art.title""";
      final respDbArticles = await LocalDB.query(queryArticleListPriceCategory).catchError((err) => []);
      List<ArticleWhitPriceListModel> articles = respDbArticles.map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb)).toList();
      if( deviceType == 'cash_pos' ) articles = articles.where((a) => a.availableForPos == 1 ).toList();
      if( mounted ) setState(() => articoli = articles);

    }catch( err ){
      debugPrint(err.toString());
    }
    setState(() {});
  }

  int _getColumnCount() {
    final w = widget.gridWidth;
    final imp = context.read<ImpostazioniController>();
    final bool ridotto = imp.visualizzazioneProdottiRidotta;
    if (w < 600) return 2;
    if (w >= 600 && w < 1200) {
      return ridotto ? 9 : 6;
    }
    return ridotto ? 10 : 8;
  }

  double _getAspectRatio() {
    final w = widget.gridWidth;
    final imp = context.read<ImpostazioniController>();
    final bool ridotto = imp.visualizzazioneProdottiRidotta;
    if (w < 600) return 1.05;
    if (w >= 600 && w < 1200) {
      return ridotto ? 1.05 : 0.75;
    }
    return ridotto ? 1.4 : 1.2;
  }

  Color _getColoreProdotto() {
    if (widget.categoria == null || _searchController.query != '') {
      return const Color(0xFF9E9E9E);
    }
    final idCatSelezionata = widget.categoria;
    String hex = "#9E9E9E";
    final categoria = categorie.firstWhereOrNull((c) => c.id == idCatSelezionata);
    if( categoria != null && categoria.color != null ){
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
          const Text("Nessun dato trovato", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text("Effettua una sincronizzazione per caricare i prodotti.", style: TextStyle(fontSize: 15, color: Colors.grey)),
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
    if (articoli.isEmpty) return _emptyState(context);
    final int totale = articoli.length;

    // check ridondante mantenuto dal vecchio file
    if (totale == 0) return _emptyState(context);
    final bool paginazioneAttiva = !op.paginatedArticle;
    if (!paginazioneAttiva && pagina != 1) pagina = 1;
    if (paginazioneAttiva) {
      final maxPagina = (totale / perPagina).ceil();
      if (pagina > maxPagina) pagina = 1;
    }
    List<ArticleWhitPriceListModel> visibili;
    if (paginazioneAttiva) {
      final start = ((pagina - 1) * perPagina).clamp(0, totale);
      final end   = (start + perPagina).clamp(0, totale);
      visibili = articoli.sublist(start, end);
    } else {
      visibili = articoli;
    }
    // filtro manageGeneric mantenuto dal vecchio file
    if (operatorLogged != null && operatorLogged!.manageGeneric == 0) {
      visibili = visibili.where((a) => a.generic == 0).toList();
    }

    return Column(
      children: [
        Expanded(
          child: GridView.count(
            key: ValueKey("${imp.grandezzaNomeProdotti}_${imp.grandezzaNomeBreveProdotti}_${imp.nomeBreveProdotti}"),
            crossAxisCount: _getColumnCount(),
            childAspectRatio: _getAspectRatio(),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
            physics: const BouncingScrollPhysics(),
            children: visibili.map((art) => _cardProdotto(art)).toList(),
          ),
        ),
        if (paginazioneAttiva) ...[
          const SizedBox(height: 8),
          _paginationBar(),
        ],
      ],
    );
  }

  String _getNomeProdotto(ArticleWhitPriceListModel p, bool usaNomeBreve) {
    if (usaNomeBreve) {
      if (p.posTitle != null && p.posTitle!.trim().isNotEmpty) return p.posTitle!;
    }
    return p.title ?? '';
  }

  double _getFontSize(ImpostazioniController imp) {
    final usaNomeBreve = imp.nomeBreveProdotti;
    final bool ridotto = imp.visualizzazioneProdottiRidotta;
    final bool isTablet = widget.gridWidth >= 700 && widget.gridWidth < 1200;
    final size = usaNomeBreve ? imp.grandezzaNomeBreveProdotti : imp.grandezzaNomeProdotti;
    double base;
    switch (size) {
      case "S": base = usaNomeBreve ? 10 : 11; break;
      case "L": base = usaNomeBreve ? 16 : 17; break;
      default:  base = usaNomeBreve ? 12 : 13;
    }
    if (ridotto) {
      if (isTablet) base -= 3;
      else base -= 2;
    }
    return base.clamp(8, 18);
  }

  Widget _cardProdotto(ArticleWhitPriceListModel p) {
    final colore = p.colorFirstCategory is String
        ? Color(int.parse(p.colorFirstCategory!.replaceFirst("#", "0xff")))
        : _getColoreProdotto();
    final double prezzo = double.tryParse(p.price?.toString() ?? "0") ?? 0.0;
    final imp = context.watch<ImpostazioniController>();
    final bool usaNomeBreve = imp.nomeBreveProdotti;
    final String nome = _getNomeProdotto(p, usaNomeBreve);
    final bool ridotto = imp.visualizzazioneProdottiRidotta;
    final bool isTablet = widget.gridWidth >= 700 && widget.gridWidth < 1200;
    double fontSize = _getFontSize(imp);
    final int maxLines = ridotto ? 1 : 2;
    final FontWeight fontWeight = ridotto ? FontWeight.w400 : FontWeight.w500;
    return Card(
      elevation: ridotto ? 1 : 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      child: InkWell(
        onTap: () {
          final ctrTab    = context.read<ControllerTableOpened>();
          final ctrServer = context.read<ControllerWsServer>();
          ctrTab.addArticleInCart(p, 1, double.parse(p.price ?? '0'), false);
          ctrServer.updateTableServer(ctrTab.table!.id, ctrTab.getTable()!);
        },
        child: Column(
          children: [
            Container(
              height: ridotto ? 8 : 13,
              decoration: BoxDecoration(
                color: colore,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: ridotto ? 4 : 8),
                child: Center(
                  child: Text(
                    nome.trim().isEmpty ? "—" : nome.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(color: Colors.black87, fontSize: fontSize, fontWeight: fontWeight),
                  ),
                ),
              ),
            ),
            // prezzo nascosto in modalità ridotta (ripristinato dal vecchio file)
            if (!ridotto)
              Text(
                "$prezzo €",
                style: const TextStyle(color: Color(0xFF97D700), fontSize: 12, fontWeight: FontWeight.w600),
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
          TextButton(onPressed: pagina > 1 ? () => setState(() => pagina--) : null, child: const Text("◀ Precedente")),
          const SizedBox(width: 20),
          Text("Pagina $pagina / $totalePagine", style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 20),
          TextButton(onPressed: pagina < totalePagine ? () => setState(() => pagina++) : null, child: const Text("Successivo ▶")),
        ],
      ),
    );
  }
}
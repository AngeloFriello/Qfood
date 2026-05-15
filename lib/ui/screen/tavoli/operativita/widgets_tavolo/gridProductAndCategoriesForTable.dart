import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/modelli/article.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/printers/not_fiscal/esc_pos.dart';
import 'package:dashboard/state/product_search_controller.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/articoli/articolo_service.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controller_list_products_tables.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/griglia_prodotti.dart';
import 'package:dashboard/varianti/state/variants_controller.dart';
import 'package:dashboard/varianti/ui/varianti_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../../../../modelli/category.dart';
import '../../../../../state/controller_impostazioni.dart';
import '../../../sincronizzazioni/databasesql_lite/local_db.dart';
import 'dialog/cambia_uscita_dialog.dart';
import 'dialog/spostamento_prodotti_dialog.dart';

class GridProductAndCategoriesForTable extends StatefulWidget {
  const GridProductAndCategoriesForTable({
    super.key,
  });

  @override
  State<GridProductAndCategoriesForTable> createState() => _GridProductAndCategoriesForTableState();
}

class _GridProductAndCategoriesForTableState extends State<GridProductAndCategoriesForTable> {
    
    List<ListPriceModel> listPrices      = [];
    ListPriceModel? idListPriceSelected;
  
    @override
    void initState() {
      super.initState();
      setListPrices();
    }

  Future<void> setListPrices () async {
    final ctrTableOpen    = context.read<ControllerTableOpened>();
    listPrices           = await ListPriceModel.getByDb();
    listPrices           = listPrices.where((list) => list.counterpart == 'customer').toList(); //filtro solo per i listini per i clienti
    if( listPrices.isNotEmpty ){
      ListPriceModel? listPriceTable = listPrices.firstWhereOrNull((lp) => lp.id == ctrTableOpen.idPriceList );
      if( listPriceTable != null ) idListPriceSelected = listPriceTable;
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;
    final ctrlTableOpen = context.watch<ControllerTableOpened>();
    final ctrlProducts  = context.watch<ControllerListProductsTable>();
    final ctrlsearch    = context.watch<ProductSearchController>();

    final double gridWidth;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0F0E)
          : const Color(0xFFE9ECE5),
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER SUPERIORE
            TavoloTopBar(
              coperti: ctrlTableOpen.coverSelected,
              tavolo: ctrlTableOpen.table!,
            ),

            /// HEADER INFERIORE
            _HeaderInferiore(
              coperti: 1,
              selezionato: 1,
              onChanged: (v) =>
                  setState(() => {}),
            ),

            /// CONTENUTO
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// SINISTRA
                  Expanded(
                    child: Column(
                      children: [

                        /// GRIGLIA PRODOTTI TAVOLI
                        Container(
                          color: isDark
                              ? const Color(0xFF151715)
                              : const Color(0xFFE9ECE5),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final bool isTablet = width >= 700 && width < 1200;
                              double dynamicHeight;

                              if (isTablet) {
                                if (ctrlProducts.preferred) {
                                  dynamicHeight = 350; // 🔥 PIÙ ALTO → 10 articoli senza sovrapposizioni
                                } else {
                                  dynamicHeight = 350; // 🔥 PIÙ ALTO → 7/8 articoli puliti
                                }
                              } else {
                                dynamicHeight = 380; // fallback mobile
                              }

                              return SizedBox(
                                height: dynamicHeight,
                                child: GrigliaProdottiResponsiveTable(
                                  gridWidth: constraints.maxWidth,
                                  contextVista: context,
                                  listPrice: idListPriceSelected,
                                  categoria: ctrlProducts.categorySelected,
                                  reparto: null,
                                  tastierinoKey: tastierinoKey,
                                  preferred: ctrlProducts.preferred,
                                ),
                              );
                            },
                          ),
                  ),

                        /// ORDINI TAVOLO
                        Expanded(
                          child: TavoloOrderSection(),
                        ),
                      ],
                    ),
                  ),

                  /// PANEL DESTRO
                  if (isDesktop)
                    SizedBox(
                      width: 320,
                      child: _ActionPanel(),
                    ),
                ],
              ),
            ),

            /// ================= FOOTER FISSO =================
            _Footer(
              coperti: ctrlTableOpen.coverSelected,
              selezionato: ctrlTableOpen.coverSelected,
              onChanged: (v) => setState(() => {}),
            ),

          ],
        ),
      ),
    );
  }
}

/// TOP BAR
class TavoloTopBar extends StatelessWidget {
  final TableModel tavolo;
  final int coperti;
  final VoidCallback? onOpenActionsMobile;


  const TavoloTopBar({
    super.key,
    required this.tavolo,
    required this.coperti,
    this.onOpenActionsMobile,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    final bool isMobile = width < 700;
    int uscitaSelezionata = 1;

    /// Stato tavolo
    final String stato = (tavolo.status ?? "").toString().toLowerCase();

    const Color verdeQFood = Color(0xFFB5FF00);
    const Color rossoTavolo = Color(0xFFE53935);

    final Color headerColor = Color(0xFF708C00);

    final Color badgeColor =
    stato == "occupato"
        ? rossoTavolo
        : verdeQFood;

    final String numeroTavolo =
    (tavolo.title ?? tavolo.id ?? "").toString();

    final Color textColor = Colors.white;

    return Container(
      height: isMobile ? 60 : 66,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
      ),
      decoration: BoxDecoration(
        color: headerColor,
      ),
      child: Row(
        children: [

          /// BACK
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 16),


          Container(
            width: 10,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),



          const SizedBox(width: 12),

          /// TAVOLO + COPERTI
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tavolo $numeroTavolo",


                style: TextStyle(
                  color: textColor,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                "coperti $coperti",
                style: TextStyle(
                  color: textColor.withOpacity(.75),
                  fontSize: isMobile ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Spacer(),

          Container(
            height: isMobile ? 30 : 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              "Sconto 0,00%",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const SizedBox(width: 12),

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final result = await showCambiaUscitaDialog(
                productsSelect: [],
                context,
                maxUscite: 5,
                initialValue: uscitaSelezionata,
              );

              if (result != null) {
                print("Uscitaaaaaaaaaaaa selezionata: $result");
              }
            },
            child: Container(
              height: isMobile ? 34 : 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    uscitaSelezionata.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),




        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeaderInferiore extends StatelessWidget {
  final int coperti;
  final int selezionato;
  final ValueChanged<int> onChanged;

  const _HeaderInferiore({
    required this.coperti,
    required this.selezionato,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    const Color verdeHeader = Color(0xFF445A0A);
    const Color verdeQfood = Color(0xFF95C01F);

    const Color darkBackground = Color(0xFF121212);
    const Color darkField = Color(0xFF1E1E1E);

    final Color backgroundColor = isDark ? darkBackground : verdeHeader;

    final Color searchColor = isDark ? darkField : Colors.white.withOpacity(.15);

    final Color iconColor = isDark ? Colors.white : Colors.white70;

    return Container(
      height: 64,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
      ),
      child: Row(
        children: [

          Row(
            children: [
              _squareIconButton(
                icon: Icons.favorite,
                color: context.read<ControllerListProductsTable>().preferred == true ? Colors.red :  searchColor,
                iconColor: iconColor,
                onTap: () {
                  bool old = context.read<ControllerListProductsTable>().preferred;
                  context.read<ControllerListProductsTable>().setPreferred( !old  );
                },
              ),
              const SizedBox(width: 10),
              _squareIconButton(
                icon: Icons.list_alt,
                color: searchColor,
                iconColor: iconColor,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: searchColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.search, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: context.read<ProductSearchController>().crtBarSearch,
                      onChanged: context.read<ProductSearchController>().setQuery,
                      style: TextStyle(color: iconColor),
                      decoration: InputDecoration(
                        hintText: "Cerca",
                        hintStyle: TextStyle(
                          color: iconColor.withOpacity(.6),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// CATEGORIE
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: verdeQfood,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Categorie",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}



class TavoloOrderSection extends StatefulWidget {
  const TavoloOrderSection({super.key});

  @override
  State<TavoloOrderSection> createState() =>
      _TavoloOrderSectionState();
}

class _TavoloOrderSectionState extends State<TavoloOrderSection> {

  bool get hasSelectedLocked {
    return true;
  }


  bool get hasSelection {
    return true;
  }

  bool mostraStati = false;
  String? statoSelezionato; // "verde" o "rosso"
  String? stato; // "verde" | "rosso"
  List<ProdottoCarrello> productsSelected = [];


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrlTableOpen = context.read<ControllerTableOpened>();
    List<ProdottoCarrello> productsLocked = [];
    
    return Container(
      color: cs.surface,
      child: Column(
        children: [

          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(.35),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant),
              ),
            ),
            child: Row(
              children: [

                const SizedBox(width: 40),

                /// COLONNA PRODOTTO
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _openInsertProdottoDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Prodotto"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF97D700),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ),

                if (!hasSelection) ...[
                  /// QTY
                  Expanded(
                    flex: 2,
                    child: const Center(
                      child: Text(
                        "Qty",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  /// €
                  Expanded(
                    flex: 2,
                    child: const Center(
                      child: Text(
                        "€",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  /// USCITE
                  const SizedBox(
                    width: 50,
                    child: Center(
                      child: Icon(Icons.logout, size: 18),
                    ),
                  ),
                ],

                if (hasSelection)
                  _actionButtons( productsSelected ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: ctrlTableOpen.products.length,
              itemBuilder: (_, i) => _buildRow(ctrlTableOpen.products[i], productsSelected, productsLocked ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ProdottoCarrello p, List<ProdottoCarrello> selected, List<ProdottoCarrello> productsLocked, ) {
    final cs = Theme.of(context).colorScheme;
    final ctrTableCart = context.watch<ControllerTableOpened>();
    return Slidable( 
      key: ValueKey(p.hashCode),
       endActionPane: ActionPane(  
      motion: const ScrollMotion(),  // Scroll fluido
      extentRatio: 0.1,  // Larghezza 
      children: [
        // ICONA 1 (es. Elimina)
        SlidableAction(
          onPressed: (context) {
            if( p.printed == 1 ) return;
            // Rimuovi prodotto dal carrello
            ctrTableCart.removeArticleByUuid(uuid: p.uuid);
            final ctrTable   = context.read<ControllerTableOpened>();
            final ctrServer  = context.read<ControllerWsServer>();
            ctrServer.updateTableServer(ctrTable.table!.id, ctrTable.getTable()!);
            setState(() {});  // Refresh lista
          },
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          icon: Icons.delete,
        ),
      ],
    ),
      child: InkWell(
        onTap: () {
          if( p.printed == 1 ) return;
          _apriVarianti(context,p);
        }  ,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  /// CHECKBOX
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: selected.contains(p),
                      activeColor: const Color(0xFF97D700),
                      onChanged: (v) {
                        setState(() {
                          if(selected.contains(p)){
                            selected.remove(p);
                            return;
                          }else{
                            selected.add(p);
                          }
                        });
                      },
                    ),
                  ),
                    
                  /// NOME PRODOTTO
                  Expanded(
                    flex: 5,
                    child: Text(
                      p.article.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                    
                  /// QTA
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: InkWell(
                        onTap: () async {
                          final value      = await _modificaQuantita(context,  p.quantity);
                          final ctrTable   = context.read<ControllerTableOpened>();
                          final ctrServer  = context.read<ControllerWsServer>();
                          if (value != null) {
                            setState(() => p.setQuantity(value.toDouble()) );
                            ctrServer.updateTableServer(ctrTable.table!.id, ctrTable.getTable()!);
                          }
                        },
                        child: Container(
                          height: 30,
                          width: 90,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.quantity.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                    
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: InkWell(
                        onTap: () async {
                          final value = await _modificaPrezzo(context, p.priceRowCart);
                          final ctrTable   = context.read<ControllerTableOpened>();
                          final ctrServer  = context.read<ControllerWsServer>();
                          if (value != null) {
                            setState(() => p.setRowPrice(value) );
                          }
                          ctrServer.updateTableServer(ctrTable.table!.id, ctrTable.getTable()!);
                        },
                        child: Container(
                          height: 30,
                          width: 90,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.priceRowCart.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  p.printed == 1
                  ?
                  SizedBox(
                    width: 60,
                    child: const Icon(
                      Icons.print,
                      size: 20,
                      color: Color.fromARGB(255, 88, 174, 255),
                    ),
                  )
                  : SizedBox(width: 60,),
                  /// USCITE / STATO / LOCK
                  Center(
                    child: SizedBox(
                      width: 60,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: productsLocked.contains(p)
                                ? const Icon(
                                    Icons.lock,
                                    size: 20,
                                    color: Colors.red,
                                  )
                                : ('p.statoSelezionato' == "verde")
                                ? Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : ('p.statoSelezionato' == "rosso")
                                ? Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : const Icon(
                                    Icons.logout,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                    
                ],),
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
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    SizedBox(width: 40,),
                                    // =========================
                                    // NOME VARIANTE
                                    // =========================
                                    Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 0),
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
                                              //width: 1,
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
                                      flex: 2,
                                      child: Center(
                                        child: Container(
                                            height: 30,
                                            width: 90,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: cs.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              v.quantity.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                      ),
                                    ),

                                    // =========================
                                    // PREZZO VARIANTE
                                    // =========================
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Container(
                                          height: 30,
                                          width: 90,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            v.priceRowCart.toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    //Expanded(child: Container()),
                                    SizedBox(width: 60,),
                                    SizedBox(width: 60,)
                                  ],
                                ),
                              ),
                            ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButtons( List<ProdottoCarrello> selected ) {
    return Row(
      children: [
        _iconAction(
          Icons.restaurant,
          onTap: () async {
            final result = await showCambiaUscitaDialog(
              productsSelect: selected,
              context,
              maxUscite: 5,      // numero uscite disponibili
              initialValue: 1,
            );
            if( result == null ) return;
            final ctrTableOpen = context.read<ControllerTableOpened>();
            ctrTableOpen.changeExitProduct(selected, result.toInt());

          },
        ),

        _iconAction(
          Icons.exposure_plus_1,
          onTap: () async {
            final confirmed = await showAvanzaUscitaDialog(context);

            if (confirmed == true) {
              debugPrint("Avanza uscita +1 confermato");
            }
          },
        ),
        _iconAction(
          Icons.receipt_long,
          onTap: () async {
            await showSpostamentoProdottiDialog(
              context: context,
              nomeProdotto: "Coperto",
              quantitaIniziale: 5,
            );
          },
        ),
        _iconAction(
          Icons.list_alt,
          onTap: () {
            print("Conto");
          },
        ),

        const SizedBox(width: 14),

        mostraStati
            ? Row(
          children: [
            _statusCircle(
              Colors.green,
              onTap: () {
                setState(() {
                  for (var p in []) {
                    if (true) {
                      //'p.statoSelezionato' = "verde";
                    }
                  }
                  mostraStati = false;
                });
              },
            ),
            _statusCircle(
              Colors.red,
              onTap: () {
                setState(() {
                  for (var p in []) {
                    if (true) {
                      //'p.statoSelezionato' = "rosso";
                    }
                  }
                  mostraStati = false;
                });
              },
            ),
          ],
        )

            : _iconAction(
          Icons.logout,
          onTap: () {
            setState(() {
              mostraStati = true;
            });
          },
        ),



        _iconAction(
          hasSelectedLocked ? Icons.lock_open : Icons.lock,
          onTap: () {
            setState(() {
              for (var p in []) {
                if (true) {
                 // p.bloccato = !hasSelectedLocked;
                }
              }
            });
          },
        ),



      ],
    );
  }


  Widget _iconAction(
      IconData icon, {
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF97D700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }



  Widget _statusCircle(
      Color color, {
        required VoidCallback onTap,
        bool isActive = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(.2) : const Color(0xFF97D700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
  void _apriVarianti(BuildContext context, ProdottoCarrello prodotto) async {
    final controller                   = context.read<ControllerTableOpened>();
    final controllerVariantsController = context.read<VariantsController>();
    controllerVariantsController.reset();
    final variants                     = await ArticoloService.getVariations( prodotto, controller.idPriceList );
    controllerVariantsController.setAllVariants(variants);
    controllerVariantsController.setQuantityArticleInRow( prodotto.quantity );
    controllerVariantsController.setArticleCurrent(prodotto);
    showDialog(
      context: context,
      builder: (_) => VariantiDialog(
        prodotto: prodotto,
        varianti: variants,
        note: const [],
        inTable: true,
      ),
    );
  }
  // MODALI (INVARIATE

  Future<double?> _modificaQuantita(
    BuildContext context, double initial) async {
    final ctrl = TextEditingController(text: initial.toString());

    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Inserisci quantità"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text) ?? 0;
              final ctrServer  = context.read<ControllerWsServer>();
              final ctrlTavolo = context.read<ControllerTableOpened>();
              ctrServer.updateTableServer(ctrlTavolo.table!.id, ctrlTavolo.getTable()!);
              Navigator.pop(context, value);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<double?> _modificaPrezzo(
      BuildContext context, double initial) async {
    final ctrl = TextEditingController(text: initial.toStringAsFixed(2));

    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Inserisci prezzo totale"),
        content: TextField(
          controller: ctrl,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              final value =double.tryParse(ctrl.text) ?? 0;
              Navigator.pop(context, value);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _openInsertProdottoDialog() {
    final nomeCtrl = TextEditingController();
    final prezzoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Inserisci prodotto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl,
              decoration:
              const InputDecoration(labelText: "Nome prodotto"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: prezzoCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration:
              const InputDecoration(labelText: "Prezzo unitario"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              final nome = nomeCtrl.text.trim();
              final prezzo = double.tryParse(prezzoCtrl.text) ?? 0;

              if (nome.isEmpty) return;


              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}


class _ActionPanel extends StatefulWidget {
  const _ActionPanel({super.key});

  @override
  State<_ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends State<_ActionPanel> {
  List<CategoryModel> categorie = [];

  @override
  void initState() {
    super.initState();
    _caricaCategorie();
  }

  Future<void> _caricaCategorie() async {
    final raw = await LocalDB.getAll('categories');
    final list = raw.map((e) => CategoryModel.fromJson(e)).toList();

    list.sort((a, b) => a.position!.compareTo(b.position!));

    final crtProductTable = context.read<ControllerListProductsTable>();

    if (list.isNotEmpty) {
      crtProductTable.setCategorySelected(list.first.id); // ✅ FIX
    }

    setState(() => categorie = list);
  }

  @override
  Widget build(BuildContext context) {
    final crtProductTable = context.watch<ControllerListProductsTable>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 300,
      color: isDark
          ? const Color(0xFF121512)
          : const Color(0xFFE9ECE5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 26,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: categorie.length,
                itemBuilder: (_, i) {
                  final cat = categorie[i];
                  final bool attiva =
                      crtProductTable.categorySelected == cat.id;

                  return _PanelButtonCategoria(
                    label: cat.title ?? "",
                    attiva: attiva,
                    onTap: () {
                      crtProductTable.setPreferred(false);
                      crtProductTable.setCategorySelected(cat.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PanelButtonCategoria extends StatelessWidget {
  final String label;
  final bool attiva;
  final VoidCallback onTap;

  const _PanelButtonCategoria({
    required this.label,
    required this.attiva,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 700 && width < 1200;
    final imp = context.watch<ImpostazioniController>();
    final bool categorieGrandi = imp.visualizzazioneCategorieIngrandita;

    // LOGICA DIMENSIONI
    double height;
    double paddingBottom;
    double fontSize;
    int maxLines;

    if (isTablet) {
      if (categorieGrandi) {
        // GRANDI: 7/8 categorie BELLE GROSSE
        height        = 52; // PIÙ ALTE
        paddingBottom = 18; // PIÙ RESPIRO
        fontSize      = 18; // PIÙ LEGGIBILE
        maxLines      = 1;
      } else {
        // RIDOTTI: 10 categorie
        height        = 52; // LEGGERMENTE PIÙ ALTE
        paddingBottom = 8;
        fontSize      = 13;
        maxLines      = 2;
      }
    } else {
      // MOBILE / DESKTOP — INVARIATO
      height        = categorieGrandi ? 58 : 38;
      paddingBottom = categorieGrandi ? 22 : 10;
      fontSize      = 16;
      maxLines      = categorieGrandi ? 1 : 2;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: attiva
                ? const Color(0xFF97D700) // verde attivo
                : Colors.white,
            borderRadius: BorderRadius.circular(10),

            /// ombra soft identica
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: attiva
                  ? Colors.black
                  : const Color(0xFF2F3B2F),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int coperti;
  final int selezionato;
  final ValueChanged<int> onChanged;

  const _Footer({
    required this.coperti,
    required this.selezionato,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    const Color verdeQfood = Color(0xFF95C01F);
    const Color verdeDarkQfood = Color(0xFF445A0A);

    final Color backgroundColor =
    isDark ? const Color(0xFF121212) : verdeDarkQfood;

    return Container(
      width: double.infinity,
      height: isMobile ? 70 : 80,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
      ),
      child: Row(
        children: [

          _footerButton(
            icon: Icons.more_horiz,
            width: isMobile ? 55 : 70,
            isDark: isDark,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const _ScorciatoieDialog(),
              );
            },
          ),

          const SizedBox(width: 14),

          _footerButton(
            label: "Esci",
            width: isMobile ? 80 : 110,
            isDark: isDark,
            onTap: () {},
          ),

          const SizedBox(width: 14),

          Expanded(
            child: _footerButton(
              label: "Invia e resta",
              isDark: isDark,
              onTap: () async {
                final ctrTab = context.read<ControllerTableOpened>();
                Map<String, List<ProdottoCarrello>> pp = await  ctrTab.splitProductsForDeparment( false, ctrTab.products );
                await Future.wait(
                  pp.entries.map((entry) {
                    final key  = entry.key;
                    final list = entry.value;
                    return EscPos().printOrderToDepartment(
                      key.split(':')[0],
                      int.parse(key.split(':')[1]),
                      operatorLogged!,
                      deviceCurrent['title'],
                      ctrTab.table!.title,
                      list,
                      ctrTab.numberCoverSelected,
                      ctrTab.getTable()!,
                      null
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Container(
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: verdeQfood,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Invia",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerButton({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    bool isDark = false,
    double? width,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: width,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(.06)
              : Colors.white.withOpacity(.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 20)
            : Text(
          label!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}



class _ScorciatoieDialog extends StatelessWidget {
  const _ScorciatoieDialog();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    const Color verdeQfood = Color(0xFF95C01F);
    const Color verdeDark = Color(0xFFE8E8E8);

    return Dialog(
      backgroundColor: Colors.transparent,

      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : width * 0.3,
        vertical: isMobile ? 30 : 80,
      ),

      child: Stack(
        children: [

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.65)
                    : Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          /// MODALE
          Container(
            decoration: BoxDecoration(
              color: verdeDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: verdeQfood,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Scorciatoie tavolo 15",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [

                        _shortcutButton("Invia e vai al checkout"),
                        _shortcutButton("Esci e non stampare prodotti"),
                        _shortcutButton("Invia + preconto"),
                        _shortcutButton("Invia + Scontrino rapido"),

                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withOpacity(.2)),
                        const SizedBox(height: 20),

                        _shortcutButton("Conto"),
                        _shortcutButton("Preconto"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcutButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF445A0A),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
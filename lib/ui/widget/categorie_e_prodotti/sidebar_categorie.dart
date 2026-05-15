import 'package:dashboard/modelli/category.dart';
import 'package:dashboard/state/product_search_controller.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// NUOVO
import '../../../state/controller_impostazioni.dart';

class SidebarCategorie extends StatefulWidget {
  final Function(int idCategoria) onCategoriaSelezionata;
  final Function() changeTabAttivo;

  const SidebarCategorie({
    super.key,
    required this.onCategoriaSelezionata,
    required this.changeTabAttivo,
  });

  @override
  State<SidebarCategorie> createState() => _SidebarCategorieState();
}

class _SidebarCategorieState extends State<SidebarCategorie> {
  List<Map<String, dynamic>> categorie = [];
  int selezionata = -1;

  @override
  void initState() {
    super.initState();
    _caricaCategorie();
  }

  Future<void> _caricaCategorie() async {
    final rawCategoriesDb = await LocalDB.getAll('categories');
    final categories =
        rawCategoriesDb.map((catDb) => CategoryModel.fromJson(catDb).toMap()).toList();

    if (categories == null) return;

    categorie = categories;

    // Ordino come da backend (position ASC)
    categorie.sort((a, b) => a["position"].compareTo(b["position"]));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color verdeQfood    = const Color(0xFF97D700);
    final Color bgBase        = isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8);
    final Color cardColor     = const Color(0xFF6A6A6A);
    final Color textColor     = isDark ? Colors.white70 : Colors.white;
    final Color activeTextColor = Colors.black;

    if (categorie.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline, size: 32, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Nessuna categoria trovata",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 250,
      color: bgBase,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categorie.length,
        itemBuilder: (context, index) {
          final cat    = categorie[index];
          final bool attiva = selezionata == cat["id"];

          // NUOVO — legge preferenza visualizzazione categorie ingrandita
          final imp    = context.watch<ImpostazioniController>();
          final bool grandi = imp.visualizzazioneCategorieIngrandita;

          // Converte colore hex → Color
          Color coloreCategoria = cardColor;
          try {
            if (cat["color"] != null && cat["color"] != "") {
              coloreCategoria = Color(
                int.parse(cat["color"].replaceFirst("#", "0xff")),
              );
            }
          } catch (_) {}

          return Padding(
            // NUOVO — padding verticale dinamico
            padding: EdgeInsets.symmetric(vertical: grandi ? 6 : 3),
            child: GestureDetector(
              onTap: () {
                widget.changeTabAttivo();
                final controllerSearchBarProduct =
                    context.read<ProductSearchController>();
                controllerSearchBarProduct.clear();
                setState(() => selezionata = cat["id"]);
                widget.onCategoriaSelezionata(cat["id"]);
              },
              child: AnimatedContainer(
                // NUOVO — durata aumentata da 180 a 200ms
                duration: const Duration(milliseconds: 200),

                // NUOVO — padding verticale dinamico
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: grandi ? 22 : 14,
                ),

                decoration: BoxDecoration(
                  color: attiva ? verdeQfood : cardColor,
                  // NUOVO — border radius dinamico
                  borderRadius: BorderRadius.circular(grandi ? 14 : 10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(attiva ? 0.3 : 0.08),
                      blurRadius: attiva ? 10 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Center(
                  child: Text(
                    cat["title"] ?? "Senza nome",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: attiva ? activeTextColor : textColor,
                      // NUOVO — font size, weight e letterSpacing dinamici
                      fontSize:      grandi ? 18   : 13,
                      fontWeight:    grandi ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: grandi ? 0.6  : 0.4,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
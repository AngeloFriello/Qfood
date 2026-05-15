import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../modelli/articleInCart.dart';
import '../../../../../../modelli/articleWithPriceList.dart';
import '../../../../../../state/controller_carrello.dart';
import '../../../../checkout/checkout_page.dart';

const Color verdeQFood = Color(0xFFB5FF00);
const Color headerColor = Color(0xFF708C00);

class RigaSeparazioneModel {
  final String id;
  final String nome;
  final double prezzoUnitario;



  int qtyTotale;
  int qtySeparata;

  RigaSeparazioneModel({
    required this.id,
    required this.nome,
    required this.prezzoUnitario,
    required this.qtyTotale,


    this.qtySeparata = 0,
  });

  int get qtyPrincipale => qtyTotale - qtySeparata;

  double get totalePrincipale =>
      qtyPrincipale * prezzoUnitario;

  double get totaleSeparato =>
      qtySeparata * prezzoUnitario;
}

class SeparazioneContoPage extends StatefulWidget {
  final String tavolo;

  /// PASSA IL CARRELLO REALE
  final List<Map<String, dynamic>> carrello;

  final bool abilitaRiscontro;

  const SeparazioneContoPage({
    super.key,
    required this.tavolo,
    required this.carrello,
    this.abilitaRiscontro = false,
  });

  @override
  State<SeparazioneContoPage> createState() =>
      _SeparazioneContoPageState();
}

class _SeparazioneContoPageState
    extends State<SeparazioneContoPage> {
  late List<RigaSeparazioneModel> righe;
  bool divisioneAvviata = false;

  int numeroPersone = 0;

  @override
  void initState() {
    super.initState();

    /// LEGGE DIRETTAMENTE IL CARRELLO
    righe = widget.carrello.map((e) {
      return RigaSeparazioneModel(
        id: e["id"].toString(),
        nome: e["nome"],
        prezzoUnitario:
        (e["prezzoUnitario"] ?? e["prezzo"])
            .toDouble(),
        qtyTotale: (e["qty"]).toInt(),
      );
    }).toList();
  }

  double get totalePrincipale {
    return righe.fold(
      0,
          (sum, e) => sum + e.totalePrincipale,
    );
  }

  double get totaleSeparato {
    return righe.fold(
      0,
          (sum, e) => sum + e.totaleSeparato,
    );
  }

  List<RigaSeparazioneModel> get listaPrincipale =>
      righe.where((e) => e.qtyPrincipale > 0).toList();

  List<RigaSeparazioneModel> get listaSeparata =>
      righe.where((e) => e.qtySeparata > 0).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 900;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            _header(isDark),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: isMobile
                    ? Column(
                  children: [
                    Expanded(
                      child: _buildPanel(
                        titolo:
                        "Conto principale",
                        items:
                        listaPrincipale,
                        isDark: isDark,
                        principale: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildPanel(
                        titolo:
                        "Conto separato",
                        items:
                        listaSeparata,
                        isDark: isDark,
                        principale: false,
                      ),
                    ),
                  ],
                )
                    : Row(
                  children: [
                    Expanded(
                      child: _buildPanel(
                        titolo:
                        "Conto principale",
                        items:
                        listaPrincipale,
                        isDark: isDark,
                        principale: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildPanel(
                        titolo:
                        "Conto separato",
                        items:
                        listaSeparata,
                        isDark: isDark,
                        principale: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _footer(isDark),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Container(
      height: 74,
      padding:
      const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF536D00),
            Color(0xFF708C00),
          ],
        ),
      ),
      child: Row(
        children: [

          /// BACK
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                Colors.white.withOpacity(.12),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              "Tavolo ${widget.tavolo} • Separazione conto",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          /// AGGIUNGI PRODOTTO
          FilledButton.icon(
            onPressed: _apriAggiungiProdotto,
            style: FilledButton.styleFrom(
              backgroundColor: verdeQFood,
              foregroundColor: Colors.black,
              minimumSize: const Size(150, 50),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              "Prodotto",
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required String titolo,
    required List<RigaSeparazioneModel> items,
    required bool isDark,
    required bool principale,
  }) {
    final text =
    isDark ? Colors.white : const Color(0xFF171717);

    final bgCard = isDark
        ? const Color(0xFF1C1C1C)
        : Colors.white;

    final bgHeader = isDark
        ? const Color(0xFF232323)
        : const Color(0xFFF2F2F2);

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
          )
        ],
      ),
      child: Column(
        children: [

          /// HEADER TABELLA
          Container(
            height: 60,
            padding:
            const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: bgHeader,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titolo,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),

                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      "Qty",
                      style: TextStyle(
                        color:
                        text.withOpacity(.7),
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: 140,
                  child: Center(
                    child: Text(
                      "€",
                      style: TextStyle(
                        color:
                        text.withOpacity(.7),
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? Center(
              child: Text(
                "Nessun prodotto",
                style: TextStyle(
                  color:
                  text.withOpacity(.4),
                  fontSize: 18,
                ),
              ),
            )
                : ListView.separated(
              padding:
              const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder:
                  (_, __) => Divider(
                height: 1,
                color: isDark
                    ? Colors.white10
                    : Colors.black12,
              ),
              itemBuilder: (_, i) {
                final item = items[i];

                final qty = principale
                    ? item.qtyPrincipale
                    : item.qtySeparata;

                final totale = principale
                    ? item.totalePrincipale
                    : item.totaleSeparato;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),

                  /// CLICK SU TUTTA LA RIGA
                  onTap: () {

                    ///DA SINISTRA DESTRA
                    if (principale &&
                        item.qtyPrincipale > 0) {
                      setState(() {
                        item.qtySeparata++;
                      });
                    }

                    ///DA DESTRA SINISTRA
                    else if (!principale &&
                        item.qtySeparata > 0) {
                      setState(() {
                        item.qtySeparata--;
                      });
                    }
                  },

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    child: Row(
                      children: [

                        /// NOME
                        Expanded(
                          child: Text(
                            item.nome,
                            style: TextStyle(
                              color: text,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        /// QTY
                        Container(
                          width: 120,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2B2B2B)
                                : const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            qty.toString(),
                            style: TextStyle(
                              color: text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// PREZZO
                        Container(
                          width: 140,
                          height: 52,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2B2B2B)
                                : const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "€ ${totale.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
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
        ],
      ),
    );
  }



  Widget _footer(bool isDark) {

    final bgFooter = isDark
        ? const Color(0xFF181818)
        : const Color(0xFFF7F7F7);

    final cardColor = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.white;

    final textColor =
    isDark ? Colors.white : const Color(0xFF171717);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: bgFooter,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),

      child: Column(
        children: [

          /// RIGA TOTALI
          Row(
            children: [

              /// CONTO PRINCIPALE
              Expanded(
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [

                      /// LABEL
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF303030)
                                : const Color(0xFFEDEDED),

                            borderRadius:
                            const BorderRadius.horizontal(
                              left: Radius.circular(18),
                            ),
                          ),
                          child: Text(
                            "Totale",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      /// VALORE
                      Container(
                        width: 170,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        child: Text(
                          "€ ${totalePrincipale.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              /// CONTO SEPARATO
              Expanded(
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [

                      /// LABEL
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF303030)
                                : const Color(0xFFEDEDED),

                            borderRadius:
                            const BorderRadius.horizontal(
                              left: Radius.circular(18),
                            ),
                          ),
                          child: Text(
                            "Totale",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      /// VALORE
                      Container(
                        width: 170,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        child: Text(
                          "€ ${totaleSeparato.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// BARRA AZIONI QFOOD
          Container(
            height: 74,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
            ),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF536D00),
                  Color(0xFF708C00),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),

            child: Row(
              children: [

                ///SPOSTA TUTTO
                FilledButton(
                  onPressed: () {
                    setState(() {
                      for (final r in righe) {
                        r.qtySeparata = r.qtyTotale;
                      }
                    });
                  },

                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(150, 50),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    "Sposta tutto",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                ///RIPRISTINA
                FilledButton(
                  onPressed: () {
                    setState(() {
                      for (final r in righe) {
                        r.qtySeparata = 0;
                      }
                    });
                  },

                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.black,

                    foregroundColor: Colors.white,

                    minimumSize: const Size(150, 50),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    "Ripristina",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),

                const Spacer(),

                /// PRECONTO
                FilledButton(
                  onPressed: _stampaPreconto,

                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,

                    minimumSize: const Size(140, 50),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    "Preconto",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// RISCONTRO
                if (widget.abilitaRiscontro)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilledButton(
                      onPressed: _vaiRiscontro,

                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,

                        minimumSize: const Size(70, 50),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      child: const Text(
                        "R",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                /// CONTO
                FilledButton(
                  onPressed: _vaiCheckout,

                  style: FilledButton.styleFrom(
                    backgroundColor: verdeQFood,
                    foregroundColor: Colors.black,

                    minimumSize: const Size(170, 50),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    "Conto",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
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



  /// AGGIUNGI PRODOTTO MANUALE
  void _apriAggiungiProdotto() {
    final search = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              height:
              MediaQuery.of(context).size.height *
                  .88,
              decoration: BoxDecoration(
                color:
                Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [

                  const SizedBox(height: 14),

                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius:
                      BorderRadius.circular(
                          99),
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.all(20),
                    child: TextField(
                      controller: search,
                      decoration:
                      InputDecoration(
                        hintText:
                        "Cerca prodotto...",
                        prefixIcon:
                        const Icon(Icons.search),
                        filled: true,
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(18),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: 20,
                      itemBuilder: (_, i) {
                        return ListTile(
                          title: Text(
                              "Prodotto demo $i"),
                          subtitle:
                          const Text("€ 0.00"),
                          trailing: FilledButton(
                            onPressed: () {
                              setState(() {
                                righe.add(
                                  new RigaSeparazioneModel(
                                    id: "$i",
                                    nome:
                                    "Prodotto demo $i",
                                    prezzoUnitario:
                                    0,
                                    qtyTotale: 1,
                                  ),
                                );
                              });

                              Navigator.pop(
                                  context);
                            },
                            child: const Text(
                                "Aggiungi"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// PRECONTO
  void _stampaPreconto() {
    debugPrint("STAMPA PRECONTO");
  }

  /// CHECKOUT
  void _vaiCheckout() {

    final ctrCart = context.read<CarrelloController>();

    ///  RESET CARRELLO CHECKOUT
    ctrCart.clearCart();

    /// PRENDE SOLO I PRODOTTI SEPARATI
    final prodottiSeparati = righe.where(
          (e) => e.qtySeparata > 0,
    );

    if (prodottiSeparati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Seleziona almeno un prodotto",
          ),
        ),
      );
      return;
    }

    /// RICREA LE RIGHE NEL CARRELLO
    for (final p in prodottiSeparati) {

      /// CREA ARTICOLO
      final article = ArticleWhitPriceListModel(
        id: int.tryParse(p.id) ?? 0,
        title: p.nome,
        code: p.id,
        articleType: ArticleType.product,
        idVatRate: 1,
        rateValue: "10",
      );

      ///  AGGIUNGI NEL CARRELLO
      ctrCart.addArticleInCart(
        article,
        p.qtySeparata.toDouble(),
        p.prezzoUnitario,
        false,
      );
    }

    ctrCart.notifyListeners();

    ///  APRE CHECKOUT
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckoutPage(),
      ),
    );
  }
  /// RISCONTRO
  void _vaiRiscontro() {

    final ctrCart = context.read<CarrelloController>();

    ctrCart.clearCart();

    final prodottiSeparati = righe.where(
          (e) => e.qtySeparata > 0,
    );

    if (prodottiSeparati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Seleziona almeno un prodotto",
          ),
        ),
      );
      return;
    }

    for (final p in prodottiSeparati) {

      final article = ArticleWhitPriceListModel(
        id: int.tryParse(p.id) ?? 0,
        title: p.nome,
        code: p.id,
        articleType: ArticleType.product,
        idVatRate: 1,
        rateValue: "10",
      );

      ctrCart.addArticleInCart(
        article,
        p.qtySeparata.toDouble(),
        p.prezzoUnitario,
        false,
      );
    }

    ctrCart.riscontro = true;

    ctrCart.notifyListeners();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckoutPage(),
      ),
    );
  }
}
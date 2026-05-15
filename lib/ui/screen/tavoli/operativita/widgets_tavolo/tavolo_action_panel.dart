import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/gridProductAndCategoriesForTable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../modelli/articleInCart.dart';
import '../../../../../modelli/table.dart';
import '../../../../../state/controller_carrello.dart';
import 'operazioni/separazione_conto.dart';
import 'operazioni/suddivisione_conto/suddivisione_conto.dart';


class TavoloActionPanelDesktop extends StatelessWidget {
  final Function setState;
  final TableModel tavolo;

  /// PRODOTTI DEL CARRELLO
  final List<ProdottoCarrello> products;

  const TavoloActionPanelDesktop({
    required this.setState,
    required this.tavolo,
    required this.products,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
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

            /// INSERISCI
            _PanelButton(
              label: "Inserisci",
              tap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        GridProductAndCategoriesForTable(),
                  ),
                );

                setState();
              },
            ),

            /// INVIA COMANDA
            _PanelButton(
              label: "Invia comanda",
              tap: () {},
            ),

            /// PRECONTO
            _PanelButton(
              label: "Preconto",
              tap: () {},
            ),

            /// CONTO
            _PanelButton(
              label: "Conto",
              tap: () {},
            ),

            /// SEPARAZIONE CONTO
            _PanelButton(
              label: "Separazione conto",
              tap: () {

                ///CONVERSIONE CARRELLO
                final carrelloConvertito =
                products.map((p) {
                  return {
                    "id": p.article.id,
                    "nome": p.article.title,

                    /// qty
                    "qty": p.quantity.toInt(),

                    /// prezzo unitario
                    "prezzoUnitario":
                    p.quantity <= 0
                        ? 0.0
                        : (p.priceRowCart /
                        p.quantity)
                        .toDouble(),

                    /// totale riga
                    "prezzo":
                    p.priceRowCart.toDouble(),
                  };
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SeparazioneContoPage(
                          tavolo: tavolo.id.toString(),
                          carrello:
                          carrelloConvertito,
                        ),
                  ),
                );
              },
            ),

            /// SUDDIVISIONE
            _PanelButton(
              label: "Suddivisione",
              tap: () async {

                final totale = context
                    .read<CarrelloController>()
                    .totalWithTipsAndDiscount;

                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => SuddivisioneContoDialog(
                    totale: totale,
                  ),
                );

              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final String label;
  final Function tap;

  const _PanelButton({
    required this.label,
    required this.tap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => tap(),
        child: Container(
          height: 42,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(12),

            /// ombra moderna
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F3B2F),
            ),
          ),
        ),
      ),
    );
  }
}

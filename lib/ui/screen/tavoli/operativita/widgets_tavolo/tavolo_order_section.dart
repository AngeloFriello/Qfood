import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dialog/cambia_uscita_dialog.dart';
import 'dialog/spostamento_prodotti_dialog.dart';

class TavoloOrderSection extends StatefulWidget {
  const TavoloOrderSection({super.key});
  
  @override
  State<TavoloOrderSection> createState() => _TavoloOrderSectionState();
}

class _TavoloOrderSectionState extends State<TavoloOrderSection> {
  List<ProdottoCarrello> productsSelected = [];
  List<ProdottoCarrello> productsLocked   = [];


  bool mostraStati = false;
  String? statoSelezionato; // "verde" o "rosso"
  String? stato; // "verde" | "rosso"


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrTableCart = context.watch<ControllerTableOpened>();

    return Container(
      color: cs.surface,
      child: Column(
        children: [

          /// ================= HEADER =================
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
                      onPressed: (){}, //_openInsertProdottoDialog,
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

                if (!false) ...[
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

                if (false)
                  _actionButtons( ctrTableCart.products ),
              ],
            ),
          ),

          /// ================= LISTA =================
          Expanded(
            child: ListView.builder(
              itemCount: ctrTableCart.products.length,
              itemBuilder: (_, i) => _buildRow(_, ctrTableCart.products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ProdottoCarrello p) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [

          /// CHECKBOX
          SizedBox(
            width: 40,
            child: Checkbox(
              value: productsSelected.contains(p),
              activeColor: const Color(0xFF97D700),
              onChanged: (v) {
                setState(() {
                  v == true ? productsSelected.add(p) : productsSelected.remove(p);
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
                  final value = await _modificaQuantita(context, p.quantity);
                  if (value != null) {
                    setState(() => p.setQuantity(value));
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

          /// PREZZO (€) ← QUESTA ERA SPARITA
          Expanded(
            flex: 2,
            child: Center(
              child: InkWell(
                onTap: () async {
                 final value = await _modificaPrezzo(context, p.priceRowCart);
                  if (value != null) {
                    setState(() => p.setRowPrice(value));
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

          /// USCITE / STATO / LOCK
          SizedBox(
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
                  child: true
                      ? const Icon(
                    Icons.lock,
                    size: 20,
                    color: Colors.red,
                  )
                      : ("verde" == "verde")
                      ? Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  )
                      : ("verde" == "rosso")
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



        ],

      ),
    );
  }

  /// ================= ACTION BUTTONS =================
  Widget _actionButtons( List<ProdottoCarrello> prodotti) {
    return Row(
      children: [
        _iconAction(
          Icons.restaurant,
          onTap: () async {
            final result = await showCambiaUscitaDialog(
              productsSelect: productsSelected,
              context,
              maxUscite: 5,      // numero uscite disponibili
              initialValue: 1,
            );

            if (result != null) {
              // qui gestisci cambio uscita
              debugPrint("Uscita selezionata: $result");
            }
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
                  for (var p in prodotti) {
                    /* if (p.selezionato) {
                      p.statoSelezionato = "verde";
                    } */
                  }
                  mostraStati = false;
                });
              },
            ),
            _statusCircle(
              Colors.red,
              onTap: () {
                setState(() {
                 /*  for (var p in prodotti) {
                    if (p.selezionato) {
                      p.statoSelezionato = "rosso";
                    }
                  } */
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



       /*  _iconAction(
          hasSelectedLocked ? Icons.lock_open : Icons.lock,
          onTap: () {
            setState(() {
              for (var p in prodotti) {
                if (p.selezionato) {
                  p.bloccato = !hasSelectedLocked;
                }
              }
            });
          },
        ), */



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


  // ==========================
  // MODALI (INVARIATE)
  // ==========================

  Future<double?> _modificaQuantita(
      BuildContext context, double initial) async {
    final ctrl =
    TextEditingController(text: initial.toString());

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
              Navigator.pop(context, value);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<double?> _modificaPrezzo( BuildContext context, double initial ) async {
    final ctrl = TextEditingController(
        text: initial.toStringAsFixed(2));

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
              final value = double.tryParse(ctrl.text) ?? 0;
              Navigator.pop(context, value);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

/*   void _openInsertProdottoDialog() {
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
              final prezzo =
                  double.tryParse(prezzoCtrl.text) ?? 0;

              if (nome.isEmpty) return;

              setState(() {
                prodotti.add(
                  _ProdottoRiga(
                      nome: nome,
                      qty: 1,
                      prezzo: prezzo),
                );
              });

              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
} */

}

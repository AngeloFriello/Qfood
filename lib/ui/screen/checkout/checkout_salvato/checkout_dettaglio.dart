import 'package:dashboard/modelli/cartModelSaledSuspended.dart';
import 'package:dashboard/ui/screen/checkout/checkout_salvato/suspended_checkout_db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/controller_carrello.dart';
import 'suspended_checkout.dart';

class CheckoutDettaglio extends StatelessWidget {
  final CartModelSaledSuspended checkout;
  final Function loadSuspended;
  const CheckoutDettaglio({
    super.key,
    required this.checkout,
    required this.loadSuspended,
  });

  @override
  Widget build(BuildContext context) {
    final carrello = context.read<CarrelloController>();
    final items = checkout.products;

    Color adaptiveTextColor(BuildContext context) {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white;
    }


    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Sostituisci:
// final items = [];
// e la sezione // ===== PRODOTTI =====

// ===== PRODOTTI =====
const SizedBox(height: 4),

...checkout.products.map((p) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── RIGA PRINCIPALE ──
        Row(
          children: [
            // Badge quantità
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(
                p.quantity % 1 == 0
                    ? p.quantity.toInt().toString()
                    : p.quantity.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nome
            Expanded(
              child: Text(
                p.article.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Prezzo riga
            Text(
              "€ ${p.priceRowCart.toStringAsFixed(2).replaceAll('.', ',')}",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // ── VARIANTI ──
        ...[...p.variationsMinus, ...p.variationsPlus, ...p.variationsFree, ...p.variationsInfo]
            .map((v) => Padding(
                  padding: const EdgeInsets.only(left: 40, top: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: v.variationType == 'minus'
                          ? Colors.red.withOpacity(0.10)
                          : Colors.green.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "${v.variationType == 'minus' ? '−' : '+'} ${v.article.title}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: v.variationType == 'minus'
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                )),
      ],
    ),
  );
}),

          // Nota carrello
          if (checkout.note.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 14, color: Color(0xFF795548)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      checkout.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4E342E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ===== AZIONI =====
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _btnIcon(
                icon: Icons.receipt_long,
                label: "Preconto",
                onPressed: () {
                  // TODO: stampa / visualizza preconto
                },
              ),

              _btnIcon(
                icon: Icons.send,
                label: "Invia comanda",
                onPressed: () {
                  // TODO: invio comanda cucina
                },
              ),

              _btnIcon(
                icon: Icons.table_bar,
                label: "Sposta su tavolo",
                onPressed: () {
                  // TODO: selezione tavolo
                },
              ),

              //_btnAggiungi(context, checkout),


              ElevatedButton.icon(
                icon: Icon(
                  Icons.restore,
                  size: 20,
                  color: adaptiveTextColor(context),
                ),
                label: Text(
                  "Ripristina",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: adaptiveTextColor(context),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: adaptiveTextColor(context), // 🔥 CHIAVE
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  checkout.suspendedInCart(carrello);
                  SuspendedCheckoutDB.delete(checkout.id ?? 0);
                  Navigator.pop(context);
                },
              ),


              ElevatedButton.icon(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: adaptiveTextColor(context),
                ),
                label: Text(
                  "Elimina",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: adaptiveTextColor(context),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: adaptiveTextColor(context),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await SuspendedCheckoutDB.delete(checkout.id ?? 0);
                  loadSuspended();
                },
              ),


            ],
          ),
          
          const Divider(height: 24),


        ],
      ),
    );
  }

  Widget _btnIcon({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

}

Color adaptiveTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : Colors.white;
}


Widget _btnAggiungi(BuildContext context, SuspendedCheckout checkout) {
  final textColor = adaptiveTextColor(context);

  return ElevatedButton.icon(
    icon: Icon(
      Icons.add_shopping_cart,
      size: 20,
      color: textColor, // ✅ icona adattiva
    ),
    label: Text(
      "Aggiungi",
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor, // ✅ testo adattivo
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF95C01F), // verde QFood
      foregroundColor: textColor, // ✅ FONDAMENTALE
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    onPressed: () async {
      final int count =
          (checkout.payload["items"] as List?)?.length ?? 0;

      final bool? conferma = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 32,
            ),
            title: const Text("Attenzione"),
            content: Text(
              count == 1
                  ? "Vuoi aggiungere questo prodotto al checkout già in corso?"
                  : "Vuoi aggiungere $count prodotti al checkout già in corso?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Annulla"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Aggiungi"),
              ),
            ],
          );
        },
      );

      if (conferma != true) return;

      final carrello = context.read<CarrelloController>();
      carrello.aggiungiDaCheckoutSalvato(checkout.payload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF95C01F),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: textColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? "Prodotto aggiunto al checkout"
                      : "$count prodotti aggiunti al checkout",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    },
  );
}



import 'package:dashboard/ui/screen/ordini/models/ordine_tipo.dart';
import 'package:dashboard/ui/screen/ordini/state/ordini_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../state/controller_carrello.dart';
import '../../state/ordine_form_controller.dart';
import 'inserisci_ordine_dialog.dart';
import 'package:provider/provider.dart';

class OrdiniFooter extends StatelessWidget {
  const OrdiniFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
     final ctrl = context.watch<OrdiniListController>();

    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFF97D700); // verde QFOOD

    final buttonColor = isDark
        ? const Color(0xFF2EE6B8)
        : const Color(0xFF6EE7C8);

    final iconColor = isDark ? Colors.black : const Color(0xFF1A1A1A);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        children: [
          // ---------------- SINISTRA ----------------
          const Text(
            'Mostra ordini completati',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: ctrl.ordiniCompletati,
            onChanged: (v) {
              ctrl.setFiltroOrdiniCompletati(v);
            },
            thumbColor: WidgetStateProperty.all(Colors.white),
          ),

          const Spacer(),

          // ---------------- DESTRA ----------------
          _FooterActionButton(
            icon: LucideIcons.shoppingBag,
            tooltip: 'Nuovo Take Away',
            bgColor: buttonColor,
            iconColor: iconColor,
            size: 50,        // GRANDE COME FOTO
            iconSize: 32,
            badgeSize: 12,
            onTap: () async {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => InserisciOrdineSheet(ordineTipo: OrdineTipo.ritiro),  /* ChangeNotifierProvider(
                  create: (_) => OrdineFormController(),
                  child: InserisciOrdineSheet(ordineTipo: OrdineTipo.ritiro),
                ), */
              );
            },
          ),

          const SizedBox(width: 10),
          _FooterActionButton(
            icon: LucideIcons.bike,
            tooltip: 'Nuova Consegna',
            bgColor: buttonColor,
            iconColor: iconColor,
            size: 50,
            iconSize: 32,
            badgeSize: 12,

            onTap: () async {
              final carrello = context.read<CarrelloController>();

              //  IMPOSTA SUBITO IL TIPO
              carrello.setTipoOrdine('delivery');

              await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => InserisciOrdineSheet(ordineTipo: OrdineTipo.consegna),  /* ChangeNotifierProvider(
                    create: (_) => OrdineFormController(),
                    child: InserisciOrdineSheet(ordineTipo: OrdineTipo.ritiro),
                  ), */
                );
              },
          ),
        ],
      ),
    );
  }
}



class _FooterActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  ///  PARAMETRI DI SCALA
  final double size;       // dimensione bottone
  final double iconSize;   // dimensione icona
  final double badgeSize;  // dimensione +

  const _FooterActionButton({
    required this.icon,
    required this.tooltip,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.size = 62,        //  DEFAULT GRANDE
    this.iconSize = 36,    //  ICONA GRANDE
    this.badgeSize = 10,   //  BADGE
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// ICONA CENTRALE
              Icon(
                icon,
                size: iconSize,
                color: iconColor,
              ),

              /// ➕ BADGE
              Positioned(
                bottom: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_circle,
                    size: badgeSize,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<int?> showCambiaUscitaDialog(
    BuildContext context, {
      required List<ProdottoCarrello> productsSelect,
      required int maxUscite,
      int initialValue = 1,
    }) {
  int selected = initialValue;

  return showDialog<int>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Cambia uscita",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Per i prodotti non inviati selezionati",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),

                ...List.generate(maxUscite, (index) {
                  final value = index + 1;

                  return RadioListTile<int>(
                    value: value,
                    groupValue: selected,
                    onChanged: (v) {
                      setState(() {
                        selected = v!;
                      });
                    },
                    title: Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: theme.colorScheme.primary,
                  );
                }),
              ],
            );
          },
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULLA"),
          ),
          TextButton(
            onPressed: () {
              
              Navigator.pop(context, selected);
            } ,
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}



Future<bool?> showAvanzaUscitaDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Avanza uscita +1",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Per i prodotti non inviati selezionati",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ANNULLA"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

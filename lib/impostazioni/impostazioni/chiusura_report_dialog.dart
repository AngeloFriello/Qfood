import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_transaction.dart';
import 'package:flutter/material.dart';

Future<void> mostraDialogChiusura(BuildContext context) async {
  final List<String> opzioni = [
    "Chiusura cassa CASSA 11",
    "Chiusura cassa CASSA 12",
    "Chiusura cassa CASSA 13",
    "Report giornaliero",
    "Chiusura + Report",
    "Report avanzato",
  ];

  String? selezionata;

  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color verdeQFood = const Color(0xFF95C01F);
  final Color bgDialog = isDark ? const Color(0xFF1B1B1B) : Colors.white;
  final Color testoPrimario = isDark ? Colors.white : Colors.black87;
  final Color bordo = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

  await showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460), // 👈 più stretto sempre
          child: AlertDialog(
            backgroundColor: bgDialog,
            elevation: 6,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: bordo.withOpacity(0.3)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
            title: Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: verdeQFood, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Chiusura / Report",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: testoPrimario,
                  ),
                ),
              ],
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...opzioni.map((option) {
                      final isSelected = selezionata == option;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          onTap: () => setState(() => selezionata = option),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? verdeQFood.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? verdeQFood
                                    : bordo.withOpacity(0.4),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? verdeQFood
                                      : bordo.withOpacity(0.6),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: testoPrimario,
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    TextButton(
                      onPressed: () async {
                        if( operatorLogged != null && (operatorLogged!.fiscalClosure ?? 0) == 0 ){
                          SnackBarForcedClosure('Operatore non abilitato', Colors.red);
                          return;
                        }
                        
                        final printer = ServiceReceipt.instance();
                        await printer.fiscalClosure();
                        Navigator.of(ctx).pop();
                      }, 
                      child: Text('Chiusura cassa'))
                    ],
                  ),
                );
              },
            ),
            actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: testoPrimario,
                  side: BorderSide(color: bordo.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                label: const Text(
                  "Annulla",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                onPressed: selezionata == null
                    ? null
                    : () {
                  Navigator.of(ctx, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Hai selezionato: $selezionata",
                        style:
                        const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: verdeQFood,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: verdeQFood,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                label: const Text("Conferma"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

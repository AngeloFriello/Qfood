import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


Future<int?> mostraDialogCoperti(
    BuildContext context,
    TableModel tavolo,
    ) async {

  final ctrl = TextEditingController();
  final theme = Theme.of(context);

  final size = MediaQuery.of(context).size;

  final bool isMobile = size.width < 700;

  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 460,
              maxHeight: size.height * 0.85,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(28),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// ================================
                    /// TITOLO
                    /// ================================
                    Text(
                      "Coperti",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// SOTTOTITOLO
                    Text(
                      "Inserisci coperti",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(.6),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// NUMERO DIGITATO
                    AnimatedBuilder(
                      animation: ctrl,
                      builder: (_, __) {
                        return Text(
                          ctrl.text.isEmpty ? "0" : ctrl.text,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    Divider(
                      color: theme.colorScheme.outlineVariant,
                    ),

                    const SizedBox(height: 10),

                    /// ================================
                    /// TASTIERINO
                    /// ================================
                    Flexible(
                      child: _TastierinoCoperti(
                        controller: ctrl,
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// ================================
                    /// BOTTONI AZIONE
                    /// ================================
                    Row(
                      children: [

                        /// RESET
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                                foregroundColor:
                                theme.colorScheme.onSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                ctrl.clear();
                              },
                              child: const Icon(Icons.close),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        /// CONFERMA
                        /// CONFERMA
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF8BC34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                final value = int.tryParse(ctrl.text) ?? 0;
                                if (value <= 0) return;
                                final ctrlTavolo = context.read<ControllerTableOpened>();
                                ctrlTavolo.setNumberCoverSelected(value);
                                Navigator.of(context).pop(value); // chiude dialog

                                /* Future.microtask(() {
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => GridProductAndCategoriesForTable(
                                        coperti: value,
                                        tavolo: tavolo,
                                      ),
                                    ),
                                  );
                                }); */
                              },

                              child: const Icon(Icons.arrow_forward),
                            ),
                          ),
                        ),


                      ],
                    ),

                    const SizedBox(height: 10),

                    /// ANNULLA
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Annulla",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}



class _TastierinoCoperti extends StatelessWidget {
  final TextEditingController controller;

  const _TastierinoCoperti({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttons = [
      "7", "8", "9",
      "4", "5", "6",
      "1", "2", "3",
      "0", "00", "⌫",
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: buttons.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, index) {
        final value = buttons[index];

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (value == "⌫") {
              if (controller.text.isNotEmpty) {
                controller.text = controller.text.substring(
                  0,
                  controller.text.length - 1,
                );
              }
            } else {
              controller.text += value;
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

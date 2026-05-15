/* import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class TavoloCopertiBar extends StatelessWidget {
  final int copertoSelezionato;
  final ValueChanged<int> onCopertoChanged;
  final VoidCallback onProcedi;

  const TavoloCopertiBar({
    super.key,
    required this.copertoSelezionato,
    required this.onCopertoChanged,
    required this.onProcedi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrTavolo = context.watch<ControllerTableOpened>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant,
        ),
      ),
      child: Row(
        children: [

          /// ==========================
          /// COPERTI
          /// ==========================
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(5, (index) {
                  final number = index + 1;
                  final selected = number == copertoSelezionato;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () => onCopertoChanged(number),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'U$number',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? cs.onPrimary
                                    : cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline,
                              size: 18,
                              color: selected
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 18),

          /// ==========================
          /// BOTTONE PROCEDI
          /// ==========================
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onProcedi,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding:
                const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Procedi ${ctrTavolo.lastExist + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 */
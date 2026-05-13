import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TavoloExistStrip extends StatelessWidget {
  final int uscite;
  final int uscitaSelezionata;
  final ValueChanged<int> onExitChanged;
  final VoidCallback onProcedi;

  const TavoloExistStrip({
    super.key,
    required this.uscite,
    required this.uscitaSelezionata,
    required this.onExitChanged,
    required this.onProcedi,
  });

  @override
  Widget build(BuildContext context) {
    final ctrTavolo = context.watch<ControllerTableOpened>();
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    final bool isMobile = width < 700;
    final bool isDark = theme.brightness == Brightness.dark;

    const Color verdeQFood = Color(0xFF95C01F);
    const Color chipGrey = Color(0xFF607D8B);
    const Color procediColor = Color(0xFF8E7CC3);

    final Color background =
    isDark ? const Color(0xFF232323) : const Color(0xFFECEFF1);

    return Container(
      height: isMobile ? 54 : 60, // 🔥 PIÙ BASSO
      color: background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 16,
      ),
      child: Row(
        children: [

          /// uscite
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(5, (index) {
                  final number = index + 1;
                  final selected = number == uscitaSelezionata;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onExitChanged(number),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? verdeQFood
                              : chipGrey.withOpacity(.20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "U$number",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: selected
                                    ? Colors.white
                                    : (isDark
                                    ? Colors.white70
                                    : Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                  ? Colors.white54
                                  : Colors.black54),
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

          const SizedBox(width: 12),

          /// PROCEDi (compatto)
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onProcedi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF95C01F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Procedi-- ${ctrTavolo.lastExist + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

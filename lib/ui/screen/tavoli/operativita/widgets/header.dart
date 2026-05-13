import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TavoloHeader extends StatelessWidget
    implements PreferredSizeWidget {

  final Map<String, dynamic> tavolo;
  final int coperti;

  const TavoloHeader({
    required this.tavolo,
    required this.coperti,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stato = tavolo["stato"];

    Color statoColor;
    switch (stato) {
      case "occupato":
        statoColor = const Color(0xFFE53935); // rosso
        break;

      case "prenotato":
        statoColor = const Color(0xFFB7E36B);
        break;

      default:
        statoColor = const Color(0xFF708C00); // verde QFood
    }


    final bgColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFF97D700);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Material(
      color: bgColor,
      elevation: 0,
      child: SizedBox(
        height: 72,
        child: Row(
          children: [

            // BACK
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),

            // BARRA STATO
            Container(
              width: 6,
              height: 38,
              decoration: BoxDecoration(
                color: statoColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(width: 12),

            // INFO TAVOLO
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tavolo["label"].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Coperti $coperti',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ===============================
            // DESTRA AZIONI
            // ===============================

            if (!isMobile)
              _HeaderActionButton(
                icon: Icons.percent,
                label: "Sconto 0,00%",
                onTap: () {
                  // TODO mock
                },
              ),

            const SizedBox(width: 10),

            _HeaderCircleButton(
              icon: Icons.group_add,
              onTap: () {
                // TODO aggiungi persona
              },
            ),

            const SizedBox(width: 10),

            _HeaderCircleButton(
              icon: Icons.info_outline,
              onTap: () {
                // TODO info
              },
            ),

            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}


class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

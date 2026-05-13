import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../filtri/prenotazioni_controller_filtri.dart';
import '../ui/nuova_prenotazione_page.dart';

class PrenotazioniFooter extends StatelessWidget {
  const PrenotazioniFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFF7FBF1E);


    final buttonColor =
    isDark ? const Color(0xFF2EE6B8) : const Color(0xFF6EE7C8);

    final iconColor = isDark ? Colors.black : const Color(0xFF1A1A1A);

    final ctrl = context.watch<PrenotazioniController>();

    final totalePrenotazioni = ctrl.filtrate.length;
    final totalePax =
    ctrl.filtrate.fold<int>(0, (sum, p) => sum + p.pax);

    final now = DateFormat('EEE d MMM  HH:mm', 'it_IT')
        .format(DateTime.now());

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        children: [
          // ---------------- SINISTRA ----------------
          Row(
            children: [
              const Icon(Icons.wifi, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                now,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ---------------- CENTRO ----------------
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.home, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$totalePrenotazioni prenotazioni',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  '$totalePax pax',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ---------------- DESTRA ----------------
          _FooterActionButton(
            icon: LucideIcons.calendarPlus,
            tooltip: 'Nuova prenotazione',
            bgColor: buttonColor,
            iconColor: iconColor,
            size: 50,
            iconSize: 30,
            badgeSize: 12,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<PrenotazioniController>(),
                    child: const NuovaPrenotazionePage(),
                  ),
                ),
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

  final double size;
  final double iconSize;
  final double badgeSize;

  const _FooterActionButton({
    required this.icon,
    required this.tooltip,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.size = 62,
    this.iconSize = 36,
    this.badgeSize = 10,
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
              Icon(icon, size: iconSize, color: iconColor),
              Positioned(
                bottom: 6,
                child: Icon(
                  Icons.add_circle,
                  size: badgeSize,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

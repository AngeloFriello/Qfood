import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
class FooterNavbarTavoli extends StatefulWidget {
  const FooterNavbarTavoli({super.key});

  @override
  State<FooterNavbarTavoli> createState() => _FooterNavbarState();
}

class _FooterNavbarState extends State<FooterNavbarTavoli> {
  String orario = "";
  bool reteAttiva = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _aggiornaOra();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _aggiornaOra(),
    );
  }

  void _aggiornaOra() {
    final now = DateTime.now();
    setState(() {
      orario =
      "${_giorno(now.weekday)} ${now.day.toString().padLeft(2, '0')} "
          "${_mese(now.month)} "
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}";
    });
  }

  String _giorno(int n) {
    const giorni = ["lun", "mar", "mer", "gio", "ven", "sab", "dom"];
    return giorni[n - 1];
  }

  String _mese(int n) {
    const mesi = [
      "gen", "feb", "mar", "apr", "mag", "giu",
      "lug", "ago", "set", "ott", "nov", "dic"
    ];
    return mesi[n - 1];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color footerColor =
    isDark ? const Color(0xFF1F2A1F) : const Color(0xFF97D700);

    final Color pillBg =
    isDark ? Colors.white.withOpacity(0.08) : Colors.white;

    final Color pillTextColor =
    isDark ? Colors.white : Colors.black87;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: footerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [

                    /// WIFI
                    Icon(
                      reteAttiva
                          ? LucideIcons.wifi
                          : LucideIcons.wifiOff,
                      size: 18,
                      color: reteAttiva
                          ? Colors.white
                          : Colors.redAccent,
                    ),

                    const SizedBox(width: 8),

                    /// ORARIO
                    Text(
                      orario,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 32),

                    /// TEMPI OCCUPAZIONE
                    _pillButton(
                      icon: LucideIcons.timer,
                      label: "Tempi di occupazione",
                      onTap: () {},
                      bgColor: pillBg,
                      textColor: pillTextColor,
                    ),

                    const SizedBox(width: 12),

                    /// PRENOTAZIONI
                    _pillButton(
                      icon: LucideIcons.calendarDays,
                      label: "Prenotazioni",
                      onTap: () {},
                      bgColor: pillBg,
                      textColor: pillTextColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color bgColor,
    required Color textColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

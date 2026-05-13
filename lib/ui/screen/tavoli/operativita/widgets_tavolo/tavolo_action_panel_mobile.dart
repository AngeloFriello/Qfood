import 'package:flutter/material.dart';

/// ===============================================================
/// DESKTOP / TABLET PANEL LATERALE
/// ===============================================================
class TavoloActionPanel extends StatelessWidget {
  final int coperti;

  const TavoloActionPanel({
    super.key,
    required this.coperti,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? const Color(0xFF111411)
          : const Color(0xFFE9ECE5),
      child: Column(
        children: [

          /// BOTTONI
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                children: const [
                  _PanelButton(label: "Inserisci"),
                  _PanelButton(label: "Invia comanda"),
                  _PanelButton(label: "Preconto"),
                  _PanelButton(label: "Conto"),
                  _PanelButton(label: "Separazione"),
                  _PanelButton(label: "Suddivisione"),
                ],
              ),
            ),
          ),

          /// FOOTER VERDE
          Container(
            height: 72,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF97D700),
            ),
            alignment: Alignment.center,
            child: Text(
              "$coperti coperti",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// MOBILE BOTTOM SHEET PANEL
/// ===============================================================
class TavoloActionPanelMobile extends StatelessWidget {
  final int coperti;

  const TavoloActionPanelMobile({
    super.key,
    required this.coperti,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111411)
            : const Color(0xFFE9ECE5),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [

          const SizedBox(height: 14),

          /// HANDLE
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  _PanelButton(label: "Inserisci"),
                  _PanelButton(label: "Invia comanda"),
                  _PanelButton(label: "Preconto"),
                  _PanelButton(label: "Conto"),
                  _PanelButton(label: "Separazione"),
                  _PanelButton(label: "Suddivisione"),
                ],
              ),
            ),
          ),

          Container(
            height: 72,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF97D700),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "$coperti coperti",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// BOTTONE INTERNO (GRADIENTE MOCKUP)
/// ===============================================================
class _PanelButton extends StatelessWidget {
  final String label;

  const _PanelButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                const Color(0xFF1B1F1B),
                const Color(0xFF151915),
              ]
                  : [
                const Color(0xFFFFFFFF),
                const Color(0xFFF2F3F0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isDark ? 0.35 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF2E3A2E),
            ),
          ),
        ),
      ),
    );
  }
}

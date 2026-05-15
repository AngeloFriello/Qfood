import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/service/service_connection.dart';
import '../../../../impostazioni/impostazioni/menu_utente.dart';
import '../filtri/filtri.dart';
import '../lista_vendite.dart';


class HeaderTavoloPill extends StatefulWidget {
  final VoidCallback onBack;

  const HeaderTavoloPill({
    super.key,
    required this.onBack,
  });

  @override
  State<HeaderTavoloPill> createState() => _HeaderTavoloPillState();
}

class _HeaderTavoloPillState extends State<HeaderTavoloPill> {
  OverlayEntry? menuOverlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color headerColor =
    isDark ? const Color(0xFF1F2A1F) : const Color(0xFF97D700);

    final Color pillBg =
    isDark ? Colors.white.withOpacity(0.08) : Colors.white;

    final Color pillTextColor =
    isDark ? Colors.white : Colors.black87;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: headerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [

          /// ---------------------------------------------------------
          /// SINISTRA
          /// ---------------------------------------------------------
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Image.asset(
                  isDark
                      ? 'assets/logodark.png'
                      : 'assets/logosuverde.png',
                  key: ValueKey(isDark),
                  height: 40,
                ),
              ),

              const SizedBox(width: 12),

              Text(
                "QFood",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 18),


            ],
          ),

          const SizedBox(width: 40),

          /// ---------------------------------------------------------
          /// CENTRO
          /// ---------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _pillButton(
                    icon: LucideIcons.receipt,
                    label: "Lista vendite",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ListaVenditeModal(),
                      );
                    },
                    bgColor: pillBg,
                    textColor: pillTextColor,
                  ),

                  const SizedBox(width: 12),
                  _pillButton(
                    icon: LucideIcons.filter,
                    label: "Filtro stato",
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (_) => const FiltroStatoModal(),
                      );

                      if (result != null) {
                        print("Filtro selezionato: $result");
                      }
                    },
                    bgColor: pillBg,
                    textColor: pillTextColor,
                  ),

                  const SizedBox(width: 12),
                  _pillButton(
                    icon: LucideIcons.search,
                    label: "Cerca",
                    onTap: () {},
                    bgColor: pillBg,
                    textColor: pillTextColor,
                  ),
                  const SizedBox(width: 12),
                  _pillButton(
                    icon: LucideIcons.barChart3,
                    label: "Report",
                    onTap: () {},
                    bgColor: pillBg,
                    textColor: pillTextColor,
                  ),
                  const SizedBox(width: 12),
                  _pillButton(
                    icon: LucideIcons.droplets,
                    label: "Apertura Cassetto",
                    onTap: () {},
                    bgColor: pillBg,
                    textColor: pillTextColor,
                  ),

                  const SizedBox(width: 22),


                  /// STATUS WIFI + ORARIO
                  statusConnessioneQFood(
                    connected: context.watch<ConnectionController>().connected,
                  ),



                ],
              ),
            ),
          ),

          /// ---------------------------------------------------------
          /// DESTRA
          /// ---------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),
            onPressed: () => _mostraMenuUtente(context),
          ),
        ],
      ),
    );
  }


  Widget statusConnessioneQFood({
    required bool connected,
  }) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final giorni = [
      'lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'
    ];

    final giorno = giorni[now.weekday - 1];
    final data = "${now.day.toString().padLeft(2, '0')} apr";
    final ora = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final color = isDark ? Colors.white : Colors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          connected ? Icons.wifi : Icons.wifi_off,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 10),
        Text(
          "$giorno $data  $ora",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  /// -------------------------------------------------------
  /// MENU UTENTE
  /// -------------------------------------------------------
  void _mostraMenuUtente(BuildContext context) {
    if (menuOverlay != null) return;

    menuOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _chiudiMenuUtente,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
            Positioned(
              top: 72,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.surface,
                child: MenuUtente(
                  onClose: _chiudiMenuUtente,
                  context: context,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(menuOverlay!);
  }

  void _chiudiMenuUtente() {
    menuOverlay?.remove();
    menuOverlay = null;
  }

  /// -------------------------------------------------------
  /// PILL BUTTON (UNICA VERSIONE)
  /// -------------------------------------------------------
  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color bgColor,
    required Color textColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
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
                fontSize: 14,
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

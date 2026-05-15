/* import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TavoloTopBar extends StatelessWidget {
  final TableModel  tavolo;
  final VoidCallback? onOpenActionsMobile;

  const TavoloTopBar({
    super.key,
    required this.tavolo,
    this.onOpenActionsMobile,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final ctrlTable = context.watch<ControllerTableOpened>();
    final bool isMobile = width < 700;

    /// Stato tavolo
    final String stato = (tavolo.status ?? "").toString().toLowerCase();

    const Color verdeQFood = Color(0xFFB5FF00);
    const Color rossoTavolo = Color(0xFFE53935);

    final Color headerColor = Color(0xFF708C00);

    final Color badgeColor =
    stato == "occupato"
        ? rossoTavolo
        : verdeQFood;



    final Color textColor = Colors.white;

    return Container(
      height: isMobile ? 60 : 66,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
      ),
      decoration: BoxDecoration(
        color: headerColor,
      ),
      child: Row(
        children: [

          /// BACK
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),

          const SizedBox(width: 16),


          Container(
            width: 10,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),


          const SizedBox(width: 16),


          const SizedBox(width: 12),

          /// TAVOLO + COPERTI
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tavolo ${tavolo.title}",
                style: TextStyle(
                  color: textColor,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                "coperti ${ctrlTable.coverSelected}",
                style: TextStyle(
                  color: textColor.withOpacity(.75),
                  fontSize: isMobile ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Spacer(),

          /// CHIP SCONTO
          Container(
            height: isMobile ? 30 : 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              "Sconto 0,00%",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// GRUPPO
          _iconButton(
            icon: Icons.group_outlined,
            onTap: () {},
          ),

          const SizedBox(width: 8),

          /// INFO
          _iconButton(
            icon: Icons.info_outline,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
 */

import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../../../Global.dart';


class TavoloTopBar extends StatelessWidget {
  final TableModel tavolo;
  final VoidCallback? onOpenActionsMobile;


  const TavoloTopBar({
    super.key,
    required this.tavolo,
    this.onOpenActionsMobile,
  });


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final ctrlTable = context.watch<ControllerTableOpened>();
    final bool isMobile = width < 700;


    /// Stato tavolo
    final String stato = (tavolo.status ?? "").toString().toLowerCase();


    const Color verdeQFood  = Color(0xFFB5FF00);
    const Color rossoTavolo = Color(0xFFE53935);

    final Color headerColor = Color(0xFF708C00);

    final Color badgeColor =
        stato == "occupato"
            ? rossoTavolo
            : verdeQFood;

    final Color textColor = Colors.white;


    return Container(
      height: isMobile ? 60 : 66,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
      ),
      decoration: BoxDecoration(
        color: headerColor,
      ),
      child: Row(
        children: [

          /// BACK
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: (ctx) => Navigator.pop(ctx),
          ),

          const SizedBox(width: 16),

          Container(
            width: 10,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(width: 16),

          const SizedBox(width: 12),

          /// TAVOLO + COPERTI
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tavolo ${tavolo.title}",
                style: TextStyle(
                  color: textColor,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                "coperti ${ctrlTable.coverSelected}",
                style: TextStyle(
                  color: textColor.withOpacity(.75),
                  fontSize: isMobile ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Spacer(),

          /// CHIP SCONTO
          Container(
            height: isMobile ? 30 : 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              "Sconto 0,00%",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 14),

          /*
          /// GRUPPO — commentato (non attivo)
          _iconButton(
            icon: Icons.group_outlined,
            onTap: (ctx) {},
          ),
          */

          const SizedBox(width: 8),

          /// INFO
          _iconButton(
            icon: Icons.info_outline,
            onTap: (ctx) => _showInfoMenu(ctx),
          ),

        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────────────
  // INFO MENU
  // ─────────────────────────────────────────────────────────────────────────

  void _showInfoMenu(BuildContext contextBtn) {
    final RenderBox button =
        contextBtn.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(contextBtn).context.findRenderObject() as RenderBox;

    final Offset buttonPosition =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    final position = RelativeRect.fromLTRB(
      buttonPosition.dx + button.size.width - 220,
      buttonPosition.dy + button.size.height + 8,
      overlay.size.width - (buttonPosition.dx + button.size.width),
      0,
    );

    final now       = DateTime.now();
    final operatore = _getOperatoreNome();

    showMenu(
      context: contextBtn,
      position: position,
      color: const Color(0xFF1E1E1E),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: _infoRow("Utente", operatore),
        ),
        PopupMenuItem(
          enabled: false,
          child: _infoRow(
            "Aperto",
            "${_formatDate(now)}\n${_formatTime(now)}",
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getOperatoreNome() {
    if (operatorLogged == null) return "—";
    final op = operatorLogged!;
    if (op.firstname != null && op.lastname != null) {
      return "${op.firstname} ${op.lastname}";
    }
    return op.title;
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";
  }

  String _formatTime(DateTime d) {
    return "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}:"
        "${d.second.toString().padLeft(2, '0')}";
  }


  // ─────────────────────────────────────────────────────────────────────────
  // ICON BUTTON — usa Builder per ottenere il BuildContext corretto
  // ─────────────────────────────────────────────────────────────────────────

  Widget _iconButton({
    required IconData icon,
    required Function(BuildContext) onTap,
  }) {
    return Builder(
      builder: (ctx) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(ctx),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
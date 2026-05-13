import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../state/ordini_list_controller.dart';
import '../dialog/fasce_orarie_dialog.dart';

class OrdineHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const OrdineHeader({super.key});

  // 🔼 più alto come header principale
  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    final bgColor = isLight
        ? const Color(0xFF97D700) // QFOOD light
        : const Color(0xFF1A1A1A); // dark

    return Material(
      color: bgColor,
      elevation: 0, // ❌ niente shadow
      child: SizedBox(
        height: 72, // 👈 header più alto
        child: Row(
          children: [
            const SizedBox(width: 8),

            // ⬅ BACK
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              },
            ),


            //  LOGO
            Image.asset(
              isLight
                  ? 'assets/logosuverde.png'
                  : 'assets/logodark.png',
              height: 40,
            ),

            const SizedBox(width: 10),

            // TITOLO
            InkWell(
              onTap: () {
                
              },
              child: const Text(
                'Gestione ordini',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),



            const SizedBox(width: 6),

            // 🟢 OGGI
            _OggiButton(),

            const SizedBox(width: 10),

            // ◀ DATA ▶
            _DateSelector(),

            const SizedBox(width: 10),

            //REFRESH
            _HeaderIcon(
              LucideIcons.refreshCcw,
              onTap: () async {
                final ctrOrdini = context.read<OrdiniListController>();
                await ctrOrdini.getOrders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ordini aggiornati"),
                    duration: Duration(milliseconds: 800),
                  ),
                );
              },

            ),


            // 🧭 ALTRO
            _HeaderIcon(
              LucideIcons.clock,
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const FasceOrarieDialog(),
                );
              },
            ),

            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}



class _OggiButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        context.read<OrdiniListController>().vaiAOggi();
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2EE6A6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Icon(Icons.calendar_today, size: 20, color: Colors.black),
            SizedBox(width: 6),
            Text(
              'Oggi',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl   = context.watch<OrdiniListController>();
    final giorno = ctrl.giornoSelezionato;

    final label = DateFormat('EEEE d MMMM', 'it_IT').format(giorno);

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: giorno,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );

        if (picked != null) {
          ctrl.setGiorno(picked); // 🔥 QUESTO MANCAVA
        }
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: Colors.white,
              onPressed: () {
                ctrl.setGiorno(
                  giorno.subtract(const Duration(days: 1)),
                );
              },
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: Colors.white,
              onPressed: () {
                ctrl.setGiorno(
                  giorno.add(const Duration(days: 1)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon(this.icon, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: Colors.white,
      onPressed: onTap,
    );
  }
}

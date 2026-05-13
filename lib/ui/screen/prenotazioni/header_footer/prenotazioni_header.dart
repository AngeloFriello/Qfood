import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../filtri/prenotazioni_controller_filtri.dart';
import 'db_debug_utils.dart';

class PrenotazioniHeader extends StatelessWidget
  implements PreferredSizeWidget {
  const PrenotazioniHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final bgColor = isLight
        ? const Color(0xFF97D700)
        : const Color(0xFF1A1A1A);

    return Material(
      color: bgColor,
      elevation: 0,
      child: SizedBox(
        height: 72,
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

            // LOGO
            Image.asset(
              isLight
                  ? 'assets/logosuverde.png'
                  : 'assets/logodark.png',
              height: 40,
            ),

            const SizedBox(width: 10),

            // TITOLO
            const Text(
              'Gestione prenotazioni',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            //  OGGI
            _OggiButton(),

            const SizedBox(width: 10),

            // ◀ DATA ▶
            _DateSelector(),

            const SizedBox(width: 10),

            // 🔄 REFRESH
            _HeaderIcon(
              Icons.refresh,
              onTap: () {
                context.read<PrenotazioniController>().loadFromDb();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Prenotazioni aggiornate"),
                    duration: Duration(milliseconds: 800),
                  ),
                );
              },
            ),

        // 🧪 DEBUG ACTIONS
            if (kDebugMode) ...[
              const SizedBox(width: 6),

              _HeaderIcon(
                Icons.download,
                onTap: () async {
                  await DbDebugUtils.exportDb();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('DB esportato'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),

              const SizedBox(width: 6),

              _HeaderIcon(
                Icons.delete_forever,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Reset database'),
                      content: const Text(
                        'ATTENZIONE:\n\n'
                            'Tutte le prenotazioni verranno eliminate.\n'
                            'L’operazione è irreversibile.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annulla'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('RESET'),
                        ),
                      ],
                    ),
                  );

                  if (ok == true) {
                    await DbDebugUtils.resetDb();

                    if (context.mounted) {
                      context.read<PrenotazioniController>().loadFromDb();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Database resettato'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],


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
        context
            .read<PrenotazioniController>()
            .setGiorno(DateTime.now());
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
    final ctrl = context.watch<PrenotazioniController>();
    final giorno = ctrl.giorno;

    final label =
    DateFormat('EEEE d MMMM', 'it_IT').format(giorno);

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: giorno,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );

        if (picked != null) {
          ctrl.setGiorno(picked);
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
              style:
              const TextStyle(color: Colors.white, fontSize: 18),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../filtri/prenotazioni_controller_filtri.dart';
import '../../model/prenotazione_stato.dart';

class PrenotazioniFiltersBar extends StatelessWidget {
  const PrenotazioniFiltersBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PrenotazioniController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF242424)
        : const Color(0xFF6A8F00);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Spacer(),

          _pillFilter(
            context,
            label: 'Tutti i turni',
            value: ctrl.turno,
            items: const {
              'TUTTI': 'Tutti i turni',
              'MATTINO': '09:00 - 13:30',
              'SERA': '16:00 - 23:59',
            },
            onSelected: ctrl.setTurno,
          ),

          const SizedBox(width: 14),

          _pillFilter(
            context,
            label: 'Tutte le sale',
            value: ctrl.sala,
            items: const {
              'TUTTE': 'Tutte le sale',
              'TAVOLI': 'TAVOLI',
              'ESTERNO': 'ESTERNO',
              'ASPORTO': 'ASPORTO',
            },
            onSelected: ctrl.setSala,
          ),

          const SizedBox(width: 14),

          _pillFilter(
            context,
            label: 'Tutti gli stati',
            value: ctrl.statoFiltro?.label ?? 'TUTTI',
            items: {
              'TUTTI': 'Tutti gli stati',
              for (final s in PrenotazioneStato.values)
                s.name: s.label,
            },
            onSelected: (v) {
              if (v == 'TUTTI') {
                ctrl.setStato(null);
              } else {
                ctrl.setStato(
                  PrenotazioneStato.values
                      .firstWhere((e) => e.name == v),
                );
              }
            },
          ),
        ],
      ),
    );
  }


  Widget _pillFilter(
      BuildContext context, {
        required String label,
        required String value,
        required Map<String, String> items,
        required ValueChanged<String> onSelected,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openDialog(context, value, items, onSelected),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2E2E2E)
              : const Color(0xFF5E7F00),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(.15),
          ),
        ),
        child: Row(
          children: [
            Text(
              items[value] ?? label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }


  // DIALOG
  void _openDialog(
      BuildContext context,
      String value,
      Map<String, String> items,
      ValueChanged<String> onSelected,
      ) {
    String selected = value;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: items.entries.map((e) {
                return RadioListTile<String>(
                  value: e.key,
                  groupValue: selected,
                  title: Text(e.value),
                  onChanged: (v) => setState(() => selected = v!),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              onSelected(selected);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

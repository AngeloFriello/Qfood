import 'package:dashboard/ui/screen/prenotazioni/ui/prenotazioni/stato_chip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../filtri/prenotazioni_controller_filtri.dart';
import '../nuova_prenotazione_page.dart';

import 'package:intl/intl.dart';


class PrenotazioniList extends StatelessWidget {
  const PrenotazioniList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<PrenotazioniController>().filtrate;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (items.isEmpty) {
      return const Center(
        child: Text('Nessuna prenotazione'),
      );
    }

    final cardBg = isDark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFECEFF1);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final p = items[i];

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          elevation: isDark ? 2 : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              final ctrl = context.read<PrenotazioniController>();

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: ctrl,
                    child: NuovaPrenotazionePage(
                      prenotazione: p,
                    ),
                  ),
                ),
              );

            },
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Row(
                children: [
                  _fixed(
                    PrenotazioniColumns.data,
                    Text(
                      DateFormat('dd MMM yyyy').format(p.data),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                  _fixed(
                    PrenotazioniColumns.ora,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.timeRangeLabel(context),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          p.durataLabel(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        if (p.tavoli.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tavoli: ${p.tavoli.join(', ')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),


                  _fixed(
                    PrenotazioniColumns.pax,
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${p.pax}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),

                  _fixed(
                    PrenotazioniColumns.stato,
                    StatoChip(stato: p.stato),
                  ),

                  Expanded(
                    child: Text(
                      p.clienteNome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  _fixed(
                    PrenotazioniColumns.telefono,
                    Text(
                      p.telefono ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  _fixed(
                    PrenotazioniColumns.note,
                    Text(
                      (p.note != null && p.note!.trim().isNotEmpty)
                          ? p.note!
                          : '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fixed(double w, Widget child) {
    return SizedBox(width: w, child: child);
  }
}

/// ======================
/// COLONNE
/// ======================
class PrenotazioniColumns {
  static const double data = 140;
  static const double ora = 140;
  static const double pax = 80;
  static const double stato = 160;
  static const double telefono = 160;
  static const double note = 140;
}

/// ======================
/// HEADER TABELLA
/// ======================
class PrenotazioniListHeaderM3 extends StatelessWidget {
  const PrenotazioniListHeaderM3({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE3E6E8);

    final fg = isDark ? Colors.grey.shade300 : Colors.grey.shade800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _cell('Data', PrenotazioniColumns.data, fg),
            _cell('Ora', PrenotazioniColumns.ora, fg),
            _cell('Pax', PrenotazioniColumns.pax, fg),
            _cell('Stato', PrenotazioniColumns.stato, fg),

            const Expanded(
              child: Text(
                'Nome',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            _cell('Telefono', PrenotazioniColumns.telefono, fg),
            _cell('Note', PrenotazioniColumns.note, fg),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, double width, Color color) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

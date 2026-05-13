import 'package:flutter/material.dart';
import 'tavolo_card.dart';
import '../../model/model_prenotazione.dart';
import '../../model/prenotazione_stato.dart';
import 'assegna_tavolo_filters.dart';
import 'assegna_tavolo_footer.dart';
import 'assegna_tavolo_header.dart';

/// ================================
/// UI NUMBER -> BACKEND ID
/// ================================
const Map<int, int> tavoliBackendMap = {
  1: 482,
  2: 483,
};

bool isOverlap({
  required DateTime startA,
  required DateTime endA,
  required DateTime startB,
  required DateTime endB,
}) {
  return startA.isBefore(endB) && endA.isAfter(startB);
}

class AssegnaTavoloPage extends StatefulWidget {
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int pax;
  final int? prenotazioneInModificaId;

  /// ⬅️ QUI SOLO ID BACKEND (482, 483)
  final List<int> tavoliGiaSelezionati;

  final List<Prenotazione> prenotazioni;

  const AssegnaTavoloPage({
    super.key,
    required this.startDateTime,
    required this.endDateTime,
    required this.pax,
    required this.prenotazioni,
    this.prenotazioneInModificaId,
    this.tavoliGiaSelezionati = const [],
  });

  @override
  State<AssegnaTavoloPage> createState() => _AssegnaTavoloPageState();
}

class _AssegnaTavoloPageState extends State<AssegnaTavoloPage> {
  /// NUMERI MOSTRATI A SCHERMO
  final List<int> tavoliUi = tavoliBackendMap.keys.toList();

  /// ID BACKEND SELEZIONATI
  final Set<int> tavoliSelezionati = {};

  /// ID BACKEND OCCUPATI
  final Set<int> tavoliOccupati = {};

  @override
  void initState() {
    super.initState();
    tavoliSelezionati.addAll(widget.tavoliGiaSelezionati);
    _calcolaTavoliOccupati();
  }

  void _calcolaTavoliOccupati() {
    tavoliOccupati.clear();

    for (final p in widget.prenotazioni) {
      if (p.stato == PrenotazioneStato.cancellato) continue;
      if (widget.prenotazioneInModificaId != null &&
          p.id == widget.prenotazioneInModificaId) {
        continue;
      }

      final overlap = isOverlap(
        startA: widget.startDateTime,
        endA: widget.endDateTime,
        startB: p.startDateTime,
        endB: p.end,
      );

      if (overlap) {
        /// 🔥 QUI SOLO ID BACKEND
        tavoliOccupati.addAll(p.tavoli);
      }
    }
  }

  Prenotazione? _prenotazionePerTavolo(int numeroUi) {
    final backendId = tavoliBackendMap[numeroUi];
    if (backendId == null) return null;

    for (final p in widget.prenotazioni) {
      if (p.stato == PrenotazioneStato.cancellato) continue;
      if (widget.prenotazioneInModificaId != null &&
          p.id == widget.prenotazioneInModificaId) {
        continue;
      }

      final overlap = isOverlap(
        startA: widget.startDateTime,
        endA: widget.endDateTime,
        startB: p.startDateTime,
        endB: p.end,
      );

      if (overlap && p.tavoli.contains(backendId)) {
        return p;
      }
    }
    return null;
  }

  String _formatOrario(DateTime start, DateTime end) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)}'
        ' - ${two(end.hour)}:${two(end.minute)}';
  }

  void _toggleTavolo(int numeroUi) {
    final backendId = tavoliBackendMap[numeroUi];
    if (backendId == null) return;
    if (tavoliOccupati.contains(backendId)) return;

    setState(() {
      if (tavoliSelezionati.contains(backendId)) {
        tavoliSelezionati.remove(backendId);
      } else {
        tavoliSelezionati.add(backendId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF2F4EC),
      appBar: const AssegnaTavoloHeader(),
      body: Column(
        children: [
          const AssegnaTavoloFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tavoliUi.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 10,
              ),
              itemBuilder: (_, i) {
                final numeroUi = tavoliUi[i];
                final backendId = tavoliBackendMap[numeroUi]!;

                final occupante = _prenotazionePerTavolo(numeroUi);
                final selezionato =
                tavoliSelezionati.contains(backendId);

                TavoloStato stato;
                String? orario;
                int? pax;

                if (occupante != null) {
                  stato = TavoloStato.prenotato;
                  orario = _formatOrario(
                    occupante.startDateTime,
                    occupante.end,
                  );
                  pax = occupante.pax;
                } else if (selezionato) {
                  stato = TavoloStato.tua;
                  orario = _formatOrario(
                    widget.startDateTime,
                    widget.endDateTime,
                  );
                  pax = widget.pax;
                } else {
                  stato = TavoloStato.libero;
                }

                return TavoloCard(
                  numero: numeroUi,
                  stato: stato,
                  orario: orario,
                  pax: pax,
                  onAdd: stato == TavoloStato.libero
                      ? () => _toggleTavolo(numeroUi)
                      : null,
                  onRemove: stato == TavoloStato.tua
                      ? () => _toggleTavolo(numeroUi)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AssegnaTavoloFooter(
        onConfirm: () {
          /// 🔥 TORNA SOLO ID BACKEND → API FELICE
          Navigator.pop(context, tavoliSelezionati.toList());
        },
      ),
    );
  }
}

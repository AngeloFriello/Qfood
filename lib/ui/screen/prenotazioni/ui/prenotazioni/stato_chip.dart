import 'package:flutter/material.dart';
import '../../model/model_prenotazione.dart';
import '../../model/prenotazione_stato.dart';

class StatoChip extends StatelessWidget {
  final PrenotazioneStato stato;

  const StatoChip({
    super.key,
    required this.stato,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;

    switch (stato) {
      case PrenotazioneStato.confermato:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;

      case PrenotazioneStato.daConfermare:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;

      case PrenotazioneStato.cancellato:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;

      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        stato.label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

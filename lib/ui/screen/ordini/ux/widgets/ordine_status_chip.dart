import 'package:flutter/material.dart';
import '../../models/ordine_stato.dart';

class OrdineStatusChip extends StatelessWidget {
  final OrdineStato stato;

  const OrdineStatusChip({
    super.key,
    required this.stato,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(stato.label),
      avatar: Icon(
        _iconForState(stato),
        size: 16,
      ),
    );
  }

  IconData _iconForState(OrdineStato stato) {
    switch (stato) {
      case OrdineStato.nuovo:
        return Icons.fiber_new;

      case OrdineStato.inPreparazione:
        return Icons.local_dining;

      case OrdineStato.pronto:
        return Icons.check_circle_outline;

      case OrdineStato.completato:
        return Icons.done_all;


      case OrdineStato.annullato:
        return Icons.cancel;

      case OrdineStato.partito:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

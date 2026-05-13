import 'package:flutter/material.dart';

import 'package:dashboard/ui/screen/ordini/ux/widgets/ordine_status_chip.dart';

import '../../models/ordine.dart';
import '../../models/ordine_tipo.dart';



//Card ordine (lista)
class OrdineCard extends StatelessWidget {
  final Ordine ordine;
  final VoidCallback onTap;

  const OrdineCard({
    super.key,
    required this.ordine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        '#${ordine.id} – ${ordine.cliente}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        ordine.tipo.label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          OrdineStatusChip(stato: ordine.stato),
          const SizedBox(height: 4),
          Text(
            '€${0000000000000}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

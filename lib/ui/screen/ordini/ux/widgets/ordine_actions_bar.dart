import 'package:flutter/material.dart';

import '../../models/ordine.dart';



//Azioni rapide (conto, partenza, modifica…)
class OrdineActionsBar extends StatelessWidget {
  final Ordine ordine;
  final bool canEdit;

  const OrdineActionsBar({
    super.key,
    required this.ordine,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.receipt),
          label: 'Conto',
        ),
        NavigationDestination(
          icon: Icon(Icons.edit),
          label: 'Modifica',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_shipping),
          label: 'Partenza',
        ),
      ],
      onDestinationSelected: (index) {
        // TODO: gestire azioni
      },
    );
  }
}

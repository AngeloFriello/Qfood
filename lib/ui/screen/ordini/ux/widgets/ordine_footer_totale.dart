import 'package:flutter/material.dart';

//Footer editor ordine (salva + totale
class OrdineFooterTotale extends StatelessWidget {
  final double totale;
  final VoidCallback onSave;

  const OrdineFooterTotale({
    super.key,
    required this.totale,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Totale: €${totale.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}

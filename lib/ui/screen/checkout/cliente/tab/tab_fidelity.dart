import 'package:flutter/material.dart';

class TabFidelity extends StatelessWidget {
  const TabFidelity({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text("Nuova Fidelity"),
      ),
    );
  }
}

// Widget per la scheda di un prodotto
import 'package:flutter/material.dart';

class SchedaProdotto extends StatelessWidget {
  final String nome;
  final VoidCallback onTap;

  const SchedaProdotto({super.key, required this.nome, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Center(child: Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

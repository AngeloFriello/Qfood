// Widget per la scheda di un tavolo
import 'package:flutter/material.dart';

class SchedaTavolo extends StatelessWidget {
  final String nome;
  final bool occupato;
  final VoidCallback onTap;

  const SchedaTavolo({super.key, required this.nome, required this.occupato, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: occupato ? Colors.redAccent : Colors.greenAccent,
        child: Center(child: Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

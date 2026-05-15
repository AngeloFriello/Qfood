import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProdottoRigaModel {
  bool selezionato;
  String nome;
  int quantita;
  double prezzo;

  ProdottoRigaModel({
    this.selezionato = false,
    required this.nome,
    this.quantita = 1,
    required this.prezzo,
  });
}


class HeaderOrdine extends StatelessWidget {
  const HeaderOrdine();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : cs.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Prodotto',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'Q.tà',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Prezzo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



//Riga prodotto
class OrdineItemRow extends StatelessWidget {
  final String nome;
  final int quantita;
  final double prezzo;
  final VoidCallback onQuantitaTap;
  final VoidCallback onPrezzoTap;

  const OrdineItemRow({
    required this.nome,
    required this.quantita,
    required this.prezzo,
    required this.onQuantitaTap,
    required this.onPrezzoTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nome,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),

          /// QUANTITA
          SizedBox(
            width: 90,
            child: GestureDetector(
              onTap: onQuantitaTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quantita.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// PREZZO
          SizedBox(
            width: 100,
            child: GestureDetector(
              onTap: onPrezzoTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  prezzo.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//Modale numerica (Q.tà)
void openNumeroDialog(
    BuildContext context, {
      required double initial,
      required ValueChanged<double> onConfirm,
    }) {
  final controller =
  TextEditingController(text: initial.toString());

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Inserisci quantità"),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla"),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(controller.text) ?? 0;
            onConfirm(value);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}


//Modale prezzo
void openPrezzoDialog(
    BuildContext context, {
      required double initial,
      required ValueChanged<double> onConfirm,
    }) {
  final controller =
  TextEditingController(text: initial.toStringAsFixed(2));

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Inserisci prezzo totale"),
      content: TextField(
        controller: controller,
        keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla"),
        ),
        ElevatedButton(
          onPressed: () {
            final value =
                double.tryParse(controller.text) ?? 0;
            onConfirm(value);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

class OrdineTabBar extends StatelessWidget {
  final VoidCallback onAdd;

  const OrdineTabBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text("Prodotto"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF97D700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}


void openNuovoProdottoDialog(
    BuildContext context, {
      required Function(String nome, double prezzo) onConfirm,
    }) {
  final nomeCtrl = TextEditingController();
  final prezzoCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Nuovo prodotto"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nomeCtrl,
            decoration: const InputDecoration(
              labelText: "Nome prodotto",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: prezzoCtrl,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Prezzo unitario",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla"),
        ),
        ElevatedButton(
          onPressed: () {
            final nome = nomeCtrl.text.trim();
            final prezzo =
                double.tryParse(prezzoCtrl.text) ?? 0.0;

            if (nome.isNotEmpty) {
              onConfirm(nome, prezzo);
            }

            Navigator.pop(context);
          },
          child: const Text("Aggiungi"),
        ),
      ],
    ),
  );
}


class OrdineRowCompleta extends StatelessWidget {
  final bool selezionato;
  final String nome;
  final int quantita;
  final double prezzo;

  final ValueChanged<bool> onCheck;
  final VoidCallback onQuantitaTap;
  final VoidCallback onPrezzoTap;

  const OrdineRowCompleta({
    required this.selezionato,
    required this.nome,
    required this.quantita,
    required this.prezzo,
    required this.onCheck,
    required this.onQuantitaTap,
    required this.onPrezzoTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [

          /// CHECKBOX
          Checkbox(
            value: selezionato,
            onChanged: (v) => onCheck(v ?? false),
            activeColor: const Color(0xFF97D700),
          ),

          const SizedBox(width: 10),

          /// NOME
          Expanded(
            child: Text(
              nome,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),

          /// QTA
          SizedBox(
            width: 80,
            child: GestureDetector(
              onTap: onQuantitaTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quantita.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// PREZZO
          SizedBox(
            width: 100,
            child: GestureDetector(
              onTap: onPrezzoTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  prezzo.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:dashboard/varianti/state/variants_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VariantiLibereSection extends StatefulWidget {
  const VariantiLibereSection({super.key});

  @override
  State<VariantiLibereSection> createState() => _VariantiLibereSectionState();
}

class _VariantiLibereSectionState extends State<VariantiLibereSection> {
  final nomeCtrl = TextEditingController();
  final prezzoCtrl = TextEditingController();
  FocusNode focusNome = FocusNode();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<VariantsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bg = isDark
        ? Colors.grey.shade900
        : const Color(0xFFE9ECEF);
    focusNome.requestFocus();
    return Column(
      children: [
        // ======================
        // INPUT ROW
        // ======================
        Container(
          padding: const EdgeInsets.all(12),
          color: bg,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  focusNode: focusNome,
                  controller: nomeCtrl,
                  decoration: const InputDecoration(
                    hintText: "Nome",
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: prezzoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: "Prezzo",
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9DE7D6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    if( nomeCtrl.text.isEmpty  ) return;
                    prezzoCtrl.text = prezzoCtrl.text.isEmpty ? '0' : prezzoCtrl.text;
                    ctrl.addInSelectedFree(nomeCtrl.text, prezzoCtrl.text);
                    nomeCtrl.clear();
                    prezzoCtrl.clear();
                  },
                  child: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ],
          ),
        ),

        // ======================
        // LISTA
        // ======================
        Expanded(
          child: ListView.separated(
            itemCount: ctrl.variants_selected_free.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(.4)),
            itemBuilder: (_, i) {
              final v = ctrl.variants_selected_free[i];
              return ListTile(
                title: Text(
                  v.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.price!.replaceAll(".", ","),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () => {
                        ctrl.removeInSelectedFree(v)
                      }
                    ),
                  ],
                ),
              );
            },
          ),
        ),

      ],
    );
  }
}

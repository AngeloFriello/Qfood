import 'package:dashboard/modelli/customer.dart';
import 'package:flutter/material.dart';

class PopupRicercaCliente extends StatefulWidget {
  final String storeId;
  final Function(CustomerModel) onSelect;

  const PopupRicercaCliente({
    super.key,
    required this.storeId,
    required this.onSelect,
  });

  @override
  State<PopupRicercaCliente> createState() => _PopupRicercaClienteState();
}

class _PopupRicercaClienteState extends State<PopupRicercaCliente> {
  final TextEditingController searchCtrl = TextEditingController();
  List<CustomerModel> clienti = [];
  bool loading = false;
  int skip = 0;
  final int take = 100;
  int total = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (loading) return;

    setState(() => loading = true);

    if (reset) {
      skip = 0;
      clienti.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 600,
        height: 520,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "Cerca cliente",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Nome, P.IVA, CF…",
                ),
                onSubmitted: (_) => _load(reset: true),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: clienti.length + 1,
                itemBuilder: (context, index) {
                  if (index == clienti.length) {
                    if (clienti.length >= total) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _load,
                        child: loading
                            ? const CircularProgressIndicator()
                            : const Text("Carica altri"),
                      ),
                    );
                  }

                  final c = clienti[index];
                  return ListTile(
                    title: Text(/* c.displayName */ 'testCliente'),
                    subtitle: Text('testCliente'),
                    onTap: () {
                      widget.onSelect(c);
                      Navigator.pop(context);
                    },
                  );

                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Text("Mostrati ${clienti.length} di $total"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../ui/screen/sincronizzazioni/sync_vista.dart';

const Map<String, String> syncMap = {
  "Utenti": "syncOperators/1f37de1a466b",
  "Prodotti": "syncArticle/ae311ca96936",
  "Reparti prodotti": "syncDepartmentsProductions/43a4a8cde0b7",
  "Categorie prodotti": "syncCategories/b0dd9f9ec9bd",
  "Contatti": "syncProductionCenter/3556ae48fae3",
  "Common": "syncVatRate/355ba80ae161",
};


class DownloadDatiVista extends StatefulWidget {
  const DownloadDatiVista({super.key});

  @override
  State<DownloadDatiVista> createState() => _DownloadDatiVistaState();
}

class _DownloadDatiVistaState extends State<DownloadDatiVista> {
  final Map<String, bool> selezioni = {
    "Utenti": true,
    "Prodotti": true,
    "Reparti prodotti": true,
    "Categorie prodotti": true,
    "Contatti": true,
    "Common": true,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          "Sincronizza dati da Server",
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seleziona i dati da scaricare",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: selezioni.keys.map((k) {
                  final selected = selezioni[k]!;
                  return ListTile(
                    title: Text(k),
                    trailing: Switch(
                      value: selected,
                      onChanged: (v) =>
                          setState(() => selezioni[k] = v),
                    ),
                    onTap: () =>
                        setState(() => selezioni[k] = !selected),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            FilledButton.icon(
              onPressed: _onDownloadPressed,
              icon: const Icon(Icons.download),
              label: const Text("Scarica dati selezionati"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDownloadPressed() {
    final endpoints = selezioni.entries
        .where((e) => e.value)
        .map((e) => syncMap[e.key])
        .whereType<String>()
        .toList();

    if (endpoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seleziona almeno una voce"),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SyncVista(endpoints: endpoints),
      ),
    );
  }
}

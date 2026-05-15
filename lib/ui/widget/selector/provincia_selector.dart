import 'package:flutter/material.dart';

const List<Map<String, String>> province = [
  {"nome": "Agrigento", "sigla": "AG"},
  {"nome": "Alessandria", "sigla": "AL"},
  {"nome": "Ancona", "sigla": "AN"},
  {"nome": "Aosta", "sigla": "AO"},
  {"nome": "Arezzo", "sigla": "AR"},
  {"nome": "Ascoli Piceno", "sigla": "AP"},
  {"nome": "Asti", "sigla": "AT"},
  {"nome": "Avellino", "sigla": "AV"},
  {"nome": "Bari", "sigla": "BA"},
  {"nome": "Barletta-Andria-Trani", "sigla": "BT"},
  {"nome": "Belluno", "sigla": "BL"},
  {"nome": "Benevento", "sigla": "BN"},
  {"nome": "Bergamo", "sigla": "BG"},
  {"nome": "Biella", "sigla": "BI"},
  {"nome": "Bologna", "sigla": "BO"},
  {"nome": "Bolzano", "sigla": "BZ"},
  {"nome": "Brescia", "sigla": "BS"},
  {"nome": "Brindisi", "sigla": "BR"},
  {"nome": "Cagliari", "sigla": "CA"},
  {"nome": "Campobasso", "sigla": "CB"},
  {"nome": "Carbonia-Iglesias", "sigla": "CI"},
  {"nome": "Caserta", "sigla": "CE"},
  {"nome": "Catania", "sigla": "CT"},
  {"nome": "Catanzaro", "sigla": "CZ"},
  {"nome": "Chieti", "sigla": "CH"},
  {"nome": "Como", "sigla": "CO"},
  {"nome": "Cosenza", "sigla": "CS"},
  {"nome": "Cremona", "sigla": "CR"},
  {"nome": "Crotone", "sigla": "KR"},
  {"nome": "Cuneo", "sigla": "CN"},
  {"nome": "Enna", "sigla": "EN"},
  {"nome": "Fermo", "sigla": "FM"},
  {"nome": "Ferrara", "sigla": "FE"},
  {"nome": "Firenze", "sigla": "FI"},
  {"nome": "Foggia", "sigla": "FG"},
  {"nome": "Forlì-Cesena", "sigla": "FC"},
  {"nome": "Frosinone", "sigla": "FR"},
  {"nome": "Genova", "sigla": "GE"},
  {"nome": "Gorizia", "sigla": "GO"},
  {"nome": "Grosseto", "sigla": "GR"},
  {"nome": "Imperia", "sigla": "IM"},
  {"nome": "Isernia", "sigla": "IS"},
  {"nome": "La Spezia", "sigla": "SP"},
  {"nome": "L'Aquila", "sigla": "AQ"},
  {"nome": "Latina", "sigla": "LT"},
  {"nome": "Lecce", "sigla": "LE"},
  {"nome": "Lecco", "sigla": "LC"},
  {"nome": "Livorno", "sigla": "LI"},
  {"nome": "Lodi", "sigla": "LO"},
  {"nome": "Lucca", "sigla": "LU"},
  {"nome": "Macerata", "sigla": "MC"},
  {"nome": "Mantova", "sigla": "MN"},
  {"nome": "Massa-Carrara", "sigla": "MS"},
  {"nome": "Matera", "sigla": "MT"},
  {"nome": "Messina", "sigla": "ME"},
  {"nome": "Milano", "sigla": "MI"},
  {"nome": "Modena", "sigla": "MO"},
  {"nome": "Monza e Brianza", "sigla": "MB"},
  {"nome": "Napoli", "sigla": "NA"},
  {"nome": "Novara", "sigla": "NO"},
  {"nome": "Nuoro", "sigla": "NU"},
  {"nome": "Oristano", "sigla": "OR"},
  {"nome": "Padova", "sigla": "PD"},
  {"nome": "Palermo", "sigla": "PA"},
  {"nome": "Parma", "sigla": "PR"},
  {"nome": "Pavia", "sigla": "PV"},
  {"nome": "Perugia", "sigla": "PG"},
  {"nome": "Pesaro e Urbino", "sigla": "PU"},
  {"nome": "Pescara", "sigla": "PE"},
  {"nome": "Piacenza", "sigla": "PC"},
  {"nome": "Pisa", "sigla": "PI"},
  {"nome": "Pistoia", "sigla": "PT"},
  {"nome": "Pordenone", "sigla": "PN"},
  {"nome": "Potenza", "sigla": "PZ"},
  {"nome": "Prato", "sigla": "PO"},
  {"nome": "Ragusa", "sigla": "RG"},
  {"nome": "Ravenna", "sigla": "RA"},
  {"nome": "Reggio Calabria", "sigla": "RC"},
  {"nome": "Reggio Emilia", "sigla": "RE"},
  {"nome": "Rieti", "sigla": "RI"},
  {"nome": "Rimini", "sigla": "RN"},
  {"nome": "Roma", "sigla": "RM"},
  {"nome": "Rovigo", "sigla": "RO"},
  {"nome": "Salerno", "sigla": "SA"},
  {"nome": "Sassari", "sigla": "SS"},
  {"nome": "Savona", "sigla": "SV"},
  {"nome": "Siena", "sigla": "SI"},
  {"nome": "Siracusa", "sigla": "SR"},
  {"nome": "Sondrio", "sigla": "SO"},
  {"nome": "Sud Sardegna", "sigla": "SU"},
  {"nome": "Taranto", "sigla": "TA"},
  {"nome": "Teramo", "sigla": "TE"},
  {"nome": "Terni", "sigla": "TR"},
  {"nome": "Torino", "sigla": "TO"},
  {"nome": "Trapani", "sigla": "TP"},
  {"nome": "Trento", "sigla": "TN"},
  {"nome": "Treviso", "sigla": "TV"},
  {"nome": "Trieste", "sigla": "TS"},
  {"nome": "Udine", "sigla": "UD"},
  {"nome": "Varese", "sigla": "VA"},
  {"nome": "Venezia", "sigla": "VE"},
  {"nome": "Verbano-Cusio-Ossola", "sigla": "VB"},
  {"nome": "Vercelli", "sigla": "VC"},
  {"nome": "Verona", "sigla": "VR"},
  {"nome": "Vibo Valentia", "sigla": "VV"},
  {"nome": "Vicenza", "sigla": "VI"},
  {"nome": "Viterbo", "sigla": "VT"}
];

Future<void> mostraSelettoreProvincia(
    BuildContext context,
    TextEditingController controller,
    ) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _ProvinciaDialog(),
  ).then((value) {
    if (value != null && value is String) {
      controller.text = value;
    }
  });
}

// =======================================================
// DIALOG COMPLETO
// =======================================================
class _ProvinciaDialog extends StatefulWidget {
  const _ProvinciaDialog();

  @override
  State<_ProvinciaDialog> createState() => _ProvinciaDialogState();
}

class _ProvinciaDialogState extends State<_ProvinciaDialog> {
  String search = "";
  String? selezionata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = province
        .where((p) =>
        p["nome"]!.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        vertical: 64, //spazio sopra e sotto
        horizontal: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 380,
          maxHeight: 480, // ALTEZZA DEFINITIVA
        ),
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Provincia",
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Cerca provincia...",
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ================= LISTA =================
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text("Nessun risultato"))
                  : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: filtered.map((p) {
                  final nome = p["nome"]!;
                  final sigla = p["sigla"]!;

                  return RadioListTile<String>(
                    dense: true,
                    value: sigla,
                    groupValue: selezionata,
                    onChanged: (v) {
                      Navigator.pop(context, v);
                    },
                    title: Row(
                      children: [
                        Expanded(child: Text(nome)),
                        Text(
                          sigla,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                            theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),

            // ================= FOOTER =================
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ANNULLA"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

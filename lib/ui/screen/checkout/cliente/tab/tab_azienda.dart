import 'package:dashboard/Global.dart';
import 'package:dashboard/ui/widget/selector/provincia_selector.dart';
import 'package:flutter/material.dart';

class TabAzienda extends StatelessWidget {
  // =========================
  // CONTROLLERS
  // =========================
  final TextEditingController ragioneSocialeController;
  final TextEditingController vatController;
  final TextEditingController codiceFiscaleController;
  final TextEditingController indirizzoController;
  final TextEditingController capController;
  final TextEditingController cittaController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController scontoController;
  final TextEditingController provinciaController;
  final VoidCallback onSearchVat;

  const TabAzienda({
    super.key,
    required this.ragioneSocialeController,
    required this.vatController,
    required this.codiceFiscaleController,
    required this.indirizzoController,
    required this.capController,
    required this.cittaController,
    required this.telefonoController,
    required this.emailController,
    required this.scontoController,
    required this.onSearchVat,
    required this.provinciaController
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchVatCard(
            vatController: vatController,
            onSearchVat: onSearchVat,
          ),

          const SizedBox(height: 24),

          _CardAnagraficaAzienda(
            ragioneSocialeController: ragioneSocialeController,
            vatController: vatController,
            codiceFiscaleController: codiceFiscaleController,
          ),

          _CardIndirizzo(
            provinciaController: provinciaController,
            indirizzoController: indirizzoController,
            capController: capController,
            cittaController: cittaController,
          ),

          _CardContatti(
            telefonoController: telefonoController,
            emailController: emailController,
          ),

          _CardCondizioni(
            scontoController: scontoController,
          ),
        ],
      ),
    );
  }
}

// =======================================================
// 🔍 RICERCA P.IVA
// =======================================================
class _SearchVatCard extends StatelessWidget {
  final TextEditingController vatController;
  final VoidCallback onSearchVat;

  const _SearchVatCard({
    required this.vatController,
    required this.onSearchVat,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Ricerca",
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: vatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cerca P.IVA",
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSearchVat(),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: scanner QR
            },
            icon: const Icon(Icons.qr_code, color: Colors.white70),
            label: const Text("Scansiona QR Code"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// 🏢 ANAGRAFICA AZIENDA
// =======================================================
class _CardAnagraficaAzienda extends StatelessWidget {
  final TextEditingController ragioneSocialeController;
  final TextEditingController vatController;
  final TextEditingController codiceFiscaleController;

  const _CardAnagraficaAzienda({
    required this.ragioneSocialeController,
    required this.vatController,
    required this.codiceFiscaleController,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Anagrafica azienda",
      child: Column(
        children: [
          _input(
            "Ragione sociale",
            controller: ragioneSocialeController,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _input(
                  "P. IVA",
                  controller: vatController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input(
                  "Codice fiscale",
                  controller: codiceFiscaleController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================================================
// 📍 INDIRIZZO
// =======================================================
class _CardIndirizzo extends StatelessWidget {
  final TextEditingController indirizzoController;
  final TextEditingController capController;
  final TextEditingController cittaController;
  final TextEditingController provinciaController;

  const _CardIndirizzo({
    required this.indirizzoController,
    required this.capController,
    required this.cittaController,
    required this.provinciaController
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Indirizzo",
      child: Column(
        children: [
          _input(
            "Indirizzo",
            controller: indirizzoController,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _input("CAP", controller: capController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input("Città", controller: cittaController),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child:
                   inputProvincia(
                      "Provincia",
                      controller: provinciaController,
                      readOnly: true,
                      onTap: () => mostraSelettoreProvincia(context, provinciaController),
                    )
                   
                   ),
              const SizedBox(width: 12),
              Expanded(child: 
              _dropdown(
                "Stato", 
                "Italy",
                []
                )),
            ],
          ),
        ],
      ),
    );
  }
}

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

// =======================================================
// ☎️ CONTATTI
// =======================================================
class _CardContatti extends StatelessWidget {
  final TextEditingController telefonoController;
  final TextEditingController emailController;

  const _CardContatti({
    required this.telefonoController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Contatti",
      child: Row(
        children: [
          Expanded(
            child: _input("Telefono", controller: telefonoController),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _input("E-mail", controller: emailController),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// 💸 CONDIZIONI
// =======================================================
class _CardCondizioni extends StatelessWidget {
  final TextEditingController scontoController;

  const _CardCondizioni({
    required this.scontoController,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Condizioni commerciali",
      child: _input(
        "Sconto %",
        controller: scontoController,
      ),
    );
  }
}

// =======================================================
// 🔧 INPUTS
// =======================================================
Widget _input(
    String label, {
      TextEditingController? controller,
    }) {
  return TextField(
    controller: controller,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _dropdown(String label, dynamic value, List<DropdownMenuItem<dynamic>> items) {
  return DropdownButtonFormField<dynamic>(
    initialValue: value,
    items: items,
    onChanged: (_) {},
    style: const TextStyle(color: Colors.white),
    dropdownColor: Colors.grey.shade900,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

// =======================================================
// 🧱 CARD BASE
// =======================================================
class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}


Widget inputProvincia(
    String label, {
      TextEditingController? controller,
      IconData? icon,
      bool readOnly = false,
      VoidCallback? onTap,
    }) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: isDark
              ? Colors.black.withOpacity(0.25)
              : theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
    },
  );
}


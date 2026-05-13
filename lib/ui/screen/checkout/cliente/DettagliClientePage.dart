import 'package:dashboard/modelli/customer.dart';
import 'package:flutter/material.dart';

class DettagliClientePage extends StatelessWidget {
  final CustomerModel cliente;

  const DettagliClientePage({
    super.key,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompany = cliente.businessType == "company";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dettagli cliente"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================
            // NOME + TIPO
            // ======================
            Row(
              children: [
                Icon(
                  isCompany ? Icons.business : Icons.person,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (cliente.title ?? "").toUpperCase(),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CODICE CLIENTE
            if ((cliente.code ?? "").isNotEmpty)
              Text(
                "Codice cliente: ${cliente.code}",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),

            const SizedBox(height: 24),

            // ======================
            // DATI AZIENDA
            // ======================
            if (isCompany) ...[
              _sectionTitle(context, "Dati azienda"),

              if ((cliente.businessVatNumber ?? "").isNotEmpty)
                _infoRow("P.IVA", cliente.businessVatNumber),


              if ((cliente.businessAddress ?? "").isNotEmpty)
                _infoRow("Indirizzo", cliente.businessAddress),

              if ((cliente.businessZipCode ?? "").isNotEmpty ||
                  (cliente.businessCity ?? "").isNotEmpty)
                _infoRow(
                  "Località",
                  "${cliente.businessZipCode ?? ""} ${cliente.businessCity ?? ""}".trim(),
                ),

              if ((cliente.businessPhone ?? "").isNotEmpty)
                _infoRow("Telefono", cliente.businessPhone),

              if ((cliente.businessEmail ?? "").isNotEmpty)
                _infoRow("Email", cliente.businessEmail),
            ]

            // ======================
            // DATI PRIVATO
            // ======================
            else ...[
              _sectionTitle(context, "Dati personali"),

              if ((cliente.businessAddress ?? "").isNotEmpty)
                _infoRow("Indirizzo", cliente.businessAddress),

              if ((cliente.businessZipCode ?? "").isNotEmpty ||
                  (cliente.personalCity ?? "").isNotEmpty)
                _infoRow(
                  "Località",
                  "${cliente.businessZipCode ?? ""} ${cliente.businessCity ?? ""}".trim(),
                ),

              if ((cliente.businessPhone ?? "").isNotEmpty)
                _infoRow("Telefono", cliente.businessPhone),

              if ((cliente.businessEmail ?? "").isNotEmpty)
                _infoRow("Email", cliente.businessEmail),
            ],
          ],
        ),
      ),
    );
  }

  // ======================
  // WIDGET UTILI
  // ======================
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

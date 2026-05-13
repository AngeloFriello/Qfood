import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ListaVenditeModal extends StatefulWidget {
  const ListaVenditeModal({super.key});

  @override
  State<ListaVenditeModal> createState() => _ListaVenditeModalState();
}

class _ListaVenditeModalState extends State<ListaVenditeModal> {
  DateTime selectedDate = DateTime.now();
  String tipo = "Tutto";
  String dispositivo = "Tutto";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final bool isMobile = size.width < 600;
    final bool isTablet = size.width >= 600 && size.width < 1100;

    final Color headerColor =
    isDark ? const Color(0xFF1F2A1F) : const Color(0xFF97D700);

    final Color backgroundColor =
    isDark ? const Color(0xFF181818) : Colors.white;

    final Color fieldColor =
    isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : size.width * 0.18,
        vertical: isMobile ? 40 : 80,
      ),
      child: Container(
        height: isMobile
            ? size.height * 0.55
            : isTablet
            ? size.height * 0.50
            : size.height * 0.45,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [

            /// =========================
            /// HEADER
            /// =========================
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                    color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Lista vendite",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            /// =========================
            /// BODY
            /// =========================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [

                    _tile(
                      label: "Data",
                      value: _formatDate(selectedDate),
                      fieldColor: fieldColor,
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 18),

                    _tile(
                      label: "Tipo",
                      value: tipo,
                      fieldColor: fieldColor,
                      onTap: _openTipoDialog,
                    ),

                    const SizedBox(height: 18),

                    _tile(
                      label: "Dispositivo",
                      value: dispositivo,
                      fieldColor: fieldColor,
                      onTap: _openDispositivoDialog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required String label,
    required String value,
    required Color fieldColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: fieldColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronDown, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() => selectedDate = result);
    }
  }

  void _openTipoDialog() async {
    final result = await _radioDialog(
      title: "Tipo",
      options: const ["Tutto", "Scontrino", "Fattura"],
      selected: tipo,
    );

    if (result != null) {
      setState(() => tipo = result);
    }
  }

  void _openDispositivoDialog() async {
    final result = await _radioDialog(
      title: "Dispositivo",
      options: const [
        "Tutto",
        "CASSA",
        "CASSA 11",
        "CASSA 12",
        "CASSA 13",
        "CASSA POS",
        "KIOSK",
        "PALMARE",
        "SALA"
      ],
      selected: dispositivo,
    );

    if (result != null) {
      setState(() => dispositivo = result);
    }
  }

  Future<String?> _radioDialog({
    required String title,
    required List<String> options,
    required String selected,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((e) {
                return RadioListTile<String>(
                  value: e,
                  groupValue: selected,
                  title: Text(e),
                  onChanged: (val) {
                    Navigator.pop(context, val);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ANNULLA"),
            ),
          ],
        );
      },
    );
  }
}

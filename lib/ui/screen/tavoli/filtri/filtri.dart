import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:flutter/material.dart';

class FiltroStatoModal extends StatefulWidget {
  final String initialValue;

  const FiltroStatoModal({
    super.key,
    this.initialValue = "Tutti",
  });

  @override
  State<FiltroStatoModal> createState() => _FiltroStatoModalState();
}

class _FiltroStatoModalState extends State<FiltroStatoModal> {
  late String selected;

  final List<String> stati = const [
    "Tutti",
    "Occupato",
    "Attesa",
    "Fine pasto",
    "Preconto",
    "Prodotti bloccati",
    "Impegnato",
    "Libero",
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isDark = theme.brightness == Brightness.dark;

    final bool isMobile = size.width < 600;

    final Color backgroundColor =
    isDark ? const Color(0xFF1C1C1C) : Colors.white;

    final Color headerColor =
    isDark ? const Color(0xFF1F2A1F) : const Color(0xFF97D700);

    final Color textColor =
    isDark ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : size.width * 0.25,
        vertical: isMobile ? 40 : 100,
      ),
      child: Container(
        height: isMobile ? size.height * 0.65 : 520,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [

            /// HEADER
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                "Filtra stato",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            /// LISTA STATI
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: stati.length,
                  itemBuilder: (context, index) {
                    final stato = stati[index];

                    return RadioListTile<String>(
                      
                      value: stato,
                      groupValue: vistaTableKey.currentState!.filterStatusTable,
                      activeColor: const Color(0xFF97D700),
                      title: Text(
                        stato,
                        style: TextStyle(color: textColor),
                      ),
                      onChanged: (val) async {
                        if(vistaTableKey.currentState != null  && vistaTableKey.currentState!.mounted){
                          vistaTableKey.currentState!.setState(() {});
                          setState(() => vistaTableKey.currentState!.filterStatusTable = val!);
                        }
                        
                      },
                    );
                  },
                ),
              ),
            ),

            const Divider(height: 1),

            /// FOOTER BOTTONI
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "ANNULLA",
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF97D700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if(vistaTableKey.currentState != null  && vistaTableKey.currentState!.mounted){
                        vistaTableKey.currentState!.loadTable();
                      }
                      Navigator.pop(context, selected);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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

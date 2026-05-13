import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/gridProductAndCategoriesForTable.dart';
import 'package:flutter/material.dart';

class TavoloActionPanelDesktop extends StatelessWidget {
  final Function setState;
  const TavoloActionPanelDesktop({
    required this.setState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark
          ? const Color(0xFF121512)
          : const Color(0xFFE9ECE5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 26,
        ),
        child: Column(
          children:  [
            _PanelButton(label: "Inserisci",tap:() async {
              await Navigator.of(context).push( MaterialPageRoute(builder: (context) => GridProductAndCategoriesForTable( )));
              setState();
            }),
            _PanelButton(label: "Invia comanda",tap: (){}),
            _PanelButton(label: "Preconto",tap: (){}),
            _PanelButton(label: "Conto",tap: (){}),
            _PanelButton(label: "Separazione",tap: (){}),
            _PanelButton(label: "Suddivisione",tap: (){}),
          ],
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final String label;
  final Function tap;

  const _PanelButton({
    required this.label,
    required this.tap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () =>  tap(),
        child: Container(
          height: 35,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),

            /// ombra molto soft come nel mock
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F3B2F), // verde scuro testo
            ),
          ),
        ),
      ),
    );
  }
}

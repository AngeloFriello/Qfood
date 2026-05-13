import 'package:flutter/material.dart';

Future<void> showSpostamentoProdottiDialog({
  required BuildContext context,
  required String nomeProdotto,
  required int quantitaIniziale,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SpostamentoProdottiDialog(
      nomeProdotto: nomeProdotto,
      quantitaIniziale: quantitaIniziale,
    ),
  );
}

class _SpostamentoProdottiDialog extends StatefulWidget {
  final String nomeProdotto;
  final int quantitaIniziale;

  const _SpostamentoProdottiDialog({
    required this.nomeProdotto,
    required this.quantitaIniziale,
  });

  @override
  State<_SpostamentoProdottiDialog> createState() =>
      _SpostamentoProdottiDialogState();
}

class _SpostamentoProdottiDialogState
    extends State<_SpostamentoProdottiDialog> {

  late int quantita;

  @override
  void initState() {
    super.initState();
    quantita = widget.quantitaIniziale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1000;

    final double dialogWidth = isMobile
        ? width * .95
        : isTablet
        ? 600
        : 700;

    const qfoodGreen = Color(0xFF97D700);

    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: isMobile ? 420 : 480,
        child: Column(
          children: [

            /// HEADER
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: qfoodGreen,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Spostamento prodotti",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            /// BODY

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 500;

                    return Container(
                      height: 110,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Row(
                          children: [

                            /// QTY ORIGINALE
                            SizedBox(
                              width: isSmall ? 30 : 40,
                              child: Text(
                                widget.quantitaIniziale.toString(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            SizedBox(width: isSmall ? 12 : 30),

                            /// -
                            _roundPurpleButton(
                              icon: Icons.remove,
                              onTap: () {
                                if (quantita > 1) {
                                  setState(() => quantita--);
                                }
                              },
                            ),

                            SizedBox(width: isSmall ? 12 : 22),

                            /// BOX NUMERO
                            Container(
                              width: isSmall ? 65 : 80,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                quantita.toString(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            SizedBox(width: isSmall ? 12 : 22),

                            /// +
                            _roundPurpleButton(
                              icon: Icons.add,
                              onTap: () {
                                setState(() => quantita++);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),



            _buildFooter(context),

          ],


        ),



      ),


    );
  }


}


Widget _buildFooter(BuildContext context) {
  const qfoodGreen = Color(0xFF97D700);

  return Container(
    width: double.infinity,
    height: 70, // più elegante e proporzionato
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color: qfoodGreen,
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(16),
      ),
    ),
    child: Center(
      child: SizedBox(
        height: 45,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(.20),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            "Sposta",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _roundPurpleButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(30),
    child: Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        color: Color(0xFFCEFB17), // viola pieno come screenshot
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.black,
        size: 28,
      ),
    ),
  );
}

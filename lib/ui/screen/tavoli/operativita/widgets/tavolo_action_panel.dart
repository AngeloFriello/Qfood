/* import 'package:flutter/material.dart';

class TavoloActionPanel extends StatelessWidget {
  final VoidCallback? onApri;
  final VoidCallback? onImpegna;
  final VoidCallback? onCancella;
  final VoidCallback? onUnisci;
  final VoidCallback? onSepara;
  final VoidCallback? onSposta;
  final VoidCallback? onVisualizza;
  final VoidCallback? onSblocca;

  const TavoloActionPanel({
    super.key,
    this.onApri,
    this.onImpegna,
    this.onCancella,
    this.onUnisci,
    this.onSepara,
    this.onSposta,
    this.onVisualizza,
    this.onSblocca,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return const SizedBox(); // su mobile lo apriamo come bottomSheet
        }

        return _DesktopPanel(
          width: constraints.maxWidth > 1400 ? 360 : 300,
          onApri: onApri,
          onImpegna: onImpegna,
          onCancella: onCancella,
          onUnisci: onUnisci,
          onSepara: onSepara,
          onSposta: onSposta,
          onVisualizza: onVisualizza,
          onSblocca: onSblocca,
        );
      },
    );
  }
}


class _DesktopPanel extends StatelessWidget {
  final double width;

  final VoidCallback? onApri;
  final VoidCallback? onImpegna;
  final VoidCallback? onCancella;
  final VoidCallback? onUnisci;
  final VoidCallback? onSepara;
  final VoidCallback? onSposta;
  final VoidCallback? onVisualizza;
  final VoidCallback? onSblocca;

  const _DesktopPanel({
    required this.width,
    this.onApri,
    this.onImpegna,
    this.onCancella,
    this.onUnisci,
    this.onSepara,
    this.onSposta,
    this.onVisualizza,
    this.onSblocca,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: const Color(0xFF1E201B),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ActionButton(label: 'Inserisci', onTap: onApri),
          _ActionButton(label: 'Invia comanda', onTap: onImpegna),
          _ActionButton(label: 'Preconto', onTap: onCancella),
          _ActionButton(label: 'Conto', onTap: onUnisci),
          _ActionButton(label: 'Separazione', onTap: onSepara),
          _ActionButton(label: 'Suddivisione', onTap: onSposta),
        ],
      ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A2D27),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}


void openTavoloPanelMobile(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E201B),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (_) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: const _DesktopPanel(
          width: double.infinity,
        ),
      ),
    ),
  );
}
 */
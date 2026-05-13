import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// =======================================================
/// DIALOG FASCE ORARIE – QFOOD
/// =======================================================
class FasceOrarieDialog extends StatelessWidget {
  const FasceOrarieDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => FasceOrarieController(),
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: 1200,
          height: 720,
          child: Column(
            children: [
              _Header(isDark: isDark),
              const SizedBox(height: 12),
              const Expanded(child: _Table()),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================================================
/// HEADER
/// =======================================================
class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF183528)
        : const Color(0xFF8AC926);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          const Text(
            'Carichi / fasce orarie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// TABELLA
/// =======================================================
class _Table extends StatelessWidget {
  const _Table();

  static const double oraW = 120;
  static const double colW = 150;
  static const double spacing = 12;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FasceOrarieController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE5E7EB);

    return Column(
      children: [
        /// HEADER COLONNE
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 56,
          decoration: BoxDecoration(
            color: headerBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              _HeaderCell(icon: Icons.schedule, label: 'Ora', width: oraW),
              SizedBox(width: spacing),
              _HeaderCell(icon: Icons.store, label: 'Ritiro', width: colW),
              SizedBox(width: spacing),
              _HeaderCell(icon: Icons.delivery_dining, label: 'Consegna', width: colW),
              SizedBox(width: spacing),
              _HeaderCell(icon: Icons.local_drink, label: 'Birre spina', width: colW),
              SizedBox(width: spacing),
              _HeaderCell(icon: Icons.local_pizza, label: 'Forno pizza', width: colW),
              SizedBox(width: spacing),
              _HeaderCell(icon: Icons.restaurant, label: 'Cucina', width: colW),
            ],
          ),
        ),

        const SizedBox(height: 12),

        /// RIGHE
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ctrl.fasce.length,
            itemBuilder: (_, i) {
              final f = ctrl.fasce[i];

              return Container(
                height: 52,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _OraCell(f.ora.format(context), width: oraW),
                    const SizedBox(width: spacing),
                    _NumCell(attuali: f.ritiri, max: ctrl.maxOrdini, width: colW),
                    const SizedBox(width: spacing),
                    _NumCell(attuali: f.consegne, max: ctrl.maxOrdini, width: colW),
                    const SizedBox(width: spacing),
                    _NumCell(
                      attuali: f.reparti['birre spina']!,
                      max: f.maxCapacita['birre spina']!,
                      width: colW,
                    ),
                    const SizedBox(width: spacing),
                    _NumCell(
                      attuali: f.reparti['forno pizza']!,
                      max: f.maxCapacita['forno pizza']!,
                      width: colW,
                    ),
                    const SizedBox(width: spacing),
                    _NumCell(
                      attuali: f.reparti['cucina']!,
                      max: f.maxCapacita['cucina']!,
                      width: colW,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// =======================================================
/// CELLE
/// =======================================================
class _HeaderCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final double width;

  const _HeaderCell({
    required this.icon,
    required this.label,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OraCell extends StatelessWidget {
  final String value;
  final double width;
  const _OraCell(this.value, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(.25),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _NumCell extends StatelessWidget {
  final int attuali;
  final int max;
  final double width;

  const _NumCell({
    required this.attuali,
    required this.max,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool pieno = attuali >= max;

    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          "$attuali / $max",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: pieno ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }
}

/// =======================================================
/// CONTROLLER
/// =======================================================
class FasceOrarieController extends ChangeNotifier {
  final int maxOrdini = 10;

  List<FasciaOraria> get fasce {
    return List.generate(32, (i) {
      final hour = 12 + (i ~/ 4);
      final minute = (i % 4) * 15;

      return FasciaOraria(
        ora: TimeOfDay(hour: hour, minute: minute),
        ritiri: i == 2 ? 6 : 0,
        consegne: 0,
        reparti: {
          'birre spina': 12,
          'forno pizza': 6,
          'cucina': 3,
        },
        maxCapacita: {
          'birre spina': 10,
          'forno pizza': 10,
          'cucina': 8,
        },
      );
    });
  }
}

/// =======================================================
/// MODEL
/// =======================================================
class FasciaOraria {
  final TimeOfDay ora;
  final int ritiri;
  final int consegne;
  final Map<String, int> reparti;
  final Map<String, int> maxCapacita;

  FasciaOraria({
    required this.ora,
    required this.ritiri,
    required this.consegne,
    required this.reparti,
    required this.maxCapacita,
  });
}


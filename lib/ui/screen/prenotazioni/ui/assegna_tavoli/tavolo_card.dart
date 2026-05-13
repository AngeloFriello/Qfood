import 'package:flutter/material.dart';

enum TavoloStato {
  libero,
  prenotato,
  tua,
}

class TavoloCard extends StatelessWidget {
  final int numero;
  final TavoloStato stato;
  final String? orario;
  final int? pax;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const TavoloCard({
    super.key,
    required this.numero,
    required this.stato,
    this.orario,
    this.pax,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .35 : .12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _left(),
          _divider(isDark),
          Expanded(child: _center()),
          _action(),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.12),
  );

  Widget _left() {
    final badge = _badge();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.table_restaurant, size: 20),
            const SizedBox(width: 6),
            Text(
              '$numero',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _badgeView(badge),
      ],
    );
  }

  Widget _badgeView(_Badge badge) => Container(
    height: 18,
    width: 90,
    decoration: BoxDecoration(
      color: badge.bg,
      borderRadius: BorderRadius.circular(4),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: badge.dot,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          badge.label,
          style: TextStyle(
            color: badge.fg,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _center() {
    if (stato == TavoloStato.libero) return const SizedBox();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (orario != null)
          Row(
            children: [
              const Icon(Icons.access_time, size: 15),
              const SizedBox(width: 6),
              Text(orario!, style: const TextStyle(fontSize: 22)),
            ],
          ),
        if (pax != null)
          Row(
            children: [
              const Icon(Icons.person, size: 15),
              const SizedBox(width: 6),
              Text('$pax', style: const TextStyle(fontSize: 22)),
            ],
          ),
      ],
    );
  }

  Widget _action() {
    final attached = stato == TavoloStato.tua;

    return InkWell(
      onTap: attached ? onRemove : onAdd,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        child: Icon(
          attached ? Icons.remove : Icons.add,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  _Badge _badge() {
    switch (stato) {
      case TavoloStato.libero:
        return _Badge(
          bg: const Color(0xFF9FE0C3),
          fg: const Color(0xFF1B5E20),
          dot: const Color(0xFF2E7D32),
          label: 'Libero',
        );
      case TavoloStato.prenotato:
        return _Badge(
          bg: const Color(0xFFF2A1A1),
          fg: const Color(0xFF8E0000),
          dot: const Color(0xFFD32F2F),
          label: 'Prenotato',
        );
      case TavoloStato.tua:
        return _Badge(
          bg: const Color(0xFFD7B6E8),
          fg: const Color(0xFF4A148C),
          dot: const Color(0xFF6A1B9A),
          label: 'Tua',
        );
    }
  }
}

class _Badge {
  final Color bg;
  final Color fg;
  final Color dot;
  final String label;

  _Badge({
    required this.bg,
    required this.fg,
    required this.dot,
    required this.label,
  });
}

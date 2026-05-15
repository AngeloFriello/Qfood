import 'package:flutter/material.dart';

class AssegnaTavoloFilters extends StatelessWidget {
  const AssegnaTavoloFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFF6FAF00);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: bg,
      child: Row(
        children: [
          _pill(
            context,
            text: 'TAVOLI',
            onTap: () {
            },
          ),

          const SizedBox(width: 14),

          _pill(
            context,
            text: 'Tutto',
            onTap: () {
            },
          ),

          const Spacer(),

          _search(context),
        ],
      ),
    );
  }

  // ================= PILL =================
  Widget _pill(
      BuildContext context, {
        required String text,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ================= SEARCH =================
  Widget _search(BuildContext context) {
    return Container(
      height: 38,
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 20, color: Colors.grey),
          SizedBox(width: 10),
          Text(
            'Cerca tavolo',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

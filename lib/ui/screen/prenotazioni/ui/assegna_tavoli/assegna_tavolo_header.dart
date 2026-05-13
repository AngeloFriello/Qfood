import 'package:flutter/material.dart';

class AssegnaTavoloHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const AssegnaTavoloHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFF97D700),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'Modifica tavolo',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

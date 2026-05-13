import 'package:flutter/material.dart';

class TabAltro extends StatelessWidget {
  const TabAltro({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardGruppoAltro(),
          _CardNoteAltro(),
        ],
      ),
    );
  }
}

class _CardGruppoAltro extends StatelessWidget {
  const _CardGruppoAltro();

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Gruppo",
      child: _dropdown("Seleziona gruppo"),
    );
  }
}



class _CardNoteAltro extends StatelessWidget {
  const _CardNoteAltro();

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Note",
      child: TextField(
        maxLines: 4,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.25)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}





Widget _input(String label, {IconData? icon}) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return TextField(
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          labelStyle: theme.textTheme.bodySmall,
          filled: true,
          fillColor: isDark
              ? Colors.black.withOpacity(0.25)
              : theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
    },
  );
}


Widget _dropdown(String label, {String? value}) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return DropdownButtonFormField<String>(
        value: value,
        items: const [],
        onChanged: (_) {},
        style: theme.textTheme.bodyMedium,
        dropdownColor: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surface,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodySmall,
          filled: true,
          fillColor: isDark
              ? Colors.black.withOpacity(0.25)
              : theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
    },
  );
}



class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.6)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(
          color: Colors.white.withOpacity(0.06),
        )
            : null,
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

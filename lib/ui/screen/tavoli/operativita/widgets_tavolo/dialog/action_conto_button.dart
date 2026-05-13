import 'package:flutter/material.dart';

class ActionPrecontoButton extends StatelessWidget {
  final VoidCallback onTap;

  const ActionPrecontoButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long),
            SizedBox(width: 8),
            Text(
              "Preconto",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

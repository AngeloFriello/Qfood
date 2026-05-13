import 'package:flutter/material.dart';

class ActionStatusGreen extends StatelessWidget {
  final VoidCallback onTap;

  const ActionStatusGreen({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}



class ActionStatusRed extends StatelessWidget {
  final VoidCallback onTap;

  const ActionStatusRed({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}



class ActionBloccaButton extends StatelessWidget {
  final VoidCallback onTap;

  const ActionBloccaButton({
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
          color: Colors.red.withOpacity(.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Blocca",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

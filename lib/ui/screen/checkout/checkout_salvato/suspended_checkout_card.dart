import 'package:dashboard/ui/screen/checkout/checkout_salvato/suspended_checkout.dart';
import 'package:flutter/material.dart';

import '../checkout_page.dart';

class SuspendedCheckoutCard extends StatelessWidget {
  final SuspendedCheckout checkout;

  const SuspendedCheckoutCard({super.key, required this.checkout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = (checkout.payload["totale"] ?? 0).toDouble();
    final isActive = checkout.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckoutPage(
                suspendedCheckout: checkout,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= LEFT =================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOTA
                    Text(
                      checkout.note?.isNotEmpty == true
                          ? checkout.note!
                          : "Checkout salvato",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // DATA
                    Text(
                      "${checkout.createdAt.day.toString().padLeft(2, '0')}/"
                          "${checkout.createdAt.month.toString().padLeft(2, '0')}/"
                          "${checkout.createdAt.year}  "
                          "${checkout.createdAt.hour.toString().padLeft(2, '0')}:"
                          "${checkout.createdAt.minute.toString().padLeft(2, '0')}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    if (isActive) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Checkout attivo",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ================= RIGHT =================
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "€ ${total.toStringAsFixed(2)}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

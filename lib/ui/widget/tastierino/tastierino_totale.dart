import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../state/controller_carrello.dart';

class TastierinoTotale extends StatelessWidget {
  const TastierinoTotale({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carrello = context.watch<CarrelloController>();

    final euroFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '€',
      decimalDigits: 2,
    );

    return Stack(
      children: [
      //  const TastierinoConScontrino(),


        ///  TOT BAR — più alta e leggibile
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 185,                          // INGRANDITO
            color: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 25,                    // più spazio
            ),
            alignment: Alignment.centerRight,
            child: Text(
              euroFormat.format(carrello.totale),
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 28,                     // più grande
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


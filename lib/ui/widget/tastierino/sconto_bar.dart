import 'package:dashboard/Global.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/controller_carrello.dart';
import '../../screen/checkout/controller_modulo_pagamenti.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/controller_carrello.dart';


class ScontoBar extends StatefulWidget {
  const ScontoBar({super.key});

  @override
  State<ScontoBar> createState() => _ScontoBarState();
}

class _ScontoBarState extends State<ScontoBar> {

  final TextEditingController scontoCtrl = TextEditingController();
  ScontoTipo? tipoInserimento;

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 900;
    final bool isDesktop = width >= 1400;

    /// NASCONDI SU MOBILE E TABLET
    if (isMobile || isTablet) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [

          _btnSconto(
            "%",
            Icons.percent_rounded,
            ScontoTipo.percentuale,
          ),

          _btnSconto(
            "€",
            Icons.euro_rounded,
            ScontoTipo.importo,
          ),

          _btnSconto(
            "TOT",
            Icons.payments_rounded,
            ScontoTipo.totale,
          ),

        ],
      ),
    );
  }

  Widget _btnSconto(String label, IconData icon, ScontoTipo tipo) {

    final theme = Theme.of(context);
    final controllerCart = context.watch<CarrelloController>();

    if( operatorLogged != null && operatorLogged!.enableDiscount == 0 ) return Container();
    
    return SizedBox(
      width: 110,
      child: GestureDetector(
        onTap: () {
          if (controllerCart.prodotti.isNotEmpty) {
            controllerCart.resetDiscount();
            _apriPopupSconto(tipo);
          }
        },
        child: Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: controllerCart.discountType == tipo
                ? Colors.orange
                : theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --------------------------------------------------------------------
  // POPUP SCONTO
  // --------------------------------------------------------------------

  void _apriPopupSconto(ScontoTipo tipo) {

    tipoInserimento = tipo;
    scontoCtrl.clear();

    final ctrlModuloPagamento = context.read<ControllerModuloPagamenti>();

    showDialog(
      context: context,
      builder: (ctx) {

        return AlertDialog(
          title: tipo == ScontoTipo.percentuale
              ? const Text("Inserisci %")
              : tipo == ScontoTipo.totale
              ? const Text("Inserisci importo da pagare")
              : const Text("Inserisci valore sconto"),
          content: TextField(
            autofocus: true,
            controller: scontoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "0,00",
            ),
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),

            ElevatedButton(
              onPressed: () async {

                final carrello = context.read<CarrelloController>();
                bool confirm = await showConfermaDialogDiscount(context: context);
                if( !confirm ) return;
                
                carrello.applyDiscount(
                  scontoCtrl.text,
                  tipo,
                  ctrlModuloPagamento,
                  context,
                );

                Navigator.pop(ctx);

              },
              child: const Text("Applica"),
            ),

          ],
        );
      },
    );
  }
}
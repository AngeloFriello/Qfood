import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/banco_state.dart';
import '../../../state/controller_carrello.dart';
import 'chechout_footer.dart';
import 'checkout_salvato/suspended_checkout.dart';
import 'modulo_opzioni.dart';
import 'modulo_cliente.dart';
import 'modulo_pagamenti.dart';
import 'checkout_header.dart';

// 🔐 STATO GLOBALE (deve essere lo stesso usato nella HOME BANCO)

class CheckoutPage extends StatefulWidget {
  final SuspendedCheckout? suspendedCheckout;

  const CheckoutPage({
    super.key,
    this.suspendedCheckout,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}


class _CheckoutPageState extends State<CheckoutPage> {


  void _onConferma() {
    debugPrint("👉 CONFERMA PREMUTA");
    // TODO:
    // - vendita normale
    // - riscontro (nonRiscosso)
  }

  //bool get checkoutCompleto => context.watch<CarrelloController>().checkoutCompleto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carrello = context.watch<CarrelloController>();
    final ctrLook  = context.watch<ControllerLookPosInPrinder>();
    return AbsorbPointer(
      absorbing: ctrLook.inPrint,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
      
        // =================================================
        // HEADER
        // ❌ NESSUN PIN QUI
        // =================================================
        appBar: CheckoutHeader(
      
        ),
      
      
        // =================================================
        // BODY
        // =================================================
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1100;
      
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: ModuloOpzioni(),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      flex: 2,
                      child: ModuloCliente(),
                    ),
                    const SizedBox(width: 16),
                    
                    // 🔥 QUI VA IL ValueListenableBuilder
                    Expanded(
                      flex: 2,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: bancoAbilitato,
                        builder: (_, pinBancoAbilitato, __) {
                          return ModuloPagamenti(
                            ctrModuloPagamento: context.read<ControllerModuloPagamenti>(),
                            carrello: carrello,
                            pinBancoAbilitato: pinBancoAbilitato,
                          );
                        },
                      ),
                    
                    ),
                    
                  ],
                )
                : ListView(
                  children: [
                    const ModuloOpzioni(),
                    const SizedBox(height: 16),
                    const ModuloCliente(),
                    const SizedBox(height: 16),
                    
                    // 🔥 QUI VA IL ValueListenableBuilder (MOBILE)
                    ValueListenableBuilder<bool>(
                      valueListenable: bancoAbilitato,
                      builder: (_, pinBancoAbilitato, __) {
                        return ModuloPagamenti(
                          ctrModuloPagamento: context.read<ControllerModuloPagamenti>(),
                          carrello: carrello,
                          pinBancoAbilitato: pinBancoAbilitato,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      
        // =================================================
        // FOOTER
        // =================================================
        bottomNavigationBar: CheckoutFooter(
          onConferma: _onConferma,
          checkoutCompleto: false,
        ),
      
      ),
    );
  }
}

import 'dart:async';

import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/app/service/service_transaction.dart';
import 'package:dashboard/casse_automatiche/bs/bsCash.dart';
import 'package:dashboard/casse_automatiche/cashlogyTcp/protocol.dart';
import 'package:dashboard/casse_automatiche/cashmatic/http_protocol.dart';
import 'package:dashboard/casse_automatiche/settings_menu_automatic_checkout.dart';
import 'package:dashboard/casse_automatiche/vne/http_protocol.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/modelli/payment.dart';
import 'package:dashboard/printers/not_fiscal/esc_pos.dart';
import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/ui/widget/header_footer/controller_not_fiscal_in_printing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../screen/ordini/models/ordine.dart';
import '../../screen/ordini/ux/pages/ordini_page.dart';
import '../../../state/controller_carrello.dart';
import '../../screen/scontrino/scontrino_service.dart';
import '../../../state/banco_state.dart';
import '../../screen/checkout/checkout_page.dart';
import 'package:dashboard/casse_automatiche/cashlogyTcp/protocol.dart' as cashlogy;




class ControllerTastierinoAperto extends ChangeNotifier {
  bool tastierinoVisibile = true;
  
  void setTastierinoVisibile ( bool v){
    tastierinoVisibile = v;
    notifyListeners();
  }
}

enum ScontoTipo { percentuale, importo, totale }

enum TastierinoMode {
  idle, // nessun input
  quantita, // N + prodotto
  prezzo, // × + N + prodotto
  quantitaPrezzo, // N × N + prodotto
  mancia, // checkout
}

class TastierinoCompattoFisso extends StatefulWidget {
  final bool advancedEnabled;

  const TastierinoCompattoFisso({
    super.key,
    required this.advancedEnabled,
  });

  // METODO PUBBLICO
  void applicaProdotto(
    ArticleWhitPriceListModel prodotto,
    CarrelloController carrello, 
    bool genericArticleFromDepartment,
    {
      double? genericQta   = null, 
      double? genericPrice = null
    }
  ) {
    final state = (key as GlobalKey?)?.currentState;
    if (state is TastierinoCompattoFissoState) {
      state.applicaInputSuProdotto(
          prodotto, carrello, genericArticleFromDepartment,
          genericPrice: genericPrice, genericQta: genericQta);
    }
  }

  @override
  State<TastierinoCompattoFisso> createState() =>
      TastierinoCompattoFissoState();
}

class TastierinoCompattoFissoState extends State<TastierinoCompattoFisso> {
  bool get advancedEnabled => widget.advancedEnabled;
  final TextEditingController scontoCtrl = TextEditingController();


  ScontoTipo? tipoInserimento;
  String buffer = '';

  double? operando1;
  String? operatore; // 'x' per moltiplicazione

  double? bufferNumero; // numero corrente digitato
  double? quantita; // N prima di ×
  double? prezzo; // N dopo ×

  TastierinoMode mode = TastierinoMode.idle;

  double? n1; // primo numero
  double? n2; // secondo numero

  bool senzaSeparatore = false; // flag 350 → 3,50
 

  double _parseInput(String v) {
    if (v.isEmpty) return 0;

    if (senzaSeparatore) {
      return double.parse(v) / 100;
    }

    return double.parse(v.replaceAll(',', '.'));
  }

  void testPrint() {
    final ctrlLook = context.read<ControllerLookPosInPrinder>();
    final carrello = context.read<CarrelloController>();
    ctrlLook.setInPrint(true);
    ServiceReceipt.instance().printReceipt(context,
        (String number, String close) async {
      if (kDebugMode) {
        print("Scontrino stampato");
        print("Nuermo  scontrino: $number-$close");
      }
      await ScontrinoService.archiveDocumentInLocalDb(carrello, null,
          closureReceipt: close, receiptNumber: number);
      carrello.clearCart();
      ctrlLook.setInPrint(false);
    }, (String error) {
      debugPrint(error);
      SnackBarForcedClosure('Errore stampa', Colors.red);
      ctrlLook.setInPrint(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carrello = context.watch<CarrelloController>();
    final controllerNotFiscal = context.watch<ControllerNotFiscalInPrinting>();
    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;
    final crtTastierinoVisibile = context.watch<ControllerTastierinoAperto>();
    double hh () => MediaQuery.of(context).size.height;

    Widget _cashlogyRow(String label, String value, Color valueColor,
        {bool bold = false}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(isTablet ? 0 : 22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isTablet ? 300 : 360,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            /// FRECCIA MOSTRA/NASCONDI
            Container(
              height: 15,
              alignment: Alignment.center,
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
                onPressed: () => crtTastierinoVisibile.setTastierinoVisibile(!crtTastierinoVisibile.tastierinoVisibile),
                icon: Icon(
                  crtTastierinoVisibile.tastierinoVisibile
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 20,
                ),
              ),
            ),

            /// BARRA SCONTO
            _buildScontoBar(context),

            /// DISPLAY CALCOLATRICE (NUOVO)
            InkWell(
                onTap: () => crtTastierinoVisibile.setTastierinoVisibile(!crtTastierinoVisibile.tastierinoVisibile),
                child: _buildDisplayBar()),

            /// TASTIERINO NUMERICO
            AnimatedContainer(
              //color: Colors.blue,
              duration: const Duration(milliseconds: 250),
              height: crtTastierinoVisibile.tastierinoVisibile ? (isTablet ? 270 : 270) : 0,
              child: crtTastierinoVisibile.tastierinoVisibile ? _buildTastierino(context) : null,
            ),

            /// TOTALE
            Container(
              constraints: const BoxConstraints(minHeight: 70),
              color: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  /// AZIONE PRINCIPALE: C / SALVA / CS
                  Row(
                    children: [
                      ///  CASO ORDINE ATTIVO → SALVA

                      /// AZIONE PRINCIPALE: C / SALVA / CS
                      if (carrello.inOrder)
                        Row(
                          children: [
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () async {
                                  bool success = false;

                                  try {
                                    if (carrello.orderinEdit != null) {
                                      //SE IN MODIFICA MODIFICA ORDINE
                                      success =  await Ordine.updateOrderInDb(context);
                                    } else {
                                      success = await Ordine.addOrderInDb(context);
                                    }
                                  } catch (err) {
                                    debugPrint(err.toString());
                                  }finally{
                                     if( success == false ){
                                        SnackBarForcedClosure('Errore ordine', Colors.red);
                                        return;
                                      }
                                    carrello.clearCart();
                                    // naviga alla lista ordini
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (_) => const OrdiniPage()),
                                      (_) => false,
                                    );
                                    // feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          true
                                              ? "Ordine aggiornato"
                                              : "Ordine salvato",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                  }
                                 
                                  
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.onPrimary,
                                  foregroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  elevation: 2,
                                ),
                                child: Text(
                                  carrello.orderinEdit != null
                                      ? "Modifica"
                                      : "SALVA",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                  onPressed: () => carrello.clearCart(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.onPrimary,
                                    foregroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Annulla',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                            )
                          ],
                        )

                      ///  CASO NORMALE → C (+ CS)
                      else
                        Row(
                          children: [
                            /// C — SCONTRINO NORMALE
                            (operatorLogged != null &&
                                    operatorLogged!.rapidButtonCash != 1)
                                ? Container()
                                : SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        //CONTROLLO MOTIVO SCONTO
                                        if ( await  modalDiscountReason(context) ==  false) return;
                                        final ctrlLook = context
                                            .read<ControllerLookPosInPrinder>();
                                        final ctrlAutomaticCheckout =
                                            context.read<
                                                ControllerAutomaticCheckout>();
                                        final ctrlCarrello =
                                            context.read<CarrelloController>();
                                        int amount =
                                            (ctrlCarrello.totaleCarrello * 100)
                                                .toInt();
                                        int insert = 0;
                                        bool paymentCashmaticComplete = false;

                                        final modelAutomatickCeckout =
                                            ctrlAutomaticCheckout.model;
                                        bool inCancel = false;
                                        bool block = false;
                                        Function? stateBuild;

                                        if (modelAutomatickCeckout != null) {
                                          // CAShlogy tcp
                                          if (modelAutomatickCeckout ==
                                              'cashlogy_tcp') {
                                            // ── Widget helper righe info ──
                                            Widget _cashlogyInfoRow({
                                              required String label,
                                              required String value,
                                              required Color valueColor,
                                              bool bold = false,
                                            }) {
                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  Text(
                                                    value,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: valueColor,
                                                      fontWeight: bold
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }

                                            DrawerAutomacitModel? cash =
                                                ctrlAutomaticCheckout
                                                    .idSelectedDrawer;
                                            if (cash == null) return;

                                            final cashInstance =
                                                CashlogyService.getInstance(
                                              cash.params['ip_address'],
                                              int.tryParse(
                                                      cash.params['port'] ??
                                                          '') ??
                                                  0,
                                            );

                                            int pendingChangeCents = 0;
                                            int targetDispenseCents = 0;
                                            Timer? pollingTimer;
                                            StateSetter? modalSetState;

                                            int dispensedCents = 0;
                                            int undeliveredCents = 0;
                                            String? errorMessage;

                                            final Completer<bool>
                                                paymentCompleter =
                                                Completer<bool>();

                                            void refreshModal() =>
                                                modalSetState?.call(() {});

                                            void finishPayment(bool success) {
                                              if (paymentCompleter.isCompleted)
                                                return;
                                              pollingTimer?.cancel();
                                              paymentCashmaticComplete =
                                                  success;
                                              refreshModal();
                                              Future.delayed(
                                                  const Duration(seconds: 2),
                                                  () {
                                                if (context.mounted)
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                paymentCompleter
                                                    .complete(success);
                                              });
                                            }

                                            void finishPaymentNow(
                                                bool success) {
                                              if (paymentCompleter.isCompleted)
                                                return;
                                              pollingTimer?.cancel();
                                              paymentCashmaticComplete =
                                                  success;
                                              refreshModal();
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 400), () {
                                                if (context.mounted)
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                paymentCompleter
                                                    .complete(success);
                                              });
                                            }

                                            void completePayment() {
                                              pollingTimer?.cancel();
                                              final change = insert - amount;
                                              pendingChangeCents =
                                                  change > 0 ? change : 0;
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 600), () {
                                                cashInstance.stopAcceptance();
                                              });
                                            }

                                            void startPolling() {
                                              pollingTimer?.cancel();
                                              pollingTimer = Timer.periodic(
                                                  const Duration(
                                                      milliseconds: 250),
                                                  (timer) {
                                                if (!block)
                                                  cashInstance
                                                      .seeAmountAccepted();
                                                if (insert >= amount) {
                                                  timer.cancel();
                                                  completePayment();
                                                }
                                              });
                                            }

                                            // ── Callbacks ──

                                            cashInstance.onCashInserted =
                                                (int inserted) {
                                              insert = inserted;
                                              refreshModal();
                                            };

                                            cashInstance
                                                    .onStopAcceptanceComplete =
                                                (int finalAmount) {
                                              targetDispenseCents =
                                                  pendingChangeCents;
                                              if (pendingChangeCents > 0) {
                                                cashInstance.dispense(
                                                  amountCents:
                                                      pendingChangeCents,
                                                  screenAlwaysOnTop: false,
                                                  showScreen: false,
                                                  coinsOnly: false,
                                                );
                                                pendingChangeCents = 0;
                                              } else {
                                                finishPayment(true);
                                              }
                                            };

                                            cashInstance.onDispenseComplete =
                                                (int dispensed) {
                                              dispensedCents = dispensed;
                                              if (targetDispenseCents > 0 &&
                                                  dispensed <
                                                      targetDispenseCents) {
                                                undeliveredCents =
                                                    targetDispenseCents -
                                                        dispensed;
                                              }
                                              if (inCancel) {
                                                inCancel = false;
                                                finishPaymentNow(false);
                                              } else {
                                                finishPayment(true);
                                              }
                                            };

                                            cashInstance.onCancelComplete =
                                                (int refundAmount) {
                                              if (refundAmount > 0) {
                                                inCancel = true;
                                                targetDispenseCents =
                                                    refundAmount;
                                                cashInstance.dispense(
                                                    amountCents: refundAmount);
                                              } else {
                                                inCancel = false;
                                                finishPaymentNow(false);
                                              }
                                            };

                                            // Gestisce #ER:GENERIC# con erogazione parziale
                                            cashInstance.onTransactionComplete =
                                                (cashlogy.TransactionResult
                                                    result) {
                                              if (result.isPartial) {
                                                dispensedCents =
                                                    result.amountReturned;
                                                final int expectedChange =
                                                    targetDispenseCents > 0
                                                        ? targetDispenseCents
                                                        : (insert - amount)
                                                            .clamp(
                                                                0, 999999999);
                                                if (dispensedCents <
                                                    expectedChange) {
                                                  undeliveredCents =
                                                      expectedChange -
                                                          dispensedCents;
                                                }
                                                errorMessage = result.message;
                                                paymentCashmaticComplete = true;
                                                pollingTimer?.cancel();
                                                refreshModal();
                                                // Non chiude automaticamente: l'operatore deve confermare
                                              }
                                            };

                                            cashInstance.onError =
                                                (String error) {
                                              block = false;
                                              inCancel = false;
                                              errorMessage = error;
                                              refreshModal();
                                              Future.delayed(
                                                  const Duration(seconds: 4),
                                                  () {
                                                if (context.mounted)
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                if (!paymentCompleter
                                                    .isCompleted)
                                                  paymentCompleter
                                                      .complete(false);
                                              });
                                            };

                                            // ── Connetti e avvia ──
                                            bool connect =
                                                await cashInstance.connect();
                                            if (!connect) return;

                                            cashInstance.startAcceptance(
                                                screenAlwaysOnTop: false);
                                            startPolling();

                                            // ── Modal ──
                                            if (context.mounted) {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (ctx) =>
                                                    StatefulBuilder(
                                                  builder:
                                                      (ctx, setModalState) {
                                                    modalSetState =
                                                        setModalState;

                                                    final double toPay =
                                                        amount / 100;
                                                    final double inserted =
                                                        insert / 100;
                                                    final double change =
                                                        ((insert - amount) /
                                                                100)
                                                            .clamp(
                                                                0.0,
                                                                double
                                                                    .infinity);
                                                    final double dispensed =
                                                        dispensedCents / 100;
                                                    final double undelivered =
                                                        undeliveredCents / 100;
                                                    final double progress =
                                                        amount > 0
                                                            ? (insert / amount)
                                                                .clamp(0.0, 1.0)
                                                            : 0.0;
                                                    final bool done =
                                                        paymentCashmaticComplete;
                                                    final bool hasUndelivered =
                                                        undeliveredCents > 0;
                                                    final bool hasError =
                                                        errorMessage != null &&
                                                            !done;

                                                    final Color statusColor =
                                                        done
                                                            ? (hasUndelivered
                                                                ? Colors.orange
                                                                    .shade700
                                                                : Colors.green
                                                                    .shade600)
                                                            : (hasError
                                                                ? Colors.red
                                                                    .shade600
                                                                : Colors
                                                                    .blueGrey
                                                                    .shade700);

                                                    final IconData statusIcon = done
                                                        ? (hasUndelivered
                                                            ? Icons
                                                                .warning_amber_rounded
                                                            : Icons
                                                                .check_circle_rounded)
                                                        : (hasError
                                                            ? Icons
                                                                .error_rounded
                                                            : Icons
                                                                .payments_outlined);

                                                    final String statusTitle =
                                                        inCancel
                                                            ? 'Annullamento in corso...'
                                                            : done
                                                                ? (hasUndelivered
                                                                    ? 'Resto parzialmente erogato'
                                                                    : 'Pagamento completato')
                                                                : (hasError
                                                                    ? 'Errore dispositivo'
                                                                    : 'In attesa di pagamento');

                                                    return Dialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                      elevation: 8,
                                                      child: Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 420),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          color: Colors.white,
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // ── Header colorato ──
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          24,
                                                                      vertical:
                                                                          20),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: statusColor
                                                                    .withOpacity(
                                                                        0.08),
                                                                borderRadius: const BorderRadius
                                                                    .vertical(
                                                                    top: Radius
                                                                        .circular(
                                                                            20)),
                                                                border: Border(
                                                                  bottom: BorderSide(
                                                                      color: statusColor
                                                                          .withOpacity(
                                                                              0.18),
                                                                      width: 1),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: statusColor
                                                                          .withOpacity(
                                                                              0.12),
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child: Icon(
                                                                        statusIcon,
                                                                        color:
                                                                            statusColor,
                                                                        size:
                                                                            24),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          12),
                                                                  Expanded(
                                                                    child: Text(
                                                                      statusTitle,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade900,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),

                                                            // ── Body ──
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      24,
                                                                      20,
                                                                      24,
                                                                      8),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  _cashlogyInfoRow(
                                                                    label:
                                                                        'Da pagare',
                                                                    value:
                                                                        '€ ${toPay.toStringAsFixed(2)}',
                                                                    valueColor:
                                                                        Colors
                                                                            .grey
                                                                            .shade800,
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          10),

                                                                  _cashlogyInfoRow(
                                                                    label:
                                                                        'Inserito',
                                                                    value:
                                                                        '€ ${inserted.toStringAsFixed(2)}',
                                                                    valueColor: insert >=
                                                                            amount
                                                                        ? Colors
                                                                            .green
                                                                            .shade700
                                                                        : Colors
                                                                            .orange
                                                                            .shade700,
                                                                    bold: true,
                                                                  ),

                                                                  // Resto previsto (visibile durante attesa se inserito > dovuto)
                                                                  if (!done &&
                                                                      change >
                                                                          0) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            10),
                                                                    _cashlogyInfoRow(
                                                                      label:
                                                                          'Resto previsto',
                                                                      value:
                                                                          '€ ${change.toStringAsFixed(2)}',
                                                                      valueColor: Colors
                                                                          .grey
                                                                          .shade500,
                                                                    ),
                                                                  ],

                                                                  // Resto erogato (visibile a fine transazione)
                                                                  if (done &&
                                                                      dispensedCents >
                                                                          0) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            10),
                                                                    _cashlogyInfoRow(
                                                                      label:
                                                                          'Resto erogato',
                                                                      value:
                                                                          '€ ${dispensed.toStringAsFixed(2)}',
                                                                      valueColor: hasUndelivered
                                                                          ? Colors
                                                                              .orange
                                                                              .shade700
                                                                          : Colors
                                                                              .green
                                                                              .shade700,
                                                                      bold:
                                                                          true,
                                                                    ),
                                                                  ],

                                                                  // ── AVVISO RESTO NON EROGATO ──
                                                                  if (hasUndelivered) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            16),
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          14),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .orange
                                                                            .shade50,
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.orange.shade300,
                                                                            width: 1.5),
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Icon(
                                                                              Icons.warning_amber_rounded,
                                                                              color: Colors.orange.shade700,
                                                                              size: 20),
                                                                          const SizedBox(
                                                                              width: 10),
                                                                          Expanded(
                                                                            child:
                                                                                Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  'Rimborso manuale richiesto',
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.w700,
                                                                                    color: Colors.orange.shade900,
                                                                                    fontSize: 13,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 4),
                                                                                Text(
                                                                                  'La macchina non ha potuto erogare'
                                                                                  ' € ${undelivered.toStringAsFixed(2)}.'
                                                                                  ' Restituire manualmente al cliente.',
                                                                                  style: TextStyle(
                                                                                    color: Colors.orange.shade800,
                                                                                    fontSize: 13,
                                                                                    height: 1.4,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                Container(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                                                                  decoration: BoxDecoration(
                                                                                    color: Colors.orange.shade700,
                                                                                    borderRadius: BorderRadius.circular(8),
                                                                                  ),
                                                                                  child: Text(
                                                                                    '€ ${undelivered.toStringAsFixed(2)} da restituire',
                                                                                    style: const TextStyle(
                                                                                      color: Colors.white,
                                                                                      fontWeight: FontWeight.w800,
                                                                                      fontSize: 15,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],

                                                                  // ── AVVISO ERRORE ──
                                                                  if (hasError) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            16),
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          14),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .red
                                                                            .shade50,
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.red.shade300,
                                                                            width: 1.5),
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Icon(
                                                                              Icons.error_rounded,
                                                                              color: Colors.red.shade700,
                                                                              size: 20),
                                                                          const SizedBox(
                                                                              width: 10),
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              errorMessage ?? 'Errore sconosciuto',
                                                                              style: TextStyle(
                                                                                color: Colors.red.shade800,
                                                                                fontSize: 13,
                                                                                height: 1.4,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],

                                                                  const SizedBox(
                                                                      height:
                                                                          20),

                                                                  // ── Progress bar ──
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    child:
                                                                        LinearProgressIndicator(
                                                                      value: done
                                                                          ? 1.0
                                                                          : progress,
                                                                      minHeight:
                                                                          8,
                                                                      backgroundColor: Colors
                                                                          .grey
                                                                          .shade200,
                                                                      valueColor:
                                                                          AlwaysStoppedAnimation<
                                                                              Color>(
                                                                        done
                                                                            ? (hasUndelivered
                                                                                ? Colors.orange.shade600
                                                                                : Colors.green.shade600)
                                                                            : Colors.blue.shade400,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          6),
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerRight,
                                                                    child: Text(
                                                                      done
                                                                          ? 'Completato'
                                                                          : '${(progress * 100).toInt()}%',
                                                                      style:
                                                                          TextStyle(
                                                                        color: done
                                                                            ? statusColor
                                                                            : Colors.grey.shade500,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  const SizedBox(
                                                                      height:
                                                                          20),

                                                                  // ── Bottone principale ──
                                                                  SizedBox(
                                                                    width: double
                                                                        .infinity,
                                                                    child: done
                                                                        ? ElevatedButton
                                                                            .icon(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(ctx).pop();
                                                                              if (!paymentCompleter.isCompleted) {
                                                                                paymentCompleter.complete(true);
                                                                              }
                                                                            },
                                                                            icon:
                                                                                const Icon(Icons.check_rounded),
                                                                            label:
                                                                                Text(
                                                                              hasUndelivered ? 'Ho restituito il resto manualmente' : 'Chiudi',
                                                                            ),
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: hasUndelivered ? Colors.orange.shade700 : Colors.green.shade600,
                                                                              foregroundColor: Colors.white,
                                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                                            ),
                                                                          )
                                                                        : OutlinedButton
                                                                            .icon(
                                                                            onPressed: inCancel
                                                                                ? null
                                                                                : () {
                                                                                    pollingTimer?.cancel();
                                                                                    inCancel = true;
                                                                                    refreshModal();
                                                                                    cashInstance.cancel();
                                                                                  },
                                                                            icon:
                                                                                const Icon(Icons.cancel_outlined, color: Colors.red),
                                                                            label:
                                                                                const Text('Annulla pagamento', style: TextStyle(color: Colors.red)),
                                                                            style:
                                                                                OutlinedButton.styleFrom(
                                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                                              side: const BorderSide(color: Colors.red),
                                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                            ),
                                                                          ),
                                                                  ),

                                                                  // Spinner annullamento
                                                                  if (inCancel) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            12),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              14,
                                                                          height:
                                                                              14,
                                                                          child:
                                                                              CircularProgressIndicator(
                                                                            strokeWidth:
                                                                                2,
                                                                            color:
                                                                                Colors.orange.shade700,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                8),
                                                                        Text(
                                                                          'Rimborso in corso...',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.orange.shade700,
                                                                            fontSize:
                                                                                13,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],

                                                                  const SizedBox(
                                                                      height:
                                                                          16),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }

                                            await paymentCompleter.future;
                                          }

                                          //BS VNE
                                          if (modelAutomatickCeckout == 'vne') {
                                            final ctrBs = context.read<BSCASHCONTROLLER>();
                                            DrawerAutomacitModel? drawer = ctrlAutomaticCheckout.idSelectedDrawer;
                                            if( drawer  != null || drawer!.params['machine_ip'] != null ){
                                              final result = await showVnePaymentDialog(
                                                context,
                                                amountEuro:  amount / 100,
                                                ipMacchina:  drawer.params['machine_ip'],
                                              );

                                              if (result.success) {
                                                paymentCashmaticComplete = result.success;
                                                if (result.changeNotDispensed > 0) {
                                                  // avvisa operatore: resto manuale
                                                }
                                              }
                                            }
                                            
                                          }

                                          //BS CASH
                                          if (modelAutomatickCeckout == 'bs_cash') {
                                            final ctrBs = context.read<BSCASHCONTROLLER>();
                                            String? in__ = ctrlAutomaticCheckout.idSelectedDrawer!.params['input_folder'];
                                            String? out__ = ctrlAutomaticCheckout.idSelectedDrawer!.params['output_folder'];
                                            if ([in__, out__].contains(null) ||[in__, out__].contains('')) return;
                                            await ctrBs.login(in__!, out__!);

                                            final payload = {
                                              "type": "receipt",
                                              "identifier":
                                                  "DOC-${DateTime.now().millisecondsSinceEpoch}",
                                              "amount": ctrBs.service
                                                  .formatAmount(amount / 100),
                                              "date": DateTime.now()
                                                  .toIso8601String(),
                                              "cashRegister": "POS-01",
                                              "operator": "Admin",
                                              "payments": [
                                                {
                                                  "type": "cash",
                                                  "amount": ctrBs.service
                                                      .formatAmount(
                                                          amount / 100)
                                                },
                                              ],
                                            };
                                            showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                      content: Container(
                                                        width: 300,
                                                        height: 300,
                                                        child: Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                  'Pagamento in corso...'),
                                                              SizedBox(
                                                                height: 20,
                                                              ),
                                                              ElevatedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    ctrBs
                                                                        .cancelCurrentTransaction();
                                                                  },
                                                                  child: Text(
                                                                      'Annulla'))
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ));

                                            bool result = await ctrBs
                                                .runCommand(BSCommand.CHRG,
                                                    data: payload);
                                            if (Navigator.of(context).canPop())
                                              Navigator.of(context).pop();
                                            if (result) {
                                              paymentCashmaticComplete = true;
                                              SnackBarForcedClosure(
                                                  'Pagamento riuscito',
                                                  Colors.green);
                                            }
                                          }

                                          //CASHMATIC
                                          if (modelAutomatickCeckout ==
                                              'cashmatic') {
                                            Cashmatic cashmatic =
                                                await Cashmatic.instance(
                                                    ctrlAutomaticCheckout
                                                            .endpoint ??
                                                        '',
                                                    20);
                                            bool auth =
                                                await cashmatic.authenticate(
                                                    ctrlAutomaticCheckout
                                                            .username ??
                                                        '',
                                                    ctrlAutomaticCheckout
                                                            .password ??
                                                        '');
                                            if (auth == false) {
                                              SnackBarForcedClosure(
                                                  'Errore autenticazione Cashmartic. Controllare username e password',
                                                  Colors.red);
                                              return;
                                            }

                                            cashmatic.launchOperationAndWait(
                                                payload: {"amount": amount},
                                                launchAndListenAsync: true,
                                                CashMaticOperation
                                                    .newTransaction, (data) {
                                              debugPrint(data.toString());
                                              if (stateBuild == null) return;
                                              stateBuild!(() {
                                                insert = data!['data']
                                                    ['inserted'] as int;
                                              });
                                            }).then((finaldata) {
                                              if (finaldata == null) {
                                                SnackBarForcedClosure(
                                                    'Chiusura improvvisa Cashmatic',
                                                    Colors.red);
                                                Navigator.of(context).pop();
                                                return;
                                              }

                                              if (finaldata != null &&
                                                  finaldata['data'] != null) {
                                                if (finaldata['data']
                                                        ['requested'] <=
                                                    finaldata['data']
                                                        ['inserted']) {
                                                  if (stateBuild == null)
                                                    return;
                                                  stateBuild!(() {
                                                    block = true;
                                                  });
                                                  SnackBarForcedClosure(
                                                      'Pagamento riuscito',
                                                      Colors.green);
                                                  paymentCashmaticComplete =
                                                      true;
                                                  Navigator.of(context).pop();
                                                }
                                              }
                                              debugPrint(finaldata.toString());
                                            });

                                            await showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder: (context, setState) {
                                                    stateBuild = setState;

                                                    return AlertDialog(
                                                      content: Container(
                                                        height: 400,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: block
                                                              ? []
                                                              : inCancel
                                                                  ? [
                                                                      Center(
                                                                        child: Text(
                                                                            'Rimborso in corso...'),
                                                                      )
                                                                    ]
                                                                  : [
                                                                      Text(
                                                                          'Totale:   ${ctrlCarrello.totaleCarrello}'),
                                                                      Text(
                                                                          'Inserito: ${insert / 100}'),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          ElevatedButton(
                                                                              onPressed: () async {
                                                                                if (inCancel || paymentCashmaticComplete) return;
                                                                                setState(() {
                                                                                  inCancel = true;
                                                                                });
                                                                                dynamic resp = await cashmatic.launchOperationAndWait(CashMaticOperation.cancelTransaction, (data) {
                                                                                  debugPrint(data.toString());
                                                                                });

                                                                                if (resp != null) {
                                                                                  SnackBarForcedClosure('Pagamento annullato', Color.fromARGB(255, 255, 180, 18));
                                                                                  Navigator.of(context).pop();
                                                                                }
                                                                              },
                                                                              child: Text("Annulla transazione"))
                                                                        ],
                                                                      )
                                                                    ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          }
                                        }

                                        if (modelAutomatickCeckout != null && paymentCashmaticComplete == false) return;

                                        ctrlLook.setInPrint(true);

                                        ServiceReceipt.instance().printReceipt(
                                            context, (String number,String close) async {
                                          if (kDebugMode) {
                                            print("Scontrino stampato");
                                            print(
                                                "Numero  scontrino: $number-$close");
                                          }
                                          await ScontrinoService.archiveDocumentInLocalDb( carrello, null, closureReceipt: close, receiptNumber: number, notCleanCart: operatorLogged?.printDefaultCommandFromBench == 1);

                                          if( operatorLogged?.printDefaultCommandFromBench == 1 ){
                                            final ctrTab = context.read<ControllerTableOpened>();
                                                Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment(true, carrello.prodotti);
                                                for (final entry in pp.entries) {
                                                  final key = entry.key;
                                                  final list = entry.value;

                                                  await EscPos().printOrderToDepartment(
                                                    key.split(':')[0],
                                                    int.parse(key.split(':')[1]),
                                                    operatorLogged!,
                                                    deviceCurrent['title'],
                                                    null,
                                                    list,
                                                    ctrTab.numberCoverSelected,
                                                    null,
                                                    null,
                                                  );
                                                }
                                          };
                                          carrello.clearCart();
                                          ctrlLook.setInPrint(false);
                                        }, (String error) {
                                          debugPrint(error);
                                          SnackBarForcedClosure( 'Errore stampa', Colors.red );
                                          ctrlLook.setInPrint(false);
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.onPrimary,
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                        "C",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                            /// CS — SOLO SE BANCO ATTIVO
                            ValueListenableBuilder<bool>(
                              valueListenable: bancoAbilitato,
                              builder: (_, isBancoAttivo, __) {
                                if (!isBancoAttivo) {
                                  return const SizedBox.shrink();
                                }

                                return Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 44,
                                      child: ElevatedButton(
                                        onLongPress: () async {
                                          ModalConfirm(context,
                                              titolo: 'Archivia senza stampa?',
                                              messaggio: '',
                                              confermaLabel: 'Archivia',
                                              colorePrimario:
                                                  const Color(0xFF95C01F),
                                              onConferma: () async {
                                            try {
                                              ///LONGPRESS SALVA IL DOCUMENTO E CHIUDE SENZA STAMPARE
                                              //RECUPERO IL PAGAMENTO CASH
                                              final PaymentModel? paymentsCash =  await PaymentModel.getCashPayment();
                                              if (paymentsCash == null) return;

                                              //CONTROLLO MOTIVO SCONTO
                                              if ( await  modalDiscountReason(context) ==  false) return;    
                                              //APPLICO AI PAGAMENTI CARRELLO IL PAGAMENTO IN CONTANTI IN QUESTO CASO UNICO
                                              carrello.addPayment(Payment(
                                                  title: paymentsCash.title,
                                                  tend: paymentsCash.tend ?? 1,
                                                  idPayment: paymentsCash.id,
                                                  amount:
                                                      carrello.totaleCarrello -
                                                          carrello.discount));
                                              //STAMPA A REPARTO
                                              if( operatorLogged?.printDefaultCommandFromBench == 1 ){
                                                final ctrTab = context.read<ControllerTableOpened>();
                                                    Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment(true, carrello.prodotti);
                                                    for (final entry in pp.entries) {
                                                      final key  = entry.key;
                                                      final list = entry.value;

                                                     EscPos().printOrderToDepartment(
                                                        key.split(':')[0],
                                                        int.parse(key.split(':')[1]),
                                                        operatorLogged!,
                                                        deviceCurrent['title'],
                                                        null,
                                                        list,
                                                        ctrTab.numberCoverSelected,
                                                        null,
                                                        null
                                                      );
                                                    }
                                              };
                                              //SE STAMPATO PROCEDO ALL'INVIO AL DB
                                              Map<String, double>
                                                  summaryTipologies = carrello
                                                      .getAmountSplitTypeProduct();
                                              await TurnoLavoro
                                                  .addDocumentToShift(
                                                tipoDocumento: 'simulation',
                                                totaleDocumento:
                                                    carrello.totaleCarrello,
                                                contanti:
                                                    carrello.totaleCarrello,
                                                sconto: carrello.discount,
                                                amountBeverage: carrello
                                                        .getAmountSplitTypeProduct()[
                                                    'beverage'] as double,
                                                amountAltro: carrello
                                                        .getAmountSplitTypeProduct()[
                                                    'altro'] as double,
                                                amountFood: carrello
                                                        .getAmountSplitTypeProduct()[
                                                    'food'] as double,
                                              );

                                              await ScontrinoService
                                                  .archiveDocumentInLocalDb(
                                                      carrello, 'simulation');
                                           
                                            } catch (err) {
                                              debugPrint(err.toString());
                                            }
                                          });
                                        },
                                        onPressed: () async {
                                          //SE IN USO LA STAMPANTE FISCALE BLOCCO IL CLICK DEL TASTO IN CASO CONTRARIO BLOCCO EVENTUALI CLICK
                                          if (controllerNotFiscal.inPrintig_) return;
                                          //CONTROLLO MOTIVO SCONTO
                                          if ( await  modalDiscountReason(context) ==  false) return; 
                                          
                                          controllerNotFiscal.setInPrinting(true);

                                          //RECUPERO IL PAGAMENTO CASH
                                          final PaymentModel? paymentsCash = await PaymentModel.getCashPayment();
                                          if (paymentsCash == null) return;

                                          //APPLICO AI PAGAMENTI CARRELLO IL PAGAMENTO IN CONTANTI IN QUESTO CASO UNICO
                                          carrello.addPayment(Payment(
                                              title: paymentsCash.title,
                                              tend: paymentsCash.tend ?? 1,
                                              idPayment: paymentsCash.id,
                                              amount: carrello.totaleCarrello -
                                                  carrello.discount));

                                          bool printed = await printNotFiscalEscPos(context,null);
                                          //STAMPA A REPARTO
                                          if( operatorLogged?.printDefaultCommandFromBench == 1 ){
                                            final ctrTab = context.read<ControllerTableOpened>();
                                                Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment(true, carrello.prodotti);
                                                for (final entry in pp.entries) {
                                                  final key = entry.key;
                                                  final list = entry.value;

                                                  await EscPos().printOrderToDepartment(
                                                    key.split(':')[0],
                                                    int.parse(key.split(':')[1]),
                                                    operatorLogged!,
                                                    deviceCurrent['title'],
                                                    null,
                                                    list,
                                                    ctrTab.numberCoverSelected,
                                                    null,
                                                    null
                                                  );
                                                }
                                          };
                                          Timer(
                                              Duration(seconds: 1),
                                              () => controllerNotFiscal
                                                  .setInPrinting(false));

                                          //SE STAMPATO PROCEDO ALL'INVIO AL DB
                                          if (printed) {
                                            //await  ScontrinoService.sendPrint( carrello, 'simulation' );
                                            ScontrinoService
                                                .archiveDocumentInLocalDb(
                                                    carrello, 'simulation');
                                          } else {
                                            carrello.setPayments([]);
                                            //NEL CASO LA STAMPA NON VA A BUON FINE SVUOTO I PAGAMENTI
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          elevation: 2,
                                        ),
                                        child: controllerNotFiscal.inPrintig_
                                            ? Icon(LucideIcons.loader)
                                            : Text(
                                                "CS",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  /// 🔢 TOTALE — INALTERATO
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutPage(),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            carrello.discountType == null
                                ? Container()
                                : Text(
                                    "${(carrello.totaleCarrello).toStringAsFixed(2).replaceAll('.', ',')} €",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            Text(
                              "${(carrello.totaleCarrello - carrello.discount).toStringAsFixed(2).replaceAll('.', ',')} €",
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // SCONTO BAR
  // --------------------------------------------------------------------
  Widget _buildScontoBar(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;
    final isMobile = width < 600;

    // Nascondi su mobile e tablet
    if (isTablet || isMobile) {
      return const SizedBox.shrink();
    }

    if (operatorLogged != null && operatorLogged!.enableDiscount == 0) return Container();

    return Container(
      height: 55,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children:
         [
          _btnSconto("%", Icons.percent_rounded, ScontoTipo.percentuale),
          _btnSconto("€", Icons.euro_rounded, ScontoTipo.importo),
          _btnSconto("TOT", Icons.payments_rounded, ScontoTipo.totale),
        ],
      ),
    );
  }

  Widget _btnSconto(String label, IconData icon, ScontoTipo tipo) {
    final theme = Theme.of(context);
    final controllerCart = context.read<CarrelloController>();

    return Expanded(
      child: GestureDetector(
        onTap: () => {
          if (controllerCart.prodotti.isNotEmpty)
            {
              controllerCart.resetDiscount(),
              _apriPopupSconto(tipo, context),
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
  void _apriPopupSconto(ScontoTipo tipo, BuildContext content) {
    tipoInserimento = tipo;
    scontoCtrl.clear();
    final ctrlModuloPagamento = context.read<ControllerModuloPagamenti>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: tipo == ScontoTipo.percentuale
              ? const Text("Inserisci % ")
              : tipo == ScontoTipo.totale
                  ? const Text("Inserisci importo da pagare")
                  : const Text("Inserisci valore sconto"),
          content: Container(
            width: 500,
            height: 500,
            child: Column(
              children: [
                Container(
                  width: 500,
                  child: TextField(
                    autofocus: true,
                    controller: scontoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "0,00",
                    ),
                  ),
                ),
                Flexible(
                  child: TastierinoNumericoGenerico(
                    controller: scontoCtrl
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () async {
                /* bool confirm = await showConfermaDialogDiscount(context: context);
                if( !confirm ) return;
                 */
                final carrello = context.read<CarrelloController>();
                // CONTROLLO SCONTO MASSIMO ABILITATO PER L'operatore loggato
                bool discountOk = OperatoreModel.checkDiscountMaximim(
                    carrello.totaleCarrello,
                    tipo,
                    scontoCtrl.text,
                    operatorLogged!.maximumDiscount);
                if (discountOk == false) return;
                carrello.applyDiscount(
                    scontoCtrl.text, tipo, ctrlModuloPagamento, context);
                Navigator.pop(ctx);
              },
              child: const Text("Applica"),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------
  // TASTIERINO NUMERICO CON PULSANTE “C”
  // --------------------------------------------------------------------
  Widget _buildTastierino(BuildContext context) {
    final carrello = context.read<CarrelloController>();
    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;

    final List<String> tasti = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '0',
      '00',
      'C',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      child: Column(
        children: [
          // ============================
          // GRID NUMERICA
          // ============================
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasti.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: isTablet ? 4 : 3,
                crossAxisSpacing: isTablet ? 5 : 3,
                childAspectRatio: isTablet ? 3.4 : 2.4,
              ),
              itemBuilder: (context, index) {
                final t = tasti[index];
                return ElevatedButton(
                  onPressed: () {
                    if (t == 'C') {
                      _resetTastierino();
                      scontoCtrl.clear();
                      return;
                    }

                    _onNumero(t);

                    // SOLO PER SCONTI
                    if (tipoInserimento != null) {
                      final valore = _calcolaRisultatoLive();
                      scontoCtrl.text =
                          valore.toStringAsFixed(2).replaceAll('.', ',');
                      //_applySconto(valore, carrello);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 3,
          ),
          // ============================
          // ,  /  CLEAR
          // ============================
          Row(
            children: [
              // CLEAR TOTALE — A SINISTRA
              Expanded(
                child: ElevatedButton(
                  onPressed: _onMoltiplica,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // , — A DESTRA
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final last = buffer.split('×').last;
                    if (!last.contains(',')) {
                      buffer += ',';
                      scontoCtrl.text = buffer;
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    ',',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // ============================
          // ✖  /  ⬅
          // ============================
          Row(
            children: [
              // ✖ MOLTIPLICAZIONE (X SOPRA)

              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _resetTastierino();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_sweep,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // ⬅ BACKSPACE (X SOTTO VERDE)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (buffer.isEmpty) return;

                    buffer = buffer.substring(0, buffer.length - 1);
                    buffer = buffer.trimRight();

                    final risultato = _calcolaRisultatoLive();
                    scontoCtrl.text = buffer.isEmpty
                        ? ''
                        : risultato.toStringAsFixed(2).replaceAll('.', ',');

                    if (tipoInserimento != null && buffer.isNotEmpty) {
                      //_applySconto(risultato, carrello);
                    }

                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC540),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back, size: 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calcolaRisultatoLive() {
    if (!buffer.contains('×')) {
      return double.tryParse(buffer.replaceAll(',', '.')) ?? 0;
    }

    final parts = buffer.split('×');
    double result = 1;

    for (final p in parts) {
      final v = double.tryParse(p.trim().replaceAll(',', '.'));
      if (v == null) return 0;
      result *= v;
    }

    return result;
  }

  Widget _buildDisplayBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;

    final bgColor = isDark ? const Color(0xFF1F2A1F) : const Color(0xFFDCECC6);

    final textColor =
        isDark ? const Color(0xFFB7E08A) : const Color(0xFF1E2E1E);

    return Container(
      height: isTablet ? 32 : 42,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              buffer.isEmpty
                  ? '0'
                  : buffer.trimRight().endsWith('×')
                      ? buffer
                          .trimRight()
                          .substring(0, buffer.trimRight().length - 1)
                          .trimRight()
                      : buffer,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: isTablet ? 18 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //TASTO NUMERO SU TASTIERINO POS
  void _onNumero(String t) {
    // ============================
    // REGOLA SE X é il primo valore
    // ============================
    if (buffer.isNotEmpty && buffer[0] == 'x') {
      operatore = null;
      buffer += t;
      n1 = null;
      mode = TastierinoMode.quantita;
      setState(() {});
      return;
    }

    // ============================
    // REGOLA 1 — PRIMO NUMERO (quantità)
    // ============================
    if (mode == TastierinoMode.idle) {
      operatore = null;
      buffer = t;
      n1 = _parseInput(buffer);
      mode = TastierinoMode.quantita;
      setState(() {});
      return;
    }

    // ============================
    // REGOLA 1 — continua quantità
    // ============================
    if (mode == TastierinoMode.quantita) {
      buffer += t;
      n1 = _parseInput(buffer);
      setState(() {});
      return;
    }

    // REGOLA 2 — × + N (prezzo unitario)
    // ============================
    if (mode == TastierinoMode.prezzo && operatore == 'x' && n1 == null) {
      buffer += t; // SOLO NUMERO
      n1 = _parseInput(buffer); // n1 = PREZZO UNITARIO
      setState(() {});
      return;
    }

    // ============================
    // REGOLA 3 — N × N
    // ============================
    if (mode == TastierinoMode.prezzo && n1 != null) {
      final parts = buffer.split('×');
      final current = parts.length > 1 ? parts.last.trim() : '';

      final nuovo = current + t;
      n2 = _parseInput(nuovo);

      buffer = '${n1!.toInt()} × $nuovo';
      mode = TastierinoMode.quantitaPrezzo;

      setState(() {});
      return;
    }

    // ============================
    // REGOLA 3 — continua prezzo
    // ============================
    if (mode == TastierinoMode.quantitaPrezzo) {
      final parts = buffer.split('×');
      final current = parts.last.trim();

      final nuovo = current + t;
      n2 = _parseInput(nuovo);

      buffer = '${n1!.toInt()} × $nuovo';

      setState(() {});
      return;
    }
  }

  //TASTO X SU TASTIERINO POS
  void _onMoltiplica() {
    //Controllo se è gia presente X
    if (buffer.isNotEmpty && buffer.contains('x')) return;

    // CASO: × premuto da idle → prezzo diretto
    if (mode == TastierinoMode.idle) {
      operatore = 'x';
      mode = TastierinoMode.prezzo;
      buffer = 'x'; // ️ NESSUN NUMERO
      n1 = null;
      setState(() {});
      return;
    }

    // CASO: N × (quantità × prezzo)
    if (mode == TastierinoMode.quantita && n1 != null) {
      operatore = 'x';
      mode = TastierinoMode.prezzo;
      buffer = '${n1!.toInt()} ×';
      setState(() {});
      return;
    }
  }

  void _resetTastierino() {
    buffer = '';
    n1 = null;
    n2 = null;
    operatore = null;
    mode = TastierinoMode.idle;
    setState(() {});
  }

  //AGGIUNTA A CARRELLO DEL PRODOTTO IN BASE AGLI INPUT DEL TASTIERINO
  void applicaInputSuProdotto(
      ArticleWhitPriceListModel p,
      CarrelloController carrello, 
      bool genericArticleFromDepartment,
      {
        double? genericQta = null, 
        double? genericPrice = null
      }) {
    try {
      //CONTROLLO QTA PASSATA SOLO DALL'articolo GENERICO
      if (![genericQta, genericPrice].contains(null)) {
        carrello.addArticleInCart( p, genericQta!, genericPrice, genericArticleFromDepartment);
        return;
      }

      //CONTROLLO IL BUFFER e x è il primo valore cambio prezzo
      if (buffer.isNotEmpty && buffer[0] == 'x') {
        double newPriceUnit =
            double.parse(buffer.substring(1).replaceAll(',', '.'));
        carrello.addArticleInCart(
            p, n1 ?? 1, newPriceUnit, genericArticleFromDepartment);
        return;
      }

      //AGGIUNGO qta x prezzo
      if (n1 != null && n2 != null) {
        carrello.addArticleInCart(p, n1 ?? 1, n2, genericArticleFromDepartment);
        return;
      }

      //AGGIUNGO CON QUANTITA SELEZIONATA
      if (n1 != null) {
        carrello.addArticleInCart(
            p, n1 ?? 1, null, genericArticleFromDepartment);
        return;
      }

      //Aggiunta base del prodotto
      carrello.addArticleInCart(p, 1, null, genericArticleFromDepartment);
    } catch (err) {
      debugPrint(err.toString());
    } finally {
      _resetTastierino();
    }
  }
}


/* import 'dart:async';

import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/app/service/service_transaction.dart';
import 'package:dashboard/casse_automatiche/bs/bsCash.dart';
import 'package:dashboard/casse_automatiche/cashlogyTcp/protocol.dart';
import 'package:dashboard/casse_automatiche/cashmatic/http_protocol.dart';
import 'package:dashboard/casse_automatiche/settings_menu_automatic_checkout.dart';
import 'package:dashboard/casse_automatiche/vne/http_protocol.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/modelli/payment.dart';
import 'package:dashboard/printers/not_fiscal/esc_pos.dart';
import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/ui/widget/header_footer/controller_not_fiscal_in_printing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../screen/ordini/models/ordine.dart';
import '../../screen/ordini/ux/pages/ordini_page.dart';
import '../../../state/controller_carrello.dart';
import '../../screen/scontrino/scontrino_service.dart';
import '../../../state/banco_state.dart';
import '../../screen/checkout/checkout_page.dart';
import 'package:dashboard/casse_automatiche/bs/bsCash.dart';
import 'package:dashboard/casse_automatiche/cashlogyTcp/protocol.dart'
    as cashlogy;

enum ScontoTipo { percentuale, importo, totale }

enum TastierinoMode {
  idle, // nessun input
  quantita, // N + prodotto
  prezzo, // × + N + prodotto
  quantitaPrezzo, // N × N + prodotto
  mancia, // checkout
}

class TastierinoCompattoFisso extends StatefulWidget {
  final bool advancedEnabled;

  const TastierinoCompattoFisso({
    super.key,
    required this.advancedEnabled,
  });

  // METODO PUBBLICO
  void applicaProdotto(ArticleWhitPriceListModel prodotto,
      CarrelloController carrello, bool genericArticleFromDepartment,
      {double? genericQta = null, double? genericPrice = null}) {
    final state = (key as GlobalKey?)?.currentState;
    if (state is TastierinoCompattoFissoState) {
      state.applicaInputSuProdotto(
          prodotto, carrello, genericArticleFromDepartment,
          genericPrice: genericPrice, genericQta: genericQta);
    }
  }

  @override
  State<TastierinoCompattoFisso> createState() =>
      TastierinoCompattoFissoState();
}

class TastierinoCompattoFissoState extends State<TastierinoCompattoFisso> {
  bool get advancedEnabled => widget.advancedEnabled;
  final TextEditingController scontoCtrl = TextEditingController();
  bool tastierinoVisibile = true;

  ScontoTipo? tipoInserimento;
  String buffer = '';

  double? operando1;
  String? operatore; // 'x' per moltiplicazione

  double? bufferNumero; // numero corrente digitato
  double? quantita; // N prima di ×
  double? prezzo; // N dopo ×

  TastierinoMode mode = TastierinoMode.idle;

  double? n1; // primo numero
  double? n2; // secondo numero

  bool senzaSeparatore = false; // flag 350 → 3,50

  double _parseInput(String v) {
    if (v.isEmpty) return 0;

    if (senzaSeparatore) {
      return double.parse(v) / 100;
    }

    return double.parse(v.replaceAll(',', '.'));
  }

  void testPrint() {
    final ctrlLook = context.read<ControllerLookPosInPrinder>();
    final carrello = context.read<CarrelloController>();
    ctrlLook.setInPrint(true);
    ServiceReceipt.instance().printReceipt(context,
        (String number, String close) async {
      if (kDebugMode) {
        print("Scontrino stampato");
        print("Nuermo  scontrino: $number-$close");
      }
      await ScontrinoService.archiveDocumentInLocalDb(carrello, null,
          closureReceipt: close, receiptNumber: number);
      carrello.clearCart();
      ctrlLook.setInPrint(false);
    }, (String error) {
      debugPrint(error);
      SnackBarForcedClosure('Errore stampa', Colors.red);
      ctrlLook.setInPrint(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carrello = context.watch<CarrelloController>();
    final controllerNotFiscal = context.watch<ControllerNotFiscalInPrinting>();
    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;

    Widget _cashlogyRow(String label, String value, Color valueColor,
        {bool bold = false}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(isTablet ? 0 : 22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isTablet ? 300 : 360,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// FRECCIA MOSTRA/NASCONDI
            Container(
              height: 15,
              alignment: Alignment.center,
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
                onPressed: () =>
                    setState(() => tastierinoVisibile = !tastierinoVisibile),
                icon: Icon(
                  tastierinoVisibile
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 20,
                ),
              ),
            ),

            /// BARRA SCONTO
            _buildScontoBar(context),

            /// DISPLAY CALCOLATRICE (NUOVO)
            InkWell(
                onTap: () =>
                    setState(() => tastierinoVisibile = !tastierinoVisibile),
                child: _buildDisplayBar()),

            /// TASTIERINO NUMERICO
            AnimatedContainer(
              //color: Colors.blue,
              duration: const Duration(milliseconds: 250),
              height: tastierinoVisibile ? (isTablet ? 270 : 270) : 0,
              child: tastierinoVisibile ? _buildTastierino(context) : null,
            ),

            /// TOTALE
            Container(
              constraints: const BoxConstraints(minHeight: 70),
              color: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  /// AZIONE PRINCIPALE: C / SALVA / CS
                  Row(
                    children: [
                      ///  CASO ORDINE ATTIVO → SALVA

                      /// AZIONE PRINCIPALE: C / SALVA / CS
                      if (carrello.inOrder)
                        Row(
                          children: [
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    if (carrello.orderinEdit != null) {
                                      //SE IN MODIFICA MODIFICA ORDINE
                                      await Ordine.updateOrderInDb(context);
                                    } else {
                                      await Ordine.addOrderInDb(context);
                                    }
                                  } catch (err) {
                                    debugPrint(err.toString());
                                  }
                                  carrello.clearCart();
                                  // naviga alla lista ordini
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) => const OrdiniPage()),
                                    (_) => false,
                                  );
                                  // feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        true
                                            ? "Ordine aggiornato"
                                            : "Ordine salvato",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.onPrimary,
                                  foregroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  elevation: 2,
                                ),
                                child: Text(
                                  carrello.orderinEdit != null
                                      ? "Modifica"
                                      : "SALVA",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                  onPressed: () => carrello.clearCart(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.onPrimary,
                                    foregroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Annulla',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                            )
                          ],
                        )

                      ///  CASO NORMALE → C (+ CS)
                      else
                        Row(
                          children: [
                            /// C — SCONTRINO NORMALE
                            (operatorLogged != null &&
                                    operatorLogged!.rapidButtonCash != 1)
                                ? Container()
                                : SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final ctrlLook = context
                                            .read<ControllerLookPosInPrinder>();
                                        final ctrlAutomaticCheckout =
                                            context.read<
                                                ControllerAutomaticCheckout>();
                                        final ctrlCarrello =
                                            context.read<CarrelloController>();
                                        int amount =
                                            (ctrlCarrello.totaleCarrello * 100)
                                                .toInt();
                                        int insert = 0;
                                        bool paymentCashmaticComplete = false;

                                        final modelAutomatickCeckout =
                                            ctrlAutomaticCheckout.model;
                                        bool inCancel = false;
                                        bool block = false;
                                        Function? stateBuild;

                                        if (modelAutomatickCeckout != null) {
                                          // CAShlogy tcp
                                          if (modelAutomatickCeckout ==
                                              'cashlogy_tcp') {
                                            // ── Widget helper righe info ──
                                            Widget _cashlogyInfoRow({
                                              required String label,
                                              required String value,
                                              required Color valueColor,
                                              bool bold = false,
                                            }) {
                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  Text(
                                                    value,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: valueColor,
                                                      fontWeight: bold
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }

                                            DrawerAutomacitModel? cash =
                                                ctrlAutomaticCheckout
                                                    .idSelectedDrawer;
                                            if (cash == null) return;

                                            final cashInstance =
                                                CashlogyService.getInstance(
                                              cash.params['ip_address'],
                                              int.tryParse(
                                                      cash.params['port'] ??
                                                          '') ??
                                                  0,
                                            );

                                            int pendingChangeCents = 0;
                                            int targetDispenseCents = 0;
                                            Timer? pollingTimer;
                                            StateSetter? modalSetState;

                                            int dispensedCents = 0;
                                            int undeliveredCents = 0;
                                            String? errorMessage;

                                            final Completer<bool>
                                                paymentCompleter =
                                                Completer<bool>();

                                            void refreshModal() =>
                                                modalSetState?.call(() {});

                                            void finishPayment(bool success) {
                                              if (paymentCompleter.isCompleted)
                                                return;
                                              pollingTimer?.cancel();
                                              paymentCashmaticComplete =
                                                  success;
                                              refreshModal();
                                              Future.delayed(
                                                  const Duration(seconds: 2),
                                                  () {
                                                if (context.mounted)
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                paymentCompleter
                                                    .complete(success);
                                              });
                                            }

                                            void finishPaymentNow(
                                                bool success) {
                                              if (paymentCompleter.isCompleted)
                                                return;
                                              pollingTimer?.cancel();
                                              paymentCashmaticComplete =
                                                  success;
                                              refreshModal();
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 400), () {
                                                if (context.mounted)
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                paymentCompleter
                                                    .complete(success);
                                              });
                                            }

                                            void completePayment() {
                                              pollingTimer?.cancel();
                                              final change = insert - amount;
                                              pendingChangeCents =
                                                  change > 0 ? change : 0;
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 600), () {
                                                cashInstance.stopAcceptance();
                                              });
                                            }

                                            void startPolling() {
                                              pollingTimer?.cancel();
                                              pollingTimer = Timer.periodic(
                                                  const Duration(
                                                      milliseconds: 250),
                                                  (timer) {
                                                if (!block)
                                                  cashInstance
                                                      .seeAmountAccepted();
                                                if (insert >= amount) {
                                                  timer.cancel();
                                                  completePayment();
                                                }
                                              });
                                            }

                                            // ── Callbacks ──

                                            cashInstance.onCashInserted =
                                                (int inserted) {
                                              insert = inserted;
                                              refreshModal();
                                            };

                                            cashInstance
                                                    .onStopAcceptanceComplete =
                                                (int finalAmount) {
                                              targetDispenseCents =
                                                  pendingChangeCents;
                                              if (pendingChangeCents > 0) {
                                                cashInstance.dispense(
                                                  amountCents:
                                                      pendingChangeCents,
                                                  screenAlwaysOnTop: false,
                                                  showScreen: false,
                                                  coinsOnly: false,
                                                );
                                                pendingChangeCents = 0;
                                              } else {
                                                finishPayment(true);
                                              }
                                            };

                                            cashInstance.onDispenseComplete =
                                                (int dispensed) {
                                              dispensedCents = dispensed;
                                              if (targetDispenseCents > 0 &&
                                                  dispensed <
                                                      targetDispenseCents) {
                                                undeliveredCents =
                                                    targetDispenseCents -
                                                        dispensed;
                                              }
                                              if (inCancel) {
                                                inCancel = false;
                                                finishPaymentNow(false);
                                              } else {
                                                finishPayment(true);
                                              }
                                            };

                                            cashInstance.onCancelComplete =
                                                (int refundAmount) {
                                              if (refundAmount > 0) {
                                                inCancel = true;
                                                targetDispenseCents =
                                                    refundAmount;
                                                cashInstance.dispense(
                                                    amountCents: refundAmount);
                                              } else {
                                                inCancel = false;
                                                finishPaymentNow(false);
                                              }
                                            };

                                            // Gestisce #ER:GENERIC# con erogazione parziale
                                            cashInstance.onTransactionComplete =
                                                (cashlogy.TransactionResult
                                                    result) {
                                              if (result.isPartial) {
                                                dispensedCents =
                                                    result.amountReturned;
                                                final int expectedChange =
                                                    targetDispenseCents > 0
                                                        ? targetDispenseCents
                                                        : (insert - amount)
                                                            .clamp(
                                                                0, 999999999);
                                                if (dispensedCents <
                                                    expectedChange) {
                                                  undeliveredCents =
                                                      expectedChange -
                                                          dispensedCents;
                                                }
                                                errorMessage = result.message;
                                                paymentCashmaticComplete = true;
                                                pollingTimer?.cancel();
                                                refreshModal();
                                                // Non chiude automaticamente: l'operatore deve confermare
                                              }
                                            };

                                            cashInstance.onError =
                                                (String error) {
                                              block = false;
                                              inCancel = false;
                                              errorMessage = error;
                                              refreshModal();
                                              Future.delayed(
                                                  const Duration(seconds: 4),
                                                  () {
                                                if (context.mounted)
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                if (!paymentCompleter
                                                    .isCompleted)
                                                  paymentCompleter
                                                      .complete(false);
                                              });
                                            };

                                            // ── Connetti e avvia ──
                                            bool connect =
                                                await cashInstance.connect();
                                            if (!connect) return;

                                            cashInstance.startAcceptance(
                                                screenAlwaysOnTop: false);
                                            startPolling();

                                            // ── Modal ──
                                            if (context.mounted) {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (ctx) =>
                                                    StatefulBuilder(
                                                  builder:
                                                      (ctx, setModalState) {
                                                    modalSetState =
                                                        setModalState;

                                                    final double toPay =
                                                        amount / 100;
                                                    final double inserted =
                                                        insert / 100;
                                                    final double change =
                                                        ((insert - amount) /
                                                                100)
                                                            .clamp(
                                                                0.0,
                                                                double
                                                                    .infinity);
                                                    final double dispensed =
                                                        dispensedCents / 100;
                                                    final double undelivered =
                                                        undeliveredCents / 100;
                                                    final double progress =
                                                        amount > 0
                                                            ? (insert / amount)
                                                                .clamp(0.0, 1.0)
                                                            : 0.0;
                                                    final bool done =
                                                        paymentCashmaticComplete;
                                                    final bool hasUndelivered =
                                                        undeliveredCents > 0;
                                                    final bool hasError =
                                                        errorMessage != null &&
                                                            !done;

                                                    final Color statusColor =
                                                        done
                                                            ? (hasUndelivered
                                                                ? Colors.orange
                                                                    .shade700
                                                                : Colors.green
                                                                    .shade600)
                                                            : (hasError
                                                                ? Colors.red
                                                                    .shade600
                                                                : Colors
                                                                    .blueGrey
                                                                    .shade700);

                                                    final IconData statusIcon = done
                                                        ? (hasUndelivered
                                                            ? Icons
                                                                .warning_amber_rounded
                                                            : Icons
                                                                .check_circle_rounded)
                                                        : (hasError
                                                            ? Icons
                                                                .error_rounded
                                                            : Icons
                                                                .payments_outlined);

                                                    final String statusTitle =
                                                        inCancel
                                                            ? 'Annullamento in corso...'
                                                            : done
                                                                ? (hasUndelivered
                                                                    ? 'Resto parzialmente erogato'
                                                                    : 'Pagamento completato')
                                                                : (hasError
                                                                    ? 'Errore dispositivo'
                                                                    : 'In attesa di pagamento');

                                                    return Dialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                      elevation: 8,
                                                      child: Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 420),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          color: Colors.white,
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // ── Header colorato ──
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          24,
                                                                      vertical:
                                                                          20),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: statusColor
                                                                    .withOpacity(
                                                                        0.08),
                                                                borderRadius: const BorderRadius
                                                                    .vertical(
                                                                    top: Radius
                                                                        .circular(
                                                                            20)),
                                                                border: Border(
                                                                  bottom: BorderSide(
                                                                      color: statusColor
                                                                          .withOpacity(
                                                                              0.18),
                                                                      width: 1),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: statusColor
                                                                          .withOpacity(
                                                                              0.12),
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child: Icon(
                                                                        statusIcon,
                                                                        color:
                                                                            statusColor,
                                                                        size:
                                                                            24),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          12),
                                                                  Expanded(
                                                                    child: Text(
                                                                      statusTitle,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade900,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),

                                                            // ── Body ──
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      24,
                                                                      20,
                                                                      24,
                                                                      8),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  _cashlogyInfoRow(
                                                                    label:
                                                                        'Da pagare',
                                                                    value:
                                                                        '€ ${toPay.toStringAsFixed(2)}',
                                                                    valueColor:
                                                                        Colors
                                                                            .grey
                                                                            .shade800,
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          10),

                                                                  _cashlogyInfoRow(
                                                                    label:
                                                                        'Inserito',
                                                                    value:
                                                                        '€ ${inserted.toStringAsFixed(2)}',
                                                                    valueColor: insert >=
                                                                            amount
                                                                        ? Colors
                                                                            .green
                                                                            .shade700
                                                                        : Colors
                                                                            .orange
                                                                            .shade700,
                                                                    bold: true,
                                                                  ),

                                                                  // Resto previsto (visibile durante attesa se inserito > dovuto)
                                                                  if (!done &&
                                                                      change >
                                                                          0) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            10),
                                                                    _cashlogyInfoRow(
                                                                      label:
                                                                          'Resto previsto',
                                                                      value:
                                                                          '€ ${change.toStringAsFixed(2)}',
                                                                      valueColor: Colors
                                                                          .grey
                                                                          .shade500,
                                                                    ),
                                                                  ],

                                                                  // Resto erogato (visibile a fine transazione)
                                                                  if (done &&
                                                                      dispensedCents >
                                                                          0) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            10),
                                                                    _cashlogyInfoRow(
                                                                      label:
                                                                          'Resto erogato',
                                                                      value:
                                                                          '€ ${dispensed.toStringAsFixed(2)}',
                                                                      valueColor: hasUndelivered
                                                                          ? Colors
                                                                              .orange
                                                                              .shade700
                                                                          : Colors
                                                                              .green
                                                                              .shade700,
                                                                      bold:
                                                                          true,
                                                                    ),
                                                                  ],

                                                                  // ── AVVISO RESTO NON EROGATO ──
                                                                  if (hasUndelivered) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            16),
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          14),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .orange
                                                                            .shade50,
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.orange.shade300,
                                                                            width: 1.5),
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Icon(
                                                                              Icons.warning_amber_rounded,
                                                                              color: Colors.orange.shade700,
                                                                              size: 20),
                                                                          const SizedBox(
                                                                              width: 10),
                                                                          Expanded(
                                                                            child:
                                                                                Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  'Rimborso manuale richiesto',
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.w700,
                                                                                    color: Colors.orange.shade900,
                                                                                    fontSize: 13,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 4),
                                                                                Text(
                                                                                  'La macchina non ha potuto erogare'
                                                                                  ' € ${undelivered.toStringAsFixed(2)}.'
                                                                                  ' Restituire manualmente al cliente.',
                                                                                  style: TextStyle(
                                                                                    color: Colors.orange.shade800,
                                                                                    fontSize: 13,
                                                                                    height: 1.4,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                Container(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                                                                  decoration: BoxDecoration(
                                                                                    color: Colors.orange.shade700,
                                                                                    borderRadius: BorderRadius.circular(8),
                                                                                  ),
                                                                                  child: Text(
                                                                                    '€ ${undelivered.toStringAsFixed(2)} da restituire',
                                                                                    style: const TextStyle(
                                                                                      color: Colors.white,
                                                                                      fontWeight: FontWeight.w800,
                                                                                      fontSize: 15,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],

                                                                  // ── AVVISO ERRORE ──
                                                                  if (hasError) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            16),
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          14),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .red
                                                                            .shade50,
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.red.shade300,
                                                                            width: 1.5),
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Icon(
                                                                              Icons.error_rounded,
                                                                              color: Colors.red.shade700,
                                                                              size: 20),
                                                                          const SizedBox(
                                                                              width: 10),
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              errorMessage ?? 'Errore sconosciuto',
                                                                              style: TextStyle(
                                                                                color: Colors.red.shade800,
                                                                                fontSize: 13,
                                                                                height: 1.4,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],

                                                                  const SizedBox(
                                                                      height:
                                                                          20),

                                                                  // ── Progress bar ──
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    child:
                                                                        LinearProgressIndicator(
                                                                      value: done
                                                                          ? 1.0
                                                                          : progress,
                                                                      minHeight:
                                                                          8,
                                                                      backgroundColor: Colors
                                                                          .grey
                                                                          .shade200,
                                                                      valueColor:
                                                                          AlwaysStoppedAnimation<
                                                                              Color>(
                                                                        done
                                                                            ? (hasUndelivered
                                                                                ? Colors.orange.shade600
                                                                                : Colors.green.shade600)
                                                                            : Colors.blue.shade400,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          6),
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerRight,
                                                                    child: Text(
                                                                      done
                                                                          ? 'Completato'
                                                                          : '${(progress * 100).toInt()}%',
                                                                      style:
                                                                          TextStyle(
                                                                        color: done
                                                                            ? statusColor
                                                                            : Colors.grey.shade500,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  const SizedBox(
                                                                      height:
                                                                          20),

                                                                  // ── Bottone principale ──
                                                                  SizedBox(
                                                                    width: double
                                                                        .infinity,
                                                                    child: done
                                                                        ? ElevatedButton
                                                                            .icon(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(ctx).pop();
                                                                              if (!paymentCompleter.isCompleted) {
                                                                                paymentCompleter.complete(true);
                                                                              }
                                                                            },
                                                                            icon:
                                                                                const Icon(Icons.check_rounded),
                                                                            label:
                                                                                Text(
                                                                              hasUndelivered ? 'Ho restituito il resto manualmente' : 'Chiudi',
                                                                            ),
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: hasUndelivered ? Colors.orange.shade700 : Colors.green.shade600,
                                                                              foregroundColor: Colors.white,
                                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                                            ),
                                                                          )
                                                                        : OutlinedButton
                                                                            .icon(
                                                                            onPressed: inCancel
                                                                                ? null
                                                                                : () {
                                                                                    pollingTimer?.cancel();
                                                                                    inCancel = true;
                                                                                    refreshModal();
                                                                                    cashInstance.cancel();
                                                                                  },
                                                                            icon:
                                                                                const Icon(Icons.cancel_outlined, color: Colors.red),
                                                                            label:
                                                                                const Text('Annulla pagamento', style: TextStyle(color: Colors.red)),
                                                                            style:
                                                                                OutlinedButton.styleFrom(
                                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                                              side: const BorderSide(color: Colors.red),
                                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                            ),
                                                                          ),
                                                                  ),

                                                                  // Spinner annullamento
                                                                  if (inCancel) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            12),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              14,
                                                                          height:
                                                                              14,
                                                                          child:
                                                                              CircularProgressIndicator(
                                                                            strokeWidth:
                                                                                2,
                                                                            color:
                                                                                Colors.orange.shade700,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                8),
                                                                        Text(
                                                                          'Rimborso in corso...',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.orange.shade700,
                                                                            fontSize:
                                                                                13,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],

                                                                  const SizedBox(
                                                                      height:
                                                                          16),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }

                                            await paymentCompleter.future;
                                          }

                                          //BS VNE
                                          if (modelAutomatickCeckout == 'vne') {
                                            final ctrBs = context.read<BSCASHCONTROLLER>();
                                            DrawerAutomacitModel? drawer = ctrlAutomaticCheckout.idSelectedDrawer;
                                            if( drawer  != null || drawer!.params['machine_ip'] != null ){
                                              final result = await showVnePaymentDialog(
                                                context,
                                                amountEuro:  amount / 100,
                                                ipMacchina:  drawer.params['machine_ip'],
                                              );

                                              if (result.success) {
                                                paymentCashmaticComplete = result.success;
                                                if (result.changeNotDispensed > 0) {
                                                  // avvisa operatore: resto manuale
                                                }
                                              }
                                            }
                                            
                                          }

                                          //BS CASH
                                          if (modelAutomatickCeckout == 'bs_cash') {
                                            final ctrBs = context.read<BSCASHCONTROLLER>();
                                            String? in__ = ctrlAutomaticCheckout.idSelectedDrawer!.params['input_folder'];
                                            String? out__ = ctrlAutomaticCheckout.idSelectedDrawer!.params['output_folder'];
                                            if ([in__, out__].contains(null) ||[in__, out__].contains('')) return;
                                            await ctrBs.login(in__!, out__!);

                                            final payload = {
                                              "type": "receipt",
                                              "identifier":
                                                  "DOC-${DateTime.now().millisecondsSinceEpoch}",
                                              "amount": ctrBs.service
                                                  .formatAmount(amount / 100),
                                              "date": DateTime.now()
                                                  .toIso8601String(),
                                              "cashRegister": "POS-01",
                                              "operator": "Admin",
                                              "payments": [
                                                {
                                                  "type": "cash",
                                                  "amount": ctrBs.service
                                                      .formatAmount(
                                                          amount / 100)
                                                },
                                              ],
                                            };
                                            showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                      content: Container(
                                                        width: 300,
                                                        height: 300,
                                                        child: Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                  'Pagamento in corso...'),
                                                              SizedBox(
                                                                height: 20,
                                                              ),
                                                              ElevatedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    ctrBs
                                                                        .cancelCurrentTransaction();
                                                                  },
                                                                  child: Text(
                                                                      'Annulla'))
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ));

                                            bool result = await ctrBs
                                                .runCommand(BSCommand.CHRG,
                                                    data: payload);
                                            if (Navigator.of(context).canPop())
                                              Navigator.of(context).pop();
                                            if (result) {
                                              paymentCashmaticComplete = true;
                                              SnackBarForcedClosure(
                                                  'Pagamento riuscito',
                                                  Colors.green);
                                            }
                                          }

                                          //CASHMATIC
                                          if (modelAutomatickCeckout ==
                                              'cashmatic') {
                                            Cashmatic cashmatic =
                                                await Cashmatic.instance(
                                                    ctrlAutomaticCheckout
                                                            .endpoint ??
                                                        '',
                                                    20);
                                            bool auth =
                                                await cashmatic.authenticate(
                                                    ctrlAutomaticCheckout
                                                            .username ??
                                                        '',
                                                    ctrlAutomaticCheckout
                                                            .password ??
                                                        '');
                                            if (auth == false) {
                                              SnackBarForcedClosure(
                                                  'Errore autenticazione Cashmartic. Controllare username e password',
                                                  Colors.red);
                                              return;
                                            }

                                            cashmatic.launchOperationAndWait(
                                                payload: {"amount": amount},
                                                launchAndListenAsync: true,
                                                CashMaticOperation
                                                    .newTransaction, (data) {
                                              debugPrint(data.toString());
                                              if (stateBuild == null) return;
                                              stateBuild!(() {
                                                insert = data!['data']
                                                    ['inserted'] as int;
                                              });
                                            }).then((finaldata) {
                                              if (finaldata == null) {
                                                SnackBarForcedClosure(
                                                    'Chiusura improvvisa Cashmatic',
                                                    Colors.red);
                                                Navigator.of(context).pop();
                                                return;
                                              }

                                              if (finaldata != null &&
                                                  finaldata['data'] != null) {
                                                if (finaldata['data']
                                                        ['requested'] <=
                                                    finaldata['data']
                                                        ['inserted']) {
                                                  if (stateBuild == null)
                                                    return;
                                                  stateBuild!(() {
                                                    block = true;
                                                  });
                                                  SnackBarForcedClosure(
                                                      'Pagamento riuscito',
                                                      Colors.green);
                                                  paymentCashmaticComplete =
                                                      true;
                                                  Navigator.of(context).pop();
                                                }
                                              }
                                              debugPrint(finaldata.toString());
                                            });

                                            await showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder: (context, setState) {
                                                    stateBuild = setState;

                                                    return AlertDialog(
                                                      content: Container(
                                                        height: 400,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: block
                                                              ? []
                                                              : inCancel
                                                                  ? [
                                                                      Center(
                                                                        child: Text(
                                                                            'Rimborso in corso...'),
                                                                      )
                                                                    ]
                                                                  : [
                                                                      Text(
                                                                          'Totale:   ${ctrlCarrello.totaleCarrello}'),
                                                                      Text(
                                                                          'Inserito: ${insert / 100}'),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          ElevatedButton(
                                                                              onPressed: () async {
                                                                                if (inCancel || paymentCashmaticComplete) return;
                                                                                setState(() {
                                                                                  inCancel = true;
                                                                                });
                                                                                dynamic resp = await cashmatic.launchOperationAndWait(CashMaticOperation.cancelTransaction, (data) {
                                                                                  debugPrint(data.toString());
                                                                                });

                                                                                if (resp != null) {
                                                                                  SnackBarForcedClosure('Pagamento annullato', Color.fromARGB(255, 255, 180, 18));
                                                                                  Navigator.of(context).pop();
                                                                                }
                                                                              },
                                                                              child: Text("Annulla transazione"))
                                                                        ],
                                                                      )
                                                                    ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          }
                                        }

                                        if (modelAutomatickCeckout != null && paymentCashmaticComplete == false) return;

                                        ctrlLook.setInPrint(true);

                                        ServiceReceipt.instance().printReceipt(
                                            context, (String number,String close) async {
                                          if (kDebugMode) {
                                            print("Scontrino stampato");
                                            print(
                                                "Numero  scontrino: $number-$close");
                                          }
                                          await ScontrinoService.archiveDocumentInLocalDb( carrello, null, closureReceipt: close, receiptNumber: number);

                                          if( operatorLogged?.printDefaultCommandFromBench == 1 ){
                                            final ctrTab = context.read<ControllerTableOpened>();
                                                Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment(true, carrello.prodotti);
                                                for (final entry in pp.entries) {
                                                  final key = entry.key;
                                                  final list = entry.value;

                                                  await EscPos().printOrderToDepartment(
                                                    key.split(':')[0],
                                                    int.parse(key.split(':')[1]),
                                                    operatorLogged!,
                                                    deviceCurrent['title'],
                                                    null,
                                                    list,
                                                    ctrTab.numberCoverSelected,
                                                    null,
                                                  );
                                                }
                                          };
                                          carrello.clearCart();
                                          ctrlLook.setInPrint(false);
                                        }, (String error) {
                                          debugPrint(error);
                                          SnackBarForcedClosure(
                                              'Errore stampa', Colors.red);
                                          ctrlLook.setInPrint(false);
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.onPrimary,
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                        "C",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                            /// CS — SOLO SE BANCO ATTIVO
                            ValueListenableBuilder<bool>(
                              valueListenable: bancoAbilitato,
                              builder: (_, isBancoAttivo, __) {
                                if (!isBancoAttivo) {
                                  return const SizedBox.shrink();
                                }

                                return Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 44,
                                      child: ElevatedButton(
                                        onLongPress: () async {
                                          ModalConfirm(context,
                                              titolo: 'Archivia senza stampa?',
                                              messaggio: '',
                                              confermaLabel: 'Archivia',
                                              colorePrimario:
                                                  const Color(0xFF95C01F),
                                              onConferma: () async {
                                            try {
                                              ///LONGPRESS SALVA IL DOCUMENTO E CHIUDE SENZA STAMPARE
                                              //RECUPERO IL PAGAMENTO CASH
                                              final PaymentModel? paymentsCash =  await PaymentModel.getCashPayment();
                                              if (paymentsCash == null) return;

                                              //CONTROLLO MOTIVO SCONTO
                                              if ( await  modalDiscountReason(context) ==  false) return;    
                                              //APPLICO AI PAGAMENTI CARRELLO IL PAGAMENTO IN CONTANTI IN QUESTO CASO UNICO
                                              carrello.addPayment(Payment(
                                                  title: paymentsCash.title,
                                                  tend: paymentsCash.tend ?? 1,
                                                  idPayment: paymentsCash.id,
                                                  amount:
                                                      carrello.totaleCarrello -
                                                          carrello.discount));
                                              //STAMPA A REPARTO
                                              if( operatorLogged?.printDefaultCommandFromBench == 1 ){
                                                final ctrTab = context.read<ControllerTableOpened>();
                                                    Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment(true, carrello.prodotti);
                                                    for (final entry in pp.entries) {
                                                      final key  = entry.key;
                                                      final list = entry.value;

                                                      await EscPos().printOrderToDepartment(
                                                        key.split(':')[0],
                                                        int.parse(key.split(':')[1]),
                                                        operatorLogged!,
                                                        deviceCurrent['title'],
                                                        null,
                                                        list,
                                                        ctrTab.numberCoverSelected,
                                                        null,
                                                      );
                                                    }
                                              };
                                              //SE STAMPATO PROCEDO ALL'INVIO AL DB
                                              Map<String, double>
                                                  summaryTipologies = carrello
                                                      .getAmountSplitTypeProduct();
                                              await TurnoLavoro
                                                  .addDocumentToShift(
                                                tipoDocumento: 'simulation',
                                                totaleDocumento:
                                                    carrello.totaleCarrello,
                                                contanti:
                                                    carrello.totaleCarrello,
                                                sconto: carrello.discount,
                                                amountBeverage: carrello
                                                        .getAmountSplitTypeProduct()[
                                                    'beverage'] as double,
                                                amountAltro: carrello
                                                        .getAmountSplitTypeProduct()[
                                                    'altro'] as double,
                                                amountFood: carrello
                                                        .getAmountSplitTypeProduct()[
                                                    'food'] as double,
                                              );

                                              await ScontrinoService
                                                  .archiveDocumentInLocalDb(
                                                      carrello, 'simulation');
                                           
                                            } catch (err) {
                                              debugPrint(err.toString());
                                            }
                                          });
                                        },
                                        onPressed: () async {
                                          //SE IN USO LA STAMPANTE FISCALE BLOCCO IL CLICK DEL TASTO IN CASO CONTRARIO BLOCCO EVENTUALI CLICK
                                          if (controllerNotFiscal.inPrintig_) return;
                                          //CONTROLLO MOTIVO SCONTO
                                          if ( await  modalDiscountReason(context) ==  false) return; 
                                          
                                          controllerNotFiscal.setInPrinting(true);

                                          //RECUPERO IL PAGAMENTO CASH
                                          final PaymentModel? paymentsCash = await PaymentModel.getCashPayment();
                                          if (paymentsCash == null) return;

                                          //APPLICO AI PAGAMENTI CARRELLO IL PAGAMENTO IN CONTANTI IN QUESTO CASO UNICO
                                          carrello.addPayment(Payment(
                                              title: paymentsCash.title,
                                              tend: paymentsCash.tend ?? 1,
                                              idPayment: paymentsCash.id,
                                              amount: carrello.totaleCarrello -
                                                  carrello.discount));

                                          bool printed = await printNotFiscalEscPos(context);
                                          //STAMPA A REPARTO
                                          if( operatorLogged?.printDefaultCommandFromBench == 1 ){
                                            final ctrTab = context.read<ControllerTableOpened>();
                                                Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment(true, carrello.prodotti);
                                                for (final entry in pp.entries) {
                                                  final key = entry.key;
                                                  final list = entry.value;

                                                  await EscPos().printOrderToDepartment(
                                                    key.split(':')[0],
                                                    int.parse(key.split(':')[1]),
                                                    operatorLogged!,
                                                    deviceCurrent['title'],
                                                    null,
                                                    list,
                                                    ctrTab.numberCoverSelected,
                                                    null,
                                                  );
                                                }
                                          };
                                          Timer(
                                              Duration(seconds: 1),
                                              () => controllerNotFiscal
                                                  .setInPrinting(false));

                                          //SE STAMPATO PROCEDO ALL'INVIO AL DB
                                          if (printed) {
                                            //await  ScontrinoService.sendPrint( carrello, 'simulation' );
                                            ScontrinoService
                                                .archiveDocumentInLocalDb(
                                                    carrello, 'simulation');
                                          } else {
                                            carrello.setPayments([]);
                                            //NEL CASO LA STAMPA NON VA A BUON FINE SVUOTO I PAGAMENTI
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          elevation: 2,
                                        ),
                                        child: controllerNotFiscal.inPrintig_
                                            ? Icon(LucideIcons.loader)
                                            : Text(
                                                "CS",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  /// 🔢 TOTALE — INALTERATO
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutPage(),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            carrello.discountType == null
                                ? Container()
                                : Text(
                                    "${(carrello.totaleCarrello).toStringAsFixed(2).replaceAll('.', ',')} €",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            Text(
                              "${(carrello.totaleCarrello - carrello.discount).toStringAsFixed(2).replaceAll('.', ',')} €",
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // SCONTO BAR
  // --------------------------------------------------------------------
  Widget _buildScontoBar(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;
    final isMobile = width < 600;

    // Nascondi su mobile e tablet
    if (isTablet || isMobile) {
      return const SizedBox.shrink();
    }

    if (operatorLogged != null && operatorLogged!.enableDiscount == 0)
      return Container();

    return Container(
      height: 55,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _btnSconto("%", Icons.percent_rounded, ScontoTipo.percentuale),
          _btnSconto("€", Icons.euro_rounded, ScontoTipo.importo),
          _btnSconto("TOT", Icons.payments_rounded, ScontoTipo.totale),
        ],
      ),
    );
  }

  Widget _btnSconto(String label, IconData icon, ScontoTipo tipo) {
    final theme = Theme.of(context);
    final controllerCart = context.read<CarrelloController>();

    return Expanded(
      child: GestureDetector(
        onTap: () => {
          if (controllerCart.prodotti.isNotEmpty)
            {
              controllerCart.resetDiscount(),
              _apriPopupSconto(tipo, context),
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
  void _apriPopupSconto(ScontoTipo tipo, BuildContext content) {
    tipoInserimento = tipo;
    scontoCtrl.clear();
    final ctrlModuloPagamento = context.read<ControllerModuloPagamenti>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: tipo == ScontoTipo.percentuale
              ? const Text("Inserisci % ")
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
              onPressed: () {
                final carrello = context.read<CarrelloController>();
                // CONTROLLO SCONTO MASSIMO ABILITATO PER L'operatore loggato
                bool discountOk = OperatoreModel.checkDiscountMaximim(
                    carrello.totaleCarrello,
                    tipo,
                    scontoCtrl.text,
                    operatorLogged!.maximumDiscount);
                if (discountOk == false) return;
                carrello.applyDiscount(
                    scontoCtrl.text, tipo, ctrlModuloPagamento, context);
                Navigator.pop(ctx);
              },
              child: const Text("Applica"),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------
  // TASTIERINO NUMERICO CON PULSANTE “C”
  // --------------------------------------------------------------------
  Widget _buildTastierino(BuildContext context) {
    final carrello = context.read<CarrelloController>();
    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;

    final List<String> tasti = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '0',
      '00',
      'C',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      child: Column(
        children: [
          // ============================
          // GRID NUMERICA
          // ============================
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasti.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: isTablet ? 4 : 3,
                crossAxisSpacing: isTablet ? 5 : 3,
                childAspectRatio: isTablet ? 3.4 : 2.4,
              ),
              itemBuilder: (context, index) {
                final t = tasti[index];
                return ElevatedButton(
                  onPressed: () {
                    if (t == 'C') {
                      _resetTastierino();
                      scontoCtrl.clear();
                      return;
                    }

                    _onNumero(t);

                    // SOLO PER SCONTI
                    if (tipoInserimento != null) {
                      final valore = _calcolaRisultatoLive();
                      scontoCtrl.text =
                          valore.toStringAsFixed(2).replaceAll('.', ',');
                      //_applySconto(valore, carrello);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 3,
          ),
          // ============================
          // ,  /  CLEAR
          // ============================
          Row(
            children: [
              // CLEAR TOTALE — A SINISTRA
              Expanded(
                child: ElevatedButton(
                  onPressed: _onMoltiplica,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // , — A DESTRA
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final last = buffer.split('×').last;
                    if (!last.contains(',')) {
                      buffer += ',';
                      scontoCtrl.text = buffer;
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    ',',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // ============================
          // ✖  /  ⬅
          // ============================
          Row(
            children: [
              // ✖ MOLTIPLICAZIONE (X SOPRA)

              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _resetTastierino();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_sweep,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // ⬅ BACKSPACE (X SOTTO VERDE)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (buffer.isEmpty) return;

                    buffer = buffer.substring(0, buffer.length - 1);
                    buffer = buffer.trimRight();

                    final risultato = _calcolaRisultatoLive();
                    scontoCtrl.text = buffer.isEmpty
                        ? ''
                        : risultato.toStringAsFixed(2).replaceAll('.', ',');

                    if (tipoInserimento != null && buffer.isNotEmpty) {
                      //_applySconto(risultato, carrello);
                    }

                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC540),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back, size: 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calcolaRisultatoLive() {
    if (!buffer.contains('×')) {
      return double.tryParse(buffer.replaceAll(',', '.')) ?? 0;
    }

    final parts = buffer.split('×');
    double result = 1;

    for (final p in parts) {
      final v = double.tryParse(p.trim().replaceAll(',', '.'));
      if (v == null) return 0;
      result *= v;
    }

    return result;
  }

  Widget _buildDisplayBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 1400 && width >= 600;

    final bgColor = isDark ? const Color(0xFF1F2A1F) : const Color(0xFFDCECC6);

    final textColor =
        isDark ? const Color(0xFFB7E08A) : const Color(0xFF1E2E1E);

    return Container(
      height: isTablet ? 32 : 42,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              buffer.isEmpty
                  ? '0'
                  : buffer.trimRight().endsWith('×')
                      ? buffer
                          .trimRight()
                          .substring(0, buffer.trimRight().length - 1)
                          .trimRight()
                      : buffer,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: isTablet ? 18 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //TASTO NUMERO SU TASTIERINO POS
  void _onNumero(String t) {
    // ============================
    // REGOLA SE X é il primo valore
    // ============================
    if (buffer.isNotEmpty && buffer[0] == 'x') {
      operatore = null;
      buffer += t;
      n1 = null;
      mode = TastierinoMode.quantita;
      setState(() {});
      return;
    }

    // ============================
    // REGOLA 1 — PRIMO NUMERO (quantità)
    // ============================
    if (mode == TastierinoMode.idle) {
      operatore = null;
      buffer = t;
      n1 = _parseInput(buffer);
      mode = TastierinoMode.quantita;
      setState(() {});
      return;
    }

    // ============================
    // REGOLA 1 — continua quantità
    // ============================
    if (mode == TastierinoMode.quantita) {
      buffer += t;
      n1 = _parseInput(buffer);
      setState(() {});
      return;
    }

    // REGOLA 2 — × + N (prezzo unitario)
    // ============================
    if (mode == TastierinoMode.prezzo && operatore == 'x' && n1 == null) {
      buffer += t; // SOLO NUMERO
      n1 = _parseInput(buffer); // n1 = PREZZO UNITARIO
      setState(() {});
      return;
    }

    // ============================
    // REGOLA 3 — N × N
    // ============================
    if (mode == TastierinoMode.prezzo && n1 != null) {
      final parts = buffer.split('×');
      final current = parts.length > 1 ? parts.last.trim() : '';

      final nuovo = current + t;
      n2 = _parseInput(nuovo);

      buffer = '${n1!.toInt()} × $nuovo';
      mode = TastierinoMode.quantitaPrezzo;

      setState(() {});
      return;
    }

    // ============================
    // REGOLA 3 — continua prezzo
    // ============================
    if (mode == TastierinoMode.quantitaPrezzo) {
      final parts = buffer.split('×');
      final current = parts.last.trim();

      final nuovo = current + t;
      n2 = _parseInput(nuovo);

      buffer = '${n1!.toInt()} × $nuovo';

      setState(() {});
      return;
    }
  }

  //TASTO X SU TASTIERINO POS
  void _onMoltiplica() {
    //Controllo se è gia presente X
    if (buffer.isNotEmpty && buffer.contains('x')) return;

    // CASO: × premuto da idle → prezzo diretto
    if (mode == TastierinoMode.idle) {
      operatore = 'x';
      mode = TastierinoMode.prezzo;
      buffer = 'x'; // ️ NESSUN NUMERO
      n1 = null;
      setState(() {});
      return;
    }

    // CASO: N × (quantità × prezzo)
    if (mode == TastierinoMode.quantita && n1 != null) {
      operatore = 'x';
      mode = TastierinoMode.prezzo;
      buffer = '${n1!.toInt()} ×';
      setState(() {});
      return;
    }
  }

  void _resetTastierino() {
    buffer = '';
    n1 = null;
    n2 = null;
    operatore = null;
    mode = TastierinoMode.idle;
    setState(() {});
  }

  //AGGIUNTA A CARRELLO DEL PRODOTTO IN BASE AGLI INPUT DEL TASTIERINO
  void applicaInputSuProdotto(ArticleWhitPriceListModel p,
      CarrelloController carrello, bool genericArticleFromDepartment,
      {double? genericQta = null, double? genericPrice = null}) {
    try {
      //CONTROLLO QTA PASSATA SOLO DALL'articolo GENERICO
      if (![genericQta, genericPrice].contains(null)) {
        carrello.addArticleInCart(
            p, genericQta!, genericPrice, genericArticleFromDepartment);
        return;
      }

      //CONTROLLO IL BUFFER e x è il primo valore cambio prezzo
      if (buffer.isNotEmpty && buffer[0] == 'x') {
        double newPriceUnit =
            double.parse(buffer.substring(1).replaceAll(',', '.'));
        carrello.addArticleInCart(
            p, n1 ?? 1, newPriceUnit, genericArticleFromDepartment);
        return;
      }

      //AGGIUNGO qta x prezzo
      if (n1 != null && n2 != null) {
        carrello.addArticleInCart(p, n1 ?? 1, n2, genericArticleFromDepartment);
        return;
      }

      //AGGIUNGO CON QUANTITA SELEZIONATA
      if (n1 != null) {
        carrello.addArticleInCart(
            p, n1 ?? 1, null, genericArticleFromDepartment);
        return;
      }

      //Aggiunta base del prodotto
      carrello.addArticleInCart(p, 1, null, genericArticleFromDepartment);
    } catch (err) {
      debugPrint(err.toString());
    } finally {
      _resetTastierino();
    }
  }
}
 */
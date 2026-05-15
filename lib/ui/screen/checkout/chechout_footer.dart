import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_connection.dart';
import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/app/service/service_transaction.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/modelli/payment.dart';
import 'package:dashboard/modelli/pos.dart';
import 'package:dashboard/pagamenti_elettronici/pagamenti.dart';
import 'package:dashboard/printers/not_fiscal/esc_pos.dart';
import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/screen/scontrino/scontrino_service.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/ui/widget/header_footer/controller_not_fiscal_in_printing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';


class CheckoutFooter extends StatefulWidget {
  final VoidCallback onConferma;
  final bool checkoutCompleto;
  const CheckoutFooter({
    super.key,
    required this.onConferma,
    required this.checkoutCompleto,
  });

  @override
  State<CheckoutFooter> createState() => _CheckoutFooterState();
}


class _CheckoutFooterState extends State<CheckoutFooter> {
  String orario = "";
  Timer? _timer;
  bool pinAdminAttivo = false; // catenaccio
  bool confirmAndSend = operatorLogged?.printDefaultCommandFromBench == 1;

  @override
  void initState() {
    super.initState();
    _aggiornaOrario();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _aggiornaOrario(),
    );
  }

  void _aggiornaOrario() {
    final now = DateTime.now();
    setState(() {
      orario =
          "${_giorno(now.weekday)} ${now.day.toString().padLeft(2, '0')} "
          "${_mese(now.month)} ${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}";
    });
  }

  String _giorno(int n) {
    const giorni = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
    return giorni[n - 1];
  }

  String _mese(int n) {
    const mesi = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic'
    ];
    return mesi[n - 1];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    const darkBackground  = Color(0xFF2A2A2A);
    const lightBackground = Color(0xFF97D700);

    final carrello             = context.watch<CarrelloController>();
    final controllerNotFiscal  = context.watch<ControllerNotFiscalInPrinting>();
    final ctrlModuloPagamento  = context.watch<ControllerModuloPagamenti>();
    final controllerConnection = context.watch<ConnectionController>();

    // ── PUNTO 1: variabili di validazione ────────────────────────────────
    final totale  = carrello.totalWithTipsAndDiscount;
    final pagato  = carrello.getPayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    final bool totaleValido    = (pagato - totale).abs() < 0.01;
    final bool haPagamenti     = ctrlModuloPagamento.paymentsSelected.isNotEmpty;
    final bool abilitaConferma = true; // totaleValido && haPagamenti;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? darkBackground : lightBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---------------------------------------------------
          // SINISTRA — RETE + ORARIO
          // ---------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Row(
              children: [
                Icon(
                  controllerConnection.connected ? Icons.wifi : Icons.wifi_off,
                  color: controllerConnection.connected
                      ? theme.colorScheme.primary
                      : Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  orario,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------
          // DESTRA — CONFERMA
          // ---------------------------------------------------
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // -------------------------------
                // SWITCH CONFERMA E INVIA
                // -------------------------------
                const SizedBox(width: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stampa comanda',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Switch(
                      value: confirmAndSend,
                      onChanged: (v) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => confirmAndSend = v);
                        });
                      },
                      thumbColor: WidgetStateProperty.all(isDark ? Colors.white : Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 80),

          // -------------------------------
          // BOTTONE CONFERMA
          // -------------------------------
          SizedBox(
            height: 46,
            width: 390,
            child: ElevatedButton(
              // ── PUNTO 3: onLongPress originale intatto ──────────────
              onLongPress: () async {
                if (carrello.riscontro == false) return;
                ModalConfirm(
                  context,
                  titolo: 'Archivia senza stampa?',
                  messaggio: '',
                  confermaLabel: 'Archivia',
                  colorePrimario: const Color(0xFF95C01F),
                  onConferma: () async {
                    try {
                      // LONGPRESS SALVA IL DOCUMENTO E CHIUDE SENZA STAMPARE
                      // RECUPERO IL PAGAMENTO CASH
                      final PaymentModel? paymentsCash =
                          await PaymentModel.getCashPayment();
                      if (paymentsCash == null) return;

                      // APPLICO AI PAGAMENTI CARRELLO IL PAGAMENTO IN CONTANTI
                      carrello.addPayment(Payment(
                        title:     paymentsCash.title,
                        tend:      paymentsCash.tend ?? 1,
                        idPayment: paymentsCash.id,
                        amount:    carrello.totaleCarrello - carrello.discount,
                      ));

                      // SE STAMPATO PROCEDO ALL'INVIO AL DB
                      Map<String, double> summaryTipologies = carrello.getAmountSplitTypeProduct();
                      await TurnoLavoro.addDocumentToShift(
                        tipoDocumento:  'simulation',
                        totaleDocumento: carrello.totaleCarrello,
                        contanti:        carrello.totaleCarrello,
                        sconto:          carrello.discount,
                        amountBeverage:  carrello.getAmountSplitTypeProduct()['beverage'] as double,
                        amountAltro:     carrello.getAmountSplitTypeProduct()['altro']    as double,
                        amountFood:      carrello.getAmountSplitTypeProduct()['food']     as double,
                      );

                      await ScontrinoService.archiveDocumentInLocalDb( carrello, 'simulation' );
                    } catch (err) {
                      debugPrint(err.toString());
                    }
                  },
                );
              },

              // ── PUNTO 3: onPressed condizionale ─────────────────────
              onPressed: abilitaConferma
                  ? () async {
                        debugPrint('🟢 [CONFERMA] Bottone premuto');
                      try {
                        //CONTROLLO MOTIVO SCONTO
                          final discountResult = await modalDiscountReason(
                            context,
                          );
                          debugPrint(
                            '🔍 [CONFERMA] modalDiscountReason result: $discountResult',
                          );
                          if (discountResult == false) {
                            debugPrint(
                              '⛔ [CONFERMA] Bloccato da modalDiscountReason (result == false)',
                            );
                            return;
                          }

                        final ctrPaymentType = context.read<ControllerModuloPagamenti>();
                        String tipoDocumento = ctrPaymentType.tipoDocumento;
                          debugPrint(
                            '🔍 [CONFERMA] tipoDocumento: $tipoDocumento',
                          );
                        final ctrlLook = context.read<ControllerLookPosInPrinder>();
                        final ctrlCart = context.read<CarrelloController>();
                          debugPrint(
                            '🔍 [CONFERMA] orderInEdit: ${ctrlCart.orderinEdit}, totale: ${ctrlCart.totalWithTipsAndDiscount}',
                          );
                        await Ordine.uploadReceiptToPrinted( ctrlCart.orderinEdit ?? 0);
                          debugPrint(
                            '🔍 [CONFERMA] paymentsSelected: ${ctrPaymentType.paymentsSelected}',
                          );
                        if (ctrPaymentType.paymentsSelected.isEmpty) {
                            debugPrint(
                              '⛔ [CONFERMA] Bloccato: nessun metodo di pagamento selezionato',
                            );
                          SnackBarForcedClosure( 'Selezionare un metodo di pagamento', Colors.red);
                          return;
                        }

                        double amoutPayments = 0;
                        ctrPaymentType.controllerTabPayment.forEach((pc) {
                          if ( ctrPaymentType.paymentsSelected.contains(pc['id']) ) {
                              final txt =
                                  (pc['controller'] as TextEditingController)
                                      .text;
                              debugPrint(
                                '🔍 [CONFERMA] pagamento id=${pc['id']} valore="$txt"',
                              );
                              if (txt.isEmpty) return;
                              amoutPayments += double.parse(txt);
                          }
                        });

                          final totaleCarrello = double.parse(
                            ctrlCart.totalWithTipsAndDiscount.toStringAsFixed(
                              2,
                            ),
                          );
                          debugPrint(
                            '🔍 [CONFERMA] amountPayments=$amoutPayments  totaleCarrello=$totaleCarrello  match=${amoutPayments == totaleCarrello}',
                          );
                          if (amoutPayments != totaleCarrello) {
                            debugPrint(
                              '⛔ [CONFERMA] Bloccato: totale pagamenti ($amoutPayments) != totale carrello ($totaleCarrello)',
                            );
                          SnackBarForcedClosure(
                              "Il totale dei pagamenti non corrisponde all' importo del carrello",
                              Colors.red);
                          return;
                        }
                          debugPrint(
                            '✅ [CONFERMA] Tutti i controlli superati — procedo con la stampa/archiviazione',
                          );

                        /* if (tipoDocumento == 'Fattura') {
                          if (carrello.cliente == null) {
                            SnackBarForcedClosure(
                                'Selezionare un cliente per la fattura',
                                Colors.red);
                            return;
                          }

                          ctrlLook.setInPrint(true);

                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                content: Container(
                                  width: 200,
                                  height: 200,
                                  child: const Center(child: Text('Attendi...')),
                                ),
                              );
                            },
                          );

                          int invoiceInDb = await ScontrinoService.archiveInvoiceDocumentInLocalDb(
                            carrello,
                            'invoice',
                            closureReceipt: null,
                            receiptNumber:  null,
                            notCleanCart:   true,
                          );
                          int timer          = 0;
                          bool foundidNumber = false;
                          int documentNumber = 0;
                          while (timer < 20 && !foundidNumber && invoiceInDb > 0) {
                            Documento? doc;
                            final resp = await LocalDB.query('SELECT * FROM documents WHERE id = $invoiceInDb');
                            if (resp.length > 0)
                              doc = Documento.fromMap(resp[0]);
                            if (doc != null &&
                                doc.idReal != null &&
                                doc.assignedDocumentNumber != null) {
                              foundidNumber  = true;
                              documentNumber = doc.assignedDocumentNumber!;
                            }
                            await Future.delayed(const Duration(seconds: 1));
                            timer++;
                          }

                          Navigator.of(context).pop(); // ESCO DAL MESSAGGIO DI ATTESA

                          if (invoiceInDb > 0) {
                            SharedPreferences pref = await SharedPreferences.getInstance();
                            String? devicePref = pref.getString('device');

                            if (devicePref == null) return;

                            Map device   = jsonDecode(devicePref);
                            String? host = device['noFiscalPrinterIpv4'];
                            int? port    = device['noFiscalPrinterPort'];
                            if (host == null || port == null) return;

                            List<String> linesHead = await getHeadReceipt();
                            List<String> lines     = [];
                            carrello.prodotti.forEach((art) {
                              List<ProdottoCarrello> vars = [
                                ...art.variationsFree,
                                ...art.variationsInfo,
                                ...art.variationsMinus,
                                ...art.variationsPlus,
                              ];
                              lines.add(formatRigaPreconto(
                                art.article.title,
                                art.quantity.toString(),
                                art.priceRowWithVariant.toStringAsFixed(2),
                              ));
                              if (vars.isNotEmpty) {
                                vars.forEach((var_) => lines.add(
                                      formatRigaPrecontoVariante(
                                        var_.article.title,
                                        var_.priceRowCart.toStringAsFixed(2),
                                        var_.variationType ?? '',
                                      ),
                                    ));
                              }
                            });

                            bool print = await EscPos().printReceiptInvoice(
                              host,
                              port,
                              linesHead,
                              lines,
                              carrello,
                              documentNumber,
                            );
                            SnackBarForcedClosure('Fattura generata', Colors.green);

                            // SE ATTIVO STAMPA A REPARTO
                            if (confirmAndSend) {
                              final ctrTab =
                                  context.read<ControllerTableOpened>();
                              Map<String, List<ProdottoCarrello>> pp =
                                  await ctrTab.splitProductsForDeparment(
                                      true, carrello.prodotti);
                              pp.forEach((key, list) {
                                EscPos().printOrderToDepartment(
                                  key.split(':')[0],
                                  int.parse(key.split(':')[1]),
                                  operatorLogged!,
                                  deviceCurrent['title'],
                                  null,
                                  list,
                                  ctrTab.numberCoverSelected,
                                  null,
                                );
                              });
                            }

                            // TURNO DI LAVORO
                            Map<String, double> summaryTipologies = carrello.getAmountSplitTypeProduct();
                            double cash        = 0;
                            double elettronico = 0;
                            double tickets     = 0;
                            List<PaymentModel> allPayments = await PaymentModel.getPayments();

                            ctrPaymentType.controllerTabPayment.forEach((pc) {
                              if (ctrPaymentType.paymentsSelected.contains(pc['id'])) {

                                if ( (pc['controller'] as TextEditingController).text.isEmpty) return;

                                PaymentModel? p = allPayments.firstWhereOrNull((p) => p.id == pc['id']);

                                if (p == null) return;

                                if (p.cashPayment == 1) cash = cash + double.parse((pc['controller'] as TextEditingController).text);

                                if (p.cashPayment == 0) elettronico = elettronico + double.parse((pc['controller'] as TextEditingController).text);
                              }
                            });

                            await TurnoLavoro.addDocumentToShift(
                              tipoDocumento:   'invoice',
                              totaleDocumento: carrello.totalWithTipsAndDiscount,
                              sconto:          carrello.discount,
                              amountAltro:     summaryTipologies['altro']     as double,
                              amountBeverage:  summaryTipologies['beverage']  as double,
                              amountFood:      summaryTipologies['food']      as double,
                              contanti:        cash,
                              assegno:         0,
                              elettronico:     elettronico,
                              tickets:         0,
                            );
                            ctrlLook.setInPrint(false);
                            carrello.clearCart();
                            Navigator.of(context).pop();
                            return;
                          }
                          ctrlLook.setInPrint(false);
                          SnackBarForcedClosure('Errore generazione fattura', Colors.red);
                          return;
                        } */

                        // ── PUNTO 4 intatto: blocco riscontro originale ──
                        if (carrello.riscontro) {

                          ControllerModuloPagamenti ctrModuloPagamento = context.read<ControllerModuloPagamenti>();

                          if( ctrModuloPagamento.nessunaStampa == true ){
                            if (controllerNotFiscal.inPrintig_) return;
                              controllerNotFiscal.setInPrinting(true);
                              // RECUPERO IL PAGAMENTO CASH
                              final PaymentModel? paymentsCash = await PaymentModel.getCashPayment();
                              if (paymentsCash == null) return;
                              carrello.addPayment(Payment(
                                title:     paymentsCash.title,
                                tend:      paymentsCash.tend ?? 1,
                                idPayment: paymentsCash.id,
                                amount:    carrello.totaleCarrello - carrello.discount,
                              ));
                              await ScontrinoService.archiveDocumentInLocalDb( carrello, 'simulation' );
                              await TurnoLavoro.addDocumentToShift(
                                tipoDocumento:   'simulation',
                                totaleDocumento: carrello.totaleCarrello,
                                contanti:        carrello.totaleCarrello,
                                sconto:          carrello.discount,
                                amountBeverage:  carrello.getAmountSplitTypeProduct()['beverage'] as double,
                                amountAltro:     carrello.getAmountSplitTypeProduct()['altro']    as double,
                                amountFood:      carrello.getAmountSplitTypeProduct()['food']     as double,
                              );
                              controllerNotFiscal.setInPrinting(false);
                              ctrModuloPagamento.setNessunaStampa(false);
                              Navigator.pop(context);
                              return;
                          }
                          // SE IN USO LA STAMPANTE FISCALE BLOCCO IL CLICK
                          if (controllerNotFiscal.inPrintig_) return;
                          controllerNotFiscal.setInPrinting(true);

                          // RECUPERO IL PAGAMENTO CASH
                          final PaymentModel? paymentsCash = await PaymentModel.getCashPayment();
                          if (paymentsCash == null) return;

                          // APPLICO AI PAGAMENTI CARRELLO IL PAGAMENTO IN CONTANTI
                          carrello.addPayment(Payment(
                            title:     paymentsCash.title,
                            tend:      paymentsCash.tend ?? 1,
                            idPayment: paymentsCash.id,
                            amount:    carrello.totaleCarrello - carrello.discount,
                          ));

                          bool printed =  await printNotFiscalEscPos(context,null);
                          Timer(const Duration(seconds: 1), () => controllerNotFiscal.setInPrinting(false));
                          await ScontrinoService.archiveDocumentInLocalDb( carrello, 'simulation' );

                          // SE STAMPATO PROCEDO ALL'INVIO AL DB
                          if (printed) {
                            await TurnoLavoro.addDocumentToShift(
                              tipoDocumento:   'simulation',
                              totaleDocumento: carrello.totaleCarrello,
                              contanti:        carrello.totaleCarrello,
                              sconto:          carrello.discount,
                              amountBeverage:  carrello.getAmountSplitTypeProduct()['beverage'] as double,
                              amountAltro:     carrello.getAmountSplitTypeProduct()['altro']    as double,
                              amountFood:      carrello.getAmountSplitTypeProduct()['food']     as double,
                            );
                            Navigator.of(context).pop();
                          } else {
                            // NEL CASO LA STAMPA NON VA A BUON FINE SVUOTO I PAGAMENTI
                            carrello.setPayments([]);
                          }
                        }

                        Map<String, dynamic> respPos = { 'success' : false , "UUID": '' };

                        ctrlLook.setInPrint(true);

                        List<PaymentModel> allPaymentsMethod = await PaymentModel.getPayments();
                        PaymentModel? paymentCard = allPaymentsMethod.firstWhereOrNull((p) => p.cashPayment == 0);
                        Payment?  paymentPos;
                        PosModel? posSelected;

                        if (paymentCard != null) paymentPos = carrello.getPayments.firstWhereOrNull( (p) => p.idPayment == paymentCard.id);
                        if (paymentPos != null) {
                          posSelected =  await PosModel.modalSelectedPos(context);
                          if (posSelected != null) {
                            // SE IL POS è selezionato
                            final ctrlTimer = context.read<ControllerTimerPos>();
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                final ctrlTimer = context.watch<ControllerTimerPos>();
                                return AlertDialog(
                                        backgroundColor: Colors.transparent,
                                        contentPadding: EdgeInsets.zero,
                                        content: Container(
                                          width: 320,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 40,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(28),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [

                                                // ── Icona animata ──────────────────────────────────────────
                                                Container(
                                                  width: 72,
                                                  height: 72,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primaryContainer,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 36,
                                                      height: 36,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 3,
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(height: 20),

                                                // ── Titolo ─────────────────────────────────────────────────
                                                Text(
                                                  'Attesa pagamento',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),

                                                const SizedBox(height: 8),

                                                // ── Sottotitolo ────────────────────────────────────────────
                                                Text(
                                                  'Avvicina o inserisci la carta al POS',
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                                                    height: 1.4,
                                                  ),
                                                ),

                                                const SizedBox(height: 20),

                                                // ── Timer pill ─────────────────────────────────────────────
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                                    borderRadius: BorderRadius.circular(50),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.timer_outlined,
                                                        size: 16,
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        ctrlTimer.timerPos.toString(),
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(height: 28),

                                                // ── Divider ────────────────────────────────────────────────
                                                Divider(
                                                  height: 1,
                                                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                                                ),

                                                const SizedBox(height: 16),

                                                // ── Bottone Annulla ────────────────────────────────────────
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton.icon(
                                                    onPressed: () async {
                                                      if (posSelected!.type == 'dojo') {
                                                        await PosModel.trashPaymentDojo(ctrlTimer.uuidPayment);
                                                      }
                                                      Navigator.of(context).pop();
                                                    },
                                                    icon: const Icon(Icons.close_rounded, size: 18),
                                                    label: const Text('Annulla pagamento'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Theme.of(context).colorScheme.error,
                                                      side: BorderSide(
                                                        color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                              },
                            );

                            
                            if (posSelected.type == 'dojo') 
                                  respPos = await PosModel.paymentDojo( posSelected, (paymentPos.amount * 100 ).toInt(),ctrlTimer);

                            if (posSelected.type == 'ecr17')
                                  respPos = await PosModel.paymentEcr17(
                                      posSelected, 
                                      paymentPos.amount, 
                                      ctrlTimer
                                    );

                            Navigator.pop(context);
                            if (respPos['success'] != true) {
                              ctrlLook.setInPrint(false);
                              return;
                            }
                          } else {
                            ctrlLook.setInPrint(false);
                            return;
                          }
                        }
                        
                        //SE IL PAGAMENTO ELETTRONICO é AVVENUTO CON SUCCESSO SALVA PAGAMENTO ELETTRONICO PER ANNULLI
                        if( respPos['success'] == true ){
                          Database db = await LocalDB.instance();
                          ElectronicPaymentDao(db).insert(ElectronicPayment(
                            idDocument: 0, 
                            posType: posSelected?.type ?? '', 
                            amount: paymentPos?.amount ?? 0,
                            paymentIdentifier: respPos['UUID'],
                            refund: 0
                          ));
                        }   
                        
                        if (tipoDocumento == 'Fattura') {
                          if (carrello.cliente == null) {
                            SnackBarForcedClosure(
                                'Selezionare un cliente per la fattura',
                                Colors.red);
                            return;
                          }

                          ctrlLook.setInPrint(true);

                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                content: Container(
                                  width: 200,
                                  height: 200,
                                  child: const Center(child: Text('Attendi...')),
                                ),
                              );
                            },
                          );

                          int invoiceInDb = await ScontrinoService.archiveInvoiceDocumentInLocalDb(
                            carrello,
                            'invoice',
                            closureReceipt: null,
                            receiptNumber:  null,
                            notCleanCart:   true,
                          );
                          int timer          = 0;
                          bool foundidNumber = false;
                          int documentNumber = 0;
                          while (timer < 20 && !foundidNumber && invoiceInDb > 0) {
                            Documento? doc;
                            final resp = await LocalDB.query('SELECT * FROM documents WHERE id = $invoiceInDb');
                            if (resp.length > 0)
                              doc = Documento.fromMap(resp[0]);
                            if (doc != null &&
                                doc.idReal != null &&
                                doc.assignedDocumentNumber != null) {
                              foundidNumber  = true;
                              documentNumber = doc.assignedDocumentNumber!;
                            }
                            await Future.delayed(const Duration(seconds: 1));
                            timer++;
                          }

                          Navigator.of(context).pop(); // ESCO DAL MESSAGGIO DI ATTESA

                          if (invoiceInDb > 0) {
                            SharedPreferences pref = await SharedPreferences.getInstance();
                            String? devicePref = pref.getString('device');

                            if (devicePref == null) return;

                            Map device   = jsonDecode(devicePref);
                            String? host = device['noFiscalPrinterIpv4'];
                            int? port    = device['noFiscalPrinterPort'];
                            if (host == null || port == null) return;

                            List<String> linesHead = await getHeadReceipt();
                            List<String> lines     = [];
                            carrello.prodotti.forEach((art) {
                              List<ProdottoCarrello> vars = [
                                ...art.variationsFree,
                                ...art.variationsInfo,
                                ...art.variationsMinus,
                                ...art.variationsPlus,
                              ];
                              lines.add(formatRigaPreconto(
                                art.article.title,
                                art.quantity.toString(),
                                art.priceRowWithVariant.toStringAsFixed(2),
                              ));
                              if (vars.isNotEmpty) {
                                vars.forEach((var_) => lines.add(
                                      formatRigaPrecontoVariante(
                                        var_.article.title,
                                        var_.priceRowCart.toStringAsFixed(2),
                                        var_.variationType ?? '',
                                      ),
                                    ));
                              }
                            });

                            bool print = await EscPos().printReceiptInvoice(
                              host,
                              port,
                              linesHead,
                              lines,
                              carrello,
                              documentNumber,
                            );
                            SnackBarForcedClosure('Fattura generata', Colors.green);

                            // SE ATTIVO STAMPA A REPARTO
                            if (confirmAndSend) {
                              final ctrTab = context.read<ControllerTableOpened>();
                              Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment( true, carrello.prodotti );

                              pp.forEach((key, list) {
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
                              });
                            }

                            // TURNO DI LAVORO
                            Map<String, double> summaryTipologies = carrello.getAmountSplitTypeProduct();
                            double cash        = 0;
                            double elettronico = 0;
                            double tickets     = 0;
                            List<PaymentModel> allPayments = await PaymentModel.getPayments();

                            ctrPaymentType.controllerTabPayment.forEach((pc) {
                              if (ctrPaymentType.paymentsSelected.contains(pc['id'])) {

                                if ( (pc['controller'] as TextEditingController).text.isEmpty) return;

                                PaymentModel? p = allPayments.firstWhereOrNull((p) => p.id == pc['id']);

                                if (p == null) return;

                                if (p.cashPayment == 1) cash = cash + double.parse((pc['controller'] as TextEditingController).text);

                                if (p.cashPayment == 0) elettronico = elettronico + double.parse((pc['controller'] as TextEditingController).text);
                              }
                            });

                            await TurnoLavoro.addDocumentToShift(
                              tipoDocumento:   'invoice',
                              totaleDocumento: carrello.totalWithTipsAndDiscount,
                              sconto:          carrello.discount,
                              amountAltro:     summaryTipologies['altro']     as double,
                              amountBeverage:  summaryTipologies['beverage']  as double,
                              amountFood:      summaryTipologies['food']      as double,
                              contanti:        cash,
                              assegno:         0,
                              elettronico:     elettronico,
                              tickets:         0,
                            );
                            ctrlLook.setInPrint(false);
                            carrello.clearCart();
                            Navigator.of(context).pop();
                            return;
                          }
                          ctrlLook.setInPrint(false);
                          SnackBarForcedClosure('Errore generazione fattura', Colors.red);
                          return;
                        }

                        // SE SOPRA LA FATTURA NON é SELEZIONATA AVVIA SCONTRINO
                        ServiceReceipt.instance().printReceipt(context, (String number, String close ) async {
                            if (kDebugMode) {
                              print("Scontrino stampato");
                              print("Numero scontrino: $number-$close");
                            }
                           bool archived = await ScontrinoService.archiveDocumentInLocalDb(
                                carrello, null,
                                closureReceipt: close,
                                receiptNumber:  number, notCleanCart: confirmAndSend);
                             
                            // SE ATTIVO STAMPA A REPARTO
                            if (confirmAndSend) {
                              final ctrTab =  context.read<ControllerTableOpened>();
                              Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment( true, carrello.prodotti);
                              pp.forEach((key, list) {
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
                              });
                            }
                            carrello.clearCart();
                            ctrlLook.setInPrint(false);
                            Navigator.pop(context);
                          },
                          (String error) {
                            if (kDebugMode) print(error);
                            ctrlLook.setInPrint(false);
                          },
                        );
                      } catch (err) {
                        debugPrint(err.toString());
                      } finally {
                        final ctrlLook =
                            context.read<ControllerLookPosInPrinder>();
                        ctrlLook.setInPrint(false);
                      }
                    }
                  : null, // ← PUNTO 3: null quando disabilitato

              // ── PUNTO 5: backgroundColor con stato disabilitato ──────
              style: ElevatedButton.styleFrom(
                backgroundColor: abilitaConferma
                    ? (confirmAndSend
                        ? Colors.orange.shade700
                        : (isDark
                            ? Colors.green.shade600
                            : Colors.green.shade700))
                    : Colors.grey.shade400, // DISABILITATO
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: controllerNotFiscal.inPrintig_
                   ? const Icon(Icons.front_loader)
                   : Text(confirmAndSend ? "Conferma e Invia" : "Conferma"),
            ),
          ),
        ],
      ),
    );
  }
}
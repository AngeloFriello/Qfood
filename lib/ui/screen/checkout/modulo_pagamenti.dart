import 'package:collection/collection.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/modelli/payment.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../state/controller_carrello.dart';
import 'cliente/InserisciClienteVista.dart';


class ModuloPagamenti extends StatefulWidget {
  final ControllerModuloPagamenti ctrModuloPagamento;
  final CarrelloController carrello;
  final bool pinBancoAbilitato;
  const ModuloPagamenti({
    super.key,
    required this.pinBancoAbilitato,
    required this.carrello,
    required this.ctrModuloPagamento
  });

  @override
  State<ModuloPagamenti> createState() => _ModuloPagamentiState();
}


class _ModuloPagamentiState extends State<ModuloPagamenti> {

  Future<void> loadPayments () async {
    final ctrlModuloPagamenti = context.read<ControllerModuloPagamenti>();
    await ctrlModuloPagamenti.getPaymentsDB(context);
    if(mounted){
      setState(() {});
    }
  }

  Future<void> apriTicketModal(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TicketModal(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) async {
      loadPayments();
      widget.ctrModuloPagamento.setTipoDocumento('Scontrino');
    });
  }


// --------------------- SCONTO ------------------------

  bool scontoAttivo = false;
  final importoCtrl = TextEditingController();
  final valoreCtrl  = TextEditingController();
  final percentCtrl = TextEditingController();
  String tipoSconto = ""; // "importo", "valore", "percent"
  bool nonRiscosso = false;
  bool mostraAttori = false;
  String attoreSelezionato = "POS";
  bool get soloContanti => widget.ctrModuloPagamento.tipoDocumento == "Riscontro";
  bool splitPaymentAbilitato = false;
  // SPLIT PAYMENT
  double splitImponibile = 0.0;
  double splitIva = 0.0;
  double splitTotale = 0.0;
  double splitDaPagare = 0.0;

  String idDocumento = "";
  String codiceCUP = "";
  String codiceCIG = "";

  final Map<int, FocusNode> focusNodes = {};


  void _resetSplit() {
    splitPaymentAbilitato = false;
    idDocumento = "";
    codiceCUP = "";
    codiceCIG = "";
    splitImponibile = 0.0;
    splitIva = 0.0;
    splitTotale = 0.0;
    splitDaPagare = 0.0;
  }

  void _calcolaSplit(CarrelloController carrello) {
    setState(() {
      splitImponibile = carrello.totaleImponibile;
      splitIva = carrello.ivaTotale;
      splitTotale = splitImponibile + splitIva;
      splitDaPagare = splitImponibile;
    });
  }

  Future<void> _popupDatiPA() async {
    final dati = await mostraDatiSplitPayment(context);
    if (dati == null) return;

    setState(() {
      idDocumento = dati["idDocumento"] ?? "";
      codiceCUP = dati["cup"] ?? "";
      codiceCIG = dati["cig"] ?? "";
    });
  }


  @override
  Widget build(BuildContext context) {
    ControllerModuloPagamenti ctrModuloPagamento = context.watch<ControllerModuloPagamenti>();
    CarrelloController        carrello = context.watch<CarrelloController>();
    return Consumer<CarrelloController>(
      builder: (context, controllerModuloPagamento, child) {
        debugPrint("PIN BANCO = ${widget.pinBancoAbilitato}");
        final theme = Theme.of(context);
        final bool isRiscontro = widget.ctrModuloPagamento.tipoDocumento == "Riscontro";
        final bool isFattura   = widget.ctrModuloPagamento.tipoDocumento == "Fattura";

        void setCash() async {
          ControllerModuloPagamenti ctrModuloPagamento = context.read<ControllerModuloPagamenti>();
          ctrModuloPagamento.resetPaymentSelectedInCheckout();
          PaymentModel? cash = await PaymentModel.getCashPayment();
          if (cash == null) return;
          final test = ctrModuloPagamento.controllerTabPayment.firstWhereOrNull((pp) => pp['id'] == cash.id);
          if (test == null) return;
          (test['controller'] as TextEditingController).text = widget.carrello.totalWithTipsAndDiscount.toString();
          ctrModuloPagamento.paymentsSelected.add(cash.id);
          widget.carrello.addPayment(Payment(title: cash.title, tend: cash.tend ?? 1, idPayment: cash.id, amount: widget.carrello.totalWithTipsAndDiscount));
        }

        Widget blocco(String titolo, Widget contenuto) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8), // [OLD] mantenuto
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  contenuto,
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -----------------------------------------------------------
              // TIPO DOCUMENTO
              // -----------------------------------------------------------
              blocco(
                "Tipo documento",
                Row(
                  children: [
                    Expanded(child: _docTile("Scontrino", LucideIcons.receipt, setCash)),
                    Expanded(child: _docTile("Fattura", LucideIcons.fileText, setCash)), 
                    if (widget.pinBancoAbilitato) Expanded(child: _docTile("Riscontro", LucideIcons.scan, setCash)),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              // -----------------------------------------------------------
              // METODI DI PAGAMENTO
              // -----------------------------------------------------------
              blocco(
                "Tipo Pagamento - Totale: ${widget.carrello.totalWithTipsAndDiscount}", // [OLD] mantenuto
                Column(
                  children: 
                  carrello.riscontro
                  ?
                  [
                    ...ctrModuloPagamento.listPayments.where((pp) => pp.title == 'Contanti').toList().map((p) => tabPayment(p, ctrModuloPagamento)).toList(),
                  ]
                  :
                  [
                    ...ctrModuloPagamento.listPayments.map((p) => tabPayment(p, ctrModuloPagamento)).toList(),
                  ],
                ),
              ),

              // [OLD] mantenuto — bottone Applica
            ctrModuloPagamento.paymentsSelected.length < 2 ? Container() : Container(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrModuloPagamento.paymentsSelected.length != 2) return;
                    //FUNZIONE CHE APPLICA LA DIVISIONE DEL CONTO IN MASSIMO 2 METODI DI PAGAMENTO DIVERSI
                    final carrello     = context.read<CarrelloController>();
                    final ctrlPayments = context.read<ControllerModuloPagamenti>();
                    final totale       = carrello.totalWithTipsAndDiscount;
                    List<Map> payments = [];
                    ctrlPayments.controllerTabPayment.forEach((p) {
                        if( !ctrModuloPagamento.paymentsSelected.contains(p['id'])  ) return;
                        payments.add({...p, 'value': double.tryParse(p['controller'].text) ?? 0 });
                      });
                    payments.sort((a,b) => (a['value'] as double).compareTo(b['value'] as double));

                    if( payments[1]['value'] < totale && payments[1]['value'] != payments[0]['value']){
                      final dif = totale - payments[1]['value'];
                      payments[0]['controller'].text = dif.toString();
                      setState(() {
                        
                      });
                    }

                    if( payments[1]['value'] == payments[0]['value']){
                      final dif = totale / 2;
                      payments[0]['controller'].text = dif.toString();
                      payments[1]['controller'].text = dif.toString();
                      setState(() {
                        
                      });
                    }
                  },
                  child: Text('Applica differenza'),
                ),
              ),

              // -----------------------------------------------------------
              // NESSUNA STAMPA (SOLO VISUALIZZAZIONE)
              // -----------------------------------------------------------
              if (widget.pinBancoAbilitato)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Nessuna stampa", style: Theme.of(context).textTheme.bodyLarge),
                        Switch(
                          value: ctrModuloPagamento.nessunaStampa,
                          onChanged: (v) => setState(() =>  ctrModuloPagamento.setNessunaStampa(v)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // -----------------------------------------------------------
              // SPLIT PAYMENT — SOLO SU FATTURA
              // -----------------------------------------------------------
              if (isFattura)
                blocco(
                  "Split Payment",
                  Column(
                    children: [
                      Row(
                        children: [
                          Text("Abilita Split payment", style: theme.textTheme.bodyLarge),
                          const Spacer(),
                          Switch(
                            value: widget.carrello.splitPayment,
                            onChanged: (v) async {
                              setState(() => widget.carrello.splitPayment = v);
                              if (v) {
                                await _popupDatiPA();
                              } else {
                                _resetSplit();
                              }
                            },
                          ),
                        ],
                      ),
                      if (widget.carrello.splitPayment) ...[
                        const SizedBox(height: 12),
                        _rigaSplit("Id Documento", idDocumento),
                        _rigaSplit("Codice CUP", codiceCUP),
                        _rigaSplit("Codice CIG", codiceCIG),
                        const Divider(),
                        _rigaSplit("Totale imponibile", "€ ${splitImponibile.toStringAsFixed(2)}"),
                        _rigaSplit("Totale IVA", "€ ${splitIva.toStringAsFixed(2)}"),
                        _rigaSplit("Totale fattura", "€ ${splitTotale.toStringAsFixed(2)}"),
                        _rigaSplit("Da pagare", "€ ${splitDaPagare.toStringAsFixed(2)}"),
                      ],
                    ],
                  ),
                ),

            ],
          ),
        );
      },
    );
  }

  bool isTotaleValido() {
    final totale = (widget.carrello.totalWithTipsAndDiscount * 100).round();
    final pagato = widget.carrello.getPayments.fold<int>(
      0, (sum, p) => sum + (p.amount * 100).round(),
    );
    return totale == pagato;
  }

  String formatPrice(double value) {
    double v = double.parse(value.toStringAsFixed(2));
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String formatPriceFixed(double value) {
    final v = (value * 100).round() / 100;
    return v.toStringAsFixed(2);
  }

  // -----------------------------------------------------------
  // TILE DOCUMENTO
  // -----------------------------------------------------------
  Widget _docTile(String label, IconData icon, Function setCash) {
    final theme = Theme.of(context);
    final carrello = context.read<CarrelloController>();


    Future<void> handleTap() async {
      carrello.riscontro = false;
      
      //Verifica se l'operatore puo gestire le fatture
      if (label == "Fattura" && operatorLogged!.manageBill == 0 ){
        SnackBarForcedClosure('Operatore non abilitato alle fatture', Colors.red);
        return;
      }
      if (label == "Fattura") {
        final cliente = carrello.cliente;

        // SE NON C'È CLIENTE APRI MODALE
        if (cliente == null) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  width: 820,
                  height: 920,
                  child: InserisciClienteSheet(
                    onSelect: (clienteSelezionato) {
                      carrello.riscontro = false;

                      final ctrCarrello = context.read<CarrelloController>();
                      ctrCarrello.setCliente(clienteSelezionato);

                      /* final ctrmodPagamento = context.read<ControllerModuloPagamenti>();
                      ctrmodPagamento.paymentsSelected = [];
                      carrello.setPayments([]); */
 
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              );
            },
          );
        
          //  se chiude senza scegliere blocca
          if (carrello.cliente == null) return;
        }
      }

      setState(() {
        widget.ctrModuloPagamento.setTipoDocumento(label);

        if (label != "Fattura") _resetSplit();

        if (label == "Riscontro") {
          carrello.riscontro = true;
          final ctrmodPagamento = context.read<ControllerModuloPagamenti>();
          ctrmodPagamento.paymentsSelected = [];
          carrello.setPayments([]);
          carrello.notifyListeners();
          mostraAttori = false;
          nonRiscosso  = false;
          setCash();
        }
      });
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: handleTap,
      child: Row(
        children: [
          Radio(
            value: label,
            groupValue: widget.ctrModuloPagamento.tipoDocumento,
            onChanged: (_) => handleTap(),
            activeColor: theme.colorScheme.primary,
          ),
          Icon(icon, size: 22),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // TILE PAGAMENTO
  // -----------------------------------------------------------
  Widget tabPayment(PaymentModel payment, ControllerModuloPagamenti ctrModuloPagamento) {
    final theme         = Theme.of(context);
    final scheme        = theme.colorScheme;
    final isDark        = theme.brightness == Brightness.dark;
    final forIcon       = PaymentModel.CodeTypePayment.firstWhereOrNull((t) => t['value'] == payment.revenueAgencyType);
    final icon          = forIcon != null ? forIcon['icon'] : LucideIcons.coins;
    final label         = payment.title;
    final forController = ctrModuloPagamento.controllerTabPayment.firstWhereOrNull((p_) => p_['id'] == payment.id);
    TextEditingController controller = forController != null ? forController['controller'] : TextEditingController();
    final carrello = context.read<CarrelloController>();

    // [NEW] focus per pagamento
    final focusNode = focusNodes.putIfAbsent(payment.id!, () => FocusNode());

    const Color verdeQFood = Color(0xFF95C01F);

    final bool attivo = ctrModuloPagamento.paymentsSelected.contains(payment.id);



    final Color bgColor = attivo
        ? verdeQFood
        : scheme.surfaceContainerHighest.withOpacity(isDark ? 0.35 : 0.6);

    final Color textColor  = attivo ? Colors.white : scheme.onSurface;
    final Color iconColor  = attivo ? Colors.white : scheme.onSurface.withOpacity(0.85);

    final Color inputBg = attivo
        ? Colors.white.withOpacity(isDark ? 0.15 : 0.9) // [OLD] mantenuto
        : (isDark ? scheme.surface.withOpacity(0.9) : scheme.surface);

    return GestureDetector(
      onTap: () async {
        if (payment.title.toLowerCase().trim() == "tiket" || payment.title.toLowerCase().trim() == "ticket") {
            debugPrint("APRO MODALE TICKET");
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const TicketModal(),
            );
            return;
          }
          carrello.resetPayments();
          ctrModuloPagamento.resetPaymentSelectedInCheckout();
          setState(() {
            if (ctrModuloPagamento.paymentsSelected.contains(payment.id)) {
              controller.clear();
              ctrModuloPagamento.paymentsSelected.remove(payment.id);
              carrello.setPayments(carrello.getPayments.where((pp) => pp.idPayment != payment.id).toList());
            } else {
              if (ctrModuloPagamento.paymentsSelected.length == 2) return;
              ctrModuloPagamento.paymentsSelected.add(payment.id);
            }
          });
        //TRASFERIRE TOTALE IMPORTO AL METODO E AZZERARE GLI ALTRI
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );

        if(!ctrModuloPagamento.paymentsSelected.contains(payment.id)) return;
        ctrModuloPagamento.controllerTabPayment.forEach((p) => p['controller'].text = '0');
        double totaleCarrello = carrello.totalWithTipsAndDiscount;
        carrello.addPayment(Payment(title: payment.title, tend: payment.tend ?? 1, idPayment: payment.id, amount: totaleCarrello));
        controller.text = totaleCarrello.toString();
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      },

      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Container(
          height: 56, // [OLD] mantenuto
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outline.withOpacity(isDark ? 0.25 : 0.35),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: attivo ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) setState(() {});
                  },
                  child: InkWell(
                    onTap: () async {
                      controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controller.text.length,
                      );
                      if (payment.title.toLowerCase().trim() == "tiket" || payment.title.toLowerCase().trim() == "ticket") {
                        debugPrint("APRO MODALE TICKET");
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const TicketModal(),
                        );
                        return;
                      }
                      controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controller.text.length,
                      );
                      setState(() {
                        if (ctrModuloPagamento.paymentsSelected.contains(payment.id)) {
                          controller.clear();
                          ctrModuloPagamento.paymentsSelected.remove(payment.id);
                          carrello.setPayments(carrello.getPayments.where((pp) => pp.idPayment != payment.id).toList());
                        } else {
                          if (ctrModuloPagamento.paymentsSelected.length == 2) return;
                          ctrModuloPagamento.paymentsSelected.add(payment.id);
                        }
                      });
                       controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controller.text.length,
                      );
                    },
                    child: TextField(
                      focusNode: focusNode, 
                      enabled: attivo,     
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87, 
                        fontWeight: FontWeight.w600,
                      ),
                      onTap: ()  {
                        controller.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: controller.text.length,
                        );
                      },
                      onChanged: (value) {
                        onChangePrice( value, widget, payment, controller );
                        /* Payment? exist = widget.carrello.getPayments.firstWhereOrNull((p) => p.idPayment == payment.id);
                        double value_  = double.tryParse(value.replaceAll(',', '.')) ?? 0.0; // [NEW] tryParse più sicuro
                        if (exist != null) {
                          widget.carrello.removePayment(exist);
                          widget.carrello.addPayment(Payment(title: payment.title, tend: payment.tend ?? 1, idPayment: payment.id, amount: value_));
                        } else {
                          widget.carrello.addPayment(Payment(title: payment.title, tend: payment.tend ?? 1, idPayment: payment.id, amount: value_));
                        }
                        double totalPaid = widget.carrello.totalWithTipsAndDiscount;
                        double totalOthersPayment = widget.carrello.getPayments.fold<double>(
                          0, (prev, element) {
                            if (element.idPayment == payment.id) return prev;
                            return prev + element.amount;
                          },
                        );
                        if (value_ + totalOthersPayment > totalPaid) {
                          Payment? pay_ = widget.carrello.getPayments.firstWhereOrNull((p) => p.idPayment == payment.id);
                          if (pay_ == null) return;
                          widget.carrello.removePayment(pay_);
                          widget.carrello.getPayments.add(Payment(title: payment.title, tend: payment.tend ?? 1, idPayment: payment.id, amount: totalPaid - totalOthersPayment));
                          controller.text = (totalPaid - totalOthersPayment).toStringAsFixed(2);
                        }
                        debugPrint(widget.carrello.getPayments.map((e) => e.amount).toList().toString());
                        widget.carrello.notifyListeners(); // [NEW] aggiunto */
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        hintText: "0",
                        hintStyle: TextStyle(
                          color: isDark ? scheme.onSurface.withOpacity(0.6) : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: scheme.outline.withOpacity(0.35)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: attivo ? Colors.white : scheme.primary,
                            width: 1.2,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: attivo ? Colors.white : scheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  final carrello = context.read<CarrelloController>();
                  setState(() {
                    ctrModuloPagamento.paymentsSelected.remove(payment.id); // [NEW] aggiunto
                    carrello.setPayments(carrello.getPayments.where((pp) => pp.idPayment != payment.id).toList());
                    controller.clear();
                  });
                  carrello.notifyListeners(); // [NEW] aggiunto
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // ATTORI PAGAMENTO
  // -----------------------------------------------------------
  Widget _selettoreAttori( ThemeData theme ) {
    const attori = ["POS", "JustEat", "Glovo", "UberEats"];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        children: attori.map((a) {
          final selected = attoreSelezionato == a;
          return ChoiceChip(
            label: Text(a),
            selected: selected,
            onSelected: (_) => setState(() => attoreSelezionato = a),
          );
        }).toList(),
      ),
    );
  }

  // -----------------------------------------------------------
  // RIGA SPLIT PAYMENT
  // -----------------------------------------------------------
  Widget _rigaSplit(String label, String valore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(valore, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // MODALE DATI PA (centrale)
  // -----------------------------------------------------------
  Future<Map<String, String>?> mostraDatiSplitPayment(BuildContext context) async {
    final idDocumentoCtrl = TextEditingController();
    final cupCtrl = TextEditingController();
    final cigCtrl = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Dati ordine di acquisto",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: idDocumentoCtrl, decoration: const InputDecoration(labelText: "Id Documento")),
                  const SizedBox(height: 12),
                  TextField(controller: cupCtrl, decoration: const InputDecoration(labelText: "Codice CUP")),
                  const SizedBox(height: 12),
                  TextField(controller: cigCtrl, decoration: const InputDecoration(labelText: "Codice CIG")),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text("ANNULLA"),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context, {"idDocumento": "", "cup": "", "cig": ""}),
                        child: const Text("SALTA"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          "idDocumento": idDocumentoCtrl.text,
                          "cup": cupCtrl.text,
                          "cig": cigCtrl.text,
                        }),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


// -----------------------------------------------------------
// [NEW] TicketModal — nuova classe aggiunta
// -----------------------------------------------------------
class TicketModal extends StatefulWidget {
  const TicketModal({super.key});

  @override
  State<TicketModal> createState() => _TicketModalState();
}

class _TicketModalState extends State<TicketModal> {
  final Color verde = const Color(0xFF95C01F);

  final TextEditingController numeroCtrl  = TextEditingController();
  final TextEditingController importoCtrl = TextEditingController();

  final FocusNode focusNumero  = FocusNode();
  final FocusNode focusImporto = FocusNode();

  List<double> tagli   = [2, 5, 7, 8];
  Map<double, int> quantita = {};

  @override
  void initState() {
    super.initState();
    for (var t in tagli) {
      quantita[t] = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNumero.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF121212) : Colors.white;
    final card   = isDark
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(.35)
        : Colors.grey.shade100;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: 600,
        width: 700,
        child: Column(
          children: [

            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: verde,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Inserisci ticket",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    // INPUT N° TICKETS + IMPORTO UNITARIO
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: numeroCtrl,
                            focusNode: focusNumero,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: "N° tickets",
                              filled: true,
                              fillColor: card,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: importoCtrl,
                            focusNode: focusImporto,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: "Importo unitario",
                              filled: true,
                              fillColor: card,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // TAGLI
                    Expanded(
                      child: ListView(
                        children: tagli.map((taglio) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "€ ${taglio.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if ((quantita[taglio] ?? 0) > 0) quantita[taglio] = (quantita[taglio] ?? 0) - 1;
                                        });
                                      },
                                      icon: const Icon(Icons.remove_circle_outline),
                                    ),
                                    Text(
                                      "${quantita[taglio] ?? 0}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          quantita[taglio] = (quantita[taglio] ?? 0) + 1;
                                        });
                                      },
                                      icon: Icon(Icons.add_circle_outline, color: verde),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // FOOTER — CONFERMA
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    // TODO: logica conferma ticket
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Conferma",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


void onChangePrice(String value, ModuloPagamenti widget, PaymentModel payment, TextEditingController controller){
  Payment? exist = widget.carrello.getPayments.firstWhereOrNull((p) => p.idPayment == payment.id);
  double value_  = double.tryParse(value.replaceAll(',', '.')) ?? 0.0; // [NEW] tryParse più sicuro
  if (exist != null) {
    widget.carrello.removePayment(exist);
    widget.carrello.addPayment(Payment(title: payment.title, tend: payment.tend ?? 1, idPayment: payment.id, amount: value_));
  } else {
    widget.carrello.addPayment(Payment(title: payment.title, tend: payment.tend ?? 1, idPayment: payment.id, amount: value_));
  }
  double totalPaid = widget.carrello.totalWithTipsAndDiscount;
  double totalOthersPayment = widget.carrello.getPayments.fold<double>(
    0, (prev, element) {
      if (element.idPayment == payment.id) return prev;
      return prev + element.amount;
    },
  );
  /* if (value_ + totalOthersPayment > totalPaid) {
    Payment? pay_ = widget.carrello.getPayments.firstWhereOrNull((p) => p.idPayment == payment.id);
    if (pay_ == null) return;
    widget.carrello.removePayment(pay_);
    widget.carrello.getPayments.add(Payment(title: payment.title, tend: payment.tend ?? 1, idPayment: payment.id, amount: totalPaid - totalOthersPayment));
    controller.text = (totalPaid - totalOthersPayment).toStringAsFixed(2);
  } */
  debugPrint(widget.carrello.getPayments.map((e) => e.amount).toList().toString());
  widget.carrello.notifyListeners(); // [NEW] aggiunto
}
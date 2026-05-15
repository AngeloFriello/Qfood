import 'dart:convert';
import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/modelli/vatRate.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/material.dart';
import 'package:dashboard/config/tema_app.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../state/controller_carrello.dart';

class ModuloOpzioni extends StatefulWidget {
  const ModuloOpzioni({super.key});

  @override
  State<ModuloOpzioni> createState() => _ModuloOpzioniState();
}

class _ModuloOpzioniState extends State<ModuloOpzioni> {
  int tipoSconto = 0; // 0 = importo, 1 = valore, 2 = percentuale

  final TextEditingController importoCtrl  = TextEditingController(text: "0");
  final TextEditingController valoreCtrl   = TextEditingController(text: "0");
  final TextEditingController percentoCtrl = TextEditingController(text: "0");
  double mancia = 0.0;
  double totale = 0.0;
  double daPagare = 0.0;
  double scontoValore = 0.0;
  bool venditaDaTavolo = false;   // true = tavolo, false = banco
  int  copertiTavolo = 1;        // arriva dal tavolo
  final FocusNode numeroPersoneFocus = FocusNode();
  bool dividiPerAbilitato = true;
  final TextEditingController numeroPersoneCtrl = TextEditingController(text: "");

  double get totalePerPersona {
    final n = int.tryParse(numeroPersoneCtrl.text) ?? 1;
    if (n <= 0) return daPagare;
    return daPagare / n;
  }

  Future<void> setFirstTotalCash () async {
    final crtModuloPagamenti = context.read<ControllerModuloPagamenti>();
    crtModuloPagamenti.setFirstTotalForCaschAndResetOthersPayments(context);
  }


  @override
  void initState() {
    setFirstTotalCash();
    final carrello = context.read<CarrelloController>();
    double corver = carrello.coperti();
    if( corver == 0 ) numeroPersoneCtrl.text = '1';
    if( corver > 0 )  numeroPersoneCtrl.text = corver.toString();
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return LayoutBuilder( builder: (context, constraints){
      final width = constraints.maxWidth;

        /// 🔥 SOLO DESKTOP
        final bool isDesktop = width >= 1200;

        /// Boost forte solo desktop
        final double desktopFontBoost = isDesktop ? 1.35 : 1.0;
        double scale;

        if (width >= 1400) {
          scale = 1.20;        // desktop grande
        } else if (width >= 1200) {
          scale = 1.10;        // desktop normale
        } else if (width >= 800) {
          scale = 0.85;        // tablet compatto
        } else {
          scale = 0.75;        // mobile
        }


        double totaleFontBoost = 1.0;

        if (width >= 1200) {
          totaleFontBoost = 1.0 + ((width - 1200) / 2500);
        }

        double s(double v) => v * scale;


        final double desktopBoost = isDesktop ? 1.15 : 1.15;


        final theme = Theme.of(context);
        final carrello = context.watch<CarrelloController>();
        final crtModuloPagamenti = context.read<ControllerModuloPagamenti>();



    Widget boxValore(String label, String valore,{Color? bg, bool highlight = false}) {
      final bool isTotale = label == "Totale";
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg ??
                  theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
              borderRadius: BorderRadius.circular(s(14)),
              border: highlight
                  ? Border.all(
                color: TemaApp.verdeBrand,
                width: s(2.4),
              )
                  : null,
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyLarge),
            Text(
              valore,
              style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: theme.textTheme.bodyLarge!.fontSize! *
                        scale *
                        (isTotale ? totaleFontBoost : 1.1),
                  ),
            ),
          ],
        ),
      );
    }




    // ----------------------------------------------------
    //  LAYOUT COMPLETO
    // ----------------------------------------------------
    return SingleChildScrollView(
        padding: EdgeInsets.only(bottom: s(40)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // --------------------------------------------
        //  TOTALE / DA PAGARE / MANCIA / RESTO
        // --------------------------------------------
        Column(
          children: [
            boxValore(
              "Totale",
              "${carrello.totalCheckoutFinal.toStringAsFixed(2).replaceAll('.', ',')} €",
              bg: TemaApp.verdeBrand,
              highlight: true,
            ),


            const SizedBox(height: 3),
            boxValore(
              "Da pagare",
              "${carrello.totalWithTipsAndDiscount.toStringAsFixed(2).replaceAll('.', ',')} €",
            ),

            const SizedBox(height:3),

            GestureDetector(
              onTap: () async {
                await mostraPopupMancia(context, carrello, crtModuloPagamenti);
              },
              child: boxValore(
                "Mancia",
                "${carrello.tips.toStringAsFixed(2).replaceAll('.', ',')} €",
              ),
            ),
            const SizedBox(height: 3),

            GestureDetector(
              onTap: () async {
                await mostraPopupResto(context);
              },
              child: boxValore(
                "Contanti ricevuti", "${carrello.cashCustomer.toStringAsFixed(2).replaceAll('.', ',')} €",
              ),
            ),

            const SizedBox(height: 3),

            GestureDetector(
              onTap: () async {
              },
              child: boxValore(
                "Resto",
                "${carrello.remainder.toStringAsFixed(2).replaceAll('.', ',')} €",
              ),
            ),

          ],
        ),

        const SizedBox(height: 10),

        // --------------------------------------------
        //  SCONTI
        // --------------------------------------------
            ModuloScontoQFood(
              carello: carrello,
            ),

        const SizedBox(height: 10),

        // --------------------------------------------
        //  DIVIDI PER (CON FLAG)
        // --------------------------------------------


            Container(
              padding: EdgeInsets.all(s(5)),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
                borderRadius: BorderRadius.circular(s(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Abilita divisione conto",
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Switch(
                        value: dividiPerAbilitato,
                        onChanged: (v) {
                          setState(() {
                            dividiPerAbilitato = v;

                            if (v) {
                              double covers = carrello.coperti();
                              numeroPersoneCtrl.text = (covers == 0 ? 1 : covers).toString();
                            } else {
                              numeroPersoneCtrl.clear();
                            }
                          });

                          if (v) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;

                              FocusScope.of(context).requestFocus(numeroPersoneFocus);

                              numeroPersoneCtrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: numeroPersoneCtrl.text.length,
                              );
                            });
                          }
                        },
                      ),

                    ],
                  ),

                  if (dividiPerAbilitato) const SizedBox(height: 2),

                  if (dividiPerAbilitato)
                    Row(
                      children: [
                        /// NUMERO PERSONE (SINISTRA)
                        SizedBox(
                          width: s(140),
                          child: TextField(
                            focusNode: numeroPersoneFocus,
                            controller: numeroPersoneCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (v) {
                              final n = int.tryParse(v) ?? 1;
                              if (n < 1) {
                                numeroPersoneCtrl.text = "1";
                                numeroPersoneCtrl.selection = TextSelection.fromPosition(
                                  const TextPosition(offset: 1),
                                );
                              }
                              setState(() {});
                            },

                            decoration: InputDecoration(
                              labelText: "N° Pers.",
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: s(12),
                                  horizontal: s(12),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(s(14)),
                                ),
                            ),
                          ),
                        ),

                        SizedBox(width: s(2)),

                        /// TOTALE PER PERSONA (DESTRA)
                        Expanded(
                          child: Container(
                            height: s(56),
                            padding: EdgeInsets.symmetric(horizontal: s(16)),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(s(14)),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Quota",
                                  style: theme.textTheme.bodyLarge,
                                ), 
                                Text(
                                  "${(carrello.totalWithTipsAndDiscount / double.parse(numeroPersoneCtrl.text == '' ? '1' : numeroPersoneCtrl.text) ).toStringAsFixed(2).replaceAll('.', ',')} €",
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
      ],
    )
    );
    });


  }




  Future<void> mostraPopupMancia(BuildContext context, CarrelloController carrello, ControllerModuloPagamenti crtModuloPagamenti ) async {
    final ctrl = TextEditingController();
    final focusText = FocusNode();
    focusText.requestFocus();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 550,
              minWidth: 400,
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Seleziona la mancia",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    focusNode:focusText ,
                    controller: ctrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Mancia libera",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async  {
                            //PER LA MANCIA AGGIUNGIAMO UN ARTICOLO CON ALIQUOTA A 0
                            final articleGeneric_             = await getGenericProduct();
                            final vatRateZeroResp             = await LocalDB.query('SELECT * FROM vatRates WHERE value = "0.00"');
                            List<VatRateModel> vatRates       = vatRateZeroResp.map((v) => VatRateModel.fromJson(v)).toList();
                            if( articleGeneric_ == null || vatRates.isEmpty ) return;
                            carrello.setTips(0);
           
                            final ctrCart =  context.read<CarrelloController>();
                            
                            //SE MANCIA ESISTE LO AGGIORNO ALTRIMENTI LO AGGIUNGO
                            ProdottoCarrello? exist = ctrCart.prodotti.firstWhereOrNull((p) => p.article.title == 'Mancia');
                            if( exist != null ){
                              ctrCart.removeArticleByUuid(uuid: exist.uuid);
                            }
                            
                            crtModuloPagamenti.setFirstTotalForCaschAndResetOthersPayments(context);

                            //AGGIORNA RESTO
                            if( ctrCart.ricevuto >=  ctrCart.totalWithTipsAndDiscount) ctrCart.setRemainder(ctrCart.ricevuto - ctrCart.totalWithTipsAndDiscount);
                            Navigator.pop(context);
                          },
                          child: const Text("Nessuna mancia"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: ()  async  {
                            Navigator.pop(context);
                          },
                          child: const Text("Annulla"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async  {
                            //PER LA MANCIA AGGIUNGIAMO UN ARTICOLO CON ALIQUOTA A 0
                            final articleGeneric_             = await getGenericProduct();
                            final vatRateZeroResp             = await LocalDB.query('SELECT * FROM vatRates WHERE value = "0.00"');
                            List<VatRateModel> vatRates       = vatRateZeroResp.map((v) => VatRateModel.fromJson(v)).toList();
                            if( articleGeneric_ == null || vatRates.isEmpty ) return;
                            carrello.setTips(double.parse(ctrl.text));
                            ArticleWhitPriceListModel articleTips = ArticleWhitPriceListModel(
                                                                                                articleType: ArticleType.product,code: articleGeneric_['code'],
                                                                                                id:        articleGeneric_['id'],
                                                                                                title:     'Mancia',
                                                                                                idVatRate: vatRates[0].id,
                                                                                                rateValue: vatRates[0].value
                                                                                              );
                            final ctrCart =  context.read<CarrelloController>();
                            
                            //SE MANCIA ESISTE LO AGGIORNO ALTRIMENTI LO AGGIUNGO
                            ProdottoCarrello? exist = ctrCart.prodotti.firstWhereOrNull((p) => p.article.title == 'Mancia');
                            if( exist == null ){
                              ctrCart.addArticleInCart( articleTips , 1, double.parse(ctrl.text), false);
                            }else{
                              ctrCart.upgradePriceRowCart(exist.uuid, double.parse(ctrl.text));
                            }
                            crtModuloPagamenti.setFirstTotalForCaschAndResetOthersPayments(context);
                            //AGGIORNA RESTO
                            if( ctrCart.ricevuto >=  ctrCart.totalWithTipsAndDiscount) ctrCart.setRemainder(ctrCart.ricevuto - ctrCart.totalWithTipsAndDiscount);
                            Navigator.pop(context);
                          },
                          child: const Text("OK"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> mostraPopupResto( BuildContext context ) async {
    final ricevutoCtrl = TextEditingController();
    final carrello = context.read<CarrelloController>();
    double totale = carrello.totaleCarrello - carrello.discount + carrello.tips;
    
    void aggiornaResto() {
      double ricevuto = double.tryParse(ricevutoCtrl.text.replaceAll(",", ".")) ?? 0.0;

      //AGGIORNA RESTO
      if( ricevuto >=  totale ) carrello.setRemainder( ricevuto - totale );
      carrello.setRicevuto(ricevuto);
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 650,
                minWidth: 500,
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const BackButton(),
                        const Spacer(),
                        Text(
                          "Totale € ${totale.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ricevutoCtrl,
                            onChanged: (v) {
                              setState(() {
                                if( v == '') return;
                                carrello.cashCustomer = double.parse(v);
                                aggiornaResto();
                              });
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Contanti ricevuti",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black12,
                          ),
                          child: Column(
                            children: [
                              const Text("Resto"),
                              Text(
                                "€${carrello.remainder.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    Wrap(
                      spacing:    10,
                      runSpacing: 10,
                      children:   [ "5", "10", "20", "50", "100", "200", "500", "2", "1", "0.50", "0.20", "0.10", "0.05", "0.02", "0.01" ].map((txt) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 14),
                          ),
                          onPressed: () {
                            setState(() {
                              if( txt == '') return;
                              ricevutoCtrl.text = txt.replaceAll(",", ".");
                              carrello.cashCustomer = double.parse(txt);
                              aggiornaResto();
                            });
                          },
                          child: Text("$txt €"),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text("Annulla"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, {
                              "ricevuto": carrello.ricevuto,
                              "resto":    carrello.remainder,
                            }),
                            child: const Text("Conferma"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }



}

class ModuloScontoQFood extends StatefulWidget {
  final CarrelloController carello;

  const ModuloScontoQFood({
    super.key,
    required this.carello,
  });

  @override
  State<ModuloScontoQFood> createState() => _ModuloScontoQFoodState();
}

class _ModuloScontoQFoodState extends State<ModuloScontoQFood> {

  ScontoTipo? tipo;
  final importoCtrl  = TextEditingController(text: "0");
  final valoreCtrl   = TextEditingController(text: "0");
  final percentoCtrl = TextEditingController(text: "0");

  final valoreCtrlMaggiorazione   = TextEditingController(text: "0");
  final percentoCtrlMaggiorazione  = TextEditingController(text: "0");

  FocusNode focusScontoImporto = FocusNode();
  FocusNode focusValore = FocusNode();
  FocusNode focusPercent = FocusNode();

  FocusNode focusValoreMaggiorazione = FocusNode();
  FocusNode focusPercentMaggiorazione  = FocusNode();

  double importo = 0.0;
  double percentuale = 0.0;
  bool scontoApplicato = false;
  bool isMaggiorazione = false;
  List<double> rapidDiscount = [];

   @override
    void initState() {
      super.initState();
      setRapidDiscount();
      tipo = widget.carello.discountType;
      importoCtrl.clear();
      valoreCtrl.clear();
      percentoCtrl.clear();
      switch (widget.carello.discountType) {
        case ScontoTipo.importo:
          valoreCtrl.text = widget.carello.discount.toStringAsFixed(2);
        break;
        case ScontoTipo.totale:
          importoCtrl.text = (widget.carello.totaleCarrello - widget.carello.discount).toStringAsFixed(2);
          break;
        case ScontoTipo.percentuale:
          percentoCtrl.text = ( (widget.carello.discount / widget.carello.totaleCarrello ) * 100 ).toStringAsFixed(2);
        break;
        default:
      }

      focusScontoImporto.addListener( ()
        {
          if (!focusScontoImporto.hasFocus) {
              final  carrello = context.read<CarrelloController>();
               final ctrModuloPagamento = context.read<ControllerModuloPagamenti>();
              // CONTROLLO SCONTO MASSIMO ABILITATO PER L'operatore loggato
              bool discountOk = OperatoreModel.checkDiscountMaximim(
                                                              carrello.totaleCarrello,
                                                              ScontoTipo.totale,
                                                              importoCtrl.text,
                                                              operatorLogged!.maximumDiscount
                                                            );
              if( discountOk == false ){
                importoCtrl.text = "0";
                carrello.resetDiscount();
                return;
              };

               carrello.applyDiscount(importoCtrl.text, ScontoTipo.totale, ctrModuloPagamento, context);

            }
        }
      );

      focusScontoImporto.addListener(() => setState(() {}));
      focusValore.addListener(() => setState(() {}));
      focusPercent.addListener(() => setState(() {}));

    }

  @override
  void dispose() {
    focusScontoImporto.dispose();
    super.dispose();
  }


  //segue il pallino al textbox quando premo
  void selectTipo(ScontoTipo t) {
    setState(() {
      tipo = t;
    });
  }

  void resetDiscount (ScontoTipo tipo_, ControllerModuloPagamenti ctrModuloPagamento) {
    widget.carello.resetDiscount();
    importoCtrl.clear();
    valoreCtrl.clear();
    percentoCtrl.clear();
    tipo = tipo_;
    ctrModuloPagamento.setFirstTotalForCaschAndResetOthersPayments(context);

    final cart = context.read<CarrelloController>();
    if( cart.cashCustomer >= cart.totalWithTipsAndDiscount ) cart.setRemainder( cart.cashCustomer - cart.totalWithTipsAndDiscount );
  }

  // 🎨 Colori QFood con supporto light/dark
  Color get verdeQ => const Color(0xFF7AF28B);
  Color get grigioBox => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2A2A2A)
      : const Color(0xFFF7F7EB);

  Color get inputColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF3C3C3C)
      : const Color(0xFFF5F5EB);

  Color get borderColor =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white12
          : Colors.black12;

  Color get textColor => Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

  double calcolaImporto(double p) => 0; //widget.totale * p / 100;

  // 🔥 Aggiorna UI dopo calcoli
  void aggiornaUI() {
    valoreCtrl.text = "${importo.toStringAsFixed(2)} €";
    importoCtrl.text = "${importo.toStringAsFixed(2)} €";
    percentoCtrl.text = "${percentuale.toStringAsFixed(0)} %";
    setState(() {});
  }



  void aggiornaDaPercentuale() {
    importo = calcolaImporto(percentuale);
    aggiornaUI();
  }

  bool isFocused(FocusNode node) => node.hasFocus;

  InputDecoration dec(FocusNode node, bool isSelected) {
    return InputDecoration(
      filled: true,
      fillColor: isSelected ? Colors.white : inputColor,
      hintStyle: TextStyle(
        color: isSelected ? Colors.black54 : Colors.grey,
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white, width: 1.5),
      ),
    );
  }


  Future<void> setRapidDiscount () async {
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      if( pref != null ){
        final settingStore = jsonDecode(pref.getString('settingStore') ?? '{}');
        if( settingStore != null ){
        (settingStore['rapidDiscountString'] as String ).split(',').forEach((d) => rapidDiscount.add(double.parse(d)));
          setState(() {
            
          }); 
        }
      }

    }catch( err ){

    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder:(context, constraints) {
      final isTablet = MediaQuery.of(context).size.width > 900;
      final carrello = context.watch<CarrelloController>();
      final ctrModuloPagamento = context.watch<ControllerModuloPagamenti>();
      final width = constraints.maxWidth;
      final bool isCompact = width < 1100;

      if( carrello.tipoMaggiorazione == ScontoTipo.importo ){
        carrello.percentualevaloreMaggiorazione = 0;
        ProdottoCarrello? p = carrello.prodotti.firstWhereOrNull((p) => p.article.title == ' Maggiorazione ');
        if( p != null && p.priceRowCart != double.tryParse(valoreCtrlMaggiorazione.text) ){
          valoreCtrlMaggiorazione.text = p.priceRowCart.toString();
        }
      }

      if( carrello.tipoMaggiorazione == ScontoTipo.percentuale ){
        if( double.tryParse(percentoCtrlMaggiorazione.text ) != carrello.percentualevaloreMaggiorazione ){
          percentoCtrlMaggiorazione.text = carrello.percentualevaloreMaggiorazione == 0 ? '' : carrello.percentualevaloreMaggiorazione.toString();
        } 
        
        /* ProdottoCarrello? p = carrello.prodotti.firstWhereOrNull((p) => p.article.title == ' Maggiorazione ');
        double totalCart  = carrello.totaleCarrello;
        double? value = double.tryParse(percentoCtrlMaggiorazione.text);
        if( p != null && value != null ){
          double totalPercentage = double.parse( (( totalCart / 100 ) * value).toStringAsFixed(2));

        } */
      }

      return AbsorbPointer(
        absorbing: operatorLogged != null && operatorLogged!.enableDiscount == 0,
        child: Container(
        decoration: BoxDecoration(
          color: grigioBox,
          borderRadius:  BorderRadius.circular(
                  isCompact ? 7 : 7), // desktop = 24 (originale)
              border: Border.all(color: borderColor, width: 1),
        ),
        padding: EdgeInsets.symmetric(
            vertical: isCompact ? 10 : 32,  // desktop = 32 (originale)
            horizontal: isCompact ? 10 : 32, // desktop = 32 (originale)
        ),

        child: 
        
        isMaggiorazione ? 
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------- TITOLO
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Opzioni",
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 14 : 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => isMaggiorazione = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isMaggiorazione ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Sconto"),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => isMaggiorazione = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isMaggiorazione ? Colors.orange : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Maggiorazione"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            SizedBox(height: isCompact ? 10 : 12),

            // -------------------------------------------------- VALORE (sempre readonly)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                      carrello.setTipoMaggiorazione(ScontoTipo.importo);
                      carrello.rimuoviMaggiorazione(context);
                      percentoCtrlMaggiorazione.text = '';
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                        FocusScope.of(context).requestFocus(focusValoreMaggiorazione);
                      });
              },
              child: Row(
                children: [
                  Radio(
                    value: ScontoTipo.importo,
                    groupValue: carrello.tipoMaggiorazione,
                    onChanged: (_) {
                      carrello.setTipoMaggiorazione(ScontoTipo.importo);
                      carrello.rimuoviMaggiorazione(context);
                      percentoCtrlMaggiorazione.text = '';
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                        FocusScope.of(context).requestFocus(focusValoreMaggiorazione);
                      });
                    },
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      "Valore",
                      style: TextStyle(
                        color: textColor,
                        fontSize: isCompact ? 14 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: isCompact ? 44 : 52,
                      child: TextField(
                        focusNode:  focusValoreMaggiorazione,
                        controller: valoreCtrlMaggiorazione, 
                        enabled:    carrello.tipoMaggiorazione == ScontoTipo.importo,
                        textAlign:  TextAlign.right,
                        onTap: () {
                          carrello.setTipoMaggiorazione(ScontoTipo.importo);
                          percentoCtrlMaggiorazione.text = '';
                        },
                        style: TextStyle(
                          color: carrello.tipoMaggiorazione == ScontoTipo.importo
                              ? Colors.black
                              : textColor,
                          fontSize: isCompact ? 14 : 16,
                        ),

                        cursorColor: Colors.black,

                        decoration: dec(
                          focusValoreMaggiorazione,
                          carrello.tipoMaggiorazione == ScontoTipo.importo,
                        ),

                        onChanged: (v) {
                          carrello.maggiorazione(context, ScontoTipo.importo, v);
                        }
                        
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isCompact ? 10 : 12),

            // -------------------------------------------------- PERCENTUALE
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                carrello.setTipoMaggiorazione(ScontoTipo.percentuale);
                carrello.rimuoviMaggiorazione(context);
                valoreCtrlMaggiorazione.text = '';
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).requestFocus(focusPercentMaggiorazione);
                });
              },
              child: Row(
                children: [
                  Radio(
                    value: ScontoTipo.percentuale,
                    groupValue: carrello.tipoMaggiorazione,
                    onChanged: (value) {
                      carrello.setTipoMaggiorazione(ScontoTipo.percentuale);
                      carrello.rimuoviMaggiorazione(context);
                      valoreCtrlMaggiorazione.text = '';
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                        FocusScope.of(context).requestFocus(focusPercentMaggiorazione);
                      });
                    },
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      "Percent.",
                      style: TextStyle(
                        color: textColor,
                        fontSize: isCompact ? 14 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: isCompact ? 44 : 52,
                      child: TextField(
                        focusNode: focusPercentMaggiorazione,
                        controller: percentoCtrlMaggiorazione,
                        enabled: carrello.tipoMaggiorazione == ScontoTipo.percentuale,
                        textAlign: TextAlign.right,
                        onTap: () {
                          
                        },
                        style: TextStyle(
                          color: carrello.tipoMaggiorazione == ScontoTipo.percentuale
                              ? Colors.black
                              : textColor,
                          fontSize: isCompact ? 14 : 16,
                        ),
                        cursorColor: Colors.black,
                        decoration: dec(
                          focusPercentMaggiorazione,
                          carrello.tipoMaggiorazione == ScontoTipo.percentuale,
                        ),
                        onChanged: (v) {
                          carrello.maggiorazione(context, ScontoTipo.percentuale, v);
                        }
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        
        : 

        //COLONNA SCONTO
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------- TITOLO
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Opzioni",
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 14 : 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => isMaggiorazione = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isMaggiorazione ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Sconto"),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => isMaggiorazione = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isMaggiorazione ? Colors.orange : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Maggiorazione"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

          // -------------------------------------------------- IMPORTO
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                tipo = ScontoTipo.totale;
                resetDiscount(ScontoTipo.totale, ctrModuloPagamento);
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                FocusScope.of(context).requestFocus(focusScontoImporto);
              });
            },
            child: Row(
              children: [
                Radio<ScontoTipo>(
                  value: ScontoTipo.totale,
                  groupValue: tipo,
                  onChanged: scontoApplicato
                      ? null
                      : (_) {
                    setState(() {
                      tipo = ScontoTipo.totale;
                      resetDiscount( ScontoTipo.totale, ctrModuloPagamento );
                    });
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                      FocusScope.of(context).requestFocus(focusScontoImporto);
                    });
                  },
                ),

                SizedBox(
                  width: 90,
                  child: Text(
                    "Importo",
                    style: TextStyle(
                      color: textColor,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                ),
                SizedBox(
                  height: isCompact ? 44 : 52, // desktop = 52
                  width: 12),
                Expanded(
                  child: SizedBox(
                    height: isCompact ? 44 : 52, // desktop = 52
                    child: TextField(
                      focusNode: focusScontoImporto,
                      controller: importoCtrl,
                      enabled: tipo == ScontoTipo.totale,
                      textAlign: TextAlign.right,
                      onTap: () {
                        setState(() {
                          tipo = ScontoTipo.totale;
                          resetDiscount(ScontoTipo.totale, ctrModuloPagamento);
                        });
                      },

                      onChanged: (v) {
                        if (v.trim().isEmpty) {
                          carrello.resetDiscount();
                          ctrModuloPagamento.setFirstTotalForCaschAndResetOthersPayments(context);
                          return;
                        }                       
                          carrello.applyDiscount(
                            v,
                            ScontoTipo.totale,
                            ctrModuloPagamento,
                            context,
                          );
                        
                      },

                      style: TextStyle(
                        color: tipo == ScontoTipo.totale ? Colors.black : textColor,
                        fontSize: isCompact ? 14 : 16,
                      ),

                      cursorColor: Colors.black,

                     decoration: dec(focusScontoImporto, tipo == ScontoTipo.totale),

                    )
                  ),
                ),
              ],
            ),
          ),

            SizedBox(height: isCompact ? 10 : 12),

            // -------------------------------------------------- VALORE (sempre readonly)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  tipo = ScontoTipo.importo;
                  resetDiscount(ScontoTipo.importo, ctrModuloPagamento);
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).requestFocus(focusValore);
                });
              },
              child: Row(
                children: [
                  Radio(
                    value: ScontoTipo.importo,
                    groupValue: tipo,
                    onChanged: scontoApplicato
                        ? null
                        : (_) {
                      setState(() {
                        tipo = ScontoTipo.importo;
                        resetDiscount(ScontoTipo.importo, ctrModuloPagamento);
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        FocusScope.of(context).requestFocus(focusValore);
                      });
                    },
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      "Valore",
                      style: TextStyle(
                        color: textColor,
                        fontSize: isCompact ? 14 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: isCompact ? 44 : 52,
                      child: TextField(
                        focusNode: focusValore,
                        controller: valoreCtrl,
                        enabled: tipo == ScontoTipo.importo,
                        textAlign: TextAlign.right,

                        onTap: () {
                          setState(() {
                            tipo = ScontoTipo.importo;
                            resetDiscount(ScontoTipo.importo, ctrModuloPagamento);
                          });
                        },

                        style: TextStyle(
                          color: tipo == ScontoTipo.importo
                              ? Colors.black
                              : textColor,
                          fontSize: isCompact ? 14 : 16,
                        ),

                        cursorColor: Colors.black,

                        decoration: dec(
                          focusValore,
                          tipo == ScontoTipo.importo,
                        ),

                        onChanged: (v) {
                          if (v.trim().isEmpty) {
                            carrello.resetDiscount();
                            ctrModuloPagamento.setFirstTotalForCaschAndResetOthersPayments(context);
                            return;
                          }

                          double valore = double.tryParse(v.replaceAll(",", ".")) ?? 0;

                         
                            bool discountOk =
                            OperatoreModel.checkDiscountMaximim(
                              carrello.totaleCarrello,
                              ScontoTipo.importo,
                              v,
                              operatorLogged!.maximumDiscount,
                            );

                            if (!discountOk) {
                              valoreCtrl.text = "0";
                              return;
                            }

                            carrello.applyDiscount(
                              v,
                              ScontoTipo.importo,
                              ctrModuloPagamento,
                              context,
                            );
                          }
                        
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isCompact ? 10 : 12),

            // -------------------------------------------------- PERCENTUALE
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  tipo = ScontoTipo.percentuale;
                  resetDiscount(ScontoTipo.percentuale, ctrModuloPagamento);
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).requestFocus(focusPercent);
                });
              },
              child: Row(
                children: [
                  Radio(
                    value: ScontoTipo.percentuale,
                    groupValue: tipo,
                    onChanged: scontoApplicato
                        ? null
                        : (_) => {
                          setState(() =>
                        resetDiscount(ScontoTipo.percentuale, ctrModuloPagamento)),
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).requestFocus(focusPercent);
                        })
                        }
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      "Percent.",
                      style: TextStyle(
                        color: textColor,
                        fontSize: isCompact ? 14 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: isCompact ? 44 : 52,
                      child: TextField(
                        focusNode: focusPercent,
                        controller: percentoCtrl,
                        enabled: tipo == ScontoTipo.percentuale,
                        textAlign: TextAlign.right,

                        onTap: () {
                          setState(() {
                            tipo = ScontoTipo.percentuale;
                            resetDiscount(ScontoTipo.percentuale, ctrModuloPagamento);
                          });
                        },

                        style: TextStyle(
                          color: tipo == ScontoTipo.percentuale
                              ? Colors.black
                              : textColor,
                          fontSize: isCompact ? 14 : 16,
                        ),

                        cursorColor: Colors.black,

                        decoration: dec(
                          focusPercent,
                          tipo == ScontoTipo.percentuale,
                        ),

                        onChanged: (v) {
                          if (v.trim().isEmpty) {
                            carrello.resetDiscount();
                            ctrModuloPagamento
                                .setFirstTotalForCaschAndResetOthersPayments(context);
                            return;
                          }

                          double perc =
                              double.tryParse(v.replaceAll(",", ".")) ?? 0;

                          
                            bool discountOk = OperatoreModel.checkDiscountMaximim(
                              carrello.totaleCarrello,
                              ScontoTipo.percentuale,
                              v,
                              operatorLogged!.maximumDiscount,
                            );

                            if (!discountOk) {
                              percentoCtrl.text = "0";
                              return;
                            }

                            carrello.applyDiscount(
                              v,
                              ScontoTipo.percentuale,
                              ctrModuloPagamento,
                              context,
                            );
                          }
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isCompact ? 10 : 24),
          
            // -------------------------------------------------- PERCENTUALI RAPIDE
            Row(
              children: rapidDiscount.map((p) {

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () async {
                        bool confirm = await showConfermaDialogDiscount(context: context);
                        if( !confirm ) return;
                        importoCtrl.text = '';
                        valoreCtrl.text = '';
                        tipo = ScontoTipo.percentuale;
                        percentoCtrl.text = p.toString();
                        carrello.applyDiscount(p.toString(), ScontoTipo.percentuale,ctrModuloPagamento, context);
                        setState(() {

                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: percentoCtrl.text == p.toString() ? Colors.black : const Color(0xFF7A7A7A),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isCompact ? 2 : 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                        ),
                      ),
                      child: Text(
                        "$p%",
                        style: GoogleFonts.poppins(
                          fontSize: isCompact ? 14 : 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
            ),
      );
    },);

  }
}

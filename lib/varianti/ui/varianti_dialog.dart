import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/varianti/state/variants_controller.dart';
import 'package:dashboard/varianti/ui/varianti_libere_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/controller_carrello.dart';
import '../../ui/widget/tastiera_qwerty/tastiera_qwerty.dart';
import '../models/nota_predefinita.dart';

class VariantiDialog extends StatelessWidget {
  final ProdottoCarrello prodotto;
  final List<ArticleWhitPriceListModel> varianti;
  final List<NotaPredefinita> note;
  final List<ArticleWhitPriceListModel>? variantiIniziali;
  final inTable;
  final bool isEdit;

  const VariantiDialog({
    super.key,
    required this.prodotto,
    required this.varianti,
    required this.note,
    required this.inTable,
    this.variantiIniziali,
    this.isEdit = false, // default ADD
  });


  @override
  Widget build(BuildContext context) {
    final theme            = Theme.of(context);
    final isDark           = theme.brightness == Brightness.dark;


    return Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: SizedBox(
          width: 920,
          height: 740,
          child: Column(
            children: [
              _Header(isDark: isDark),
              const _Tabs(),
              _QuantitaBar(qtaInit: prodotto.quantity),
              const _SearchBar(),
              Expanded(
                child: Builder(
                  builder: ( context ) {
                    final ctrl = context.watch<VariantsController>();
                    if (ctrl.typeSelected == VariantsType.free) {
                      return const VariantiLibereSection();
                    }
                    return const _ListaVarianti();
                  },
                ),
              ),
              _Footer(
                carrello: context.read<CarrelloController>(),
                prodotto: prodotto,
                isEdit:  isEdit,
                inTable: inTable,
              ),
            ],
          ),
        ),
      );
  }
}



class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF8BC540),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          const Text(
            "Gestione Varianti",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}


class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<VariantsController>();

    Widget tab(String t, VariantsType tipo) {
      final attiva = ctrl.typeSelected == tipo;
      return Expanded(
        child: GestureDetector(
          onTap: () => {
            ctrl.setTab(tipo),
            ctrl.controllerSearch.clear()
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: attiva
                  ? const Color(0xFF6FAE32)
                  : const Color(0xFF8BC540),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: () {
              if (tipo == VariantsType.minus) {
                return const Icon(Icons.remove, color: Colors.white, size: 28);
              }

              if (tipo == VariantsType.plus) {
                return const Icon(Icons.add, color: Colors.white, size: 28);
              }

              if (tipo == VariantsType.plusMinus) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 24),
                    SizedBox(width: 4),
                    Icon(Icons.remove, color: Colors.white, size: 24),
                  ],
                );
              }

              return Text(
                t,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          tab("+/-", VariantsType.plusMinus),
          const SizedBox(width: 6),
          tab("+", VariantsType.plus),
          const SizedBox(width: 6),
          tab("-", VariantsType.minus),
          const SizedBox(width: 6),
          tab("Info", VariantsType.info),
          const SizedBox(width: 6),
          tab("Libere", VariantsType.free),
        ],
      ),
    );
  }
}


class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController searchCtrl = TextEditingController();
  final FocusNode searchFocus = FocusNode();


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vCtrl = context.watch<VariantsController>();


    /* // 🔄 sync visivo
    if (_ctrl.text != vCtrl.te) {
      _ctrl.text = vCtrl.filtro;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    } */

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child:
      TextField(
        controller: vCtrl.controllerSearch,
        onChanged:  vCtrl.setTitleFilter,
        decoration: InputDecoration(
          hintText: "Cerca",
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: theme.brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
  
  void _apriTastieraQwerty(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return QwertyKeyboard(
          controller: searchCtrl,
        );
      },
    );
  }
}

class _QuantitaBar extends StatelessWidget {
  final double qtaInit;
  const _QuantitaBar({required this.qtaInit});


  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<VariantsController>();
    

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: ctrl.setQuantityMinus,
            icon: const Icon(Icons.remove_circle, size: 32),
          ),
          Container(
            width: 60,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ctrl.quantity.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black   // numero scuro su box chiaro
                    : Colors.black,  // numero scuro anche in light
              ),
            ),

          ),
          IconButton(
            onPressed: ctrl.setQuantityPlus,
            icon: const Icon(Icons.add_circle, size: 32),
          ),
        ],
      ),
    );
  }
}

class _ListaVarianti extends StatelessWidget {
  const _ListaVarianti();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<VariantsController>();
    final typeSelected = ctrl.typeSelected;
    final variants = typeSelected  == VariantsType.plus      ? ctrl.variantsPlus
                   : typeSelected  == VariantsType.minus     ? ctrl.variantsMinus
                   : typeSelected  == VariantsType.plusMinus ? ctrl.variantsPlusMinus 
                   : typeSelected  == VariantsType.info      ? ctrl.variantsInfo
                   : [];
                   
    //  TAB LIBERE
    if (ctrl.typeSelected == VariantsType.free) {
      return const _ListaLibere();
    }

    // ALTRE TAB
    if (variants.isEmpty) {
      return const Center(child: Text("Nessuna variante"));
    }

    if (variants.isEmpty) {
      return const Center(child: Text("Nessuna variante"));
    }

    return ListView.builder(
      itemCount: variants.length,
      itemBuilder: (_, i) {
        ArticleWhitPriceListModel v        = variants[i];
        return InkWell(
          onTap: () {
            if( v.variationType == 'plus' ){
              ctrl.addInSelectedPlus(v);
            }

            if( v.variationType == 'minus'){
              ctrl.addInSelectedMinus(v);
            }

            if( v.variationType == 'info'){
              ctrl.addInSelectedInfo(v);
            }
          },
          child: ListTile(
            title: Text(v.title),
            leading: (v.variationType! == 'plus' || v.variationType! == 'info') ? SizedBox() :  InkWell(
              onTap: () => ctrl.addInSelectedMinus(v),
              child: Container(
                  child:   ctrl.variant_selected_minus.firstWhereOrNull((e) => e.id == v.id) != null
                  ? const Icon(Icons.remove_circle, color: Color.fromARGB(255, 255, 30, 0))
                  : const Icon(Icons.remove_circle, color: Color.fromARGB(255, 112, 112, 112)) ,
              ),
            ),
            trailing: v.variationType! == 'minus' ? Container() : InkWell(
              onTap: () => v.variationType == 'info' ? ctrl.addInSelectedInfo(v) : ctrl.addInSelectedPlus(v),
              child: Container(
              child:(v.variationType == 'info' ? ctrl.variant_selected_info.firstWhereOrNull((e) => e.id == v.id) != null :  ctrl.variant_selected_plus.firstWhereOrNull((e) => e.id == v.id) != null)
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.add_circle_outline),
            ))
          ),
        );
      },
    );
  }
}


class _ListaLibere extends StatefulWidget {
  const _ListaLibere();

  @override
  State<_ListaLibere> createState() => _ListaLibereState();
}

class _ListaLibereState extends State<_ListaLibere> {
  final nomeCtrl = TextEditingController();
  final prezzoCtrl = TextEditingController();
  FocusNode nomeFocus = FocusNode();
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<VariantsController>();

    
    return Column(
      children: [

        // ➕ INSERIMENTO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nomeCtrl,
                  focusNode: nomeFocus,
                  decoration: const InputDecoration(
                    hintText: "Nome",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: prezzoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Prezzo",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6EE7C2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final nome = nomeCtrl.text.trim();
                    final prezzo = double.tryParse(
                      prezzoCtrl.text.replaceAll(',', '.'),
                    );

                    if (nome.isEmpty || prezzo == null) return;

                    //ctrl.aggiungiLibera(nome, prezzo);
                    nomeCtrl.clear();
                    prezzoCtrl.clear();
                  },
                  child: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        // 📋 LISTA
        Expanded(
          child: ListView.builder(
            itemCount: ctrl.variants_selected_free.length,
            itemBuilder: (_, i) {
              final v = ctrl.variants_selected_free[i];
              return ListTile(
                title: Text(v.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text( v.price!.replaceAll('.', ','), ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => {}
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class _Footer extends StatelessWidget {
  final CarrelloController carrello;
  final ProdottoCarrello prodotto;
  final bool isEdit;
  final inTable;

  const _Footer({
    required this.carrello,
    required this.prodotto,
    required this.isEdit,
    required this.inTable
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC540),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(64), // 🔥 ALTEZZA FORZATA
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Annulla",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if( inTable ){
                  final ctrl     = context.read<VariantsController>();
                  final tab      = context.read<ControllerTableOpened>();
                  tab.upgradeVariantsRowTable(
                                                  ctrl.currentArticle!.uuid, 
                                                  ctrl.convertVariantForCart(ctrl.variants_selected_free,  'free'), 
                                                  ctrl.convertVariantForCart(ctrl.variant_selected_minus,  'minus'),
                                                  ctrl.convertVariantForCart(ctrl.variant_selected_plus,   'plus'),
                                                  ctrl.convertVariantForCart(ctrl.variant_selected_info,   'info'),
                                                  ctrl.quantity,
                                                  false
                                                );
                  Navigator.pop(context);
                  return;
                }
                final ctrl     = context.read<VariantsController>();
                final carrello = context.read<CarrelloController>();
                carrello.upgradeVariantsRowCart(
                                                ctrl.currentArticle!.uuid, 
                                                ctrl.convertVariantForCart(ctrl.variants_selected_free,  'free'), 
                                                ctrl.convertVariantForCart(ctrl.variant_selected_minus,  'minus'),
                                                ctrl.convertVariantForCart(ctrl.variant_selected_plus,   'plus'),
                                                ctrl.convertVariantForCart(ctrl.variant_selected_info,   'info'),
                                                ctrl.quantity,
                                                false
                                              );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC540),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(64), // 🔥 ALTEZZA FORZATA
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Conferma",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}


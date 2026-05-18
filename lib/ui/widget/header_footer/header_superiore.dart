import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/app/service/service_new_update.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/cartModelSaledSuspended.dart';
import 'package:dashboard/modelli/category.dart';
import 'package:dashboard/modelli/listPrice.dart';
import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/widget/header_footer/ControllerListPriceSelected.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/service/service_locator.dart';
import '../../../app/theme/controllers/theme_controller.dart';
import '../../../impostazioni/impostazioni/menu_utente.dart';
import '../../../state/controller_carrello.dart';
import '../../../state/banco_state.dart';
import '../../../state/controller_impostazioni.dart';
import '../../../state/product_search_controller.dart';
import '../../screen/checkout/checkout_salvato/suspended_checkout_popup.dart';
import '../../screen/checkout/cliente/InserisciClienteVista.dart';
import '../../screen/sincronizzazioni/operatori/operator_preferences_controller.dart';

class HeaderSuperiore extends StatefulWidget {
  final Function(ListPriceModel) onListPriceSelected;
  final bool mostraPulsanteBanco;
  final bool advancedEnabled;
  final ValueChanged<bool> onAdvancedModeChanged;
  final ListPriceModel? selected;
  final List<ListPriceModel> listListPrices;
  final Function setShowListDocuments;

  const HeaderSuperiore({
    super.key,
    this.mostraPulsanteBanco = false,
    required this.listListPrices,
    required this.advancedEnabled,
    required this.onAdvancedModeChanged,
    required this.onListPriceSelected,
    required this.selected,
    required this.setShowListDocuments
  });

  @override
  State<HeaderSuperiore> createState() => _HeaderSuperioreState();

  
}

class _HeaderSuperioreState extends State<HeaderSuperiore> {
  OverlayEntry? _menuOverlay;
  String valueRapidDiscount = '0';
  int _secretTapCount = 0;
  DateTime? _lastSecretTap;
  

  void rapidDiscount () async {
    try{
      SharedPreferences pref = await SharedPreferences.getInstance();
      final settingStore     = pref.getString('settingStore');
      if( settingStore == null ) return;
      final setting = jsonDecode(settingStore);
      setState(() {
        valueRapidDiscount = setting['rapidDiscountString'] == "" ? "0" : setting['rapidDiscountString'];
        if( 
          operatorLogged != null 
          && 
          operatorLogged!.rapidDiscountButtonPercentage != null 
          &&
          operatorLogged!.rapidDiscountButtonPercentage != ''
          &&
          operatorLogged!.rapidDiscountButtonPercentage != '0'
          ){
           valueRapidDiscount = operatorLogged!.rapidDiscountButtonPercentage!;
        }
       
      });
 
    }catch( err ){
      debugPrint( err.toString() );
    }
  }


  @override
  void initState() {
    super.initState();
    final themeController = serviceLocator<ThemeController>();
    /* themeController.setThemeMode(
                        operatorLogged!.useDarkMode == 1 ? ThemeMode.dark : ThemeMode.light,
                      ); */
    rapidDiscount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = serviceLocator<ThemeController>();
    final bool isLight = theme.brightness == Brightness.light;
    final ctrCart = context.watch<CarrelloController>();
    final imp = context.read<ImpostazioniController>();
    final op  = context.read<OperatorPreferencesController>();

    final newUpdate  = context.watch<ControllerLastUpdate>();
    
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isLight ? const Color(0xFF97D700) : const Color(0xFF1A1A1A),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 1400;
          final headerContent = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ---------------------------------------------------------
              // LOGO + THEME SWITCH + LISTINO + SCONTO
              // ---------------------------------------------------------
              Row(
                children: [
                  ElevatedButton(child: Text('test'), onPressed: () => testTotemOrderPost()),
                  Image.asset(
                    isLight ? 'assets/logosuverde.png' : 'assets/logodark.png',
                    height: 48,
                  ),
                  const SizedBox(width: 10),
                  Text(
                      "QFood",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  
                  if (widget.mostraPulsanteBanco)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                    ),
                  IconButton(
                    icon: Icon(
                      isLight
                          ? Icons.bedtime_outlined
                          : Icons.wb_sunny_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final bool newDarkMode = isLight;

                      themeController.setThemeMode(
                        newDarkMode ? ThemeMode.dark : ThemeMode.light,
                      );

                      //SALVA SU IMPOSTAZIONI
                      await imp.aggiorna('darkMode', newDarkMode);
                      
                      //SYNC CONTROLLER API
                      op.useDarkMode = newDarkMode;
                      op.notifyListeners();
                    },
                  ),
                  const SizedBox(width: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 86),
                    child: _pulsanteListino(context),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(width: 12),
                  _pulsanteScontoConAreaSegreta(theme),
                ],
              ),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _searchBar(),
              ),
              // ---------------------------------------------------------
              // PULSANTI DI DESTRA
              // ---------------------------------------------------------
              Row(
                children: [
                  _iconButton(
                      ctrCart: ctrCart,
                      icon: LucideIcons.utensils,
                      tooltip: "Trasferisci su Tavolo"),
                  _iconButton(
                      onTap: () => widget.setShowListDocuments(),
                      ctrCart: ctrCart,
                      icon: LucideIcons.receipt, tooltip: "Lista Vendite"),
                  InkWell(
                    onTap: () => noteCart(context) ,
                    child: _iconButton(ctrCart: ctrCart, icon: LucideIcons.pencil, tooltip: "Nota")
                  ),
                  _iconButton(
                    ctrCart: ctrCart,
                    icon:    LucideIcons.save,
                    tooltip: "Memorizza vendita sospesa",
                    onTap: () {
                      final carrello = ctrCart;
                      mostraSalvaCheckout(context, carrello);
                    },
                  ),
                  _iconButton(
                    ctrCart: ctrCart,
                    icon: LucideIcons.listRestart,
                    tooltip: "Recupera vendita sospesa",
                    onTap: () {
                      mostraListaCheckoutSalvati(context);
                    },
                  ),
                  _iconButton(
                    ctrCart: ctrCart,
                    icon: LucideIcons.trash2,
                    tooltip: "Cancella vendita totale",
                    onTap: () => _confermaEliminaCheckout(context),
                  ),
                  _iconButton(
                    ctrCart: ctrCart,
                    icon: LucideIcons.userPlus,
                    tooltip: "Inserisci cliente",
                    onTap: () {
                      apriPopupCliente();
                    },
                  ),
                  Badge(
                    isLabelVisible: newUpdate.newSync,
                    alignment: Alignment.bottomCenter,
                    label: Text("NEW"),
                    backgroundColor: Colors.red,
                      child: IconButton(
                      icon:  Icon(Icons.more_vert_rounded, color: Colors.white),
                      onPressed: () => _mostraMenuUtente(context),
                    ),
                  )
                  
                ],
              ),
            ],
          );

          // ==========================================================
          // MOBILE  → scroll orizzontale
          // DESKTOP → normale
          // ==========================================================
          return isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: headerContent,
                ),
                )
              : headerContent;
        },
      ),
    );
  }

  Widget _searchBar() {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 900 && width < 1200;
    final bool isMobile = width < 900;
    final search = context.watch<ProductSearchController>();

    final double height = isMobile
        ? 36
        : isTablet
        ? 38
        : 42;

    final double minWidth = isMobile
        ? 140
        : isTablet
        ? 170
        : 200;

    final double iconSize = isMobile
        ? 18
        : isTablet
        ? 20
        : 22;

    final double fontSize = isMobile
        ? 13
        : isTablet
        ? 14
        : 15;

    if( operatorLogged!.searchArticles == 0 ) return Container();

    return Container(
      height: 40,
      width: 40,
      constraints: BoxConstraints(minWidth: minWidth),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: search.crtBarSearch,
        onChanged: search.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Cerca...",
          hintStyle: TextStyle(fontSize: fontSize),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: iconSize,
            color: theme.colorScheme.onSurfaceVariant,
          ),

          //  pulsante X per pulire
          suffixIcon: search.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:() =>{
                    search.crtBarSearch.text = '',
                    search.setQuery(''),
                  } 
                )
              : null,
        ),
      ),
    );
  }

  void apriPopupCliente() {
    showDialog(
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
              onSelect: (cliente) {
                //  collega cliente al checkout
                context.read<CarrelloController>().setCliente(cliente);
                Navigator.pop(ctx); // chiude il dialog
              },
            ),
          ),
        );
      },
    );
  }

  void mostraListaCheckoutSalvati(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SuspendedCheckoutPopup(),
    );
  }

  void _toggleSconto() async {
    final carrello = context.read<CarrelloController>();
    final ctrlModuloPagamento = context.read<ControllerModuloPagamenti>();
 /*    if( carrello.discount == 0 ){
        bool confirm = await showConfermaDialogDiscount(context: context);
        if( !confirm ) return;
    }

    setState(() {
      
    }); */

    if (carrello.discount > 0) {
      carrello.resetDiscount();
    } else {
      carrello.applyDiscount( valueRapidDiscount, ScontoTipo.percentuale, ctrlModuloPagamento, context);
    } 
  }

  Future<bool?> _confermaEliminaCheckout(BuildContext context) async {
    final theme = Theme.of(context);
    final carrello = context.read<CarrelloController>();

    final bool? conferma = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          title: const Text("Attenzione"),
          content: const Text(
            "Sei sicuro di voler eliminare il checkout attuale?\n"
            "Questa operazione non può essere annullata.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annulla"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );

    if (conferma != true) return conferma;

    //  ELIMINA DAVVERO
    carrello.clearCart();
    
    //  FEEDBACK UX
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF95C01F), // ✅ VERDE QFOOD
        content: Row(
          children: const [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Checkout cancellato",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    return true;
  }

  Widget _pulsanteScontoConAreaSegreta(ThemeData theme) {
    return Row(
      children: [
        _pulsanteSconto20(theme),
        const SizedBox(width: 6),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleSecretTap,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            child: ValueListenableBuilder<bool>(
              valueListenable: bancoAbilitato,
              builder: (_, isBancoAttivo, __) {
                return isBancoAttivo
                    ? const Icon(
                        Icons.home,
                        color: Colors.white70,
                        size: 20,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showPasswordDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Inserisci pin"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: () async {
                if( operatorLogged == null) return;
                if (controller.text == operatorLogged!.trainingPin) {
                  bancoAbilitato.value = !bancoAbilitato.value;
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Conferma"),
            ),
          ],
        );
      },
    );
  }

  void _handleSecretTap() {
    final now = DateTime.now();

    if (_lastSecretTap == null ||
        now.difference(_lastSecretTap!) > const Duration(seconds: 2)) {
      _secretTapCount = 0;
    }

    _lastSecretTap = now;
    _secretTapCount++;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _showPasswordDialog();
    }
  }

  // ICON BUTTON STANDARD
  static Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required CarrelloController ctrCart,
    VoidCallback? onTap, // ✅ FIX
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap, // ✅ ORA ESISTE
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: icon == LucideIcons.save && ctrCart.cartSuspended  != null ? const Color.fromARGB(255, 255, 173, 20) : const Color(0xFFEFF0E3),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF2E3029),
          ),
        ),
      ),
    );
  }

  Widget _pulsanteSconto20(ThemeData theme) {
    final carrello = context.watch<CarrelloController>();
    final isActive = carrello.discount > 0;

    return (valueRapidDiscount == "0" || operatorLogged!.enableDiscount == 0 ) ? Container() : GestureDetector(
      onTap: _toggleSconto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.error
                : theme.dividerColor.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.percent,
              size: 18,
              color: isActive
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? "Annulla $valueRapidDiscount%" : "Sconto $valueRapidDiscount%",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }


void noteCart(BuildContext context) {
  final noteController = TextEditingController();
  final ctrCart = context.read<CarrelloController>();
  noteController.text = ctrCart.note;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 420,
            maxWidth: 600,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITOLO
                const Text(
                  "Inserisci nota",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // CAMPO TESTO — più alto
                TextField(
                  controller: noteController,
                  autofocus: true,
                  maxLines: 5,
                  minLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Nota",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // AZIONI
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Annulla"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        try {
                          //if (noteController.text.isEmpty) return;
                          ctrCart.setNote(noteController.text);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "Nota aggiunta",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: const Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (err) {
                          debugPrint(err.toString());
                        }
                      },
                      child: const Text("Salva"),
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

  void mostraSalvaCheckout(BuildContext context, CarrelloController carrello) {
    final noteController = TextEditingController();
    final ctrCart = context.read<CarrelloController>();

    if( ctrCart.cartSuspended != null ) setState(() {
        noteController.text = ctrCart.cartSuspended!.title;
       }); 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Memorizza vendita sospesa",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: noteController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Nota",
              hintText: "Es. Tavolo 5, cliente abituale…",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: () async {
                try{
                if( noteController.text.isEmpty ) return;
                final ctrCart = context.read<CarrelloController>();
                CartModelSaledSuspended cart = CartModelSaledSuspended.fromCartController(ctrCart, noteController.text ?? '');
                final db = await LocalDB.instance();
                final resp = await db.insert('cartsSuspended', cart.toMapForDb());
                debugPrint(resp.toString());
                ctrCart.clearCart();
                Navigator.pop(context); // chiude popup
                //  FEEDBACK VERDE
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    "Checkout salvato con successo",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF4CAF50), // verde POS
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              
                }catch( err ){
                  debugPrint( err.toString() );
                }
            },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------
//  PULSANTE "LISTINO BANCO" – come esempio in foto
// -------------------------------------------------------


Widget _pulsanteListino(BuildContext context) {
  
  return DropdownButton<ListPriceModel>(
    value: widget.selected,
    hint:  Text('Seleziona listino'), 
    items: widget.listListPrices.map((list) => 
      DropdownMenuItem<ListPriceModel>(
        value: list, 
        child: Text(list.title),
      ),
    ).toList(),
    onChanged: (ListPriceModel? selected_) async {
      if( selected_ == null ) return;
      final controllerCart      = context.read<CarrelloController>();
      final controllerListPrice = context.read<ControllerListPriceSelected>();
      //CONTROLLO SE IL CARRELLO é PIENO PRIMA DI CAMBIARE LISTINO e Aggiorna i prezzi
      bool? confirm  = true;
      if( controllerCart.prodotti.length > 0 ){
        //confirm = await _confermaEliminaCheckout(context);
        List<ProdottoCarrello> oldProducts = [...controllerCart.prodotti];
         
        String queryPreferred = """SELECT 
                                    art.*, 
                                    lp.*  
                                    FROM articles art
                                    INNER JOIN articlesPrices lp ON lp.idArticle = art.id AND lp.idPriceList = ${selected_.id}
                                    """;
        
        final respDbArticles   = await LocalDB.query(queryPreferred).catchError((err) => []);
        
        List<ArticleWhitPriceListModel> articles  = respDbArticles.map((articleDb) => ArticleWhitPriceListModel.fromJson(articleDb)).toList();

        bool priceZero = false;
        oldProducts.forEach((oldProd) {
          final existInListPrice = articles.firstWhereOrNull((a) => a.id == oldProd.article.id );
          if( existInListPrice == null ){
            oldProd.setRowPrice(0);
            if( priceZero == false ){
              priceZero == true;
              showDialog(
                context: context, 
                 builder: (context) =>  AlertDialog(
                  icon: Icon(Icons.warning),
                  title: Text('Attenzione, ci sono prodotti con prezzo a zero nel nuovo listino'),

                ));
            }
            return;
          } 
          double newPrice = double.parse(existInListPrice.price ?? '0') * oldProd.quantity;
          oldProd.setRowPrice(newPrice);
        } ,);

        controllerCart.changeProductsInCart(oldProducts);
      }
      

      if( confirm == null || !confirm  ) return;
      
      controllerListPrice.listPriceSelected = selected_;
      widget.onListPriceSelected(selected_);
      setListPriceSelected(selected_);
      setState(() {
      });
    }
  );
}


// -------------------------------------------------------
// POPUP SELEZIONE LISTINO
// -------------------------------------------------------

  // MENU UTENTE OVERLAY
  void _mostraMenuUtente(BuildContext context) {
    if (_menuOverlay != null) return;

    _menuOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // clic fuori chiude menu
            Positioned.fill(
              child: GestureDetector(
                onTap: _chiudiMenuUtente,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),

            Positioned(
              top: 70,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: MenuUtente(
                  onClose: _chiudiMenuUtente,
                  context: context,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_menuOverlay!);
  }

  void _chiudiMenuUtente() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }
}

String formattaData(String isoString) {
  DateTime data = DateTime.parse(isoString);  // Parse ISO
  final formatter = DateFormat('dd/MM/yyyy HH:mm');
  return formatter.format(data);  // Es: "13/02/2026 16:34"
}


class CheckoutItem extends StatelessWidget {
  final CartModelSaledSuspended checkout;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onExpand;

  const CheckoutItem({
    super.key,
    required this.checkout,
    required this.selected,
    required this.expanded,
    required this.onTap,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totale = (checkout.total ?? '');

    return GestureDetector(
      onTap: onTap, // 👈 TAP SU TUTTA LA CELLA
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.35 : 0.12,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    checkout.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "€ ${totale}",
                  style: theme.textTheme.titleMedium,
                ),
                IconButton( 
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: onExpand, // 👈 SOLO FRECCIA
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                formattaData(checkout.createAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* import 'dart:async';
import 'package:dashboard/impostazioni/home_vista.dart';
import 'package:dashboard/modelli/cartModelSaledSuspended.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:dashboard/state/controller_impostazioni.dart';
import 'package:dashboard/state/product_search_controller.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine_tipo.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/widget/header_footer/controller_not_fiscal_in_printing.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../impostazioni/report_avanzato_vista.dart';
import '../../screen/ordini/ux/widgets/inserisci_ordine_dialog.dart';
import '../../../state/controller_carrello.dart';
import '../../screen/sincronizzazioni/operatori/operator_preferences_controller.dart';

class HeaderInferiore extends StatefulWidget {
  final ValueChanged<int> onTabChanged;

  const HeaderInferiore({
    super.key,
    required this.onTabChanged,
  });

  @override
  State<HeaderInferiore> createState() => HeaderInferioreState();
}

class HeaderInferioreState extends State<HeaderInferiore> {
  int selezionato = 0;
  bool showExtendedCart = false;

  // 🔥 Listener esplicito per evitare problemi in release mode
  late final CarrelloController _carrello;
  late final OperatorPreferencesController _operatorPrefs;
  late final ImpostazioniController _impostazioni;
  bool _listenersAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenersAdded) {
      _listenersAdded = true;
      _carrello = context.read<CarrelloController>();
      _carrello.addListener(_rebuild);
      _operatorPrefs = context.read<OperatorPreferencesController>();
      _operatorPrefs.addListener(_rebuild);
      _impostazioni = context.read<ImpostazioniController>();
      _impostazioni.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _carrello.removeListener(_rebuild);
    _operatorPrefs.removeListener(_rebuild);
    _impostazioni.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    final bool isMobile  = width < 600;
    final bool isTablet  = width >= 600 && width < 900;
    final bool isDesktop = width >= 1400;

    final double iconSize = isMobile ? 22 : (isTablet ? 24 : 26);
    final double fontSize = isMobile ? 13 : (isTablet ? 14 : 15);

    final Color bgColor       = theme.colorScheme.surface;
    final Color activeColor   = theme.colorScheme.primaryContainer;
    final Color inactiveColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final Color iconColor     = theme.colorScheme.onSurface;
    final Color textColor     = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      alignment: Alignment.topLeft,
      height: isMobile || isTablet ? 120 : 60,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isDesktop
          ? _layoutDesktop(fontSize, iconSize, activeColor, inactiveColor, textColor)
          : _layoutMobileTablet(fontSize, iconSize, activeColor, inactiveColor, textColor, iconColor),
    );
  }

  // --------------------------------------------------------------------
  // DESKTOP
  // --------------------------------------------------------------------
  Widget _layoutDesktop(
    double fontSize,
    double iconSize,
    Color active,
    Color inactive,
    Color textColor,
  ) {
    final op     = _operatorPrefs;
    final isLeft = _impostazioni.uiSide == "L";

    Widget bloccoCategorie = Expanded(
      child: Align(
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isLeft
                ? [
                    const SizedBox(width: 8),
                    Flexible(child: _Sospeso(context)),
                    const SizedBox(width: 8),
                    Flexible(child: _notaChip(context)),
                    const SizedBox(width: 8),

                    // preferiti
                    _pulsanteIcona(
                      LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                      onTap: () {
                        setState(() => selezionato = 2);
                        widget.onTabChanged(2);
                      },
                    ),
                    const SizedBox(width: 8),

                    // vecchio carrello tab 3

                    const SizedBox(width: 8),

                    // nuovo carrello esteso (condizionale)
                    if (op.extendedCart) ...[
                      Consumer<CarrelloController>(
                        builder: (_, carrello, __) => _pulsanteIcona(
                          LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                          forceActive: carrello.extendedCartOpen,
                          onTap: () {
                            setState(() => selezionato = -1);
                            context.read<CarrelloController>().toggleExtendedCart();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    _pulsanteTab("Reparti",   1, active, inactive, textColor, fontSize),
                    const SizedBox(width: 4),
                    _pulsanteTab("Categorie", 0, active, inactive, textColor, fontSize),
                    const SizedBox(width: 12),
                  ]
                : [
                    _pulsanteTab("Categorie", 0, active, inactive, textColor, fontSize),
                    const SizedBox(width: 4),
                    _pulsanteTab("Reparti",   1, active, inactive, textColor, fontSize),
                    const SizedBox(width: 12),

                    // preferiti
                    _pulsanteIcona(
                      LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                      onTap: () {
                        setState(() => selezionato = 2);
                        widget.onTabChanged(2);
                      },
                    ),
                    const SizedBox(width: 8),

                    // vecchio carrello tab 3

                    const SizedBox(width: 8),

                    // nuovo carrello esteso (condizionale)
                    if (op.extendedCart) ...[
                      Consumer<CarrelloController>(
                        builder: (_, carrello, __) => _pulsanteIcona(
                          LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                          forceActive: carrello.extendedCartOpen,
                          onTap: () {
                            setState(() => selezionato = -1);
                            context.read<CarrelloController>().toggleExtendedCart();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    const SizedBox(width: 12),
                    Flexible(child: _notaChip(context)),
                    const SizedBox(width: 8),
                    Flexible(child: _Sospeso(context)),
                    const SizedBox(width: 8),

                    Flexible(
                      child: Consumer<CarrelloController>(
                        builder: (_, carrello, __) {
                          if (carrello.cliente == null) return const SizedBox();
                          return _ClienteHeader(
                            cliente: carrello.cliente!,
                            onEdit: () => apriPopupCliente(context),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
          ),
        ),
      ),
    );

    Widget bloccoAzioni = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _azioniExtra(context, iconSize, Theme.of(context)),
        const SizedBox(width: 12),
        _pulsanteIcona(
          LucideIcons.shoppingBag, 100, active, inactive, textColor, iconSize,
          onTap: () async {
          await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => InserisciOrdineSheet(
                  ordineTipo: OrdineTipo.ritiro,
                ),
              );
          },
        ),
        const SizedBox(width: 8),
        _pulsanteIcona(
          LucideIcons.bike, 101, active, inactive, textColor, iconSize,
          onTap: () async {
            context.read<CarrelloController>().setTipoOrdine('Consegna');
            await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => InserisciOrdineSheet(
                  ordineTipo: OrdineTipo.consegna,
                ),
              );
          },
        ),
      ],
    );

    return Row(
      children: isLeft
          ? [bloccoAzioni, Expanded(child: bloccoCategorie)]
          : [Expanded(child: bloccoCategorie), bloccoAzioni],
    );
  }

  // --------------------------------------------------------------------
  // TABLET + MOBILE
  // --------------------------------------------------------------------
  Widget _layoutMobileTablet(
    double fontSize,
    double iconSize,
    Color active,
    Color inactive,
    Color textColor,
    Color iconColor,
  ) {
    final op     = _operatorPrefs;
    final isLeft = _impostazioni.uiSide == "L";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: isLeft
              ? [
                  _azioniExtra(context, iconSize, Theme.of(context)),
                  const SizedBox(width: 12),

                  _pulsanteIcona(
                    LucideIcons.shoppingBag, 100, active, inactive, textColor, iconSize,
                    onTap: () async {
                     await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.ritiro,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  _pulsanteIcona(
                    LucideIcons.bike, 101, active, inactive, textColor, iconSize,
                    onTap: () async {
                      context.read<CarrelloController>().setTipoOrdine('Consegna');
                    await  showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.consegna,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),

                  SizedBox(width: MediaQuery.of(context).size.width * 0.4),

                  _pulsanteIcona(
                    LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                    onTap: () {
                      setState(() => selezionato = 2);
                      widget.onTabChanged(2);
                    },
                  ),
                  const SizedBox(width: 12),

                  // vecchio carrello tab 3

                  const SizedBox(width: 12),

                  // nuovo carrello esteso (condizionale)
                  if (op.extendedCart) ...[
                    Consumer<CarrelloController>(
                      builder: (_, carrello, __) => _pulsanteIcona(
                        LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                        forceActive: carrello.extendedCartOpen,
                        onTap: () {
                          setState(() => selezionato = -1);
                          context.read<CarrelloController>().toggleExtendedCart();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  _pulsanteTab("Categorie", 0, active, inactive, textColor, fontSize),
                  const SizedBox(width: 8),
                  _pulsanteTab("Reparti",   1, active, inactive, textColor, fontSize),
                  const SizedBox(width: 16),
                ]
              : [
                  _pulsanteTab("Categorie", 0, active, inactive, textColor, fontSize),
                  const SizedBox(width: 8),
                  _pulsanteTab("Reparti",   1, active, inactive, textColor, fontSize),
                  const SizedBox(width: 16),

                  // ScontoBar dal vecchio

                  const SizedBox(width: 16),

                  _pulsanteIcona(
                    LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                    onTap: () {
                      setState(() => selezionato = 2);
                      widget.onTabChanged(2);
                    },
                  ),
                  const SizedBox(width: 12),

                  // vecchio carrello tab 3

                  const SizedBox(width: 12),

                  // nuovo carrello esteso (condizionale)
                  if (op.extendedCart) ...[
                    Consumer<CarrelloController>(
                      builder: (_, carrello, __) => _pulsanteIcona(
                        LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                        forceActive: carrello.extendedCartOpen,
                        onTap: () {
                          setState(() => selezionato = -1);
                          context.read<CarrelloController>().toggleExtendedCart();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  _pulsanteIcona(LucideIcons.scale, 4, active, inactive, textColor, iconSize),
                  const SizedBox(width: 12),

                  _pulsanteReportAvanzato(
                    LucideIcons.barChart3, 5, active, inactive, textColor, iconSize, context,
                  ),
                  const SizedBox(width: 12),

                  _pulsanteIcona(
                    LucideIcons.shoppingBag, 100, active, inactive, textColor, iconSize,
                    onTap: () async {
                    await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.ritiro,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  _pulsanteIcona(
                    LucideIcons.bike, 101, active, inactive, textColor, iconSize,
                    onTap: () async {
                      context.read<CarrelloController>().setTipoOrdine('Consegna');
                    await  showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.consegna,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),

                  _azioniExtra(context, iconSize, Theme.of(context)),
                  const SizedBox(width: 12),
                ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // WIDGET HELPERS
  // --------------------------------------------------------------------

  Widget _pulsanteTab(
    String testo,
    int index,
    Color active,
    Color inactive,
    Color textColor,
    double fontSize, {
    VoidCallback? onTap,
  }) {
    final bool attivo = selezionato == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap ??
          () {
            context.read<ProductSearchController>().clear();
            setState(() => selezionato = index);
            widget.onTabChanged(index);
          },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 40,
        constraints: const BoxConstraints(minWidth: 110),
        decoration: BoxDecoration(
          color: attivo ? active : inactive,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: attivo
                ? theme.colorScheme.primary.withOpacity(0.35)
                : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          testo,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: attivo ? FontWeight.bold : FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _pulsanteIcona(
    IconData icona,
    int index,
    Color active,
    Color inactive,
    Color iconColor,
    double iconSize, {
    VoidCallback? onTap,
    bool? forceActive,
  }) {
    final theme    = Theme.of(context);
    final carrello = _carrello;

    final bool attivo = forceActive ??
        (carrello.extendedCartOpen ? index == 999 : selezionato == index);

    return GestureDetector(
      onTap: onTap ?? () { setState(() => selezionato = index); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: attivo ? active : inactive,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: attivo
                ? theme.colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icona,
          size: iconSize,
          color: attivo
              ? theme.colorScheme.onPrimaryContainer
              : iconColor.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _pulsanteReportAvanzato(
    IconData icona,
    int index,
    Color active,
    Color inactive,
    Color iconColor,
    double iconSize,
    BuildContext context,
  ) {
    final attivo = selezionato == index;
    final theme  = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() => selezionato = index);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportAvanzatoVista()),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: attivo ? active : inactive,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: attivo
                ? theme.colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icona,
          size: iconSize,
          color: attivo
              ? theme.colorScheme.onPrimaryContainer
              : iconColor.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _azioniExtra(BuildContext context, double iconSize, ThemeData theme) {
    final Color bg = theme.colorScheme.surfaceContainerHighest.withOpacity(0.55);
    final Color ic = theme.colorScheme.onSurface.withOpacity(0.85);
    final controllerNotFiscal = context.watch<ControllerNotFiscalInPrinting>();

    Widget btn(IconData icon, Function onTap) {
      return InkWell(
        onTap: () => onTap(),
        child: Container(
          width: 45,
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ic, size: iconSize),
        ),
      );
    }

    return Row(
      children: [
        btn(LucideIcons.scan,     () {}),
        btn(LucideIcons.scanLine, () {}),
        btn(LucideIcons.ticket,   () {}),
        btn(LucideIcons.grid,     () {}),
        btn(
          controllerNotFiscal.inPrintig_ ? LucideIcons.loader : LucideIcons.printer,
          () async {
            if (controllerNotFiscal.inPrintig_) return;
            controllerNotFiscal.setInPrinting(true);
            await printNotFiscalEscPos(context,null);
            Timer(
              const Duration(seconds: 1),
              () => controllerNotFiscal.setInPrinting(false),
            );
          },
        ),
      ],
    );
  }

  // tenuto dal nuovo, disponibile per usi futuri
  void _openExtendedCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ExtendedCartView(scrollController: controller),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// WIDGET ESTERNI
// --------------------------------------------------------------------

class _ClienteHeader extends StatelessWidget {
  final CustomerModel cliente;
  final VoidCallback onEdit;

  const _ClienteHeader({required this.cliente, required this.onEdit});

  String get _displayName {
    if (cliente.businessName != null) return cliente.businessName!;
    final first = cliente.personalFirstname;
    final last  = cliente.personalLastname;
    if (first != null && last != null) return '$first $last';
    return cliente.title ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF57C00),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            cliente.businessType == "company"
                ? Icons.business_rounded
                : Icons.person_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 18,
            onSelected: (value) {
              if (value == 'edit')   onEdit();
              if (value == 'delete') context.read<CarrelloController>().clearCliente();
            },
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white),
            color: const Color(0xFF424242),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_rounded, size: 16, color: Colors.white70),
                  SizedBox(width: 8),
                  Text('Modifica', style: TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_rounded, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Elimina', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _Sospeso(BuildContext context) {
  return Consumer<CarrelloController>(
    builder: (_, carrello, __) {
      final suspended = carrello.cartSuspended;
      if (suspended == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF57C00),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF57C00).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.list_alt_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            const Text(
              'Sospeso:',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                suspended.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                try {
                  final ctrCart = context.read<CarrelloController>();
                  final cart = CartModelSaledSuspended.fromCartController(
                    ctrCart, ctrCart.cartSuspended!.title,
                  );
                  final db   = await LocalDB.instance();
                  final resp = await db.insert('cartsSuspended', cart.toMapForDb());
                  debugPrint(resp.toString());
                  ctrCart.clearCart();
                } catch (err) {
                  debugPrint(err.toString());
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _notaChip(BuildContext context) {
  return Consumer<CarrelloController>(
    builder: (_, carrello, __) {
      final nota = carrello.note;
      if (nota.isEmpty) return const SizedBox.shrink();

      return GestureDetector(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF57C00),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF57C00).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  nota,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ExtendedCartView extends StatelessWidget {
  final ScrollController scrollController;

  const ExtendedCartView({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Carrello Esteso"));
  }
} */


import 'dart:async';
import 'package:dashboard/impostazioni/home_vista.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:dashboard/state/controller_impostazioni.dart';
import 'package:dashboard/state/product_search_controller.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine_tipo.dart';
import 'package:dashboard/ui/widget/header_footer/controller_not_fiscal_in_printing.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../impostazioni/report_avanzato_vista.dart';
import '../../screen/ordini/ux/widgets/inserisci_ordine_dialog.dart';
import '../../../state/controller_carrello.dart';
import '../../screen/sincronizzazioni/operatori/operator_preferences_controller.dart';

class HeaderInferiore extends StatefulWidget {
  final ValueChanged<int> onTabChanged;

  const HeaderInferiore({
    super.key,
    required this.onTabChanged,
  });

  @override
  State<HeaderInferiore> createState() => HeaderInferioreState();
}

class HeaderInferioreState extends State<HeaderInferiore> {
  int selezionato = 0;

  // 🔥 Listener espliciti per evitare problemi in release mode
  late final CarrelloController _carrello;
  late final OperatorPreferencesController _operatorPrefs;
  late final ImpostazioniController _impostazioni;
  bool _listenersAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenersAdded) {
      _listenersAdded = true;
      _carrello = context.read<CarrelloController>();
      _carrello.addListener(_rebuild);
      _operatorPrefs = context.read<OperatorPreferencesController>();
      _operatorPrefs.addListener(_rebuild);
      _impostazioni = context.read<ImpostazioniController>();
      _impostazioni.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _carrello.removeListener(_rebuild);
    _operatorPrefs.removeListener(_rebuild);
    _impostazioni.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Leggi i provider UNA SOLA VOLTA qui nel build
    final theme    = Theme.of(context);
    final width    = MediaQuery.of(context).size.width;
    final op       = _operatorPrefs;
    final carrello = _carrello;
    final isLeft   = _impostazioni.uiSide == 'L';

    final bool isMobile  = width < 600;
    final bool isTablet  = width >= 600 && width < 900;
    final bool isDesktop = width >= 1400;

    final double iconSize = isMobile ? 22 : (isTablet ? 24 : 26);
    final double fontSize = isMobile ? 13 : (isTablet ? 14 : 15);

    final Color bgColor     = theme.colorScheme.surface;
    final Color active      = theme.colorScheme.primaryContainer;
    final Color inactive    = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final Color iconColor   = theme.colorScheme.onSurface;
    final Color textColor   = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      height: isMobile || isTablet ? 120 : 60,
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isDesktop
          ? _layoutDesktop(
              fontSize, iconSize, active, inactive, textColor,
              op, carrello, isLeft,
            )
          : _layoutMobileTablet(
              fontSize, iconSize, active, inactive, textColor, iconColor,
              op, carrello, isLeft,
            ),
    );
  }

  // ------------------------------------------------------------------
  // DESKTOP
  // ------------------------------------------------------------------
  Widget _layoutDesktop(
    double fontSize,
    double iconSize,
    Color active,
    Color inactive,
    Color textColor,
    OperatorPreferencesController op,
    CarrelloController carrello,
    bool isLeft,
  ) {
    final theme = Theme.of(context);

    final bloccoCategorie = Expanded(
      child: Align(
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isLeft
                ? [
                    const SizedBox(width: 8),
                    _SospesoWidget(),
                    const SizedBox(width: 8),
                    _NotaChipWidget(),
                    const SizedBox(width: 8),
                    // preferiti
                    _pulsanteIcona(
                      LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                      carrello: carrello,
                      onTap: () {
                        setState(() => selezionato = 2);
                        widget.onTabChanged(2);
                      },
                    ),
                    const SizedBox(width: 8),
                    if (op.extendedCart) ...[
                      _pulsanteIcona(
                        LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                        carrello: carrello,
                        forceActive: carrello.extendedCartOpen,
                        onTap: () {
                          setState(() => selezionato = -1);
                          context.read<CarrelloController>().toggleExtendedCart();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    _pulsanteTab('Reparti',   1, active, inactive, textColor, fontSize),
                    const SizedBox(width: 4),
                    _pulsanteTab('Categorie', 0, active, inactive, textColor, fontSize),
                    const SizedBox(width: 12),
                  ]
                : [
                    _pulsanteTab('Categorie', 0, active, inactive, textColor, fontSize),
                    const SizedBox(width: 4),
                    _pulsanteTab('Reparti',   1, active, inactive, textColor, fontSize),
                    const SizedBox(width: 12),
                    _pulsanteIcona(
                      LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                      carrello: carrello,
                      onTap: () {
                        setState(() => selezionato = 2);
                        widget.onTabChanged(2);
                      },
                    ),
                    const SizedBox(width: 8),
                    if (op.extendedCart) ...[
                      _pulsanteIcona(
                        LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                        carrello: carrello,
                        forceActive: carrello.extendedCartOpen,
                        onTap: () {
                          setState(() => selezionato = -1);
                          context.read<CarrelloController>().toggleExtendedCart();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    const SizedBox(width: 12),
                    _NotaChipWidget(),
                    const SizedBox(width: 8),
                    _SospesoWidget(),
                    const SizedBox(width: 8),
                    if (carrello.cliente != null)
                      _ClienteHeader(
                        cliente: carrello.cliente!,
                        onEdit: () => apriPopupCliente(context),
                      ),
                    const SizedBox(width: 12),
                  ],
          ),
        ),
      ),
    );

    final bloccoAzioni = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _azioniExtra(context, iconSize, theme),
        const SizedBox(width: 12),
        _pulsanteIcona(
          LucideIcons.shoppingBag, 100, active, inactive, textColor, iconSize,
          carrello: carrello,
          onTap: () async {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => InserisciOrdineSheet(ordineTipo: OrdineTipo.ritiro),
            );
          },
        ),
        const SizedBox(width: 8),
        _pulsanteIcona(
          LucideIcons.bike, 101, active, inactive, textColor, iconSize,
          carrello: carrello,
          onTap: () async {
            context.read<CarrelloController>().setTipoOrdine('Consegna');
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => InserisciOrdineSheet(ordineTipo: OrdineTipo.consegna),
            );
          },
        ),
      ],
    );

    return Row(
      children: isLeft
          ? [bloccoAzioni, bloccoCategorie]
          : [bloccoCategorie, bloccoAzioni],
    );
  }

  // ------------------------------------------------------------------
  // MOBILE / TABLET
  // ------------------------------------------------------------------
  Widget _layoutMobileTablet(
    double fontSize,
    double iconSize,
    Color active,
    Color inactive,
    Color textColor,
    Color iconColor,
    OperatorPreferencesController op,
    CarrelloController carrello,
    bool isLeft,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: isLeft
              ? [
                  _azioniExtra(context, iconSize, theme),
                  const SizedBox(width: 12),
                  _pulsanteIcona(
                    LucideIcons.shoppingBag, 100, active, inactive, textColor, iconSize,
                    carrello: carrello,
                    onTap: () async {
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.ritiro,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _pulsanteIcona(
                    LucideIcons.bike, 101, active, inactive, textColor, iconSize,
                    carrello: carrello,
                    onTap: () async {
                      context.read<CarrelloController>().setTipoOrdine('Consegna');
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.consegna,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.4),
                  _pulsanteIcona(
                    LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                    carrello: carrello,
                    onTap: () {
                      setState(() => selezionato = 2);
                      widget.onTabChanged(2);
                    },
                  ),
                  const SizedBox(width: 12),
                  if (op.extendedCart) ...[
                    _pulsanteIcona(
                      LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                      carrello: carrello,
                      forceActive: carrello.extendedCartOpen,
                      onTap: () {
                        setState(() => selezionato = -1);
                        context.read<CarrelloController>().toggleExtendedCart();
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  _pulsanteTab('Categorie', 0, active, inactive, textColor, fontSize),
                  const SizedBox(width: 8),
                  _pulsanteTab('Reparti',   1, active, inactive, textColor, fontSize),
                  const SizedBox(width: 16),
                ]
              : [
                  _pulsanteTab('Categorie', 0, active, inactive, textColor, fontSize),
                  const SizedBox(width: 8),
                  _pulsanteTab('Reparti',   1, active, inactive, textColor, fontSize),
                  const SizedBox(width: 16),
                  _pulsanteIcona(
                    LucideIcons.heart, 2, active, inactive, textColor, iconSize,
                    carrello: carrello,
                    onTap: () {
                      setState(() => selezionato = 2);
                      widget.onTabChanged(2);
                    },
                  ),
                  const SizedBox(width: 12),
                  if (op.extendedCart) ...[
                    _pulsanteIcona(
                      LucideIcons.shoppingCart, 999, active, inactive, textColor, iconSize,
                      carrello: carrello,
                      forceActive: carrello.extendedCartOpen,
                      onTap: () {
                        setState(() => selezionato = -1);
                        context.read<CarrelloController>().toggleExtendedCart();
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  _pulsanteIcona(LucideIcons.scale, 4, active, inactive, textColor, iconSize, carrello: carrello),
                  const SizedBox(width: 12),
                  _pulsanteReportAvanzato(LucideIcons.barChart3, 5, active, inactive, textColor, iconSize, context),
                  const SizedBox(width: 12),
                  _pulsanteIcona(
                    LucideIcons.shoppingBag, 100, active, inactive, textColor, iconSize,
                    carrello: carrello,
                    onTap: () async {
                      // ⚠️ NON wrappare con ChangeNotifierProvider.value: il controller
                      // è già fornito dal MultiProvider in main.dart (root).
                      // Ri-fornire lo stesso ChangeNotifier in un sotto-scope crea due
                      // provider per la stessa istanza e in release mode può rompere
                      // le subscription dei widget esterni quando il dialog viene chiuso.
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogCtx) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.ritiro,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _pulsanteIcona(
                    LucideIcons.bike, 101, active, inactive, textColor, iconSize,
                    carrello: carrello,
                    onTap: () async {
                      context.read<CarrelloController>().setTipoOrdine('Consegna');
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogCtx) => InserisciOrdineSheet(
                          ordineTipo: OrdineTipo.consegna,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _azioniExtra(context, iconSize, theme),
                  const SizedBox(width: 12),
                ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------------

  Widget _pulsanteTab(
    String testo,
    int index,
    Color active,
    Color inactive,
    Color textColor,
    double fontSize, {
    VoidCallback? onTap,
  }) {
    final bool attivo = selezionato == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap ??
          () {
            context.read<ProductSearchController>().clear();
            setState(() => selezionato = index);
            widget.onTabChanged(index);
          },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 40,
        constraints: const BoxConstraints(minWidth: 110),
        decoration: BoxDecoration(
          color: attivo ? active : inactive,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: attivo
                ? theme.colorScheme.primary.withOpacity(0.35)
                : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          testo,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: attivo ? FontWeight.bold : FontWeight.w500,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // ✅ FIX PRINCIPALE: carrello passato come parametro, NON letto con watch qui dentro
  Widget _pulsanteIcona(
    IconData icona,
    int index,
    Color active,
    Color inactive,
    Color iconColor,
    double iconSize, {
    required CarrelloController carrello,
    VoidCallback? onTap,
    bool? forceActive,
  }) {
    final theme = Theme.of(context);
    final bool attivo = forceActive ??
        (carrello.extendedCartOpen ? index == 999 : selezionato == index);

    return GestureDetector(
      onTap: onTap ?? () { setState(() => selezionato = index); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: attivo ? active : inactive,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: attivo
                ? theme.colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icona,
          size: iconSize,
          color: attivo
              ? theme.colorScheme.onPrimaryContainer
              : iconColor.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _pulsanteReportAvanzato(
    IconData icona,
    int index,
    Color active,
    Color inactive,
    Color iconColor,
    double iconSize,
    BuildContext context,
  ) {
    final attivo = selezionato == index;
    final theme  = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() => selezionato = index);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportAvanzatoVista()),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: attivo ? active : inactive,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: attivo
                ? theme.colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icona,
          size: iconSize,
          color: attivo
              ? theme.colorScheme.onPrimaryContainer
              : iconColor.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _azioniExtra(BuildContext context, double iconSize, ThemeData theme) {
    final Color bg = theme.colorScheme.surfaceContainerHighest.withOpacity(0.55);
    final Color ic = theme.colorScheme.onSurface.withOpacity(0.85);
    final controllerNotFiscal = context.watch<ControllerNotFiscalInPrinting>();

    Widget btn(IconData icon, Function onTap) {
      return InkWell(
        onTap: () => onTap(),
        child: Container(
          width: 45,
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ic, size: iconSize),
        ),
      );
    }

    return Row(
      children: [
        btn(LucideIcons.scan,     () {}),
        btn(LucideIcons.scanLine, () {}),
        btn(LucideIcons.ticket,   () {}),
        btn(LucideIcons.grid,     () {}),
        btn(
          controllerNotFiscal.inPrintig_ ? LucideIcons.loader : LucideIcons.printer,
          () async {
            if (controllerNotFiscal.inPrintig_) return;
            controllerNotFiscal.setInPrinting(true);
            await printNotFiscalEscPos(context, null);
            Timer(
              const Duration(seconds: 1),
              () => controllerNotFiscal.setInPrinting(false),
            );
          },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// WIDGET ESTERNI (ora come StatelessWidget, non funzioni top-level)
// ------------------------------------------------------------------

class _SospesoWidget extends StatelessWidget {
  const _SospesoWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer<CarrelloController>(
      builder: (_, carrello, __) {
        final suspended = carrello.cartSuspended;
        if (suspended == null) return const SizedBox.shrink();
        // ... tuo codice Sospeso invariato
        return const SizedBox.shrink(); // placeholder
      },
    );
  }
}

class _NotaChipWidget extends StatelessWidget {
  const _NotaChipWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer<CarrelloController>(
      builder: (_, carrello, __) {
        // ... tuo codice _notaChip invariato
        return const SizedBox.shrink(); // placeholder
      },
    );
  }
}

class _ClienteHeader extends StatelessWidget {
  final CustomerModel cliente;
  final VoidCallback onEdit;

  const _ClienteHeader({
    required this.cliente,
    required this.onEdit,
  });

  String get _displayName {
    if (cliente.businessName != null) return cliente.businessName!;
    final first = cliente.personalFirstname;
    final last  = cliente.personalLastname;
    if (first != null && last != null) return '$first $last';
    return cliente.title ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF57C00),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            cliente.businessType == 'company'
                ? Icons.business_rounded
                : Icons.person_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 18,
            onSelected: (value) {
              if (value == 'edit')   onEdit();
              if (value == 'delete') context.read<CarrelloController>().clearCliente();
            },
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white),
            color: const Color(0xFF424242),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_rounded, size: 16, color: Colors.white70),
                  SizedBox(width: 8),
                  Text('Modifica', style: TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_rounded, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Elimina', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
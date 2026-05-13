import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/printers/not_fiscal/esc_pos.dart';
import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine_stato.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine_tipo.dart';
import 'package:dashboard/ui/screen/ordini/state/ordini_list_controller.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../state/controller_carrello.dart';
import '../../../checkout/checkout_page.dart';
import '../../models/ordine.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────

Color getColorBgVariantRow(String type) {
  switch (type) {
    case 'minus': return Colors.red;
    case 'plus':  return Colors.green;
    case 'free':  return Colors.green;
    case 'info':  return Colors.lightBlue;
    default:      return Colors.black;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Box extends StatelessWidget {
  final String text;
  final bool small;
  final bool alignRight;

  const _Box({
    required this.text,
    this.small = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: small ? 28 : 34,
      alignment: alignRight ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class OrdineDettaglioDialog extends StatelessWidget {
  final Ordine ordine;
  final Function setStateParentForOrders;

  const OrdineDettaglioDialog({
    super.key,
    required this.setStateParentForOrders,
    required this.ordine,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final isDark      = theme.brightness == Brightness.dark;
    final headerColor = const Color(0xFF97D700);
    final bgColor     = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 920,
        height: 920,
        child: Column(
          children: [

            // ── HEADER ────────────────────────────────────────────────
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    '${ordine.tipo.name.toUpperCase()}  #${ordine.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── INFO ORDINE ───────────────────────────────────────────
            infoDueColonne(context),

            // ── LISTA ARTICOLI ────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                itemCount: ordine.articles.length,
                itemBuilder: (ctx, i) {
                  final p = ordine.articles[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // RIGA PRODOTTO PRINCIPALE
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                p.article.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _Box(text: p.quantity.toString()),
                            ),
                            Expanded(
                              flex: 1,
                              child: _Box(
                                text: p.priceRowCart
                                    .toStringAsFixed(2)
                                    .replaceAll('.', ','),
                                alignRight: true,
                              ),
                            ),
                          ],
                        ),

                        // VARIANTI
                        ...[
                          ...p.variationsFree,
                          ...p.variationsInfo,
                          ...p.variationsMinus,
                          ...p.variationsPlus,
                        ].map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getColorBgVariantRow(v.variationType!),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: getColorBgVariantRow(v.variationType!),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "${v.variationType == 'minus' ? '-' : '+'} ${v.article.title}",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _Box(
                                    text: v.quantity.toString(),
                                    small: true,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _Box(
                                    text: v.priceRowCart
                                        .toStringAsFixed(2)
                                        .replaceAll('.', ','),
                                    small: true,
                                    alignRight: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── FOOTER ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _actionRow(
                    left: _actionBtn(
                      text: 'Partenza',
                      icon: Icons.directions_bike,
                      color: ordine.tipo != OrdineTipo.consegna
                          ? const Color.fromARGB(255, 175, 175, 175)
                          : Colors.grey.shade600,
                      onTap: () async {
                        if (ordine.tipo != OrdineTipo.consegna) return;

                        final ctrlOrdini = context.read<OrdiniListController>();
                        await Ordine.changeStatus(
                            ordine.id ?? 0, OrdineStato.partito.label);
                        await ctrlOrdini.getOrders();

                        final changeCtr = TextEditingController(
                            text: (ordine.change ?? 0).toString());
                        List<OperatoreModel> riders = (await OperatoreModel
                                .getOperators())
                            .where((o) => o.rider == 1)
                            .toList();
                        int? idRaider;
                        double resto = 0;

                        // ── DIALOG PARTENZA (nuovo stile) ──────────────
                        final Map<String, dynamic>? riderAndChange =
                            await showDialog(
                          context: context,
                          builder: (context) {
                            final dlgDark =
                                Theme.of(context).brightness == Brightness.dark;

                            return Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Container(
                                width: 420,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: dlgDark
                                      ? const Color(0xFF1E1E1E)
                                      : const Color(0xFFF8F8F4),
                                  borderRadius: BorderRadius.circular(34),
                                  border: Border.all(
                                    color: dlgDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.black.withOpacity(0.04),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 35,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                    // ICONA
                                    Container(
                                      width: 82,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB5FF00)
                                            .withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.delivery_dining_rounded,
                                        size: 40,
                                        color: Color(0xFF708C00),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // TITOLO
                                    Text(
                                      'Partenza ordine',
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.8,
                                        color: dlgDark
                                            ? Colors.white
                                            : const Color(0xFF171F2D),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Text(
                                      'Seleziona rider e inserisci il resto',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: dlgDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 30),

                                    // DROPDOWN RIDER
                                    DropdownMenu<int?>(
                                      width: 340,
                                      onSelected: (value) async {
                                        idRaider = value;
                                      },
                                      enableFilter: false,
                                      enableSearch: false,
                                      initialSelection: ordine.idRider,
                                      leadingIcon: const Icon(
                                        Icons.delivery_dining_rounded,
                                        color: Color(0xFF708C00),
                                        size: 22,
                                      ),
                                      menuStyle: MenuStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                          dlgDark
                                              ? const Color(0xFF2A2A2A)
                                              : Colors.white,
                                        ),
                                        elevation:
                                            const WidgetStatePropertyAll(10),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(22),
                                          ),
                                        ),
                                      ),
                                      inputDecorationTheme:
                                          InputDecorationTheme(
                                        filled: true,
                                        fillColor: dlgDark
                                            ? const Color(0xFF262626)
                                            : Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: BorderSide(
                                            color: Colors.black.withOpacity(0.06),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFB5FF00),
                                            width: 1.4,
                                          ),
                                        ),
                                      ),
                                      trailingIcon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 24,
                                      ),
                                      selectedTrailingIcon: const Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        size: 24,
                                      ),
                                      dropdownMenuEntries: [
                                        const DropdownMenuEntry(
                                          value: null,
                                          label: 'Nessuno',
                                        ),
                                        ...riders.map(
                                          (s) => DropdownMenuEntry(
                                            value: s.id,
                                            label: s.title,
                                            leadingIcon: CircleAvatar(
                                              radius: 13,
                                              backgroundColor: const Color(
                                                      0xFFB5FF00)
                                                  .withOpacity(0.16),
                                              child: Text(
                                                s.title.isNotEmpty
                                                    ? s.title[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF708C00),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),

                                    // CAMPO RESTO
                                    TextField(
                                      controller: changeCtr,
                                      autofocus: true,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'),
                                        ),
                                      ],
                                      onChanged: (value) async {
                                        double vv = 0;
                                        if (value.contains('.')) {
                                          vv = double.tryParse(value) ?? 0;
                                        } else {
                                          vv = double.parse(
                                              (int.tryParse(value) ?? 0)
                                                  .toString());
                                        }
                                        resto = vv;
                                      },
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Resto',
                                        hintText: '0.00',
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFB5FF00)
                                                .withOpacity(0.14),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.payments_rounded,
                                            color: Color(0xFF708C00),
                                          ),
                                        ),
                                        suffixText: '€',
                                        filled: true,
                                        fillColor: dlgDark
                                            ? const Color(0xFF262626)
                                            : Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: BorderSide(
                                            color: Colors.black.withOpacity(0.06),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFB5FF00),
                                            width: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 34),

                                    // BOTTONI
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: dlgDark
                                                  ? const Color(0xFF2B2B2B)
                                                  : Colors.white,
                                              foregroundColor:
                                                  const Color(0xFF5A6B1A),
                                              elevation: 0,
                                              minimumSize:
                                                  const Size.fromHeight(58),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                            ),
                                            child: const Text(
                                              'Annulla',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context, {
                                                'idRaider': idRaider,
                                                'resto': resto,
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.delivery_dining_rounded,
                                              size: 22,
                                            ),
                                            label: const Text('Parti'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFB5FF00),
                                              foregroundColor:
                                                  const Color(0xFF171F2D),
                                              elevation: 0,
                                              minimumSize:
                                                  const Size.fromHeight(58),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        if (riderAndChange == null) return;
                        await Ordine.uploadChange(resto, ordine.id ?? 0);
                        await Ordine.uploadRider(idRaider, ordine.id ?? 0);
                        Navigator.pop(context);
                        await _checkoutOrdine(context, ordine);
                        await Ordine.getAllOrder();
                      },
                    ),
                    right: _actionBtn(
                      text: 'Conto',
                      icon: Icons.payments,
                      color: Colors.grey.shade600,
                      onTap: () async {
                        await _checkoutOrdine(context, ordine);
                        await Ordine.getAllOrder();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  _actionRow(
                    left: _actionBtn(
                      text: 'Preconto',
                      icon: Icons.receipt_long,
                      color: Colors.grey.shade600,
                      onTap: () async {
                        await printNotFiscalEscPos(context, ordine);
                      },
                    ),
                    right: _actionBtn(
                      text: 'Invia comanda',
                      icon: Icons.send,
                      color: Colors.grey.shade600,
                      onTap: () async {
                        final ctrTab = context.read<ControllerTableOpened>();
                        Map<String, List<ProdottoCarrello>> pp = await ctrTab.splitProductsForDeparment( true, ordine.articles );

                        pp.forEach((key, list) {
                          EscPos().printOrderToDepartment(
                            key.split(':')[0],
                            int.parse(key.split(':')[1]),
                            operatorLogged!,
                            deviceCurrent['title'],
                            null,
                            list,
                            0,
                            null,
                            ordine
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  _actionRow(
                    left: _actionBtn(
                      text: 'Modifica',
                      icon: Icons.edit,
                      color: Colors.blueGrey,
                      onTap: () => _modificaOrdine(context, ordine),
                    ),
                    right: _actionBtn(
                      text: 'Elimina',
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: () async {
                        await _eliminaOrdine(context);
                        setStateParentForOrders();
                        SnackBarForcedClosure('Ordine eliminato', Colors.green);
                      },
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

  // ─────────────────────────────────────────────────────────────────────────
  // AZIONI

  void _modificaOrdine(BuildContext context, Ordine order) {
    final carrello = context.read<CarrelloController>();
    carrello.clearCart();
    carrello.inOrder     = true;
    carrello.orderinEdit = order.id;
    carrello.addArticlesFromOrderInEdit(order.articles);
    carrello.setCliente(order.cliente);
    carrello.setTipoOrdine(ordine.tipo.label == 'Consegna'
        ? 'delivery'
        : ordine.tipo.label == 'Ritiro'
            ? 'takeAway'
            : 'eatHere');
    carrello.callerPager  = order.callerPager ?? '';
    carrello.dataOrdine   = order.data;
    carrello.addressOrder = order.indirizzo ?? '';
    carrello.phoneNumber  = order.telefono ?? '';

    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _checkoutOrdine(BuildContext context, Ordine order) async {
    final carrello = context.read<CarrelloController>();
    carrello.clearCart();
    carrello.inOrder     = true;
    carrello.orderinEdit = order.id;
    carrello.addArticlesFromOrderInEdit(order.articles);
    carrello.setCliente(order.cliente);
    carrello.setTipoOrdine(ordine.tipo.label == 'Consegna'
        ? 'delivery'
        : ordine.tipo.label == 'Ritiro'
            ? 'takeAway'
            : 'eatHere');
    carrello.callerPager  = order.callerPager ?? '';
    carrello.dataOrdine   = order.data;
    carrello.addressOrder = order.indirizzo ?? '';
    carrello.phoneNumber  = order.telefono ?? '';
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  Future<void> _eliminaOrdine(BuildContext context) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina ordine'),
        content: const Text(
          'Sei sicuro di voler eliminare questa consegna?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma == true) {
      await Ordine.delete(ordine.id ?? 0);
      Navigator.pop(context);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS UI

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _actionBtn({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 66,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 26),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget infoDueColonne(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget riga(String label, String value) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SINISTRA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  riga('Cliente',
                      ordine.cliente == null
                          ? ''
                          : ordine.cliente?.titleCustomer ?? ''),
                  riga('Ritiro',
                      DateFormat('dd MMM yyyy – HH:mm').format(ordine.data)),
                  riga('Totale', '${ordine.totaleCarrello} €'),
                  riga('Stato Pagamento', 'Da pagare'),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // DESTRA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  riga('Destinazione', ordine.indirizzo ?? '-'),
                  riga('Contatto', ordine.telefono ?? '-'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
        ),
      ],
    );
  }
}
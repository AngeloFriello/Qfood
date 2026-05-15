/* import 'package:dashboard/config/responsive.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:dashboard/ui/screen/ordini/ux/widgets/ordini_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/ordini_list_controller.dart';
import '../../models/ordine_tipo.dart';
import '../../models/ordine_stato.dart';


class OrdiniFiltersBar extends StatefulWidget {
  const OrdiniFiltersBar({super.key});

  @override
  State<OrdiniFiltersBar> createState() => _OrdiniFiltersBarState();
}

class _OrdiniFiltersBarState extends State<OrdiniFiltersBar> {
  List<OperatoreModel> riders            = [];

    @override
    void initState() {
      getRiders();
      super.initState();
    }

    Future<void> getRiders ()async{
     List<OperatoreModel> temp = await OperatoreModel.getOperators();
     setState(() {
       riders = temp.where((o)=> o.rider == 1).toList();
     });
    }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OrdiniListController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    TextEditingController riderController = TextEditingController(text: null);
    final ctrFilterSelectedOrder = context.watch<ControllerOrdiniSelezionati>();



    final bgColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFF8AC926); // verde QFood più scuro

    return Container(
      height: 56,                 // 🔥 compatta e incollata all’header
      width: double.infinity,     // 🔥 full-bleed
      color: bgColor,
      child: context.r.isMobile
      ?  
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // margine minimo solo estetico (NON padding)
            const SizedBox(width: 32),
        
            // ------------------ TAB SINISTRA ------------------
            _TipoChip(
              label: 'Tutti',
              badge: ctrl.totaleOrdini,
              selected: ctrl.filtroTipo == null,
              onTap: () => ctrl.setTipo(null),
            ),
        
            _TipoChip(
              label: 'Ritiro',
              badge: ctrl.totaleRitiro,
              selected: ctrl.filtroTipo == OrdineTipo.ritiro,
              onTap: () => ctrl.setTipo(OrdineTipo.ritiro),
            ),
        
            _TipoChip(
              label: 'Consegna',
              badge: ctrl.totaleConsegna,
              selected: ctrl.filtroTipo == OrdineTipo.consegna,
              onTap: () => ctrl.setTipo(OrdineTipo.consegna),
            ),
        
            _TipoChip(
              label: 'Mangia qui',
              badge: ctrl.totaleMangiaQui,
              selected: ctrl.filtroTipo == OrdineTipo.mangiaQui,
              onTap: () => ctrl.setTipo(OrdineTipo.mangiaQui),
            ),
        
             Text('Totale A: 2000'),
            /* const Spacer(), */

            Container(
              width: 200,
              child: DropdownMenu(
                hintText: 'Rider',
                controller: riderController,
                onSelected: (value) async {
                  int? idRaider = value as int?;
                  ctrl.setFilterIdRider( idRaider );
                },
                width: OrdiniColumns.raider,
                enableFilter: false,
                enableSearch: false,
                initialSelection: ctrl.idRiderFilter,
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                    value: null,
                    label: 'Nessuno',
                  ),
                  ...riders.map((s) => DropdownMenuEntry(
                  value: s.id,
                  label: s.title,
                )).toList()],
              ),
            ),

            // ------------------ DESTRA ------------------
            _DropdownButton(
              label: ctrl.filtroStato?.label ?? 'Tutti gli stati',
              onTap: () => _showStatiDialog(context),
            ),
            const SizedBox(width: 8),
        
        
            const SizedBox(width: 12), // simmetria destra
          ],
        ),
      )
      : 
      Row(
        children: [
          const SizedBox(width: 32),

          _TipoChip(
            label: 'Tutti',
            badge: ctrl.totaleOrdini,
            selected: ctrl.filtroTipo == null,
            onTap: () => ctrl.setTipo(null),
          ),

          _TipoChip(
            label: 'Ritiro',
            badge: ctrl.totaleRitiro,
            selected: ctrl.filtroTipo == OrdineTipo.ritiro,
            onTap: () => ctrl.setTipo(OrdineTipo.ritiro),
          ),

          _TipoChip(
            label: 'Consegna',
            badge: ctrl.totaleConsegna,
            selected: ctrl.filtroTipo == OrdineTipo.consegna,
            onTap: () => ctrl.setTipo(OrdineTipo.consegna),
          ),

          _TipoChip(
            label: 'Mangia qui',
            badge: ctrl.totaleMangiaQui,
            selected: ctrl.filtroTipo == OrdineTipo.mangiaQui,
            onTap: () => ctrl.setTipo(OrdineTipo.mangiaQui),
          ),
          const Spacer(),

          Text('Totale: ${ctrFilterSelectedOrder.totalNotPaid( ctrl.ordiniFiltrati )}'),
          const Spacer(),
          Text('Totale selezionato: ${ctrFilterSelectedOrder.totalNotPaidSelected()}'),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              for( final o in ctrFilterSelectedOrder.idsOrdersDeliverySelected ){
                await Ordine.changeStatus( o.id ?? 0, OrdineStato.completato.label );
              }
              ctrFilterSelectedOrder.resetOrder();
              await ctrl.getOrders();
            }, 
            child: Text('Completa ordini')
          ),
          const Spacer(),

          Container(
              width: 200,
              child: DropdownMenu(
                hintText: 'Rider',
                controller: riderController,
                
                onSelected: (value) async {
                  int? idRaider = value as int?;
                  ctrl.setFilterIdRider( idRaider );
                },
                width: OrdiniColumns.raider,
                enableFilter: false,
                enableSearch: false,
                initialSelection: ctrl.idRiderFilter,
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                    value: null,
                    label: 'Nessuno',
                  ),
                  ...riders.map((s) => DropdownMenuEntry(
                  value: s.id,
                  label: s.title,
                )).toList()],
              ),
            ),


          _DropdownButton(
            label: ctrl.filtroStato?.label ?? 'Tutti gli stati',
            onTap: () => _showStatiDialog(context),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );

  }
}




class _TipoChip extends StatelessWidget {
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  const _TipoChip({
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primaryContainer,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}



//TUTTI GLI STATI / RIDER
class _DropdownButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DropdownButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.keyboard_arrow_down),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
    );
  }
}


void _showStatiDialog(BuildContext context) {
  final ctrl = context.read<OrdiniListController>();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('Filtra per stato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<OrdineStato?>(
              title: const Text('Tutti gli stati'),
              value: null,
              groupValue: ctrl.filtroStato,
              onChanged: (value) {
                ctrl.setStato(null);
                Navigator.pop(context);
              },
            ),
            ...OrdineStato.values.map((stato) {
              return RadioListTile<OrdineStato?>(
                title: Text(stato.label),
                value: stato,
                groupValue: ctrl.filtroStato,
                onChanged: (value) {
                  ctrl.setStato(value);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      );
    },
  );
}



 */

import 'package:dashboard/config/responsive.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:dashboard/ui/screen/ordini/ux/widgets/ordini_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/ordini_list_controller.dart';
import '../../models/ordine_tipo.dart';
import '../../models/ordine_stato.dart';

class OrdiniFiltersBar extends StatefulWidget {
  const OrdiniFiltersBar({super.key});

  @override
  State<OrdiniFiltersBar> createState() => _OrdiniFiltersBarState();
}

class _OrdiniFiltersBarState extends State<OrdiniFiltersBar> {
  List<OperatoreModel> riders = [];

  @override
  void initState() {
    getRiders();
    super.initState();
  }

  Future<void> getRiders() async {
    List<OperatoreModel> temp = await OperatoreModel.getOperators();
    setState(() {
      riders = temp.where((o) => o.rider == 1).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OrdiniListController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    TextEditingController riderController = TextEditingController(text: null);
    final ctrFilterSelectedOrder = context.watch<ControllerOrdiniSelezionati>();

    final bgColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFF8AC926);

    return Container(
      height: 56,
      width: double.infinity,
      color: bgColor,
      child: context.r.isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 32),
                  _TipoChip(
                    label: 'Tutti',
                    badge: ctrl.totaleOrdini,
                    selected: ctrl.filtroTipo == null,
                    onTap: () => ctrl.setTipo(null),
                  ),
                  _TipoChip(
                    label: 'Ritiro',
                    badge: ctrl.totaleRitiro,
                    selected: ctrl.filtroTipo == OrdineTipo.ritiro,
                    onTap: () => ctrl.setTipo(OrdineTipo.ritiro),
                  ),
                  _TipoChip(
                    label: 'Consegna',
                    badge: ctrl.totaleConsegna,
                    selected: ctrl.filtroTipo == OrdineTipo.consegna,
                    onTap: () => ctrl.setTipo(OrdineTipo.consegna),
                  ),
                  _TipoChip(
                    label: 'Mangia qui',
                    badge: ctrl.totaleMangiaQui,
                    selected: ctrl.filtroTipo == OrdineTipo.mangiaQui,
                    onTap: () => ctrl.setTipo(OrdineTipo.mangiaQui),
                  ),
                  Text('Totale A: 2000'),
                  Container(
                    width: 200,
                    child: DropdownMenu(
                      hintText: 'Rider',
                      controller: riderController,
                      onSelected: (value) async {
                        int? idRaider = value as int?;
                        ctrl.setFilterIdRider(idRaider);
                      },
                      width: OrdiniColumns.raider,
                      enableFilter: false,
                      enableSearch: false,
                      initialSelection: ctrl.idRiderFilter ?? null,
                      dropdownMenuEntries: [
                        DropdownMenuEntry(value: null, label: 'Nessuno'),
                        ...riders.map((s) => DropdownMenuEntry(
                              value: s.id,
                              label: s.title,
                            )).toList(),
                      ],
                    ),
                  ),
                  _DropdownButton(
                    label: ctrl.filtroStato?.label ?? 'Tutti gli stati',
                    onTap: () => _showStatiDialog(context),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 12),
                ],
              ),
            )
          : Row(
              children: [
                const SizedBox(width: 32),
                _TipoChip(
                  label: 'Tutti',
                  badge: ctrl.totaleOrdini,
                  selected: ctrl.filtroTipo == null,
                  onTap: () => ctrl.setTipo(null),
                ),
                _TipoChip(
                  label: 'Ritiro',
                  badge: ctrl.totaleRitiro,
                  selected: ctrl.filtroTipo == OrdineTipo.ritiro,
                  onTap: () => ctrl.setTipo(OrdineTipo.ritiro),
                ),
                _TipoChip(
                  label: 'Consegna',
                  badge: ctrl.totaleConsegna,
                  selected: ctrl.filtroTipo == OrdineTipo.consegna,
                  onTap: () => ctrl.setTipo(OrdineTipo.consegna),
                ),
                _TipoChip(
                  label: 'Mangia qui',
                  badge: ctrl.totaleMangiaQui,
                  selected: ctrl.filtroTipo == OrdineTipo.mangiaQui,
                  onTap: () => ctrl.setTipo(OrdineTipo.mangiaQui),
                ),
                const Spacer(),

                // ── Totale ordini ──────────────────────────────────────
                _ModernInfoCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Totale ordini',
                  value:
                      '${ctrFilterSelectedOrder.totalNotPaid(ctrl.ordiniFiltrati).toStringAsFixed(2)} €',
                ),
                const SizedBox(width: 20),

                // ── Totale selezionato ─────────────────────────────────
                _ModernInfoCard(
                  icon: Icons.payments_outlined,
                  title: 'Totale selezionato',
                  value:
                      '${ctrFilterSelectedOrder.totalNotPaidSelected().toStringAsFixed(2)} €',
                ),
                const SizedBox(width: 20),

                // ── Completa ordini ────────────────────────────────────
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: () async {
                      for (final o
                          in ctrFilterSelectedOrder.idsOrdersDeliverySelected) {
                        await Ordine.changeStatus(
                          o.id ?? 0,
                          OrdineStato.completato.label,
                        );
                      }
                      ctrFilterSelectedOrder.resetOrder();
                      await ctrl.getOrders();
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 22),
                    label: const Text(
                      'Completa ordini',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF242424)
                          : Colors.white,
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF171F2D),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: BorderSide(
                        color: Colors.white.withOpacity(isDark ? 0.04 : 0.12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // ── Dropdown Rider ─────────────────────────────────────
                SizedBox(
                  width: 220,
                  child: DropdownMenu<int?>(
                    controller: riderController,
                    hintText: 'Rider',
                    leadingIcon: Icon(
                      Icons.delivery_dining_rounded,
                      size: 20,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                    onSelected: (value) async {
                      int? idRaider = value;
                      ctrl.setFilterIdRider(idRaider);
                    },
                    width: 220,
                    enableFilter: false,
                    enableSearch: false,
                    initialSelection: ctrl.idRiderFilter,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        isDark ? const Color(0xFF2B2B2B) : Colors.white,
                      ),
                      elevation: const WidgetStatePropertyAll(5),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFF7F8F9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: Color(0xFFB5FF00),
                          width: 1.4,
                        ),
                      ),
                    ),
                    trailingIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                    selectedTrailingIcon: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 20,
                    ),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry<int?>(
                        value: null,
                        label: 'Nessuno',
                      ),
                      ...riders.map(
                        (s) => DropdownMenuEntry<int?>(
                          value: s.id,
                          label: s.title,
                          leadingIcon: CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                const Color(0xFFB5FF00).withOpacity(0.18),
                            child: Text(
                              s.title.isNotEmpty
                                  ? s.title[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF708C00),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filtro stati ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 20),
                  child: _DropdownButton(
                    label: ctrl.filtroStato?.label ?? 'Tutti gli stati',
                    onTap: () => _showStatiDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TipoChip extends StatelessWidget {
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  const _TipoChip({
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primaryContainer,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DropdownButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DropdownButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.keyboard_arrow_down),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void _showStatiDialog(BuildContext context) {
  final ctrl = context.read<OrdiniListController>();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('Filtra per stato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<OrdineStato?>(
              title: const Text('Tutti gli stati'),
              value: null,
              groupValue: ctrl.filtroStato,
              onChanged: (value) {
                ctrl.setStato(null);
                Navigator.pop(context);
              },
            ),
            ...OrdineStato.values.map((stato) {
              return RadioListTile<OrdineStato?>(
                title: Text(stato.label),
                value: stato,
                groupValue: ctrl.filtroStato,
                onChanged: (value) {
                  ctrl.setStato(value);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ModernInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ModernInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : const Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFB5FF00).withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF708C00)),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF171F2D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
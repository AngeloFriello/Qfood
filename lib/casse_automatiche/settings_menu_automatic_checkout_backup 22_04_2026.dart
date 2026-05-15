import 'dart:convert';

import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:dashboard/casse_automatiche/bs/bsCash.dart';
import 'package:dashboard/casse_automatiche/cashlogyTcp/protocol.dart';
import 'package:dashboard/casse_automatiche/cashmatic/http_protocol.dart';
import 'package:dashboard/casse_automatiche/vne/emptyDrawer.dart';
import 'package:dashboard/casse_automatiche/vne/http_protocol.dart';
import 'package:dashboard/casse_automatiche/vne/refill.dart';
import 'package:dashboard/casse_automatiche/vne/reset.dart';
import 'package:dashboard/config/costanti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/controller_impostazioni.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════════════
// COSTANTI
// ═══════════════════════════════════════════════════════════════════════════

const _kDefaultPin = '1234';
const _kVerde      = Color(0xFF95C01F);
const _kVerdeDark  = Color(0xFF6E8E16);
const _kBgLight    = Color(0xFFF7F7F2);
const _kBgDark     = Color(0xFF111111);
const _kCardDark   = Color(0xFF1E1E1E);

// ═══════════════════════════════════════════════════════════════════════════
// MODELLI CASSA — compatibilità azioni
// ═══════════════════════════════════════════════════════════════════════════

/// Restituisce true se l'azione [action] è supportata dal modello [model].
bool _isActionEnabled(String action, String? model) {
  if (model == null) return false;
  switch (action) {
    case 'versamento':
      // Tutti i modelli supportano il versamento
      return true;
    case 'prelievo':
      // Tutti i modelli supportano il prelievo
      return true;
    case 'ritira_monete':
      // cashlogy_tcp (placeholder) e cashmatic
      return model == 'cashlogy_tcp' || model == 'cashmatic';
    case 'cambio_banconote':
      // Solo bs_cash e cashmatic
      return model == 'bs_cash' || model == 'cashmatic';
    case 'trasferisci_banconote':
      // Solo cashmatic
      return model == 'cashmatic';
    case 'ritira_tutto':
      // cashmatic e vne
      return model == 'cashmatic' || model == 'vne';
    case 'stato_cashlogy':
      // Solo cashlogy_tcp
      return model == 'cashlogy_tcp';
    case 'reset':
      // cashlogy_tcp e vne
      return model == 'cashlogy_tcp' || model == 'vne';
    case 'annulla_bs':
      // Solo bs_cash
      return model == 'bs_cash';
    default:
      return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS / CONTROLLER
// ═══════════════════════════════════════════════════════════════════════════

class DrawerAutomacitModel extends ControllerAutomaticCheckout {
  final int     id;
  final String  model;
  final String  title;
  final dynamic params;

  DrawerAutomacitModel({
    required this.id,
    required this.model,
    required this.title,
    required this.params,
  });

  static Future<void> getDrawers(BuildContext context) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");
      final idStore = prefs.getInt("idStore");
      final url = "https://$istanza-api.qfood.it/api/v1/cash_drawer/listCashDrawers/b6abeed3457e?idStore=$idStore";
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          "x-api-key":     posApiKey,
          "Authorization": "Bearer $token",
          "Content-Type":  "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final decode = jsonDecode(resp.body);
        List<DrawerAutomacitModel> temp = [];
        if (decode != null && (decode['data'] as List).isNotEmpty) {
          temp = (decode['data'] as List)
              .map((rd) => DrawerAutomacitModel(
                    id:     rd['id'],
                    model:  rd['model'],
                    title:  rd['title'],
                    params: jsonDecode(rd['params']),
                  ))
              .toList();
        }
        final ctrAutDrawer = context.read<ControllerAutomaticCheckout>();
        ctrAutDrawer.setDrawers(temp);
        final pref   = await SharedPreferences.getInstance();
        final encode = pref.getString('drawer');
        if (encode == null) return;
        final dec = jsonDecode(encode);
        ctrAutDrawer.setSelectedDrawer(DrawerAutomacitModel(
          id:     dec['id'],
          model:  dec['model'],
          title:  dec['title'],
          params: dec['params'],
        ));
      }
    } catch (err) {
      debugPrint(err.toString());
    }
  }
}

class ControllerAutomaticCheckout extends ChangeNotifier {
  DrawerAutomacitModel?      _selectedDrawer;
  DrawerAutomacitModel? get  idSelectedDrawer => _selectedDrawer;
  String? get model    => _selectedDrawer?.model;
  String? get endpoint => _selectedDrawer?.params?['endpoint_url'];
  String? get username => _selectedDrawer?.params?['username'];
  String? get password => _selectedDrawer?.params?['password'];
  List<DrawerAutomacitModel> _drawers = [];
  List<DrawerAutomacitModel> get drawers => _drawers;

  void setDrawers(List<DrawerAutomacitModel> dd) => _drawers = dd;

  void setSelectedDrawer(DrawerAutomacitModel? d) async {
    final pref = await SharedPreferences.getInstance();
    _selectedDrawer = d;
    if (d == null) {
      pref.remove('drawer');
    } else {
      pref.setString('drawer', jsonEncode({
        'id':     d.id,
        'model':  d.model,
        'title':  d.title,
        'params': d.params,
      }));
    }
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET PRINCIPALE
// ═══════════════════════════════════════════════════════════════════════════

class SettingAutomaticCheckout extends StatefulWidget {
  const SettingAutomaticCheckout({super.key});

  @override
  State<SettingAutomaticCheckout> createState() =>
      _SettingAutomaticCheckoutState();
}

class _SettingAutomaticCheckoutState extends State<SettingAutomaticCheckout> {
  bool   _pinUnlocked = false;
  String _pinBuffer   = '';
  bool   _pinError    = false;
  String _savedPin    = _kDefaultPin;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _savedPin = prefs.getString('drawer_pin') ?? _kDefaultPin);
  }

  void _onPinKey(String key) {
    if (_pinBuffer.length >= 4) return;
    setState(() {
      _pinError  = false;
      _pinBuffer += key;
    });
    if (_pinBuffer.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (_pinBuffer == _savedPin) {
          setState(() { _pinUnlocked = true; _pinBuffer = ''; });
        } else {
          setState(() { _pinError = true; _pinBuffer = ''; });
        }
      });
    }
  }

  void _onPinDelete() => setState(() {
    _pinError = false;
    if (_pinBuffer.isNotEmpty) {
      _pinBuffer = _pinBuffer.substring(0, _pinBuffer.length - 1);
    }
  });

  void _lock() => setState(() { _pinUnlocked = false; _pinBuffer = ''; });

  @override
  Widget build(BuildContext context) {
    final imp    = context.watch<ImpostazioniController>();
    final isDark = imp.darkMode || Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? _kBgDark   : _kBgLight;
    final card   = isDark ? _kCardDark : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // ── Pannello sinistro: PIN + lista ──
          SizedBox(
            width: 300,
            child: _buildDrawerPanel(isDark, card),
          ),
          Container(width: 1, color: Colors.grey.shade300),
          // ── Pannello destra: azioni ──
          Expanded(child: _buildActionsPanel(isDark, card, context)),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _kVerde,
    elevation: 0,
    title: const Text(
      'Casse Automatiche',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
    ),
    actions: [
      if (_pinUnlocked)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: _lock,
            icon: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            label: const Text('Blocca', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ),
    ],
  );

  // ── Pannello lista casse ─────────────────────────────────────────────────
  Widget _buildDrawerPanel(bool isDark, Color card) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _pinUnlocked
          ? _buildDrawerList(isDark, card)
          : _buildPinPad(isDark),
    );
  }

  // ── PIN PAD ──────────────────────────────────────────────────────────────
  Widget _buildPinPad(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    return Container(
      key: const ValueKey('pin'),
      color: isDark ? const Color(0xFF161616) : const Color(0xFFF0F0EC),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kVerde.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: _kVerde, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Accesso protetto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 6),
          Text('Inserisci il PIN per gestire le casse',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5))),
          const SizedBox(height: 28),

          // Pallini
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _pinBuffer.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pinError
                      ? Colors.red.shade400
                      : filled ? _kVerde : Colors.transparent,
                  border: Border.all(
                    color: _pinError
                        ? Colors.red.shade400
                        : filled ? _kVerde : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          if (_pinError) ...[
            const SizedBox(height: 10),
            Text('PIN errato',
                style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 28),

          // Tastierino
          GridView.count(
            crossAxisCount:  3,
            shrinkWrap:      true,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...['1','2','3','4','5','6','7','8','9'].map(
                (k) => _PinKey(label: k, isDark: isDark, onTap: () => _onPinKey(k)),
              ),
              const SizedBox.shrink(),
              _PinKey(label: '0', isDark: isDark, onTap: () => _onPinKey('0')),
              _PinDeleteKey(isDark: isDark, onTap: _onPinDelete),
            ],
          ),
        ],
      ),
    );
  }

  // ── LISTA CASSE ──────────────────────────────────────────────────────────
  Widget _buildDrawerList(bool isDark, Color card) {
    final ctrlDrawer = context.watch<ControllerAutomaticCheckout>();
    final textColor  = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
      key: const ValueKey('list'),
      color: isDark ? const Color(0xFF161616) : const Color(0xFFF0F0EC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(children: [
              const Icon(Icons.point_of_sale_rounded, color: _kVerde, size: 20),
              const SizedBox(width: 8),
              Text('Cassetti disponibili',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const Spacer(),
              Text('${ctrlDrawer.drawers.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: _kVerde,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ctrlDrawer.drawers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Nessun cassetto configurato',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: ctrlDrawer.drawers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final d        = ctrlDrawer.drawers[i];
                      final selected = ctrlDrawer._selectedDrawer?.id == d.id;
                      return _DrawerTile(
                        drawer:   d,
                        selected: selected,
                        isDark:   isDark,
                        onTap: () {
                          if (selected) {
                            ctrlDrawer.setSelectedDrawer(null);
                          } else {
                            if (d.model == 'cashlogy_tcp' &&
                                d.params['ip_address'] is String &&
                                int.tryParse(d.params['port']) != null) {
                              CashlogyService.getInstance(
                                d.params['ip_address'],
                                int.tryParse(d.params['port'])!,
                              );
                            }
                            ctrlDrawer.setSelectedDrawer(d);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── PANNELLO AZIONI ──────────────────────────────────────────────────────
  Widget _buildActionsPanel(bool isDark, Color card, BuildContext context) {
    final ctrl  = context.watch<ControllerAutomaticCheckout>();
    final model = ctrl.model; // null se nessun cassetto selezionato

    final actions = <_ActionDef>[
      _ActionDef(
        label:   'Versamento',
        icon:    Icons.arrow_circle_down_rounded,
        color:   const Color(0xFF10B981),
        key:     'versamento',
        enabled: _isActionEnabled('versamento', model),
        onTap:   () => refill(context),
      ),
      _ActionDef(
        label:   'Prelievo',
        icon:    Icons.arrow_circle_up_rounded,
        color:   const Color(0xFF3B82F6),
        key:     'prelievo',
        enabled: _isActionEnabled('prelievo', model),
        onTap:   () => withDraw(context),
      ),
      _ActionDef(
        label:   'Ritira monete',
        icon:    Icons.toll_rounded,
        color:   const Color(0xFFF59E0B),
        key:     'ritira_monete',
        enabled: _isActionEnabled('ritira_monete', model),
        onTap:   () => withDrawCoins(context),
      ),
      _ActionDef(
        label:   'Cambio banconote',
        icon:    Icons.currency_exchange_rounded,
        color:   const Color(0xFF8B5CF6),
        key:     'cambio_banconote',
        enabled: _isActionEnabled('cambio_banconote', model),
        onTap:   () => changeCash(context),
      ),
      _ActionDef(
        label:   'Trasferisci banconote',
        icon:    Icons.swap_horiz_rounded,
        color:   const Color(0xFF06B6D4),
        key:     'trasferisci_banconote',
        enabled: _isActionEnabled('trasferisci_banconote', model),
        onTap:   () => withDrawCash(context),
      ),
      _ActionDef(
        label:   'Ritira tutto',
        icon:    Icons.account_balance_wallet_rounded,
        color:   const Color(0xFFEF4444),
        key:     'ritira_tutto',
        enabled: _isActionEnabled('ritira_tutto', model),
        onTap:   () => getAll(context),
      ),
      _ActionDef(
        label:   'Stato Cashlogy TCP',
        icon:    Icons.monitor_heart_rounded,
        color:   const Color(0xFF64748B),
        key:     'stato_cashlogy',
        enabled: _isActionEnabled('stato_cashlogy', model),
        onTap: () {
          try {
            final ctrlAuto = context.read<ControllerAutomaticCheckout>();
            final cash = ctrlAuto.idSelectedDrawer;
            if (cash == null) return;
            CashlogyService.getInstance(
              cash.params['ip_address'],
              int.tryParse(cash.params['port'] ?? '') ?? 0,
            ).getStatus(screenAlwaysOnTop: true);
          } catch (err) { debugPrint(err.toString()); }
        },
      ),
      _ActionDef(
        label:   'Reset',
        icon:    Icons.restart_alt_rounded,
        color:   const Color(0xFFEC4899),
        key:     'reset',
        enabled: _isActionEnabled('reset', model),
        onTap:   () => reset(context),
      ),
      _ActionDef(
        label:   'Annulla pag. BS Cash',
        icon:    Icons.cancel_rounded,
        color:   const Color(0xFFDC2626),
        key:     'annulla_bs',
        enabled: _isActionEnabled('annulla_bs', model),
        onTap: () {
          final appState = BSCASHCONTROLLER();
          showStornoDialog(context, appState);
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedDrawerBadge(ctrl: ctrl, isDark: isDark),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing:   14,
                mainAxisSpacing:    14,
                childAspectRatio:   1.15,
              ),
              itemCount: actions.length,
              itemBuilder: (_, i) => _ActionCard(
                def:    actions[i],
                isDark: isDark,
                card:   card,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SOTTO-WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _PinKey extends StatelessWidget {
  final String label;
  final bool   isDark;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
    borderRadius: BorderRadius.circular(10),
    elevation: 1,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Center(
        child: Text(label,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
      ),
    ),
  );
}

class _PinDeleteKey extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onTap;

  const _PinDeleteKey({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
    borderRadius: BorderRadius.circular(10),
    elevation: 1,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: const Center(
        child: Icon(Icons.backspace_outlined, size: 20, color: Colors.grey),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final DrawerAutomacitModel drawer;
  final bool         selected;
  final bool         isDark;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.drawer,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  IconData _iconForModel(String m) {
    if (m.contains('cashlogy'))  return Icons.developer_board_rounded;
    if (m.contains('cashmatic')) return Icons.point_of_sale_rounded;
    if (m.contains('vne'))       return Icons.account_balance_rounded;
    if (m.contains('bs_cash'))   return Icons.savings_rounded;
    return Icons.payments_rounded;
  }

  String _labelForModel(String m) {
    if (m.contains('cashlogy'))  return 'Cashlogy TCP';
    if (m.contains('cashmatic')) return 'Cashmatic';
    if (m.contains('vne'))       return 'VNE';
    if (m.contains('bs_cash'))   return 'BS Cash';
    return m;
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: selected
          ? _kVerde.withOpacity(isDark ? 0.2 : 0.08)
          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected ? _kVerde : Colors.grey.withOpacity(0.2),
        width: selected ? 2 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? _kVerde.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconForModel(drawer.model),
              size: 18,
              color: selected ? _kVerde : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drawer.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(_labelForModel(drawer.model),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: _kVerde, size: 18),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _SelectedDrawerBadge extends StatelessWidget {
  final ControllerAutomaticCheckout ctrl;
  final bool isDark;

  const _SelectedDrawerBadge({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = ctrl.idSelectedDrawer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: d != null
            ? _kVerde.withOpacity(isDark ? 0.15 : 0.08)
            : Colors.grey.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: d != null
              ? _kVerde.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(children: [
        Icon(
          d != null ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          color: d != null ? _kVerde : Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: d != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cassetto attivo',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _kVerde,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    Text(d.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                  ],
                )
              : Text('Nessun cassetto selezionato',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500)),
        ),
        if (d != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kVerde.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(d.model,
                style: const TextStyle(
                    fontSize: 11,
                    color: _kVerdeDark,
                    fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionDef {
  final String       label;
  final IconData     icon;
  final Color        color;
  final String       key;
  final bool         enabled;
  final VoidCallback onTap;

  const _ActionDef({
    required this.label,
    required this.icon,
    required this.color,
    required this.key,
    required this.enabled,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionDef def;
  final bool       isDark;
  final Color      card;

  const _ActionCard({required this.def, required this.isDark, required this.card});

  @override
  Widget build(BuildContext context) {
    // Quando disabilitato: colori completamente neutralizzati
    final Color effectiveColor = def.enabled
        ? def.color
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade400);

    final Color bgColor = def.enabled
        ? card
        : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5));

    final Color textColor = def.enabled
        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    return Tooltip(
      message: def.enabled ? '' : 'Non disponibile per questa cassa',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: def.enabled ? 1.0 : 0.45,
        child: Material(
          color:        bgColor,
          borderRadius: BorderRadius.circular(16),
          elevation:    def.enabled ? 2 : 0,
          shadowColor:  effectiveColor.withOpacity(0.2),
          child: InkWell(
            // onTap null = nessuna interazione quando disabilitato
            onTap: def.enabled ? def.onTap : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: def.enabled ? effectiveColor.withOpacity(0.12) : Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: effectiveColor.withOpacity(isDark ? 0.35 : 0.15),
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: effectiveColor.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(def.icon, color: effectiveColor, size: 22),
                      ),
                      const Spacer(),
                      // Badge "N/D" quando disabilitato
                      if (!def.enabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'N/D',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    def.label,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FUNZIONI DI AZIONE (logica originale intatta)
// ═══════════════════════════════════════════════════════════════════════════

void reset(BuildContext context) async {
  try {
    final ctrlAutomaticCheckout  = context.read<ControllerAutomaticCheckout>();
    final modelAutomatickCeckout = ctrlAutomaticCheckout.model;
    if (modelAutomatickCeckout == 'cashlogy_tcp') {
      DrawerAutomacitModel? cash = ctrlAutomaticCheckout.idSelectedDrawer;
      if (cash == null) return;
      CashlogyService.getInstance(
        cash.params['ip_address'],
        int.tryParse(cash.params['port'] ?? '') ?? 0,
      ).recoverFromBusy();
    }

    if (modelAutomatickCeckout == 'vne') {
      DrawerAutomacitModel? drawer = ctrlAutomaticCheckout.idSelectedDrawer;
      if (drawer == null || drawer.params['machine_ip'] == null) return;
      showVneStackerResetModal(context, ipAddress: drawer.params['machine_ip']);
    }
  } catch (err) {
    debugPrint(err.toString());
  }
}

void changeCash(BuildContext context) async {
  if( operatorLogged!.acChange == 0 ){
    SnackBarForcedClosure('Operatore non abilitato', const Color.fromARGB(255, 253, 2, 2));
    return;
  }
  final ctrlAutomaticCheckout  = context.read<ControllerAutomaticCheckout>();
  final modelAutomatickCeckout = ctrlAutomaticCheckout.model;

  if (modelAutomatickCeckout != null) {
    if (modelAutomatickCeckout == 'bs_cash') {
      final ctrBs = context.read<BSCASHCONTROLLER>();
      String? in__  = ctrlAutomaticCheckout.idSelectedDrawer!.params['input_folder'];
      String? out__ = ctrlAutomaticCheckout.idSelectedDrawer!.params['output_folder'];
      if ([in__, out__].contains(null) || [in__, out__].contains('')) return;
      await ctrBs.login(in__!, out__!);
      final resp = await ctrBs.runCommand(BSCommand.CHNG, data: {});
      if (resp)  SnackBarForcedClosure('Cambio completo', Colors.green);
      if (!resp) SnackBarForcedClosure('Errore cambio',   Colors.red);
    }
    if (modelAutomatickCeckout == 'cashmatic') {
      Cashmatic cashmatic = await Cashmatic.instance(ctrlAutomaticCheckout.endpoint ?? '', 20);
      bool auth = await cashmatic.authenticate(
          ctrlAutomaticCheckout.username ?? '', ctrlAutomaticCheckout.password ?? '');
      if (!auth) {
        SnackBarForcedClosure(
            'Errore autenticazione Cashmatic. Controllare username e password', Colors.red);
        return;
      }
    }
  }
}

void refill(BuildContext context) async {
  if( operatorLogged!.acRefill == 0 ){
    SnackBarForcedClosure('Operatore non abilitato', const Color.fromARGB(255, 253, 2, 2));
    return;
  }
  final ctrlAutomaticCheckout  = context.read<ControllerAutomaticCheckout>();
  final modelAutomatickCeckout = ctrlAutomaticCheckout.model;
  int insert = 0;
  bool refilComplete = false;
  Function? stateBuild;

  if (modelAutomatickCeckout != null) {
    if (modelAutomatickCeckout == 'cashlogy_tcp') {
      DrawerAutomacitModel? cash = ctrlAutomaticCheckout.idSelectedDrawer;
      if (cash == null) return;
      await apriVersamento(context, CashlogyService.getInstance(
        cash.params['ip_address'],
        int.tryParse(cash.params['port'] ?? '') ?? 0,
      ));
    }

    if (modelAutomatickCeckout == 'vne') {
      DrawerAutomacitModel? drawer = ctrlAutomaticCheckout.idSelectedDrawer;
      if (drawer == null || drawer.params['machine_ip'] == null) return;
      showVneRefillModal(context, ipAddress: drawer.params['machine_ip']);
    }

    if (modelAutomatickCeckout == 'bs_cash') {
      final ctrBs = context.read<BSCASHCONTROLLER>();
      String? in__  = ctrlAutomaticCheckout.idSelectedDrawer!.params['input_folder'];
      String? out__ = ctrlAutomaticCheckout.idSelectedDrawer!.params['output_folder'];
      if ([in__, out__].contains(null) || [in__, out__].contains('')) return;
      await ctrBs.login(in__!, out__!);
      double? cash = await numericKeyboard(context, 0, title: 'Quanto vuoi versare?');
      if (cash == null) return;
      final payload = {
        "type":         "versamento",
        "identifier":   "DOC-${DateTime.now().millisecondsSinceEpoch}",
        "amount":       ctrBs.service.formatAmount(cash),
        "date":         DateTime.now().toIso8601String(),
        "cashRegister": "POS-01",
        "operator":     "Admin",
        "payments": [
          {"type": "cash", "amount": ctrBs.service.formatAmount(cash)},
        ],
      };
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (c) => AlertDialog(
          content: SizedBox(
            width: 300, height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Versamento in corso...'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async => ctrBs.cancelCurrentTransaction(),
                    child: const Text('Annulla'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      bool result = await ctrBs.runCommand(BSCommand.CHRG, data: payload);
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (result) SnackBarForcedClosure('Versamento completo', Colors.green);
    }

    if (modelAutomatickCeckout == 'cashmatic') {
      Cashmatic cashmatic =
          await Cashmatic.instance(ctrlAutomaticCheckout.endpoint ?? '', 20);
      bool auth = await cashmatic.authenticate(
          ctrlAutomaticCheckout.username ?? '', ctrlAutomaticCheckout.password ?? '');
      if (!auth) {
        SnackBarForcedClosure(
            'Errore autenticazione Cashmatic. Controllare username e password', Colors.red);
        return;
      }

      cashmatic.launchOperationAndWait(
        launchAndListenAsync: true,
        CashMaticOperation.refill,
        (data) {
          if (stateBuild == null) return;
          if (data!['data']['inserted'] > 0) {
            debugPrint(data['data']['inserted'].toString());
          }
          stateBuild!(() { insert = data!['data']['inserted'] as int; });
        },
      ).then((finaldata) {
        if (finaldata == null) {
          SnackBarForcedClosure('Chiusura improvvisa Cashmatic', Colors.red);
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          return;
        }
        if (finaldata['data'] != null) {
          if (finaldata['data']['requested'] <= finaldata['data']['inserted']) {
            if (stateBuild == null) return;
            stateBuild!(() { refilComplete = true; });
            SnackBarForcedClosure('Versamento terminato', Colors.green);
            Navigator.of(context).pop();
          }
        }
        debugPrint(finaldata.toString());
      });

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            stateBuild = setState;
            return AlertDialog(
              content: SizedBox(
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Totale:   ${insert / 100}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (refilComplete) return;
                            dynamic resp = await cashmatic.launchOperationAndWait(
                              CashMaticOperation.stopRefill,
                              (data) { debugPrint(data.toString()); },
                            );
                            if (resp != null) {
                              SnackBarForcedClosure(
                                  'Versamento completo', const Color.fromARGB(255, 255, 180, 18));
                              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Completa versamento'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

void withDraw(BuildContext context) async {
  if( operatorLogged!.acWithdrawal == 0 ){
    SnackBarForcedClosure('Operatore non abilitato', const Color.fromARGB(255, 253, 2, 2));
    return;
  }
  final ctrlAutomaticCheckout  = context.read<ControllerAutomaticCheckout>();
  final modelAutomatickCeckout = ctrlAutomaticCheckout.model;
  Function? stateBuild;
  String status    = 'Prelievo in corso...';
  int dispensed    = 0;
  int notDispensed = 0;

  if (modelAutomatickCeckout != null) {
    if (modelAutomatickCeckout == 'cashlogy_tcp') {
      DrawerAutomacitModel? cash = ctrlAutomaticCheckout.idSelectedDrawer;
      if (cash == null) return;
      await apriPrelievo(context, CashlogyService.getInstance(
        cash.params['ip_address'],
        int.tryParse(cash.params['port'] ?? '') ?? 0,
      ));
    }

    if (modelAutomatickCeckout == 'vne') {
      DrawerAutomacitModel? drawer = ctrlAutomaticCheckout.idSelectedDrawer;
      if (drawer == null || drawer.params['machine_ip'] == null) return;
      final result = await showVneWithdrawalDialog(
        context,
        ipMacchina: drawer.params['machine_ip'],
      );
      if (result.success) {
        // gestione post-prelievo VNE se necessario
      }
    }

    if (modelAutomatickCeckout == 'bs_cash') {
      final ctrBs = context.read<BSCASHCONTROLLER>();
      String? in__  = ctrlAutomaticCheckout.idSelectedDrawer!.params['input_folder'];
      String? out__ = ctrlAutomaticCheckout.idSelectedDrawer!.params['output_folder'];
      if ([in__, out__].contains(null) || [in__, out__].contains('')) return;
      await ctrBs.login(in__!, out__!);
      double? cash = await numericKeyboard(context, 0);
      if (cash == null) return;
      final payload = {
        "amount":     ctrBs.service.formatAmount(cash),
        "motivation": "Uscita Cassa Manuale",
      };
      bool resp = await ctrBs.runCommand(BSCommand.WTDW, data: payload);
      if (resp){
        LogService.instance().saveLog('Prelievo cassa','Prelevati ${ctrBs.service.formatAmount(cash)}','');
        SnackBarForcedClosure('Prelievo completo', Colors.green);
      }  
      if (!resp) SnackBarForcedClosure('Errore prelievo',   Colors.red);
    }

    if (modelAutomatickCeckout == 'cashmatic') {
      Cashmatic cashmatic =
          await Cashmatic.instance(ctrlAutomaticCheckout.endpoint ?? '', 180);
      bool auth = await cashmatic.authenticate(
          ctrlAutomaticCheckout.username ?? '', ctrlAutomaticCheckout.password ?? '');
      if (!auth) {
        SnackBarForcedClosure(
            'Errore autenticazione Cashmatic. Controllare username e password', Colors.red);
        return;
      }

      double? cash = await numericKeyboard(context, 0);
      if (cash == null) return;

      cashmatic.launchOperationAndWait(
        payload:             {"amount": (cash * 100).toInt()},
        launchAndListenAsync: true,
        CashMaticOperation.withdrawal,
        (data) {
          if (stateBuild == null || data == null) return;
          stateBuild!(() { dispensed = data['data']['dispensed']; });
        },
      ).then((finaldata) {
        if (finaldata == null) {
          SnackBarForcedClosure('Chiusura improvvisa Cashmatic', Colors.red);
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          return;
        }
        if (finaldata['data'] != null) {
          if (stateBuild == null) return;
          stateBuild!(() {
            status       = 'Prelievo completato';
            dispensed    = finaldata['data']['dispensed'];
            notDispensed = finaldata['data']['notDispensed'];
          });
          
          Future.delayed(const Duration(seconds: 5), () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return;
        }
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        SnackBarForcedClosure('Chiusura improvvisa Cashmatic', Colors.red);
        debugPrint(finaldata.toString());
      });

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            stateBuild = setState;
            return AlertDialog(
              content: SizedBox(
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(status),
                    const SizedBox(height: 30),
                    Text('Erogato: ${dispensed / 100}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('Non erogato: ${notDispensed / 100}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

void withDrawCoins(BuildContext context) async {
  if( operatorLogged!.acWithdrawal == 0 ){
    SnackBarForcedClosure('Operatore non abilitato', const Color.fromARGB(255, 253, 2, 2));
    return;
  }
  final ctrlAutomaticCheckout  = context.read<ControllerAutomaticCheckout>();
  final modelAutomatickCeckout = ctrlAutomaticCheckout.model;
  Function? stateBuild;
  String status = 'Prelievo in corso...';
  int dispensed = 0;

  if (modelAutomatickCeckout != null) {
    if (modelAutomatickCeckout == 'cashlogy_tcp') {
      // placeholder cashlogy
    }

    if (modelAutomatickCeckout == 'cashmatic') {
      Cashmatic cashmatic =
          await Cashmatic.instance(ctrlAutomaticCheckout.endpoint ?? '', 20);
      bool auth = await cashmatic.authenticate(
          ctrlAutomaticCheckout.username ?? '', ctrlAutomaticCheckout.password ?? '');
      if (!auth) {
        SnackBarForcedClosure(
            'Errore autenticazione Cashmatic. Controllare username e password', Colors.red);
        return;
      }

      cashmatic.launchOperationAndWait(
        launchAndListenAsync: false,
        CashMaticOperation.emptyCoins,
        (data) {
          if (stateBuild == null || data == null) return;
          stateBuild!(() { dispensed = data['data']['dispensed']; });
          Future.delayed(const Duration(seconds: 5), () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        },
      ).then((finaldata) {
        if (finaldata == null) {
          SnackBarForcedClosure('Chiusura improvvisa Cashmatic', Colors.red);
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          return;
        }
        if (finaldata['data'] != null) {
          if (stateBuild == null) return;
          stateBuild!(() {
            status    = 'Prelievo completato';
            dispensed = finaldata['data']['dispensed'];
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        }
        debugPrint(finaldata.toString());
      });

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            stateBuild = setState;
            return AlertDialog(
              content: SizedBox(
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(status),
                    const SizedBox(height: 30),
                    Text('Erogato: ${dispensed / 100}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

void withDrawCash(BuildContext context) async {
  final ctrlAutomaticCheckout  = context.read<ControllerAutomaticCheckout>();
  final modelAutomatickCeckout = ctrlAutomaticCheckout.model;
  Function? stateBuild;
  String status    = 'Prelievo in corso...';
  int dispensed    = 0;
  int notDispensed = 0;

  if (modelAutomatickCeckout != null) {
    if (modelAutomatickCeckout == 'cashmatic') {
      Cashmatic cashmatic =
          await Cashmatic.instance(ctrlAutomaticCheckout.endpoint ?? '', 20);
      bool auth = await cashmatic.authenticate(
          ctrlAutomaticCheckout.username ?? '', ctrlAutomaticCheckout.password ?? '');
      if (!auth) {
        SnackBarForcedClosure(
            'Errore autenticazione Cashmatic. Controllare username e password', Colors.red);
        return;
      }

      cashmatic.launchOperationAndWait(
        launchAndListenAsync: false,
        CashMaticOperation.emptyNotes,
        (data) {},
      ).then((finaldata) {
        if (finaldata == null) {
          SnackBarForcedClosure('Chiusura improvvisa Cashmatic', Colors.red);
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          return;
        }
        if (finaldata['data'] != null) {
          if (stateBuild == null) return;
          stateBuild!(() {
            status       = 'Prelievo completato';
            dispensed    = finaldata['data']['dispensed'];
            notDispensed = finaldata['data']['notDispensed'];
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        }
        debugPrint(finaldata.toString());
      });

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            stateBuild = setState;
            return AlertDialog(
              content: SizedBox(
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(status)],
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

void getAll(BuildContext context) async {
  final ctrlAutomaticCheckout  = context.read<ControllerAutomaticCheckout>();
  final modelAutomatickCeckout = ctrlAutomaticCheckout.model;
  Function? stateBuild;
  String status    = 'Prelievo in corso...';
  int dispensed    = 0;
  int notDispensed = 0;

  if (modelAutomatickCeckout != null) {
    if (modelAutomatickCeckout == 'cashmatic') {
      Cashmatic cashmatic =
          await Cashmatic.instance(ctrlAutomaticCheckout.endpoint ?? '', 20);
      bool auth = await cashmatic.authenticate(
          ctrlAutomaticCheckout.username ?? '', ctrlAutomaticCheckout.password ?? '');
      if (!auth) {
        SnackBarForcedClosure(
            'Errore autenticazione Cashmatic. Controllare username e password', Colors.red);
        return;
      }

      cashmatic.launchOperationAndWait(
        launchAndListenAsync: false,
        CashMaticOperation.emptyAll,
        (data) {},
      ).then((finaldata) {
        if (finaldata == null) {
          SnackBarForcedClosure('Chiusura improvvisa Cashmatic', Colors.red);
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          return;
        }
        if (finaldata['data'] != null) {
          if (stateBuild == null) return;
          stateBuild!(() {
            status       = 'Prelievo completato';
            dispensed    = finaldata['data']['dispensed'];
            notDispensed = finaldata['data']['notDispensed'];
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        }
        debugPrint(finaldata.toString());
      });

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            stateBuild = setState;
            return AlertDialog(
              content: SizedBox(
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(status)],
                ),
              ),
            );
          },
        ),
      );
    }

    if (modelAutomatickCeckout == 'vne') {
      DrawerAutomacitModel? drawer = ctrlAutomaticCheckout.idSelectedDrawer;
      if (drawer == null || drawer.params['machine_ip'] == null) return;
      showVneFullEmptyModal(context, ipAddress: drawer.params['machine_ip']);
    }
  }
}

Future<double?> numericKeyboard(
  BuildContext context,
  double initial, {
  String? title,
}) async {
  final ctrl = TextEditingController(text: initial.toString());
  return showDialog<double>(
    context: context,
    builder: (_) => AlertDialog(
      title:   Text(title ?? 'Quanto vuoi prelevare?'),
      content: TextField(
        controller:   ctrl,
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, double.tryParse(ctrl.text) ?? 0),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
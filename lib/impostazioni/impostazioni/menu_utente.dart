


import 'package:dashboard/ButtonFullScreen.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:dashboard/app/service/service_new_update.dart';
import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/casse_automatiche/settings_menu_automatic_checkout.dart';
import 'package:dashboard/config/responsive.dart';
import 'package:dashboard/impostazioni/impostazioni/tools/tools_vista.dart';
import 'package:dashboard/impostazioni/impostazioni/versione_progetto_page.dart';
import 'package:dashboard/modelli/pos.dart';
import 'package:dashboard/pagamenti_elettronici/pagamenti.dart';
import 'package:dashboard/state/app_session_controller.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/screen/ordini/state/ordine_attivo_controller.dart';
import '../../state/banco_state.dart';
import '../../state/controller_carrello.dart';
import 'debug_page.dart';
import '../../ui/screen/store_e_dispositivi/company_selector_vista.dart';
import 'chiusura_report_dialog.dart';
import 'distinta_turno_vista.dart';
import 'impostazioni_utente.dart';

class MenuUtente extends StatelessWidget {
  final VoidCallback onClose;

  const MenuUtente({super.key, required this.onClose, required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context_) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = theme.colorScheme.surface;
    final newUpdate  = context.watch<ControllerLastUpdate>();

    return Align(
      alignment: Alignment.topRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(top: 70, right: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: context.r.isDesktop
                  ? context.r.height * 0.75
                  : context.r.height * 0.70,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // HEADER DINAMICO
                  const HeaderMenuPOS(),
                  const StoreDeviceHeader(),
                  const SizedBox(height: 8),
                  WindowFullscreenToggle(),
                  _itemMenu(
                    context,
                    Icons.logout_rounded,
                    "Disconnetti",
                    coloreIcona: theme.colorScheme.error,
                    coloreTesto: theme.colorScheme.error,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
              
                      // ❗ NON uso prefs.clear()
                      // perché cancellerebbe tema, lingua, configurazioni utente ecc.
              
                      await prefs.remove("token");
                      await prefs.remove("istanza");
                      await prefs.remove("idCompany");
                      await prefs.remove("nomeCompany");
                      await prefs.remove("idStore");
                      await prefs.remove("storeTitle");
                      await prefs.remove("storeGuid");
                      await prefs.remove("idDevice");
                      await prefs.remove("deviceName");
                      await prefs.remove("deviceType");
                      await prefs.remove("identifier");
                      await prefs.remove("serverIp");
                      await prefs.remove("serverPort");
                      await prefs.remove("fiscalPrinterModel");
                      await prefs.remove("noFiscalPrinterModel");
              
                      // 🔥 FLAG DEL FLUSSO LOGIN
                      await prefs.setBool("logged", false);
                      await prefs.setBool("companySelected", false);
                      await prefs.setBool("storeSelected", false);
                      await prefs.setBool("deviceSelected", false);
              
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                  ),
                  
                  _itemMenu(
                    context,
                    Icons.sync_alt_outlined,
                    newUpdate.newSync ? 'Aggiornamento disponibile' : "Sync",
                    onTap: ()  { 
                      final ctrLastUpdate = context.read<ControllerLastUpdate>();
                      ctrLastUpdate.reset();
                     Navigator.pushReplacementNamed(context, '/sync');
                    },
                  ),
/*                   _itemMenu(
                    context,
                    Icons.work,
                    "Turno",
                    onTap: () async {
                      bool shiftOpened = await TurnoLavoro.lastShiftOpened( );
                      if (!shiftOpened ) {
                        final TextEditingController _titoloController    = TextEditingController();
                        final TextEditingController _fondoCassaController = TextEditingController();
                        final _formKey = GlobalKey<FormState>();

                        showDialog(
                          context: context,
                          builder: (context_) {
                            return AlertDialog(
                              title: Text('Apri turno'),
                              content: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      controller: _titoloController,
                                      decoration: InputDecoration(
                                        labelText: 'Titolo turno',
                                        hintText: 'Es. Turno mattina',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Inserisci il titolo del turno';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    TextFormField(
                                      controller: _fondoCassaController,
                                      decoration: InputDecoration(
                                        labelText: 'Fondo cassa iniziale',
                                        hintText: 'Es. 100.00',
                                        prefixText: '€ ',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Inserisci il fondo cassa';
                                        }
                                        if (double.tryParse(value.replaceAll(',', '.')) == null) {
                                          return 'Inserisci un valore valido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context_).pop(),
                                  child: Text('Annulla'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final String titolo = _titoloController.text.trim();
                                      final double fondoCassa = double.parse(
                                        _fondoCassaController.text.replaceAll(',', '.'),
                                      );

                                      int open = await TurnoLavoro.openShift(
                                          nomeTurno: titolo, 
                                          fondoCassaIniziale: fondoCassa,
                                      );
                                      if( open ==  0 ){
                                        SnackBarForcedClosure('Errore apertura turno', Colors.red);
                                        return;
                                      }
                                      SnackBarForcedClosure('Turno avviato', const Color.fromARGB(255, 70, 244, 54));
                                      Navigator.of(context_).pop();
                                    }
                                  },
                                  child: Text('Apri turno'),
                                ),
                              ],
                            );
                          },
                        );
                      }else{
                        showDialog(
                          context: context,
                          builder: (context_) {
                            final TextEditingController _fondoCassaFinaleController = TextEditingController();
                            final _formKey = GlobalKey<FormState>();
                            return AlertDialog(
                              icon: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
                              title: Text('Turno già aperto'),
                              content: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Non è possibile aprire un nuovo turno finché quello attuale non viene chiuso.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 20),
                                    TextFormField(
                                      controller: _fondoCassaFinaleController,
                                      decoration: InputDecoration(
                                        labelText: 'Fondo cassa lasciato',
                                        hintText: 'Es. 150.00',
                                        prefixText: '€ ',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Inserisci il fondo cassa lasciato';
                                        }
                                        if (double.tryParse(value.replaceAll(',', '.')) == null) {
                                          return 'Inserisci un valore valido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context_).pop(),
                                  child: Text('Annulla'),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: Icon(Icons.lock_outline),
                                  label: Text('Chiudi turno'),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final double fondoCassaFinale = double.parse(
                                        _fondoCassaFinaleController.text.replaceAll(',', '.'),
                                      );
                                      await TurnoLavoro.closeShift(
                                        fondoCassaFinale: fondoCassaFinale,
                                      );

                                      Navigator.of(context_).pop();
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ), */
                  _itemMenu(
                    context,
                    Icons.credit_card,
                    "Dispositivi pagamento",
                    onTap: () async { 
                     final resp = await PosModel.modalSelectedPos(context);
                     debugPrint(resp.toString());
                    },
                  ),
                  _itemMenu(
                    context,
                    Icons.change_circle,
                    "Logout operatore",
                    coloreIcona: theme.colorScheme.error,
                    coloreTesto: theme.colorScheme.error,
                    onTap: () async { 
                      await LogService.instance().saveLog('logout', 'da menu a tendina', '');
                      Navigator.pushReplacementNamed(context, '/login-operator');
                    },
                  ),
                  _itemMenu(context, Icons.refresh, "Ricarica"),
              
                  _itemMenu(context, Icons.build_circle_rounded, "Tools",
                      onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ToolsVista()));
                  }),
              
                  _itemMenu(
                    context,
                    Icons.settings_backup_restore_rounded,
                    "Riconfigura postazione",
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
              
                      // RESET SOLO CONFIGURAZIONE POSTAZIONE
                      await prefs.remove("idCompany");
                      await prefs.remove("nomeCompany");
                      await prefs.remove("idStore");
                      await prefs.remove("storeTitle");
                      await prefs.remove("storeGuid");
                      await prefs.remove("idDevice");
                      await prefs.remove("deviceName");
                      await prefs.remove("deviceType");
              
                      //  FLAG FLUSSO CONFIGURAZIONE
                      await prefs.setBool("companySelected", false);
                      await prefs.setBool("storeSelected", false);
                      await prefs.setBool("deviceSelected", false);
              
                      //  NON tocchiamo:
                      // - token
                      // - logged
              
                      if (!context.mounted) return;
              
                      //  RESET STATO APP
                      context.read<CarrelloController>().clearCart();
                      context.read<OrdineAttivoController>().clearOrdine();
              
                      //  VAI ALLA CONFIGURAZIONE (NON LOGIN)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const CompanySelectorVista()),
                        (route) => false,
                      );
                    },
                  ),
              
                  _itemMenu(
                    context,
                    Icons.undo_rounded,
                    "Reso merce",
                    onTap: () {
                      Navigator.pop(context); // chiude il menu se aperto
                      Navigator.pushNamed(
                          context, '/reso-merce'); // apre la pagina
                    },
                  ),
              
                  _itemMenu(
                    context,
                    Icons.badge,
                    "Operatori POS",
                    onTap: () {
                      ///Navigator.pop(context);
                      //Navigator.pushNamed(context, '/pos-operatori');
                    },
                  ),
              
                  ValueListenableBuilder<bool>(
                    valueListenable: bancoAbilitato,
                    builder: (context, isAttivo, _) {
                      if (!isAttivo) return const SizedBox.shrink();
              
                      return _itemMenu(
                        context,
                        Icons.bug_report_outlined,
                        "Debug DB",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DebugPage()),
                          );
                        },
                      );
                    },
                  ),
              
                  _itemMenu(
                    context,
                    Icons.info_outline,
                    "Versione Progetto",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VersioneProgettoPage()),
                      );
                    },
                  ),
              
                  _itemMenu(context, Icons.schedule_rounded, "Distinta turno",
                      onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DistintaTurnoVista()),
                    );
                  }),
              
                  _itemMenu(
                    context,
                    Icons.assignment_rounded,
                    "Chiusura / Report",
                    onTap: () async {
                      await mostraDialogChiusura(context);
                    },
                  ),
              
                  _itemMenu(context, Icons.account_tree_rounded,
                      "Funzioni st. fiscale"),
              
                  _itemMenu(context, Icons.settings, "Impostazioni", onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ImpostazioniUtente()),
                    );
                  }),

                  _itemMenu(context, Icons.credit_card_outlined, "Pagamenti elettronici", onTap: () async {
                   final db = await LocalDB.instance();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_)   {
                         return ElectronicPaymentsPage(
                            dao: ElectronicPaymentDao(db),
                          );
                        }
                      ),
                    );
                  }),

                  _itemMenu(context, Icons.paid_rounded, "Casse automatiche", onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingAutomaticCheckout()),
                    );
                  }),
              
                  _itemMenu(
                    context,
                    Icons.bug_report_outlined,
                    "Logs",
                    coloreIcona: Colors.grey.withOpacity(0.6),
                    testoDisabilitato: true,
                  ),
              
                  const Divider(height: 8, thickness: 0.7),
              
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemMenu(
    BuildContext context,
    IconData icona,
    String titolo, {
    VoidCallback? onTap,
    Color? coloreIcona,
    Color? coloreTesto,
    bool testoDisabilitato = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: testoDisabilitato
          ? null
          : () {
              onClose(); // ✅ chiude overlay
              if (onTap != null) onTap(); // esegue azione
            },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icona,
                color: coloreIcona ?? theme.colorScheme.onSurfaceVariant,
                size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titolo,
                style: TextStyle(
                  fontSize: 15,
                  color: coloreTesto ?? theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderMenuPOS extends StatefulWidget {
  const HeaderMenuPOS({super.key});

  @override
  State<HeaderMenuPOS> createState() => _HeaderMenuPOSState();
}

class _HeaderMenuPOSState extends State<HeaderMenuPOS> {
  String? storeName;
  int? idStore;
  String? operatorName;
  String? deviceName;

  @override
  void initState() {
    super.initState();
    _loadDatiReali();
  }

  Future<void> _loadDatiReali() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      // 🏬 STORE (arriva dal login)
      storeName = prefs.getString('storeName');
      idStore = prefs.getInt('idStore');

      // 👤 OPERATORE (arriva dopo syncOperators)
      operatorName = prefs.getString('operatorName');

      // 🧾 DEVICE (arriva dopo assignIdentifierToDevice)
      deviceName = prefs.getString('deviceName');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🔒 Nessuno store → niente header
    if (storeName == null || idStore == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // 🏬 NEGOZIO (OBBLIGATORIO)
          // =========================
          _row(
            icon: LucideIcons.store,
            text: '$storeName (ID $idStore)',
            theme: theme,
            bold: true,
          ),

          // =========================
          // 👤 OPERATORE (OPZIONALE)
          // =========================
          if (operatorName != null) ...[
            const SizedBox(height: 6),
            _row(
              icon: LucideIcons.user,
              text: operatorName!,
              theme: theme,
            ),
          ],

          // =========================
          // 🧾 CASSA / DEVICE (OPZIONALE)
          // =========================
          if (deviceName != null) ...[
            const Divider(height: 20),
            _row(
              icon: LucideIcons.creditCard,
              text: deviceName!,
              theme: theme,
            ),
          ],

          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String text,
    required ThemeData theme,
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class StoreDeviceHeader extends StatelessWidget {
  const StoreDeviceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ❌ niente store → niente header
    if (session.storeName == null) {
      return const SizedBox.shrink();
    }

    const verdeQFood = Color(0xFF95C01F);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withOpacity(isDark ? .35 : .6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: verdeQFood.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // 🏬 STORE (SEMPRE)
            // =========================
            Row(
              children: [
                _iconCircle(
                  icon: Icons.storefront,
                  color: verdeQFood,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.storeName!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // =========================
            // 🧾 DEVICE (SOLO SE ESISTE)
            // =========================
            if (session.deviceName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _iconCircle(
                    icon: Icons.point_of_sale,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.deviceName!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconCircle({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}

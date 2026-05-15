import 'dart:async';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_client.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/app/service/service_connection.dart';
import 'package:dashboard/app/service/service_transaction.dart';
import 'package:dashboard/ui/screen/prenotazioni/ui/prenotazioni/prenotazioni_page.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../config/responsive.dart';
import '../../../impostazioni/report_avanzato_vista.dart';
import '../../../state/controller_impostazioni.dart';
import '../../screen/ordini/state/ordini_list_controller.dart';
import '../../screen/ordini/ux/pages/ordini_page.dart';
import '../../screen/tavoli/tavoli_vista.dart';


class ControllerNuovoOrdine  extends ChangeNotifier {
  bool _nuovo = false;
  bool get nuovo => _nuovo;

  void setNuovo( bool n ){
    _nuovo = n;
    notifyListeners();
  }
}


class FooterNavbar extends StatefulWidget {
  final Widget? tastierino;   //  AGGIUNTO


  const FooterNavbar({
    super.key,
    this.tastierino,   //  AGGIUNTO
  });



  @override
  State<FooterNavbar> createState() => _FooterNavbarState();
}

class _FooterNavbarState extends State<FooterNavbar> {
  String orario = '';
  late StreamSubscription<InternetStatus> _subscription;
  int selezionato = 0;
  Timer? _timer;


  final List<_VoceFooter> voci = const [
    //  Sinistra
    _VoceFooter("Prenotazioni", LucideIcons.calendarDays),
    _VoceFooter("Report", LucideIcons.barChart3),
    //  Destra
    _VoceFooter("Bilancia",  LucideIcons.scale),
    _VoceFooter("Take Away", LucideIcons.shoppingBag),
    _VoceFooter("Cassetto",  LucideIcons.wallet),
    _VoceFooter("Tavoli",    LucideIcons.table2),
  ];

  @override
  void initState() {
    super.initState();
    _subscription = InternetConnection().onStatusChange.listen((status) {
      context.read<ConnectionController>().setRete( status == InternetStatus.connected );
    });
    aggiornaOra();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => aggiornaOra());
  }


  void aggiornaOra() {
    final ora = DateTime.now();
    setState(() {
      orario =
      "${_giorno(ora.weekday)} ${ora.day.toString().padLeft(2, '0')} ${_mese(ora.month)}  ${ora.hour.toString().padLeft(2, '0')}:${ora.minute.toString().padLeft(2, '0')}";
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
    _subscription.cancel();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ctrlConnection = context.watch<ConnectionController>();
    

    final ctrWS = context.watch<ControllerWsServer>();
    final ctrWSClient   = context.watch<ControllerWsClient>();


    //per gestire il mancino
    final imp = context.watch<ImpostazioniController>();
    final isLeft = imp.uiSide == "L";

    final r = context.r;

    final bool isMobile = r.isMobile;
    final bool isTablet = r.isTablet;

    final double fontSize = isMobile ? 12 : (isTablet ? 13 : 14);
    final double iconSize = isMobile ? 20 : (isTablet ? 22 : 24);
    final double altezza = isMobile ? 58 : (isTablet ? 66 : 70);

    final Color textColor = theme.colorScheme.onSurface;
    final Color activeColor = theme.colorScheme.primaryContainer;
    final Color inactiveColor =
    theme.colorScheme.surfaceContainerHighest.withOpacity(0.6);

    //  Dichiaro i gruppi (così non avrai più l'errore)
    final gruppoSinistra = voci.take(2).toList(); // Prenotazioni, Statistiche
    final gruppoDestra = voci.skip(2).toList();   // Bilancia, Take Away, Cassetto, Tavoli

    final ordiniCtrl = context.watch<OrdiniListController>();
    final int prenotazioniAttive = ordiniCtrl.countPrenotazioni;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: altezza,

      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)         //  Dark mode (come header dark)
            : const Color(0xFF97D700),        // ☀ Light mode (verde QFOOD)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      //@

      child: r.isDesktop
          ?
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),

          child: Row(
            textDirection:
            isLeft ? TextDirection.rtl : TextDirection.ltr,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment:
            isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              SizedBox(width: 10),
              deviceCurrent['deviceServer'] == 1
                  ?
              /// WS SERVER
              InkWell(
                  onLongPress: () => showDialog(context: context, builder: (context){
                    final ctrlWS = context.watch<ControllerWsServer>();
                    return Center(
                        child: Container(
                            color: Colors.white,
                            width: 300,
                            height: 300,
                            child: Column(
                              children: ctrlWS.clients.map((c)=> Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(c.idOperator.toString()),
                                  Text(c.deviceType),
                                ],
                              )).toList(),))); }),
                  onTap: () => ctrWS.stopForTest(), //FORZO LA CHIUSURA SERVE PER TESTARE IL RESTART
                  child: Text(
                    'WS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ctrWS.serverOpened ? theme.colorScheme.primary
                          : Colors.redAccent,
                    ),
                  )
              )
                  :
              /// WS Client
              InkWell(
                  onLongPress: () => ctrWSClient.connect(),
                  onTap: () => ctrWSClient.disconnect(), //FORZO LA CHIUSURA SERVE PER TESTARE IL RESTART
                  child: Text(
                    'C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ctrWSClient.connected ? theme.colorScheme.primary
                          : Colors.redAccent,
                    ),
                  )
              ),

              const SizedBox(width: 20),



              Row(
                children: [
                  Icon(
                    ctrlConnection.connected ? Icons.wifi : Icons.wifi_off,
                    color: ctrlConnection.connected
                        ? theme.colorScheme.primary
                        : Colors.redAccent,
                    size: iconSize,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    orario,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              //  SINISTRA — Stato rete + ora + Prenotazioni + Statistiche
              Row(
                children: [


                  SizedBox(width: 68),
                  ...gruppoSinistra.map((voce) {
                    final attivo = selezionato == voci.indexOf(voce);
                    return _bottoneFooter(
                      voce,
                      attivo,
                      theme,
                      iconSize,
                      fontSize,
                      activeColor,
                      inactiveColor,
                      textColor,
                      prenotazioniAttive,
                    );
                  }),





                ],
              ),


              Padding(
                padding: EdgeInsets.only(
                  right: isLeft ? 0 : 350,
                  left: isLeft ? 350 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: gruppoDestra.map((voce) {
                    final attivo = selezionato == voci.indexOf(voce);
                    return _bottoneFooter(
                      voce,
                      attivo,
                      theme,
                      iconSize,
                      fontSize,
                      activeColor,
                      inactiveColor,
                      textColor,
                      prenotazioniAttive,
                    );
                  }).toList(),
                ),
              ),


            ],
          )


      )
          :
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            deviceCurrent['deviceServer'] == 1
                ?
            /// WS SERVER
            InkWell(
                onLongPress: () => showDialog(context: context, builder: (context){
                  final ctrlWS = context.watch<ControllerWsServer>();
                  return Center(
                      child: Container(
                          color: Colors.white,
                          width: 300,
                          height: 300,
                          child: Column(
                            children: ctrlWS.clients.map((c)=> Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(c.idOperator.toString()),
                                Text(c.deviceType),
                              ],
                            )).toList(),))); }),
                onTap: () => ctrWS.stopForTest(), //FORZO LA CHIUSURA SERVE PER TESTARE IL RESTART
                child: Text(
                  'WS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: ctrWS.serverOpened ? theme.colorScheme.primary
                        : Colors.redAccent,
                  ),
                )
            )
                :
            /// WS Client
            InkWell(
                onLongPress: () => ctrWSClient.connect(),
                onTap: () => ctrWSClient.disconnect(), //FORZO LA CHIUSURA SERVE PER TESTARE IL RESTART
                child: Text(
                  'C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: ctrWSClient.connected ? theme.colorScheme.primary
                        : Colors.redAccent,
                  ),
                )
            ),


            const SizedBox(width: 6),

            Icon(
              ctrlConnection.connected ? Icons.wifi : Icons.wifi_off,
              color: ctrlConnection.connected
                  ? theme.colorScheme.primary
                  : Colors.redAccent,
              size: iconSize,
            ),

            const SizedBox(width: 6),

            Text(
              orario,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 20),

            ...voci.map((voce) {
              final attivo = selezionato == voci.indexOf(voce);
              return _bottoneFooter(
                voce,
                attivo,
                theme,
                iconSize,
                fontSize,
                activeColor,
                inactiveColor,
                textColor,
                prenotazioniAttive,
              );
            }).toList(),

            //  SPAZIO EXTRA PER TASTIERINO
            const SizedBox(width: 320),
          ],
        ),
      ),

    );
  }

  ///  Metodo per i pulsanti del footer
  Widget _bottoneFooter(
      _VoceFooter voce,
      bool attivo,
      ThemeData theme,
      double iconSize,
      double fontSize,
      Color activeColor,
      Color inactiveColor,
      Color textColor,
      int prenotazioniAttive,

      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          final index = voci.indexOf(voce);
          //  CASSETTO
          if (voce.titolo == "Cassetto") {
            ServiceReceipt.instance().openDrawer();
            return;
          }
          //  PRENOTAZIONE
          if (voce.titolo == "Prenotazioni") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrenotazioniPage(),
              ),
            );
            return;
          }
          //  REPORT = AZIONE
          if (voce.titolo == "Report") {
            if( operatorLogged!.displayDailyReport  == 0 ) {
              SnackBarForcedClosure('Operatore non abilitato', Colors.red);
              return;
            }
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReportAvanzatoVista(),
              ),
            );
            return;
          }
          //  PRENOTAZIONI = AZIONE (NON TAB)
          if (voce.titolo == "Take Away") {
            context.read<ControllerNuovoOrdine>().setNuovo(false);
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const OrdiniPage(),
              ),
            );
            return; //  non cambia selezionato
          }

          //  TAVOLI = TAB
          if (voce.titolo == "Tavoli") {
            setState(() => selezionato = index);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) =>  TavoliVista(key: vistaTableKey,)),
            );
            return;
          }

          //  ALTRE VOCI = TAB (per ora)
          setState(() => selezionato = index);
        },

        child: Consumer<ControllerNuovoOrdine>(
                builder: (context, value, child) {
                  final bool haNewOrder = voce.titolo == "Take Away" && value.nuovo == true;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: haNewOrder ? 1 : 0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, glow, _) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 6),
                        decoration: BoxDecoration(
                          color: attivo ? activeColor : inactiveColor,
                          borderRadius: BorderRadius.circular(10),
                          border: haNewOrder
                              ? Border.all(
                                  color: Colors.red.withOpacity(glow),
                                  width: 2,
                                )
                              : null,
                          boxShadow: haNewOrder
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.35 * glow),
                                    blurRadius: 12 * glow,
                                    spreadRadius: 2 * glow,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                voce.icona,
                                key: ValueKey(attivo),
                                color: attivo
                                    ? theme.colorScheme.onPrimaryContainer
                                    : textColor.withOpacity(0.8),
                                size: iconSize,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              children: [
                                Text(
                                  voce.titolo,
                                  style: TextStyle(
                                    color: attivo
                                        ? theme.colorScheme.onPrimaryContainer
                                        : textColor.withOpacity(0.9),
                                    fontSize: fontSize,
                                    fontWeight: attivo ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),

                                // 🔢 COUNTER PRENOTAZIONI
                                if (voce.titolo == "Take Away" && prenotazioniAttive > 0)
                                  AnimatedScale(
                                    scale: prenotazioniAttive > 0 ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.elasticOut,
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: attivo
                                            ? theme.colorScheme.onPrimaryContainer.withOpacity(.15)
                                            : Colors.black.withOpacity(.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        prenotazioniAttive.toString(),
                                        style: TextStyle(
                                          fontSize: fontSize - 1,
                                          fontWeight: FontWeight.w700,
                                          color: attivo
                                              ? theme.colorScheme.onPrimaryContainer
                                              : textColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                // 🔴 BADGE "Nuovo"
                                if (haNewOrder)
                                  _PulsingBadge(fontSize: fontSize),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

}

class _VoceFooter {
  final String titolo;
  final IconData icona;
  const _VoceFooter(this.titolo, this.icona);
}

class _PulsingBadge extends StatefulWidget {
  final double fontSize;
  const _PulsingBadge({required this.fontSize});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              'Nuovo',
              style: TextStyle(
                fontSize: (widget.fontSize - 4).clamp(8, 11).toDouble(),
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_client.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/modelli/articlePriceList.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/tavolo_action_panel.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/tavolo_action_panel_mobile.dart';
import 'package:flutter/material.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/tavolo_coperti_strip.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/tavolo_info_section.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/tavolo_order_section.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/tavolo_top_bar.dart';
import 'package:provider/provider.dart';

class TavoloOperativoPage extends StatefulWidget {

  final TableModel  tavolo;
  final int coperti;


  const TavoloOperativoPage({
    super.key,
    required this.tavolo,
    required this.coperti,
  });

  @override
  State<TavoloOperativoPage> createState() =>
      _TavoloOperativoPageState();
}

class _TavoloOperativoPageState extends State<TavoloOperativoPage> {
  List<ArticlePricesListModel> covers = [];

  void _openMobilePanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TavoloActionPanelMobile(
        coperti: widget.coperti,
      ),
    );
  }

  void firstStart () async {
    try{
      final ctrTableOpen = context.read<ControllerTableOpened>();
      ctrTableOpen.openTable(widget.tavolo);
    }catch( err ){
      debugPrint( err.toString() );
    }
  }

  @override
  void initState() {
    firstStart();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrTavolo = context.watch<ControllerTableOpened>();
    final ctrTableCart =
    context.watch<ControllerTableOpened>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {

        //TASTO INDIETRO DA PANNELLO ORDINE
        debugPrint( result.toString());
        final ctrTableOpened   = context.read<ControllerTableOpened>();
        TableModel? tabCurrent = ctrTableOpened.getTable();
        if( tabCurrent == null ) return;

        if( deviceCurrent['deviceServer'] == 1 ){
          final ctrWebSocketServer= context.read<ControllerWsServer>();
          ctrWebSocketServer.unLookTableServer(widget.tavolo.id);
          //ctrWebSocketServer.updateTableServer(widget.tavolo.id, tabCurrent);
          return;
        }

        final ctrWebSocketClient = context.read<ControllerWsClient>();
        ctrWebSocketClient.send(jsonEncode({ 'type' : 'unLockTable', 'idTable': widget.tavolo.id }));
        //ctrWebSocketClient.send(jsonEncode({ 'type' : 'updateTable', 'idOperator': operatorLogged!.id, 'table': tabCurrent.toMap(), 'idTable': widget.tavolo.id }));
      },
      child: Scaffold(
        backgroundColor: cs.background,
        body: SafeArea(
          child: Column(
            children: [
      
              /// TOP BAR
              TavoloTopBar(
                tavolo:  widget.tavolo,
                onOpenActionsMobile: _openMobilePanel,
              ),
      
              /// uscite STRIP
              TavoloExistStrip(
                uscite: widget.coperti,
                uscitaSelezionata: ctrTavolo.exitSelectedForProduct,
                onExitChanged: (v) => ctrTavolo.setExitSelectedForProcuct(v),
                onProcedi: () { 
                  ctrTavolo.setLastExit( ctrTavolo.lastExist + 1 );
                },
              ),
      
              /// CONTENUTO PRINCIPALE
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
      
                    final width = constraints.maxWidth;
      
                    final isDesktop = width > 1200;
                    final isTablet = width > 700 && width <= 1200;
                    final isMobile = width <= 700;
      
                    return Row(
                      children: [
      
                        /// ================= SINISTRA =================
                        Expanded(
                          child: Column(
                            children: [
      
                              /// INFO + ORDINI SCROLLABILI
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      TavoloInfoSection(
                                        tavolo: widget.tavolo,
                                      ),
      
                                      const SizedBox(height: 12),
      
                                      SizedBox(
                                        height: 500, // altezza base ordini
                                        child: TavoloOrderSection(),
                                      ),
      
                                    ],
                                  ),
                                ),
                              ),
      
                            ],
                          ),
                        ),
      
                        /// ================= PANEL DESKTOP =================
                        if (isDesktop)
                          SizedBox(
                            width: 320,
                            child: TavoloActionPanelDesktop(
                              tavolo: widget.tavolo,
                              setState: () => setState(() {}),
                              products: ctrTableCart.products,
                            ),
                          ),
      
                        if (isTablet)
                          SizedBox(
                            width: 260,
                            child: TavoloActionPanelDesktop(
                              tavolo: widget.tavolo,
                              setState: () => setState(() {}),
                              products: ctrTableCart.products,
                            ),
                          ),
      
                      ],
                    );
                  },
                ),
              ),
      
      
            ],
          ),
        ),
      ),
    );
  }
}


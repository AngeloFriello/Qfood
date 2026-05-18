import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_client.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/modelli/room.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/state/controller_impostazioni.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:dashboard/ui/screen/tavoli/widgets/coperti_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../ordini/ux/pages/ordini_page.dart';
import '../prenotazioni/ui/prenotazioni/prenotazioni_page.dart';
import '../sincronizzazioni/operatori/operator_preferences_controller.dart';
import 'header_footer/header_tavoli.dart';
import 'operativita/tavolo_operativo_page.dart';


enum TavoloAzione {
  apri,
  impegna,
  cancella,
  unisci,
  separa,
  sposta,
  visualizza,
  sblocca,
}

class TavoliVista extends StatefulWidget {
  const TavoliVista({super.key});

  @override
  State<TavoliVista> createState() => TavoliVistaState();
}

class TavoliVistaState extends State<TavoliVista> {
  int tabSelezionato = 0;
  String? filterStatusTable = 'Tutti';
  List<TableModel> tavoli = [];
  TavoloAzione azioneSelezionata = TavoloAzione.apri;
  List<Room> rooms = [];
  TableModel? tableMoved;
  List<TableModel> tablesForJoin = [];


  Widget _footerAzioniNavigazione() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          _navFooterBtn(
            "Prenotazioni",
            LucideIcons.calendarDays,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrenotazioniPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          _navFooterBtn(
            "Banco",
            LucideIcons.layoutDashboard,
            () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          const SizedBox(height: 10),
          _navFooterBtn(
            "Take Away",
            LucideIcons.shoppingBag,
            () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const OrdiniPage()),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _navFooterBtn(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF97D700).withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFF97D700).withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }


  void exitTable(int idTable) {
    try {
      final ctrl = context.read<ControllerTableOpened>();
      if (ctrl.table == null) return;
      if (idTable != ctrl.table!.id) return;
      ctrl.clearTable();
      while (navigatorKey.currentState!.canPop()) {
        navigatorKey.currentState!.pop();
      }
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  void setTableByServer() async {
    if (deviceCurrent["deviceServer"] == 0) {
      if (rooms.isNotEmpty) {
        tavoli = tableByServerForClient
            .where((t) => t.idRoom == (tabSelezionato == 0 ? rooms[0].id : tabSelezionato))
            .toList();
        if (filterStatusTable == 'Tutti')             tavoli = tavoli;
        if (filterStatusTable == 'Occupato')          tavoli = tavoli.where((t) => t.status == '').toList();
        if (filterStatusTable == 'Attesa')            tavoli = tavoli.where((t) => t.status == '').toList();
        if (filterStatusTable == 'Fine pasto')        tavoli = tavoli.where((t) => t.status == '').toList();
        if (filterStatusTable == 'Preconto')          tavoli = tavoli.where((t) => t.status == '').toList();
        if (filterStatusTable == 'Prodotti bloccati') tavoli = tavoli.where((t) => t.status == '').toList();
        if (filterStatusTable == 'Impegnato')         tavoli = tavoli.where((t) => t.status == 'impegnato').toList();
        if (filterStatusTable == 'Libero')            tavoli = tavoli.where((t) => t.status == null).toList();
        setState(() {});
      }
    }
    if (deviceCurrent["deviceServer"] == 1) {
      List table = await TableModel.listTableForRoom(tabSelezionato);
      List<TableModel> tables = (table as List).map((t) => TableModel.fromMap(t)).toList();
      if (filterStatusTable == 'Tutti')               tables = tables;
      if (filterStatusTable == 'Occupato')            tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Attesa')              tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Fine pasto')          tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Preconto')            tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Prodotti bloccati')   tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Impegnato')           tables = tables.where((t) => t.status == 'impegnato').toList();
      if (filterStatusTable == 'Libero')              tables = tables.where((t) => t.status == null).toList();
      setState(() {
        tavoli = tables;
      });
    }
  }

  Future<void> loadTable() async {
    if (!mounted) return;
    if (deviceCurrent['deviceServer'] == 1) {
      List table = await TableModel.listTableForRoom(tabSelezionato);
      List<TableModel> tables = (table as List).map((t) => TableModel.fromMap(t)).toList();
      if (filterStatusTable == 'Tutti')               tables = tables;
      if (filterStatusTable == 'Occupato')            tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Attesa')              tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Fine pasto')          tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Preconto')            tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Prodotti bloccati')   tables = tables.where((t) => t.status == '').toList();
      if (filterStatusTable == 'Impegnato')           tables = tables.where((t) => t.status == 'impegnato').toList();
      if (filterStatusTable == 'Libero')              tables = tables.where((t) => t.status == null).toList();
      setState(() {
        tavoli = tables;
      });
    } else {
      final ctrWSClient = context.read<ControllerWsClient>();
      ctrWSClient.send(jsonEncode({'type': 'getTables', 'idRoom': tabSelezionato}));
    }
  }

  Future<void> getRoom() async {
    try {
      final resp = await LocalDB.query('SELECT * FROM rooms');
      setState(() {
        rooms = resp.map((m) => Room.fromMap(m)).toList();
        if (resp.isNotEmpty) tabSelezionato = (resp[0]['id'] as int);
      });
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> firstStart() async {
    await getRoom();
    await loadTable();
  }

  @override
  void initState() {
    super.initState();
    firstStart();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      // [NUOVO] breakpoint mobile abbassato a 600
      final bool isMobile  = width < 600;
      final bool isTablet  = width >= 600 && width < 1100;
      final bool isDesktop = width >= 1100;

      // [NUOVO] debug print
      debugPrint("WIDTH: $width");
      debugPrint("isMobile: $isMobile");
      debugPrint("isTablet: $isTablet");
      debugPrint("isDesktop: $isDesktop");

      // [RIPRISTINATO] imp watch
      final imp = context.watch<ImpostazioniController>();
      // [NUOVO] op watch — sorgente primaria per tavoliRidotti
      final op = context.watch<OperatorPreferencesController>();
      bool tavoliRidotti = op.displayTableReduced;

      int crossAxisCount;
      double aspect;

      if (isMobile) {
        // [NUOVO] valori mobile aggiornati
        crossAxisCount = tavoliRidotti ? 5 : 2;
        aspect = tavoliRidotti ? 0.70 : 1.1;
      } else if (isTablet) {
        // [RIPRISTINATO] blocco tablet separato
        crossAxisCount = tavoliRidotti ? 3 : 2;
        aspect = tavoliRidotti ? 0.8 : 0.9;
      } else {
        // [NUOVO] desktop con logica fluid per ridotti
        if (tavoliRidotti) {
          crossAxisCount = 12;
          aspect = width < 1600
              ? 1.05
              : width < 1800
                  ? 1.12
                  : 1.3;
        } else {
          crossAxisCount = 5;
          aspect = 1.1;
        }
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          debugPrint(result.toString());
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                HeaderTavoloPill(
                  onBack: () => Navigator.pop(context),
                ),
                _headerMini(rooms),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: isDesktop
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _buildGrid(
                                      context,
                                      crossAxisCount,
                                      aspect,
                                      isTablet,
                                      isDesktop,
                                    ),
                                  ),
                                ],
                              )
                            : _buildGrid(
                                context,
                                crossAxisCount,
                                aspect,
                                isTablet,
                                isDesktop,
                              ),
                      ),
                      if (isDesktop) _menuLateraleDesktop(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }


  Widget _buildGrid(
    BuildContext context,
    int crossAxisCount,
    double aspect,
    bool isTablet,
    bool isDesktop,
  ) {
    final op = context.watch<OperatorPreferencesController>();
    final tavoliRidotti = op.displayTableReduced;
    final ScrollController gridController = ScrollController();
    return Padding(
      // [NUOVO] padding dinamico
      padding: EdgeInsets.all(tavoliRidotti ? 8 : 16),
      child: Scrollbar(
        controller: gridController,
        thumbVisibility: true,
        child: GridView.builder(
          controller: gridController,
          physics: const BouncingScrollPhysics(),
          itemCount: tavoli.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspect,
            // [NUOVO] spacing dinamico
            crossAxisSpacing: tavoliRidotti ? 6 : 16,
            mainAxisSpacing:  tavoliRidotti ? 6 : 16,
          ),
          itemBuilder: (_, i) => _buildCardTavolo(
            context,
            tavoli[i],
            isTablet,
            isDesktop,
          ),
        ),
      ),
    );
  }


  Widget _headerMini(List<Room> rooms) {
    final theme      = Theme.of(context);
    final width      = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 1100;

    return Container(
      // [NUOVO] padding ridotto
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: rooms.map((r) => _tabButton(r.title, r.id)).toList(),
              ),
            ),
          ),
          if (!isDesktop) ...[
            // [NUOVO] SizedBox ridotto a 1
            const SizedBox(width: 1),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openMenuMobile,
              child: Container(
                width: 46,
                // [NUOVO] altezza 44
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF97D700),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final theme = Theme.of(context);
    final bool attivo = tabSelezionato == index;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            tabSelezionato    = index;
            tableMoved        = null;
            tablesForJoin     = [];
            azioneSelezionata = TavoloAzione.apri;
            loadTable();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: attivo
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: attivo ? FontWeight.bold : FontWeight.w500,
                color: attivo
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        // [NUOVO] spacing ridotto a 3
        const SizedBox(width: 3),
      ],
    );
  }


  Widget _buildCardTavolo(
    BuildContext context,
    TableModel t,
    bool isTablet,
    bool isDesktop,
  ) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // [NUOVO]
    final op            = context.watch<OperatorPreferencesController>();
    final tavoliRidotti = op.displayTableReduced;

    final ctrWebSocketClient = context.read<ControllerWsClient>();
    final ctrWebSocketServer = context.read<ControllerWsServer>();

    Color statoColor;
    switch (t.status) {
      case 'libero':       statoColor = const Color(0xFF97D700); break;
      case 'occupato':     statoColor = const Color(0xFFFF1744); break;
      case 'prenotato':    statoColor = const Color.fromARGB(255, 0, 93, 136); break;
      case 'impegnato':    statoColor = const Color.fromARGB(255, 255, 137, 26); break;
      case 'preconto':     statoColor = const Color.fromARGB(255, 255, 244, 91); break;
      case 'finePasto':    statoColor = const Color.fromARGB(255, 137, 209, 241); break;
      case 'attesaUscite': statoColor = const Color.fromARGB(255, 219, 39, 255); break;
      default:             statoColor = const Color(0xFF97D700);
    }
    if (t.idJoinedParent != null) statoColor = Colors.grey;

    return GestureDetector(
      onTap: () async {
        switch (azioneSelezionata) {
          case TavoloAzione.apri:
            if (t.idJoinedParent != null) return;
            if (deviceCurrent["deviceServer"] == 1) {
              bool lock = await ctrWebSocketServer.lookTableServer(t.id);
              if (!lock) vistaTableKey.currentState!.apriPaginaColorata(t);
              return;
            }
            ctrWebSocketClient.send(jsonEncode({'type': 'lockTable', 'idTable': t.id}));
            break;
          case TavoloAzione.impegna:
            if (t.idJoinedParent != null) return;
            _impegnaDialog(t);
            break;
          case TavoloAzione.cancella:
            _resetTable(t);
            break;
          case TavoloAzione.sblocca:
            if (deviceCurrent["deviceServer"] == 0) {
              return;
              ctrWebSocketClient.send(jsonEncode({'type': 'unLockTable', 'idTable': t.id}));
            }
            _modalUnlockTable(() {
              if (deviceCurrent["deviceServer"] == 1) {
                ctrWebSocketServer.unLookTableServer(t.id);
              }
            });
            break;
          case TavoloAzione.sposta:
            if (t.idJoinedParent != null) return;
            if (tableMoved != null && tableMoved != t) {
              _modalMoveTable(t);
              return;
            }
            setState(() {
              if (tableMoved == t) {
                tableMoved = null;
                return;
              }
              if (tableMoved == null) tableMoved = t;
            });
            break;
          case TavoloAzione.unisci:
            if (t.idJoinedParent != null) return;
            if (tablesForJoin.contains(t)) {
              setState(() { tablesForJoin.remove(t); });
              return;
            }
            setState(() { tablesForJoin.add(t); });
            break;
          case TavoloAzione.separa:
            if (t.joinedTables == null && t.idJoinedParent == null) return;
            if (deviceCurrent["deviceServer"] == 1) {
              if (t.idJoinedParent != null) {
                TableModel parent = tavoli.firstWhere((tt) => tt.id == t.idJoinedParent!['id']);
                await ctrWebSocketServer.unjoinTablesServer([t], parent);
                return;
              }
              List<dynamic>? tables = t.joinedTables;
              List<TableModel> tableSelected = await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context_) {
                  List<TableModel> selected = [];
                  return AlertDialog(
                    title: const Text('Seleziona i tavoli da separare'),
                    content: StatefulBuilder(
                      builder: (context, setState_) => SizedBox(
                        height: 300,
                        width: 300,
                        child: ListView.builder(
                          itemCount: tables!.length,
                          itemBuilder: (context, index) {
                            TableModel tItem = tavoli.firstWhere((tt) => tt.id == tables[index]['id']);
                            return ListTile(
                              title: Row(
                                children: [
                                  Checkbox(
                                    value: selected.contains(tItem),
                                    onChanged: (v) {
                                      selected.contains(tItem) ? selected.remove(tItem) : selected.add(tItem);
                                      setState_(() {});
                                    },
                                  ),
                                  Text(tables[index]['title']),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(onPressed: () => Navigator.of(context_).pop([]), child: const Text('Annulla')),
                          const SizedBox(width: 10),
                          ElevatedButton(onPressed: () => Navigator.of(context_).pop(selected), child: const Text('Conferma')),
                        ],
                      ),
                    ],
                  );
                },
              );
              if (tableSelected.isEmpty) return;
              ctrWebSocketServer.unjoinTablesServer(tableSelected, t);
              return;
            }
            // CLIENT
            if (t.idJoinedParent != null) {
              TableModel parent = tavoli.firstWhere((tp) => tp.id == t.idJoinedParent!['id']);
              ctrWebSocketClient.send(jsonEncode({'type': 'unJoinParentTables', 'parent': parent.toMap(), 'children': [t.toMap()]}));
              return;
            }
            List<dynamic>? tables = t.joinedTables;
            List<TableModel> tableSelected = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context_) {
                List<TableModel> selected = [];
                return AlertDialog(
                  title: const Text('Seleziona i tavoli da separare'),
                  content: StatefulBuilder(
                    builder: (context, setState_) => SizedBox(
                      height: 300,
                      width: 300,
                      child: ListView.builder(
                        itemCount: tables!.length,
                        itemBuilder: (context, index) {
                          TableModel tItem = tavoli.firstWhere((tt) => tt.id == tables[index]['id']);
                          return ListTile(
                            title: Row(
                              children: [
                                Checkbox(
                                  value: selected.contains(tItem),
                                  onChanged: (v) {
                                    selected.contains(tItem) ? selected.remove(tItem) : selected.add(tItem);
                                    setState_(() {});
                                  },
                                ),
                                Text(tables[index]['title']),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(onPressed: () => Navigator.of(context_).pop([]), child: const Text('Annulla')),
                        const SizedBox(width: 10),
                        ElevatedButton(onPressed: () => Navigator.of(context_).pop(selected), child: const Text('Conferma')),
                      ],
                    ),
                  ],
                );
              },
            );
            if (tableSelected.isEmpty) return;
            ctrWebSocketClient.send(jsonEncode({
              'type': 'unJoinParentTables',
              'parent': t.toMap(),
              'children': tableSelected.map((c) => c.toMap()).toList(),
            }));
            break;
          default:
        }
      },
      child: Container(
        // [NUOVO] constraints tablet
        constraints: BoxConstraints(
          minHeight: isTablet ? (tavoliRidotti ? 100 : 150) : 0,
        ),
        decoration: BoxDecoration(
          border: tableMoved == t
              ? Border.all(color: Colors.yellowAccent, width: 5)
              : null,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            /// BARRA COLORATA SUPERIORE
            Container(
              height: 15,
              decoration: BoxDecoration(
                color: statoColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),

            /// CONTENUTO
            Expanded(
              child: Padding(
                // [NUOVO] padding dinamico
                padding: EdgeInsets.symmetric(
                  horizontal: tavoliRidotti ? 8 : 16,
                  vertical:   tavoliRidotti ? 4 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    tablesForJoin.contains(t)
                        ? const Icon(Icons.link, size: 30, color: Colors.deepOrange)
                        : const SizedBox.shrink(),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: tavoliRidotti ? 14 : 28,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          if (t.blocked == 1)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(Icons.lock, size: 16),
                            ),
                        ],
                      ),
                    ),

                    /// INFO TAVOLO UNITO
                    if (t.idJoinedParent != null)
                      Text(
                        "Unito al tavolo ${t.idJoinedParent!['title']}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),

                    /// COPERTI
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        t.coversInTable.toString(),
                        style: TextStyle(
                          // [NUOVO] fontSize dinamico
                          fontSize: tavoliRidotti ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// FOOTER — nascosto in modalità ridotta [NUOVO]
            if (!tavoliRidotti)
              Container(
                // [NUOVO] altezza dinamica
                height: isDesktop ? 43 : 36,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                // [RIPRISTINATO] logica completa: unisci / nota / more
                child: (tablesForJoin.isNotEmpty && tablesForJoin.last == t)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () { _modalJoinTables(); },
                            child: const Text('Unisci'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // [RIPRISTINATO] pulsante nota
                          (t.note != null && t.note!.isNotEmpty)
                              ? InkWell(
                                  onTap: () => _onEditPressed(t),
                                  child: Text(t.note ?? ''),
                                )
                              : IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  onPressed: () => _onEditPressed(t),
                                ),
                          // [RIPRISTINATO] spacer
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            onPressed: () => _onMorePressed(t),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  void _onMorePressed(TableModel t) {
    print("Menu premuto su tavolo ${t.title}");
  }

  void apriPaginaColorata(TableModel t) async {
    final ctrWebSocketClient = context.read<ControllerWsClient>();
    final crtServer          = context.read<ControllerWsServer>();
    TableModel? newTable;
    int? coperti = t.coversInTable;
    if (t.idOperatorOpenTable == null || coperti == 0) {
      coperti = await mostraDialogCoperti(context, t);
    }
    if (!mounted) return;
    if ((coperti == null || coperti == 0) && t.idOperatorOpenTable == null) {
      if (deviceCurrent['deviceServer'] == 0) ctrWebSocketClient.send(jsonEncode({'type': 'unLockTable', 'idTable': t.id}));
      if (deviceCurrent['deviceServer'] == 1) crtServer.unLookTableServer(t.id);
      return;
    }
    if (t.idOperatorOpenTable == null && t.dateStartTable == null) {
      if (deviceCurrent['deviceServer'] == 0) ctrWebSocketClient.send(jsonEncode({'type': 'openTable', 'idTable': t.id, 'idOperator': operatorLogged!.id, 'coversInTable': coperti}));
      if (deviceCurrent['deviceServer'] == 1) await crtServer.openTableServer(t.id, coperti!);
    }
    if (deviceCurrent['deviceServer'] == 0) return;
    if (deviceCurrent['deviceServer'] == 1) {
      final resp = await LocalDB.query("SELECT * FROM tables WHERE id = ${t.id}");
      if (resp.isEmpty) return;
      newTable = TableModel.fromMap(resp[0]);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TavoloOperativoPage(
          tavolo: newTable!,
          coperti: coperti!,
        ),
      ),
    );
  }

  void _modalUnlockTable(Function unLock) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
          title: const Text("Attenzione"),
          content: const Text('Sicuro sbloccare il tavolo'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: () async {
                unLock();
                Navigator.pop(ctx, true);
              },
              child: const Text("Sblocca"),
            ),
          ],
        );
      },
    );
  }

  void _onEditPressed(TableModel t) {
    showDialog(
      context: context,
      builder: (ctx) {
        TextEditingController msgCtr = TextEditingController();
        msgCtr.text = t.note ?? '';
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 400,
            height: 300,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    const Text('Inserisci una nota'),
                    const SizedBox(height: 20),
                    TextField(controller: msgCtr),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Annulla'),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () {
                            if (deviceCurrent['deviceServer'] == 0) {
                              final ctrClient = context.read<ControllerWsClient>();
                              ctrClient.send(jsonEncode({'idTable': t.id, 'type': 'noteTable', 'note': msgCtr.text}));
                            } else {
                              final ctrserver = context.read<ControllerWsServer>();
                              ctrserver.setNoteTableServer(t.id, msgCtr.text);
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Ok'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetTable(TableModel t) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
          title: const Text("Attenzione"),
          content: Text('Sicuro di eliminare il tavolo ${t.title}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: () async {
                if (deviceCurrent["deviceServer"] == 1) {
                  final ctrlServer = context.read<ControllerWsServer>();
                  ctrlServer.resetTableServer(t.id);
                } else {
                  final ctrlClient = context.read<ControllerWsClient>();
                  ctrlClient.send(jsonEncode({'type': 'resetTable', 'idTable': t.id}));
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  void _modalMoveTable(TableModel t) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
          title: const Text("Attenzione"),
          content: Text('Sicuro di spostare il tavolo ${tableMoved!.title} sul tavolo ${t.title}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: () async {
                if (deviceCurrent["deviceServer"] == 1) {
                  final ctrlServer = context.read<ControllerWsServer>();
                  ctrlServer.moveTableServer(tableMoved!, t);
                  setState(() { tableMoved = null; });
                } else {
                  final ctrlClient = context.read<ControllerWsClient>();
                  ctrlClient.send(jsonEncode({'type': 'moveTable', 'tableFrom': tableMoved!.toMap(), 'tableTo': t.toMap()}));
                  setState(() { tableMoved = null; });
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Sposta"),
            ),
          ],
        );
      },
    );
  }

  void _modalJoinTables() {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
          title: const Text("Attenzione"),
          content: Text('Sicuro di unire i tavoli ${tablesForJoin.map((t) => t.title).toList().join(', ')} '),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: () async {
                if (deviceCurrent["deviceServer"] == 1) {
                  final ctrlServer = context.read<ControllerWsServer>();
                  ctrlServer.joinTablesServer(tablesForJoin[0], tablesForJoin.skip(1).toList());
                  setState(() { tableMoved = null; });
                } else {
                  final ctrlClient = context.read<ControllerWsClient>();
                  ctrlClient.send(jsonEncode({
                    'type': 'joinTables',
                    'parent': tablesForJoin[0].toMap(),
                    'children': tablesForJoin.skip(1).map((c) => c.toMap()).toList(),
                  }));
                  setState(() { tableMoved = null; });
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Unisci"),
            ),
          ],
        );
      },
    );
  }

  void _impegnaDialog(TableModel t) {
    showDialog(
      context: context,
      builder: (ctx) {
        TextEditingController msgCtr   = TextEditingController();
        TextEditingController coverCtr = TextEditingController();
        msgCtr.text = t.note ?? '';
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 400,
            height: 300,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    const Text('Inserisci nota'),
                    TextField(controller: msgCtr),
                    const SizedBox(height: 20),
                    const Text('Inserisci coperti'),
                    TextField(
                      controller: coverCtr,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Annulla'),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () {
                            if (coverCtr.text.isEmpty || msgCtr.text.isEmpty) return;
                            if (deviceCurrent['deviceServer'] == 0) {
                              final ctrClient = context.read<ControllerWsClient>();
                              ctrClient.send(jsonEncode({'idTable': t.id, 'type': 'impegnaTable', 'note': msgCtr.text, 'numberCover': int.parse(coverCtr.text)}));
                            } else {
                              final ctrserver = context.read<ControllerWsServer>();
                              ctrserver.impegnaTableServer(t.id, msgCtr.text, int.parse(coverCtr.text));
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Ok'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // MOBILE MENU
  // =========================================================
  void _openMenuMobile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
      Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: _menuContent(),
        );
      },
    );
  }

    Widget _menuContent() {
    final theme = Theme.of(context);
    final activeColor = const Color(0xFF97D700);

    final voci = TavoloAzione.values;

    return ListView.separated(
      itemCount: voci.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final value = voci[index];
        final bool isSelected = azioneSelezionata == value;

        return InkWell(
          onTap: () {
            tableMoved = null;
            tablesForJoin = [];
            setState(() => azioneSelezionata = value);
            _handleAction(value);
          },
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.name.toUpperCase(),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(0xFF97D700),
                    ),
                  )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // HANDLE ACTION
  // =========================================================
  void _handleAction(TavoloAzione azione) {
    print("Azione selezionata: $azione");
  }

    // =========================================================
  // MENU DESKTOP
  // =========================================================
  Widget _menuLateraleDesktop(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _menuContent(),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              children: [

                _actionBtn("Preconto", Icons.receipt_long, () {
                  debugPrint("PRECONTO");
                }),

                _actionBtn("Conto", Icons.payments, () {
                  debugPrint("CONTO");
                }),

                _actionBtn("Dividi conto", Icons.call_split, () {
                  debugPrint("DIVIDI");
                }),

                _actionBtn("Separa conto", Icons.table_restaurant, () {
                  debugPrint("SEPARA");
                }),

              ],
            ),
          ),

          _footerAzioniNavigazione(),
        ],
      ),    );
  }

}
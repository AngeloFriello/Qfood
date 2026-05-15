import 'dart:convert';
import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/app/service/service_transaction.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/report_chiusura/PrintReport.dart';
import 'package:dashboard/report_chiusura/ReportChiusura.dart';
import 'package:dashboard/report_chiusura/ReportList.dart';
import 'package:dashboard/state/banco_state.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';


// ─────────────────────────────── EXPANSION CARD CUSTOM ───────────────────────
// Sostituisce ExpansionTile che usa InkWell/MouseRegion internamente
// e causa il crash !_debugDuringDeviceUpdate su desktop/web

class _CustomExpansionCard extends StatefulWidget {
  final String title;
  final Color accentColor;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _CustomExpansionCard({
    required this.title,
    required this.accentColor,
    required this.children,
    this.initiallyExpanded = true,
  });

  @override
  State<_CustomExpansionCard> createState() => _CustomExpansionCardState();
}

class _CustomExpansionCardState extends State<_CustomExpansionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // GestureDetector — non registra MouseRegion, nessun conflitto col mouse tracker
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _expanded = !_expanded);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: widget.accentColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          // AnimatedSize garantisce dimensioni sempre definite → nessun RenderBox "fantasma"
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.children,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────── MAIN WIDGET ─────────────────────────────────

class ReportAvanzatoVista extends StatefulWidget {
  const ReportAvanzatoVista({super.key});

  @override
  State<ReportAvanzatoVista> createState() => _ReportAvanzatoVistaState();
}

class _ReportAvanzatoVistaState extends State<ReportAvanzatoVista> {
  final Color verdeFlex = const Color(0xFF95C01F);
  List<List> totals = [];


  DateTime dataInizio = DateTime.now().subtract(const Duration(days: 1));
  DateTime dataFine = DateTime.now();
  String? uuidTurno;


  String? operatingHours;
  String tipoReport = "Tutti";
  List<OperatoreModel> operators = [];
  int? operatorSelected;
  bool showFiltri = true;
  bool isLoading = false;
  String bottoneSelezionato = "Turno utente corrente";
  List listShiftLast6Months = [];
  dynamic shiftSelected;
  ReportChiusura? report;
  bool mostraCategorie = false;
  bool mostraProdotti = false;
  ReportChiusura? rep;

  // Differisce setState al frame successivo — fix definitivo per !_debugDuringDeviceUpdate
  void _safeSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  void totalLastShift({
    String? tipo,
    String? uuid,
    bool lastTurn = false,
    DateTime? from_,
    DateTime? to_,
    bool lastLogin = false,
    String? fromTime,
    int? idOperator,
  }) async {
    final Map<String, dynamic> totals_ = await TurnoLavoro.getTotalsByDocumentTypeLastShift(
      uuidTurno: uuid,
      tipoReport: tipo,
      lastClosedShift: lastTurn,
      from: from_,
      to: to_,
      lastLogin: lastLogin,
      fromTime: fromTime,
      idOperator: idOperator,
    );
    totals.clear();
    for (final key in totals_.keys) {
      totals.add([key, totals_[key]]);
    }
    _safeSetState(() {});
  }

  @override
  void initState() {
    super.initState();
    totalLastShift();
    _getOperatingHours();
    _getOperators();
    _getShifts();
  }

  Future<void> _getOperators() async {
    final result = await OperatoreModel.getOperators();
    _safeSetState(() => operators = result);
  }

  Future<void> _getShifts() async {
    try {
      final result = await TurnoLavoro.getTurniUltimi6Mesi();
      _safeSetState(() => listShiftLast6Months = result);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> _getOperatingHours() async {
    final prefs = await SharedPreferences.getInstance();
    final storeString = prefs.getString('settingStore');
    if (storeString == null) return;
    final storeSettings = jsonDecode(storeString) as Map<String, dynamic>;
    if (storeSettings['operatingHours'] != null &&
        storeSettings['operatingHours'] != '') {
      _safeSetState(() => operatingHours = storeSettings['operatingHours'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: verdeFlex,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report avanzato',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pulsantiRapidi(),
                const SizedBox(height: 20),
                _cardFiltri(textColor),
                const SizedBox(height: 25),
                if (report != null)
                  ReportChiusuraWidget( report_: report!, mostraCategorie: mostraCategorie,mostraProdotti: mostraProdotti, )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "Premi 'Genera report' per visualizzare i dati",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // GENERA REPORT
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: verdeFlex,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: verdeFlex.withOpacity(0.3),
                  ),
                  onPressed: () async => await _generaReport(),
                  child: const Text(
                    'Genera report',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // STAMPA REPORT
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // disabilitato se il report non è ancora pronto
                  onPressed: () async {
                    final ctrLook  = context.read<ControllerLookPosInPrinder>();
                    try{
                      EsitoChiusura resp = await chiediChiusuraConto( context );
                      ctrLook.setInPrint(true);
                      if( resp == EsitoChiusura.parziale ){
                        await StampaReport();
                        return;
                      }

                      if( resp == EsitoChiusura.definitivaSoloFiscale ){
                        final printer = ServiceReceipt.instance();
                        printer.fiscalClosure();
                        await StampaReport();
                        return;
                      }

                      if( resp == EsitoChiusura.soloTurno ){
                        /* final printer = ServiceReceipt.instance();
                        printer.fiscalClosure();
                        await StampaReport(); */
                        return;
                      }
                      

                    }catch(err ){

                    }finally{
                      ctrLook.setInPrint(false);
                    }
                    /* report == null
                        ? null
                      : () async => await StampaReport(), */
                  } ,
                  child: const Text(
                    'Stampa report',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── SEZIONI ───────────────────────────────

  Widget _pulsantiRapidi() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _bottone('Ultimo turno utente',
            click: () async {
              final test = await getLastOpenedAndClosedShift();
              if( test != null ){
                dataInizio = DateTime.parse( test["dataApertura"]! );
                dataFine   = DateTime.parse( test["dataChiusura"]! );
                uuidTurno  = test["uuidTurno"];
                setState(() {
                  
                });
                _generaReport();
              }
              if( test == null ) SnackBarForcedClosure('Manca turno precedente', Colors.orange);
            }),
        _bottone('Turno utente corrente',
            click: () async {
              final test = await getCurrentOpenedShift();
              if( test != null ){
                dataInizio = DateTime.parse( test["dataApertura"]! );
                dataFine   = DateTime.now();
                uuidTurno  = test["uuidTurno"];
                setState(() {
                  
                });
                _generaReport();
              }
              
            }),
        if (operatingHours != null)
          _bottone('Orario di esercizio',
              click: ()  {
                dataInizio = timeStringToDateTimeToday(settingStore!.storeData['insightStartHour']);
                dataFine   = timeStringToDateTimeToday(settingStore!.storeData['insightEndHour']);
                uuidTurno  = null;
                setState(() {
                  
                });
                _generaReport();
              }),
          _bottone('Generale',
              click: ()  {
                dataInizio = timeStringToDateTimeToday(settingStore!.storeData['insightStartHour']);
                dataFine   = timeStringToDateTimeToday(settingStore!.storeData['insightEndHour']);
                uuidTurno  = null;
                setState(() {
                  
                });
                _generaReportGenerale();
              }),
      ],
    );
  }

  Widget _bottone(String testo, {Function? click}) {
    final bool selezionato = bottoneSelezionato == testo;
    return GestureDetector(
      onTap: () {
        if (click != null) click();
        setState(() => bottoneSelezionato = testo );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selezionato ? verdeFlex : verdeFlex.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          boxShadow: selezionato
              ? [
                  BoxShadow(
                      color: verdeFlex.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          testo,
          style: TextStyle(
            color: selezionato ? Colors.white : verdeFlex,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  DateTime timeStringToDateTimeToday(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]), // ore
      int.parse(parts[1]), // minuti
      int.parse(parts[2]), // secondi
    );
  }

  // _cardFiltri usa _CustomExpansionCard invece di ExpansionTile
  Widget _cardFiltri(Color textColor) {
    return _CustomExpansionCard(
      title: 'Filtri di ricerca',
      accentColor: verdeFlex,
      initiallyExpanded: true,
      children: [
        Row(
          children: [
            Expanded(
              child: _campoData('Inizio', dataInizio, (v) {
                _safeSetState(() {
                  uuidTurno = null;
                  dataInizio = v;
                  bottoneSelezionato = '';
                  _generaReport();
                });

              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campoData('Fine', dataFine, (v) {
                _safeSetState(()  {
                  uuidTurno = null;
                  dataFine = v;
                  bottoneSelezionato = '';
                  _generaReport();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            /* Expanded(
              child: _dropdown(
                  'Tipo', tipoReport, ['Vendite', 'Riscontri', 'Tutti'],
                  (v) {
                _safeSetState(() => tipoReport = v);
                totalLastShift(
                    idOperator: operatorSelected,
                    from_: dataInizio,
                    to_: dataFine,
                    tipo: v);
              }),
            ), */
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownContainer(
                child: DropdownButton<int?>(
                  value: operatorSelected,
                  isExpanded: true,
                  underline: const SizedBox(),
                  onChanged: (v) {
                    _safeSetState(() {
                      operatorSelected = v;
                      bottoneSelezionato = '';
                    });
                    totalLastShift(
                        idOperator: v,
                        from_: dataInizio,
                        to_: dataFine,
                        tipo: tipoReport
                    );
                  },
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tutti')),
                    ...operators.map( (e) => DropdownMenuItem(value: e.id, child: Text(e.title)) ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: _dropdownContainer(
            child: DropdownButton<dynamic>(
              hint: const Text('Seleziona turno...'),
              value: shiftSelected,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (v) {
                _safeSetState(() {
                  shiftSelected = v;
                  bottoneSelezionato = '';
                });

                
                Map? shift  =  listShiftLast6Months.firstWhereOrNull((s) => s['uuidTurno'] == v  );
                if( shift == null ) return;
                uuidTurno  = v;
                dataInizio = DateTime.parse(shift['dataInizioTurno']);
                dataFine   = shift['dataFineTurno'] != null ? DateTime.parse(shift['dataFineTurno']) : DateTime.now();
                _generaReport();
              },
              items: [
                DropdownMenuItem( 
                  value: null, 
                  child: Text('Seleziona turno..')),
                ...listShiftLast6Months.map((e) => DropdownMenuItem(
                      value: e['uuidTurno'],
                      child: Text(e['nomeTurno'] as String))).toList()],
            ),
                    ),
          ),
          ],
        ),
        const SizedBox(height: 16),
        _switchRow('Mostra categorie nel report', mostraCategorie,
            (v) => _safeSetState(() => mostraCategorie = v)),
        const SizedBox(height: 8),
        _switchRow('Mostra prodotti nel report', mostraProdotti,
            (v) => _safeSetState(() => mostraProdotti = v)),
      ],
    );
  }

  // ─────────────────────────────── COMPONENTI ───────────────────────────────

  // Contenitore riutilizzabile per i DropdownButton
  Widget _dropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w500)),
        Switch(value: value, onChanged: onChanged, activeColor: verdeFlex),
      ],
    );
  }

Widget _campoData(
    String label, DateTime value, ValueChanged<DateTime> onChanged) {
  return GestureDetector(
    onTap: () async {
      // ── 1. SELEZIONA DATA ──────────────────────────────────────────
      final nuovaData = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        locale: const Locale('it', 'IT'),
        helpText: 'Seleziona data',
        cancelText: 'Annulla',
        confirmText: 'Avanti',
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF95C01F),
                onPrimary: Colors.white,
                surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                onSurface: isDark ? Colors.white : Colors.black87,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF95C01F),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (nuovaData == null || !mounted) return;

      // ── 2. SELEZIONA ORA ──────────────────────────────────────────
      final nuovaOra = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value),
        helpText: 'Seleziona ora',
        cancelText: 'Annulla',
        confirmText: 'Conferma',
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF95C01F),
                onPrimary: Colors.white,
                surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                onSurface: isDark ? Colors.white : Colors.black87,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF95C01F),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (nuovaOra == null) return;

      // ── 3. COMBINA DATA + ORA ─────────────────────────────────────
      onChanged(DateTime(
        nuovaData.year,
        nuovaData.month,
        nuovaData.day,
        nuovaOra.hour,
        nuovaOra.minute,
      ));
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14.5)),
          const SizedBox(height: 4),
          // ── mostra data E ora ──────────────────────────────────────
          Text(
            '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/'
            '${value.year}  '
            '${value.hour.toString().padLeft(2, '0')}:'
            '${value.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    ),
  );
}

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return _dropdownContainer(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (v) => onChanged(v!),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      ),
    );
  }

  String getTitleTotal(String docType) {
    switch (docType) {
      case 'amount_simulation':      return 'Simulazione';
      case 'number_simulation':      return 'Num. simulazioni';
      case 'number_invoice':         return 'Num. fatture';
      case 'number_cancel_receipt':  return 'Num. annulli scontrino';
      case 'amount_invoice':         return 'Fatture';
      case 'amount_receipt':         return 'Scontrini';
      case 'amount_cancel_receipt':  return 'Annulli scontrino';
      case 'amount_credit_note':     return 'Note di credito';
      case 'totale_food':            return 'Food';
      case 'totale_beverage':        return 'Beverage';
      case 'totale_altro':           return 'Altro';
      case 'totale_contanti':        return 'Contanti';
      case 'totale_elettronico':     return 'Elettronico';
      case 'totale_tickets':         return 'Tickets';
      case 'totale_assegno':         return 'Assegni';
      case 'totale_sconto':          return 'Sconti';
      case 'percentuale_simulation': return 'Percentuale simulazione';
      case 'totale_vendite':         return 'Totale';
      default:                       return '';
    }
  }

  Future<void> _generaReport() async {
    _safeSetState(() => isLoading = true);
    report = await ReportChiusura.report( bancoAbilitato.value, dataInizio, dataFine,uuidRigaTurno: uuidTurno);
    _safeSetState(() => isLoading = false);
    if( report == null ) return;
  }

  Future<DateTime?> getFirstSaleToday() async {
    try{
    
    final db = await LocalDB.instance();

    // Data di oggi nel formato yyyy-MM-dd
    final String today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.query(
      'documents',
      columns: ['realDate'],
      where: "realDate LIKE ? AND deletedBy IS NULL",
      whereArgs: ['$today%'],
      orderBy: 'realDate ASC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    final String raw = result.first['realDate'] as String;
    return DateTime.tryParse(raw);
    }catch( err ){
      debugPrint(err.toString());
    }finally{
      
    }
} 

  Future<void> _generaReportGenerale() async {
    _safeSetState(() => isLoading = true);
    DateTime end = DateTime.now();
    DateTime start = (await getFirstSaleToday() ?? DateTime.now());
    report = await ReportChiusura.report( bancoAbilitato.value, dataInizio, end, uuidRigaTurno: null, reportGenerale: true);
    _safeSetState(() => isLoading = false);
    if( report == null ) return;
  }

  Future<void> StampaReport() async {
    _safeSetState(() => isLoading = true);
    report = await ReportChiusura.report(bancoAbilitato.value, dataInizio, dataFine, uuidRigaTurno: uuidTurno);
    _safeSetState(() => isLoading = false);
    if( report == null ) return;
    printReportChiusura(rep: report!,mostraCategorie: mostraCategorie, mostraProdotti: mostraProdotti, simulazione: bancoAbilitato.value);
  }
}


// ─────────────────────────────── DIALOG & ENUM ───────────────────────────────

Future<EsitoChiusura> chiediChiusuraConto(BuildContext context) async {
  
  final scelta = await showTipoPagamentoDialog(context);
  if (scelta == 'parziale') return EsitoChiusura.parziale;
  if (scelta == 'definitiva') {
    final chiusura = await showTipoChiusuraDefinitivaDialog(context);
    if (chiusura == 'solo_fiscale') return EsitoChiusura.definitivaSoloFiscale;
    if (chiusura == 'cassa_report') return EsitoChiusura.definitivaCassaEReport;
    if( chiusura == 'chiudi_turno') return EsitoChiusura.soloTurno;
    return EsitoChiusura.annulla;
  }
  return EsitoChiusura.annulla;
}

enum EsitoChiusura {
  parziale,
  definitivaSoloFiscale,
  definitivaCassaEReport,
  annulla,
  soloTurno
}

Future<String?> showTipoPagamentoDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Conferma report'),
      content: const Text(''),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop('parziale'),
            child: const Text('Parziale')),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop('definitiva'),
            child: const Text('Definitiva')),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annulla')),
      ],
    ),
  );
}

Future<String?> showTipoChiusuraDefinitivaDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Chiusura definitiva'),
      content: const Text(
          'Vuoi fare solo la chiusura fiscale della cassa oppure chiusura cassa + report?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop('chiudi_turno'),
            child: const Text('Chiudi turno')),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop('solo_fiscale'),
            child: const Text('Solo chiusura fiscale')),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop('cassa_report'),
            child: const Text('Fiscale + report')),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annulla')),
      ],
    ),
  );
}


  /// Ritorna ultimo turno che è stato aperto e poi chiuso
  /// null se non esiste nessun turno chiuso
 Future<Map<String, String>?> getLastOpenedAndClosedShift() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    dynamic device = jsonDecode(pref.getString('device') ?? '{}');
    if (device == null || device.isEmpty) return null;

    if (device['deviceServer'] == 1) {
      final db = await LocalDB.instance();

      //ultima riga di chiusura (turno_chiuso = 1)
      final lastClosed = await db.query(
        'turno_lavoro',
        columns: ['uuid_turno', 'data_ora_creazione'],
        where: 'turno_chiuso = 1',
        orderBy: 'id DESC',
        limit: 1,
      );

      // nessun turno chiuso
      if (lastClosed.isEmpty) return null;

      final String uuidTurno   = lastClosed.first['uuid_turno'] as String;
      final String dataChiusura = lastClosed.first['data_ora_creazione'] as String;

      // 2) prima riga del turno
      final firstRow = await db.query(
        'turno_lavoro',
        columns: ['data_ora_creazione'],
        where: 'uuid_turno = ?',
        whereArgs: [uuidTurno],
        orderBy: 'id ASC',
        limit: 1,
      );

      if (firstRow.isEmpty) {
        // caso anomalo: ho chiusura ma non apertura
        return null;
      }

      final String dataApertura = firstRow.first['data_ora_creazione'] as String;

      return {
        'uuidTurno':   uuidTurno,
        'dataApertura': dataApertura,
        'dataChiusura': dataChiusura,
      };

    } else {
      // CLIENT → delega al server via WebSocket (da implementare lato server)
      //return await TurnoLavoroWsClient.getLastOpenedAndClosedShift();
    }
  }

/// Ritorna il turno corrente: ultimo aperto e NON chiuso.
/// Ritorna null se non esiste nessun turno aperto.
Future<Map<String, String>?> getCurrentOpenedShift() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  dynamic device = jsonDecode(pref.getString('device') ?? '{}');
  if (device == null || device.isEmpty) return null;

  // Leggi l'operatore corrente dalle prefs
  final int? idOperatore = operatorLogged!.id; // ← adatta la chiave alla tua
  if (idOperatore == null) return null;

  if (device['deviceServer'] == 1) {
    final db = await LocalDB.instance();

    // 1) ultimo turno dell'operatore corrente
    final lastShift = await db.query(
      'turno_lavoro',
      columns: ['uuid_turno'],
      where: 'id_operatore_apertura = ?',        // ← filtro operatore
      whereArgs: [idOperatore],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (lastShift.isEmpty) return null;

    final String uuidTurno = lastShift.first['uuid_turno'] as String;

    // 2) se esiste una riga di chiusura per questo uuid → NON è aperto
    final closedRow = await db.query(
      'turno_lavoro',
      columns: ['id'],
      where: 'uuid_turno = ? AND turno_chiuso = 1',
      whereArgs: [uuidTurno],
      limit: 1,
    );

    if (closedRow.isNotEmpty) return null;

    // 3) prima riga del turno → data di apertura
    final firstRow = await db.query(
      'turno_lavoro',
      columns: ['data_ora_creazione'],
      where: 'uuid_turno = ?',
      whereArgs: [uuidTurno],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (firstRow.isEmpty) return null;

    final String dataApertura = firstRow.first['data_ora_creazione'] as String;

    return {
      'uuidTurno': uuidTurno,
      'dataApertura': dataApertura,
      'idOperatore': idOperatore.toString(), // opzionale, utile per il chiamante
    };
  } else {
    // CLIENT → delega al server via WebSocket
    // return await TurnoLavoroWsClient.getCurrentOpenedShift();
  }
}


  
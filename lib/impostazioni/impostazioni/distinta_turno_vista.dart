import 'dart:convert';

import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/modelli/movimentiCassa.dart';
import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';


// helper: riga label ........... valore (42 char)
List<int> _rigaMov(Generator g, String label, String valore) {
  const int maxLen = 42;
  final int spazi = maxLen - label.length - valore.length;
  final String linea =
      spazi > 0 ? '$label${' ' * spazi}$valore' : '$label: $valore';
  return g.text(linea);
}

String _formatDate(DateTime d) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(d.day)}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
}

class DistintaTurnoVista extends StatefulWidget {
  const DistintaTurnoVista({super.key});

  @override
  State<DistintaTurnoVista> createState() => _DistintaTurnoVistaState();
}

class _DistintaTurnoVistaState extends State<DistintaTurnoVista> {
  final TextEditingController fondoInizialeCtrl = TextEditingController(text: "0");
  final TextEditingController valoreAttualeCtrl = TextEditingController(text: "0");
  final TextEditingController fondoFinaleCtrl   = TextEditingController(text: "0");
  final TextEditingController nomeTurno         = TextEditingController(text: "");

  bool shiftOpened = false;
  String? uuidTurnoCorrente;
  List<MovimentoCassa> movimenti = [];

  final _formKeyMovimento = GlobalKey<FormState>();
  final TextEditingController descrizioneCtrl   = TextEditingController();
  final TextEditingController categoriaCtrl     = TextEditingController(text: 'altro');
  final TextEditingController valoreCtrl        = TextEditingController();
  final TextEditingController contropartitaCtrl = TextEditingController();
  final TextEditingController noteCtrl          = TextEditingController();
  String tipoMovimentoForm = 'Entrata';

  // ─── fissi, non più scelti dall'utente ───────────────────────────────────
  static const String _metodoPagamento = 'contanti';
  static const String _provenienza     = 'cassa';
  
  Future<void> _stampaMovimento({
  required int numeroCopie,
  int port = 9100,
}) async {
  PrinterNetworkManager? printer;
  try {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? devicePref = pref.getString('device');
    if (devicePref == null) return;
    Map device = jsonDecode(devicePref);
    String? ip = device['noFiscalPrinterIpv4'];
    if (ip == null) return;

    printer = PrinterNetworkManager(ip, port: port);
    final PosPrintResult connect = await printer.connect();

    if (connect != PosPrintResult.success) {
      debugPrint('Connessione stampante fallita: ${connect.msg}');
      return;
    }

    final profile   = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    final List<String> linesHead = await getHeadReceipt();

    // ── Font B (ridotto/condensato) ──────────────────────────────────
    const List<int> fontB = [0x1D, 0x4D, 0x03];
    const List<int> fontA = [0x1B, 0x4D, 0x00];
    // ────────────────────────────────────────────────────────────────

    for (int copia = 0; copia < numeroCopie; copia++) {
      List<int> bytes = [];
      bytes += [0x1B, 0x40];
      bytes += generator.setGlobalCodeTable('CP1252');
      bytes += fontB; // ← attiva font ridotto per tutto il documento
      bytes += generator.emptyLines(1);

      // ─── INTESTAZIONE PUNTO VENDITA ──────────────────────────────────
      bytes += [27, 97, 1]; // centra
      bytes += [0x1B, 0x45, 0x01];
      bytes += generator.text(linesHead[0]);
      bytes += [0x1B, 0x45, 0x00];
      bytes += generator.text(linesHead[1]);
      bytes += generator.text(linesHead[2]);
      bytes += generator.text(linesHead[3]);
      bytes += generator.text(linesHead[4]);
      bytes += [27, 97, 0]; // sinistra

      bytes += generator.emptyLines(1);
      bytes += generator.hr(len: 42);

      // ─── TITOLO ──────────────────────────────────────────────────────
      bytes += generator.text(
        'MOVIMENTO DI CASSA',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );
      bytes += generator.text(
        _formatDate(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center),
      );
      if (nomeTurno.text.trim().isNotEmpty) {
        bytes += generator.text(
          'Turno: ${nomeTurno.text.trim()}',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.hr(len: 42);

      // ─── DATI MOVIMENTO ──────────────────────────────────────────────
      bytes += generator.emptyLines(1);

      bytes += _rigaMov(generator, 'Tipo',        tipoMovimentoForm);
      bytes += _rigaMov(generator, 'Descrizione', descrizioneCtrl.text.trim());

      final double importo = double.tryParse(
            valoreCtrl.text.replaceAll(',', '.'),
          ) ?? 0;
      bytes += _rigaMov(generator, 'Importo', '${importo.toStringAsFixed(2)} E');

      if (categoriaCtrl.text.trim().isNotEmpty &&
          categoriaCtrl.text.trim() != 'altro') {
        bytes += _rigaMov(generator, 'Categoria', categoriaCtrl.text.trim());
      }

      if (contropartitaCtrl.text.trim().isNotEmpty) {
        bytes += _rigaMov(
          generator,
          'Contropartita',
          contropartitaCtrl.text.trim(),
        );
      }

      if (noteCtrl.text.trim().isNotEmpty) {
        bytes += generator.emptyLines(1);
        bytes += generator.text(
          'Note:',
          styles: const PosStyles(bold: true),
        );
        bytes += generator.text(noteCtrl.text.trim());
      }

      bytes += generator.emptyLines(1);
      bytes += generator.hr(len: 42);

      // ─── OPERATORE ───────────────────────────────────────────────────
      if (operatorLogged != null) {
        bytes += _rigaMov(
          generator,
          'Operatore',
          operatorLogged!.title ?? '',
        );
        bytes += generator.hr(len: 42);
      }

      // ─── COPIA N. ────────────────────────────────────────────────────
      if (numeroCopie > 1) {
        bytes += generator.text(
          'Copia ${copia + 1} di $numeroCopie',
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += generator.hr(len: 42);
      }

      // ─── CAMPO FIRMA ─────────────────────────────────────────────────
      bytes += generator.emptyLines(2);
      bytes += generator.text(
        'Firma',
        styles: const PosStyles(bold: true),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.text('_' * 32);
      bytes += generator.emptyLines(1);

      // ─── FINE ────────────────────────────────────────────────────────
      bytes += fontA; // ← ripristina font normale prima del cut
      bytes += generator.feed(4);
      bytes += generator.cut();

      await printer.printTicket(bytes);
    }
  } catch (err) {
    debugPrint(err.toString());
  } finally {
    if (printer != null) printer.disconnect();
  }
}

List<int> _rigaMov(Generator g, String label, String valore) {
  const int maxLen = 42;
  final int spazi = maxLen - label.length - valore.length;
  final String linea =
      spazi > 0 ? '$label${' ' * spazi}$valore' : '$label: $valore';
  return g.text(linea);
}
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> isOpened() async {
    shiftOpened = await TurnoLavoro.lastShiftOpened();
    final resp  = await TurnoLavoro.getCurrentCashStatus();
    if (resp == null) {
      setState(() {});
      return;
    }

    fondoInizialeCtrl.text = resp['fondoIniziale'].toString();
    valoreAttualeCtrl.text = resp['totaleCassa'].toString();
    nomeTurno.text         = resp['nomeTurno']?.toString() ?? '';
    fondoFinaleCtrl.text   = resp['fondoFinalePrecedente'].toString();
    uuidTurnoCorrente      = resp['uuidTurno'] as String?;

    await _loadMovimentiTurno();
    setState(() {});
  }

  Future<void> _loadMovimentiTurno() async {
    if (uuidTurnoCorrente == null) { movimenti = []; return; }
    final db   = await LocalDB.instance();
    final rows = await db.query(
      'movimenti_cassa',
      where: 'uuid_turno = ?',      // ← rimosso AND deleted = 0
      whereArgs: [uuidTurnoCorrente],
      orderBy: 'data_ora_creazione ASC',
    );
    movimenti = rows.map((m) => MovimentoCassa.fromMap(m)).toList();
  }

  Future<void> _salvaNuovoMovimento() async {
    try {
      if (!_formKeyMovimento.currentState!.validate()) return;
      if (uuidTurnoCorrente == null || operatorLogged == null) return;

      final tipoDb = switch (tipoMovimentoForm) {
        'Entrata' => 'entrata',
        'Uscita'  => 'uscita',
        'Neutro'  => 'neutro',
        _         => 'neutro',
      };

      final prefs = await SharedPreferences.getInstance();
      int activePrint = 0;
      final storeString = prefs.getString('settingStore');
      final storeSettings = jsonDecode(storeString as String);
      if (storeSettings != null && storeSettings['printReceiptCashInOutFlows'] is int ) {
        activePrint = storeSettings['printReceiptCashInOutFlows'];
      }


      TextEditingController numberCopyCtr = TextEditingController(text: '1');
      double? numeroCopie;
      bool? print;
      if( activePrint == 1 ){
              print =  await showDialog(
              context: context,
              barrierDismissible: false,
              builder:(context) =>  AlertDialog(
                content: Container(
                  width: 300,
                  height: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Numero copie'),
                      TextField(
                        keyboardType: TextInputType.number,
                        controller: numberCopyCtr,
                      ),
                      SizedBox( height: 20,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              numeroCopie = double.tryParse(numberCopyCtr.text);
                              if( numeroCopie == null ){
                                SnackBarForcedClosure('Numero non valido', Colors.red);
                                return;
                              }
                              if (numeroCopie is double && numeroCopie! > 0) {
                                 await _stampaMovimento(numeroCopie: numeroCopie!.toInt());
                              }
                              Navigator.pop(context, true);
                            }, 
                            child: Text('Stampa')
                          ),
                          SizedBox( width: 20,),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, null), 
                            child: Text('Annulla')
                          )
                        ],
                      )
                      
                    ],
                  ),
                ),
              )
            );
      }

      
      if( print == null  && activePrint == 1 ) return;

      if( print == true && numeroCopie is double && numeroCopie! > 0  ){
        //STAMPARE CAMPI MOviMento piu firma in basso


        SnackBarForcedClosure('Stampo le copie', Colors.green);
      };

      await MovimentoCassa.insert(
        uuidTurno:                uuidTurnoCorrente!,
        tipoMovimento:            tipoDb,
        categoria:                categoriaCtrl.text.trim().isEmpty ? 'altro' : categoriaCtrl.text.trim(),
        descrizione:              descrizioneCtrl.text.trim(),
        importo:                  double.parse(valoreCtrl.text.replaceAll(',', '.')),
        metodoPagamento:          _metodoPagamento,
        contropartitaNome:        contropartitaCtrl.text.trim().isEmpty ? null : contropartitaCtrl.text.trim(),
        contropartitaRiferimento: null,
        provenienza:              _provenienza,
        note:                     noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        deviceId:                 null,
      );

      descrizioneCtrl.clear();
      valoreCtrl.clear();
      contropartitaCtrl.clear();
      noteCtrl.clear();

      await isOpened();
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  void initState() { isOpened(); super.initState(); }

  @override
  void dispose() {
    for (final c in [
      fondoInizialeCtrl, valoreAttualeCtrl, fondoFinaleCtrl, nomeTurno,
      descrizioneCtrl, categoriaCtrl, valoreCtrl, contropartitaCtrl, noteCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final isDark      = theme.brightness == Brightness.dark;
    final verde       = const Color(0xFF4F6137);
    final verdeChiaro = const Color(0xFF6D7E4A);
    final bg          = isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F2);
    final card        = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text        = isDark ? Colors.white : Colors.black87;
    final divider     = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: verde,
        elevation: 0,
        title: const Text(
          "Distinta turno",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: LayoutBuilder(builder: (context, constraints) {
        if (!shiftOpened) return _emptyShiftView(text, card);

        final isWide = constraints.maxWidth >= 700;
        return isWide
            ? _layoutWide(verde, card, text, divider)
            : _layoutNarrow(verde, card, text, divider);
      }),

      bottomNavigationBar: _bottomBar(verdeChiaro, verde),
    );
  }

  // ─── SCHERMATA VUOTA ─────────────────────────────────────────────────────
  Widget _emptyShiftView(Color text, Color card) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 72, color: text.withOpacity(0.2)),
            const SizedBox(height: 20),
            Text(
              "Nessun turno aperto",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: text.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Premi "Inizia turno" per aprire un nuovo turno di cassa.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: text.withOpacity(0.45)),
            ),
          ],
        ),
      ),
    );
  }

  

  // ─── LAYOUT WIDE (≥700px) ────────────────────────────────────────────────
  Widget _layoutWide(Color verde, Color card, Color text, Color divider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titolo("Gestione fondi cassa: ${nomeTurno.text}", text),
                const SizedBox(height: 16),
                _campo("Fondo cassa ultimo turno", fondoFinaleCtrl,   card, text, divider),
                _campo("Fondo cassa iniziale",     fondoInizialeCtrl, card, text, divider),
                _campo("Valore cassa attuale",     valoreAttualeCtrl, card, text, divider),
                const SizedBox(height: 16),
                Divider(color: divider.withOpacity(0.6)),
                const SizedBox(height: 12),
                _sectionTitle("Movimenti registrati", text),
                const SizedBox(height: 8),
                Expanded(
                  child: movimenti.isEmpty
                      ? Text("Nessun movimento registrato.",
                          style: TextStyle(color: text.withOpacity(0.6)))
                      : ListView.builder(
                          itemCount: movimenti.length,
                          itemBuilder: (_, i) =>
                              _rigaMovimento(movimenti[i], card, text, divider),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Nuovo movimento", text),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _formMovimento(card, text, divider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LAYOUT NARROW (<700px) ──────────────────────────────────────────────
  Widget _layoutNarrow(Color verde, Color card, Color text, Color divider) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _titolo("Gestione fondi cassa: ${nomeTurno.text}", text),
        const SizedBox(height: 16),
        _campo("Fondo cassa ultimo turno", fondoFinaleCtrl,   card, text, divider),
        _campo("Fondo cassa iniziale",     fondoInizialeCtrl, card, text, divider),
        _campo("Valore cassa attuale",     valoreAttualeCtrl, card, text, divider),
        const SizedBox(height: 16),
        Divider(color: divider.withOpacity(0.6)),
        const SizedBox(height: 12),
        _sectionTitle("Movimenti registrati", text),
        const SizedBox(height: 8),
        if (movimenti.isEmpty)
          Text("Nessun movimento registrato.",
              style: TextStyle(color: text.withOpacity(0.6)))
        else
          ...movimenti.map((m) => _rigaMovimento(m, card, text, divider)),
        const SizedBox(height: 16),
        Divider(color: divider.withOpacity(0.6)),
        const SizedBox(height: 12),
        _sectionTitle("Nuovo movimento", text),
        const SizedBox(height: 12),
        _formMovimento(card, text, divider),
        const SizedBox(height: 100),
      ],
    );
  }

  // ─── FORM NUOVO MOVIMENTO ────────────────────────────────────────────────
  Widget _formMovimento(Color card, Color text, Color divider) {
    return Form(
      key: _formKeyMovimento,
      child: Column(
        children: [
          // descrizione
          TextFormField(
            controller: descrizioneCtrl,
            decoration: const InputDecoration(
              labelText: "Descrizione",
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Inserisci una descrizione" : null,
          ),
          const SizedBox(height: 12),

          // tipo movimento
          DropdownButtonFormField<String>(
            value: tipoMovimentoForm,
            items: const [
              DropdownMenuItem(value: "Entrata", child: Text("Entrata")),
              DropdownMenuItem(value: "Uscita",  child: Text("Uscita")),
              DropdownMenuItem(value: "Neutro",  child: Text("Neutro")),
            ],
            onChanged: (val) {
              if (val != null) setState(() => tipoMovimentoForm = val);
            },
            decoration: const InputDecoration(
              labelText: "Tipo",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // importo
          TextFormField(
            controller: valoreCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Importo",
              prefixText: "€ ",
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Inserisci l'importo";
              final p = double.tryParse(v.replaceAll(',', '.'));
              if (p == null || p <= 0) return "Importo non valido";
              return null;
            },
          ),
          const SizedBox(height: 12),

          // contropartita (opzionale)
          TextFormField(
            controller: contropartitaCtrl,
            decoration: const InputDecoration(
              labelText: "Contropartita (fornitore / banca / altro)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // note (opzionale)
          TextFormField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Note",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────────────────────
  Widget _bottomBar(Color verdeChiaro, Color verde) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: verde,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(children: [
        _footerButton(
          shiftOpened ? 'Chiudi turno' : "Inizia turno",
          verdeChiaro.withOpacity(0.4),
          Colors.white70,
          _onTurnoTap,
        ),
        if (shiftOpened)
          _footerButton(
            "Salva movimento",
            verdeChiaro,
            Colors.white,
            () async => await _salvaNuovoMovimento(),
          ),
      ]),
    );
  }

  // ─── LOGICA APERTURA / CHIUSURA TURNO ────────────────────────────────────
  Future<void> _onTurnoTap() async {
    final aperto = await TurnoLavoro.lastShiftOpened();
    if (!aperto) {
      _mostraDialogApertura();
    } else {
      _mostraDialogChiusura();
    }
  }

  void _mostraDialogApertura() {
    final titoloCtrl = TextEditingController();
    final fondoCtrl  = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apri turno'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: titoloCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo turno',
                hintText: 'Es. Turno mattina',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci il titolo' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: fondoCtrl,
              decoration: const InputDecoration(
                labelText: 'Fondo cassa iniziale',
                hintText: 'Es. 100.00',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Inserisci il fondo cassa';
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
                  return 'Valore non valido';
                }
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final id = await TurnoLavoro.openShift(
                nomeTurno: titoloCtrl.text.trim(),
                fondoCassaIniziale:
                    double.parse(fondoCtrl.text.replaceAll(',', '.')),
              );
              if (id == 0) {
                SnackBarForcedClosure('Errore apertura turno', Colors.red);
                return;
              }
              await isOpened();
              SnackBarForcedClosure(
                'Turno avviato',
                const Color.fromARGB(255, 70, 244, 54),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Apri turno'),
          ),
        ],
      ),
    );
  }

  void _mostraDialogChiusura() {
    final fondoCtrl = TextEditingController();
    final formKey   = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
        title: const Text('Chiudi turno'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'Inserisci il fondo cassa lasciato per chiudere il turno.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: fondoCtrl,
              decoration: const InputDecoration(
                labelText: 'Fondo cassa lasciato',
                hintText: 'Es. 150.00',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Inserisci il fondo cassa';
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
                  return 'Valore non valido';
                }
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Chiudi turno'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await TurnoLavoro.closeShift(
                fondoCassaFinale:
                    double.parse(fondoCtrl.text.replaceAll(',', '.')),
              );
              await isOpened();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ──────────────────────────────────────────────────────
  Widget _titolo(String testo, Color text) => Text(
        testo,
        style: TextStyle(
          color: text.withOpacity(0.9),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _sectionTitle(String testo, Color text) => Text(
        testo,
        style: TextStyle(
          color: text.withOpacity(0.9),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _campo(
    String label,
    TextEditingController ctrl,
    Color card,
    Color text,
    Color divider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: text.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              readOnly: true,
              controller: ctrl,
              textAlign: TextAlign.end,
              style: TextStyle(color: text, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _rigaMovimento(
  MovimentoCassa m,
  Color card,
  Color text,
  Color divider,
) {
  final isDeleted    = m.deleted == 1;
  final isEntrata    = m.tipoMovimento == 'entrata';
  final isUscita     = m.tipoMovimento == 'uscita';
  final segno        = isEntrata ? '+' : isUscita ? '-' : '';
  final coloreValore = isDeleted
      ? text.withOpacity(0.3)
      : isEntrata
          ? Colors.green
          : isUscita
              ? Colors.red
              : text.withOpacity(0.8);

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      // sfondo rosso tenue se eliminato
      color: isDeleted ? Colors.red.withOpacity(0.06) : card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDeleted
            ? Colors.red.withOpacity(0.25)
            : divider.withOpacity(0.2),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── testo ────────────────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // badge "ELIMINATO"
                  if (isDeleted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "ELIMINATO",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      (m.descrizione ?? m.categoria ) +' '+ "(${ isUscita ? 'Uscita' : isEntrata ? 'Entrata' : 'Neutro'})",
                      style: TextStyle(
                        color: text.withOpacity(isDeleted ? 0.35 : 1.0),
                        fontWeight: FontWeight.w600,
                        // testo barrato se eliminato
                        decoration: isDeleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: text.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
              if (m.contropartitaNome != null &&
                  m.contropartitaNome!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  m.contropartitaNome!,
                  style: TextStyle(
                    color: text.withOpacity(isDeleted ? 0.25 : 0.6),
                    fontSize: 12,
                    decoration: isDeleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: text.withOpacity(0.3),
                  ),
                ),
              ],
              if (m.note != null && m.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  m.note!,
                  style: TextStyle(
                    color: text.withOpacity(isDeleted ? 0.25 : 0.45),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    decoration: isDeleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: text.withOpacity(0.3),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        // ── importo ──────────────────────────────────────────────────────
        Text(
          "$segno${m.importo.toStringAsFixed(2)}",
          style: TextStyle(
            color: coloreValore,
            fontWeight: FontWeight.bold,
            decoration: isDeleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: coloreValore,
          ),
        ),
        const SizedBox(width: 4),
        
        // ── tasto elimina (nascosto se già eliminato) ─────────────────────
        if (!isDeleted)
          GestureDetector(
            onTap: () {
                if( operatorLogged!.trashRoundDetails == 0 ){
                  SnackBarForcedClosure('Operatore non abilitato', Colors.red);
                  return;
                }
                _confermaEliminaMovimento(m);
            },
            child: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.red.withOpacity(0.7),
            ),
          )
        else
          const SizedBox(width: 20),
      ],
    ),
  );
}
  Future<void> _confermaEliminaMovimento(MovimentoCassa m) async {
  final conferma = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
        size: 36,
      ),
      title: const Text("Elimina movimento"),
      content: Text(
        'Vuoi eliminare "${m.descrizione ?? m.categoria}"?\n'
        'L\'operazione non può essere annullata.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text("Annulla"),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text("Elimina"),
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );

  if (conferma != true) return;

  await TurnoLavoro.delete(m.id ?? 0);
  await isOpened(); // ricarica movimenti e totali cassa
}
  
  Widget _footerButton(
    String label,
    Color bg,
    Color fg,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
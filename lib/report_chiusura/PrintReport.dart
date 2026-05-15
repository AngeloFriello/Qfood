import 'dart:convert';

import 'package:dashboard/printers/not_fiscal/not_print_function.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:dashboard/report_chiusura/ReportChiusura.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<void> printReportChiusura({
  required ReportChiusura rep,
  required bool mostraCategorie,
  required bool mostraProdotti,
  int port = 9100,
  required bool simulazione,
}) async {
  PrinterNetworkManager? printer;
  try{
  SharedPreferences pref = await SharedPreferences.getInstance();
  String? devicePref = pref.getString('device');
  if( devicePref == null ) return;
  Map device = jsonDecode(devicePref);
  String? ip       = device['noFiscalPrinterIpv4'];
  if( ip == null ) return;
  printer = PrinterNetworkManager(ip, port: port);
  final PosPrintResult connect = await printer.connect();
  List<String> linesHead = await getHeadReceipt();

if (connect != PosPrintResult.success) {
    debugPrint('Connessione stampante fallita: ${connect.msg}');
    return;
  }

  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm80, profile);
  List<int> bytes = [];

    bytes += [0x1B, 0x40];
    bytes += generator.setGlobalCodeTable('CP1252');
  // ─── STILI RIUTILIZZABILI ────────────────────────────────────────
  const PosStyles sNormal = PosStyles(
    height: PosTextSize.size1,
    width:  PosTextSize.size1,
  );
  const PosStyles sCenter = PosStyles(
    align:  PosAlign.center,
    height: PosTextSize.size1,
    width:  PosTextSize.size1,
  );
  const PosStyles sCenterBold = PosStyles(
    align:  PosAlign.center,
    bold:   true,
    height: PosTextSize.size1,
    width:  PosTextSize.size1,
  );
  const PosStyles sBoldUnderline = PosStyles(
    bold:      true,
    underline: true,
    height:    PosTextSize.size1,
    width:     PosTextSize.size1,
  );
  // ─────────────────────────────────────────────────────────────────

  bytes += generator.setGlobalCodeTable('CP1252');
  bytes += generator.emptyLines(2);

  //INTESTAZIONE PUNTO VENDITA
  bytes += [27, 97, 1];
  bytes += [0x1B, 0x45, 0x01];
  bytes += generator.text(linesHead[0], styles: sCenter);
  bytes += [0x1B, 0x45, 0x00];
  bytes += generator.text(linesHead[1], styles: sCenter);
  bytes += generator.text(linesHead[2], styles: sCenter);
  bytes += generator.text(linesHead[3], styles: sCenter);
  bytes += generator.text(linesHead[4], styles: sCenter);
  bytes += [27, 97, 0];

  bytes += generator.emptyLines(5);
  // ─── INTESTAZIONE ───────────────────────────────────────────────
  bytes += generator.text(
    'REPORT DI CHIUSURA',
    styles: sCenterBold,
  );
  bytes += generator.text(
    _formatDate(DateTime.now()),
    styles: sCenter,
  );
  bytes += generator.hr(len: 42);;

  // ─── DOCUMENTI EMESSI ────────────────────────────────────────────
  bytes += generator.text('DOCUMENTI EMESSI', styles: sBoldUnderline);
  bytes += generator.emptyLines(1);

    bytes += _rigaQtaTot(
      generator,
      'Scontrini incassati',
      '${rep.n_scontrini - rep.n_simulation}',
      _fmt(rep.scontrini_incassati - rep.simulation),
    );
    bytes += _rigaQtaTot(
      generator,
      'Scontrini sospesi',
      '${rep.n_simulation}',
      _fmt(rep.simulation),
    );
  bytes += _rigaQtaTot(generator, 'Scontrini non inc.',    '${rep.n_scontrini_non_incassati}', _fmt(rep.scontrini_non_incassati));
  bytes += _rigaQtaTot(generator, 'Scontrini annullati',   '${rep.n_scontrini_annullati}',     _fmt(rep.scontrini_annullati));
  bytes += _rigaQtaTot(generator, 'Fatture incassate',     '${rep.n_fatture_incassate}',       _fmt(rep.fatture_incassate));
  bytes += _rigaQtaTot(generator, 'Fatture non inc.',      '${rep.n_fatture_non_incassate}',   _fmt(rep.fatture_non_incassate));
  bytes += _rigaQtaTot(generator, 'Note di credito',       '${rep.n_note_credito}',            _fmt(rep.note_credito));

  if (rep.n_simulation > 0 && simulazione) {
    bytes += _rigaQtaTot(generator, 'Riscontri', '${rep.n_simulation}', _fmt(rep.simulation));
  }
  if( !simulazione ){
    rep.n_totale_documenti = rep.n_totale_documenti - rep.n_simulation;
    rep.totale_documenti   = rep.totale_documenti;
  }

  bytes += generator.emptyLines(1);
  bytes += _rigaQtaTot(generator, 'TOT. DOCUMENTI', '${rep.n_totale_documenti}', _fmt(rep.totale_documenti), bold: true);
  bytes += generator.hr(len: 42);

  // ─── DETTAGLI INCASSI ────────────────────────────────────────────
  bytes += generator.text('DETTAGLI INCASSI', styles: sBoldUnderline);
  bytes += generator.emptyLines(1);

  if (rep.paymentsAmountAndQta != null) {
      rep.paymentsAmountAndQta!.entries
          .where((e) => !e.key.endsWith('_qta'))
          .forEach((e) {
            int qta = (rep.paymentsAmountAndQta!['${e.key}_qta'] ?? 0).toInt();
            bytes += _rigaQtaTot(generator, e.key, '$qta', _fmt(e.value));
    });
  }
  if( simulazione) bytes += _rigaQtaTot(generator, 'di cui riscontro', '${rep.n_simulation}', _fmt(rep.simulation));
  bytes += generator.hr(len: 42);

  // ─── STATISTICHE ─────────────────────────────────────────────────
  bytes += generator.text('STATISTICHE', styles: sBoldUnderline);
  bytes += generator.emptyLines(1);

  if( !simulazione ){
    bytes += _rigaQtaTot(generator, 'Vendite banco', '${rep.n_vedite_banco - rep.n_simulation}', _fmt(rep.vedite_banco - rep.simulation));
  }else{
    bytes += _rigaQtaTot(generator, 'Vendite banco', '${rep.n_vedite_banco}', _fmt(rep.vedite_banco));
  }

  bytes += _rigaQtaTot(generator, 'Vendite ritiro',  '${rep.n_vendite_ritiri}',   _fmt(rep.vendite_ritiri));
  bytes += _rigaQtaTot(generator, 'Vendite consegna','${rep.n_vendite_consegne}', _fmt(rep.vendite_consegne));

  if (rep.mancia > 0) {
    bytes += _rigaQtaTot(generator, 'Mancia', '${rep.n_mancia}', _fmt(rep.mancia));
  }

  bytes += _riga(generator, 'Media scontrino', _fmt(rep.media_scontrini));

  if (rep.n_coperti > 0) {
    bytes += _riga(generator, 'N. coperti',    '${rep.n_coperti}');
    bytes += _riga(generator, 'Media coperti', _fmt(rep.media_coperti));
  }
  bytes += generator.hr(len: 42);;

  // ─── PRODOTTI ESENTI ─────────────────────────────────────────────
  if (rep.totale_prodotti_esenti > 0) {
    bytes += generator.text('PRODOTTI ESENTI', styles: sBoldUnderline);
    bytes += generator.emptyLines(1);

    if (rep.n_tabacchi > 0)       bytes += _rigaQtaTot(generator, 'Tabacchi',      '${rep.n_tabacchi}',       _fmt(rep.tabacchi));
    if (rep.n_valori_bollati > 0) bytes += _rigaQtaTot(generator, 'Valori bollati','${rep.n_valori_bollati}', _fmt(rep.valori_bollati));
    if (rep.n_giochi > 0)         bytes += _rigaQtaTot(generator, 'Giochi',        '${rep.n_giochi}',         _fmt(rep.giochi));
    if (rep.n_gratta_e_vinci > 0) bytes += _rigaQtaTot(generator, 'Gratta e vinci','${rep.n_gratta_e_vinci}', _fmt(rep.gratta_e_vinci));
    if (rep.n_biglietti > 0)      bytes += _rigaQtaTot(generator, 'Biglietti',     '${rep.n_biglietti}',      _fmt(rep.biglietti));

    bytes += generator.emptyLines(1);
    bytes += _rigaQtaTot(generator, 'TOT. ESENTI', '${rep.n_totale_prodotti_esenti}', _fmt(rep.totale_prodotti_esenti), bold: true);
    bytes += generator.hr(len: 42);;
  }

  // ─── CASTELLETTO IVA ─────────────────────────────────────────────
  if (rep.castellettoIva != null && rep.castellettoIva!.isNotEmpty) {
    bytes += generator.text('CASTELLETTO IVA', styles: sBoldUnderline);
    bytes += generator.emptyLines(1);

    for (final iva in rep.castellettoIva!) {
      final aliquota = '${iva['value'] ?? ''}%';
      final importo  = (iva['amount'] as num?)?.toDouble() ?? 0;
      final imponibile = (iva['net'] as num?)?.toDouble() ?? 0;
      bytes += _rigaQtaTot(generator, 'IVA $aliquota', _fmt(imponibile), _fmt(importo));
    } 
    bytes += generator.hr(len: 42);;
  }

  // ─── RIEPILOGO TIPOLOGIE ─────────────────────────────────────────
  if (rep.tipiCategoria != null && rep.tipiCategoria!.isNotEmpty) {
    bytes += generator.text('RIEPILOGO TIPOLOGIE', styles: sBoldUnderline);
    bytes += generator.emptyLines(1);

    for (final tipo in rep.tipiCategoria!) {
      bytes += _riga(generator, '${tipo['tipology'] ?? ''}', _fmt((tipo['amount'] as num?)?.toDouble() ?? 0));
    }
    bytes += generator.hr(len: 42);;
  }

  // ─── CATEGORIE ───────────────────────────────────────────────────
  if (rep.categories != null && rep.categories!.isNotEmpty && mostraCategorie) {
    bytes += generator.text('CATEGORIE', styles: sBoldUnderline);
    bytes += generator.emptyLines(1);

    for (final cat in rep.categories!) {
      bytes += _rigaQtaTot(
        generator,
        '${cat['title'] ?? ''}',
        '${cat['qta'] ?? 0}',
        _fmt(cat['amount'] ?? 0),
      );
    }
    bytes += generator.hr(len: 42);;
  }

  // ─── PRODOTTI VENDUTI ────────────────────────────────────────────
  if (rep.products != null && rep.products!.isNotEmpty && mostraProdotti) {
    bytes += generator.text('PRODOTTI VENDUTI', styles: sBoldUnderline);
    bytes += generator.emptyLines(1);

    for (final prod in rep.products!) {
      final String titolo  = '${prod['title'] ?? ''}';
      final dynamic qtaRaw = prod['qta'];
      final String qtaStr  = qtaRaw is num ? qtaRaw.toString() : (qtaRaw?.toString() ?? '0');

      bytes += _rigaQtaTot(generator, titolo, qtaStr, _fmt(prod['amount'] ?? 0));
    }
    bytes += generator.hr(len: 42);;
  }

  // ─── MOVIMENTI CASSA ─────────────────────────────────────────────
  bytes += generator.text('MOVIMENTI CASSA', styles: sBoldUnderline);
  bytes += generator.emptyLines(1);

  bytes += _riga(generator, 'Fondo iniziale', _fmt(rep.fondo_cassa_iniziale));
  bytes += _riga(generator, 'Entrate',        _fmt(rep.entrate_di_cassa));
  bytes += _riga(generator, 'Uscite',         _fmt(rep.uscite_di_cassa));
  bytes += _riga(generator, 'Prelievi auto.', _fmt(rep.prelievi_cassetto_automatico));
  bytes += _riga(generator, 'Tot. movimenti', _fmt(rep.totale_movimenti_cassa),bold: true);

  bytes += generator.emptyLines(1);
  bytes += _riga(generator, 'Fondo finale', _fmt(rep.fondo_cassa_finale), bold: true);
  bytes += generator.hr(len: 42);;

  // ─── FINE ────────────────────────────────────────────────────────
  bytes += generator.feed(10);
  bytes += generator.cut();

  await printer.printTicket(bytes);

  }catch( err ){
    debugPrint( err.toString());
  }finally{
    if( printer != null ) return;
    printer!.disconnect();
  }
}


// ─── HELPERS ───────────────────────────────────────────────────────────────

List<int> _rigaQtaTot(
  Generator g,
  String label,
  String qta,
  String totale, {
  bool bold = false,
}) {
  const int maxLen = 42;

  qta    = qta.trim();
  totale = totale.trim();

  if (qta.isEmpty && totale.isEmpty) {
    return _riga(g, label, '', bold: bold);
  }

  const int minSpaceBetweenQtaAndTot = 1;

  int availableForLabel = maxLen - qta.length - totale.length - minSpaceBetweenQtaAndTot;
  if (availableForLabel < 1) availableForLabel = 1;

  String lab = label;
  if (lab.length > availableForLabel) lab = lab.substring(0, availableForLabel);

  int space = lab.length == 19 ? 3 : ( 19 - (lab.length) ) + 3;
  int spacesAfterLabel = maxLen - (lab.length + space) - qta.length - totale.length - minSpaceBetweenQtaAndTot - 3;
  if (spacesAfterLabel < 1) spacesAfterLabel = 1;

  final String line = '$lab${ ' ' * space }$qta${( ' ' * spacesAfterLabel )}    $totale';

  return g.text(
    line,
    styles: PosStyles(
      bold:   bold,
      height: PosTextSize.size1,
      width:  PosTextSize.size1,
    ),
  );
}

List<int> _riga(
  Generator g,
  String label,
  String valore, {
  bool bold = false,
}) {
  const int totale = 42;
  final int spazi  = totale - label.length - valore.length;
  final String linea = spazi > 0 ? '$label${' ' * spazi}$valore' : '$label $valore';

  return g.text(
    linea,
    styles: PosStyles(
      bold:   bold,
      height: PosTextSize.size1,
      width:  PosTextSize.size1,
    ),
  );
}

String _fmt(double v) => '${v.toStringAsFixed(2)} E';

String _formatDate(DateTime d) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(d.day)}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
}
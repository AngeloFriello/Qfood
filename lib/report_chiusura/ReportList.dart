import 'package:dashboard/report_chiusura/ReportChiusura.dart';
import 'package:dashboard/state/banco_state.dart';
import 'package:flutter/material.dart';

class ReportChiusuraWidget extends StatelessWidget {
  final ReportChiusura report_;
  final bool mostraCategorie;
  final bool mostraProdotti;
  

  const ReportChiusuraWidget(
    {
      super.key, 
      required this.report_,
      required this.mostraCategorie,
      required this.mostraProdotti
      });

  @override
  Widget build(BuildContext context) {
    
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,  // ← fondamentale: occupa solo lo spazio necessario
      children: [
        _SectionCard(
          title: '📄 Documenti Emessi',
          children: [
            _ReportTable(rows: [
              ['', 'N°', 'Importo'],
              ['Scontrini incassati',    '${report_.n_scontrini}',    '€ ${report_.scontrini_incassati.toStringAsFixed(2)}'],
              if(bancoAbilitato.value)    ['Riscontri',    '${report_.n_simulation}',    '€ ${report_.simulation.toStringAsFixed(2)}'],
              ['Scontrini sospesi',      '${report_.n_scontrini_sospesi}',      '€ ${report_.scontrini_sospesi.toStringAsFixed(2)}'],
              ['Scontrini non incassati','${report_.n_scontrini_non_incassati}','€ ${report_.scontrini_non_incassati.toStringAsFixed(2)}'],
              ['Scontrini annullati',    '${report_.n_scontrini_annullati}',    '€ ${report_.scontrini_annullati.toStringAsFixed(2)}'],
              ['Fatture incassate',      '${report_.n_fatture_incassate}',      '€ ${report_.fatture_incassate.toStringAsFixed(2)}'],
              ['Fatture non incassate',  '${report_.n_fatture_non_incassate}',  '€ ${report_.fatture_non_incassate.toStringAsFixed(2)}'],
              ['Note di credito',        '${report_.n_note_credito}',           '€ ${report_.note_credito.toStringAsFixed(2)}'],
            ]),
            _TotalRow(
              label: 'Totale documenti',
              count: report_.n_totale_documenti,
              amount: report_.totale_documenti,
            ),
          ],
        ),

        _SectionCard(
          title: '🚫 Prodotti Esenti',
          children: [
            _ReportTable(rows: [
              ['', 'N°', 'Importo'],
              ['Tabacchi',      '${report_.n_tabacchi}',      '€ ${report_.tabacchi.toStringAsFixed(2)}'],
              ['Valori bollati','${report_.n_valori_bollati}','€ ${report_.valori_bollati.toStringAsFixed(2)}'],
              ['Giochi',        '${report_.n_giochi}',        '€ ${report_.giochi.toStringAsFixed(2)}'],
              ['Gratta e Vinci','${report_.n_gratta_e_vinci}','€ ${report_.gratta_e_vinci.toStringAsFixed(2)}'],
              ['Biglietti',     '${report_.n_biglietti}',     '€ ${report_.biglietti.toStringAsFixed(2)}'],
              ['Mancia',        '${report_.n_mancia}',        '€ ${report_.mancia.toStringAsFixed(2)}'],
            ]),
            _TotalRow(
              label: 'Totale esenti',
              count: report_.n_totale_prodotti_esenti,
              amount: report_.totale_prodotti_esenti,
            ),
          ],
        ),

        _SectionCard(
          title: '💳 Dettagli Incassi',
          children: [
            if (report_.paymentsAmountAndQta != null && report_.paymentsAmountAndQta!.isNotEmpty) _PaymentsTable(payments: report_.paymentsAmountAndQta!, report_: report_,),
          ],
        ),

        _SectionCard(
          title: '🏧 Movimenti Cassa',
          children: [
            _KeyValueList(items: [
              ('Fondo cassa iniziale',         '€ ${report_.fondo_cassa_iniziale.toStringAsFixed(2)}'),
              ('Entrate di cassa',             '€ ${report_.entrate_di_cassa.toStringAsFixed(2)}'),
              ('Uscite di cassa',              '€ ${report_.uscite_di_cassa.toStringAsFixed(2)}'),
              ('Prelievi cassetto automatico', '€ ${report_.prelievi_cassetto_automatico.toStringAsFixed(2)}'),
              ('Fondo cassa finale',           '€ ${report_.fondo_cassa_finale.toStringAsFixed(2)}'),
              ('Totale movimenti',             '€ ${report_.totale_movimenti_cassa.toStringAsFixed(2)}'),
            ]),
          ],
        ),

        _SectionCard(
          title: '📊 Dettagli Statistici',
          children: [
            _ReportTable(rows: [
              ['Canale',   'N°',                              'Importo'],
              ['Banco',    '${report_.n_vedite_banco}',       '€ ${report_.vedite_banco.toStringAsFixed(2)}'],
              ['Consegne', '${report_.n_vendite_consegne}',   '€ ${report_.vendite_consegne.toStringAsFixed(2)}'],
              ['Ritiri',   '${report_.n_vendite_ritiri}',     '€ ${report_.vendite_ritiri.toStringAsFixed(2)}'],
            ]),
            const SizedBox(height: 8),
            _KeyValueList(items: [
              ('Mance',           '€ ${report_.mance.toStringAsFixed(2)}'),
              ('N° scontrini',    '${ (report_.n_scontrini + report_.n_fatture_incassate + report_.n_fatture_non_incassate + ( bancoAbilitato.value ? report_.n_simulation : 0 ))}'),
              ('Media scontrino', '€ ${ (report_.totale_documenti / (report_.n_scontrini + report_.n_fatture_incassate + report_.n_fatture_non_incassate + ( bancoAbilitato.value ? report_.n_simulation : 0 ))).toStringAsFixed(2)}'),
              ('N° coperti',      '${report_.n_coperti}'),
              ('Media coperto',   '€ ${report_.media_coperti.toStringAsFixed(2)}'),
            ]),
          ],
        ),

        if (report_.tipiCategoria != null && report_.tipiCategoria!.isNotEmpty)
          _SectionCard(
            title: '🗂️ Tipologie Categoria',
            children: [
              _DynamicListTable(
                headers: const ['Tipologia', 'Importo'],
                rows: report_.tipiCategoria!
                    .map((e) => [
                          e['tipology'].toString(),
                          '€ ${(e['amount'] as double).toStringAsFixed(2)}'
                        ])
                    .toList(),
              ),
            ],
          ),

        if (report_.categories != null && report_.categories!.isNotEmpty && mostraCategorie)
          _SectionCard(
            title: '📂 Categorie Vendute',
            children: [
              _DynamicListTable(
                headers: const ['Categoria', 'Qtà', 'Importo'],
                rows: report_.categories!
                    .map((e) => [e['title'].toString(),    '${e['qta'].toString()}',    '€ ${e['amount'].toString()}'])
                    .toList(),
              ),
            ],
          ),

        if (report_.products != null && report_.products!.isNotEmpty && mostraProdotti )
          _SectionCard(
            title: '🛒 Prodotti Venduti',
            children: [
              _DynamicListTable(
                headers: const ['Prodotto', 'Qtà','Importo'],
                rows: report_.products!
                    .map((e) => [e['title'].toString(),    '${e['qta'].toString()}',    '€ ${e['amount'].toString()}'])
                    .toList(),
              ),
            ],
          ),

        if (report_.castellettoIva != null && report_.castellettoIva!.isNotEmpty)
        _ReportTable(rows: [
              ['Canale',   'N°',                              'Importo'],
              ['Banco',    '${report_.n_vedite_banco}',       '€ ${report_.vedite_banco.toStringAsFixed(2)}'],
              ['Consegne', '${report_.n_vendite_consegne}',   '€ ${report_.vendite_consegne.toStringAsFixed(2)}'],
              ['Ritiri',   '${report_.n_vendite_ritiri}',     '€ ${report_.vendite_ritiri.toStringAsFixed(2)}'],
            ]),
          _SectionCard(
            title: '🧾 Castelletto IVA',
            children: [
              _DynamicListTable(
                headers: const ['Aliquota', 'Imponibile', 'IVA'],
                rows: report_.castellettoIva!
                    .map((e) => [
                          '${e['value']}%',
                          '€ ${(e['net'] as double).toStringAsFixed(2)}',
                          '€ ${(e['amount'] as double).toStringAsFixed(2)}'
                        ])
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }
}

// ─── Sezione Card espandibile ────────────────────────────────────────────────

class _SectionCard extends StatefulWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
            ),
        ],
      ),
    );
  }
}

// ─── Tabella fissa (header + righe) ─────────────────────────────────────────

class _ReportTable extends StatelessWidget {
  final List<List<String>> rows; // prima riga = header
  const _ReportTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(2)},
      children: rows.asMap().entries.map((entry) {
        final isHeader = entry.key == 0;
        return TableRow(
          decoration: BoxDecoration(
            color: isHeader ? Colors.grey.shade100 : Colors.transparent,
          ),
          children: entry.value.map((cell) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              cell,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              textAlign: isHeader && entry.value.indexOf(cell) > 0 ? TextAlign.center : TextAlign.start,
            ),
          )).toList(),
        );
      }).toList(),
    );
  }
}

// ─── Tabella dinamica (per categorie, prodotti, iva) ─────────────────────────

class _DynamicListTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  
  const _DynamicListTable({required this.headers, required this.rows, });

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.5)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          )).toList(),
        ),
        ...rows.map((row) => TableRow(
          children: row.map((cell) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(cell, style: const TextStyle(fontSize: 13)),
          )).toList(),
        )),
      ],
    );
  }
}

// ─── Pagamenti (da Map<String, double>) ─────────────────────────────────────

class _PaymentsTable extends StatelessWidget {
  final Map<String, double> payments;
  final ReportChiusura? report_;
  const _PaymentsTable({required this.payments, required this.report_});
  
  @override
  Widget build(BuildContext context) {
    final bool simulation = bancoAbilitato.value;

    final methods = payments.keys.where((k) => !k.endsWith('_qta')).toList();
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(2)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            Padding(padding: EdgeInsets.all(6), child: Text('Metodo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: EdgeInsets.all(6), child: Text('N°',    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: EdgeInsets.all(6), child: Text('Totale',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        ),
        ...methods.map((key) {
          final qta    = (payments['${key}_qta'] ?? 0).toInt();
          final amount = payments[key] ?? 0.0;
          if( !simulation && key.trim().toUpperCase().contains('contanti'.trim().toUpperCase()) ){
            return TableRow(children: [
                Padding(padding: const EdgeInsets.all(6), child: Text(key, style: const TextStyle(fontSize: 13))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${qta - report_!.n_simulation }', style: const TextStyle(fontSize: 13))),
                Padding(padding: const EdgeInsets.all(6), child: Text('€ ${(amount -report_!.simulation).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13))),
              ]);
          }else{
              return TableRow(children: [
                Padding(padding: const EdgeInsets.all(6), child: Text(key, style: const TextStyle(fontSize: 13))),
                Padding(padding: const EdgeInsets.all(6), child: Text('$qta', style: const TextStyle(fontSize: 13))),
                Padding(padding: const EdgeInsets.all(6), child: Text('€ ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13))),
              ]);
          } 
        }),
       if(  report_ != null && simulation ) TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(6), child: Text('di cui riscontro', style: const TextStyle(fontSize: 13))),
            Padding(padding: const EdgeInsets.all(6), child: Text('${report_!.n_simulation}', style: const TextStyle(fontSize: 13))),
            Padding(padding: const EdgeInsets.all(6), child: Text('€ ${report_!.simulation.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13))),
          ]
        ),
        //SCONTI E MAGGIORAZIONI
        TableRow(
          children: [
              Padding(padding: const EdgeInsets.all(6), child: Text('Sconti', style: const TextStyle(fontSize: 13))),
              Padding(padding: const EdgeInsets.all(6), child: Text('${report_!.n_sconti.toString() }', style: const TextStyle(fontSize: 13))),
              Padding(padding: const EdgeInsets.all(6), child: Text('€ ${report_!.sconti.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13))),
            ]),
        TableRow(
          children: [
              Padding(padding: const EdgeInsets.all(6), child: Text('maggiorazioni', style: const TextStyle(fontSize: 13))),
              Padding(padding: const EdgeInsets.all(6), child: Text('${report_!.n_maggiorazioni.toString() }', style: const TextStyle(fontSize: 13))),
              Padding(padding: const EdgeInsets.all(6), child: Text('€ ${report_!.maggiorazioni.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13))),
            ])
      ],
    );
  }
}

// ─── Lista chiave-valore ──────────────────────────────────────────────────────

class _KeyValueList extends StatelessWidget {
  final List<(String, String)> items;
  const _KeyValueList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.$1, style: const TextStyle(fontSize: 13)),
            Text(item.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      )).toList(),
    );
  }
}

// ─── Riga totale evidenziata ──────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final String label;
  final int count;
  final double amount;
  const _TotalRow({required this.label, required this.count, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$count doc.  •  € ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
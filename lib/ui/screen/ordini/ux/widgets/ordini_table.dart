/* import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:dashboard/ui/screen/ordini/state/ordini_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/ordine_stato.dart';
import '../../models/ordine_tipo.dart';
import 'ordine_dettaglio_dialog.dart';


class ControllerOrdiniSelezionati extends ChangeNotifier {
  List<Ordine> _idsOrdersDeliverySelected     = [];
  List<Ordine> get idsOrdersDeliverySelected  => _idsOrdersDeliverySelected;

  void addOrder( Ordine o){
    _idsOrdersDeliverySelected.add(o);
    notifyListeners();
  }

  void removeOrder( int idOrder ){
    _idsOrdersDeliverySelected = _idsOrdersDeliverySelected.where((o) => o.id != idOrder).toList();
    notifyListeners();
  }

  void resetOrder(  ){
    _idsOrdersDeliverySelected = [];
    notifyListeners();
  }

  double totalNotPaidSelected () {
    double result = _idsOrdersDeliverySelected.fold(0.0, (sum, o) => sum + o.totaleCarrello + ( o.change ?? 0));
    return result;
  }

  double totalNotPaid ( List<Ordine> list ) {
    double result = list.fold(0.0, (sum, o) => sum + o.totaleCarrello + ( o.change ?? 0));
    return result;
  }

}


//HEADER TABELLA
class OrdiniListHeaderM3 extends StatelessWidget {
  const OrdiniListHeaderM3({
    super.key
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    ControllerOrdiniSelezionati ctrSelezionati = context.watch<ControllerOrdiniSelezionati>();


    final bg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE3E6E8);

    final fg = isDark ? Colors.grey.shade300 : Colors.grey.shade800;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: kTableWidth,
        height: 48,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _cell('# Ord. n.',     OrdiniColumns.ordine, fg),
            _cell('Tipologia',     OrdiniColumns.tipologia, fg),
            _cell('Ora',           OrdiniColumns.ora, fg),
            _cell('Stato',         OrdiniColumns.stato, fg),
            _cell('Rider',         OrdiniColumns.raider, fg),
            _cell('Resto',         OrdiniColumns.charge, fg),
            _cell('Destinatario',  OrdiniColumns.destinatario, fg),
            _cell('Totale.',       OrdiniColumns.importo, fg, right: true),
            _cell('Totale rider.', OrdiniColumns.importoRider, fg, right: true),
            _cell('Pagato',        OrdiniColumns.paid, fg),
            _cell('Note',                   OrdiniColumns.note, fg),
            _cell('Aperto/Chiuso',          OrdiniColumns.printed, fg),
          ],
        ),
      ),
    );

  }

  Widget _cell(String text, double width, Color color, {bool right = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: _style(color),
      ),
    );
  }

  TextStyle _style(Color color) => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: color,
  );
}


class OrdiniListM3 extends StatefulWidget {
  const OrdiniListM3({
    super.key
  });

  @override
  State<OrdiniListM3> createState() => _OrdiniListM3State();
}

class _OrdiniListM3State extends State<OrdiniListM3> {
    List<OperatoreModel> riders            = [];
    

    Future<void> getRiders ()async{
     List<OperatoreModel> temp = await OperatoreModel.getOperators();
     setState(() {
       riders = temp.where((o)=> o.rider == 1).toList();
     });
    }

    @override
    void initState() {
      getRiders();
      super.initState();
    }

    @override
    Widget build(BuildContext context) {
    OrdiniListController crtOrders = context.watch<OrdiniListController>();
    ControllerOrdiniSelezionati ctrSelezionati = context.watch<ControllerOrdiniSelezionati>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    


    final cardBg = isDark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFECEFF1);
    

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: kTableWidth,
        child: ListView.separated(
          key: Key(DateTime.now().microsecondsSinceEpoch.toString()) ,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
          itemCount: crtOrders.ordini.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) {
            Ordine o = crtOrders.ordini[i];
            TextEditingController changeCtr = TextEditingController(text: (o.change ?? 0).toString());
            TextEditingController riderController = TextEditingController(text: o.idRider.toString());
            TextEditingController ctrMenu = TextEditingController();
            return Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              elevation: isDark ? 2 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await  showDialog(
                      context: context,
                      builder: (_) => OrdineDettaglioDialog(ordine: o, setStateParentForOrders: () => setState(() {
                      }),),
                    );
                  final cc = context.read<OrdiniListController>();
                  await cc.getOrders();
                  setState(() {
                    
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22, 
                    vertical: 18
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: OrdiniColumns.box,
                        child: Checkbox(
                          value: ctrSelezionati.idsOrdersDeliverySelected.indexWhere((o_) => o_.id == o.id ) > -1,
                          onChanged: (v) {
                            if( o.tipo == OrdineTipo.consegna ){
                              if( ctrSelezionati.idsOrdersDeliverySelected.indexWhere((o_) => o_.id == o.id ) > -1 ){
                                ctrSelezionati.removeOrder(o.id ?? 0);
                              }else{
                                ctrSelezionati.addOrder(o);
                              }
                            }
                            setState(() {
                              
                            });
                          }
                          ),
                      ),
                       // ORDINE
                      SizedBox(
                        width: OrdiniColumns.ordine,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${o.id}',
                                style: theme.textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              o.id
                                  .toString()
                                  .substring(o.id.toString().length - 1),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),

                      // TIPOLOGIA
                      SizedBox(
                        width: OrdiniColumns.tipologia,
                        child: _TipoBadge(tipo: o.tipo),
                      ),

                      // ORA
                      SizedBox(
                        width: OrdiniColumns.ora,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(o.data),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy').format(o.data),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      // STATO
                      SizedBox(
                        width: OrdiniColumns.stato,
                        child: DropdownMenu(
                          controller: ctrMenu,
                          onSelected: (value) async {
                            if( value == 'Completato' ){
                              ctrMenu.text = o.stato.label;
                              SnackBarForcedClosure('Impossibile completare ordine manualmente', Colors.red);
                              return;
                            }
                            switch (value) {
                              case 'Partito':
                                await Ordine.changeStatus(o.id ?? 0, OrdineStato.partito.label);
                                break;
                              case 'Nuovo':
                                await Ordine.changeStatus(o.id ?? 0, OrdineStato.nuovo.label);
                                break;
                              case 'Annullato':
                                await Ordine.changeStatus(o.id ?? 0, OrdineStato.annullato.label);
                                break;
                              case 'In preparazione':
                                await Ordine.changeStatus(o.id ?? 0, OrdineStato.inPreparazione.label);
                                break;
                              case 'Pronto':
                                await Ordine.changeStatus(o.id ?? 0, OrdineStato.pronto.label);
                                break;
                              default:
                            }
                            await crtOrders.getOrders();
                          },
                          width: OrdiniColumns.stato,
                          enableFilter: false,
                          enableSearch: false,
                          initialSelection: o.stato.label,
                          dropdownMenuEntries: OrdineStato.values.map((s) => DropdownMenuEntry(
                            value: s.label,
                            label: s.label,
                          )).toList(),
                        ),
                      ),
                      
                      // Rider
                      SizedBox(
                        width: OrdiniColumns.raider,
                        child: DropdownMenu(
                          controller: riderController,
                          onSelected: (value) async {
                            int? idRaider = value as int?;
                            await Ordine.uploadRider(idRaider ,o.id ?? 0);
                          },
                          width: OrdiniColumns.raider,
                          enableFilter: false,
                          enableSearch: false,
                          initialSelection: o.idRider,
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

                      // resto
                      SizedBox(
                        width: OrdiniColumns.charge,
                        child: TextField(
                                  controller: changeCtr,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                onChanged: (value) async {
                                  double vv = 0;
                                  if (value.contains('.')) {
                                    vv = double.tryParse(value)!;
                                  } else {
                                    vv = double.parse(int.tryParse(value)!.toString())  ;
                                  }
                                  final cc = context.read<OrdiniListController>();
                                  await Ordine.uploadChange(vv,o.id ?? 0);
                                  //await cc.getOrders();
                                },
                              ),
                      ),

                      // DESTINATARIO
                      SizedBox(
                        width: 320,
                        child: Text(
                          o.titleCustomer,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // IMPORTO
                      SizedBox(
                        width: OrdiniColumns.importo,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${o.totaleCarrello} €',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // totale rider
                      SizedBox(
                        width: OrdiniColumns.importoRider,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${o.totaleCarrello + (o.change ?? 0)} €',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // RIDER
                      SizedBox(
                        width: OrdiniColumns.rider,
                        child: const Text('-'),
                      ),

                      // PAGATO
                      SizedBox(
                        width: OrdiniColumns.paid,
                        child: Text(
                          o.paid == 0 ? 'Da pagare' : 'Pagato',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                            o.paid == 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // NOTE
                      SizedBox(
                        width: OrdiniColumns.note,
                        child: Text(
                          o.note ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // STAMPATO 
                      SizedBox(
                        width: OrdiniColumns.printed,
                        child: Text(
                          style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18 ),
                          o.receiptPrinted == 0 ? 'A' : 'C',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      /* SizedBox(
                        width: OrdiniColumns.checkbox,
                        child: Checkbox(
                          value: false,
                          onChanged: (_) {
        
                          },
                        ),
                      ),
        
                      _fixed(
                        OrdiniColumns.ordine,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${o.id}', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              o.id.toString().substring(o.id.toString().length - 1),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
        
                      _fixed(
                        OrdiniColumns.tipologia,
                        _TipoBadge(tipo: o.tipo),
                      ),
        
                      _fixed(
                        OrdiniColumns.ora,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(o.data),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 22,            // ⬅️ prima ~20
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy').format(o.data),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15.5,          // ⬅️ prima ~14
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.9),
                              ),
                            ),
        
                          ],
                        ),
                      ),
                      _fixed(
                          OrdiniColumns.stato, 
                          DropdownMenu(
                          key: Key('ordine-${o.id}-${o.stato.label}'),
                          enableFilter: false,
                          enableSearch: false,
                          onSelected:(value) async {
                            bool resp = await Ordine.changeStatus(o.id ?? 0, value ?? 'Nuovo');
                            if( !resp ){
                              SnackBarForcedClosure('Errore nel cambio stato', Colors.red);
                              crtOrders.getOrders();
                              return;
                            }
                            SnackBarForcedClosure('Stato cambiato', Colors.green);
                            crtOrders.getOrders();
                          },
                          leadingIcon: Icon(Icons.circle, color:  colorStatus_,),
                          initialSelection: o.stato.label,
                          dropdownMenuEntries: OrdineStato.values.map((s) => DropdownMenuEntry(value: s.label, label: s.label)).toList()
                        ),
                      ),
                      Expanded(
                        child: Text(
                          o.titleCustomer,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
        
        
                      _fixed(
                        OrdiniColumns.importo,
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${o.totaleCarrello} €',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
        
                        ),
                      ),
        
                      _fixed(
                        OrdiniColumns.rider,
                        const Text('-'),
                      ),
        
                      _fixed(
                        OrdiniColumns.paid,
                        o.paid == 0
                        ?
                        Text('Da pagare', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),)
                        :
                        Text('Pagato',    style: TextStyle(color: const Color.fromARGB(255, 58, 203, 0), fontWeight: FontWeight.bold)), 
                      ),
        
                      _fixed(
                        OrdiniColumns.note,
                        Text(o.note ?? ''),
                      ), */


                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}



class _TipoBadge extends StatelessWidget {
  final OrdineTipo tipo;

  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isConsegna = tipo == OrdineTipo.consegna;

    final bg = isConsegna
        ? (isDark
        ? const Color(0xFF1F3D2B)
        : const Color(0xFFE1F3EA))
        : (isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEDEDED));

    final fg = isConsegna
        ? (isDark ? Colors.white : const Color(0xFF1B5E20))
        : (isDark ? Colors.white : Colors.black87);



    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tipo == OrdineTipo.consegna ? Icons.delivery_dining :  tipo == OrdineTipo.ritiro ? Icons.storefront : Icons.restaurant_menu,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            tipo.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}


Map<String, Color> colorStatus (OrdineStato stato) {
  switch (stato) {
      case OrdineStato.nuovo:
      return {
            "bg" : const Color(0xFFFFF3E0), // arancio chiarissimo
            "fg" : const Color(0xFFE65100) // arancio scuro
      };

      case OrdineStato.inPreparazione:
        return {
            "bg" : const Color(0xFFE8F5E9),
            "fg" : const Color(0xFF1B5E20) 
        };

      case OrdineStato.annullato:
        return {
            "bg" : const Color(0xFFFDECEA),
            "fg" : const Color(0xFFB71C1C)  
        };

      default:
      return {
            "bg" : Colors.grey.shade200,
            "fg" : Colors.grey.shade800 
        };
    }
}


/// ================== STATO CHIP ==================
class _StatoChip extends StatelessWidget {
  final OrdineStato stato;

  const _StatoChip({required this.stato});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;

    switch (stato) {
      case OrdineStato.nuovo:
        bg = const Color(0xFFFFF3E0); // arancio chiarissimo
        fg = const Color(0xFFE65100); // arancio scuro
        break;

      case OrdineStato.inPreparazione:
        bg = const Color(0xFFE8F5E9); // verde chiarissimo
        fg = const Color(0xFF1B5E20); // verde scuro
        break;

      case OrdineStato.annullato:
        bg = const Color(0xFFFDECEA);
        fg = const Color(0xFFB71C1C);
        break;

      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        stato.label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 1.1,
        ),
      ),
    );
  }
}

const double kHorizontalRowPadding = 22 * 2; // 44
const double kListPadding = 10 * 2; // 20


const double kTableWidth =
        OrdiniColumns.ordine +
        OrdiniColumns.tipologia +
        OrdiniColumns.ora +
        OrdiniColumns.stato +
        320 +
        OrdiniColumns.importo +
        OrdiniColumns.importoRider +
        OrdiniColumns.rider +
        OrdiniColumns.paid +
        OrdiniColumns.note +
        OrdiniColumns.raider +
        OrdiniColumns.charge +
        OrdiniColumns.printed +
        OrdiniColumns.box +
        kHorizontalRowPadding +
        kListPadding;



class OrdiniColumns {
  static const double ordine       = 100;
  static const double tipologia    = 150;
  static const double ora          = 100;
  static const double stato        = 190;
  static const double importo      = 150;
  static const double importoRider = 150;
  static const double rider        = 80;
  static const double note         = 120;
  static const double paid         = 90;
  static const double destinatario = 250;
  static const double raider       = 190;
  static const double charge       = 120;
  static const double printed      = 150;
  static const double box          = 50;
} */

import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/operator.dart';
import 'package:dashboard/ui/screen/ordini/models/ordine.dart';
import 'package:dashboard/ui/screen/ordini/state/ordini_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/ordine_stato.dart';
import '../../models/ordine_tipo.dart';
import 'ordine_dettaglio_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ControllerOrdiniSelezionati extends ChangeNotifier {
  List<Ordine> _idsOrdersDeliverySelected    = [];
  List<Ordine> get idsOrdersDeliverySelected => _idsOrdersDeliverySelected;

  void addOrder(Ordine o) {
    _idsOrdersDeliverySelected.add(o);
    notifyListeners();
  }

  void removeOrder(int idOrder) {
    _idsOrdersDeliverySelected =
        _idsOrdersDeliverySelected.where((o) => o.id != idOrder).toList();
    notifyListeners();
  }

  void resetOrder() {
    _idsOrdersDeliverySelected = [];
    notifyListeners();
  }

  double totalNotPaidSelected() {
    return _idsOrdersDeliverySelected.fold(
      0.0,
      (sum, o) => sum + o.totaleCarrello + (o.change ?? 0),
    );
  }

  double totalNotPaid(List<Ordine> list) {
    return list.fold(
      0.0,
      (sum, o) => sum + o.totaleCarrello + (o.change ?? 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIMENSIONI DESKTOP

class OrdiniColumns {
  static const double box          = 52;
  static const double ordine       = 100;
  static const double tipologia    = 120;
  static const double ora          = 95;
  static const double stato        = 190;
  static const double raider       = 200;
  static const double charge       = 130;
  static const double destinatario = 180;
  static const double importo      = 95;
  static const double importoRider = 130;
  static const double paid         = 120;
  static const double note         = 90;
  static const double printed      = 160;
}

const double kTableWidth =
    OrdiniColumns.box +
    OrdiniColumns.ordine +
    OrdiniColumns.tipologia +
    OrdiniColumns.ora +
    OrdiniColumns.stato +
    OrdiniColumns.raider +
    OrdiniColumns.charge +
    OrdiniColumns.destinatario +
    OrdiniColumns.importo +
    OrdiniColumns.importoRider +
    OrdiniColumns.paid +
    OrdiniColumns.note +
    OrdiniColumns.printed;

// ─────────────────────────────────────────────────────────────────────────────
// HEADER

class OrdiniListHeaderM3 extends StatelessWidget {
  const OrdiniListHeaderM3({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerBg = isDark ? const Color(0xFF171717) : Colors.white;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _headerCell(
            'Ordine',
            Icons.receipt_long_rounded,
            OrdiniColumns.box + OrdiniColumns.ordine,
          ),
          _headerCell('Tipo',          Icons.category_rounded,       OrdiniColumns.tipologia),
          _headerCell('Ora',           Icons.schedule_rounded,       OrdiniColumns.ora),
          _headerCell('Stato',         Icons.flag_rounded,           OrdiniColumns.stato),
          _headerCell('Rider',         Icons.delivery_dining_rounded, OrdiniColumns.raider),
          _headerCell('Resto',         Icons.payments_rounded,       OrdiniColumns.charge),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: _headerCell('Cliente', Icons.person_rounded, OrdiniColumns.destinatario),
          ),
          _headerCell('Totale',        Icons.euro_rounded,           OrdiniColumns.importo,      right: true),
          _headerCell('Tot Rider',     Icons.wallet_rounded,         OrdiniColumns.importoRider, right: true),
          _headerCell('Pagato',        Icons.credit_card_rounded,    OrdiniColumns.paid),
          _headerCell('Note',          Icons.notes_rounded,          OrdiniColumns.note),
          _headerCell('Caller',        Icons.numbers,                OrdiniColumns.printed),
          _headerCell('Aperto/Chiuso', Icons.receipt_rounded,        OrdiniColumns.printed),
        ],
      ),
    );
  }

  Widget _headerCell(
    String title,
    IconData icon,
    double width, {
    bool right = false,
  }) {
    return Container(
      width: width,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            right ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
                letterSpacing: -.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTA

class OrdiniListM3 extends StatefulWidget {
  const OrdiniListM3({super.key});

  @override
  State<OrdiniListM3> createState() => _OrdiniListM3State();
}

class _OrdiniListM3State extends State<OrdiniListM3> {
  List<OperatoreModel> riders = [];

  Future<void> getRiders() async {
    List<OperatoreModel> temp = await OperatoreModel.getOperators();
    setState(() {
      riders = temp.where((o) => o.rider == 1).toList();
    });
  }

  @override
  void initState() {
    getRiders();
    super.initState();
  }

  Color getStatusColor(String stato) {
    switch (stato) {
      case 'Nuovo':         return const Color(0xFF4DA3FF);
      case 'In preparazione': return const Color(0xFFFFB547);
      case 'Pronto':        return const Color(0xFF00C853);
      case 'Partito':       return const Color(0xFF7C4DFF);
      case 'Annullato':     return const Color(0xFFFF5252);
      case 'Completato':    return const Color(0xFFB5FF00);
      default:              return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final crtOrders      = context.watch<OrdiniListController>();
    final ctrSelezionati = context.watch<ControllerOrdiniSelezionati>();
    final isDark         = Theme.of(context).brightness == Brightness.dark;

    final bg     = isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);
    final cardBg = isDark ? const Color(0xFF1C1C1C) : Colors.white;

    return Container(
      color: bg,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
              itemCount: crtOrders.ordini.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final o = crtOrders.ordini[i];

                final changeCtr = TextEditingController(
                  text: (o.change ?? 0).toString(),
                );
                final riderController = TextEditingController(
                  text: riders.where((op) => op.id == o.idRider).firstOrNull?.title ?? '',
                );
                final ctrMenu = TextEditingController(
                  text: o.stato.label,
                );
                return Material(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => OrdineDettaglioDialog(
                          ordine: o,
                          setStateParentForOrders: () => setState(() {}),
                        ),
                      );
                      await crtOrders.getOrders();
                      setState(() {});
                    },
                    child: Container(
                      height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.04),
                        ),
                      ),
                      child: Row(
                        children: [

                          // ── ORDINE ───────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.box + OrdiniColumns.ordine,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Checkbox(
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      value: ctrSelezionati
                                              .idsOrdersDeliverySelected
                                              .indexWhere((o_) => o_.id == o.id) >
                                          -1,
                                      onChanged: (v) {
                                        if (o.tipo == OrdineTipo.consegna) {
                                          if (ctrSelezionati.idsOrdersDeliverySelected.indexWhere((o_) => o_.id == o.id) > -1) {
                                            ctrSelezionati.removeOrder(o.id ?? 0);
                                          } else {
                                            ctrSelezionati.addOrder(o);
                                          }
                                        }
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB5FF00).withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 18,
                                      color: Color(0xFF7EA800),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${o.id}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd MMM').format(o.data),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── TIPO ─────────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.tipologia,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _TipoBadge(tipo: o.tipo),
                            ),
                          ),

                          // ── ORA ──────────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.ora,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(o.data),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM').format(o.data),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── STATO ────────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.stato,
                            child: DropdownMenu<String>(
                              controller: ctrMenu,
                              initialSelection: o.stato.label,
                              width: OrdiniColumns.stato - 10,
                              enableFilter: false,
                              enableSearch: false,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                isDense: true,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF232323)
                                    : const Color(0xFFF8F8F8),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              trailingIcon: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: getStatusColor(ctrMenu.text),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: getStatusColor(ctrMenu.text)
                                          .withOpacity(0.35),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              onSelected: (value) async {
                                if (value == null) return;
                                await Ordine.changeStatus(o.id ?? 0, value);
                                setState(() => ctrMenu.text = value);
                                await crtOrders.getOrders();
                              },
                              dropdownMenuEntries: OrdineStato.values
                                  .map((s) => DropdownMenuEntry<String>(
                                        value: s.label,
                                        label: s.label,
                                      ))
                                  .toList(),
                            ),
                          ),

                          // ── RIDER ────────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.raider,
                            child: DropdownMenu<int?>(
                              controller: riderController,
                              initialSelection: o.idRider,
                              width: OrdiniColumns.raider - 10,
                              enableFilter: false,
                              enableSearch: false,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                isDense: true,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF232323)
                                    : const Color(0xFFF8F8F8),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              trailingIcon: const Icon(
                                Icons.delivery_dining_rounded,
                                size: 16,
                                color: Color(0xFF7EA800),
                              ),
                              onSelected: (value) async {
                                await Ordine.uploadRider(value, o.id ?? 0);
                              },
                              dropdownMenuEntries: [
                                const DropdownMenuEntry<int?>(
                                  value: null,
                                  label: 'Nessuno',
                                ),
                                ...riders.map((s) => DropdownMenuEntry<int?>(
                                      value: s.id,
                                      label: s.title,
                                    )),
                              ],
                            ),
                          ),

                          // ── RESTO ────────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.charge,
                            child: TextField(
                              controller: changeCtr,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF232323)
                                    : const Color(0xFFF8F8F8),
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  size: 16,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 46,
                                  minHeight: 46,
                                ),
                                suffixText: '€',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) async {
                                double vv = 0;
                                if (value.contains('.')) {
                                  vv = double.tryParse(value) ?? 0;
                                } else {
                                  vv = double.parse(
                                      (int.tryParse(value) ?? 0).toString());
                                }
                                await Ordine.uploadChange(vv, o.id ?? 0);
                              },
                            ),
                          ),

                          // ── CLIENTE ──────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: SizedBox(
                              width: OrdiniColumns.destinatario,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.person,
                                      size: 15,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      o.titleCustomer,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── IMPORTO ──────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.importo,
                            child: Center(
                              child: Text(
                                '${o.totaleCarrello} €',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          // ── IMPORTO RIDER ────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.importoRider,
                            child: Center(
                              child: Text(
                                '${o.totaleCarrello + (o.change ?? 0)} €',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          // ── PAGATO ───────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.paid,
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: 28,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: o.paid == 0
                                      ? Colors.red.withOpacity(0.10)
                                      : Colors.green.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  o.paid == 0 ? 'Da pagare' : 'Pagato',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: o.paid == 0
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── NOTE ─────────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.note,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 8,
                              ),
                              child: Text(
                                o.note ?? '-',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // ── CALLER ────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.printed,
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                child: Center(
                                  child: Text(
                                    o.callerPager ?? '-',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── SCONTRINO ────────────────────────────────
                          SizedBox(
                            width: OrdiniColumns.printed,
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: o.receiptPrinted == 0
                                      ? Colors.orange.withOpacity(0.12)
                                      : Colors.green.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    o.receiptPrinted == 0 ? 'A' : 'C',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: o.receiptPrinted == 0
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIPO BADGE

class _TipoBadge extends StatelessWidget {
  final OrdineTipo tipo;

  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final isConsegna = tipo == OrdineTipo.consegna;

    final bg = isConsegna
        ? (isDark ? const Color(0xFF1F3D2B) : const Color(0xFFE1F3EA))
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEDEDED));

    final fg = isConsegna
        ? (isDark ? Colors.white : const Color(0xFF1B5E20))
        : (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tipo == OrdineTipo.consegna
                ? Icons.delivery_dining
                : tipo == OrdineTipo.ritiro
                    ? Icons.storefront
                    : Icons.restaurant_menu,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            tipo.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/Service_Socket/service_ws_server.dart';
import 'package:dashboard/modelli/table.dart';
import 'package:dashboard/ui/screen/tavoli/operativita/widgets_tavolo/controllerTableOpened.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../modelli/customer.dart';
import '../../../checkout/cliente/InserisciClienteVista.dart';

String differenzaTempoIso(String dataInizioIso, {String? dataFineIso}) {
  // Forza DB come UTC: aggiungi Z e converti a local
  final inizioUtc = DateTime.parse(dataInizioIso).toLocal(); // 12:20 IT
  final fine = dataFineIso != null 
      ? DateTime.parse(dataFineIso + 'Z').toLocal() 
      : DateTime.now(); // 14:28 IT
      
  final diff = fine.difference(inizioUtc);
  final ore = diff.inHours;
  final minuti = diff.inMinutes - (ore * 60);
  final secondi = diff.inSeconds % 60;
  
  return '${ore.toString().padLeft(2, '0')}:'
         '${minuti.toString().padLeft(2, '0')}:'
         '${secondi.toString().padLeft(2, '0')}';
}


class TavoloInfoSection extends StatefulWidget {
  final TableModel tavolo;

  const TavoloInfoSection({
    super.key,
    required this.tavolo,
  });

  @override
  State<TavoloInfoSection> createState() => _TavoloInfoSectionState();
}

String isoToOra(String iso8601) {
  final data =  DateTime.parse(iso8601);
  return DateFormat('HH:mm:ss').format(data); // "10:43:00"[web:33]
}


class _TavoloInfoSectionState extends State<TavoloInfoSection> {
  
  final TextEditingController noteController = TextEditingController();
  final TextEditingController pagamentoCtrl =
  TextEditingController(text: "1");
  String timeFromOpen = '';
  Timer? timerOpen;
  bool pagamentoCompleto = true;
  bool servizioAttivo = true;
  CustomerModel? clienteSelezionato;
  int? listinoSelezionato;
  String camera = "";
  
  @override
  void initState() {
    setState(() {
      clienteSelezionato =  context.read<ControllerTableOpened>().customer;
    });
    // TODO: implement initState
    if( widget.tavolo.dateStartTable == null ) return;
      timerOpen = Timer.periodic(Duration(seconds: 1), (timer) => setState(() {
        timeFromOpen = differenzaTempoIso(  widget.tavolo.dateStartTable == null ? DateTime.now().add(const Duration(hours: 1)).toIso8601String() :  widget.tavolo.dateStartTable!);
      }),);
    super.initState();
  }

  @override
  void dispose() {
    timerOpen?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme         = Theme.of(context);
    final cs            = theme.colorScheme;
    final width         = MediaQuery.of(context).size.width;
    final ctrlTableOpen = context.read<ControllerTableOpened>();
    final bool isMobile = width < 700;
    final bool isTablet = width >= 700 && width < 1100;

    


    return Container(
        color: cs.surface,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 10 : 16,
          ),
          child: Column(

          children: [

          /// NOTE
          _noteField(cs),

          const SizedBox(height: 12),

          /// RIGA 1
          _responsiveRow([
            _infoBox("Aperto", isoToOra(widget.tavolo.dateStartTable == null ? DateTime.now().add(const Duration(hours: 1)).toIso8601String() : widget.tavolo.dateStartTable!)),
            _infoBox("Attivo", timeFromOpen),
            _clienteBox(),
          ], isMobile),

          const SizedBox(height: 10),

          /// RIGA 2
          _responsiveRow([
            _listinoDropdown(),
            _infoBox("Camera", camera.isEmpty ? "—" : camera),
            _pagamentoCompletoBox(),
          ], isMobile),

          const SizedBox(height: 14),

          /// RIGA TOTALI
          _responsiveRow([
            _infoBox("Cons.", "0"),
            _infoBox("Tot.", "${ctrlTableOpen.totaleCarrello}€"),
            _servizioBox(),
          ], isMobile),
        ],
      ),
    ),
    );
  }

  // ============================================================
  // NOTE
  // ============================================================

  Widget _noteField(ColorScheme cs) { 
    return TextField(
      controller: context.read<ControllerTableOpened>().controllerNote,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: "Note",
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(.35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // INFO BOX GENERICA
  // ============================================================

  Widget _infoBox(String label, String value) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CLIENTE
  // ============================================================

  Widget _clienteBox() {
    final cs = Theme.of(context).colorScheme;
    final bool hasCliente = clienteSelezionato != null;

    return InkWell(
      onTap: hasCliente ? null : _apriModaleCliente,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.group_outlined, size: 18),
            const SizedBox(width: 8),

            Expanded(
              child: Text(
                hasCliente
                    ? clienteSelezionato!.titleCustomer
                    : "Aggiungi cliente",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (hasCliente)
              InkWell(
                onTap: () {
                  final ctrServer  = context.read<ControllerWsServer>();
                  final ctrlTavolo = context.read<ControllerTableOpened>();
                  ctrlTavolo.setCustomer(null);
                  setState(() {
                    clienteSelezionato = null;
                  });
                  ctrServer.updateTableServer(ctrlTavolo.table!.id, ctrlTavolo.getTable()!);
                },
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }


  void _apriModaleCliente() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width < 700
              ? MediaQuery.of(context).size.width * .95
              : 800,
          height: MediaQuery.of(context).size.height * .90,

          child: InserisciClienteSheet(
            onSelect: (cliente) {
              final ctrlTavolo = context.read<ControllerTableOpened>();
              final ctrServer  = context.read<ControllerWsServer>();
              ctrlTavolo.setCustomer(cliente);
              setState(() {
                clienteSelezionato = cliente;
              });
              //AGGIUNGO CLIENTE AL TAVOLO
              ctrServer.updateTableServer(ctrlTavolo.table!.id, ctrlTavolo.getTable()!);
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }


  // ============================================================
  // LISTINO SELECT
  // ============================================================

  Widget _listinoDropdown() {
    final cs = Theme.of(context).colorScheme;
    final ctrlTable = context.read<ControllerTableOpened>();

    //se prima apertura imposto primo listino
    if( ctrlTable.idPriceList == null && listsPrice.isNotEmpty ){
      ctrlTable.setIdPriceList( listsPrice[0].id );
      setState(() => listinoSelezionato = listsPrice[0].id!);
    }
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: ctrlTable.idPriceList,
          isExpanded: true,
          items: listsPrice.map((lp) => DropdownMenuItem(value: lp.id, child: Text(lp.title)) ).toList(), 
          onChanged: (v) {
            ctrlTable.setIdPriceList( v );
            setState(() => listinoSelezionato = v!);
            final ctrServer  = context.read<ControllerWsServer>();
            final ctrlTavolo = context.read<ControllerTableOpened>();
            ctrServer.updateTableServer(ctrlTavolo.table!.id, ctrlTavolo.getTable()!);
          },
        ),
      ),
    );
  }

  // ============================================================
  // PAGAMENTO COMPLETO
  // ============================================================

  Widget _pagamentoCompletoBox() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text(
            "P. completo",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          SizedBox(
            width: 40,
            child: TextField(
              controller: pagamentoCtrl,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Switch(
            value: pagamentoCompleto,
            onChanged: (v) {
              setState(() => pagamentoCompleto = v);
            },
          )
        ],
      ),
    );
  }

  // ============================================================
  // SERVIZIO SWITCH
  // ============================================================

  Widget _servizioBox() {
    final cs = Theme.of(context).colorScheme;
    final ctrlTabOpen = context.read<ControllerTableOpened>();

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text(
            "Servizio",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Text("0,00 €"),
          const SizedBox(width: 8),
          Switch(
            value: ctrlTabOpen.serviceTable == 1 ? true : false,
            activeColor: const Color(0xFFD0DD18),
            onChanged: (v) {
              if( v ){
                ctrlTabOpen.setServiceTable( 1 );
              }else{
                ctrlTabOpen.setServiceTable( 0 );
              }
            },
          )
        ],
      ),
    );
  }

  // ============================================================
  // RESPONSIVE ROW
  // ============================================================

  Widget _responsiveRow(List<Widget> children, bool isMobile) {
    if (isMobile) {
      return Column(
        children: children
            .map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: e,
        ))
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((e) => Flexible(
        fit: FlexFit.tight,

        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: e,
        ),
      ))
          .toList(),
    );
  }
}

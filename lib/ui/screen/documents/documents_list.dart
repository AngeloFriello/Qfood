import 'package:dashboard/modelli/device.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/state/banco_state.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'document_detail_modal.dart';

class DocumentsList extends StatefulWidget {
  final VoidCallback onClose;

  const DocumentsList({
    super.key,
    required this.onClose,
  });

  @override
  State<DocumentsList> createState() => DocumentsListState();
}

class DocumentsListState extends State<DocumentsList> {
  List<Documento> listDocumets = [];
  TextEditingController controllerDate = TextEditingController();
  DateTime date = DateTime.now();
  List<Device> listDevices = [];
  int? filtroDispositivo;
  String? filtroTipo;

  Future<void> allDocuments () async {
    try{
    listDevices = await Device.devices();
    final day = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    String query = """SELECT * FROM documents 
                      WHERE date(realDate) = '$day' 
                      ORDER BY realDate DESC;""";
     List<Map<String, dynamic>> respDb = await LocalDB.query(query);
     
     List<Documento> list = respDb.map((d) => Documento.fromMap(d)).toList();
     debugPrint(list.toString());
    setState(() {
      List<Documento> listTemp = [...list];
      if( !bancoAbilitato.value )  listTemp = list.where((d) => d.overrideMovementType != 'simulation').toList();
      if( filtroTipo != null ){
        String? type = filtroTipo == 'Scontrino' ? null : filtroTipo == 'Storno' ? 'cancel_rt' : filtroTipo == 'Fattura' ? 'invoice' : 'invoice';
        listTemp = list.where((d) => type == 'cancel_rt' ? (d.overrideMovementType == 'cancel_rt' || d.overrideMovementType == 'credit_note') : d.overrideMovementType == type ).toList();
      }
      if( filtroDispositivo != null ){
        listTemp = listTemp.where((d) => d.idDevice == filtroDispositivo ).toList();
      }
      listDocumets = listTemp;
    });
    }catch(err){
      debugPrint(err.toString());
    }
  }

  @override
  void initState() {
    allDocuments();
    super.initState();
  }


  Widget _dropdownFiltro(
      BuildContext context, {
        required String label,
        required dynamic value,
        required List<dynamic> items,
        required ValueChanged<dynamic> onChanged,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DropdownButtonFormField<dynamic>(
      value: value,
      isExpanded: true,
      items: [
        const DropdownMenuItem<dynamic>(
          value: null,
          child: Text("Tutti"),
        ),
        ...items.map(
              (e) => DropdownMenuItem<dynamic>(
            value: (e is String) ? e : e.id,
            child: Text((e is String) ? e : e.title),
          ),
        ),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? cs.surface // niente nero
              : cs.surface,
        ),
        child: Column(
        children: [

          Row(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _closeButton(context, widget.onClose),
              ),
            ],
          ),


          /// HEADER CARD
          Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(20),
            color: cs.surfaceContainerHighest.withOpacity(isDark ? .25 : .6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _input(
                      "Seleziona data",
                      controller: controllerDate,
                      icon: Icons.calendar_today_rounded,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          locale: const Locale('it', 'IT'),
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          date = picked;
                          controllerDate.text =
                          "${picked.day.toString().padLeft(2, '0')}/"
                              "${picked.month.toString().padLeft(2, '0')}/"
                              "${picked.year}";
                          allDocuments();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
           const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _dropdownFiltro(
                  context,
                  label: "Tipo",
                  value: filtroTipo,
                  items: const [
                    "Scontrino",
                    "Fattura",
                    "Storno",
                  ],

                  onChanged: (val) {
                    setState(() {
                      filtroTipo = val;
                    });
                    allDocuments();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdownFiltro(
                  context,
                  label: "Dispositivo",
                  value: filtroDispositivo,
                  items: listDevices,
                  onChanged: (val) {
                    setState(() {
                      filtroDispositivo = val;
                    });
                    allDocuments();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// TABLE CARD
          Expanded(
            child: Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(24),
              color: cs.surface,
              child: Column(
                children: [

                  /// HEADER TABLE
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.06),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: _columnsTableDocuments(context),
                  ),

                  /// LIST
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      itemCount: listDocumets.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: cs.outlineVariant),
                      itemBuilder: (_, index) {
                        final doc = listDocumets[index];
                        return _rowDocument(context, doc, index, widget.onClose);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

Widget _columnsTableDocuments(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  TextStyle headerStyle = theme.textTheme.labelLarge!.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: .5,
    color: cs.primary,
  );

  return Row(
    children: [
      Expanded(child: Text('Numero', style: headerStyle)),
      Expanded(child: Text('Tipo', style: headerStyle)),
      Expanded(child: Text('Data/Ora', style: headerStyle)),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: Text('Totale', style: headerStyle),
        ),
      ),
    ],
  );
}


Widget _rowDocument(
    BuildContext context,
    Documento doc,
    int index,
    Function closeListDocuments,
    ) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  final bool even = index % 2 == 0;

  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(.45),
        builder: (_) => DocumentDetailModal(
          closeListDocuments: closeListDocuments,
          documento: doc,
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: even
            ? cs.surfaceContainerHighest.withOpacity(isDark ? .2 : .4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [

          Expanded(
            child: Column(
              children: [
                Text(
                      doc.overrideMovementType == 'simulation' ? 'Riscontro' : 
                      (doc.overrideMovementType == null || doc.overrideMovementType == 'cancel_rt')
                      ? '${doc.documentRtNumber ?? ''}/${doc.documentRtCloseNumber ?? ''}'
                      : doc.overrideMovementType == 'credit_note' ? '' : '',
                  style: theme.textTheme.bodyMedium,
                ),
                doc.deletedBy != null 
                ?
                Text(doc.deletedBy ?? '',
                  style: theme.textTheme.bodyMedium,
                )
                :
                Container()
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  doc.overrideMovementType ==  null ? 'RT' : 
                  doc.overrideMovementType == 'cancel_rt'   ? 'Annullo RT' : 
                  doc.overrideMovementType == 'simulation'  ? 'Riscontro' : 
                  doc.overrideMovementType == 'credit_note' ? 'Nota di credito' : 'Fattura'
                ),
                doc.deletedBy != null 
                ?
                Text('Annullato')
                :
                Container(),
              ],
            )),
            
          Expanded(
            child: Text(
              formattaDataISO(
                  doc.printedAt ?? DateTime.now().toIso8601String()),
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "€ ${doc.amount.toStringAsFixed(2)}",
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String formattaDataISO(String iso8601) {
  // Parse ISO8601 → DateTime
  final data = DateTime.parse(iso8601);
  
  // Formatta: "14/02/2026, 17:40"
  final formatter = DateFormat('dd/MM/yyyy, HH:mm');
  
  return formatter.format(data);
}



Widget _input(
    String label, {
      TextEditingController? controller,
      IconData? icon,
      bool readOnly = false,
      VoidCallback? onTap,
    }) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      return TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: cs.primary)
              : null,
          filled: true,
          fillColor: cs.surface,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: cs.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: cs.primary,
              width: 1.4,
            ),
          ),
        ),
      );
    },
  );
}



Widget _closeButton(BuildContext context, VoidCallback onClose) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onClose,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(.08)
            : Colors.black.withOpacity(.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.close_rounded,
        size: 20,
        color: theme.colorScheme.onSurface,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashboard/ui/screen/ordini/state/ordine_attivo_controller.dart';
import '../../models/ordine_tipo.dart';
import '../ordini_navigation.dart';
import '../widgets/ordine_footer_totale.dart';
import '../widgets/ordine_item_row.dart';



class OrdineEditorPage extends StatelessWidget {
  const OrdineEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdineAttivoController>();
    final ordine = controller.ordine;

    if (ordine == null) {
      return const Center(child: Text('Nessun ordine attivo'));
    }

    return WillPopScope(
      onWillPop: () => OrdiniNavigation.canPop(context, controller),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${ordine.tipo.label} – ${ordine.cliente}',
          ),
        ),
        body: ListView.builder(
          itemCount: ordine.articles.length,
          itemBuilder: (_, index) {
            return OrdineItemRow(
              item: ordine.articles[index],
              editable: true,
            );
          },
        ),
        bottomNavigationBar: OrdineFooterTotale(
          totale: 0,
          onSave: () {
            // TODO: salva ordine (API)
            controller.markSaved();
          },
        ),
      ),
    );
  }
}

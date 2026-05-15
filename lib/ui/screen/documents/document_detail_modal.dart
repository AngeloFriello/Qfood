import 'package:auto_route/auto_route.dart';
import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:dashboard/app/service/service_transaction.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/screen/scontrino/ControllerLookPosInPrint.dart';
import 'package:dashboard/ui/screen/scontrino/scontrino_service.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../modelli/document.dart';

class DocumentDetailModal extends StatelessWidget {
  final Documento documento;
  final Function closeListDocuments;
  const DocumentDetailModal({
    super.key,
    required this.documento,
    required this.closeListDocuments
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1024;
    final ctrLook  = context.watch<ControllerLookPosInPrinder>();

    return Center(
      child: AbsorbPointer(
        absorbing: ctrLook.inPrint,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 40 : 60,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: isMobile ? double.infinity : 700,
              color: cs.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
        
                  /// HEADER
                  _Header(documento: documento),
        
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
        
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: DateFormat('dd-MM-yyyy')
                                .format(DateTime.parse(documento.printedAt!)),
                            color: cs.primary,
                          ),
        
                          const SizedBox(height: 12),
        
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: DateFormat('HH:mm:ss')
                                .format(DateTime.parse(documento.printedAt!)),
                            color: cs.secondary,
                          ),
        
                          const SizedBox(height: 20),
        
                          _ActionButtons( doc: documento, closeListDocuments: closeListDocuments, ),
        
                          const SizedBox(height: 28),
        
                          _TotalsSection(documento: documento),
        
                          const SizedBox(height: 24),
        
                          _ProductsTable(documento: documento),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Documento documento;

  const _Header({required this.documento});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.primary.withOpacity(.85),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Dettaglio vendita",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// RIGA INFO ICONA + LABEL
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Documento doc;  
  final Function closeListDocuments;
  const _ActionButtons({
    required this.closeListDocuments,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
    return (doc.overrideMovementType == 'cancel_rt' || doc.deletedBy != null) ? Container() :  Row(
      children: [
       /*  ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.tertiaryContainer,
            foregroundColor: cs.onTertiaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {},
          child: const Text("Reso merce"),
        ), */
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () async {
            if( operatorLogged != null && operatorLogged!.cancelReceipt == 0 ){
              SnackBarForcedClosure('Operatore non abilitato', Colors.red);
              return;
            }

            final theme = Theme.of(context);
            final int? conferma = await showDialog<int>( // null annulla azione - 1 cancella scontrino - 2 cancella e riapri in carrello
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  return AlertDialog(
                    icon: Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                      size: 32,
                    ),
                    title: const Text("Attenzione"),
                    content: const Text(
                      "",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text("Annulla"),
                      ),
                     doc.overrideMovementType == 'simulation' ? Container() : FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, 1),
                        child: Text(  doc.overrideMovementType == null ? "Cancella scontrino" : 'Nota di credito'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, 2),
                        child: const Text("Cancella e apri conto"),
                      ),
                    ],
                  );
                },
              );
            
            if( conferma == null ) return;
              final ctrLook  = context.read<ControllerLookPosInPrinder>();
              
              ctrLook.setInPrint(true);

              //NOTA DI CREDITO
              if( doc.overrideMovementType == 'invoice' ) {
                await ScontrinoService.archiveCreditNoteLocalDb( doc );
                ctrLook.setInPrint(false);
                
                //CASO 2 riapro conto nel carrello
                if( conferma == 2 ){
                  final ctrCart = context.read<CarrelloController>();
                  //LOG RIELABORA
                  LogService.instance().saveLog('${doc.overrideMovementType ?? 'Scontrino'} n. ${doc.documentRtNumber ?? doc.assignedDocumentNumber}', 'Rielabora', '');

                  //REFRESH UUID E ROW GUID ARTICOLI
                  List<ProdottoCarrello> temp = [...doc.copyCart];
                  temp.forEach((p) => p.refreshGuid());
                  ctrCart.addArticlesFromOrderInEdit(temp);

                  ctrCart.setDiscountValue(doc.footDiscount != null ? doc.footDiscount! * -1 : 0);
                  ctrCart.discountType = doc.footDiscount != null ? ScontoTipo.importo : null;
                  //Carico il cliente se presente
                  final customerresp = await LocalDB.query('SELECT * FROM customers WHERE id = ${doc.idCustomer}');
                  if( customerresp.isNotEmpty ){
                    CustomerModel customer = CustomerModel.fromMap(customerresp[0]);
                    ctrCart.setCliente(customer);
                  }
                }
                closeListDocuments();
                Navigator.of(context).pop();
            }

            //ANNULLO Simulazione
            if( doc.overrideMovementType == 'simulation' ){
              //CASO 2 riapro conto nel carrello
                if( conferma == 2 ){
                  final ctrCart = context.read<CarrelloController>();
                  //LOG RIELABORA
                  LogService.instance().saveLog('${doc.overrideMovementType ?? 'Scontrino'} n. ${doc.documentRtNumber ?? doc.assignedDocumentNumber}', 'Rielabora', '');

                  //REFRESH UUID E ROW GUID ARTICOLI
                  List<ProdottoCarrello> temp = [...doc.copyCart];
                  temp.forEach((p) => p.refreshGuid());
                  ctrCart.addArticlesFromOrderInEdit(temp);

                  ctrCart.setDiscountValue(doc.footDiscount != null ? doc.footDiscount! * -1 : 0 );
                  ctrCart.discountType = doc.footDiscount != null ? ScontoTipo.importo : null;
                  //Carico il cliente se presente
                  final customerresp = await LocalDB.query('SELECT * FROM customers WHERE id = ${doc.idCustomer}');
                  if( customerresp.isNotEmpty ){
                    CustomerModel customer = CustomerModel.fromMap(customerresp[0]);
                    ctrCart.setCliente(customer);
                  }
                }
              ctrLook.setInPrint(false);
              closeListDocuments();
              Navigator.of(context).pop();
            }
            
            //ANNULLO SCONTRINO
            if( doc.overrideMovementType == null ){
              ServiceReceipt.instance().cancelReceipt(
                  doc, 
                  (String number, String close) async {
                    debugPrint('ANNULLO $number / $close');
                    await ScontrinoService.archiveCancelReceiptInLocalDb( doc, null, closureReceipt: close, receiptNumber: number);

                    //CASO 2 riapro conto nel carrello
                    if( conferma == 2 ){
                      final ctrCart = context.read<CarrelloController>();

                      //REFRESH UUID E ROW GUID ARTICOLI
                      List<ProdottoCarrello> temp = [...doc.copyCart];
                      temp.forEach((p) => p.refreshGuid());
                      ctrCart.addArticlesFromOrderInEdit(temp);

                      ctrCart.setDiscountValue(  doc.footDiscount != null ? doc.footDiscount! * -1 : 0 );
                      ctrCart.discountType = doc.footDiscount != null ? ScontoTipo.importo : null;
                      //Carico il cliente se presente
                      final customerresp = await LocalDB.query('SELECT * FROM customers WHERE id = ${doc.idCustomer}');
                      if( customerresp.isNotEmpty ){
                        CustomerModel customer = CustomerModel.fromMap(customerresp[0]);
                        ctrCart.setCliente(customer);
                      }
                    }
                    ctrLook.setInPrint(false);
                    closeListDocuments();
                    Navigator.of(context).pop();
                  }, 
                  (String cause){
                    ctrLook.setInPrint(false);
                    SnackBarForcedClosure('Errore annullo', theme.colorScheme.error);
                  }
                );
            }
            
            
          },
          child: const Text("Rielabora"),
        ),
      ],
    );
  }
}

/// ======================================================
/// TOTALI
/// ======================================================
class _TotalsSection extends StatelessWidget {
  final Documento documento;

  const _TotalsSection({required this.documento});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [

          _totRow("Imponibile", "${documento.amount} €"),
          _totRow("Tasse", "${documento.amountTax.toStringAsFixed(2)} €"),
          _totRow("Sconto", "${documento.footDiscount}"),
          const Divider(height: 24),
          _totRow(
            "Totale",
            "€ ${documento.amount.toStringAsFixed(2)}",
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _totRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// TABELLA PRODOTTI
class _ProductsTable extends StatelessWidget {
  final Documento documento;

  const _ProductsTable({required this.documento});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: const [
                Expanded(child: Text("Quantità")),
                Expanded(flex: 2, child: Text("Descrizione")),
                Expanded(child: Text("Totale t.i.")),
                Expanded(child: Text("IVA %")),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              height: 200,
              child: ListView.builder(
                itemCount: documento.copyCart.length,
                itemBuilder: (context, index) {

                  ProdottoCarrello p = documento.copyCart[index];

                  return Row(
                    children: [
                      Expanded(child: Text(p.quantity.toStringAsFixed(2))),
                      Expanded(flex: 2, child: Text(p.article.title)),
                      Expanded(child: Text(p.priceRowWithVariant.toStringAsFixed(2))),
                      Expanded(child: Text(p.taxRow.toStringAsFixed(2))),
                    ],
                  );
              },)
            )
          ),
        ],
      ),
    );
  }
}

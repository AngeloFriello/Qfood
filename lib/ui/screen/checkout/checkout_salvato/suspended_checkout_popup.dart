import 'package:dashboard/modelli/cartModelSaledSuspended.dart';
import 'package:flutter/material.dart';
import '../../../widget/header_footer/header_superiore.dart';
import 'checkout_dettaglio.dart';
import 'suspended_checkout_db.dart';



class SuspendedCheckoutPopup extends StatefulWidget {
  const SuspendedCheckoutPopup({super.key});
  
  @override
  State<SuspendedCheckoutPopup> createState() =>
      _SuspendedCheckoutPopupState();
}

class _SuspendedCheckoutPopupState extends State<SuspendedCheckoutPopup> {
  int? selectedCheckoutId;
  int? expandedCheckoutId;
  List<CartModelSaledSuspended> list = [];
    

    @override
    void initState() {
      loadSuspended();
      super.initState();
    }

    void loadSuspended() async {
      list = await SuspendedCheckoutDB.getAll();
      setState(() {
        
      });  
    }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 760,
        height: 520,
        child: Column(
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  BackButton(),
                  SizedBox(width: 8),
                  Text(
                    "Checkout salvati",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
               child: 
                  list.isEmpty
                  ?
                  const Center(
                    child: Text("Nessun checkout salvato"),
                  )
                  :
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      CartModelSaledSuspended checkout = list[i];
                      return Column(
                        children: [
                          CheckoutItem(
                            checkout: checkout,
                            selected: checkout.id == selectedCheckoutId,
                            expanded: checkout.id == expandedCheckoutId,
                            onTap: () {
                              setState(() {
                                selectedCheckoutId = checkout.id;
                                //  TOGGLE AUTOMATICO DETTAGLIO
                                expandedCheckoutId =
                                expandedCheckoutId == checkout.id ? null : checkout.id;
                              });
                            },

                            onExpand: () {
                              setState(() {
                                expandedCheckoutId =
                                expandedCheckoutId == checkout.id
                                    ? null
                                    : checkout.id;
                              });
                            },
                          ),
                          if (expandedCheckoutId == checkout.id) 
                            CheckoutDettaglio( 
                              loadSuspended: (){ loadSuspended(); }, 
                              checkout: checkout
                            ), 
                        ],
                      );
                    },
                  )
            )
          ],
        ),
      ),
    );
  }
}

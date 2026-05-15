import 'package:dashboard/ui/screen/checkout/controller_modulo_pagamenti.dart';
import 'package:dashboard/ui/widget/header_footer/ControllerListPriceSelected.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../state/controller_carrello.dart';
import '../../widget/carrello/carrello_widget.dart';
import 'checkout_salvato/suspended_checkout_popup.dart';

class CheckoutHeader extends StatelessWidget implements PreferredSizeWidget {

  const CheckoutHeader({
    super.key,
  });


  @override
  Size get preferredSize => const Size.fromHeight(58); // 🔥 Header più basso


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;



    return AppBar(
      backgroundColor: isLight ? const Color(0xFF97D700) : const Color(0xFF1A1A1A),
      elevation: 0,
      automaticallyImplyLeading: false, // gestiamo noi il back
      titleSpacing: 0,

      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // -------------------------------------------------------
            // BACK + LOGO + Checkout
            // -------------------------------------------------------
            Row(
              children: [
                // 🔙 Tasto Back
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () { 
                    //SVUOTO I PAGAMENTI ALL'USCITA DEL CHEKOUT
                    final controllerCarrello  = context.read<CarrelloController>();
                    final ctrlModuloPagamenti = context.read<ControllerModuloPagamenti>();
                    ctrlModuloPagamenti.resetPaymentSelectedInCheckout();
                    controllerCarrello.setPayments([]);
                    if( controllerCarrello.orderinEdit != null ){
                      controllerCarrello.clearCart();
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 22, color: Colors.white),
                  ),
                ),

                const SizedBox(width: 12),

                // Logo
                Image.asset(
                  isLight ? 'assets/logosuverde.png' : 'assets/logodark.png',
                  height: 40,
                ),

                const SizedBox(width: 10),

                // Titolo
                const Text(
                  "Checkout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // -------------------------------------------------------
            // Pulsanti pill a destra
            // -------------------------------------------------------
            Expanded(
              child: Align(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),

                      
                      
                      _pillButton(
                        context: context,
                        icon: LucideIcons.eye,
                        label: "Guarda",
                        onTap: () async {
                          final carrello = context.read<CarrelloController>();
                          final ok = await carrello.caricaUltimoCheckout();
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Nessun checkout trovato")),
                            );
                            return;
                          }
                  
                          await mostraCheckoutModale(context);
                        },
                      ),
                  
                      const SizedBox(width: 8),
                  
                      _pillButton(
                        context: context,
                        icon: LucideIcons.shoppingCart,
                        label: "Salvati",
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (_) => const SuspendedCheckoutPopup(),
                          );
                        },
                      ),
                  
                      const SizedBox(width: 8),
                  
                      _pillButton(
                        context: context,
                        icon: LucideIcons.trash2,
                        label: "Elimina",
                        onTap: () => _confermaEliminaCheckout(context),
                      ),
                  
                      const SizedBox(width: 8),
                  
                      _pillButton(
                        context: context,
                        icon: LucideIcons.receipt,
                        label: "Gestisci stampa comande",
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _confermaEliminaCheckout(BuildContext context) async {
    final theme = Theme.of(context);
    final carrello = context.read<CarrelloController>();

    // =========================
    // DIALOG DI CONFERMA
    // =========================
    final bool? conferma = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          title: const Text("Attenzione"),
          content: const Text(
            "Sei sicuro di voler eliminare il checkout attuale?\n"
                "Questa operazione non può essere annullata.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annulla"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    // =========================
    // ELIMINAZIONE CHECKOUT
    // =========================
    carrello.clearCart();

    // =========================
    // FEEDBACK VISIVO
    // =========================
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        content: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Checkout cancellato",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  Future<void> mostraCheckoutModale(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = context.read<ControllerListPriceSelected>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45), // 🔥 overlay elegante
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 1200 ? 1000 : 900,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Material(
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                color: isDark
                    ? const Color(0xFF141414)
                    : const Color(0xFFF6F6EC),
                child: Column(
                  children: [
                    // ===========================
                    // 🔝 HEADER MODALE PREMIUM
                    // ===========================
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF0F0E0),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 26,
                          ),
                          const SizedBox(width: 12),

                          const Text(
                            "Carrello",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Spacer(),

                          IconButton(
                            icon: const Icon(Icons.close, size: 22),
                            onPressed: () {
                              //  ripristina stato
                              context.read<CarrelloController>().readonly = false;
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // ===========================
                    // 🧾 CONTENUTO CARRELLO
                    // ===========================
                  /*   Expanded(
                      child: Stack(
                        children: [
                          AbsorbPointer(
                            absorbing: true,
                            child: CarrelloWidget(onEditCliente: () {  }, listPrice: controller.listPriceSelected,),
                          ),
                          Positioned.fill(
                            child: Container(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ), */
                    Text('jkjbnjbidddddddddddddddddddddddddddddddddddddddddddddddddddddhb'),

                    // ===========================
                    // 💰 FOOTER TOTALE
                    // ===========================
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF0F0E0),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      child: Consumer<CarrelloController>(
                        builder: (_, carrello, __) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "TOTALE",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                "${carrello.totaleCarrello.toStringAsFixed(2)} €",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),


                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }




  Widget _pillButton({
    required IconData icon,
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white
              : Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(14),
          border: isLight
              ? Border.all(color: Colors.grey.shade300)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isLight ? Colors.black87 : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLight ? Colors.black87 : Colors.white, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}

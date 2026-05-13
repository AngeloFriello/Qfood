import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../state/controller_carrello.dart';
import 'cliente/InserisciClienteVista.dart';

class ModuloCliente extends StatefulWidget {
  const ModuloCliente({super.key});

  @override
  State<ModuloCliente> createState() => _ModuloClienteState();
}

class _ModuloClienteState extends State<ModuloCliente> {


  final FocusNode pastiFocus = FocusNode();

  bool dividiPerAbilitato = false;
  final TextEditingController dividiPerCtrl = TextEditingController();
  final TextEditingController noteComandaCtrl = TextEditingController();

  //fidelity card
  final TextEditingController fidelityCtrl = TextEditingController();
  final FocusNode fidelityFocus = FocusNode();

  //pager per asporto
  final TextEditingController pagerCtrl = TextEditingController();

  //pasto completo
  bool pastoCompleto = false;
  final TextEditingController pastiCompletiCtrl =
  TextEditingController(text: "1");


  @override
  void initState() {
    super.initState();

    // PASTO COMPLETO DEFAULT
    pastoCompleto = false;
    pastiCompletiCtrl.clear();
  }


  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void apriPopupCliente() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: 820,
            height: 920,
            child: InserisciClienteSheet(
              onSelect: (cliente) {
                context.read<CarrelloController>().setCliente(cliente);
                Navigator.pop(ctx);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder:(context, constraints) {
      final width = constraints.maxWidth;
      final isMobile = width < 800;
      final isTablet = width >= 800 && width < 1200;
      final isDesktop = width >= 1200;
      final double titleSize = isDesktop ? 20 : isTablet ? 17 : 15;
      final double bodySize = isDesktop ? 15 : isTablet ? 14 : 13;
      final double padding = isDesktop ? 18 : isTablet ? 14 : 10;
      final double iconSize = isDesktop ? 22 : isTablet ? 20 : 18;
      final isTabletLandscape = isTablet && MediaQuery.of(context).orientation == Orientation.landscape;
      final theme = Theme.of(context);

      //GESTIRE IL CLIENTE
    final carrello = context.watch<CarrelloController>();
    final clienteSelezionato = carrello.cliente;
    TextEditingController ctrlNoteDocument = TextEditingController( text: carrello.note );
    // -------------------------------------------------------------
    // HEADER BLOCCO
    // -------------------------------------------------------------
    Widget blocco(
        String titolo,
        IconData icona,
        Widget contenuto
      ) {

      return Container(

        decoration:  BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(.28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [


            if (titolo.isNotEmpty) SizedBox(height: isTabletLandscape ? 6 : 6),
            contenuto,
          ],
        ),
      );
    }


    // -------------------------------------------------------------
    // CARD CLIENTE (CENTRALE)
    // -------------------------------------------------------------
    Widget cardCliente() {
      if (clienteSelezionato == null) {
        return Container(
          height: isTablet ? 30 : 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Text(
            "Nessun cliente selezionato",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        );
      }

      final c = clienteSelezionato;
      final isCompany = c.businessType == "company";

      return Container(
        padding: EdgeInsets.all(isTablet ? 12 : 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // TIPO CLIENTE
            // =========================
            Row(
              children: [
                Icon(
                  isCompany ? LucideIcons.building2 : LucideIcons.user,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isCompany ? "Azienda" : "Privato",
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // =========================
            // NOME
            // =========================
            Text(
              ((isCompany ? c.businessName : c.title) ?? "").toUpperCase(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            // =========================
            // CODICE CLIENTE
            // =========================
            Text(
              "Codice: ${c.code ?? "-"}",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),

            const SizedBox(height: 10),

            // =========================
            // DATI AGGIUNTIVI
            // =========================
// DATI AGGIUNTIVI
// =========================

// --- AZIENDA ---
            if (isCompany) ...[
              if (c.businessVatNumber != null && c.businessVatNumber!.isNotEmpty)
                _infoRow(context, "P. IVA", c.businessVatNumber!),

              if (c.businessAddress != null && c.businessCity != null)
                _infoRow(
                  context,
                  "Indirizzo",
                  "${c.businessAddress}"
                      "${c.businessZipCode != null ? ', ${c.businessZipCode}' : ''}"
                      " ${c.businessCity}",
                ),

              if (c.businessPhone != null && c.businessPhone!.isNotEmpty)
                _infoRow(context, "Telefono", c.businessPhone!),

              if (c.businessEmail != null && c.businessEmail!.isNotEmpty)
                _infoRow(context, "Email", c.businessEmail!),
            ]

// --- PRIVATO ---
            else ...[
              if (c.personalFiscalCode != null && c.personalFiscalCode!.isNotEmpty)
                _infoRow(context, "Cod. Fiscale", c.personalFiscalCode!),

              if (c.personalAddress != null && c.personalCity != null)
                _infoRow(
                  context,
                  "Indirizzo",
                  "${c.personalAddress}"
                      "${c.personalZipCode != null ? ', ${c.personalZipCode}' : ''}"
                      " ${c.personalCity}",
                ),

              if (c.personalPhone != null && c.personalPhone!.isNotEmpty)
                _infoRow(context, "Telefono", c.personalPhone!),

              if (c.personalEmail != null && c.personalEmail!.isNotEmpty)
                _infoRow(context, "Email", c.personalEmail!),
            ],

          ],
        ),
      );
    }



    // -------------------------------------------------------------
    // BLOCCO CLIENTE (CENTRALE + ICONA DESTRA)
    // -------------------------------------------------------------
    Widget bloccoCliente() {
      final bool hasCliente = clienteSelezionato != null;
      

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cardCliente()),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              if (clienteSelezionato != null) {
                context.read<CarrelloController>().clearCliente();
              } else {
               apriPopupCliente();
              }
            },

            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasCliente ? Colors.red : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasCliente ? LucideIcons.trash2 : LucideIcons.search,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      );
    }


    // -------------------------------------------------------------
    // UI
    // -------------------------------------------------------------
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  CLIENTE
          blocco(
            "Cliente",
            LucideIcons.personStanding,
            bloccoCliente(),
          ),

          const SizedBox(height: 7),

          //  FIDELITY
          blocco(
            "",
            LucideIcons.scan,
            Row(
              children: [
                /// CAMPO FIDELITY
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: fidelityCtrl,
                      focusNode: fidelityFocus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,

                      onChanged: (_) => setState(() {}),

                      onSubmitted: (value) {
                        debugPrint("FIDELITY LETTO: $value");
                      },

                      style: const TextStyle(fontSize: 14),

                      decoration: InputDecoration(
                        hintText: "Codice Fidelity",

                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),

                        filled: true,
                        fillColor: theme.colorScheme.surface,

                        prefixIcon: const Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                        ),

                        suffixIcon: fidelityCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            fidelityCtrl.clear();
                            fidelityFocus.requestFocus();
                            setState(() {});
                          },
                        )
                            : null,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                SizedBox(
                  height: 44,
                  width: 44,
                  child: Material(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        debugPrint("APRI RICERCA FIDELITY");
                      },
                      child: const Center(
                        child: Icon(
                          Icons.search,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 2),

        //  NOTE DOCUMENTO
        blocco(
          "Note documento",
          LucideIcons.stickyNote,
            SizedBox(
              height: 44,
              child: TextField(
                controller: ctrlNoteDocument,
                maxLines: 1,
                onChanged: (value) => carrello.setNote(value),
                style: const TextStyle(fontSize: 14),

                decoration: InputDecoration(
                  hintText: "Inserisci note…",

                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 12,
                  ),

                  filled: true,
                  fillColor: theme.colorScheme.surface,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
        ),


          const SizedBox(height: 2),

          blocco(
            "Pager / Asporto",
            LucideIcons.bell,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: TextField(
                    controller: pagerCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,

                    onChanged: (_) => setState(() {}),

                    onSubmitted: (value) {
                      debugPrint("PAGER ASSEGNATO: $value");
                    },

                    style: const TextStyle(fontSize: 14),

                    decoration: InputDecoration(
                      labelText: "Numero Pager",
                      hintText: "Inserisci numero dischetto",

                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),

                      filled: true,
                      fillColor: theme.colorScheme.surface,

                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 18,
                      ),

                      suffixIcon: pagerCtrl.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          pagerCtrl.clear();
                          setState(() {});
                        },
                      )
                          : null,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )



              ],
            ),
          ),

          const SizedBox(height: 6),

          // pasto completo
          blocco(
            "Pasto Completo",
            LucideIcons.utensils,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Abilita pasto completo"),
                    Switch(
                      value: pastoCompleto,
                      onChanged: (v) {
                        setState(() {
                          pastoCompleto = v;

                          if (v) {
                            pastiCompletiCtrl.text = "1";
                          } else {
                            pastiCompletiCtrl.clear();
                          }
                        });

                        if (v) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;

                            FocusScope.of(context).requestFocus(pastiFocus);

                            pastiCompletiCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: pastiCompletiCtrl.text.length,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 45,
                  child: TextField(
                    focusNode: pastiFocus,
                    controller: pastiCompletiCtrl,
                    enabled: pastoCompleto, // attivo solo se switch ON
                    keyboardType: TextInputType.number,

                    style: TextStyle(
                      color: pastoCompleto ? Colors.black : Colors.grey,
                    ),

                    decoration: InputDecoration(

                      labelStyle: TextStyle(
                        color: pastoCompleto
                            ? Colors.black87
                            : Colors.grey,
                      ),

                      floatingLabelStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),

                      filled: true,
                      fillColor: pastoCompleto
                          ? Colors.white
                          : Theme.of(context).colorScheme.surfaceContainerHighest,

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),],),);},);
  }
}



import 'dart:async';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/ui/screen/checkout/cliente/CustomerApi.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'nuovo_cliente.dart';

class InserisciClienteSheet extends StatefulWidget {
  final Function(CustomerModel cliente) onSelect;

  const InserisciClienteSheet({super.key, required this.onSelect});

  @override
  State<InserisciClienteSheet> createState() => _InserisciClienteSheetState();
}

class _InserisciClienteSheetState extends State<InserisciClienteSheet> {
  List<CustomerModel> allClienti = [];
  List<CustomerModel> clienti = [];
  int skip = 0;
  final int take = 100;
  int total = 0;
  bool loading = false;
  Timer? _debounce;
  String searchText = "";

  @override
  void initState() {
    super.initState();
    _loadClienti();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadClienti({bool reset = false}) async {
    if (loading) return;
    try{
      setState(() => loading = true);
      List<CustomerModel> temp = await CustomerModel.getCustomers();
      allClienti = temp;
      clienti = temp;
    }catch( err ){

    }finally{
      setState(() => loading = false);
    }

/*     if (reset) {
      skip = 0;
      allClienti.clear();
      clienti.clear();
    } */

  }

  void _onSearchChanged(String value) {
    searchText = value.trim();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _applyLocalFilter);
  }

  void _applyLocalFilter() {
    final q = searchText.toLowerCase();

    setState(() {
      if (q.isEmpty) {
        clienti = List.from(allClienti);
        return;
      }

      clienti = allClienti.where((c) {
        final title = (c.title ?? "").toLowerCase();
        final code = (c.code ?? "").toLowerCase();

        // telefono (azienda o privato)
        final telefono = (
            (c.businessPhone ?? "") +
                (c.personalPhone ?? "")
        ).toLowerCase();

        // P.IVA (solo azienda)
        final piva = (c.businessVatNumber ?? "").toLowerCase();

        return title.contains(q) ||
            code.contains(q) ||
            telefono.contains(q) ||
            piva.contains(q);
      }).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(
        children: [
          // ================= HEADER =================
          Container(
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF8BC540),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Inserisci cliente",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // AGGIUNGI CLIENTE
                Positioned(
                  top: 8,
                  right: 12,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                     bool? resp  = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NuovoClientePage(),
                        ),
                      );
                      _loadClienti();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= CONTENUTO =================
          Expanded(
            child: Column(
              children: [
                // SEARCH
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Cerca",
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                // LISTA CLIENTI
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: clienti.length,
                    itemBuilder: (_, i) => _cardCliente(clienti[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // CARD CLIENTE MODALE CLIENTE
  // =======================================================
  Widget _cardCliente(CustomerModel c) {
    final theme = Theme.of(context);

    final nome = (c.title ?? "-").toUpperCase();
    final codice = c.code ?? "-";




    final isCompany = c.businessType == "company";

// =========================
// DATI AZIENDA
// =========================
    final pIva = isCompany ? (c.businessVatNumber ?? "") : "";
    final telefonoAzienda = isCompany ? (c.businessPhone ?? "") : "";
    final emailAzienda = isCompany ? (c.businessEmail ?? "") : "";
    final indirizzoAzienda = isCompany ? (c.businessAddress ?? "") : "";
    final capAzienda = isCompany ? (c.businessZipCode ?? "") : "";
    final cittaAzienda = isCompany ? (c.businessCity ?? "") : "";

// =========================
// DATI PRIVATO
// =========================
    final telefonoPrivato = !isCompany ? (c.personalPhone ?? "") : "";
    final emailPrivato = !isCompany ? (c.personalEmail ?? "") : "";
    final indirizzoPrivato = !isCompany ? (c.personalAddress ?? "") : "";
    final capPrivato = !isCompany ? (c.personalZipCode ?? "") : "";
    final cittaPrivato = !isCompany ? (c.personalCity ?? "") : "";



    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.35 : 0.15,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= SINISTRA =================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    color: Color(0xFF8BC540),
                  ),
                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TIPO
                      Row(
                        children: [
                          Icon(
                            isCompany
                                ? LucideIcons.building2
                                : LucideIcons.user,
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

                      const SizedBox(height: 6),

                      // NOME
                      Text(
                        nome,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // CODICE
                      Text(
                        "Codice: $codice",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // ================= DESTRA =================
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== AZIENDA =====
                  if (isCompany && pIva.isNotEmpty)
                    Text("P. IVA: $pIva"),

                  if (isCompany && indirizzoAzienda.isNotEmpty)
                    Text(indirizzoAzienda),

                  if (isCompany && (capAzienda.isNotEmpty || cittaAzienda.isNotEmpty))
                    Text("$capAzienda $cittaAzienda"),

                  if (isCompany && telefonoAzienda.isNotEmpty)
                    Text("Tel: $telefonoAzienda"),

                  if (isCompany && emailAzienda.isNotEmpty)
                    Text(emailAzienda),

                  // ===== PRIVATO =====
                  if (!isCompany && telefonoPrivato.isNotEmpty)
                    Text("Tel: $telefonoPrivato"),

                  if (!isCompany && emailPrivato.isNotEmpty)
                    Text(emailPrivato),
                ],
              ),


            ],
          ),

          const SizedBox(height: 14),

          // ================= BOTTONI =================
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () async {
                  if (c.id == null) {
                    debugPrint("❌ ID cliente nullo");
                    return;
                  }

                  debugPrint("🔍 Recupero dettagli cliente ID = ${c.id}");

                  final idCustomer = c.id;

                  if (idCustomer == null) {
                    debugPrint("❌ ID cliente non valido: ${c.id}");
                    return;
                  }

                  final dettaglio = await CustomerApi.getCustomerById(
                    idCustomer: idCustomer,
                  );


                  if (!context.mounted || dettaglio == null) {
                    debugPrint("❌ Dettaglio cliente non trovato");
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NuovoClientePage(
                        cliente: c,
                        dettaglio: dettaglio,
                      ),
                    ),
                  );
                },
                child: const Text("Dettagli"),
              ),



              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => widget.onSelect(c),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC540),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    "Inserisci",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

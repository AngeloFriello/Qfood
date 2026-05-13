
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/customer.dart';
import 'package:dashboard/ui/screen/checkout/cliente/tab/tab_azienda.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/sync_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:dashboard/ui/screen/checkout/cliente/tab/tab_altro.dart';
import 'package:dashboard/ui/screen/checkout/cliente/tab/tab_fattura_differita.dart';
import 'package:dashboard/ui/screen/checkout/cliente/tab/tab_fidelity.dart';
import 'package:dashboard/ui/screen/checkout/cliente/tab/tab_fidelity_avanzata.dart';
import 'package:dashboard/ui/screen/checkout/cliente/tab/tab_privato.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/customer_api.dart';
import '../../../../api/helper_api.dart';
import 'CustomerDetailModel.dart';

class NuovoClientePage extends StatefulWidget {
  final CustomerModel? cliente;
  final CustomerDetailModel? dettaglio;

  const NuovoClientePage({
    super.key,
    this.cliente,
    this.dettaglio,
  });

  bool get isEdit => cliente != null;

  @override
  State<NuovoClientePage> createState() => _NuovoClientePageState();
}

class _NuovoClientePageState extends State<NuovoClientePage> {
  int tabIndex = 0;

  // =========================
  // CONTROLLERS AZIENDA
  // =========================
  final TextEditingController ragioneSocialeController = TextEditingController();
  final TextEditingController vatController = TextEditingController();
  final TextEditingController codiceFiscaleController = TextEditingController();
  final TextEditingController indirizzoController = TextEditingController();
  final TextEditingController capController = TextEditingController();
  final TextEditingController cittaController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController scontoController = TextEditingController();
  final TextEditingController provinciaController = TextEditingController();
  final TextEditingController statoController = TextEditingController();

  // =========================
  // CONTROLLERS PRIVATO
  // =========================
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cognomeController = TextEditingController();
  final TextEditingController dataNascitaController = TextEditingController();


  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _loadCustomerDetail(); // ✅ UNICA FONTE VERITÀ
    }
  }



  Future<void> _onSearchVat() async {
    final vat = vatController.text.trim();

    if (vat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inserisci una Partita IVA")),
      );
      return;
    }

    final data = await HelperApi.isValidVatNumber(
      vatNumber: vat,
      useVies: true,
      useCerved: false,
    );


    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("P.IVA non trovata")),
      );
      return;
    }

    // AUTOCOMPILA AZIENDA
    ragioneSocialeController.text = data["businessName"] ?? ragioneSocialeController.text;

    indirizzoController.text = data["address"] ?? "";
    capController.text = data["zipCode"] ?? "";
    cittaController.text = data["city"] ?? "";
    provinciaController.text = data["province"] ?? "";
    statoController.text = data["country"] ?? "IT";

    telefonoController.text = data["phone"] ?? "";
    emailController.text = data["email"] ?? "";
  }


  Future<void> _loadCustomerDetail() async {
    if (widget.cliente == null) return;

    final id = widget.cliente!.id ;
    if (id == null) return;

    final detail = await CustomerApi.getCustomerById(
      idCustomer: id,
    );

    if (detail == null) return;

    final isAzienda = widget.cliente!.businessType == "company";

    // 🔥 TAB CORRETTO
    tabIndex = isAzienda ? 0 : 1;

    // 🔥 POPOLA I CAMPI
    _populateFromDetail(widget.cliente!, detail);

    setState(() {}); // OBBLIGATORIO
  }



  void _populateFromDetail(
      CustomerModel cliente,
      CustomerDetailModel d,
      ) {
    final isCompany = cliente.businessType == "company";

    // =========================
    // PRIVATO
    // =========================
    if (!isCompany) {
      nomeController.text = d.personalFirstName ?? "";
      cognomeController.text = d.personalLastName ?? "";
    //  dataNascitaController.text = d.personalBirthDate ?? "";
      codiceFiscaleController.text = d.personalFiscalCode ?? "";

      indirizzoController.text = d.personalAddress ?? "";
      capController.text = d.personalZipCode ?? "";
      cittaController.text = d.personalCity ?? "";
    //  provinciaController.text = d.personalProvince ?? "";
     // statoController.text = d.personalCountry ?? "";

      telefonoController.text = d.personalPhone ?? "";
      emailController.text = d.personalEmail ?? "";
    }

    // =========================
    // AZIENDA
    // =========================
    if (isCompany) {
      ragioneSocialeController.text = d.businessName ?? "";
      vatController.text = d.businessVatNumber ?? "";
      codiceFiscaleController.text = d.businessFiscalCode ?? "";

      indirizzoController.text = d.businessAddress ?? "";
      capController.text = d.businessZipCode ?? "";
      cittaController.text = d.businessCity ?? "";
   //   provinciaController.text = d.businessProvince ?? "";
   //   statoController.text = d.businessCountry ?? "";

      telefonoController.text = d.businessPhone ?? "";
      emailController.text = d.businessEmail ?? "";
    }
  }


  final tabs = const [
    "Azienda",
    "Privato",
    "Fidelity",
    "Fidelity avanzata",
    "Altro",
    "Fattura differita",
  ];




  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      appBar: AppBar(
        backgroundColor: const Color(0xFF8BC540),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
              await SyncCatalogo.syncCustomer(null);
              Navigator.pop(context);},
        ),
        title: Text(
          widget.isEdit ? "Modifica cliente" : "Nuovo cliente",
          style: const TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          _tabsSelector(),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFF8BC540),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: FilledButton(
              onPressed: _onSalva,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 94, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Salva",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // TABS
  // =========================
  Widget _tabsSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = tabIndex == i;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tabs[i]),
              selected: selected,
              onSelected: (_) => setState(() => tabIndex = i),
              selectedColor: const Color(0xFF8BC540),
              backgroundColor: Colors.grey.shade800,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ),
    );
  }

  // =========================
  // CONTENUTO TAB
  // =========================
  Widget _buildTabContent() {
    switch (tabIndex) {
      case 0:
        return  TabAzienda(
          provinciaController: provinciaController,
          ragioneSocialeController: ragioneSocialeController,
          vatController: vatController,
          codiceFiscaleController: codiceFiscaleController,
          indirizzoController: indirizzoController,
          capController: capController,
          cittaController: cittaController,
          telefonoController: telefonoController,
          emailController: emailController,
          scontoController: scontoController,
          onSearchVat: _onSearchVat,
        );



      case 1:
        return TabPrivato(
          nomeController: nomeController,
          cognomeController: cognomeController,
          dataNascitaController: dataNascitaController,
          codiceFiscaleController: codiceFiscaleController,
          indirizzoController: indirizzoController,
          capController: capController,
          cittaController: cittaController,
          telefonoController: telefonoController,
          emailController: emailController,
          provinciaController: provinciaController,
          statoController: statoController,
        );
      case 2:
        return const TabFidelity();
      case 3:
        return const TabFidelityAvanzata();
      case 4:
        return const TabAltro();
      case 5:
        return const TabFatturaDifferita();
      default:
        return const SizedBox();
    }
  }

  // =========================
  // SALVA (CREATE – UPDATE FUTURO)
  // =========================
  Future<void> _onSalva() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? istanza    = pref.getString('istanza');
    String? token = pref.getString("token");
    if( token == null || istanza == null ){
      debugPrint('manca');
      return;
    }

    final bool isAzienda = ragioneSocialeController.text.trim().isNotEmpty;

    final String titoloCliente = isAzienda
        ? ragioneSocialeController.text.trim()
        : "${nomeController.text.trim()} ${cognomeController.text.trim()}";

    final int discount = int.tryParse(scontoController.text.trim()) ?? 0;

    final customerId = await CustomerApi.createCustomer(
      title: titoloCliente,
      businessType: isAzienda ? "company" : "physical_person",
      discountPercentage: discount,
      token: token,
      istanza: istanza
    );

    if (customerId == null) return;

    final Map<String, dynamic> detailPayload = isAzienda
        ? {
            "businessName": ragioneSocialeController.text.trim(),
            "businessVatNumber": vatController.text.trim(),
            "businessFiscalCode": codiceFiscaleController.text.trim(),
            "businessAddress": indirizzoController.text.trim(),
            "businessCity": cittaController.text.trim(),
            "businessZipCode": capController.text.trim(),
            "businessCountry": "IT",
            "businessPhone": telefonoController.text.trim(),
            "businessEmail": emailController.text.trim(),
            "businessSplitPayment": 0,
            "businessGetPurchaseOrderDate": 0,
          }
        : {
          "personalFirstName": nomeController.text.trim(),
          "personalLastName": cognomeController.text.trim(),
          "personalFiscalCode": codiceFiscaleController.text.trim(),
          "personalAddress": indirizzoController.text.trim(),
          "personalCity": cittaController.text.trim(),
          "personalZipCode": capController.text.trim(),
          "personalCountry": "IT",
          "personalProvince": provinciaController.text.trim(),
          "personalPhone": telefonoController.text.trim(),
          "personalEmail": emailController.text.trim(),
          "businessSplitPayment": 0,
          "businessGetPurchaseOrderDate": 0,
        };

    //CONTROLLO CAMPI PERSONA FISICA
    if( !isAzienda ){
      if(  detailPayload['personalFirstName'].length  > 60 
          || detailPayload['personalLastName'].length   > 60
          || detailPayload['personalFiscalCode'].length > 16
          || detailPayload['personalAddress'].length    > 60
          || detailPayload['personalCity'].length       > 60
          || detailPayload['personalZipCode'].length    != 5
          || detailPayload['personalProvince'].length   != 2
          || detailPayload['personalCountry'].length    != 2
        ){
          SnackBarForcedClosure('Compilare correttamente i campi', Colors.red);
          return;
        } 
    }else{
      //CONTROLLO CAMPI Azienda
      if(    detailPayload['businessName'].length                  > 60 
          || detailPayload['businessVatNumber'].length             > 60
          || detailPayload['businessFiscalCode'].length            > 16
          || detailPayload['businessAddress'].length               > 60
          || detailPayload['businessCity'].length                  > 60
          || detailPayload['businessZipCode'].length               != 5
          || detailPayload['businessPhone'].length                 > 12
          || ![0,1].contains( detailPayload['businessSplitPayment']  )                
          || detailPayload['businessEmail'].length                 > 60
          //|| detailPayload['businessGetPurchaseOrderDate'].length  > 1

      ){
        SnackBarForcedClosure('Compilare correttamente i campi', Colors.red);
        return;
      } 
    }
    

    

   bool respDetails =  await CustomerApi.createCustomerDetail(
      idCustomer: customerId,
      detail: detailPayload,
      token: token,
      istanza: istanza
    );

    if( !respDetails ) return;
    await SyncCatalogo.syncCustomer(null);
    Navigator.pop(context, true);
  }
}

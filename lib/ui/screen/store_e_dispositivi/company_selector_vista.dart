import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:dashboard/ui/screen/login/login_screen.dart';
import 'package:dashboard/ui/screen/store_e_dispositivi/store_selector_vista.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/costanti.dart';

@RoutePage()
class CompanySelectorVista extends StatefulWidget {
  const CompanySelectorVista({super.key});

  @override
  State<CompanySelectorVista> createState() => _CompanySelectorVistaState();
}

class _CompanySelectorVistaState extends State<CompanySelectorVista> {
  List<Map<String, dynamic>> companies = [];
  bool loading = true;
  String? errore;

  @override
  void initState() {
    super.initState();
    _caricaAziende();
  }

  Future<void> _caricaAziende() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final istanza = prefs.getString("istanza");

      if (token == null || istanza == null) {
        setState(() {
          errore = "Token o istanza mancanti — rifai login.";
          loading = false;
        });
        return;
      }

      final url = "https://$istanza-api.qfood.it/api/v1/company/listCompanies/efc2e23e1ae6?skip=0&take=100";
      debugPrint("🔹 Richiesta aziende → $url");

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "x-api-key": defaultApiKey,
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json["success"] == true && json["data"] != null) {
          final data = json["data"];
          List<Map<String, dynamic>> list = [];

          if (data is Map && data["records"] != null) {
            list = List<Map<String, dynamic>>.from(data["records"]);
          } else if (data is List) {
            list = List<Map<String, dynamic>>.from(data);
          }

          setState(() {
            companies = list;
            loading = false;
          });
        } else {
          setState(() {
            errore  = "Nessuna azienda trovata.";
            loading = false;
          });
        }
      } else {
        setState(() {
          errore  = "❌ Errore HTTP ${res.statusCode}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errore = "❌ Errore durante la richiesta: $e";
        loading = false;
      });
    }
  }

  Future<void> _selezionaAzienda(Map<String, dynamic> azienda) async {
    final prefs = await SharedPreferences.getInstance();

    final int idCompany = azienda["id"] ?? 0;
    final String nomeCompany = azienda["title"] ?? "Senza nome";

    // Salva tutti i dati azienda selezionata
    await prefs.setString('company', jsonEncode(azienda));

    //Salvati da marco verificare se sono utilizzati altrove
    await prefs.setInt("idCompany", idCompany);
    await prefs.setString("nomeCompany", nomeCompany);
    await prefs.setBool("companySelected", true);

    debugPrint("🏢 Azienda selezionata: $nomeCompany (ID: $idCompany)");
    debugPrint("🔐 companySelected = TRUE");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StoreSelectorVista(
          idAzienda: idCompany,
          nomeAzienda: nomeCompany,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF181818) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BC540), // 💚 verde Flexboard CMYK C50 M0 Y100 K0
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  final curve = Curves.easeInOutCubic;
                  final tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(position: animation.drive(tween), child: child);
                },
              ),
            ); 
          },
        ),
        title: const Text(
          "Seleziona Azienda",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/logosuverde.png' // 🌙 dark mode
                  : 'assets/logosuverde.png', // ☀️ light mode
              height: 58,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errore != null
          ? Center(
        child: Text(
          errore!,
          style: TextStyle(
            color: dark ? Colors.red[300] : Colors.red[800],
            fontSize: 16,
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 3;
            if (constraints.maxWidth < 900) crossAxisCount = 2;
            if (constraints.maxWidth < 600) crossAxisCount = 1;

            return GridView.builder(
              itemCount: companies.length,
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, i) {
                final c = companies[i];
                return _CompanyCard(
                  nome:  c["title"] ?? "Senza nome",
                  email: c["email"] ?? "info@azienda.it",
                  id:    c["id"]?.toString() ?? "-",
                  onTap: () => _selezionaAzienda(c),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final String nome;
  final String email;
  final String id;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.nome,
    required this.email,
    required this.id,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        color: dark ? const Color(0xFF262626) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icona/avatar
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: dark
                        ? Colors.tealAccent.withOpacity(.2)
                        : Colors.teal.shade50,
                    radius: 22,
                    child: Icon(
                      Icons.business_rounded,
                      color: dark ? Colors.tealAccent : Colors.teal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: dark ? Colors.white54 : Colors.black45,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                nome,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 13,
                  color: dark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Divider(color: dark ? Colors.white10 : Colors.grey[200]),
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "ID: $id",
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? Colors.white70 : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


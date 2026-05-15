import 'dart:async';
import 'dart:convert';
import 'package:dashboard/Global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/api_client.dart';
import '../../../config/costanti.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  List<DropdownMenuItem> instanceOptions = [];
  String? _selectedInstance;

  bool mostraPassword = false;
  bool caricamento = false;
  String errore = "";

  final Color verdeFlex = const Color(0xFF95C01F);

  @override
  void initState() {
    super.initState();
    _getInstance();
  }

  Future<void> _getInstance() async {
    try {
      setState(() => caricamento = true);
      final url = "https://instance1-api.qfood.it/api/v1/helper/listBackends/3c98923b8631";

      http.Response respInstance = await http.get(
        Uri.parse(url),
      );

      if (respInstance.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(respInstance.body);
        List<dynamic> clusters = (body['data']['records'] as List<dynamic>);

        List<DropdownMenuItem> instanceOptionsTemp = clusters
            .map((cluster) => DropdownMenuItem(
                value: cluster['instance'], child: Text(cluster['instance'])))
            .toList();
        setState(() {
          instanceOptions = instanceOptionsTemp;
        });
      }
    } catch (err) {
      debugPrint(err.toString());
    } finally {
      setState(() => caricamento = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      caricamento = true;
      errore = "";
    });

    try {
      if (_selectedInstance == null) {
        errore = 'Selezionare istanza';
        return;
      }

      defaultInstance = _selectedInstance ?? "";
      final istanza = _selectedInstance ?? "";

      final url =
          "https://$istanza-api.qfood.it/api/v1/auth/createBearer/9fdcf0b20019";

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          "x-api-key": defaultApiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim(),
          "noExpirationKey" : "hQvNLLQUV6ljx1JF0CgTKWjT5c6Qsp6lnzxdkTykG7b2Dtw1120TLPZpMRccgMS1pAhblDBQKF1l4n25DUeqvwPyKb9JAnLIM65BqiOKVFgVCdZdy9gdLj8yT48SQRZp"
        }),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              errore = 'Richiesta scaduta', Duration(seconds: 10));
        },
      );

      debugPrint("🔍 RAW LOGIN RESPONSE: ${response.body}");

      final dati = jsonDecode(response.body);

      if (!(response.statusCode == 200 || response.statusCode == 201) ||
          dati?["success"] != true ||
          dati?["data"]?["bearerToken"] == null) {
        throw Exception(
          dati?["verboseMessage"] ?? dati?["message"] ?? "Credenziali errate.",
        );
      }

      // TOKEN
      final token = dati["data"]["bearerToken"];

      ApiClient.bearerToken = token;

      // STORE fallback
      final store = dati["data"]["store"];
      final idStore = store?["idStore"] ?? 77;

      // COMPANY GUID ⚠️ IMPORTANTE !!!
      final companyGuid = dati["data"]["companyGuid"];

      debugPrint("🏢 companyGuid: $companyGuid");

      final prefs = await SharedPreferences.getInstance();
      usernameStore = _usernameController.text.trim();
      await prefs.setString("posToken", token); // <<<<<< FIX
      await prefs.setString("token", token);
      await prefs.setString("jwt", token);
      await prefs.setString("istanza", istanza);
      await prefs.setInt("idStore", idStore);

      if (companyGuid != null) {
        await prefs.setString("companyGuid", companyGuid);

        debugPrint("🔎 Recupero idCompanyHex...");
        await _recuperaIdCompanyHex(companyGuid); // <--- FIX CRITICO
      } else {
        debugPrint("⚠️ companyGuid NON presente nel login!");
      }

      await prefs.setBool("logged", true);

      // reset vecchie chiavi
      await prefs.remove("companySelected");
      await prefs.remove("storeSelected");
      await prefs.remove("deviceSelected");
      await prefs.remove("onboardingCompleted");

      debugPrint("🔐 TOKEN & DATI SALVATI");
      debugPrint("token = ${prefs.getString('token')}");
      debugPrint("jwt   = ${prefs.getString('jwt')}");
      debugPrint("idStore = ${prefs.getInt('idStore')}");
      debugPrint("companyGuid = ${prefs.getString('companyGuid')}");
      debugPrint("idCompanyHex = ${prefs.getString('idCompanyHex')}");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Login effettuato con successo!"),
          backgroundColor: verdeFlex,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/company');
      }
    } catch (e) {
      setState(() => errore = "Errore durante l'accesso: ${e.toString()}");
    } finally {
      setState(() => caricamento = false);
    }
  }

  Future<void> _recuperaIdCompanyHex(String companyGuid) async {
    final prefs = await SharedPreferences.getInstance();
    final istanza = prefs.getString("istanza") ?? defaultInstance;

    final url =
        "https://$istanza-api.qfood.it/api/v1/company/lookUpCompany/$companyGuid";

    debugPrint("🔍 LOOKUP COMPANY URL → $url");

    final res = await http.get(
      Uri.parse(url),
      headers: {"x-api-key": defaultApiKey},
    );

    debugPrint("📥 Risposta lookupCompany: ${res.body}");

    if (res.statusCode != 200) {
      debugPrint("❌ ERRORE lookupCompany");
      return;
    }

    final json = jsonDecode(res.body);

    if (json?["data"]?["records"] == null || json["data"]["records"].isEmpty) {
      debugPrint("❌ Nessuna azienda trovata");
      return;
    }

    final record = json["data"]["records"][0];

    final hex = record["_id"]; // <--- ECCO L'HEX CHE VOGLIAMO
    final name = record["title"];

    debugPrint("🏢 Azienda HEX trovata → $hex ($name)");

    await prefs.setString("idCompanyHex", hex);
    await prefs.setString("nomeCompany", name);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 800;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F8F3);
    final Color card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final Color text = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      body: isMobile
          ? _buildMobileLayout(card, text, isDark)
          : _buildDesktopLayout(card, text, isDark),
    );
  }

  // MOBILE — logo sopra, form sotto
  Widget _buildMobileLayout(Color card, Color text, bool isDark) {
    final size = MediaQuery.of(context).size;
    final double logoSize = size.width * 0.5;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: verdeFlex.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  isDark ? 'assets/logo.png' : 'assets/logoback.png',
                  width: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 36),
              _titoloBenvenuto(text),
              const SizedBox(height: 32),
              _formCampi(isDark),
            ],
          ),
        ),
      ),
    );
  }

//  DESKTOP —
  Widget _buildDesktopLayout(Color card, Color text, bool isDark) {
    final size = MediaQuery.of(context).size;
    final double logoSize = size.width * 0.22;

    return Container(
      color: isDark ? const Color(0xFF0E0E0E) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //  Sinistra — Logo grande centrato
          Expanded(
            flex: 4,
            child: Center(
              child: Image.asset(
                isDark ? 'assets/logodark.png' : 'assets/logo.png',
                width: logoSize,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 🔸 Destra — Card login più centrata
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF95C01F).withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _titoloBenvenuto(text),
                      const SizedBox(height: 36),
                      _formCampi(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //  Piccolo spazio laterale per centratura visiva
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _titoloBenvenuto(Color text) {
    return Column(
      children: [
        Text(
          "Benvenuto",
          style: TextStyle(
            color: text,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Accedi per continuare",
          style: TextStyle(
            color: text.withOpacity(0.7),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _formCampi(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdownInput(
          label: 'Istanza',
          items: instanceOptions,
          icona: Icons.web_asset,
          isDark: isDark,
          value: _selectedInstance,
          onChanged: (value) => setState(() => _selectedInstance = value),
        ),
        const SizedBox(height: 16),
        _campoInput("Username", _usernameController,
            Icons.person_outline_rounded, false, isDark),
        const SizedBox(height: 16),
        _campoInput("Password", _passwordController, Icons.lock_outline_rounded,
            true, isDark),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: caricamento ? null : _login,
          style: FilledButton.styleFrom(
            backgroundColor: verdeFlex,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: caricamento
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Accedi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (errore.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            errore,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _campoInput(
    String label,
    TextEditingController controller,
    IconData icona,
    bool isPassword,
    bool isDark,
  ) {
    return TextField(
      controller: controller, // 🔥 QUI È CRITICO
      obscureText: isPassword && !mostraPassword,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,

      onSubmitted: (_) {
        if (isPassword) {
          if (!caricamento) _login();
        } else {
          FocusScope.of(context).nextFocus();
        }
      },

      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icona, color: verdeFlex),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  mostraPassword ? Icons.visibility_off : Icons.visibility,
                  color: verdeFlex,
                ),
                onPressed: () =>
                    setState(() => mostraPassword = !mostraPassword),
              )
            : null,
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: verdeFlex, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dropdownInput<T>({
    required String label,
    required List<DropdownMenuItem<T>> items,
    required T? value,
    required ValueChanged<T?> onChanged,
    IconData icona = Icons.arrow_drop_down,
    bool isDark = false,
    String? hintText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: hintText != null
          ? Text(hintText,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ))
          : null,
      //icon: Icon(icona, color: verdeFlex),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icona, color: verdeFlex),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: verdeFlex, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: items,
      onChanged: onChanged,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      menuMaxHeight: 200,
    );
  }
}

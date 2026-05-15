import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';

class VersioneProgettoPage extends StatefulWidget {
  const VersioneProgettoPage({super.key});

  @override
  State<VersioneProgettoPage> createState() => _VersioneProgettoPageState();
}

class _VersioneProgettoPageState extends State<VersioneProgettoPage> {
  String version = "-";
  String buildNumber = "-";

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      version = info.version;
      buildNumber = info.buildNumber;
    });
  }

  // copia negli appunti
  void _copyInfo() {
    Clipboard.setData(
      ClipboardData(text: "Versione: 1.1 "),
      //$version — Build: $buildNumber
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Informazioni versione copiate!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,

      appBar: AppBar(
        backgroundColor: const Color(0xFF95C01F),
        elevation: 0,

        // ✅ LEADING QUI
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
                  (route) => false,
            );
          },
        ),

        // ✅ TITLE QUI
        title: Row(
          children: [
            Image.asset(
              "assets/logo.png",
              height: 28,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            const Text(
              "Debug",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // intestazione
          Row(
            children: [
              Icon(Icons.info_outline, size: 32, color: cs.primary),
              const SizedBox(width: 12),
              Text(
                "Qfood",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // --- CARD VERSIONE ---
          Card(
            elevation: 1,
            color: cs.surfaceContainerHighest,
            shadowColor: cs.shadow.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Versione app",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    "1.1",
                   // version,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text("Build",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    buildNumber,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 22),

                  FilledButton.icon(
                    onPressed: _copyInfo,
                    icon: const Icon(Icons.copy),
                    label: const Text("Copia info versione"),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            "Note aggiornamento",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // --- CARD NOTE ---
          Card(
            elevation: 1,
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _NoteItem("Fix completo sincronizzazione POS"),
                  _NoteItem("Gestione corretta Bearer Token & login POS"),
                  _NoteItem("Aggiornato e stabilizzato DB locale"),
                  _NoteItem("Aggiunta pagina Debug DB"),
                  _NoteItem("Migliorato Sync Pagamenti"),
                  _NoteItem("Aggiunte nuove rotte POS"),
                  _NoteItem("Nuovo modulo Checkout avanzato"),
                  _NoteItem("Calcolo automatico totale, da pagare, mancia e resto"),
                  _NoteItem("Modulo calcolo resto per pagamenti in contanti"),
                  _NoteItem("Gestione sconti avanzata (importo, valore, percentuale)"),
                  _NoteItem("Sconti rapidi predefiniti 5% • 10% • 15% • 20%"),
                  _NoteItem("Funzione Dividi conto con calcolo quota per persona"),
                  _NoteItem("Selezione cliente con popup centrale"),
                  _NoteItem("Visualizzazione completa dati cliente/azienda"),
                  _NoteItem("PIN amministratore nascosto per funzioni avanzate - dopo pulsante sconto 20%"),
                  _NoteItem("Abilitazione pulsanti speciali (CS, vendita non fiscale, riscontro)"),
                  _NoteItem("Tastierino numerico migliorato e collegato al totale"),
                  _NoteItem("Migliorie grafiche e UX/UI (Material 3)"),
                  _NoteItem("Risolti bug grafici e di interazione"),

                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------
// WIDGET NOTE (Material 3 style)
// -----------------------------
class _NoteItem extends StatelessWidget {
  final String text;
  const _NoteItem(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "- $text",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

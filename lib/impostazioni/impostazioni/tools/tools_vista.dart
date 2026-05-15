import 'package:flutter/material.dart';

class ToolsVista extends StatefulWidget {
  const ToolsVista({super.key});

  @override
  State<ToolsVista> createState() => _ToolsVistaState();
}

class _ToolsVistaState extends State<ToolsVista> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color verdeFlexboard = const Color(0xFF95C01F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: verdeFlexboard,
        elevation: 0,
        title: const Text(
          "Tools",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.build_rounded), text: "Strumenti"),
            Tab(icon: Icon(Icons.history_rounded), text: "Storico messaggi"),
            Tab(icon: Icon(Icons.email_rounded), text: "Impostazioni email"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StrumentiTab(onAction: _eseguiAzione, verdeFlexboard: verdeFlexboard),
          const _StoricoMessaggiTab(),
          const _ImpostazioniEmailTab(),
        ],
      ),
    );
  }

  /// 🔹 Simula chiamata API (puoi sostituire con le tue funzioni reali)
  Future<void> _eseguiAzione(String tipo) async {
    await Future.delayed(const Duration(milliseconds: 800)); // simulazione API

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$tipo eseguito con successo ✅"),
        backgroundColor: verdeFlexboard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────── STRUMENTI TAB ───────────────────────────────

class _StrumentiTab extends StatelessWidget {
  final Future<void> Function(String) onAction;
  final Color verdeFlexboard;

  const _StrumentiTab({required this.onAction, required this.verdeFlexboard});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF232323) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final tools = [
      {
        'titolo': 'Svuota tavoli',
        'descrizione': 'Cancella localmente il contenuto dei tavoli per tutte le sale.',
        'azione': 'Svuota tavoli',
      },
      {
        'titolo': 'Cancella ordini',
        'descrizione': 'Cancella localmente tutti gli ordini.',
        'azione': 'Cancella ordini',
      },
      {
        'titolo': 'Download',
        'descrizione': 'Scarica i dati richiesti per il punto vendita.',
        'azione': 'Download',
      },
      {
        'titolo': 'Sincronizzazione PLU Bizerba',
        'descrizione': 'Sincronizza le modifiche dei prodotti con le bilance Bizerba.',
        'azione': 'Sincronizza',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          color: bgCard,
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool['titolo']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tool['descrizione']!,
                  style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: verdeFlexboard,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _mostraDialogConferma(
                    context,
                    titolo: tool['titolo']!,
                    messaggio:
                    "Questa operazione eseguirà: ${tool['titolo']}. Sei sicuro di voler procedere?",
                    confermaLabel: "Sì, procedi",
                    colorePrimario: verdeFlexboard,
                    onConferma: () async => onAction(tool['azione']!),
                  ),
                  child: Text(
                    tool['azione']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Dialog di conferma universale
  void _mostraDialogConferma(
      BuildContext context, {
        required String titolo,
        required String messaggio,
        required String confermaLabel,
        required Color colorePrimario,
        required VoidCallback onConferma,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(
              "Attenzione!",
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: Text(
              messaggio,
              style: TextStyle(color: textColor.withOpacity(0.9)),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ANNULLA",
                    style: TextStyle(
                        color: colorePrimario, fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConferma();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorePrimario,
                  foregroundColor: Colors.white,
                ),
                child: Text(confermaLabel.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── STORICO MESSAGGI TAB ───────────────────────────────

class _StoricoMessaggiTab extends StatelessWidget {
  const _StoricoMessaggiTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF232323) : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: 5,
      itemBuilder: (_, i) => Card(
        color: bg,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.mail_outline_rounded, color: text.withOpacity(0.8)),
          title: Text(
            "Messaggio #$i",
            style: TextStyle(fontWeight: FontWeight.bold, color: text),
          ),
          subtitle: Text(
            "Inviato il ${DateTime.now().subtract(Duration(days: i)).toString().substring(0, 10)}",
            style: TextStyle(color: text.withOpacity(0.6)),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, color: text.withOpacity(0.5), size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────── IMPOSTAZIONI EMAIL TAB ───────────────────────────────

class _ImpostazioniEmailTab extends StatelessWidget {
  const _ImpostazioniEmailTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF232323) : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;
    final Color verde = const Color(0xFF95C01F);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          color: bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Impostazioni email",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: text)),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Email mittente",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Host SMTP",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Porta",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text("Configurazione salvata ✅"),
                      backgroundColor: verde,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text("Salva configurazione"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

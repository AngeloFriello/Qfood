import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LogsVista extends StatefulWidget {
  const LogsVista({super.key});

  @override
  State<LogsVista> createState() => _LogsVistaState();
}

class _LogsVistaState extends State<LogsVista> {
  List<dynamic> logs = [];
  bool caricamento = false;
  String errore = "";
  bool darkMode = true; // 🌗 Modalità di default

  @override
  void initState() {
    super.initState();
    _caricaLogs();
  }

  Future<void> _caricaLogs() async {
    setState(() {
      caricamento = true;
      errore = "";
    });

    try {
      final prefs   = await SharedPreferences.getInstance();
      final token   = prefs.getString("token");
      final istanza = prefs.getString("istanza");

      // TODO 🔧 Inserisci qui l’endpoint reale dei logs
      final url = "https://$istanza-api.qfood.it/api/v1/logs";

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          logs = List.from(data["data"] ?? []);
        });
      } else {
        setState(() => errore = "Errore server: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => errore = "Errore di connessione: $e");
    } finally {
      setState(() => caricamento = false);
    }
  }

  Future<void> _cancellaTutti() async {
    setState(() => logs.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tutti i log sono stati cancellati")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color sfondo =
    darkMode ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
    final Color testo = darkMode ? Colors.white : Colors.black87;
    final Color accent = darkMode ? Colors.greenAccent : Colors.green;

    return Scaffold(
      backgroundColor: sfondo,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        title: Text(
          "Logs",
          style: TextStyle(
            color: darkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: logs.isNotEmpty ? _cancellaTutti : null,
            icon: const Icon(Icons.delete),
            color: darkMode ? Colors.white : Colors.black,
          ),
          IconButton(
            onPressed: () => setState(() => darkMode = !darkMode),
            icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
            color: accent,
          ),
        ],
        iconTheme:
        IconThemeData(color: darkMode ? Colors.white : Colors.black),
        elevation: 4,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: sfondo,
        child: caricamento
            ? const Center(child: CircularProgressIndicator())
            : errore.isNotEmpty
            ? Center(
          child: Text(
            errore,
            style: TextStyle(color: Colors.redAccent, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        )
            : logs.isEmpty
            ? Center(
          child: Text(
            "Nessun log disponibile",
            style: TextStyle(
                color: testo.withOpacity(0.7), fontSize: 16),
          ),
        )
            : LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final livello = log["level"] ?? "info";
                final colore = livello == "error"
                    ? Colors.redAccent
                    : (livello == "warning"
                    ? Colors.amberAccent
                    : accent);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin:
                  const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: darkMode
                        ? const Color(0xFF1C1C1C)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colore.withOpacity(0.3)),
                    boxShadow: [
                      if (!darkMode)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${log["timestamp"] ?? ""}  •  ${log["service"] ?? "System"}",
                                style: TextStyle(
                                  color: colore,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 13 : 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  logs.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          log["message"] ?? "Nessun messaggio",
                          style: TextStyle(
                            color: testo,
                            fontSize: isMobile ? 14 : 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

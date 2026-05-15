import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';


class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> articles = [];
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> operators = [];
  List<Map<String, dynamic>> vatRates = [];

  String dbPath = "";
  int dbSizeBytes = 0;

  void _goHome() {
    Future.microtask(() {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  // ============================================================
  // LOAD DEBUG DATA (CON PARSING VARIANTI)
  // ============================================================
  Future<void> _loadDebugData() async {
    final db = await LocalDB.instance();
    final path = p.join(await getDatabasesPath(), "qfood_pos.db");

    final file = File(path);
    dbSizeBytes = await file.length();

    categories = await db.query("categories");
    payments   = await db.query("payments");
    operators  = await db.query("operators");
    vatRates   = await db.query("vat_rates");

    // 🔥 ARTICOLI + PARSE VARIANTI
    final rawArticles = await db.query("articles");

    articles = rawArticles.map((row) {
      final raw = row["variants"];
      List<dynamic> parsed = [];

      if (raw is String && raw.isNotEmpty) {
        try {
          parsed = jsonDecode(raw);
        } catch (_) {}
      }

      return {
        ...row,
        "variantsParsed": parsed,
      };
    }).toList();

    setState(() => dbPath = path);
  }

  // ============================================================
  // RESET DB — FIX DEFINITIVO
  // ============================================================
  Future<void> _resetDB() async {
    final path = p.join(await getDatabasesPath(), "qfood_pos.db");

    // 🔥 CHIUDI DB SE APERTO
    if (LocalDB.hasInstance) {
      await LocalDB.close();
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    // 🔁 RIAPRE DB
    await LocalDB.instance();
    await _loadDebugData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Database resettato correttamente")),
    );
  }

  void _exportJson() {
    final export = {
      "categories": categories,
      "articles": articles,
      "payments": payments,
      "operators": operators,
      "vatRates": vatRates,
    };

    final encoded = const JsonEncoder.withIndent("  ").convert(export);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("📤 Esportazione JSON"),
        content: SingleChildScrollView(child: Text(encoded)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ============================================================
  // BOX GENERICO
  // ============================================================
  Widget _sectionBox(String title, List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title (${items.length})",
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  items[i].toString(),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOX ARTICOLI (CON VARIANTI VISIBILI)
  // ============================================================
  Widget _articlesBox() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Articoli (${articles.length})",
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: articles.length,
              itemBuilder: (_, i) {
                final a = articles[i];
                final vars = a["variantsParsed"] as List;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🍔 ${a["title"]}",
                          style: theme.textTheme.bodyMedium),
                      Text(
                        "Varianti: ${vars.length}",
                        style: theme.textTheme.bodySmall,
                      ),
                      if (vars.isNotEmpty)
                        Text(
                          vars.map((v) => v["title"]).join(", "),
                          style: theme.textTheme.bodySmall!
                              .copyWith(color: theme.colorScheme.primary),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Debug DB Locale"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                FilledButton(
                  onPressed: _resetDB,
                  child: const Text("Reset DB"),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _exportJson,
                  child: const Text("Esporta JSON"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                children: [
                  _sectionBox("Categorie", categories),
                  _articlesBox(), // 🔥 QUI VEDI LE VARIANTI
                  _sectionBox("Pagamenti", payments),
                  _sectionBox("Operatori", operators),
                  _sectionBox("IVA", vatRates),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';

class ResoMerceVista extends StatefulWidget {
  const ResoMerceVista({super.key});

  @override
  State<ResoMerceVista> createState() => _ResoMerceVistaState();
}

class _ResoMerceVistaState extends State<ResoMerceVista> {
  final TextEditingController barcodeCtrl = TextEditingController();
  final Color verdeFlex = const Color(0xFF95C01F);

  bool prodottoTrovato = false;
  bool isLoading = false;

  Map<String, String> prodotto = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: verdeFlex,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Reso merce",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔍 Campo ricerca barcode
            TextField(
              controller: barcodeCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _cercaProdotto,
              decoration: InputDecoration(
                hintText: "Barcode vendita",
                prefixIcon: Icon(Icons.search_rounded, color: verdeFlex),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: verdeFlex.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: verdeFlex, width: 2),
                ),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Dettaglio prodotto trovato
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (prodottoTrovato)
              _cardProdotto(isDark)
            else
              Expanded(
                child: Center(
                  child: Text(
                    "Inserisci o scansiona il barcode vendita per effettuare un reso",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // Pulsante inferiore
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: barcodeCtrl.text.isEmpty ? Colors.grey : verdeFlex,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: verdeFlex.withOpacity(0.3),
            ),
            onPressed: barcodeCtrl.text.isEmpty ? null : _confermaReso,
            child: const Text(
              "Conferma",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── COMPONENTI ───────────────────────────────

  Widget _cardProdotto(bool isDark) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: verdeFlex.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prodotto["nome"] ?? "Prodotto sconosciuto",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: verdeFlex,
                  ),
                ),
                const SizedBox(height: 10),
                _rigaDettaglio("Barcode", prodotto["barcode"] ?? "-"),
                _rigaDettaglio("Prezzo", prodotto["prezzo"] ?? "-"),
                _rigaDettaglio("Data vendita", prodotto["data"] ?? "-"),
                _rigaDettaglio("Cassiere", prodotto["cassiere"] ?? "-"),
                const Spacer(),
                Center(
                  child: Icon(Icons.inventory_2_rounded,
                      color: verdeFlex.withOpacity(0.7), size: 90),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rigaDettaglio(String label, String valore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(valore, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─────────────────────────────── LOGICA ───────────────────────────────

  Future<void> _cercaProdotto(String barcode) async {
    if (barcode.isEmpty) return;
    setState(() {
      isLoading = true;
      prodottoTrovato = false;
    });

    // Simulazione API lookup
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      prodottoTrovato = true;
      isLoading = false;
      prodotto = {
        "nome": "Caffè Espresso",
        "barcode": barcode,
        "prezzo": "1.30 €",
        "data": "11/11/2025",
        "cassiere": "Demo User",
      };
    });
  }

  void _confermaReso() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: verdeFlex,
        content: const Text(
          "Reso effettuato con successo ✅",
          style: TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );

    setState(() {
      prodottoTrovato = false;
      barcodeCtrl.clear();
    });
  }
}

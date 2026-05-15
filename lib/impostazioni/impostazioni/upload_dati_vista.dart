import 'package:flutter/material.dart';

class UploadDatiVista extends StatefulWidget {
  const UploadDatiVista({super.key});

  @override
  State<UploadDatiVista> createState() => _UploadDatiVistaState();
}

class _UploadDatiVistaState extends State<UploadDatiVista> {
  final Color verdeFlex = const Color(0xFF95C01F);

  final Map<String, bool> selezioni = {
    "Utenti": false,
    "Prodotti": false,
    "Reparti prodotti": true,
    "Categorie prodotti": true,
    "Contatti": true,
    "Common": true,
  };

  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF7F8F3);
    final Color surface = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: verdeFlex,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Invia dati al Server",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // intestazione
                Text(
                  "Seleziona i dati da caricare",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Puoi caricare più categorie contemporaneamente. I file verranno sincronizzati automaticamente.",
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // card con tabella
                Expanded(
                  child: Card(
                    color: surface,
                    elevation: 3,
                    shadowColor: verdeFlex.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ListView.separated(
                        itemCount: selezioni.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: verdeFlex.withOpacity(0.15),
                        ),
                        itemBuilder: (context, index) {
                          final key = selezioni.keys.elementAt(index);
                          final attivo = selezioni[key]!;

                          return ListTile(
                            onTap: () => setState(() => selezioni[key] = !attivo),
                            leading: Icon(
                              attivo
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: attivo ? verdeFlex : Colors.grey,
                            ),
                            title: Text(
                              key,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Switch(
                              value: attivo,
                              activeThumbColor: verdeFlex,
                              onChanged: (v) =>
                                  setState(() => selezioni[key] = v),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          if (isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),

      // 🔹 footer
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: const Text(
              "Carica dati",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: _uploadDati,
            style: FilledButton.styleFrom(
              backgroundColor: verdeFlex,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: verdeFlex.withOpacity(0.3),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadDati() async {
    setState(() => isUploading = true);

    // simulazione upload
    await Future.delayed(const Duration(seconds: 2));

    setState(() => isUploading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: verdeFlex,
        content: const Text(
          "Upload completato con successo ✅",
          style: TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

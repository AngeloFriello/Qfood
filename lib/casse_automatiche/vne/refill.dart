import 'dart:async';
import 'package:dashboard/casse_automatiche/vne/updateVne.dart';
import 'package:flutter/material.dart';

/// Avvia il refill VNE sulla macchina all'IP specificato,
/// mostrando una modal con l'importo inserito in tempo reale.
///
/// Restituisce [true] se il refill è stato completato con successo,
/// [false] se annullato o in errore.
Future<bool> showVneRefillModal(
  BuildContext context, {
  required String ipAddress,
  String opName = 'CASSA_01',
}) async {
  final service = VneService(ipAddress, opName: opName);
  final completer = Completer<bool>();

  // ── Stato locale della modal ──────────────────────────────────────────
  int    amountCents  = 0;   // amountRefill dal polling
  bool   isEnding     = false; // "Termina Refill" premuto, attesa risposta
  bool   isDone       = false; // endRefill completato con successo
  bool   hasError     = false;
  String errorMessage = '';
  Timer? pollingTimer;
  StateSetter? _setState;

  void refresh() => _setState?.call(() {});

  // ── Avvia polling tipo 33 ─────────────────────────────────────────────
  void startPolling() {
    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final res = await service.pollRefill();
        if (completer.isCompleted) return;
        if (res['req_status'] == 1) {
          amountCents = res['amountRefill'] ?? 0;
          refresh();
        }
      } catch (_) {
        // Ignora errori di rete transitori durante il polling
      }
    });
  }

  // ── Termina refill (tipo 31) ──────────────────────────────────────────
  Future<void> doEndRefill() async {
    if (isEnding || completer.isCompleted) return;
    isEnding = true;
    refresh();
    pollingTimer?.cancel();

    try {
      final res = await service.endRefill();
      if (res['req_status'] == 1) {
        isDone = true;
        refresh();
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        completer.complete(true);
      } else {
        errorMessage = res['mess']?.toString() ?? 'Errore sconosciuto';
        hasError  = true;
        isEnding  = false;
        refresh();
        // Riprende il polling perché il refill è ancora attivo
        startPolling();
      }
    } catch (e) {
      errorMessage = e.toString();
      hasError  = true;
      isEnding  = false;
      refresh();
      startPolling();
    }
  }

  // ── 1. Avvia refill (tipo 30) ─────────────────────────────────────────
  Map<String, dynamic> startRes;
  try {
    startRes = await service.startRefill(acceptAll: 1);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore connessione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  if (startRes['req_status'] != 1) {
    final msg = startRes['mess']?.toString() ?? 'NACK sconosciuto';
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossibile avviare il refill: $msg'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  // ── 2. Avvia polling e apri la modal ──────────────────────────────────
  startPolling();

  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // impedisce chiusura con back
        child: StatefulBuilder(
          builder: (ctx, setState) {
            _setState = setState;

            final double amountEur = amountCents / 100.0;

            // ── Colori e icone stato ──────────────────────────────────
            final Color accentColor = isDone
                ? Colors.green.shade600
                : hasError
                    ? Colors.red.shade600
                    : const Color(0xFF1976D2);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Header ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.07),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: accentColor.withOpacity(0.15),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : hasError
                                      ? Icons.error_rounded
                                      : Icons.savings_outlined,
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDone
                                      ? 'Refill completato'
                                      : hasError
                                          ? 'Errore refill'
                                          : 'Refill in corso',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Macchina: $ipAddress',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        children: [

                          // Importo inserito — display grande
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green.shade50
                                  : hasError
                                      ? Colors.red.shade50
                                      : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: accentColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'IMPORTO INSERITO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor.withOpacity(0.7),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '€ ${amountEur.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    letterSpacing: -1,
                                  ),
                                ),
                                if (!isDone && !hasError) ...[
                                  const SizedBox(height: 12),
                                  // Indicatore animato "in ascolto"
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'In attesa banconote/monete…',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Messaggio di errore
                          if (hasError) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── Bottone principale ───────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: isDone

                                // Chiudi dopo completamento
                                ? ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text('Chiudi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )

                                // Termina Refill
                                : ElevatedButton.icon(
                                    onPressed: isEnding ? null : doEndRefill,
                                    icon: isEnding
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.stop_circle_outlined,
                                          ),
                                    label: Text(
                                      isEnding
                                          ? 'Terminando…'
                                          : 'Termina Refill',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── 3. Attendi la fine dell'operazione ────────────────────────────────
  final result = await completer.future;
  pollingTimer?.cancel();
  return result;
}
import 'dart:async';
import 'package:dashboard/casse_automatiche/vne/updateVne.dart';
import 'package:flutter/material.dart';

/// Valori periferica per tipo 52
enum StackerPeripheral {
  coinCashbox(0, 'Cashbox monete', Icons.toll_outlined),
  banknotesStacker(1, 'Stacker banconote', Icons.layers_outlined),
  both(2, 'Entrambi', Icons.device_hub_outlined);

  final int value;
  final String label;
  final IconData icon;
  const StackerPeripheral(this.value, this.label, this.icon);
}

/// Avvia il reset stacker VNE con selezione periferica e modal di progresso.
///
/// Mostra prima un dialog di conferma con scelta della periferica,
/// poi apre la modal di avanzamento con polling (tipo 53).
///
/// Restituisce [true] se completato con successo, [false] altrimenti.
Future<bool> showVneStackerResetModal(
  BuildContext context, {
  required String ipAddress,
  String opName = 'CASSA_01',
}) async {
  // ── Step 1: dialog di selezione periferica ────────────────────────────
  final StackerPeripheral? selectedPeripheral =
      await showDialog<StackerPeripheral>(
    context: context,
    builder: (ctx) {
      StackerPeripheral selected = StackerPeripheral.both;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: Colors.orange.shade100),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restore_page_outlined,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Reset Stacker',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleziona la periferica da resettare:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              ...StackerPeripheral.values.map((p) {
                final bool isSelected = selected == p;
                return GestureDetector(
                  onTap: () => setState(() => selected = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orange.shade400
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          p.icon,
                          size: 20,
                          color: isSelected
                              ? Colors.orange.shade700
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.orange.shade800
                                : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              color: Colors.orange.shade600, size: 18),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Il reset annullerà il contenuto dello stacker selezionato. '
                        'Assicurarsi che la macchina sia in stato idle.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.amber.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Pop 1 – Annulla selezione
                if (Navigator.of(ctx).canPop()) {
                  Navigator.of(ctx).pop(null);
                }
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Pop 2 – Conferma selezione
                if (Navigator.of(ctx).canPop()) {
                  Navigator.of(ctx).pop(selected);
                }
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Avvia Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (selectedPeripheral == null || !context.mounted) return false;

  // ── Step 2: chiama tipo 52 ────────────────────────────────────────────
  final service = VneService(ipAddress, opName: opName);
  Map<String, dynamic> startRes;
  try {
    startRes = await service.stackerCancellation(selectedPeripheral.value);
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
          content: Text('Impossibile avviare il reset: $msg'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  // ── Step 3: modal di avanzamento con polling tipo 53 ──────────────────
  final completer = Completer<bool>();

  bool isDone = false;
  bool hasError = false;
  String errorMsg = '';
  Timer? pollingTimer;
  StateSetter? _setState;

  void refresh() => _setState?.call(() {});

  void stopWithResult(bool success) {
    if (completer.isCompleted) return;
    pollingTimer?.cancel();
    isDone = success;
    if (!success) hasError = true;
    refresh();
    Future.delayed(const Duration(seconds: 2), () {
      // Pop 3 – chiusura automatica modal dopo successo
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
      if (!completer.isCompleted) completer.complete(success);
    });
  }

  // Polling tipo 53
  pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
    try {
      final res = await service.pollEmptying();
      if (completer.isCompleted) return;

      if (res['req_status'] == 1) {
        final int emptyStatus = res['empty_status'] ?? -1;
        // empty_status != 1 → operazione completata
        if (emptyStatus != 1) {
          stopWithResult(true);
        }
        // se == 1 → ancora in corso, continua il polling
      } else {
        // NACK dal polling
        errorMsg = res['mess']?.toString() ?? 'NACK sconosciuto';
        pollingTimer?.cancel();
        hasError = true;
        refresh();
        Future.delayed(const Duration(seconds: 3), () {
          // Pop 4 – chiusura automatica modal dopo errore NACK polling
          if (context.mounted) {
            final nav = Navigator.of(context, rootNavigator: true);
            if (nav.canPop()) nav.pop();
          }
          if (!completer.isCompleted) completer.complete(false);
        });
      }
    } catch (_) {
      // Errore rete transitorio, continua polling
    }
  });

  // ── Step 4: apri modal progresso ─────────────────────────────────────
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (ctx, setState) {
            _setState = setState;

            final Color accentColor = isDone
                ? Colors.green.shade600
                : hasError
                    ? Colors.red.shade600
                    : Colors.orange.shade700;

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 18),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.07),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        border: Border(
                          bottom: BorderSide(
                              color: accentColor.withOpacity(0.15)),
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
                                      : Icons.restore_page_outlined,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDone
                                      ? 'Reset completato'
                                      : hasError
                                          ? 'Errore reset'
                                          : 'Reset in corso…',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  selectedPeripheral.label,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isDone
                                ? Icon(Icons.check_circle_rounded,
                                    key: const ValueKey('done'),
                                    color: Colors.green.shade500,
                                    size: 64)
                                : hasError
                                    ? Icon(Icons.error_rounded,
                                        key: const ValueKey('error'),
                                        color: Colors.red.shade400,
                                        size: 64)
                                    : SizedBox(
                                        key: const ValueKey('loading'),
                                        width: 64,
                                        height: 64,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 5,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green.shade50
                                  : hasError
                                      ? Colors.red.shade50
                                      : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: accentColor.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(selectedPeripheral.icon,
                                        size: 18, color: accentColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedPeripheral.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: accentColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isDone
                                      ? 'Stacker resettato con successo'
                                      : hasError
                                          ? errorMsg
                                          : 'Operazione di reset in corso,\nattendere il completamento…',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: accentColor.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Macchina: $ipAddress',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 20),

                          // Bottone chiudi (solo quando terminato)
                          if (isDone || hasError)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  pollingTimer?.cancel();
                                  // Pop 5 – chiusura manuale da bottone "Chiudi"
                                  if (Navigator.of(ctx).canPop()) {
                                    Navigator.of(ctx).pop();
                                  }
                                  if (!completer.isCompleted) {
                                    completer.complete(isDone && !hasError);
                                  }
                                },
                                icon: Icon(
                                    isDone ? Icons.check : Icons.close,
                                    size: 18),
                                label: const Text('Chiudi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDone
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
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

  final result = await completer.future;
  pollingTimer?.cancel();
  return result;
}
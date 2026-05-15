import 'dart:async';
import 'package:dashboard/casse_automatiche/vne/updateVne.dart';
import 'package:flutter/material.dart';

// ── Modello step svuotamento ──────────────────────────────────────────────────
enum _EmptyStep {
  hopper(
    label: 'Svuotamento Hopper',
    subtitle: 'Monete nel cassetto',
    icon: Icons.toll_outlined,
    color: Color(0xFF7B61FF),
  ),
  recycler(
    label: 'Svuotamento Recycler',
    subtitle: 'Banconote nel recycler',
    icon: Icons.layers_outlined,
    color: Color(0xFF0288D1),
  );

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _EmptyStep({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

enum _StepStatus { waiting, running, done, error }

/// Svuota completamente la macchina VNE: prima hopper (monete),
/// poi recycler (banconote). Mostra una modal con avanzamento per ogni step.
///
/// Restituisce [true] se entrambi gli step sono completati con successo.
Future<bool> showVneFullEmptyModal(
  BuildContext context, {
  required String ipAddress,
  String opName = 'CASSA_01',
}) async {
  // ── Conferma distruttiva ──────────────────────────────────────────────
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(bottom: BorderSide(color: Colors.red.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Svuotamento Completo',
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
            'Stai per avviare lo svuotamento completo della macchina.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 16),
          // Riepilogo step
          ..._EmptyStep.values.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: s.color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(s.icon, size: 18, color: s.color),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.label,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: s.color)),
                      Text(s.subtitle,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'L\'operazione è irreversibile. Assicurarsi che i cassetti '
                    'siano aperti e pronti a ricevere il contante.',
                    style:
                        TextStyle(fontSize: 11, color: Colors.red.shade700),
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
            if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(false);
          },
          child: const Text('Annulla'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(true);
          },
          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
          label: const Text('Conferma Svuotamento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  // ── Stato shared della modal ──────────────────────────────────────────
  final completer = Completer<bool>();

  final Map<_EmptyStep, _StepStatus> stepStatus = {
    _EmptyStep.hopper: _StepStatus.waiting,
    _EmptyStep.recycler: _StepStatus.waiting,
  };
  final Map<_EmptyStep, String> stepError = {};
  _EmptyStep? currentStep;
  bool globalError = false;

  Timer? pollingTimer;
  StateSetter? _setState;

  void refresh() => _setState?.call(() {});

  void closeModal(bool success) {
    if (completer.isCompleted) return;
    pollingTimer?.cancel();
    refresh();
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
      if (!completer.isCompleted) completer.complete(success);
    });
  }

  // ── Polling tipo 53 per un singolo step ──────────────────────────────
  Future<bool> pollUntilDone(_EmptyStep step) async {
    final poll = Completer<bool>();
    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (poll.isCompleted) return;
      try {
        final res = await VneService(ipAddress, opName: opName).pollEmptying();
        if (res['req_status'] == 1) {
          final int emptyStatus = res['empty_status'] ?? -1;
          if (emptyStatus != 1) {
            pollingTimer?.cancel();
            poll.complete(true);
          }
        } else {
          pollingTimer?.cancel();
          stepError[step] = res['mess']?.toString() ?? 'NACK sconosciuto';
          poll.complete(false);
        }
      } catch (_) {
        // Errore rete transitorio, continua
      }
    });
    return poll.future;
  }

  // ── Esecuzione sequenziale degli step ────────────────────────────────
  Future<void> runSequence() async {
    final service = VneService(ipAddress, opName: opName);

    for (final step in _EmptyStep.values) {
      currentStep = step;
      stepStatus[step] = _StepStatus.running;
      refresh();

      // Avvia lo step
      Map<String, dynamic> startRes;
      try {
        startRes = step == _EmptyStep.hopper
            ? await service.startHopperEmptying(full: 1)
            : await service.startRecyclerEmptying(full: 1);
      } catch (e) {
        stepStatus[step] = _StepStatus.error;
        stepError[step] = 'Errore connessione: $e';
        globalError = true;
        refresh();
        closeModal(false);
        return;
      }

      if (startRes['req_status'] != 1) {
        stepStatus[step] = _StepStatus.error;
        stepError[step] =
            startRes['mess']?.toString() ?? 'NACK sconosciuto';
        globalError = true;
        refresh();
        closeModal(false);
        return;
      }

      // Polling fino al completamento dello step
      final ok = await pollUntilDone(step);

      if (!ok) {
        stepStatus[step] = _StepStatus.error;
        globalError = true;
        refresh();
        closeModal(false);
        return;
      }

      stepStatus[step] = _StepStatus.done;
      refresh();

      // Pausa breve tra i due step
      if (step != _EmptyStep.values.last) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    // Tutti gli step completati
    currentStep = null;
    closeModal(true);
  }

  // ── Apri modal progresso ──────────────────────────────────────────────
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (ctx, setState) {
            _setState = setState;

            final bool allDone = stepStatus.values
                .every((s) => s == _StepStatus.done);
            final bool anyError = stepStatus.values
                .any((s) => s == _StepStatus.error);

            final Color headerColor = allDone
                ? Colors.green.shade600
                : anyError
                    ? Colors.red.shade600
                    : Colors.indigo.shade600;

            final int doneCount =
                stepStatus.values.where((s) => s == _StepStatus.done).length;
            final double progress = doneCount / _EmptyStep.values.length;

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Header ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 18),
                      decoration: BoxDecoration(
                        color: headerColor.withOpacity(0.07),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        border: Border(
                          bottom: BorderSide(
                              color: headerColor.withOpacity(0.15)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: headerColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              allDone
                                  ? Icons.check_circle_rounded
                                  : anyError
                                      ? Icons.error_rounded
                                      : Icons.delete_sweep_rounded,
                              color: headerColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allDone
                                      ? 'Svuotamento completato'
                                      : anyError
                                          ? 'Svuotamento interrotto'
                                          : 'Svuotamento in corso…',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Macchina: $ipAddress',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        children: [

                          // Barra progresso globale
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progresso totale',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '$doneCount / ${_EmptyStep.values.length} step',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: allDone ? 1.0 : progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    allDone
                                        ? Colors.green.shade500
                                        : anyError
                                            ? Colors.red.shade400
                                            : Colors.indigo.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Card per ogni step
                          ..._EmptyStep.values.map((step) {
                            final status = stepStatus[step]!;
                            final isActive = currentStep == step;
                            final error = stepError[step];

                            final Color stepColor = status == _StepStatus.done
                                ? Colors.green.shade600
                                : status == _StepStatus.error
                                    ? Colors.red.shade600
                                    : isActive
                                        ? step.color
                                        : Colors.grey.shade400;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: status == _StepStatus.done
                                    ? Colors.green.shade50
                                    : status == _StepStatus.error
                                        ? Colors.red.shade50
                                        : isActive
                                            ? step.color.withOpacity(0.05)
                                            : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: stepColor.withOpacity(0.25),
                                  width: isActive ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icona step
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: stepColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: status == _StepStatus.running
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: step.color,
                                              ),
                                            )
                                          : Icon(
                                              status == _StepStatus.done
                                                  ? Icons.check_rounded
                                                  : status ==
                                                          _StepStatus.error
                                                      ? Icons.close_rounded
                                                      : step.icon,
                                              size: 18,
                                              color: stepColor,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Testo
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: stepColor,
                                          ),
                                        ),
                                        Text(
                                          status == _StepStatus.done
                                              ? 'Completato'
                                              : status == _StepStatus.error
                                                  ? (error ?? 'Errore')
                                                  : status ==
                                                          _StepStatus.running
                                                      ? step.subtitle
                                                      : 'In attesa…',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: stepColor.withOpacity(0.75),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Badge stato
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: stepColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status == _StepStatus.done
                                          ? '✓ OK'
                                          : status == _StepStatus.error
                                              ? '✗ Errore'
                                              : status ==
                                                      _StepStatus.running
                                                  ? 'In corso'
                                                  : 'Attesa',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: stepColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // Bottone chiudi (solo a fine operazione)
                          if (allDone || anyError) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  pollingTimer?.cancel();
                                  if (Navigator.of(ctx).canPop()) {
                                    Navigator.of(ctx).pop();
                                  }
                                  if (!completer.isCompleted) {
                                    completer.complete(allDone && !anyError);
                                  }
                                },
                                icon: Icon(
                                  allDone ? Icons.check : Icons.close,
                                  size: 18,
                                ),
                                label: const Text('Chiudi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: allDone
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

    // Avvia la sequenza dopo che la modal è montata
    Future.microtask(runSequence);
  }

  final result = await completer.future;
  pollingTimer?.cancel();
  return result;
}
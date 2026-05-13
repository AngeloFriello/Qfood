import 'dart:async';
import 'dart:convert';

import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/PosProt_17.dart';
import 'package:dashboard/pagamenti_elettronici/pagamenti.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ── Costanti stile QFood ──────────────────────────────────────────────────
const _kVerde     = Color(0xFF95C01F);
const _kVerdeDark = Color(0xFF6E8E16);
const _kCardDark  = Color(0xFF1E1E1E);

// ═══════════════════════════════════════════════════════════════════════════

class ControllerTimerPos extends ChangeNotifier {
  int _timerPos = 0;
  int get timerPos => _timerPos;
  String _uuidPayment = '' ;
  String get uuidPayment => _uuidPayment;

  void setTimer(int t) {
    _timerPos = t;
    notifyListeners();
  }

  void setUUID(String uuid) {
    _uuidPayment = uuid;
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class PosModel extends ControllerTimerPos {
  final dynamic id;
  final String? idTerminalDojo;
  final String  title;
  final String  type;
  final String? ipAddress;
  final int?    port;
  final String? idTerminal;
  final String? ecrTerminal;
  final String? terminalBytes;
  final int?    useLegacy;

  PosModel({
    required this.id,
    this.idTerminalDojo,
    required this.title,
    required this.type,
    this.ecrTerminal,
    this.idTerminal,
    this.ipAddress,
    this.port,
    this.terminalBytes,
    this.useLegacy,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      "id":             id,
      "title":          title,
      "idTerminalDojo": idTerminalDojo,
      "type":           type,
      "ipAddress":      ipAddress,
      "port":           port,
      "idTerminal":     idTerminal,
      "ecrTerminal":    ecrTerminal,
      "terminalBytes":  terminalBytes,
      "useLegacy":      useLegacy,
    };
  }

  factory PosModel.fromJson(Map<String, Object?> json, String type) {
    return PosModel(
      id:             json['id'].toString(),
      title:          type == 'dojo' ? json['id'] as String : json['title'] as String,
      idTerminalDojo: type == 'dojo' ? json['id'] as String : null,
      type:           type,
      ipAddress:      json['ipAddress'] as String?,
      port:           json['port'] as int?,
      idTerminal:     json['idTerminal'] as String?,
      ecrTerminal:    json['ecrTerminal'] as String?,
      terminalBytes:  json['terminalBytes'] as String?,
      useLegacy:      json['useLegacy'] as int?,
    );
  }

  static Future<List<PosModel>> getPos() async {
    try {
      return [];
    } catch (err) {
      debugPrint(err.toString());
      return [];
    }
  }

  // ── Modal selezione POS ── SOSTITUITA ─────────────────────────────────────

  static Future<PosModel?> modalSelectedPos(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<PosModel?>(
      barrierDismissible: false,
      context: context,
      builder: (_) => _PosSelectionDialog(isDark: isDark),
    );
  }

  // ── Pagamento Dojo ────────────────────────────────────────────────────────

  static Future<Map<String,dynamic>> paymentDojo(
    PosModel pos, int amountCent, ControllerTimerPos ctrTimerPos) async {
    Map<String,dynamic> success = { 'success' : false , "UUID": '' };

    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");
      final idStore = prefs.getInt("idStore") ?? 0;
      String uuidPayment = Uuid().v4();
      ctrTimerPos.setUUID(uuidPayment);

      final respSendPaymentToDojoPos = await http.post(
        Uri.parse(
            "https://$istanza-api.qfood.it/api/v1/dojo/createPaymentIntent/646a9c26ae55"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":  "application/json",
        },
        body: jsonEncode({
          "internalReference": uuidPayment,
          "description":       "Payment ${amountCent.toString()}",
          "amount":            amountCent,
          "idTerminal":        pos.idTerminalDojo,
          "idStore":           idStore,
        }),
      );
      success['UUID'] = uuidPayment;
      final json = jsonDecode(respSendPaymentToDojoPos.body);
      if ( respSendPaymentToDojoPos.statusCode == 201 && json['success'] == true ) {
        do {
          try {
            http.Response respStatus = await http.get(
              Uri.parse(
                  'https://$istanza-api.qfood.it/api/v1/dojo/getStatusPaymentIntent/cc77f7187e38?internalReference=$uuidPayment&idStore=$idStore'),
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type":  "application/json",
              },
            );
            final jsonStatus = jsonDecode(respStatus.body);
            if (respStatus.statusCode == 200 &&
                jsonStatus['success'] == true) {
              if (jsonStatus['data']['IsCompleted'] == true) success["success"] = true;
              if (jsonStatus['data']['DojoTerminalSession']['status'] ==
                  'Canceled') success["success"] = null;
            }
          } catch (err) {
            success["success"] = null;
          }
          await Future.delayed(const Duration(seconds: 1));
          ctrTimerPos.setTimer(ctrTimerPos.timerPos + 1);
        } while (
            ctrTimerPos.timerPos < 50 &&
            success["success"] != null &&
            success["success"] != true);

        ctrTimerPos.setTimer(0);
      } else {
        success["success"] = false;
      }
    } catch (err) {
      success["success"] = false;
    } finally {
       return success;
    }
  }


    // ── STORNO Dojo ────────────────────────────────────────────────────────

  static Future<bool> refundDojo (
    String internalReference,
    double amount,
    ControllerTimerPos ctrTimerPos
  ) async {
    bool success = false;
    bool cancel  = false;
    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");
      final idStore = prefs.getInt("idStore") ?? 0;
      ctrTimerPos.setTimer(0);
      final respSendPaymentToDojoPos = await http.get(
        Uri.parse(
            "https://$istanza-api.qfood.it/api/v1/dojo/refundTransaction/0a070ee587ce?internalReference=${internalReference}&idStore=${idStore}&amount=${amount}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":  "application/json",
        },
      );
      final json = jsonDecode(respSendPaymentToDojoPos.body);
      if ( respSendPaymentToDojoPos.statusCode == 200 && json['success'] == true) {
        do {
          try {
            http.Response respStatus = await http.get(
              Uri.parse(
                  'https://$istanza-api.qfood.it/api/v1/dojo/getStatusPaymentIntent/cc77f7187e38?internalReference=$internalReference&idStore=$idStore'),
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type":  "application/json",
              },
            );
            final jsonStatus = jsonDecode(respStatus.body);
            if (respStatus.statusCode == 200 && jsonStatus['success'] == true && jsonStatus['data']['isRefunded'] == true) success = true;
            if (respStatus.statusCode == 200 && jsonStatus['success'] == true && jsonStatus['data']['IsCanceled'] == true){
              success = true;
              cancel  = true;
            } 
          } catch (err) {
            success = false;
          }
          await Future.delayed(const Duration(seconds: 1));
          ctrTimerPos.setTimer(ctrTimerPos.timerPos + 1);
        } while ( ( ctrTimerPos.timerPos < 30 &&  success != true ) );
           ctrTimerPos.setTimer(0);
      }else{
        success = false;
      }
      }catch (err) {
        success = false;
      } finally {
        if( cancel )
          success = false;
          SnackBarForcedClosure('Rimborso annullato', Colors.red);
        return success;
      }
    }

      // ── STORNO Dojo ────────────────────────────────────────────────────────

  static Future<bool> trashPaymentDojo (
    String internalReference,
  ) async {
    bool success = true;

    try {
      final prefs   = await SharedPreferences.getInstance();
      final istanza = prefs.getString("istanza");
      final token   = prefs.getString("token");
      final idStore = prefs.getInt("idStore") ?? 0;

      final respSendPaymentToDojoPos = await http.get(
        Uri.parse(
            "https://$istanza-api.qfood.it/api/v1/dojo/cancelSession/95d56d6bc488?internalReference=${internalReference}&idStore=${idStore}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":  "application/json",
        },
      );
      final json = jsonDecode(respSendPaymentToDojoPos.body);
      if ( respSendPaymentToDojoPos.statusCode == 201 && json['success'] == true) {
     
           
      }else{
        success = false;
      }
      }catch (err) {
        success = false;
      } finally {
        return success;
      }
    }

  // ── Pagamento ECR17 ───────────────────────────────────────────────────────

  static Future<Map<String,dynamic>> paymentEcr17(
    PosModel pos, double amount, ControllerTimerPos ctrTimerPos) async {
    Map<String,dynamic> success = { 'success' : false , "UUID": '' };
    try {
      MbP17 instance = MbP17(pos.idTerminal ?? '00000001', pos.ecrTerminal ?? '00088105');
      bool connected = await instance.openConnection( pos.ipAddress ?? '192.168.1.34', 9100 );
      if (connected) {
        bool worksOn = true;
        await instance.payAndWait(
          timeout:       50,
          amount:        amount,
          useLegacy:     pos.useLegacy == 1,
          printerFooter: false,
          onTimeout: () async { worksOn = false; },
          paymentFailed: () async { worksOn = false; },
          paymentDone: (String? output) {
            success['success']  = true;
            worksOn  = false;
          },
        );
        while (worksOn) {
          debugPrint("Running POS ECR17");
          ctrTimerPos.setTimer(ctrTimerPos.timerPos + 1);
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } catch (err) {
      success['success'] = false;
    }
    return success;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _PosSelectionDialog
// ═══════════════════════════════════════════════════════════════════════════

class _PosSelectionDialog extends StatefulWidget {
  final bool isDark;
  const _PosSelectionDialog({required this.isDark});

  @override
  State<_PosSelectionDialog> createState() => _PosSelectionDialogState();
}

class _PosSelectionDialogState extends State<_PosSelectionDialog> {
  PosModel? _hovered;

  IconData _iconForType(String type) {
    switch (type) {
      case 'dojo': return Icons.contactless_rounded;
      case 'p17':  return Icons.point_of_sale_rounded;
      default:     return Icons.payment_rounded;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'dojo': return 'Dojo';
      case 'p17':  return 'P17';
      default:     return type.toUpperCase();
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'dojo': return const Color(0xFF3B82F6);
      case 'p17':  return _kVerde;
      default:     return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg        = widget.isDark ? _kCardDark : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(widget.isDark ? 0.5 : 0.15),
              blurRadius: 32,
              offset:     const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header verde ─────────────────────────────────────────
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                color: _kVerde.withOpacity(widget.isDark ? 0.12 : 0.06),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        _kVerde.withOpacity(
                          widget.isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        color: _kVerde, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seleziona dispositivo',
                          style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w800,
                            color:      textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${posGlobal.length} dispositiv${posGlobal.length == 1 ? 'o disponibile' : 'i disponibili'}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        _kVerde.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(
                          color: _kVerde.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${posGlobal.length}',
                      style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color:      _kVerdeDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Lista POS ─────────────────────────────────────────────
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: posGlobal.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.devices_other_rounded,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'Nessun dispositivo trovato',
                            style: TextStyle(
                                fontSize:   13,
                                color:      Colors.grey.shade500,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      itemCount:        posGlobal.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final p     = posGlobal[i];
                        final color = _colorForType(p.type);
                        final isHov = _hovered == p;

                        return MouseRegion(
                          onEnter:  (_) => setState(() => _hovered = p),
                          onExit:   (_) => setState(() => _hovered = null),
                          cursor:   SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              posSelected = p;
                              Navigator.pop(context, p);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isHov
                                    ? color.withOpacity(
                                        widget.isDark ? 0.12 : 0.07)
                                    : (widget.isDark
                                        ? const Color(0xFF272727)
                                        : const Color(0xFFF8F8F6)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHov
                                      ? color.withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.15),
                                  width: isHov ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(
                                          widget.isDark ? 0.2 : 0.1),
                                      borderRadius:
                                          BorderRadius.circular(9),
                                    ),
                                    child: Icon(_iconForType(p.type),
                                        color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.title,
                                          style: TextStyle(
                                            fontSize:   13,
                                            fontWeight: FontWeight.w700,
                                            color:      textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _labelForType(p.type),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedSlide(
                                    duration: const Duration(milliseconds: 180),
                                    offset: isHov
                                        ? Offset.zero
                                        : const Offset(-0.3, 0),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                          milliseconds: 180),
                                      opacity: isHov ? 1.0 : 0.0,
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size:  14,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Bottone Annulla ───────────────────────────────────────
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon:  const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Annulla',
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
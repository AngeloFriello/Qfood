import 'package:dashboard/modelli/customer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../checkout/cliente/InserisciClienteVista.dart';
import '../filtri/prenotazioni_controller_filtri.dart';
import '../model/model_prenotazione.dart';
import '../model/prenotazione_channel.dart';
import '../model/prenotazione_stato.dart';
import 'assegna_tavoli/assegna_tavolo_page.dart';

class NuovaPrenotazionePage extends StatefulWidget {

  final Prenotazione? prenotazione;
  const NuovaPrenotazionePage({
  super.key,
  this.prenotazione,
  });

  @override
  State<NuovaPrenotazionePage> createState() =>
      _NuovaPrenotazionePageState();
}

class _NuovaPrenotazionePageState extends State<NuovaPrenotazionePage> {
  DateTime? data;
  String? orario;
  String? durata;
  PrenotazioneStato? stato;
  int? pax;
  CustomerModel? clienteSelezionato;
  final _nomeCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? note;

  bool _isEdit = false;
  String? tavoloAssegnato;
  List<int> tavoliAgganciati = [];

  final _noteCtrl = TextEditingController();



  PrenotazioneChannel channel = PrenotazioneChannel.manuale;


  @override
  void initState() {
    super.initState();

    final p = widget.prenotazione;
    if (p != null) {
      _isEdit = true;

      // PRENOTAZIONE
      data = p.data;
      pax = p.pax;
      stato = p.stato;
      channel = p.channel;
      orario = _formatTimeOfDay(p.orario);
      durata = _durataLabel(p.durata);
      tavoliAgganciati = List.from(p.tavoli);

      // NOTE
      note = p.note;
      _noteCtrl.text = p.note ?? '';

      // CLIENTE
      clienteSelezionato = CustomerModel(
        id: p.clienteId > 0 ? p.clienteId : 0,
        title: p.clienteNome,
        businessPhone: p.telefono ?? '',
        businessEmail: p.email,
      );

      //POPOLA CAMPI UI
      _nomeCtrl.text = p.clienteNome;
      _telefonoCtrl.text = p.telefono ?? '';
      _emailCtrl.text = p.email ?? '';
    }
  }


  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _durataLabel(Duration d) {
    switch (d.inMinutes) {
      case 30:
        return '30 minuti';
      case 60:
        return '1 ora';
      case 90:
        return '1 ora e mezza';
      case 120:
        return '2 ore';
      case 150:
        return '2 ore e mezza';
      default:
        return '3 ore';
    }
  }

  // ==========================
  // DATA
  // ==========================

  final List<String> orari = List.generate(60, (i) {
    final totalMinutes = (9 * 60) + (i * 15);
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  });

  final List<String> durate = const [
    '30 minuti',
    '1 ora',
    '1 ora e mezza',
    '2 ore',
    '2 ore e mezza',
    '3 ore',
  ];

  // ==========================
  // CLIENTE
  // ==========================

  void apriSelezionaCliente() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 820,
          height: 920,
          child: Material(
            color: Colors.transparent,
            child: InserisciClienteSheet(
              onSelect: (cliente) {
                setState(() {
                  clienteSelezionato   = cliente;
                  _nomeCtrl.text       = cliente.titleCustomer;
                  _telefonoCtrl.text   = cliente.personalPhone ?? cliente.businessPhone ?? '';
                  _emailCtrl.text      = cliente.businessEmail ?? cliente.personalEmail ?? '';
                });
                Navigator.pop(ctx);
              },

            ),
          ),
        ),
      ),
    );
  }

  // ==========================
  // INVIO PRENOTAZIONE
  // ==========================

  Future<void> _submit() async {
    final nome = _nomeCtrl.text.trim();

    if (data == null ||
        orario == null ||
        durata == null ||
        stato == null ||
        pax == null ||
        pax! <= 0 ||
        nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi obbligatori')),
      );
      return;
    }


    final parts = orario!.split(':');
    final time = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final durataMap = {
      '30 minuti': const Duration(minutes: 30),
      '1 ora': const Duration(hours: 1),
      '1 ora e mezza': const Duration(hours: 1, minutes: 30),
      '2 ore': const Duration(hours: 2),
      '2 ore e mezza': const Duration(hours: 2, minutes: 30),
      '3 ore': const Duration(hours: 3),
    };

    final telefono = _telefonoCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    final prenotazione = Prenotazione(
      id: widget.prenotazione?.id ?? DateTime.now().millisecondsSinceEpoch,

      data: DateTime(data!.year, data!.month, data!.day),
      orario: time,
      durata: durataMap[durata]!,
      pax: pax!,


      clienteId: 0,//clienteSelezionato!.id ?? 0,

      clienteNome: _nomeCtrl.text.trim(),
      telefono: telefono.isNotEmpty ? telefono : null,
      email: email.isNotEmpty ? email : null,

      stato: stato!,
      channel: channel,
      sala: 'TAVOLI',
      tavoli: List.from(tavoliAgganciati),
      note: note,

    );




    final ctrl = context.read<PrenotazioniController>();


    if (widget.prenotazione == null) {
      await ctrl.add(prenotazione);     // aTTENDI API + DB
    } else {
      await ctrl.update(prenotazione);  // ATTENDI API + DB
    }

    if (mounted) {
      setState(() {
        clienteSelezionato = null;

        //reset campi testo
        _nomeCtrl.clear();
        _telefonoCtrl.clear();
        _emailCtrl.clear();

        //reset prenotazione
        tavoliAgganciati.clear();
        data = null;
        orario = null;
        durata = null;
        pax = null;
        stato = null;
        channel = PrenotazioneChannel.manuale;
      });

      Navigator.of(context).pop();
    }


  }


  void _delete() {
    final p = widget.prenotazione;
    if (p == null) return;

    context.read<PrenotazioniController>().remove(p.id);
    Navigator.of(context).pop();
  }


  // UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final canAssignTable =
        data != null && orario != null && durata != null;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF2F4EC);
    final cardBg =
    isDark ? const Color(0xFF1E201B) : const Color(0xFFE6EAD6);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFF97D700),
        foregroundColor: Colors.white,
        title: const Text(
          'Nuova prenotazione',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _SectionCard(
              title: 'Prenotazione',

              bg: cardBg,
              children: [
                // ===== RIGA 1: Data | Orario | Pax =====
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DateWheelPickerField(
                        label: 'Data',
                        value: data,
                        onChanged: (v) => setState(() {
                          data = v;
                        }),


                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _DropdownField<String>(
                        label: 'Orario',
                        value: orario,
                        items: orari,
                        onChanged: (v) => setState(() => orario = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _NumberField(
                        label: 'Persone',
                        onChanged: (v) => pax = int.tryParse(v),
                      ),
                    ),


                  ],
                ),

                // Stato | Durata
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DropdownField<PrenotazioneStato>(
                        label: 'Stato prenotazione',
                        value: stato,
                        items: PrenotazioneStato.values,
                        itemLabel: (s) => s.label,
                        onChanged: (v) => setState(() => stato = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _DropdownField<String>(
                        label: 'Durata',
                        value: durata,
                        items: durate,
                        onChanged: (v) => setState(() => durata = v),
                      ),
                    ),
                    const Spacer(flex: 1), // mantiene griglia allineata
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            _SectionCard(
              title: 'Info cliente',
              bg: cardBg,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Expanded(
                      flex: 3,
                      child: _TextField(
                        label: 'Cliente',
                        controller: _nomeCtrl,
                      ),

                    ),

                    const SizedBox(width: 12),

                    // ===== CERCA / CANCELLA =====
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SizedBox(
                        height: 56,
                        width: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (clienteSelezionato != null) {
                              setState(() {
                                clienteSelezionato = null;
                                _nomeCtrl.clear();
                                _telefonoCtrl.clear();
                                _emailCtrl.clear();
                              });
                            } else {
                              apriSelezionaCliente();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: clienteSelezionato != null
                                ? Colors.red.shade700
                                : const Color(0xFF97D700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Icon(
                            clienteSelezionato != null
                                ? Icons.close
                                : Icons.search,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ===== TELEFONO =====
                    Expanded(
                      flex: 2,
                      child: _TextField(
                        label: 'Telefono',
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                      ),

                    ),
                  ],
                ),

                // ===== EMAIL =====
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        label: 'E-mail',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),

                    ),
                  ],
                ),
              ],
            ),


            const SizedBox(height: 20),

            _SectionCard(
              title: 'Assegna tavolo',
              bg: cardBg,
              children: [
                // ================== RIGA TAVOLO ==================
                Row(
                  children: [
                    Expanded(
                      child: _ReadonlyField(
                        label: 'Tavoli',
                        value: tavoliAgganciati.isEmpty
                            ? 'Non assegnato'
                            : tavoliAgganciati.join(', '),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SizedBox(
                        height: 56,
                        width: 56,
                        child: ElevatedButton(
                          onPressed: canAssignTable
                              ? () async {
                            // ⏱ costruzione DateTime completi
                            final parts = orario!.split(':');
                            final start = DateTime(
                              data!.year,
                              data!.month,
                              data!.day,
                              int.parse(parts[0]),
                              int.parse(parts[1]),
                            );

                            final durataMap = {
                              '30 minuti':
                              const Duration(minutes: 30),
                              '1 ora': const Duration(hours: 1),
                              '1 ora e mezza':
                              const Duration(hours: 1, minutes: 30),
                              '2 ore': const Duration(hours: 2),
                              '2 ore e mezza':
                              const Duration(hours: 2, minutes: 30),
                              '3 ore': const Duration(hours: 3),
                            };

                            final end =
                            start.add(durataMap[durata]!);

                            final prenotazioni = context
                                .read<PrenotazioniController>()
                                .tutte;

                            final result =
                            await Navigator.of(context)
                                .push<List<int>>(
                              MaterialPageRoute(
                                builder: (_) => AssegnaTavoloPage(
                                  startDateTime: start,
                                  endDateTime: end,
                                  pax:
                                  widget.prenotazione?.pax ??
                                      pax ??
                                      1,
                                  prenotazioni: prenotazioni,
                                  prenotazioneInModificaId:
                                  widget.prenotazione?.id,
                                  tavoliGiaSelezionati:
                                  tavoliAgganciati,
                                ),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                tavoliAgganciati = result;
                              });
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAssignTable
                                ? (isDark
                                ? const Color(0xFF97D700)
                                : const Color(0xFF2E4D00))
                                : Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ================== LISTA TAVOLI ==================
                if (tavoliAgganciati.isNotEmpty) ...[
                  const SizedBox(height: 14),

                  Column(
                    children: [
                      // ========= TAVOLO PRINCIPALE =========
                      _buildTavoloRow(
                        isDark: isDark,
                        label: 'Tavolo principale',
                        tavolo: tavoliAgganciati.first,
                        showRemove: false,
                      ),

                      const SizedBox(height: 8),

                      // ========= TAVOLI AGGANCIATI =========
                      ...tavoliAgganciati.skip(1).map((tavolo) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildTavoloRow(
                            isDark: isDark,
                            label: 'Tavolo agganciato',
                            tavolo: tavolo,
                            showRemove: true,
                            onRemove: () {
                              setState(() {
                                tavoliAgganciati.remove(tavolo);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ],
            ),


            const SizedBox(height: 20),


            _SectionCard(
              title: 'Channel',
              bg: cardBg,
              children: [
                Row(
                  children: [
                    _ChannelRadio(
                      label: 'Manuale',
                      value: PrenotazioneChannel.manuale,
                      groupValue: channel,
                      onChanged: (v) => setState(() => channel = v),
                    ),
                    const SizedBox(width: 24),
                    _ChannelRadio(
                      label: 'Qfood',
                      value: PrenotazioneChannel.flood,
                      groupValue: channel,
                      onChanged: (v) => setState(() => channel = v),
                    ),
                    const SizedBox(width: 24),
                    _ChannelRadio(
                      label: 'Google',
                      value: PrenotazioneChannel.google,
                      groupValue: channel,
                      onChanged: (v) => setState(() => channel = v),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),


            _SectionCard(
              title: 'Note',
              bg: cardBg,
              children: [
                _NoteField(
                  label: 'Note',
                  controller: _noteCtrl,
                  onChanged: (v) => note = v,
                ),



              ],
            ),



          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF97D700),
          ),
          child: Row(
            children: [
              // ELIMINA
              if (widget.prenotazione != null)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Elimina'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade300,
                  ),
                ),

              const Spacer(),

              // ANNULLA
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annulla',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),


              const SizedBox(width: 12),

              // STAMPA
              if (widget.prenotazione != null)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO stampa
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Stampa'),
                ),

              const SizedBox(width: 12),

              // SALVA
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(
                  Icons.check,
                  size: 22,
                ),
                label: const Text(
                  'Salva',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),

    );
  }
}


class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _TextField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16),
          filled: true,
          fillColor: isDark ? const Color(0xFF2A2B26) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}


Widget _buildTavoloRow({
  required bool isDark,
  required String label,
  required int tavolo,
  bool showRemove = false,
  VoidCallback? onRemove,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.table_restaurant, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const Spacer(),
        Text(
          '#$tavolo',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        if (showRemove) ...[
          const SizedBox(width: 12),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 18,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    ),
  );
}



class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color bg;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}



class _NoteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NoteField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: 4,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          filled: true,
          fillColor:
          isDark ? const Color(0xFF2A2B26) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}


class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? itemLabel;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value != null && items.contains(value) ? value : null,

        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),

        items: items
            .toSet()
            .map(
              (e) => DropdownMenuItem<T>(
            value: e,
            child: Text(
              itemLabel?.call(e) ?? e.toString(),
              style: TextStyle(
                fontSize: 18,

                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        )
            .toList(),

        onChanged: onChanged,

        decoration: InputDecoration(
          labelText: label,

          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),

          filled: true,
          fillColor: isDark ? const Color(0xFF2A2B26) : Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2A2B26) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}



class _ReadonlyField extends StatelessWidget {
  final String label;
  final String? value;

  const _ReadonlyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor:
          isDark ? const Color(0xFF2A2B26) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(
          value ?? '--',
          style: TextStyle(
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}



class _BaseField extends StatelessWidget {
  final String label;
  final String? text;
  final IconData? icon;
  final VoidCallback? onTap;
  final TextStyle? textStyle;

  const _BaseField({
    required this.label,
    this.text,
    this.icon,
    this.onTap,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2B26) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: icon != null ? Icon(icon) : null,
          ),
          child: Text(
            text ?? '--',
            style: textStyle ??
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
          ),
        ),
      ),
    );
  }
}


class _ChannelRadio extends StatelessWidget {
  final String label;
  final PrenotazioneChannel value;
  final PrenotazioneChannel groupValue;
  final ValueChanged<PrenotazioneChannel> onChanged;

  const _ChannelRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<PrenotazioneChannel>(
            value: value,
            groupValue: groupValue,
            onChanged: (v) => onChanged(v!),
            activeColor: const Color(0xFF97D700),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}


class _DateWheelPickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const _DateWheelPickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseField(
      label: label,
      text: value != null
          ? DateFormat('dd MMM yyyy', 'it_IT').format(value!)
          : 'Seleziona',
      icon: Icons.calendar_today,
      onTap: () => _openPicker(context),
    );
  }

  void _openPicker(BuildContext context) {
    final initial = value ?? DateTime.now();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Center(
        child: _DayMonthYearPickerDialog(
          initialDate: initial,
          onConfirm: onChanged,
        ),
      ),
    );
  }
}





class _DayMonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onConfirm;

  const _DayMonthYearPickerDialog({
    required this.initialDate,
    required this.onConfirm,
  });

  @override
  State<_DayMonthYearPickerDialog> createState() =>
      _DayMonthYearPickerDialogState();
}

class _DayMonthYearPickerDialogState
    extends State<_DayMonthYearPickerDialog> {
  late int day;
  late int month;
  late int year;

  final years = List.generate(12, (i) => DateTime.now().year + i);

  @override
  void initState() {
    super.initState();
    day = widget.initialDate.day;
    month = widget.initialDate.month;
    year = widget.initialDate.year;

  }

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  void _confirm() {
    widget.onConfirm(DateTime(year, month, day));
    Navigator.pop(context);
  }




  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        height: 320,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2E4D00),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla',

                        style: TextStyle(color: Colors.white)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _confirm,
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PICKER
            Expanded(
              child: Row(
                children: [
                  _wheel(
                    count: daysInMonth,
                    initial: day - 1,
                    onChanged: (v) => setState(() => day = v + 1),
                    builder: (i) => '${i + 1}',
                  ),
                  _wheel(
                    count: 12,
                    initial: month - 1,
                    onChanged: (v) => setState(() => month = v + 1),
                    builder: (i) =>
                        DateFormat.MMMM('it_IT')
                            .format(DateTime(0, i + 1)),
                  ),
                  _wheel(
                    count: years.length,
                    initial: years.indexOf(year),
                    onChanged: (v) =>
                        setState(() => year = years[v]),
                    builder: (i) => '${years[i]}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel({
    required int count,
    required int initial,
    required ValueChanged<int> onChanged,
    required String Function(int) builder,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController:
        FixedExtentScrollController(initialItem: initial),
        itemExtent: 42,
        onSelectedItemChanged: onChanged,
        children: List.generate(
          count,
              (i) => Center(
            child: Text(
              builder(i),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



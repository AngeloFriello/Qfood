

import 'package:dashboard/ui/screen/ordini/models/ordine_tipo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../state/controller_carrello.dart';
import '../../../checkout/cliente/InserisciClienteVista.dart';
import 'package:provider/provider.dart';

class InserisciOrdineSheet extends StatefulWidget {
  final OrdineTipo? ordineTipo;

  const InserisciOrdineSheet({
    required this.ordineTipo,
    super.key,
  });

  @override
  State<InserisciOrdineSheet> createState() => InserisciOrdineSheetState();
}

class InserisciOrdineSheetState extends State<InserisciOrdineSheet> {
  late final TextEditingController telefonoCtrl;
  late final TextEditingController indirizzoCtrl;
  late final TextEditingController callerPagerCtrl;
  late final TextEditingController noteCtrl;
  late final TextEditingController nomeClienteCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // ⚠️ Usa didChangeDependencies invece di initState per accedere al Provider.
      // In release mode context.read in initState può fallire.
      final carrello = context.read<CarrelloController>();
      if (widget.ordineTipo != null) {
        carrello.setTipoOrdine(labelTipoOrdine(widget.ordineTipo!));
      }
      telefonoCtrl    = TextEditingController(text: carrello.phoneNumber);
      indirizzoCtrl   = TextEditingController(text: carrello.addressOrder);
      callerPagerCtrl = TextEditingController(text: carrello.callerPager);
      noteCtrl        = TextEditingController(text: carrello.note);
      nomeClienteCtrl = TextEditingController(text: carrello.nomeClienteOrdine);
    }
  }

  @override
  void dispose() {
    telefonoCtrl.dispose();
    indirizzoCtrl.dispose();
    callerPagerCtrl.dispose();
    noteCtrl.dispose();
    nomeClienteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: LayoutBuilder(
              builder: (_, constraints) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Header(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        // ⚠️ NIENTE const: _Body usa context.watch() e deve poter
                        // rebuild quando CarrelloController emette notifyListeners().
                        child: _Body(
                          telefonoCtrl    : telefonoCtrl,
                          indirizzoCtrl   : indirizzoCtrl,
                          callerPagerCtrl : callerPagerCtrl,
                          noteCtrl        : noteCtrl,
                          nomeClienteCtrl : nomeClienteCtrl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    _Footer(
                      telefonoCtrl    : telefonoCtrl,
                      indirizzoCtrl   : indirizzoCtrl,
                      callerPagerCtrl : callerPagerCtrl,
                      noteCtrl        : noteCtrl,
                      nomeClienteCtrl : nomeClienteCtrl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A00) : const Color(0xFF97D700),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),   // ✅ context locale corretto
          ),
          const SizedBox(width: 8),
          const Text(
            'Inserisci ordine',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final TextEditingController telefonoCtrl;
  final TextEditingController indirizzoCtrl;
  final TextEditingController callerPagerCtrl;
  final TextEditingController noteCtrl;
  final TextEditingController nomeClienteCtrl;

  // ⚠️ NON const: usa context.watch<CarrelloController>() e in release mode
  // i widget const possono essere riusati come istanza Element e NON
  // ricostruirsi quando il provider notifica.
  // ignore: prefer_const_constructors_in_immutables
  _Body({
    required this.telefonoCtrl,
    required this.indirizzoCtrl,
    required this.callerPagerCtrl,
    required this.noteCtrl,
    required this.nomeClienteCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final carrello = context.watch<CarrelloController>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _EditableField(label: 'Nome cliente', controller: nomeClienteCtrl),
          _ClienteField(
            telefonoCtrl  : telefonoCtrl,
            indirizzoCtrl : indirizzoCtrl,
          ),
          // ⚠️ NON const: usano context.watch()
          _TipoField(),
          _Paid(),
          _DataOraField(),
          _EditableField(label: 'Telefono', controller: telefonoCtrl),
          carrello.tipoOrdine == 'delivery'
              ? _EditableField(label: 'Indirizzo',      controller: indirizzoCtrl)
              : _EditableField(label: 'Caller / Pager', controller: callerPagerCtrl),
          _EditableField(label: 'Note', controller: noteCtrl, maxLines: 3),
        ],
      ),
    );
  }
}

// ── Cliente ───────────────────────────────────────────────────────────────────

// 🔥 STATEFUL con listener ESPLICITO: funziona garantito anche in release
// perché non dipende da InheritedWidget subscription che può fallire.
class _ClienteField extends StatefulWidget {
  final TextEditingController telefonoCtrl;
  final TextEditingController indirizzoCtrl;

  const _ClienteField({
    required this.telefonoCtrl,
    required this.indirizzoCtrl,
  });

  @override
  State<_ClienteField> createState() => _ClienteFieldState();
}

class _ClienteFieldState extends State<_ClienteField> {
  late final CarrelloController _carrello;

  @override
  void initState() {
    super.initState();
    // Non possiamo leggere Provider qui in initState
    // Lo faremo in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ottieni il controller e aggiungi listener ESPLICITO
    _carrello = context.read<CarrelloController>();
    _carrello.addListener(_onCarrelloChanged);
  }

  @override
  void dispose() {
    // Rimuovi listener per evitare memory leak
    _carrello.removeListener(_onCarrelloChanged);
    super.dispose();
  }

  // 🔥 Questo viene chiamato ogni volta che notifyListeners() viene emesso
  void _onCarrelloChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild quando il cliente cambia
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = _carrello.cliente;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _ReadOnlyField(
              label: 'Cliente',
              // ✅ titleCustomer: usa businessName oppure firstname+lastname.
              // Il campo raw `title` è spesso null nel DB.
              value: cliente?.titleCustomer ?? '',
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: cliente != null ? Colors.red : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (cliente != null) {
                    _carrello.clearCliente();
                  } else {
                    _apriSelezioneCliente();
                  }
                },
                child: Icon(
                  cliente != null ? Icons.delete : Icons.search,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _apriSelezioneCliente() {
    // 🔥 Usa _carrello che è già memorizzato nella State
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: 820,
            height: 920,
            child: InserisciClienteSheet(
              onSelect: (cliente) {
                final telefono  = cliente.personalPhone   ?? cliente.businessPhone    ?? '';
                final indirizzo = cliente.personalAddress ?? cliente.businessAddress  ?? '';

                // 1) Aggiorna i TextEditingController
                widget.telefonoCtrl.text  = telefono;
                widget.indirizzoCtrl.text = indirizzo;

                // 2) Chiudi il dialog
                Navigator.pop(dialogCtx);

                // 3) Update atomico DOPO la chiusura
                // Il listener _onCarrelloChanged trigghera automaticamente setState
                _carrello.setClienteWithContacts(
                  cliente  : cliente,
                  telefono : telefono,
                  indirizzo: indirizzo,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Tipo ordine ───────────────────────────────────────────────────────────────

class _TipoField extends StatelessWidget {
  // ⚠️ NON const: usa context.watch()
  // ignore: prefer_const_constructors_in_immutables
  _TipoField();

  @override
  Widget build(BuildContext context) {
    final carrello = context.watch<CarrelloController>();

    return InkWell(
      onTap: () => _showTipoDialog(context),
      child: _ReadOnlyField(
        label: 'Tipo',
        value: carrello.tipoOrdine == 'delivery'
            ? 'Consegna'
            : carrello.tipoOrdine == 'eatHere'
                ? 'Mangia qui'
                : 'Ritiro',
        dropdown: true,
      ),
    );
  }

  void _showTipoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String? selected = context.read<CarrelloController>().tipoOrdine;

        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: const Text('Tipo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Consegna'),
                    value: 'delivery',
                    groupValue: selected,
                    activeColor: const Color(0xFF97D700),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  RadioListTile<String>(
                    title: const Text('Ritiro'),
                    value: 'takeAway',
                    groupValue: selected,
                    activeColor: const Color(0xFF97D700),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  RadioListTile<String>(
                    title: const Text('Mangia qui'),
                    value: 'eatHere',
                    groupValue: selected,
                    activeColor: const Color(0xFF97D700),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    if (selected != null) {
                      context.read<CarrelloController>().setTipoOrdine(selected);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Pagamento ─────────────────────────────────────────────────────────────────

class _Paid extends StatelessWidget {
  // ⚠️ NON const: usa context.watch()
  // ignore: prefer_const_constructors_in_immutables
  _Paid();

  @override
  Widget build(BuildContext context) {
    final carrello = context.watch<CarrelloController>();

    return InkWell(
      onTap: () => _showPaidDialog(context),
      child: _ReadOnlyField(
        label: 'Pagamento',
        value: carrello.orderPaid == 1 ? 'Pagato' : 'Da pagare',
        dropdown: true,
      ),
    );
  }

  void _showPaidDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        int paid = context.read<CarrelloController>().orderPaid;

        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: const Text('Stato pagamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int>(
                    title: const Text('Pagato'),
                    value: 1,
                    groupValue: paid,
                    activeColor: const Color(0xFF97D700),
                    onChanged: (v) => setState(() => paid = v!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Da pagare'),
                    value: 0,
                    groupValue: paid,
                    activeColor: const Color(0xFF97D700),
                    onChanged: (v) => setState(() => paid = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<CarrelloController>().setPaid(paid);
                    Navigator.pop(ctx);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final TextEditingController telefonoCtrl;
  final TextEditingController indirizzoCtrl;
  final TextEditingController callerPagerCtrl;
  final TextEditingController noteCtrl;
  final TextEditingController nomeClienteCtrl;

  const _Footer({
    required this.telefonoCtrl,
    required this.indirizzoCtrl,
    required this.callerPagerCtrl,
    required this.noteCtrl,
    required this.nomeClienteCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A00) : const Color(0xFF97D700),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),  // ✅ context locale
            child: const Text(
              'Annulla',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6EF0C2),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final carrello = context.read<CarrelloController>();
              carrello.phoneNumber  = telefonoCtrl.text;
              carrello.addressOrder = indirizzoCtrl.text;
              carrello.callerPager  = callerPagerCtrl.text;
              carrello.setNomeCLiente(nomeClienteCtrl.text);
              carrello.setNote(noteCtrl.text);
              carrello.inOrder = true;
              Navigator.pop(context);   // ✅ chiude il dialog dopo conferma
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }
}

// ── Campi ─────────────────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final bool dropdown;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.dropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withOpacity(.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value)),
                if (dropdown) const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _EditableField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data e ora ────────────────────────────────────────────────────────────────

String _mese(int m) {
  const mesi = [
    'gen','feb','mar','apr','mag','giu',
    'lug','ago','set','ott','nov','dic',
  ];
  return mesi[m - 1];
}

class _DataOraField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final carrello = context.watch<CarrelloController>();
    final data     = carrello.dataOrdine ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data e ora'),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _openDateTimePicker(context, data),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withOpacity(.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                '${data.day.toString().padLeft(2, '0')} '
                '${_mese(data.month)} '
                '${data.year}  '
                '${data.hour.toString().padLeft(2, '0')}:'
                '${data.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDateTimePicker(BuildContext context, DateTime initial) {
    final carrello  = context.read<CarrelloController>();
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final focusNode = FocusNode();
    DateTime temp   = initial;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {              // ✅ ctx separato
        return RawKeyboardListener(
          focusNode: focusNode,
          autofocus: true,
          onKey: (event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                carrello.setDataOrdine(temp);
                Navigator.pop(dialogCtx); // ✅ usa dialogCtx
              }
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(dialogCtx);
              }
            }
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Center(
              child: Container(
                width: 380,
                height: 280,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A00)
                            : const Color(0xFF97D700),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text(
                              'Annulla',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              carrello.setDataOrdine(temp);
                              Navigator.pop(dialogCtx);
                            },
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          brightness: isDark ? Brightness.dark : Brightness.light,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              fontSize: 20,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          initialDateTime: initial,
                          mode: CupertinoDatePickerMode.dateAndTime,
                          use24hFormat: true,
                          onDateTimeChanged: (v) => temp = v,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
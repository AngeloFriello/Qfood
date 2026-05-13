import 'package:dashboard/Global.dart';
import 'package:dashboard/app/service/service_log_pos.dart';
import 'package:dashboard/modelli/pos.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../state/controller_impostazioni.dart';

// ═══════════════════════════════════════════════════════════════════════════
// COSTANTI
// ═══════════════════════════════════════════════════════════════════════════

const _kVerde     = Color(0xFF95C01F);
const _kVerdeDark = Color(0xFF6E8E16);
const _kBgLight   = Color(0xFFF7F7F2);
const _kBgDark    = Color(0xFF111111);
const _kCardDark  = Color(0xFF1E1E1E);
const _kRed       = Color(0xFFEF4444);

// ═══════════════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════════════

class ElectronicPayment {
  final int?    id;
  final int     idDocument;
  final String  posType;
  final double  amount;
  final String? paymentIdentifier;
  final String? dataDevice;
  final String? createdDate;
  final int     refund;

  const ElectronicPayment({
    this.id,
    required this.idDocument,
    required this.posType,
    required this.amount,
    required this.refund,
    this.paymentIdentifier,
    this.dataDevice,
    this.createdDate,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'idDocument':         idDocument,
    'posType':            posType,
    'amount':             amount,
    'payment_identifier': paymentIdentifier,
    'data_device':        dataDevice,
    'refund'     :        refund,
    if (createdDate != null) 'created_date': createdDate,
  };

  factory ElectronicPayment.fromMap(Map<String, dynamic> map) =>
      ElectronicPayment(
        id:                 map['id'] as int?,
        idDocument:         map['idDocument'] as int,
        posType:            map['posType'] as String,
        amount:             (map['amount'] as num).toDouble(),
        paymentIdentifier:  map['payment_identifier'] as String?,
        dataDevice:         map['data_device'] as String?,
        createdDate:        map['created_date'] as String?,
        refund:             map['refund'] as int,
      );

  @override
  String toString() =>
      'ElectronicPayment(id: $id, idDocument: $idDocument, '
      'posType: $posType, amount: $amount, createdDate: $createdDate)';
}

// ═══════════════════════════════════════════════════════════════════════════
// DAO
// ═══════════════════════════════════════════════════════════════════════════

class ElectronicPaymentDao {
  static const String _table = 'electronic_payments';
  final Database db;

  const ElectronicPaymentDao(this.db);

  Future<int> insert(ElectronicPayment payment) async =>
      db.insert(_table, payment.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort);

  Future<List<ElectronicPayment>> getByDay(DateTime day) async {
    final prefix =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}%';
    final rows = await db.query(_table,
        where: 'created_date LIKE ?',
        whereArgs: [prefix],
        orderBy: 'created_date ASC');
    return rows.map(ElectronicPayment.fromMap).toList();
  }

  Future<List<ElectronicPayment>> getByDateRange(
    DateTime from, DateTime to) async {
    final fromStr      = _toIsoUtc(from.toUtc());
    final toNormalized = DateTime.utc(to.year, to.month, to.day, 23, 59, 59);
    final toStr        = _toIsoUtc(toNormalized);
    final rows = await db.query(_table,
        where: 'created_date BETWEEN ? AND ?',
        whereArgs: [fromStr, toStr],
        orderBy: 'created_date ASC');
    return rows.map(ElectronicPayment.fromMap).toList();
  }

  Future<List<ElectronicPayment>> getByDocument(int idDocument) async {
    final rows = await db.query(_table,
        where: 'idDocument = ?',
        whereArgs: [idDocument],
        orderBy: 'created_date DESC');
    return rows.map(ElectronicPayment.fromMap).toList();
  }

  String _toIsoUtc(DateTime utc) =>
      '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}T'
      '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}:'
      '${utc.second.toString().padLeft(2, '0')}Z';
}



// ═══════════════════════════════════════════════════════════════════════════
// PAGINA
// ═══════════════════════════════════════════════════════════════════════════

class ElectronicPaymentsPage extends StatefulWidget {
  final ElectronicPaymentDao dao;
  const ElectronicPaymentsPage({super.key, required this.dao});

  @override
  State<ElectronicPaymentsPage> createState() => _ElectronicPaymentsPageState();
}

class _ElectronicPaymentsPageState extends State<ElectronicPaymentsPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<ElectronicPayment> _payments = [];
  bool     _loading = false;
  String?  _error;

  final _dateFmt   = DateFormat('dd/MM/yyyy');
  final _timeFmt   = DateFormat('dd/MM/yyyy HH:mm');
  final _amountFmt = NumberFormat.currency(locale: 'it_IT', symbol: '€');

  @override
  void initState() {
    super.initState();
    _dateFrom = DateTime.now().subtract(const Duration(days: 30));
    _dateTo   = DateTime.now();
    loadPayments();
  }

  // ── DB ──────────────────────────────────────────────────────────────────

  Future<void> loadPayments() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await widget.dao.getByDateRange(
        _dateFrom ?? DateTime(2000),
        _dateTo   ?? DateTime(2099),
      );
      if (mounted) setState(() { _payments = rows.reversed.toList(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _resetFilters() {
    setState(() {
      _dateFrom = DateTime.now().subtract(const Duration(days: 30));
      _dateTo   = DateTime.now();
    });
    loadPayments();
  }

  // ── Date picker ──────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_dateFrom ?? DateTime.now())
                           : (_dateTo   ?? DateTime.now());
    final picked = await showDatePicker(
      context:     context,
      initialDate: initial,
      firstDate:   DateTime(2020),
      lastDate:    DateTime(2099),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   _kVerde,
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() { if (isFrom) _dateFrom = picked; else _dateTo = picked; });
    loadPayments();
  }

  // ── Modal rimborso ────────────────────────────────────────────────────────

  Future<void> _showRefundConfirm(ElectronicPayment payment) async {
    final isDark = context.read<ImpostazioniController>().darkMode || Theme.of(context).brightness == Brightness.dark;
    final ctrTimer = context.read<ControllerTimerPos>();
    final confirmed = await showDialog<bool>(
      context:           context,
      barrierDismissible: true,
      builder: (_) => _RefundConfirmDialog(
        payment:   payment,
        isDark:    isDark,
        amountFmt: _amountFmt,
      ),
    );

    if (confirmed == true) {
      if( payment.posType == 'dojo' ){
        showDialog(
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.4),
          context: context,
          builder: (ctx) {
            final ctrTimer = ctx.watch<ControllerTimerPos>();
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text(
                    'Attesa rimborso',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Text(
                    'Poggiare la carta sul Pos',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                   ( 30 - ctrTimer.timerPos ).toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                    // ── Bottone Annulla ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (posSelected!.type == 'dojo') {
                            await PosModel.trashPaymentDojo(ctrTimer.uuidPayment);
                          }
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Annulla rimborso'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
        bool refund = await PosModel.refundDojo(payment.paymentIdentifier!, payment.amount, ctrTimer);
        if( refund ){
            final db = await LocalDB.instance();
            await db.update(
              'electronic_payments',
              {'refund': 1},
              where: 'id = ?',
              whereArgs: [payment.id],
            );
        }
        //LOG RIMBORSO
        LogService.instance().saveLog('Pagamento elettronico', 'Rimborsati ${payment.amount}','');
        await loadPayments();
        if( Navigator.canPop(context) ) Navigator.pop(context);
      }
    }
  }

  // ── Computed ─────────────────────────────────────────────────────────────

  double get _totalAmount =>
      _payments.fold(0.0, (sum, p) => sum + p.amount);

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final imp    = context.watch<ImpostazioniController>();
    final isDark = imp.darkMode || Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? _kBgDark   : _kBgLight;
    final card   = isDark ? _kCardDark : Colors.white;
    final text   = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(isDark, card, text),
          const Divider(height: 1),
          _buildSummaryBadge(isDark, text),
          const Divider(height: 1),
          Expanded(child: _buildBody(isDark, card, text)),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _kVerde,
    elevation:       0,
    title: const Text(
      'Pagamenti Elettronici',
      style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    centerTitle: true,
    leading: IconButton(
      icon:      const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
    actions: [
      IconButton(
        tooltip:   'Aggiorna',
        icon:      const Icon(Icons.refresh_rounded, color: Colors.white),
        onPressed: loadPayments,
      ),
    ],
  );

  // ── Filter bar ──────────────────────────────────────────────────────────

  Widget _buildFilterBar(bool isDark, Color card, Color text) =>
      Container(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF0F0EC),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_rounded, color: _kVerde, size: 18),
            const SizedBox(width: 8),
            Text('Filtra per data',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(width: 16),
            _DateChip(
              label:    _dateFrom != null ? _dateFmt.format(_dateFrom!) : 'Da',
              isDark:   isDark,
              hasValue: _dateFrom != null,
              onTap:    () => _pickDate(isFrom: true),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            _DateChip(
              label:    _dateTo != null ? _dateFmt.format(_dateTo!) : 'A',
              isDark:   isDark,
              hasValue: _dateTo != null,
              onTap:    () => _pickDate(isFrom: false),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt_rounded,
                  size: 16, color: Colors.grey),
              label: Text('Reset',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),
          ],
        ),
      );

  // ── Summary badge ───────────────────────────────────────────────────────

  Widget _buildSummaryBadge(bool isDark, Color text) => Container(
    color: isDark ? const Color(0xFF161616) : const Color(0xFFF0F0EC),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        _SummaryChip(
          icon:   Icons.receipt_long_rounded,
          label:  '${_payments.length} record',
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _SummaryChip(
          icon:   Icons.euro_rounded,
          label:  _amountFmt.format(_totalAmount),
          isDark: isDark,
          accent: true,
        ),
      ],
    ),
  );

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody(bool isDark, Color card, Color text) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kVerde));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: Colors.red.shade400),
            const SizedBox(height: 10),
            Text('Errore nel caricamento',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style:     ElevatedButton.styleFrom(backgroundColor: _kVerde),
              onPressed: loadPayments,
              icon:      const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Riprova',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('Nessun pagamento trovato',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Prova a cambiare il range di date',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding:          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount:        _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PaymentTile(
        payment:   _payments[i],
        isDark:    isDark,
        card:      card,
        timeFmt:   _timeFmt,
        amountFmt: _amountFmt,
        onRefund:  () => _showRefundConfirm(_payments[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _DateChip
// ═══════════════════════════════════════════════════════════════════════════

class _DateChip extends StatelessWidget {
  final String       label;
  final bool         isDark;
  final bool         hasValue;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isDark,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap:        onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasValue
            ? _kVerde.withOpacity(isDark ? 0.2 : 0.1)
            : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasValue
              ? _kVerde.withOpacity(0.6)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded,
              size:  13,
              color: hasValue ? _kVerde : Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize:   12,
              fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
              color:      hasValue
                  ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// _SummaryChip
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isDark;
  final bool     accent;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: accent
          ? _kVerde.withOpacity(isDark ? 0.2 : 0.1)
          : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accent
            ? _kVerde.withOpacity(0.4)
            : Colors.grey.withOpacity(0.2),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size:  13,
            color: accent ? _kVerde : Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      accent ? _kVerdeDark : Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// _PaymentTile
// ═══════════════════════════════════════════════════════════════════════════

class _PaymentTile extends StatelessWidget {
  final ElectronicPayment payment;
  final bool              isDark;
  final Color             card;
  final DateFormat        timeFmt;
  final NumberFormat      amountFmt;
  final VoidCallback      onRefund;

  const _PaymentTile({
    required this.payment,
    required this.isDark,
    required this.card,
    required this.timeFmt,
    required this.amountFmt,
    required this.onRefund,
  });

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.grey.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Riga principale ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icona POS
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        _kVerde.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      color: _kVerde, size: 20),
                ),
                const SizedBox(width: 12),

                // Info centrali
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // posType + badge #id
                      Row(children: [
                        Expanded(
                          child: Text(
                            payment.posType,
                            style: TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w700,
                                color:      textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:        _kVerde.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('#${payment.id}',
                              style: const TextStyle(
                                  fontSize:   10,
                                  fontWeight: FontWeight.w700,
                                  color:      _kVerdeDark)),
                        ),
                      ]),
                      const SizedBox(height: 6),

                      // Doc + identifier
                      Row(children: [
                        Icon(Icons.description_rounded,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('Doc. ${payment.idDocument}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                        if (payment.paymentIdentifier != null &&
                            payment.paymentIdentifier!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.tag_rounded,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(payment.paymentIdentifier!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 4),

                      // Data
                      Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(_formatDate(payment.createdDate),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                      ]),
                    ],
                  ),
                ),

                // Importo + device
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(amountFmt.format(payment.amount),
                        style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w800,
                            color:      textColor)),
                    if (payment.dataDevice != null &&
                        payment.dataDevice!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:        Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(payment.dataDevice!,
                              style: TextStyle(
                                  fontSize:   9,
                                  color:      Colors.grey.shade500,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ── Bottone rimborso ─────────────────────────────────────
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            const SizedBox(height: 8),
            payment.refund ==  1
            ?
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: _kVerde,
                  backgroundColor: _kVerde.withOpacity(isDark ? 0.12 : 0.07),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _kVerde.withOpacity(0.3)),
                  ),
                ),
                label: const Text('Rimborsato',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            )
            :
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRefund,
                style: TextButton.styleFrom(
                  foregroundColor: _kRed,
                  backgroundColor: _kRed.withOpacity(isDark ? 0.12 : 0.07),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _kRed.withOpacity(0.3)),
                  ),
                ),
                icon:  const Icon(Icons.undo_rounded, size: 15),
                label: const Text('Rimborso',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _RefundConfirmDialog
// ═══════════════════════════════════════════════════════════════════════════

class _RefundConfirmDialog extends StatelessWidget {
  final ElectronicPayment payment;
  final bool              isDark;
  final NumberFormat      amountFmt;

  const _RefundConfirmDialog({
    required this.payment,
    required this.isDark,
    required this.amountFmt,
  });

  @override
  Widget build(BuildContext context) {
    final bg        = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ────────────────────────────────────────────────
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color:        _kRed.withOpacity(isDark ? 0.15 : 0.07),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:  _kRed.withOpacity(isDark ? 0.2 : 0.1),
                    shape:  BoxShape.circle,
                    border: Border.all(
                        color: _kRed.withOpacity(0.25), width: 1.5),
                  ),
                  child: const Icon(Icons.undo_rounded,
                      color: _kRed, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Conferma rimborso',
                  style: TextStyle(
                      fontSize:   17,
                      fontWeight: FontWeight.w800,
                      color:      _kRed),
                ),
                const SizedBox(height: 4),
                Text(
                  'Questa azione non può essere annullata',
                  style: TextStyle(
                      fontSize: 12, color: _kRed.withOpacity(0.7)),
                ),
              ]),
            ),

            // ── Dettagli ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withOpacity(0.15)),
                ),
                child: Column(children: [
                  _InfoRow(
                    label: 'Pagamento',
                    value: '#${payment.id}',
                    isDark: isDark,
                    valueStyle: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      _kVerdeDark),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label:  'Tipo POS',
                    value:  payment.posType,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label:  'Documento',
                    value:  'Doc. ${payment.idDocument}',
                    isDark: isDark,
                  ),
                  if (payment.paymentIdentifier != null &&
                      payment.paymentIdentifier!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      label:  'Identificatore',
                      value:  payment.paymentIdentifier!,
                      isDark: isDark,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child:   Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Importo rimborsato',
                          style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                              color:      textColor)),
                      Text(amountFmt.format(payment.amount),
                          style: const TextStyle(
                              fontSize:   18,
                              fontWeight: FontWeight.w900,
                              color:      _kRed)),
                    ],
                  ),
                ]),
              ),
            ),

            // ── Bottoni ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                          color: Colors.grey.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Annulla',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Conferma rimborso',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _InfoRow
// ═══════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String     label;
  final String     value;
  final bool       isDark;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      Text(value,
          style: valueStyle ??
              TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              )),
    ],
  );
}
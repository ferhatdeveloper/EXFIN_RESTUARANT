import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class SupplierExtractScreen extends StatefulWidget {
  final String? supplierId;
  final String? supplierName;

  const SupplierExtractScreen({super.key, this.supplierId, this.supplierName});

  @override
  State<SupplierExtractScreen> createState() => _SupplierExtractScreenState();
}

class _SupplierExtractScreenState extends State<SupplierExtractScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  double _totalDebit = 0;
  double _totalCredit = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final results = await pg.query(
        """SELECT id, fiche_no, date, amount, sign, definition, transaction_type, currency_code
           FROM rex_001_01_cash_lines
           WHERE customer_id IS NOT NULL
           ORDER BY date DESC LIMIT 50""",
      );

      double debit = 0;
      double credit = 0;
      for (final r in results) {
        final amount = _toDouble(r['amount']).abs();
        final sign = r['sign'];
        if (sign == 1 || sign == '1') {
          debit += amount;
        } else {
          credit += amount;
        }
      }

      if (mounted) {
        setState(() {
          _transactions = results;
          _totalDebit = debit;
          _totalCredit = credit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: widget.supplierName ?? 'Cari Hesap Ekstresi',
          icon: Icons.account_balance_outlined,
          gradientStart: const Color(0xFF2563EB),
          gradientEnd: const Color(0xFF1D4ED8),
          count: _transactions.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.file_download_outlined, label: 'Excel', onTap: () {}),
          ],
        ),
        _buildSummary(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? const Center(child: Text('Hareket bulunamadı'))
                  : _buildTable(),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final balance = _totalDebit - _totalCredit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _summaryCard('Borç (B)', _totalDebit, const Color(0xFFEF4444)),
          const SizedBox(width: 10),
          _summaryCard('Alacak (A)', _totalCredit, const Color(0xFF10B981)),
          const SizedBox(width: 10),
          _summaryCard('Bakiye', balance, balance >= 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            Text('${value.toStringAsFixed(0)} IQD',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 38,
          dataRowMaxHeight: 44,
          columnSpacing: 16,
          horizontalMargin: 14,
          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          columns: const [
            DataColumn(label: Text('TARİH')),
            DataColumn(label: Text('FİŞ NO')),
            DataColumn(label: Text('TİP')),
            DataColumn(label: Text('AÇIKLAMA')),
            DataColumn(label: Text('BORÇ'), numeric: true),
            DataColumn(label: Text('ALACAK'), numeric: true),
            DataColumn(label: Text('BAKİYE'), numeric: true),
          ],
          rows: () {
            double runningBalance = 0;
            return _transactions.map((t) {
              final amount = _toDouble(t['amount']).abs();
              final sign = t['sign'];
              final isDebit = sign == 1 || sign == '1';
              if (isDebit) runningBalance += amount;
              else runningBalance -= amount;

              return DataRow(cells: [
                DataCell(Text(_formatDate(t['date']?.toString()), style: const TextStyle(fontSize: 11))),
                DataCell(Text(t['fiche_no']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF2563EB)))),
                DataCell(StatusBadge(
                  label: isDebit ? 'Tahsilat' : 'Tediye',
                  color: isDebit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                )),
                DataCell(SizedBox(
                  width: 150,
                  child: Text(t['definition']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                )),
                DataCell(Text(
                  isDebit ? amount.toStringAsFixed(0) : '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                )),
                DataCell(Text(
                  !isDebit ? amount.toStringAsFixed(0) : '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                )),
                DataCell(Text(
                  runningBalance.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: runningBalance >= 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                )),
              ]);
            }).toList();
          }(),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }
}

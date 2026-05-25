import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';

class CashRegisterService {
  static final CashRegisterService _instance = CashRegisterService._();
  factory CashRegisterService() => _instance;
  CashRegisterService._();

  bool _isDayOpen = false;
  bool get isDayOpen => _isDayOpen;
  String? _registerId;
  String? get registerId => _registerId;
  double _openingBalance = 0;
  double get openingBalance => _openingBalance;
  DateTime? _dayOpenedAt;
  DateTime? get dayOpenedAt => _dayOpenedAt;

  Future<bool> openDay({double openingAmount = 0}) async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final registers = await pg.query(
        "SELECT id, balance FROM rex_001_cash_registers WHERE is_active = true LIMIT 1",
      );

      if (registers.isNotEmpty) {
        _registerId = registers.first['id']?.toString();
        _openingBalance = _toDouble(registers.first['balance']);
      }

      _isDayOpen = true;
      _dayOpenedAt = DateTime.now();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> closeDay() async {
    final summary = {
      'openedAt': _dayOpenedAt?.toIso8601String(),
      'closedAt': DateTime.now().toIso8601String(),
      'openingBalance': _openingBalance,
    };

    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final sales = await pg.query(
        "SELECT COUNT(*) as cnt, COALESCE(SUM(net_amount), 0) as total FROM rex_001_01_sales WHERE DATE(created_at) = CURRENT_DATE AND is_cancelled = false",
      );

      if (sales.isNotEmpty) {
        summary['totalSales'] = _toDouble(sales.first['total']);
        summary['salesCount'] = _toInt(sales.first['cnt']);
      }

      final cashLines = await pg.query(
        "SELECT COALESCE(SUM(CASE WHEN sign = 1 THEN amount ELSE 0 END), 0) as cash_in, COALESCE(SUM(CASE WHEN sign = -1 THEN ABS(amount) ELSE 0 END), 0) as cash_out FROM rex_001_01_cash_lines WHERE DATE(created_at) = CURRENT_DATE",
      );

      if (cashLines.isNotEmpty) {
        summary['cashIn'] = _toDouble(cashLines.first['cash_in']);
        summary['cashOut'] = _toDouble(cashLines.first['cash_out']);
      }

      summary['closingBalance'] = _openingBalance +
          (summary['cashIn'] as double? ?? 0) -
          (summary['cashOut'] as double? ?? 0);
    } catch (_) {}

    _isDayOpen = false;
    _dayOpenedAt = null;
    return summary;
  }

  Future<bool> addCashTransaction({
    required double amount,
    required int sign,
    required String type,
    required String description,
  }) async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final ficheNo = 'KAS-${DateTime.now().millisecondsSinceEpoch}';
      await pg.query(
        "INSERT INTO rex_001_01_cash_lines (firm_nr, period_nr, register_id, fiche_no, date, amount, sign, definition, transaction_type, currency_code, exchange_rate, created_at) VALUES ('001', '01', @regId, @ficheNo, NOW(), @amount, @sign, @desc, @type, 'IQD', 1, NOW())",
        params: {
          'regId': _registerId,
          'ficheNo': ficheNo,
          'amount': amount,
          'sign': sign,
          'desc': description,
          'type': type,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }
}

class CashRegisterOpenDialog extends StatefulWidget {
  final VoidCallback onOpened;

  const CashRegisterOpenDialog({super.key, required this.onOpened});

  @override
  State<CashRegisterOpenDialog> createState() => _CashRegisterOpenDialogState();
}

class _CashRegisterOpenDialogState extends State<CashRegisterOpenDialog> {
  final _amountController = TextEditingController(text: '0');
  bool _isOpening = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_open_outlined,
                  color: Color(0xFF10B981), size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mali Günü Aç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kasayı açarak satış işlemlerine başlayabilirsiniz',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Açılış Tutarı (IQD)',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isOpening ? null : _openDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isOpening
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Günü Aç',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDay() async {
    setState(() => _isOpening = true);
    final amount = double.tryParse(_amountController.text) ?? 0;
    final success = await CashRegisterService().openDay(openingAmount: amount);
    if (mounted) {
      setState(() => _isOpening = false);
      if (success) {
        Navigator.pop(context);
        widget.onOpened();
      }
    }
  }
}

class ZReportDialog extends StatelessWidget {
  final Map<String, dynamic> summary;

  const ZReportDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.summarize_outlined,
                  color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Z RAPORU — Gün Sonu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _buildRow('Açılış Bakiyesi', _fmt(summary['openingBalance'])),
            _buildRow('Toplam Satış', _fmt(summary['totalSales']),
                color: const Color(0xFF10B981)),
            _buildRow('Satış Adedi', '${summary['salesCount'] ?? 0}'),
            const Divider(),
            _buildRow('Nakit Giriş', _fmt(summary['cashIn']),
                color: const Color(0xFF10B981)),
            _buildRow('Nakit Çıkış', _fmt(summary['cashOut']),
                color: const Color(0xFFEF4444)),
            const Divider(),
            _buildRow('Kapanış Bakiyesi', _fmt(summary['closingBalance']),
                bold: true, size: 16),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Yazdır'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {Color? color, bool bold = false, double size = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF374151))),
          Text(value,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  String _fmt(dynamic val) {
    if (val == null) return '0 IQD';
    final d = val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0;
    return '${d.toStringAsFixed(0)} IQD';
  }
}

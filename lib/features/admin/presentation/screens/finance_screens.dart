import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

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
        "SELECT id, code, name, bank_name, iban, currency_code, balance, is_active FROM rex_001_bank_registers ORDER BY name",
      );
      if (mounted) setState(() { _accounts = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Banka Hesapları',
          icon: Icons.account_balance_outlined,
          gradientStart: const Color(0xFF0EA5E9),
          gradientEnd: const Color(0xFF0284C7),
          count: _accounts.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Hesap', onTap: () {}),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _accounts.isEmpty
                  ? _emptyState()
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Banka hesabı bulunamadı', style: TextStyle(color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('İlk Hesabı Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, i) {
        final a = _accounts[i];
        final balance = _toDouble(a['balance']);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance, color: Color(0xFF0EA5E9), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['name']?.toString() ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text([a['bank_name'], a['iban']].where((v) => v != null && v.toString().isNotEmpty).join(' • '),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${balance.toStringAsFixed(0)} ${a['currency_code'] ?? 'IQD'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    StatusBadge(
                      label: a['is_active'] == true ? 'Aktif' : 'Pasif',
                      color: a['is_active'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExpenseCardsScreen extends StatefulWidget {
  const ExpenseCardsScreen({super.key});

  @override
  State<ExpenseCardsScreen> createState() => _ExpenseCardsScreenState();
}

class _ExpenseCardsScreenState extends State<ExpenseCardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, code, name, description, is_active FROM rex_001_expense_cards ORDER BY name",
      );
      if (mounted) setState(() { _cards = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Gider Kartları',
          icon: Icons.money_off_outlined,
          gradientStart: const Color(0xFFDC2626),
          gradientEnd: const Color(0xFFB91C1C),
          count: _cards.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Gider', onTap: () {}),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cards.isEmpty
                  ? const Center(child: Text('Gider kartı bulunamadı', style: TextStyle(color: Color(0xFF94A3B8))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cards.length,
                      itemBuilder: (context, i) {
                        final c = _cards[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.receipt_outlined, color: Color(0xFFDC2626), size: 18),
                            ),
                            title: Text(c['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(c['description']?.toString() ?? c['code']?.toString() ?? '',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            trailing: StatusBadge(
                              label: c['is_active'] == true ? 'Aktif' : 'Pasif',
                              color: c['is_active'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class CurrencyRatesScreen extends StatefulWidget {
  const CurrencyRatesScreen({super.key});

  @override
  State<CurrencyRatesScreen> createState() => _CurrencyRatesScreenState();
}

class _CurrencyRatesScreenState extends State<CurrencyRatesScreen> {
  List<Map<String, dynamic>> _rates = [];
  bool _isLoading = true;

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
        "SELECT id, currency_code, date, buy_rate, sell_rate, source FROM public.exchange_rates WHERE is_active = true ORDER BY date DESC, currency_code",
      );
      if (mounted) setState(() { _rates = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Döviz Kurları',
          icon: Icons.currency_exchange_outlined,
          gradientStart: const Color(0xFF7C3AED),
          gradientEnd: const Color(0xFF6D28D9),
          count: _rates.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Kur Ekle', onTap: () {}),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rates.isEmpty
                  ? const Center(child: Text('Kur verisi bulunamadı'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          dataRowMinHeight: 38,
                          dataRowMaxHeight: 44,
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          columns: const [
                            DataColumn(label: Text('PARA BİRİMİ')),
                            DataColumn(label: Text('TARİH')),
                            DataColumn(label: Text('ALIŞ'), numeric: true),
                            DataColumn(label: Text('SATIŞ'), numeric: true),
                            DataColumn(label: Text('KAYNAK')),
                          ],
                          rows: _rates.map((r) {
                            return DataRow(cells: [
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(r['currency_code']?.toString() ?? '-',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
                                  ),
                                ],
                              )),
                              DataCell(Text(_formatDate(r['date']?.toString()), style: const TextStyle(fontSize: 11))),
                              DataCell(Text(_toDouble(r['buy_rate']).toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)))),
                              DataCell(Text(_toDouble(r['sell_rate']).toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)))),
                              DataCell(StatusBadge(
                                label: r['source']?.toString() ?? 'manual',
                                color: const Color(0xFF64748B),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

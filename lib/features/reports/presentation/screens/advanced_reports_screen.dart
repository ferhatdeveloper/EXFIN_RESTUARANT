import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 5, vsync: this); _load(); }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  double _toDouble(dynamic val) { if (val == null) return 0; if (val is num) return val.toDouble(); return double.tryParse(val.toString()) ?? 0; }
  int _toInt(dynamic val) { if (val == null) return 0; if (val is int) return val; return int.tryParse(val.toString()) ?? 0; }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final dailySales = await pg.query("SELECT DATE(created_at) as sale_date, COUNT(*) as cnt, COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE is_cancelled = false GROUP BY DATE(created_at) ORDER BY sale_date DESC LIMIT 14");
      final topProducts = await pg.query("SELECT item_name, SUM(quantity) as qty, SUM(net_amount) as revenue FROM rex_001_01_sale_items GROUP BY item_name ORDER BY revenue DESC LIMIT 10");
      final paymentBreakdown = await pg.query("SELECT payment_method, COUNT(*) as cnt, COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE is_cancelled = false GROUP BY payment_method");
      final cashierSales = await pg.query("SELECT cashier, COUNT(*) as cnt, COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE is_cancelled = false AND cashier IS NOT NULL GROUP BY cashier ORDER BY total DESC");
      final categoryBreakdown = await pg.query("SELECT si.item_name, SUM(si.net_amount) as total FROM rex_001_01_sale_items si GROUP BY si.item_name ORDER BY total DESC LIMIT 15");

      if (mounted) setState(() { _data = {'daily': dailySales, 'products': topProducts, 'payments': paymentBreakdown, 'cashiers': cashierSales, 'categories': categoryBreakdown}; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        const BackofficeHeader(title: 'İleri Raporlar & Analiz', icon: Icons.analytics_outlined,
          gradientStart: Color(0xFF6366F1), gradientEnd: Color(0xFF4F46E5)),
        TabBar(controller: _tabController, isScrollable: true,
          labelColor: const Color(0xFF6366F1), unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF6366F1), labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'GÜNLÜK SATIŞ'), Tab(text: 'TOP ÜRÜNLER'), Tab(text: 'ÖDEME ANALİZİ'), Tab(text: 'PERSONEL'), Tab(text: 'KATEGORİ')]),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: _tabController, children: [
          _buildDailyTab(), _buildProductsTab(), _buildPaymentTab(), _buildCashierTab(), _buildCategoryTab(),
        ])),
      ]),
    );
  }

  Widget _buildDailyTab() {
    final daily = (_data['daily'] as List?) ?? [];
    return SingleChildScrollView(child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
      columns: const [DataColumn(label: Text('TARİH')), DataColumn(label: Text('SİPARİŞ'), numeric: true), DataColumn(label: Text('TOPLAM (IQD)'), numeric: true)],
      rows: daily.map((d) => DataRow(cells: [
        DataCell(Text(d['sale_date']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
        DataCell(Text('${_toInt(d['cnt'])}', style: const TextStyle(fontSize: 11))),
        DataCell(Text(_toDouble(d['total']).toStringAsFixed(0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)))),
      ])).toList(),
    ));
  }

  Widget _buildProductsTab() {
    final products = (_data['products'] as List?) ?? [];
    return SingleChildScrollView(child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
      columns: const [DataColumn(label: Text('ÜRÜN')), DataColumn(label: Text('ADET'), numeric: true), DataColumn(label: Text('GELİR (IQD)'), numeric: true)],
      rows: products.map((p) => DataRow(cells: [
        DataCell(SizedBox(width: 150, child: Text(p['item_name']?.toString() ?? '-', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
        DataCell(Text('${_toDouble(p['qty']).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))),
        DataCell(Text(_toDouble(p['revenue']).toStringAsFixed(0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)))),
      ])).toList(),
    ));
  }

  Widget _buildPaymentTab() {
    final payments = (_data['payments'] as List?) ?? [];
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: payments.length, itemBuilder: (_, i) {
      final p = payments[i]; final total = _toDouble(p['total']); final method = p['payment_method']?.toString() ?? 'other';
      Color color; switch (method) { case 'cash': color = const Color(0xFF10B981); break; case 'card': color = const Color(0xFF3B82F6); break; case 'credit': color = const Color(0xFFF59E0B); break; default: color = const Color(0xFF64748B); }
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(method == 'cash' ? Icons.money : method == 'card' ? Icons.credit_card : Icons.account_balance_wallet, color: color, size: 18)),
        title: Text(method.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${_toInt(p['cnt'])} işlem', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: Text('${total.toStringAsFixed(0)} IQD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ));
    });
  }

  Widget _buildCashierTab() {
    final cashiers = (_data['cashiers'] as List?) ?? [];
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: cashiers.length, itemBuilder: (_, i) {
      final c = cashiers[i]; final total = _toDouble(c['total']);
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: CircleAvatar(radius: 16, backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
          child: Text((c['cashier']?.toString() ?? '?')[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 12))),
        title: Text(c['cashier']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${_toInt(c['cnt'])} satış', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: Text('${total.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ));
    });
  }

  Widget _buildCategoryTab() {
    final cats = (_data['categories'] as List?) ?? [];
    return SingleChildScrollView(child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
      columns: const [DataColumn(label: Text('ÜRÜN / KATEGORİ')), DataColumn(label: Text('TOPLAM (IQD)'), numeric: true)],
      rows: cats.map((c) => DataRow(cells: [
        DataCell(SizedBox(width: 180, child: Text(c['item_name']?.toString() ?? '-', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
        DataCell(Text(_toDouble(c['total']).toStringAsFixed(0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)))),
      ])).toList(),
    ));
  }
}

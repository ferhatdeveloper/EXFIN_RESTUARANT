import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class FullReportsModule extends StatefulWidget {
  const FullReportsModule({super.key});

  @override
  State<FullReportsModule> createState() => _FullReportsModuleState();
}

class _FullReportsModuleState extends State<FullReportsModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 8, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        const BackofficeHeader(title: 'Raporlar & Analiz', icon: Icons.analytics_outlined,
          gradientStart: Color(0xFF6366F1), gradientEnd: Color(0xFF4F46E5)),
        TabBar(controller: _tabController, isScrollable: true,
          labelColor: const Color(0xFF6366F1), unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF6366F1), labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'GÜNLÜK SATIŞ'), Tab(text: 'SAATLİK'), Tab(text: 'TOP ÜRÜNLER'),
            Tab(text: 'ÖDEME'), Tab(text: 'PERSONEL'), Tab(text: 'MÜŞTERİ'),
            Tab(text: 'STOK DURUM'), Tab(text: 'KÂR / ZARAR'),
          ]),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _DailySalesReport(), _HourlySalesReport(), _TopProductsReport(),
          _PaymentReport(), _StaffReport(), _CustomerReport(),
          _StockStatusReport(), _ProfitLossReport(),
        ])),
      ]),
    );
  }
}

double _toD(dynamic v) { if (v == null) return 0; if (v is num) return v.toDouble(); return double.tryParse(v.toString()) ?? 0; }
int _toI(dynamic v) { if (v == null) return 0; if (v is int) return v; return int.tryParse(v.toString()) ?? 0; }

class _DailySalesReport extends StatefulWidget { @override State<_DailySalesReport> createState() => _DailySalesReportState(); }
class _DailySalesReportState extends State<_DailySalesReport> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT DATE(created_at) as d, COUNT(*) as cnt, COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE is_cancelled=false GROUP BY DATE(created_at) ORDER BY d DESC LIMIT 14");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Veri yok'));
    final reversed = _data.reversed.toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      SizedBox(height: 200, child: BarChart(BarChartData(
        barGroups: reversed.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(toY: _toD(e.value['total']) / 1000, color: const Color(0xFF6366F1), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        ])).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            if (v.toInt() >= reversed.length) return const SizedBox();
            final d = reversed[v.toInt()]['d']?.toString() ?? '';
            return Text(d.length >= 10 ? d.substring(8, 10) : d, style: const TextStyle(fontSize: 8));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: const TextStyle(fontSize: 8)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ))),
      const SizedBox(height: 16),
      DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        dataRowMinHeight: 34, dataRowMaxHeight: 40, columnSpacing: 20,
        columns: const [DataColumn(label: Text('TARİH')), DataColumn(label: Text('SİPARİŞ'), numeric: true), DataColumn(label: Text('TOPLAM (IQD)'), numeric: true)],
        rows: _data.map((d) => DataRow(cells: [
          DataCell(Text(d['d']?.toString() ?? '-', style: const TextStyle(fontSize: 10))),
          DataCell(Text('${_toI(d['cnt'])}', style: const TextStyle(fontSize: 10))),
          DataCell(Text(_toD(d['total']).toStringAsFixed(0), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)))),
        ])).toList(),
      ),
    ]));
  }
}

class _HourlySalesReport extends StatefulWidget { @override State<_HourlySalesReport> createState() => _HourlySalesReportState(); }
class _HourlySalesReportState extends State<_HourlySalesReport> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT EXTRACT(HOUR FROM created_at)::int as hr, COUNT(*) as cnt, COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE is_cancelled=false AND DATE(created_at)=CURRENT_DATE GROUP BY hr ORDER BY hr");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Bugün satış yok'));
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      const Align(alignment: Alignment.centerLeft, child: Text('Saatlik Satış Dağılımı (Bugün)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      SizedBox(height: 200, child: LineChart(LineChartData(
        lineBarsData: [LineChartBarData(
          spots: _data.map((d) => FlSpot(_toD(d['hr']), _toD(d['total']) / 1000)).toList(),
          isCurved: true, color: const Color(0xFF3B82F6), barWidth: 3,
          belowBarData: BarAreaData(show: true, color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
          dotData: FlDotData(show: true, getDotPainter: (s, _, __, ___) => FlDotCirclePainter(radius: 3, color: const Color(0xFF3B82F6), strokeWidth: 0)),
        )],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text('${v.toInt()}:00', style: const TextStyle(fontSize: 8)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: const TextStyle(fontSize: 8)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ))),
      const SizedBox(height: 16),
      DataTable(
        headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        dataRowMinHeight: 32, dataRowMaxHeight: 38, columnSpacing: 24,
        columns: const [DataColumn(label: Text('SAAT')), DataColumn(label: Text('SİPARİŞ'), numeric: true), DataColumn(label: Text('TUTAR'), numeric: true)],
        rows: _data.map((d) => DataRow(cells: [
          DataCell(Text('${_toI(d['hr']).toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 10))),
          DataCell(Text('${_toI(d['cnt'])}', style: const TextStyle(fontSize: 10))),
          DataCell(Text('${_toD(d['total']).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ])).toList(),
      ),
    ]));
  }
}

class _TopProductsReport extends StatefulWidget { @override State<_TopProductsReport> createState() => _TopProductsReportState(); }
class _TopProductsReportState extends State<_TopProductsReport> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT item_name, SUM(quantity) as qty, SUM(net_amount) as revenue FROM rex_001_01_sale_items GROUP BY item_name ORDER BY revenue DESC LIMIT 10");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Veri yok'));
    final maxRev = _data.fold<double>(0, (m, d) => _toD(d['revenue']) > m ? _toD(d['revenue']) : m);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      const Align(alignment: Alignment.centerLeft, child: Text('En Çok Satılan Ürünler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      SizedBox(height: 220, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: _data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(toY: _toD(e.value['revenue']), color: Color.lerp(const Color(0xFF10B981), const Color(0xFF3B82F6), e.key / 10)!, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        ])).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            if (v.toInt() >= _data.length) return const SizedBox();
            final n = _data[v.toInt()]['item_name']?.toString() ?? '';
            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(n.length > 8 ? '${n.substring(0, 8)}.' : n, style: const TextStyle(fontSize: 7)));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${(v / 1000).toStringAsFixed(0)}K', style: const TextStyle(fontSize: 8)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ))),
      const SizedBox(height: 16),
      ..._data.asMap().entries.map((e) {
        final d = e.value; final rev = _toD(d['revenue']); final pct = maxRev > 0 ? rev / maxRev : 0.0;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          SizedBox(width: 20, child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['item_name']?.toString() ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFE2E8F0), color: const Color(0xFF6366F1), minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ])),
          const SizedBox(width: 12),
          Text('${rev.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ]));
      }),
    ]));
  }
}

class _PaymentReport extends StatefulWidget { @override State<_PaymentReport> createState() => _PaymentReportState(); }
class _PaymentReportState extends State<_PaymentReport> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT payment_method, COUNT(*) as cnt, COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE is_cancelled=false GROUP BY payment_method");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  Color _methodColor(String? m) { switch(m) { case 'cash': return const Color(0xFF10B981); case 'card': return const Color(0xFF3B82F6); case 'credit': return const Color(0xFFF59E0B); default: return const Color(0xFF64748B); } }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Veri yok'));
    final total = _data.fold<double>(0, (s, d) => s + _toD(d['total']));
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      SizedBox(height: 200, child: PieChart(PieChartData(
        sections: _data.map((d) { final v = _toD(d['total']); final pct = total > 0 ? v / total * 100 : 0;
          return PieChartSectionData(value: v, title: '${pct.toStringAsFixed(0)}%', color: _methodColor(d['payment_method']?.toString()),
            radius: 60, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));
        }).toList(),
        centerSpaceRadius: 40,
      ))),
      const SizedBox(height: 16),
      ..._data.map((d) { final m = d['payment_method']?.toString() ?? 'other'; final v = _toD(d['total']);
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: _methodColor(m).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(m == 'cash' ? Icons.money : m == 'card' ? Icons.credit_card : Icons.account_balance_wallet, color: _methodColor(m), size: 18)),
          title: Text(m.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('${_toI(d['cnt'])} işlem', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          trailing: Text('${v.toStringAsFixed(0)} IQD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _methodColor(m))),
        ));
      }),
    ]));
  }
}

class _StaffReport extends StatefulWidget { @override State<_StaffReport> createState() => _StaffReportState(); }
class _StaffReportState extends State<_StaffReport> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT cashier, COUNT(*) as cnt, COALESCE(SUM(net_amount),0) as total, COALESCE(AVG(net_amount),0) as avg_val FROM rex_001_01_sales WHERE is_cancelled=false AND cashier IS NOT NULL GROUP BY cashier ORDER BY total DESC");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Personel verisi yok'));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; final total = _toD(d['total']); final avg = _toD(d['avg_val']);
      return Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            child: Text((d['cashier']?.toString() ?? '?')[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w800, fontSize: 16))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['cashier']?.toString() ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text('${_toI(d['cnt'])} satış • Ort: ${avg.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ])),
          Text('${total.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        ])));
    });
  }
}

class _CustomerReport extends StatefulWidget { @override State<_CustomerReport> createState() => _CustomerReportState(); }
class _CustomerReportState extends State<_CustomerReport> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT name, code, phone, total_spent, customer_tier FROM rex_001_customers WHERE is_active=true ORDER BY total_spent DESC LIMIT 20");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Müşteri verisi yok'));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; final spent = _toD(d['total_spent']); final tier = d['customer_tier']?.toString() ?? 'normal';
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: CircleAvatar(radius: 18, backgroundColor: tier == 'vip' ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFF3B82F6).withValues(alpha: 0.1),
          child: Text((d['name']?.toString() ?? '?')[0].toUpperCase(), style: TextStyle(color: tier == 'vip' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6), fontWeight: FontWeight.w700))),
        title: Text(d['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${d['phone'] ?? ''} • ${tier.toUpperCase()}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: Text('${spent.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ));
    });
  }
}

class _StockStatusReport extends StatefulWidget { @override State<_StockStatusReport> createState() => _StockStatusReportState(); }
class _StockStatusReportState extends State<_StockStatusReport> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.getProducts();
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    final normal = _data.where((p) => _toD(p['stock']) >= 30).length;
    final low = _data.where((p) => _toD(p['stock']) < 30 && _toD(p['stock']) >= 10).length;
    final critical = _data.where((p) => _toD(p['stock']) < 10 && _toD(p['stock']) > 0).length;
    final out = _data.where((p) => _toD(p['stock']) <= 0).length;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      SizedBox(height: 200, child: PieChart(PieChartData(
        sections: [
          PieChartSectionData(value: normal.toDouble(), title: 'Normal\n$normal', color: const Color(0xFF10B981), radius: 55, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
          PieChartSectionData(value: low.toDouble(), title: 'Düşük\n$low', color: const Color(0xFFF59E0B), radius: 55, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
          PieChartSectionData(value: critical.toDouble(), title: 'Kritik\n$critical', color: const Color(0xFFEF4444), radius: 55, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
          PieChartSectionData(value: out.toDouble(), title: 'Tüken\n$out', color: const Color(0xFF64748B), radius: 55, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
        centerSpaceRadius: 35,
      ))),
      const SizedBox(height: 16),
      Row(children: [
        _statBox('Normal', '$normal', const Color(0xFF10B981)),
        _statBox('Düşük', '$low', const Color(0xFFF59E0B)),
        _statBox('Kritik', '$critical', const Color(0xFFEF4444)),
        _statBox('Tükendi', '$out', const Color(0xFF64748B)),
      ]),
    ]));
  }
  Widget _statBox(String label, String value, Color color) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color)),
    ]),
  ));
}

class _ProfitLossReport extends StatefulWidget { @override State<_ProfitLossReport> createState() => _ProfitLossReportState(); }
class _ProfitLossReportState extends State<_ProfitLossReport> {
  Map<String, dynamic> _data = {}; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final sales = await pg.query("SELECT COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE is_cancelled=false AND fiche_type='sales_invoice'");
      final purchases = await pg.query("SELECT COALESCE(SUM(net_amount),0) as total FROM rex_001_01_sales WHERE fiche_type='A'");
      final expenses = await pg.query("SELECT COALESCE(SUM(ABS(amount)),0) as total FROM rex_001_01_cash_lines WHERE sign=-1");
      final revenue = _toD(sales.isNotEmpty ? sales.first['total'] : 0);
      final cost = _toD(purchases.isNotEmpty ? purchases.first['total'] : 0);
      final exp = _toD(expenses.isNotEmpty ? expenses.first['total'] : 0);
      if (mounted) setState(() { _data = {'revenue': revenue, 'cost': cost, 'expenses': exp, 'gross': revenue - cost, 'net': revenue - cost - exp}; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('KÂR / ZARAR RAPORU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
      const SizedBox(height: 20),
      _plRow('Satış Gelirleri', _toD(_data['revenue']), const Color(0xFF10B981)),
      _plRow('Satışların Maliyeti (-)', -_toD(_data['cost']), const Color(0xFFEF4444)),
      const Divider(height: 20),
      _plRow('BRÜT KÂR', _toD(_data['gross']), const Color(0xFF3B82F6), bold: true),
      const SizedBox(height: 8),
      _plRow('Faaliyet Giderleri (-)', -_toD(_data['expenses']), const Color(0xFFEF4444)),
      const Divider(height: 20),
      _plRow('NET KÂR / ZARAR', _toD(_data['net']), _toD(_data['net']) >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), bold: true, size: 18),
      const SizedBox(height: 24),
      SizedBox(height: 180, child: BarChart(BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _toD(_data['revenue']) / 1000, color: const Color(0xFF10B981), width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _toD(_data['cost']) / 1000, color: const Color(0xFFEF4444), width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _toD(_data['expenses']) / 1000, color: const Color(0xFFF59E0B), width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: _toD(_data['net']) / 1000, color: const Color(0xFF3B82F6), width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Gelir', 'Maliyet', 'Gider', 'Net Kâr'];
            return Text(v.toInt() < labels.length ? labels[v.toInt()] : '', style: const TextStyle(fontSize: 9));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: const TextStyle(fontSize: 8)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ))),
    ]));
  }
  Widget _plRow(String label, double value, Color color, {bool bold = false, double size = 14}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
      Text('${value.toStringAsFixed(0)} IQD', style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
    ]),
  );
}

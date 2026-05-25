import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.getProducts();
      if (mounted) {
        setState(() {
          _products = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _products.fold<double>(
        0, (sum, p) => sum + _toDouble(p['price']) * _toDouble(p['stock']));
    final lowStock = _products.where((p) => _toDouble(p['stock']) < 10 && _toDouble(p['stock']) > 0).length;
    final outOfStock = _products.where((p) => _toDouble(p['stock']) <= 0).length;

    return Column(
      children: [
        BackofficeHeader(
          title: 'Stok Yönetimi',
          icon: Icons.warehouse_outlined,
          gradientStart: const Color(0xFFF97316),
          gradientEnd: const Color(0xFFEA580C),
          count: _products.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.file_download_outlined, label: 'Excel', onTap: () {}),
          ],
        ),
        _buildStatsRow(totalValue, lowStock, outOfStock),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFF97316),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFFF97316),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'GENEL BAKIŞ'),
              Tab(text: 'HAREKETLER'),
              Tab(text: 'SAYIM'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMovementsTab(),
                    _buildCountTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double totalValue, int lowStock, int outOfStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statCard('Stok Değeri', '${(totalValue / 1000).toStringAsFixed(0)}K IQD', const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          _statCard('Düşük Stok', '$lowStock ürün', const Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          _statCard('Tükenen', '$outOfStock ürün', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
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
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
          dataRowMinHeight: 38,
          dataRowMaxHeight: 44,
          columnSpacing: 16,
          horizontalMargin: 12,
          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
          columns: const [
            DataColumn(label: Text('KOD')),
            DataColumn(label: Text('ÜRÜN ADI')),
            DataColumn(label: Text('KATEGORİ')),
            DataColumn(label: Text('STOK'), numeric: true),
            DataColumn(label: Text('BİRİM MALİYET'), numeric: true),
            DataColumn(label: Text('STOK DEĞERİ'), numeric: true),
            DataColumn(label: Text('DURUM')),
          ],
          rows: _products.map((p) {
            final stock = _toDouble(p['stock']);
            final cost = _toDouble(p['cost']);
            final value = stock * cost;

            String status;
            Color statusColor;
            if (stock <= 0) {
              status = 'Tükendi';
              statusColor = const Color(0xFF64748B);
            } else if (stock < 10) {
              status = 'Kritik';
              statusColor = const Color(0xFFEF4444);
            } else if (stock < 30) {
              status = 'Düşük';
              statusColor = const Color(0xFFF59E0B);
            } else {
              status = 'Normal';
              statusColor = const Color(0xFF10B981);
            }

            return DataRow(cells: [
              DataCell(Text(p['code']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF2563EB)))),
              DataCell(SizedBox(
                width: 160,
                child: Text(p['name']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
              )),
              DataCell(Text(p['categoryName']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
              DataCell(Text(stock.toStringAsFixed(0),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: stock < 10 ? const Color(0xFFEF4444) : const Color(0xFF1E293B)))),
              DataCell(Text(cost.toStringAsFixed(0), style: const TextStyle(fontSize: 11))),
              DataCell(Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              DataCell(StatusBadge(label: status, color: statusColor)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMovementsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_vert, size: 40, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text('Stok Hareketleri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Giriş / Çıkış / Transfer kayıtları', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildCountTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist, size: 40, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text('Stok Sayımı', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Sayım fişleri ve sonuçları', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

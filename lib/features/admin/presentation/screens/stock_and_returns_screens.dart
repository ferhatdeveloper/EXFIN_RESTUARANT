import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class StockMovementSlipsScreen extends StatefulWidget {
  const StockMovementSlipsScreen({super.key});

  @override
  State<StockMovementSlipsScreen> createState() => _StockMovementSlipsScreenState();
}

class _StockMovementSlipsScreenState extends State<StockMovementSlipsScreen> {
  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;
  String _filter = 'all';

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

      String where = '';
      if (_filter == 'in') where = "WHERE movement_type = 'in'";
      else if (_filter == 'out') where = "WHERE movement_type = 'out'";
      else if (_filter == 'transfer') where = "WHERE movement_type = 'transfer'";

      final results = await pg.query(
        "SELECT id, document_no, movement_type, movement_date, description, status, exchange_rate FROM rex_001_01_stock_movements $where ORDER BY movement_date DESC LIMIT 100",
      );
      if (mounted) setState(() { _movements = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Stok Hareket Fişleri',
          icon: Icons.swap_vert_outlined,
          gradientStart: const Color(0xFFF97316),
          gradientEnd: const Color(0xFFEA580C),
          count: _movements.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Fiş', onTap: () {}),
          ],
        ),
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _movements.isEmpty
                  ? const Center(child: Text('Hareket fişi bulunamadı'))
                  : _buildTable(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _filterChip('Tümü', 'all'),
          const SizedBox(width: 6),
          _filterChip('Giriş', 'in'),
          const SizedBox(width: 6),
          _filterChip('Çıkış', 'out'),
          const SizedBox(width: 6),
          _filterChip('Transfer', 'transfer'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return InkWell(
      onTap: () { setState(() => _filter = value); _load(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF97316) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? const Color(0xFFF97316) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: active ? Colors.white : const Color(0xFF374151),
        )),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          columns: const [
            DataColumn(label: Text('BELGE NO')),
            DataColumn(label: Text('TARİH')),
            DataColumn(label: Text('TİP')),
            DataColumn(label: Text('AÇIKLAMA')),
            DataColumn(label: Text('DURUM')),
          ],
          rows: _movements.map((m) {
            final type = m['movement_type']?.toString() ?? '';
            Color typeColor;
            String typeLabel;
            switch (type) {
              case 'in': typeColor = const Color(0xFF10B981); typeLabel = 'Giriş'; break;
              case 'out': typeColor = const Color(0xFFEF4444); typeLabel = 'Çıkış'; break;
              case 'transfer': typeColor = const Color(0xFF3B82F6); typeLabel = 'Transfer'; break;
              default: typeColor = const Color(0xFF64748B); typeLabel = type;
            }

            return DataRow(cells: [
              DataCell(Text(m['document_no']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF2563EB)))),
              DataCell(Text(_formatDate(m['movement_date']?.toString()), style: const TextStyle(fontSize: 11))),
              DataCell(StatusBadge(label: typeLabel, color: typeColor)),
              DataCell(SizedBox(width: 180, child: Text(m['description']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
              DataCell(StatusBadge(
                label: m['status']?.toString() ?? 'completed',
                color: const Color(0xFF10B981),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try { final dt = DateTime.parse(d); return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'; }
    catch (_) { return d.length > 10 ? d.substring(0, 10) : d; }
  }
}

class ReturnManagementScreen extends StatefulWidget {
  const ReturnManagementScreen({super.key});

  @override
  State<ReturnManagementScreen> createState() => _ReturnManagementScreenState();
}

class _ReturnManagementScreenState extends State<ReturnManagementScreen> {
  List<Map<String, dynamic>> _returns = [];
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
        "SELECT id, return_number, original_receipt, product_name, quantity, unit_price, total_amount, return_reason, staff_name, created_at FROM rest.return_log ORDER BY created_at DESC LIMIT 50",
      );
      if (mounted) setState(() { _returns = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'İade Yönetimi',
          icon: Icons.assignment_return_outlined,
          gradientStart: const Color(0xFFEF4444),
          gradientEnd: const Color(0xFFDC2626),
          count: _returns.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni İade', onTap: () {}),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _returns.isEmpty
                  ? const Center(child: Text('İade kaydı bulunamadı', style: TextStyle(color: Color(0xFF94A3B8))))
                  : _buildTable(),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          columns: const [
            DataColumn(label: Text('İADE NO')),
            DataColumn(label: Text('TARİH')),
            DataColumn(label: Text('ÜRÜN')),
            DataColumn(label: Text('ADET'), numeric: true),
            DataColumn(label: Text('TUTAR'), numeric: true),
            DataColumn(label: Text('SEBEP')),
            DataColumn(label: Text('PERSONEL')),
          ],
          rows: _returns.map((r) {
            return DataRow(cells: [
              DataCell(Text(r['return_number']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFFEF4444)))),
              DataCell(Text(_formatDate(r['created_at']?.toString()), style: const TextStyle(fontSize: 11))),
              DataCell(SizedBox(width: 140, child: Text(r['product_name']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
              DataCell(Text('${_toDouble(r['quantity']).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))),
              DataCell(Text('${_toDouble(r['total_amount']).toStringAsFixed(0)} IQD',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)))),
              DataCell(SizedBox(width: 120, child: Text(r['return_reason']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis))),
              DataCell(Text(r['staff_name']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try { final dt = DateTime.parse(d); return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'; }
    catch (_) { return d.length > 10 ? d.substring(0, 10) : d; }
  }
}

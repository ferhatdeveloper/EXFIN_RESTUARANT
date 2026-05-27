import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.getProducts();
      if (mounted) {
        setState(() {
          _products = results;
          _filtered = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = _products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final code = (p['code'] ?? '').toString().toLowerCase();
        final cat = (p['categoryName'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || code.contains(q) || cat.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Ürün Yönetimi',
          icon: Icons.inventory_2_outlined,
          gradientStart: const Color(0xFF2563EB),
          gradientEnd: const Color(0xFF1D4ED8),
          count: _products.length,
          actions: [
            HeaderIconButton(
              icon: Icons.refresh,
              onTap: _loadProducts,
            ),
            const SizedBox(width: 6),
            HeaderIconButton(
              icon: Icons.file_download_outlined,
              label: 'Excel',
              onTap: () {},
            ),
            const SizedBox(width: 6),
            HeaderIconButton(
              icon: Icons.add,
              label: 'Yeni Ürün',
              onTap: () {},
            ),
          ],
        ),
        BackofficeSearchBar(
          hint: 'Ürün adı, kodu veya barkod ara...',
          onChanged: _onSearch,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('Ürün bulunamadı',
                          style: TextStyle(color: Color(0xFF94A3B8))))
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
          headingRowColor:
              WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 48,
          columnSpacing: 20,
          horizontalMargin: 16,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
          columns: const [
            DataColumn(label: Text('KOD')),
            DataColumn(label: Text('AD')),
            DataColumn(label: Text('KATEGORİ')),
            DataColumn(label: Text('FİYAT'), numeric: true),
            DataColumn(label: Text('MALİYET'), numeric: true),
            DataColumn(label: Text('STOK'), numeric: true),
            DataColumn(label: Text('KDV %'), numeric: true),
            DataColumn(label: Text('BİRİM')),
            DataColumn(label: Text('DURUM')),
          ],
          rows: _filtered.map((p) {
            final stockRaw = p['stock'];
            final stock = stockRaw is num ? stockRaw.toDouble() : double.tryParse(stockRaw?.toString() ?? '0') ?? 0;
            final priceRaw = p['price'];
            final price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw?.toString() ?? '0') ?? 0;
            final costRaw = p['cost'];
            final cost = costRaw is num ? costRaw.toDouble() : double.tryParse(costRaw?.toString() ?? '0') ?? 0;
            final isActive = p['isActive'] == true;

            return DataRow(
              cells: [
                DataCell(Text(
                  p['code']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                    fontFamily: 'monospace',
                  ),
                )),
                DataCell(SizedBox(
                  width: 180,
                  child: Text(
                    p['name']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Text(
                  p['categoryName']?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF64748B)),
                )),
                DataCell(Text(
                  price.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                )),
                DataCell(Text(
                  cost.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                )),
                DataCell(Text(
                  stock.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: stock < 10
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                )),
                DataCell(Text(
                  '${(p['vatRate'] is num ? (p['vatRate'] as num).toInt() : int.tryParse(p['vatRate']?.toString() ?? '0') ?? 0)}',
                  style: const TextStyle(fontSize: 11),
                )),
                DataCell(Text(
                  p['unit']?.toString() ?? 'Adet',
                  style: const TextStyle(fontSize: 11),
                )),
                DataCell(StatusBadge(
                  label: isActive ? 'Aktif' : 'Pasif',
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

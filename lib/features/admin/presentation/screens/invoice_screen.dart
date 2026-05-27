import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class InvoiceListScreen extends StatefulWidget {
  final String invoiceType;
  final String title;

  const InvoiceListScreen({
    super.key,
    required this.invoiceType,
    required this.title,
  });

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      String whereClause = '';
      if (widget.invoiceType == 'sales') {
        whereClause = "WHERE fiche_type = 'S' OR (trcode = 7 OR trcode = 8)";
      } else if (widget.invoiceType == 'purchase') {
        whereClause = "WHERE fiche_type = 'A' OR trcode = 1";
      } else if (widget.invoiceType == 'return') {
        whereClause = "WHERE trcode = 3 OR trcode = 6";
      }

      final results = await pg.query(
        "SELECT id, fiche_no, document_no, date, customer_name, total_net, total_vat, total_gross, net_amount, currency, payment_method, status, is_cancelled, fiche_type, trcode, notes FROM rex_001_01_sales $whereClause ORDER BY date DESC LIMIT 100",
      );
      if (mounted) {
        setState(() {
          _invoices = results;
          _filtered = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = _invoices.where((inv) {
        final s = q.toLowerCase();
        return (inv['fiche_no'] ?? '').toString().toLowerCase().contains(s) ||
            (inv['customer_name'] ?? '').toString().toLowerCase().contains(s) ||
            (inv['notes'] ?? '').toString().toLowerCase().contains(s);
      }).toList();
    });
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  Color get _headerColor {
    switch (widget.invoiceType) {
      case 'sales':
        return const Color(0xFF10B981);
      case 'purchase':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return InvoiceFormScreen(
        invoiceType: widget.invoiceType,
        onBack: () => setState(() {
          _showForm = false;
          _load();
        }),
      );
    }

    return Column(
      children: [
        BackofficeHeader(
          title: widget.title,
          icon: Icons.receipt_long_outlined,
          gradientStart: _headerColor,
          gradientEnd: _headerColor.withValues(alpha: 0.8),
          count: _invoices.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(
              icon: Icons.add,
              label: 'Yeni Fatura',
              onTap: () => setState(() => _showForm = true),
            ),
          ],
        ),
        BackofficeSearchBar(
          hint: 'Fiş no, müşteri adı veya not ara...',
          onChanged: _onSearch,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('Fatura bulunamadı',
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
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 48,
          columnSpacing: 18,
          horizontalMargin: 14,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
          columns: const [
            DataColumn(label: Text('FİŞ NO')),
            DataColumn(label: Text('TARİH')),
            DataColumn(label: Text('MÜŞTERİ / TEDARİKÇİ')),
            DataColumn(label: Text('NET TUTAR'), numeric: true),
            DataColumn(label: Text('KDV'), numeric: true),
            DataColumn(label: Text('TOPLAM'), numeric: true),
            DataColumn(label: Text('ÖDEME')),
            DataColumn(label: Text('DURUM')),
          ],
          rows: _filtered.map((inv) {
            final netAmount = _toDouble(inv['net_amount']);
            final totalVat = _toDouble(inv['total_vat']);
            final totalGross = _toDouble(inv['total_gross']);
            final net = netAmount > 0 ? netAmount : _toDouble(inv['total_net']);
            final isCancelled = inv['is_cancelled'] == true;

            return DataRow(
              cells: [
                DataCell(Text(
                  inv['fiche_no']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                    fontFamily: 'monospace',
                  ),
                )),
                DataCell(Text(
                  _formatDate(inv['date']?.toString()),
                  style: const TextStyle(fontSize: 11),
                )),
                DataCell(SizedBox(
                  width: 150,
                  child: Text(
                    inv['customer_name']?.toString() ?? 'Peşin Müşteri',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Text(
                  net.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
                DataCell(Text(
                  totalVat.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                )),
                DataCell(Text(
                  (totalGross > 0 ? totalGross : net).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                )),
                DataCell(StatusBadge(
                  label: _paymentLabel(inv['payment_method']?.toString()),
                  color: _paymentColor(inv['payment_method']?.toString()),
                )),
                DataCell(StatusBadge(
                  label: isCancelled ? 'İptal' : (inv['status']?.toString() ?? 'completed'),
                  color: isCancelled
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                )),
              ],
            );
          }).toList(),
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

  String _paymentLabel(String? method) {
    switch (method) {
      case 'cash': return 'Nakit';
      case 'credit': return 'Veresiye';
      case 'card': return 'Kart';
      default: return method ?? 'Nakit';
    }
  }

  Color _paymentColor(String? method) {
    switch (method) {
      case 'cash': return const Color(0xFF10B981);
      case 'credit': return const Color(0xFFF59E0B);
      case 'card': return const Color(0xFF3B82F6);
      default: return const Color(0xFF64748B);
    }
  }
}

class InvoiceFormScreen extends StatefulWidget {
  final String invoiceType;
  final VoidCallback onBack;

  const InvoiceFormScreen({
    super.key,
    required this.invoiceType,
    required this.onBack,
  });

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final _searchController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.getProducts();
      if (mounted) {
        setState(() {
          _products = results;
          _filteredProducts = results;
        });
      }
    } catch (_) {}
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  void _searchProducts(String q) {
    setState(() {
      _filteredProducts = _products.where((p) {
        final s = q.toLowerCase();
        return (p['name'] ?? '').toString().toLowerCase().contains(s) ||
            (p['code'] ?? '').toString().toLowerCase().contains(s) ||
            (p['barcode'] ?? '').toString().contains(s);
      }).toList();
    });
  }

  void _addItem(Map<String, dynamic> product) {
    final existing = _items.indexWhere((i) => i['productId'] == product['id']);
    if (existing >= 0) {
      setState(() {
        _items[existing]['quantity'] = (_items[existing]['quantity'] as int) + 1;
        _items[existing]['total'] =
            _items[existing]['quantity'] * _toDouble(_items[existing]['unitPrice']);
      });
    } else {
      setState(() {
        _items.add({
          'productId': product['id'],
          'name': product['name'],
          'code': product['code'],
          'unitPrice': _toDouble(product['price']),
          'cost': _toDouble(product['cost']),
          'vatRate': _toDouble(product['vatRate']),
          'quantity': 1,
          'total': _toDouble(product['price']),
          'unit': product['unit'] ?? 'Adet',
        });
      });
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  double get _subtotal => _items.fold(0, (s, i) => s + _toDouble(i['total']));
  double get _totalVat => _items.fold(
      0, (s, i) => s + (_toDouble(i['total']) * _toDouble(i['vatRate']) / 100));
  double get _grandTotal => _subtotal + _totalVat;

  @override
  Widget build(BuildContext context) {
    final isSales = widget.invoiceType == 'sales';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSales
                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                  : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack,
              ),
              Icon(
                isSales ? Icons.receipt_long : Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isSales ? 'Yeni Satış Faturası' : 'Yeni Alış Faturası',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _items.isNotEmpty ? _saveDraft : null,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isSales
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildProductPanel()),
              Container(width: 1, color: const Color(0xFFE2E8F0)),
              Expanded(flex: 2, child: _buildInvoicePanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: _searchProducts,
            decoration: InputDecoration(
              hintText: 'Ürün adı, kodu veya barkod ile ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, i) {
              final p = _filteredProducts[i];
              final price = _toDouble(p['price']);
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _addItem(p),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p['name']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p['code']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              '${price.toStringAsFixed(0)} IQD',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicePanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (_) {},
                  decoration: InputDecoration(
                    hintText: widget.invoiceType == 'sales'
                        ? 'Müşteri adı...'
                        : 'Tedarikçi adı...',
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _paymentMethod,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Nakit')),
                  DropdownMenuItem(value: 'credit', child: Text('Veresiye')),
                  DropdownMenuItem(value: 'card', child: Text('Kart')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(
                  child: Text(
                    'Ürün eklemek için soldan seçin',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name']?.toString() ?? '-',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${_toDouble(item['unitPrice']).toStringAsFixed(0)} × ${item['quantity']} = ${_toDouble(item['total']).toStringAsFixed(0)} IQD',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                                  onPressed: () {
                                    if ((item['quantity'] as int) > 1) {
                                      setState(() {
                                        item['quantity'] = (item['quantity'] as int) - 1;
                                        item['total'] = item['quantity'] * _toDouble(item['unitPrice']);
                                      });
                                    } else {
                                      _removeItem(i);
                                    }
                                  },
                                ),
                                Text('${item['quantity']}',
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      item['quantity'] = (item['quantity'] as int) + 1;
                                      item['total'] = item['quantity'] * _toDouble(item['unitPrice']);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                  onPressed: () => _removeItem(i),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              _totalRow('Ara Toplam', _subtotal),
              _totalRow('KDV', _totalVat),
              const Divider(),
              _totalRow('GENEL TOPLAM', _grandTotal, bold: true, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false, double size = 12}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: const Color(0xFF374151))),
          Text(
            '${value.toStringAsFixed(0)} IQD',
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? const Color(0xFF1E293B) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fatura kaydedildi'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
    widget.onBack();
  }
}

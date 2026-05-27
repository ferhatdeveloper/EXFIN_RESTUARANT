import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';
import '../../../pos/presentation/widgets/payment_dialog.dart';
import '../../../pos/presentation/widgets/receipt_widgets.dart';
import '../../../pos/presentation/widgets/pos_dialogs.dart';
import '../../../pos/presentation/widgets/staff_and_options_dialogs.dart';

enum PosMode { table, retail, selfService }

class FullPosScreen extends StatefulWidget {
  final PosMode mode;
  final String? tableId;
  final String? tableNumber;

  const FullPosScreen({
    super.key,
    this.mode = PosMode.retail,
    this.tableId,
    this.tableNumber,
  });

  @override
  State<FullPosScreen> createState() => _FullPosScreenState();
}

class _FullPosScreenState extends State<FullPosScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _cart = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _selectedCourse = 0;
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
      final products = await pg.getProducts();
      final categories = await pg.query("SELECT DISTINCT category_code FROM rex_001_products WHERE is_active = true AND category_code IS NOT NULL AND category_code != ''");
      if (mounted) setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
      final matchCat = _selectedCategory == 'all' || (p['categoryName']?.toString() ?? '').toLowerCase() == _selectedCategory.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (p['name']?.toString() ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p['code']?.toString() ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p['barcode']?.toString() ?? '').contains(_searchQuery);
      return matchCat && matchSearch;
    }).toList();
  }

  double get _subtotal => _cart.fold(0, (s, i) => s + _toDouble(i['total']));
  double get _totalDiscount => _cart.fold(0, (s, i) => s + _toDouble(i['discount']));
  double get _netTotal => _subtotal - _totalDiscount;

  void _addToCart(Map<String, dynamic> product) {
    final existIdx = _cart.indexWhere((i) => i['productId'] == product['id'] && i['course'] == _selectedCourse);
    if (existIdx >= 0) {
      setState(() {
        _cart[existIdx]['qty'] = (_cart[existIdx]['qty'] as int) + 1;
        _cart[existIdx]['total'] = _cart[existIdx]['qty'] * _toDouble(_cart[existIdx]['price']);
      });
    } else {
      setState(() {
        _cart.add({
          'productId': product['id'],
          'name': product['name'],
          'code': product['code'],
          'price': _toDouble(product['price']),
          'qty': 1,
          'total': _toDouble(product['price']),
          'discount': 0.0,
          'note': '',
          'options': <String>[],
          'course': _selectedCourse,
        });
      });
    }
  }

  void _removeFromCart(int idx) => setState(() => _cart.removeAt(idx));

  void _showPayment() {
    showDialog(context: context, builder: (_) => PaymentDialog(
      totalAmount: _netTotal,
      onComplete: (method, paid, discount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ödeme tamamlandı: $method'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _cart.clear());
      },
    ));
  }

  void _showReceipt() {
    showDialog(context: context, builder: (_) => PrintTypeDialog(onPreview: () {
      showDialog(context: context, builder: (_) => ReceiptPreviewDialog(
        receiptNo: 'RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        cashier: 'admin',
        tableNo: widget.tableNumber ?? '-',
        items: _cart,
        subtotal: _subtotal,
        discount: _totalDiscount,
        total: _netTotal,
        paid: _netTotal,
      ));
    }));
  }

  void _showItemOptions(int idx) {
    showDialog(context: context, builder: (_) => ProductOptionsDialog(
      productName: _cart[idx]['name']?.toString() ?? '',
      onConfirm: (options, note) {
        setState(() {
          _cart[idx]['options'] = options;
          if (note != null) _cart[idx]['note'] = note;
        });
      },
    ));
  }

  void _showItemDiscount(int idx) {
    showDialog(context: context, builder: (_) => DiscountDialog(
      currentPrice: _toDouble(_cart[idx]['total']),
      onApply: (discountAmount) {
        setState(() => _cart[idx]['discount'] = discountAmount);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = widget.mode == PosMode.retail ? 'PERAKENDE' : widget.mode == PosMode.selfService ? 'SELF SERVİS' : 'MASA ${widget.tableNumber ?? ''}';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(modeLabel),
          _buildCourseBar(),
          Expanded(
            child: Row(
              children: [
                _buildCategorySidebar(),
                Expanded(child: _buildProductGrid()),
                _buildCartPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String modeLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)]),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context)),
          const Icon(Icons.search, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ürün veya kategori ara...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(modeLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.print_outlined, color: Colors.white70, size: 18), onPressed: _cart.isNotEmpty ? _showReceipt : null),
        ],
      ),
    );
  }

  Widget _buildCourseBar() {
    return Container(
      height: 36,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _courseChip('HEPSİ', -1),
          ...List.generate(4, (i) => _courseChip('TABAK ${i + 1}', i)),
          const Spacer(),
          TextButton.icon(icon: const Icon(Icons.save_outlined, size: 14), label: const Text('KAYDET', style: TextStyle(fontSize: 10)), onPressed: () {}),
          TextButton.icon(icon: const Icon(Icons.swap_horiz, size: 14), label: const Text('MASA TAŞI', style: TextStyle(fontSize: 10)), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _courseChip(String label, int course) {
    final active = _selectedCourse == course || (course == -1 && _selectedCourse == 0);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedCourse = course == -1 ? 0 : course),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B))),
        ),
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      width: 100,
      color: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          _catItem('TÜMÜ', 'all', Icons.restaurant_menu),
          ..._categories.map((c) {
            final code = c['category_code']?.toString() ?? '';
            return _catItem(code.length > 12 ? code.substring(0, 12) : code, code, Icons.label_outline);
          }),
        ],
      ),
    );
  }

  Widget _catItem(String label, String code, IconData icon) {
    final active = _selectedCategory == code;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.transparent,
          border: Border(left: BorderSide(color: active ? Colors.white : Colors.transparent, width: 3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.white : const Color(0xFF94A3B8), size: 18),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8, color: active ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final products = _filteredProducts;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 1.3),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        final price = _toDouble(p['price']);
        return Material(
          color: Colors.white, borderRadius: BorderRadius.circular(8), elevation: 1,
          child: InkWell(
            onTap: () => _addToCart(p),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['name']?.toString() ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(p['categoryName']?.toString() ?? '', style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                    Text('${price.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartPanel() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFF8FAFC),
            child: Row(children: [
              const Icon(Icons.shopping_cart, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text('${_cart.length} kalem', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('Sepet boş', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))))
                : ListView.builder(
                    padding: const EdgeInsets.all(6), itemCount: _cart.length,
                    itemBuilder: (context, i) {
                      final item = _cart[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                        child: Row(children: [
                          Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(4)),
                            child: Center(child: Text('${item['qty']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
                          const SizedBox(width: 6),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['name']?.toString() ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            Text('${_toDouble(item['price']).toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                          ])),
                          InkWell(onTap: () => _showItemOptions(i), child: const Icon(Icons.tune, size: 14, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 4),
                          InkWell(onTap: () => _showItemDiscount(i), child: const Icon(Icons.percent, size: 14, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 4),
                          InkWell(onTap: () => _removeFromCart(i), child: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444))),
                        ]),
                      );
                    }),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Ara toplam', style: TextStyle(fontSize: 11)),
                Text('${_subtotal.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              if (_totalDiscount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('İndirim', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                Text('-${_totalDiscount.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              ]),
              const Divider(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('NET ÖDEME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text('${_netTotal.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _payBtn('NAKİT', Icons.money, const Color(0xFF10B981))),
                const SizedBox(width: 4),
                Expanded(child: _payBtn('K. KARTI', Icons.credit_card, const Color(0xFF3B82F6))),
                const SizedBox(width: 4),
                Expanded(child: _payBtn('PARÇALI', Icons.grid_view, const Color(0xFF8B5CF6))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _payBtn(String label, IconData icon, Color color) {
    return InkWell(
      onTap: _cart.isNotEmpty ? _showPayment : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Column(children: [
          Icon(icon, size: 16, color: color),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

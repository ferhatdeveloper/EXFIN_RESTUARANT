import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';

class CustomerFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existingCustomer;
  final VoidCallback onSaved;

  const CustomerFormDialog({super.key, this.existingCustomer, required this.onSaved});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  bool get _isEdit => widget.existingCustomer != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.existingCustomer!;
      _nameController.text = c['name']?.toString() ?? '';
      _phoneController.text = c['phone']?.toString() ?? '';
      _emailController.text = c['email']?.toString() ?? '';
      _cityController.text = c['city']?.toString() ?? '';
      _addressController.text = c['address']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      if (_isEdit) {
        await pg.query(
          "UPDATE rex_001_customers SET name = @name, phone = @phone, email = @email, city = @city, address = @address WHERE id = @id::uuid",
          params: {
            'id': widget.existingCustomer!['id']?.toString(),
            'name': _nameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'city': _cityController.text,
            'address': _addressController.text,
          },
        );
      } else {
        final code = 'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        await pg.query(
          "INSERT INTO rex_001_customers (firm_nr, code, name, phone, email, city, address, is_active, created_at) VALUES ('001', @code, @name, @phone, @email, @city, @address, true, NOW())",
          params: {
            'code': code,
            'name': _nameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'city': _cityController.text,
            'address': _addressController.text,
          },
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_isEdit ? Icons.edit : Icons.person_add,
                      color: const Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 8),
                  Text(_isEdit ? 'Müşteri Düzenle' : 'Yeni Müşteri',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _field('Ad Soyad *', _nameController, Icons.person_outline),
              _field('Telefon', _phoneController, Icons.phone_outlined),
              _field('E-posta', _emailController, Icons.email_outlined),
              _field('Şehir', _cityController, Icons.location_city_outlined),
              _field('Adres', _addressController, Icons.home_outlined, maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;
  final VoidCallback onSaved;

  const ProductFormDialog({super.key, this.existingProduct, required this.onSaved});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _vatController = TextEditingController(text: '18');
  final _unitController = TextEditingController(text: 'Adet');
  String _categoryCode = '';
  bool _isSaving = false;

  bool get _isEdit => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existingProduct!;
      _nameController.text = p['name']?.toString() ?? '';
      _codeController.text = p['code']?.toString() ?? '';
      _barcodeController.text = p['barcode']?.toString() ?? '';
      _priceController.text = (p['price'] ?? 0).toString();
      _costController.text = (p['cost'] ?? 0).toString();
      _stockController.text = (p['stock'] ?? 0).toString();
      _vatController.text = (p['vatRate'] ?? 18).toString();
      _unitController.text = p['unit']?.toString() ?? 'Adet';
      _categoryCode = p['categoryName']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _vatController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      if (_isEdit) {
        await pg.query(
          "UPDATE rex_001_products SET name = @name, code = @code, barcode = @barcode, price = @price, cost = @cost, stock = @stock, vat_rate = @vat, unit = @unit, category_code = @cat, updated_at = NOW() WHERE id = @id::uuid",
          params: {
            'id': widget.existingProduct!['id']?.toString(),
            'name': _nameController.text,
            'code': _codeController.text,
            'barcode': _barcodeController.text,
            'price': double.tryParse(_priceController.text) ?? 0,
            'cost': double.tryParse(_costController.text) ?? 0,
            'stock': double.tryParse(_stockController.text) ?? 0,
            'vat': double.tryParse(_vatController.text) ?? 18,
            'unit': _unitController.text,
            'cat': _categoryCode,
          },
        );
      } else {
        final code = _codeController.text.isNotEmpty
            ? _codeController.text
            : 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        await pg.query(
          "INSERT INTO rex_001_products (firm_nr, code, barcode, name, price, cost, stock, vat_rate, unit, category_code, is_active, created_at, updated_at) VALUES ('001', @code, @barcode, @name, @price, @cost, @stock, @vat, @unit, @cat, true, NOW(), NOW())",
          params: {
            'code': code,
            'barcode': _barcodeController.text,
            'name': _nameController.text,
            'price': double.tryParse(_priceController.text) ?? 0,
            'cost': double.tryParse(_costController.text) ?? 0,
            'stock': double.tryParse(_stockController.text) ?? 0,
            'vat': double.tryParse(_vatController.text) ?? 18,
            'unit': _unitController.text,
            'cat': _categoryCode,
          },
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_isEdit ? Icons.edit : Icons.add_box,
                      color: const Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  Text(_isEdit ? 'Ürün Düzenle' : 'Yeni Ürün',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _field('Ürün Adı *', _nameController, Icons.inventory_2_outlined),
              Row(
                children: [
                  Expanded(child: _field('Kod', _codeController, Icons.qr_code)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Barkod', _barcodeController, Icons.barcode_reader)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Fiyat', _priceController, Icons.attach_money)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Maliyet', _costController, Icons.money_off)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Stok', _stockController, Icons.inventory)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('KDV %', _vatController, Icons.percent)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Birim', _unitController, Icons.straighten)),
                ],
              ),
              TextField(
                onChanged: (v) => _categoryCode = v,
                controller: TextEditingController(text: _categoryCode),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: label.contains('Fiyat') || label.contains('Maliyet') || label.contains('Stok') || label.contains('KDV')
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

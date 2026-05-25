import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final String currency;
  final Function(String method, double paid, double discount) onComplete;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    this.currency = 'IQD',
    required this.onComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMethod = 'cash';
  String _discountType = 'percent';
  double _discountValue = 0;
  double _enteredAmount = 0;
  final _discountController = TextEditingController();
  final _amountController = TextEditingController();

  double get _discountAmount {
    if (_discountType == 'percent') {
      return widget.totalAmount * _discountValue / 100;
    }
    return _discountValue;
  }

  double get _netTotal => widget.totalAmount - _discountAmount;

  @override
  void dispose() {
    _discountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _setQuickDiscount(double percent) {
    setState(() {
      _discountType = 'percent';
      _discountValue = percent;
      _discountController.text = percent.toStringAsFixed(0);
    });
  }

  void _setQuickAmount(double amount) {
    setState(() {
      _enteredAmount += amount;
      _amountController.text = _enteredAmount.toStringAsFixed(0);
    });
  }

  void _setFullAmount() {
    setState(() {
      _enteredAmount = _netTotal;
      _amountController.text = _netTotal.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildLeftPanel()),
                  Container(width: 1, color: const Color(0xFFE2E8F0)),
                  Expanded(child: _buildRightPanel()),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('Ödeme Al',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          _headerChip('Numpad', const Color(0xFF3B82F6)),
          const SizedBox(width: 6),
          _headerChip('FIB', const Color(0xFFEF4444)),
          const SizedBox(width: 6),
          _headerChip('FastPay', const Color(0xFF10B981)),
          const SizedBox(width: 6),
          _headerChip('ZainCash', const Color(0xFF8B5CF6)),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('~~ İndirim (İsteğe Bağlı)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              _toggleButton('%', _discountType == 'percent', () => setState(() => _discountType = 'percent')),
              const SizedBox(width: 8),
              _toggleButton('${widget.currency}', _discountType == 'fixed', () => setState(() => _discountType = 'fixed')),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'İndirim Oranı (%)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _discountValue = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [5, 10, 15, 20].map((v) => _quickChip('%$v', () => _setQuickDiscount(v.toDouble()))).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ÖDEME ÖZETİ',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1)),
                const SizedBox(height: 10),
                _summaryRow('Ara Toplam:', widget.totalAmount),
                if (_discountAmount > 0) _summaryRow('İndirim:', -_discountAmount, color: const Color(0xFFEF4444)),
                const Divider(),
                _summaryRow('Toplam:', _netTotal, bold: true, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ödeme Yöntemi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _methodButton('Nakit', Icons.money, 'cash'),
              _methodButton('Kart (POS)', Icons.credit_card, 'card'),
              _methodButton('Veresiye (Cari)', Icons.account_balance_wallet_outlined, 'credit'),
              _methodButton('QR Ödeme', Icons.qr_code, 'qr'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Para Birimi & Kurlar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _currencyChip('IQ IQD', true),
              const SizedBox(width: 8),
              _currencyChip('US USD\n1 = 1310 IQD', false),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tutar:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _enteredAmount = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _quickChip('+1.000', () => _setQuickAmount(1000)),
              _quickChip('+5.000', () => _setQuickAmount(5000)),
              _quickChip('+10.000', () => _setQuickAmount(10000)),
              _quickChip('+20.000', () => _setQuickAmount(20000)),
              _quickChip('+50.000', () => _setQuickAmount(50000)),
              _quickChip('+100.000', () => _setQuickAmount(100000)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _setFullAmount,
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              child: const Text('Tam Tutar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ödeme Ekle', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Yazdır'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onComplete(_paymentMethod, _enteredAmount, _discountAmount);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Complete Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB)),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _methodButton(String label, IconData icon, String method) {
    final active = _paymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB).withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? const Color(0xFF2563EB) : const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }

  Widget _currencyChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB).withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: active ? 2 : 1,
        ),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF2563EB) : const Color(0xFF374151))),
    );
  }

  Widget _quickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {Color? color, bool bold = false, double size = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(
            '${value.toStringAsFixed(0)} ${widget.currency}',
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (bold ? const Color(0xFF2563EB) : const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}

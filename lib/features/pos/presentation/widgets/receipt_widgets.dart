import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class ReceiptPreviewDialog extends StatefulWidget {
  final String receiptNo;
  final String cashier;
  final String tableNo;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double total;
  final double paid;

  const ReceiptPreviewDialog({
    super.key,
    required this.receiptNo,
    required this.cashier,
    required this.tableNo,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    this.paid = 0,
  });

  @override
  State<ReceiptPreviewDialog> createState() => _ReceiptPreviewDialogState();
}

class _ReceiptPreviewDialogState extends State<ReceiptPreviewDialog> {
  AppLanguage _lang = AppLanguage.tr;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(),
            Expanded(child: _buildReceiptContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          ...[AppLanguage.tr, AppLanguage.en, AppLanguage.ar, AppLanguage.ku]
              .map((l) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => setState(() => _lang = l),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _lang == l
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _lang == l ? Colors.white : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  )),
          const Spacer(),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.download, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Icon(Icons.restaurant, size: 28, color: Color(0xFF1E293B)),
            const SizedBox(height: 4),
            const Text('DESTERHAN RESTUARANT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const Text('Profesyonel ERP Çözümleri',
                style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                textAlign: TextAlign.center),
            const Text('DESTERHAN RESTUARANT',
                style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            _receiptLine('FİŞ NO:', widget.receiptNo),
            _receiptLine('TARİH:', dateStr),
            _receiptLine('KASİYER:', widget.cashier),
            _receiptLine('MASA:', widget.tableNo),
            const SizedBox(height: 8),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(flex: 4, child: Text('Ürün', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600))),
                const Expanded(flex: 1, child: Text('Adet', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const Expanded(flex: 2, child: Text('Tutar', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 4),
            ...widget.items.map((item) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(item['name']?.toString() ?? '-',
                              style: const TextStyle(fontSize: 10)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('${item['quantity'] ?? 1}',
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${_toDouble(item['total']).toStringAsFixed(0)} IQD',
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item['quantity'] ?? 1} × ${_toDouble(item['unitPrice']).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                    ),
                    Container(height: 0.5, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 2),
                  ],
                )),
            const SizedBox(height: 8),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 6),
            _receiptLine('ARA TOPLAM:', '${widget.subtotal.toStringAsFixed(0)} IQD'),
            if (widget.discount > 0)
              _receiptLine('İNDİRİM:', '-${widget.discount.toStringAsFixed(0)} IQD'),
            _receiptLine('TOPLAM:', '${widget.total.toStringAsFixed(0)} IQD', bold: true),
            const SizedBox(height: 4),
            const Text('ÖDEME DETAYLARI:',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
            _receiptLine('ÖDENEN:', '${widget.paid.toStringAsFixed(0)} IQD'),
            const SizedBox(height: 12),
            Container(
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: const Center(
                child: Text('||||||||||||||||||||',
                    style: TextStyle(fontSize: 10, letterSpacing: -1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print, size: 16),
              label: Text(L.get('print', _lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(L.get('close_without_print', _lang)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

class PrintTypeDialog extends StatefulWidget {
  final VoidCallback onPreview;

  const PrintTypeDialog({super.key, required this.onPreview});

  @override
  State<PrintTypeDialog> createState() => _PrintTypeDialogState();
}

class _PrintTypeDialogState extends State<PrintTypeDialog> {
  String _type = 'bill';
  AppLanguage _lang = AppLanguage.tr;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(L.get('print_80mm', _lang),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(L.get('print_80mm_desc', _lang),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(L.get('receipt_type', _lang),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _typeCard(L.get('bill_receipt', _lang), 'Tutarlar', Icons.receipt_long_outlined, 'bill'),
                const SizedBox(width: 12),
                _typeCard(L.get('kitchen_receipt', _lang), 'Ürün / adet', Icons.soup_kitchen_outlined, 'kitchen'),
              ],
            ),
            const SizedBox(height: 16),
            Text('${L.get('language', _lang)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [AppLanguage.tr, AppLanguage.en, AppLanguage.ar, AppLanguage.ku].map((l) {
                final active = _lang == l;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _lang = l),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: Text(
                        l.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onPreview();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(L.get('preview', _lang)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(String title, String subtitle, IconData icon, String type) {
    final active = _type == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2563EB).withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? const Color(0xFF2563EB) : const Color(0xFF374151))),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }
}

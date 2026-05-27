import 'package:flutter/material.dart';

class StaffPinDialog extends StatefulWidget {
  final List<Map<String, dynamic>> staffList;
  final Function(Map<String, dynamic> staff) onSelected;

  const StaffPinDialog({
    super.key,
    required this.staffList,
    required this.onSelected,
  });

  @override
  State<StaffPinDialog> createState() => _StaffPinDialogState();
}

class _StaffPinDialogState extends State<StaffPinDialog> {
  String _enteredPin = '';
  String? _error;

  void _onNumber(String n) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += n;
        _error = null;
      });
      if (_enteredPin.length == 4) _tryLogin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  void _onClear() => setState(() => _enteredPin = '');

  void _tryLogin() {
    final match = widget.staffList.firstWhere(
      (s) => s['pin']?.toString() == _enteredPin,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      widget.onSelected(match);
      Navigator.pop(context);
    } else {
      setState(() {
        _error = 'Geçersiz PIN';
        _enteredPin = '';
      });
    }
  }

  void _selectDirect(Map<String, dynamic> staff) {
    widget.onSelected(staff);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_pin_outlined,
                  color: Color(0xFF2563EB), size: 26),
            ),
            const SizedBox(height: 12),
            const Text('Personel Seçimi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('PIN girin veya personel seçin',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _enteredPin.length
                      ? const Color(0xFF2563EB)
                      : Colors.transparent,
                  border: Border.all(
                    color: i < _enteredPin.length
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
              )),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
            ],
            const SizedBox(height: 14),
            _buildNumpad(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Hızlı Seç:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.staffList.map((s) => InkWell(
                onTap: () => _selectDirect(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        child: Text(
                          (s['name']?.toString() ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(s['name']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Column(
        children: [
          _numRow(['1', '2', '3']),
          const SizedBox(height: 6),
          _numRow(['4', '5', '6']),
          const SizedBox(height: 6),
          _numRow(['7', '8', '9']),
          const SizedBox(height: 6),
          _numRow(['C', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _numRow(List<String> keys) {
    return Row(
      children: keys.map((k) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: k == 'C' || k == '⌫'
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                if (k == 'C') _onClear();
                else if (k == '⌫') _onBackspace();
                else _onNumber(k);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: k == '⌫'
                    ? const Icon(Icons.backspace_outlined, size: 16, color: Color(0xFF64748B))
                    : Text(k, style: TextStyle(
                        fontSize: k == 'C' ? 12 : 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      )),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class ProductOptionsDialog extends StatefulWidget {
  final String productName;
  final List<Map<String, dynamic>> options;
  final Function(List<String> selectedOptions, String? note) onConfirm;

  const ProductOptionsDialog({
    super.key,
    required this.productName,
    this.options = const [],
    required this.onConfirm,
  });

  @override
  State<ProductOptionsDialog> createState() => _ProductOptionsDialogState();
}

class _ProductOptionsDialogState extends State<ProductOptionsDialog> {
  final Set<String> _selected = {};
  final _noteController = TextEditingController();

  final _defaultOptions = [
    'Az Pişmiş', 'Orta Pişmiş', 'Çok Pişmiş',
    'Acısız', 'Az Acılı', 'Çok Acılı',
    'Ketçapsız', 'Mayonezsiz', 'Soğansız',
    'Ekstra Peynir', 'Ekstra Sos', 'Büyük Boy',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options.isNotEmpty
        ? widget.options.map((o) => o['name']?.toString() ?? '').toList()
        : _defaultOptions;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF8B5CF6), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.productName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Ürün seçenekleri ve notlar',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: options.map((opt) {
                final sel = _selected.contains(opt);
                return FilterChip(
                  label: Text(opt, style: TextStyle(
                    fontSize: 11,
                    color: sel ? Colors.white : const Color(0xFF374151),
                  )),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) _selected.add(opt); else _selected.remove(opt);
                  }),
                  selectedColor: const Color(0xFF8B5CF6),
                  checkmarkColor: Colors.white,
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: BorderSide(color: sel ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Sipariş notu (opsiyonel)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
                isDense: true,
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(
                    _selected.toList(),
                    _noteController.text.isNotEmpty ? _noteController.text : null,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _selected.isEmpty ? 'Not Ekle' : '${_selected.length} seçenek ile ekle',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

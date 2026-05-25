import 'package:flutter/material.dart';

class TableOpenDialog extends StatefulWidget {
  final String tableNumber;
  final String floorName;
  final int defaultSeats;
  final String currentStaff;
  final Function(int guestCount) onOpen;

  const TableOpenDialog({
    super.key,
    required this.tableNumber,
    required this.floorName,
    this.defaultSeats = 4,
    required this.currentStaff,
    required this.onOpen,
  });

  @override
  State<TableOpenDialog> createState() => _TableOpenDialogState();
}

class _TableOpenDialogState extends State<TableOpenDialog> {
  late int _guestCount;

  @override
  void initState() {
    super.initState();
    _guestCount = widget.defaultSeats;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildStaffRow(),
                  const SizedBox(height: 20),
                  _buildGuestCounter(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MASA ${widget.tableNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.floorName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline,
                size: 18, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GARSON',
                  style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              Text(widget.currentStaff.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.swap_horiz, size: 14),
            label: const Text('DEĞİŞTİR',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCounter() {
    return Column(
      children: [
        const Text('KİŞİ SAYISI',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counterButton(Icons.remove, () {
              if (_guestCount > 1) setState(() => _guestCount--);
            }),
            const SizedBox(width: 20),
            Column(
              children: [
                Text(
                  '$_guestCount',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800),
                ),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: const Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text('kişi',
                        style: TextStyle(
                            fontSize: 12, color: const Color(0xFF2563EB))),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 20),
            _counterButton(Icons.add, () {
              if (_guestCount < 20) setState(() => _guestCount++);
            }),
          ],
        ),
      ],
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: icon == Icons.add
              ? const Color(0xFF2563EB)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: icon == Icons.add
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(icon,
            color: icon == Icons.add
                ? Colors.white
                : const Color(0xFF374151),
            size: 20),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('VAZGEÇ'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              widget.onOpen(_guestCount);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('MASAYI AÇ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

class VoidReasonDialog extends StatefulWidget {
  final Function(String reason) onVoid;

  const VoidReasonDialog({super.key, required this.onVoid});

  @override
  State<VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<VoidReasonDialog> {
  String? _selectedReason;
  final _customController = TextEditingController();

  final _reasons = [
    'Müşteri vazgeçti',
    'Yanlış sipariş',
    'Ürün bitti',
    'Kalite sorunu',
    'Çok bekletti',
    'Diğer',
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_outlined, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            const Text('İptal Sebebi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Lütfen iptal sebebini seçin',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ..._reasons.map((r) => RadioListTile<String>(
                  value: r,
                  groupValue: _selectedReason,
                  onChanged: (v) => setState(() => _selectedReason = v),
                  title: Text(r, style: const TextStyle(fontSize: 13)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
            if (_selectedReason == 'Diğer') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customController,
                decoration: InputDecoration(
                  hintText: 'Açıklama yazın...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(10),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedReason != null
                        ? () {
                            final reason = _selectedReason == 'Diğer'
                                ? _customController.text
                                : _selectedReason!;
                            widget.onVoid(reason);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('İptal Et'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DiscountDialog extends StatefulWidget {
  final double currentPrice;
  final Function(double discountAmount) onApply;

  const DiscountDialog({
    super.key,
    required this.currentPrice,
    required this.onApply,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  String _type = 'percent';
  final _controller = TextEditingController();

  double get _discountAmount {
    final val = double.tryParse(_controller.text) ?? 0;
    if (_type == 'percent') return widget.currentPrice * val / 100;
    return val;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.discount_outlined, size: 36, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            const Text('İndirim Uygula',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                _tab('%', 'percent'),
                const SizedBox(width: 8),
                _tab('IQD', 'fixed'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _type == 'percent' ? 'Ör: 10' : 'Ör: 5000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [5, 10, 15, 20, 25, 50].map((v) {
                return ActionChip(
                  label: Text(_type == 'percent' ? '%$v' : '${v * 1000}',
                      style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _controller.text = '${_type == 'percent' ? v : v * 1000}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('İndirim:', style: TextStyle(fontSize: 12)),
                  Text('-${_discountAmount.toStringAsFixed(0)} IQD',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('İptal'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_discountAmount);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Uygula'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, String type) {
    final active = _type == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF59E0B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF374151),
            )),
          ),
        ),
      ),
    );
  }
}

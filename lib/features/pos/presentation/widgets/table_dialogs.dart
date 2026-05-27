import 'package:flutter/material.dart';

class SplitBillDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final Function(List<List<Map<String, dynamic>>> splits) onSplit;

  const SplitBillDialog({
    super.key,
    required this.items,
    required this.totalAmount,
    required this.onSplit,
  });

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  int _splitCount = 2;
  String _splitMode = 'equal';

  double get _perPerson => widget.totalAmount / _splitCount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_split, size: 36, color: Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            const Text('Adisyon Parçala',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Toplam: ${widget.totalAmount.toStringAsFixed(0)} IQD',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            Row(
              children: [
                _modeButton('Eşit Böl', 'equal', Icons.balance),
                const SizedBox(width: 10),
                _modeButton('Ürüne Göre', 'items', Icons.list_alt),
              ],
            ),
            const SizedBox(height: 16),
            if (_splitMode == 'equal') ...[
              const Text('Kişi Sayısı',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _counterBtn(Icons.remove, () {
                    if (_splitCount > 2) setState(() => _splitCount--);
                  }),
                  const SizedBox(width: 20),
                  Text('$_splitCount',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 20),
                  _counterBtn(Icons.add, () {
                    if (_splitCount < 10) setState(() => _splitCount++);
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kişi başı:', style: TextStyle(fontSize: 13)),
                    Text('${_perPerson.toStringAsFixed(0)} IQD',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ürünleri sürükle-bırak ile gruplara ayırın (yakında)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
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
                      widget.onSplit([]);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Parçala'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, String mode, IconData icon) {
    final active = _splitMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _splitMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF3B82F6).withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? const Color(0xFF3B82F6) : const Color(0xFF64748B), size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? const Color(0xFF3B82F6) : const Color(0xFF374151),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF3B82F6)),
      ),
    );
  }
}

class MoveTableDialog extends StatefulWidget {
  final String currentTable;
  final List<Map<String, dynamic>> availableTables;
  final Function(String targetTableId) onMove;

  const MoveTableDialog({
    super.key,
    required this.currentTable,
    required this.availableTables,
    required this.onMove,
  });

  @override
  State<MoveTableDialog> createState() => _MoveTableDialogState();
}

class _MoveTableDialogState extends State<MoveTableDialog> {
  String? _selectedTableId;

  @override
  Widget build(BuildContext context) {
    final emptyTables = widget.availableTables
        .where((t) => t['status'] == 'empty')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, size: 36, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            const Text('Masa Taşı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Masa ${widget.currentTable} → ?',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Boş masalar:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: emptyTables.length,
                itemBuilder: (context, i) {
                  final t = emptyTables[i];
                  final id = t['id']?.toString() ?? '';
                  final selected = _selectedTableId == id;
                  return InkWell(
                    onTap: () => setState(() => _selectedTableId = id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE2E8F0),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          t['name']?.toString() ?? '?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
                    onPressed: _selectedTableId != null
                        ? () {
                            widget.onMove(_selectedTableId!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Taşı'),
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

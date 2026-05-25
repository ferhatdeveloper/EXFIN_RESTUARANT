import 'package:flutter/material.dart';

class TableStatusColors {
  static const Map<String, Color> colors = {
    'empty': Color(0xFF10B981),
    'occupied': Color(0xFF3B82F6),
    'kitchen': Color(0xFFF59E0B),
    'served': Color(0xFF8B5CF6),
    'billing': Color(0xFFEF4444),
    'cleaning': Color(0xFF64748B),
    'reserved': Color(0xFFF59E0B),
  };

  static const Map<String, String> labels = {
    'empty': 'BOŞ',
    'occupied': 'DOLU',
    'kitchen': 'MUTFAKTA',
    'served': 'SERVİSTE',
    'billing': 'HESAP',
    'cleaning': 'TEMİZLİK',
    'reserved': 'REZERVE',
  };

  static const Map<String, IconData> icons = {
    'empty': Icons.check_circle_outline,
    'occupied': Icons.people,
    'kitchen': Icons.soup_kitchen,
    'served': Icons.room_service,
    'billing': Icons.receipt,
    'cleaning': Icons.cleaning_services,
    'reserved': Icons.event,
  };

  static Color getColor(String? status) => colors[status ?? 'empty'] ?? colors['empty']!;
  static String getLabel(String? status) => labels[status ?? 'empty'] ?? 'BOŞ';
  static IconData getIcon(String? status) => icons[status ?? 'empty'] ?? Icons.check_circle_outline;
}

class TableCard extends StatelessWidget {
  final Map<String, dynamic> table;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    this.onLongPress,
  });

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final status = table['status']?.toString() ?? 'empty';
    final color = TableStatusColors.getColor(status);
    final number = table['name']?.toString() ?? '?';
    final seats = table['capacity'] ?? 4;
    final total = _toDouble(table['total']);
    final waiter = table['waiter']?.toString();

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(TableStatusColors.getIcon(status), color: Colors.white.withValues(alpha: 0.7), size: 14),
                  if (waiter != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(waiter.substring(0, waiter.length > 2 ? 2 : waiter.length).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const Spacer(),
              Center(
                child: Text(
                  number,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              if (status == 'billing')
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                    child: const Text('HESAP', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.people, color: Colors.white70, size: 12),
                    const SizedBox(width: 2),
                    Text('$seats', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ]),
                  Text(
                    total > 0 ? '${total.toStringAsFixed(0)}' : '0',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TableLegend extends StatelessWidget {
  const TableLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: TableStatusColors.colors.entries.map((e) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(TableStatusColors.labels[e.key] ?? '', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          ]),
        )).toList(),
      ),
    );
  }
}

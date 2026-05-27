import 'package:flutter/material.dart';

class ParkedOrdersDialog extends StatelessWidget {
  final List<Map<String, dynamic>> parkedOrders;
  final Function(Map<String, dynamic> order) onResume;

  const ParkedOrdersDialog({
    super.key,
    required this.parkedOrders,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text('Park Edilen Siparişler',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${parkedOrders.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: parkedOrders.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 40, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 8),
                          Text('Park edilen sipariş yok',
                              style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: parkedOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final order = parkedOrders[i];
                        final items = order['items'] as List? ?? [];
                        final total = _toDouble(order['total']);

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: InkWell(
                            onTap: () {
                              onResume(order);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        order['tableNo']?.toString() ?? '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Masa ${order['tableNo']} • ${items.length} kalem',
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          items.take(3).join(', '),
                                          style: const TextStyle(
                                              fontSize: 11, color: Color(0xFF64748B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${total.toStringAsFixed(0)} IQD',
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w700)),
                                      Text(order['time']?.toString() ?? '',
                                          style: const TextStyle(
                                              fontSize: 10, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.play_circle_outline,
                                      color: Color(0xFF10B981), size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

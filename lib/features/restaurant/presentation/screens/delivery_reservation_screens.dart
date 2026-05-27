import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, order_no, status, total_amount, waiter, note, created_at FROM rest.rex_001_01_rest_orders WHERE status != 'closed' ORDER BY created_at DESC LIMIT 50",
      );
      if (mounted) setState(() { _orders = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          BackofficeHeader(
            title: 'Paket Servis / Delivery',
            icon: Icons.delivery_dining,
            gradientStart: const Color(0xFF3B82F6),
            gradientEnd: const Color(0xFF2563EB),
            count: _orders.length,
            actions: [
              HeaderIconButton(icon: Icons.refresh, onTap: _load),
              const SizedBox(width: 6),
              HeaderIconButton(icon: Icons.add, label: 'Yeni Sipariş', onTap: () {}),
            ],
          ),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? _emptyState()
                    : _buildOrderCards(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: ['all', 'open', 'preparing', 'ready', 'delivered'].map((f) {
          final labels = {'all': 'Tümü', 'open': 'Yeni', 'preparing': 'Hazırlanıyor', 'ready': 'Hazır', 'delivered': 'Teslim'};
          final active = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(labels[f] ?? f, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : const Color(0xFF374151),
                )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text('Paket sipariş bulunamadı', style: TextStyle(color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildOrderCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      itemBuilder: (context, i) {
        final o = _orders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delivery_dining, color: Color(0xFF3B82F6), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o['order_no']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(o['note']?.toString() ?? 'Paket sipariş', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_toDouble(o['total_amount']).toStringAsFixed(0)} IQD',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    StatusBadge(label: o['status']?.toString() ?? 'open', color: const Color(0xFF3B82F6)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, customer_name, phone, reservation_date, reservation_time, guest_count, table_number, status, note FROM rest.rex_001_01_rest_reservations ORDER BY reservation_date DESC, reservation_time DESC LIMIT 50",
      );
      if (mounted) setState(() { _reservations = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          BackofficeHeader(
            title: 'Rezervasyonlar',
            icon: Icons.calendar_month_outlined,
            gradientStart: const Color(0xFFF43F5E),
            gradientEnd: const Color(0xFFE11D48),
            count: _reservations.length,
            actions: [
              HeaderIconButton(icon: Icons.refresh, onTap: _load),
              const SizedBox(width: 6),
              HeaderIconButton(icon: Icons.add, label: 'Yeni Rezervasyon', onTap: () {}),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reservations.isEmpty
                    ? const Center(child: Text('Rezervasyon bulunamadı', style: TextStyle(color: Color(0xFF94A3B8))))
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _reservations.length,
      itemBuilder: (context, i) {
        final r = _reservations[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r['reservation_date']?.toString().split('-').last ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFF43F5E))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['customer_name']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('${r['reservation_time'] ?? ''} • ${r['guest_count'] ?? 2} kişi • Masa ${r['table_number'] ?? '-'}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      if (r['phone'] != null)
                        Text(r['phone'].toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                StatusBadge(
                  label: _statusLabel(r['status']?.toString()),
                  color: _statusColor(r['status']?.toString()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'pending': return 'Bekliyor';
      case 'confirmed': return 'Onaylı';
      case 'seated': return 'Oturdu';
      case 'cancelled': return 'İptal';
      default: return s ?? 'Bekliyor';
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'confirmed': return const Color(0xFF10B981);
      case 'seated': return const Color(0xFF3B82F6);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }
}

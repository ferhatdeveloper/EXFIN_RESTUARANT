import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filtered = [];
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
        "SELECT id, code, name, phone, phone2, email, city, address, balance, total_spent, customer_tier, is_active, created_at FROM rex_001_customers WHERE is_active = true ORDER BY name",
      );
      if (mounted) setState(() { _customers = results; _filtered = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = _customers.where((c) {
        final s = q.toLowerCase();
        return (c['name'] ?? '').toString().toLowerCase().contains(s) ||
            (c['code'] ?? '').toString().toLowerCase().contains(s) ||
            (c['phone'] ?? '').toString().contains(s) ||
            (c['email'] ?? '').toString().toLowerCase().contains(s);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Müşteriler',
          icon: Icons.people_outline,
          gradientStart: const Color(0xFF2563EB),
          gradientEnd: const Color(0xFF1D4ED8),
          count: _customers.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.file_download_outlined, label: 'Excel', onTap: () {}),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.person_add, label: 'Yeni Müşteri', onTap: () {}),
          ],
        ),
        BackofficeSearchBar(hint: 'Ad, kod, telefon veya e-posta ara...', onChanged: _onSearch),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('Müşteri bulunamadı'))
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = _filtered[i];
        final spentRaw = c['total_spent'];
        final spent = spentRaw is num ? spentRaw.toDouble() : double.tryParse(spentRaw?.toString() ?? '0') ?? 0;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
            child: Text(
              (c['name']?.toString() ?? '?')[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          title: Text(c['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(
            [c['phone'], c['email'], c['city']].where((v) => v != null && v.toString().isNotEmpty).join(' • '),
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${spent.toStringAsFixed(0)} IQD',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        );
      },
    );
  }
}

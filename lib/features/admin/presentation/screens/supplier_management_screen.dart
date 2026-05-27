import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  List<Map<String, dynamic>> _suppliers = [];
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
        "SELECT id, code, name, phone, email, city, address, balance, tax_nr, tax_office, contact_person, payment_terms, is_active FROM rex_001_suppliers WHERE is_active = true ORDER BY name",
      );
      if (mounted) setState(() { _suppliers = results; _filtered = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = _suppliers.where((s) {
        final search = q.toLowerCase();
        return (s['name'] ?? '').toString().toLowerCase().contains(search) ||
            (s['code'] ?? '').toString().toLowerCase().contains(search) ||
            (s['phone'] ?? '').toString().contains(search);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Tedarikçiler',
          icon: Icons.business_outlined,
          gradientStart: const Color(0xFFF97316),
          gradientEnd: const Color(0xFFEA580C),
          count: _suppliers.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Tedarikçi', onTap: () {}),
          ],
        ),
        BackofficeSearchBar(hint: 'Tedarikçi adı, kodu veya telefon ara...', onChanged: _onSearch),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('Tedarikçi bulunamadı'))
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
        final s = _filtered[i];
        final balRaw = s['balance'];
        final balance = balRaw is num ? balRaw.toDouble() : double.tryParse(balRaw?.toString() ?? '0') ?? 0;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.1),
            child: const Icon(Icons.business, size: 18, color: Color(0xFFF97316)),
          ),
          title: Text(s['name']?.toString() ?? '-',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(
            [s['phone'], s['city'], s['contact_person']].where((v) => v != null && v.toString().isNotEmpty).join(' • '),
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(
                label: 'Tedarikçi',
                color: const Color(0xFFF97316),
              ),
              const SizedBox(width: 8),
              if (balance != 0)
                Text(
                  '${balance.toStringAsFixed(0)} IQD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: balance > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

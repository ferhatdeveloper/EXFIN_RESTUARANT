import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../widgets/backoffice_widgets.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, code, name, type, city, address, phone, firm_nr, manager_name, is_main, is_active FROM public.stores ORDER BY name",
      );
      if (mounted) setState(() { _stores = results; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(title: 'Mağaza / Depo Yönetimi', icon: Icons.store_outlined,
          gradientStart: const Color(0xFF0EA5E9), gradientEnd: const Color(0xFF0284C7), count: _stores.length,
          actions: [HeaderIconButton(icon: Icons.refresh, onTap: _load), const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Mağaza', onTap: () {})]),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _stores.isEmpty ? const Center(child: Text('Mağaza bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: _stores.length,
                  itemBuilder: (context, i) {
                    final s = _stores[i];
                    final isMain = s['is_main'] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: (isMain ? const Color(0xFF0EA5E9) : const Color(0xFF64748B)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(isMain ? Icons.warehouse : Icons.store,
                            color: isMain ? const Color(0xFF0EA5E9) : const Color(0xFF64748B), size: 22)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(s['name']?.toString() ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            if (isMain) ...[const SizedBox(width: 8), const StatusBadge(label: 'Ana Depo', color: Color(0xFF0EA5E9))],
                          ]),
                          Text([s['city'], s['address'], s['phone']].where((v) => v != null && v.toString().isNotEmpty).join(' • '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          if (s['manager_name'] != null)
                            Text('Sorumlu: ${s['manager_name']}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(s['code']?.toString() ?? '', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                          const SizedBox(height: 4),
                          StatusBadge(label: s['is_active'] == true ? 'Aktif' : 'Pasif',
                            color: s['is_active'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        ]),
                      ])),
                    );
                  }),
        ),
      ],
    );
  }
}

class PrinterSettingsScreen extends StatelessWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BackofficeHeader(title: 'Yazıcı Ayarları', icon: Icons.print_outlined,
          gradientStart: Color(0xFF64748B), gradientEnd: Color(0xFF475569)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _printerCard('MUTFAK', 'Termal 80mm', 'system', true),
              const SizedBox(height: 12),
              _printerCard('KASA', 'Termal 80mm', 'system', true),
              const SizedBox(height: 12),
              _printerCard('BAR', 'Termal 58mm', 'network', false),
              const SizedBox(height: 24),
              const Text('Kategori → Yazıcı Yönlendirme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _routeRow('ANA YEMEKLER', 'MUTFAK'),
              _routeRow('İÇECEKLER', 'BAR'),
              _routeRow('TATLILAR', 'MUTFAK'),
              _routeRow('ATIŞTIRMALIK', 'MUTFAK'),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Ayarları Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
            ]),
          ),
        ),
      ],
    );
  }

  static Widget _printerCard(String name, String type, String connection, bool online) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF64748B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.print, color: Color(0xFF64748B), size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text('$type • $connection', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ])),
        StatusBadge(label: online ? 'Online' : 'Offline', color: online ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
      ])),
    );
  }

  static Widget _routeRow(String category, String printer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Text(category, style: const TextStyle(fontSize: 12)),
        )),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF94A3B8))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2))),
          child: Text(printer, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
        ),
      ]),
    );
  }
}

class ServiceCardsScreen extends StatefulWidget {
  const ServiceCardsScreen({super.key});

  @override
  State<ServiceCardsScreen> createState() => _ServiceCardsScreenState();
}

class _ServiceCardsScreenState extends State<ServiceCardsScreen> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, code, name, description, unit, unit_price, tax_rate, is_active FROM rex_001_services ORDER BY name",
      );
      if (mounted) setState(() { _services = results; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(title: 'Hizmet Kartları', icon: Icons.build_outlined,
          gradientStart: const Color(0xFF0891B2), gradientEnd: const Color(0xFF0E7490), count: _services.length,
          actions: [HeaderIconButton(icon: Icons.refresh, onTap: _load), const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Hizmet', onTap: () {})]),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _services.isEmpty ? const Center(child: Text('Hizmet kartı bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: _services.length,
                  itemBuilder: (context, i) {
                    final s = _services[i];
                    final price = _toDouble(s['unit_price']);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(width: 36, height: 36,
                          decoration: BoxDecoration(color: const Color(0xFF0891B2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.build_circle_outlined, color: Color(0xFF0891B2), size: 18)),
                        title: Text(s['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${s['code'] ?? ''} • ${s['unit'] ?? 'Adet'} • KDV %${s['tax_rate'] ?? 18}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        trailing: Text('${price.toStringAsFixed(0)} IQD',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0891B2))),
                      ),
                    );
                  }),
        ),
      ],
    );
  }
}

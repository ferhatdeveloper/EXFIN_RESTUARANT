import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class BeautyModule extends StatefulWidget {
  const BeautyModule({super.key});

  @override
  State<BeautyModule> createState() => _BeautyModuleState();
}

class _BeautyModuleState extends State<BeautyModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 5, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        const BackofficeHeader(title: 'Beauty / Klinik Yönetimi', icon: Icons.spa_outlined,
          gradientStart: Color(0xFF9333EA), gradientEnd: Color(0xFF7C3AED)),
        TabBar(controller: _tabController, labelColor: const Color(0xFF9333EA), unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF9333EA), labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), isScrollable: true,
          tabs: const [Tab(text: 'UZMANLAR'), Tab(text: 'HİZMETLER'), Tab(text: 'RANDEVULAR'), Tab(text: 'PAKETLER'), Tab(text: 'CİHAZLAR')]),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _SpecialistList(), _BeautyServiceList(), _AppointmentList(), _PackageList(), _DeviceList(),
        ])),
      ]),
    );
  }
}

class _SpecialistList extends StatefulWidget { @override State<_SpecialistList> createState() => _SpecialistListState(); }
class _SpecialistListState extends State<_SpecialistList> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, name, phone, specialty, color, commission_rate, is_active FROM beauty.rex_001_beauty_specialists ORDER BY name");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i];
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: CircleAvatar(radius: 18, backgroundColor: const Color(0xFF9333EA).withValues(alpha: 0.15),
          child: Text((d['name']?.toString() ?? '?')[0], style: const TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.w700))),
        title: Text(d['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${d['specialty'] ?? ''} • %${d['commission_rate'] ?? 0} komisyon', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: StatusBadge(label: d['is_active'] == true ? 'Aktif' : 'Pasif', color: d['is_active'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
      ));
    });
  }
}

class _BeautyServiceList extends StatefulWidget { @override State<_BeautyServiceList> createState() => _BeautyServiceListState(); }
class _BeautyServiceListState extends State<_BeautyServiceList> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  double _toDouble(dynamic v) { if (v == null) return 0; if (v is num) return v.toDouble(); return double.tryParse(v.toString()) ?? 0; }
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, name, category, duration_min, price, color, is_active FROM beauty.rex_001_beauty_services ORDER BY name");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i];
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF9333EA).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.spa, color: Color(0xFF9333EA), size: 18)),
        title: Text(d['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${d['category'] ?? ''} • ${d['duration_min'] ?? 30} dk', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: Text('${_toDouble(d['price']).toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF9333EA))),
      ));
    });
  }
}

class _AppointmentList extends StatefulWidget { @override State<_AppointmentList> createState() => _AppointmentListState(); }
class _AppointmentListState extends State<_AppointmentList> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, appointment_date, appointment_time, duration, status, type, total_price FROM beauty.rex_001_01_beauty_appointments ORDER BY appointment_date DESC LIMIT 30");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Randevu bulunamadı'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; final status = d['status']?.toString() ?? 'scheduled';
      Color sc; switch (status) { case 'completed': sc = const Color(0xFF10B981); break; case 'cancelled': sc = const Color(0xFFEF4444); break; default: sc = const Color(0xFF3B82F6); }
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.event, color: sc, size: 18)),
        title: Text('${d['appointment_date'] ?? ''} ${d['appointment_time'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        subtitle: Text('${d['duration'] ?? 30} dk • ${d['type'] ?? 'regular'}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: StatusBadge(label: status, color: sc),
      ));
    });
  }
}

class _PackageList extends StatefulWidget { @override State<_PackageList> createState() => _PackageListState(); }
class _PackageListState extends State<_PackageList> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  double _toDouble(dynamic v) { if (v == null) return 0; if (v is num) return v.toDouble(); return double.tryParse(v.toString()) ?? 0; }
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, name, description, total_sessions, price, is_active FROM beauty.rex_001_beauty_packages ORDER BY name");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Paket bulunamadı'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i];
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.card_giftcard, color: Color(0xFF6366F1), size: 18)),
        title: Text(d['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${d['total_sessions'] ?? 1} seans • ${d['description'] ?? ''}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: Text('${_toDouble(d['price']).toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
      ));
    });
  }
}

class _DeviceList extends StatefulWidget { @override State<_DeviceList> createState() => _DeviceListState(); }
class _DeviceListState extends State<_DeviceList> {
  List<Map<String, dynamic>> _data = []; bool _l = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, name, device_type, serial_number, manufacturer, model, total_shots, max_shots, status FROM beauty.rex_001_beauty_devices ORDER BY name");
      if (mounted) setState(() { _data = r; _l = false; });
    } catch (_) { if (mounted) setState(() => _l = false); }
  }
  @override Widget build(BuildContext context) {
    if (_l) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Cihaz bulunamadı'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i];
      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.devices, color: Color(0xFFEC4899), size: 18)),
        title: Text(d['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${d['manufacturer'] ?? ''} ${d['model'] ?? ''} • SN: ${d['serial_number'] ?? ''}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: StatusBadge(label: d['status']?.toString() ?? 'active', color: d['status'] == 'active' ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
      ));
    });
  }
}

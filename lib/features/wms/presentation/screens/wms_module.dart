import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class WmsModule extends StatefulWidget {
  const WmsModule({super.key});

  @override
  State<WmsModule> createState() => _WmsModuleState();
}

class _WmsModuleState extends State<WmsModule> with SingleTickerProviderStateMixin {
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
        const BackofficeHeader(title: 'WMS — Depo Yönetimi', icon: Icons.warehouse_outlined,
          gradientStart: Color(0xFF0891B2), gradientEnd: Color(0xFF0E7490)),
        TabBar(controller: _tabController, labelColor: const Color(0xFF0891B2), unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0891B2), labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'DEPOLAR'), Tab(text: 'MAL KABUL'), Tab(text: 'SEVKİYAT'), Tab(text: 'TRANSFER'), Tab(text: 'SAYIM')]),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _WarehouseList(), _ReceivingSlips(), _DispatchSlips(), _TransferList(), _CountingList(),
        ])),
      ]),
    );
  }
}

class _WarehouseList extends StatefulWidget { @override State<_WarehouseList> createState() => _WarehouseListState(); }
class _WarehouseListState extends State<_WarehouseList> {
  List<Map<String, dynamic>> _data = []; bool _isLoading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, code, name, type, city, is_main, is_active FROM public.stores ORDER BY name");
      if (mounted) setState(() { _data = r; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }
  @override Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF0891B2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.warehouse, color: Color(0xFF0891B2), size: 18)),
        title: Text(d['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${d['code'] ?? ''} • ${d['city'] ?? ''}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: d['is_main'] == true ? const StatusBadge(label: 'Ana', color: Color(0xFF0891B2)) : null,
      ));
    });
  }
}

class _ReceivingSlips extends StatefulWidget { @override State<_ReceivingSlips> createState() => _ReceivingSlipsState(); }
class _ReceivingSlipsState extends State<_ReceivingSlips> {
  List<Map<String, dynamic>> _data = []; bool _isLoading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, slip_no, supplier_name, notes, status, created_at FROM wms.receiving_slips ORDER BY created_at DESC LIMIT 30");
      if (mounted) setState(() { _data = r; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }
  @override Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Mal kabul fişi bulunamadı'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.move_to_inbox, color: Color(0xFF10B981), size: 18)),
        title: Text(d['slip_no']?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        subtitle: Text(d['supplier_name']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: StatusBadge(label: d['status']?.toString() ?? 'pending', color: d['status'] == 'completed' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
      ));
    });
  }
}

class _DispatchSlips extends StatefulWidget { @override State<_DispatchSlips> createState() => _DispatchSlipsState(); }
class _DispatchSlipsState extends State<_DispatchSlips> {
  List<Map<String, dynamic>> _data = []; bool _isLoading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, slip_no, customer_name, priority, status, created_at FROM wms.dispatch_slips ORDER BY created_at DESC LIMIT 30");
      if (mounted) setState(() { _data = r; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }
  @override Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Sevkiyat fişi bulunamadı'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.outbox, color: Color(0xFFEF4444), size: 18)),
        title: Text(d['slip_no']?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        subtitle: Text(d['customer_name']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (d['priority'] == 'high') const StatusBadge(label: 'Acil', color: Color(0xFFEF4444)),
          const SizedBox(width: 6),
          StatusBadge(label: d['status']?.toString() ?? 'draft', color: d['status'] == 'completed' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
        ]),
      ));
    });
  }
}

class _TransferList extends StatefulWidget { @override State<_TransferList> createState() => _TransferListState(); }
class _TransferListState extends State<_TransferList> {
  List<Map<String, dynamic>> _data = []; bool _isLoading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, fiche_no, date, status FROM wms.transfers ORDER BY date DESC LIMIT 30");
      if (mounted) setState(() { _data = r; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }
  @override Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Transfer bulunamadı'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.swap_horiz, color: Color(0xFF3B82F6), size: 18)),
        title: Text(d['fiche_no']?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        subtitle: Text(d['date']?.toString() ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: StatusBadge(label: d['status']?.toString() ?? 'pending', color: d['status'] == 'completed' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
      ));
    });
  }
}

class _CountingList extends StatefulWidget { @override State<_CountingList> createState() => _CountingListState(); }
class _CountingListState extends State<_CountingList> {
  List<Map<String, dynamic>> _data = []; bool _isLoading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
      final r = await pg.query("SELECT id, fiche_no, date, status, count_type, description FROM wms.counting_slips ORDER BY date DESC LIMIT 30");
      if (mounted) setState(() { _data = r; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }
  @override Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Sayım fişi bulunamadı'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length, itemBuilder: (_, i) {
      final d = _data[i]; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.checklist, color: Color(0xFF059669), size: 18)),
        title: Text(d['fiche_no']?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        subtitle: Text('${d['count_type'] ?? 'full'} • ${d['description'] ?? ''}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: StatusBadge(label: d['status']?.toString() ?? 'draft', color: d['status'] == 'completed' ? const Color(0xFF10B981) : const Color(0xFF64748B)),
      ));
    });
  }
}

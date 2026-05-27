import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../widgets/backoffice_widgets.dart';

class FirmPeriodScreen extends StatefulWidget {
  const FirmPeriodScreen({super.key});

  @override
  State<FirmPeriodScreen> createState() => _FirmPeriodScreenState();
}

class _FirmPeriodScreenState extends State<FirmPeriodScreen> {
  Map<String, dynamic>? _firm;
  List<Map<String, dynamic>> _periods = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final firms = await pg.query("SELECT id, firm_nr, name, title, tax_nr, tax_office, city, country, email, phone, ana_para_birimi FROM public.firms WHERE is_active = true LIMIT 1");
      final periods = await pg.query("SELECT id, nr, beg_date, end_date, is_active FROM public.periods ORDER BY nr");
      if (mounted) setState(() {
        _firm = firms.isNotEmpty ? firms.first : null;
        _periods = periods;
        _isLoading = false;
      });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(title: 'Firma & Dönem', icon: Icons.business_center_outlined,
          gradientStart: const Color(0xFF1E40AF), gradientEnd: const Color(0xFF1E3A8A)),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFirmCard(),
                    const SizedBox(height: 20),
                    _buildPeriodsSection(),
                  ],
                )),
        ),
      ],
    );
  }

  Widget _buildFirmCard() {
    if (_firm == null) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Firma tanımı bulunamadı')));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFF1E40AF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.business, color: Color(0xFF1E40AF), size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_firm!['name']?.toString() ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('Firma No: ${_firm!['firm_nr']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ])),
                StatusBadge(label: 'Aktif', color: const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 16), const Divider(),
            const SizedBox(height: 12),
            _infoRow('Vergi No', _firm!['tax_nr']?.toString() ?? '-'),
            _infoRow('Şehir', _firm!['city']?.toString() ?? '-'),
            _infoRow('E-posta', _firm!['email']?.toString() ?? '-'),
            _infoRow('Telefon', _firm!['phone']?.toString() ?? '-'),
            _infoRow('Para Birimi', _firm!['ana_para_birimi']?.toString() ?? 'IQD'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPeriodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dönemler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ..._periods.map((p) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(radius: 16, backgroundColor: const Color(0xFF1E40AF).withValues(alpha: 0.1),
              child: Text('${p['nr']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)))),
            title: Text('Dönem ${p['nr']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${p['beg_date']} → ${p['end_date']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            trailing: StatusBadge(label: p['is_active'] == true ? 'Aktif' : 'Kapalı',
              color: p['is_active'] == true ? const Color(0xFF10B981) : const Color(0xFF64748B)),
          ),
        )),
      ],
    );
  }
}

class StockCountScreen extends StatefulWidget {
  const StockCountScreen({super.key});

  @override
  State<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends State<StockCountScreen> {
  List<Map<String, dynamic>> _slips = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, fiche_no, date, status, count_type, description FROM wms.counting_slips ORDER BY date DESC LIMIT 20",
      );
      if (mounted) setState(() { _slips = results; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(title: 'Stok Sayım', icon: Icons.checklist_outlined,
          gradientStart: const Color(0xFF059669), gradientEnd: const Color(0xFF047857), count: _slips.length,
          actions: [HeaderIconButton(icon: Icons.refresh, onTap: _load), const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Sayım', onTap: () {})]),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _slips.isEmpty ? const Center(child: Text('Sayım fişi bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: _slips.length,
                  itemBuilder: (context, i) {
                    final s = _slips[i];
                    final status = s['status']?.toString() ?? 'draft';
                    Color statusColor;
                    switch (status) {
                      case 'completed': statusColor = const Color(0xFF10B981); break;
                      case 'active': case 'counting': statusColor = const Color(0xFFF59E0B); break;
                      default: statusColor = const Color(0xFF64748B);
                    }
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_outlined, color: Color(0xFF059669), size: 20)),
                        title: Text(s['fiche_no']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                        subtitle: Text('${s['count_type'] ?? 'full'} • ${s['description'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        trailing: StatusBadge(label: status, color: statusColor),
                      ),
                    );
                  }),
        ),
      ],
    );
  }
}

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, table_name, record_id, action, firm_nr, created_at FROM public.audit_logs ORDER BY created_at DESC LIMIT 50",
      );
      if (mounted) setState(() { _logs = results; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(title: 'Denetim Logu', icon: Icons.history_outlined,
          gradientStart: const Color(0xFF64748B), gradientEnd: const Color(0xFF475569), count: _logs.length,
          actions: [HeaderIconButton(icon: Icons.refresh, onTap: _load)]),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty ? const Center(child: Text('Log kaydı bulunamadı'))
              : SingleChildScrollView(scrollDirection: Axis.horizontal, child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    dataRowMinHeight: 36, dataRowMaxHeight: 42, columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('TARİH')),
                      DataColumn(label: Text('TABLO')),
                      DataColumn(label: Text('İŞLEM')),
                      DataColumn(label: Text('FİRMA')),
                    ],
                    rows: _logs.map((l) {
                      final action = l['action']?.toString() ?? '';
                      Color actionColor;
                      switch (action) {
                        case 'INSERT': actionColor = const Color(0xFF10B981); break;
                        case 'UPDATE': actionColor = const Color(0xFF3B82F6); break;
                        case 'DELETE': actionColor = const Color(0xFFEF4444); break;
                        default: actionColor = const Color(0xFF64748B);
                      }
                      return DataRow(cells: [
                        DataCell(Text(_fmtDate(l['created_at']?.toString()), style: const TextStyle(fontSize: 10))),
                        DataCell(Text(l['table_name']?.toString() ?? '-', style: const TextStyle(fontSize: 10, fontFamily: 'monospace'))),
                        DataCell(StatusBadge(label: action, color: actionColor)),
                        DataCell(Text(l['firm_nr']?.toString() ?? '-', style: const TextStyle(fontSize: 10))),
                      ]);
                    }).toList(),
                  ),
                )),
        ),
      ],
    );
  }

  String _fmtDate(String? d) {
    if (d == null) return '-';
    try { final dt = DateTime.parse(d); return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'; }
    catch (_) { return d.length > 16 ? d.substring(0, 16) : d; }
  }
}

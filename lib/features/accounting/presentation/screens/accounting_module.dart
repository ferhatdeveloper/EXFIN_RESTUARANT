import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class AccountingModule extends StatefulWidget {
  const AccountingModule({super.key});

  @override
  State<AccountingModule> createState() => _AccountingModuleState();
}

class _AccountingModuleState extends State<AccountingModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        const BackofficeHeader(title: 'Muhasebe & Mali Tablolar', icon: Icons.account_balance_outlined,
          gradientStart: Color(0xFF1E40AF), gradientEnd: Color(0xFF1E3A8A)),
        TabBar(controller: _tabController, labelColor: const Color(0xFF1E40AF), unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF1E40AF), labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'HESAP PLANI'), Tab(text: 'YEVMİYE'), Tab(text: 'MİZAN'), Tab(text: 'MALİ TABLOLAR')]),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _ChartOfAccounts(), _JournalEntries(), _TrialBalance(), _FinancialStatements(),
        ])),
      ]),
    );
  }
}

class _ChartOfAccounts extends StatelessWidget {
  final List<Map<String, String>> _accounts = const [
    {'code': '100', 'name': 'KASA', 'type': 'Aktif'},
    {'code': '101', 'name': 'ALINAN ÇEKLER', 'type': 'Aktif'},
    {'code': '102', 'name': 'BANKALAR', 'type': 'Aktif'},
    {'code': '120', 'name': 'ALICILAR', 'type': 'Aktif'},
    {'code': '150', 'name': 'İLK MADDE VE MALZEME', 'type': 'Aktif'},
    {'code': '153', 'name': 'TİCARİ MALLAR', 'type': 'Aktif'},
    {'code': '255', 'name': 'DEMİRBAŞLAR', 'type': 'Aktif'},
    {'code': '300', 'name': 'BANKA KREDİLERİ', 'type': 'Pasif'},
    {'code': '320', 'name': 'SATICILAR', 'type': 'Pasif'},
    {'code': '360', 'name': 'ÖDENECEK VERGİ', 'type': 'Pasif'},
    {'code': '500', 'name': 'SERMAYE', 'type': 'Özkaynaklar'},
    {'code': '600', 'name': 'YURTİÇİ SATIŞLAR', 'type': 'Gelir'},
    {'code': '621', 'name': 'SATILAN MAL MALİYETİ', 'type': 'Gider'},
    {'code': '630', 'name': 'AR-GE GİDERLERİ', 'type': 'Gider'},
    {'code': '660', 'name': 'FİNANSMAN GİDERLERİ', 'type': 'Gider'},
    {'code': '770', 'name': 'GENEL YÖNETİM GİDERLERİ', 'type': 'Gider'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12), itemCount: _accounts.length,
      itemBuilder: (_, i) {
        final a = _accounts[i];
        Color typeColor;
        switch (a['type']) {
          case 'Aktif': typeColor = const Color(0xFF2563EB); break;
          case 'Pasif': typeColor = const Color(0xFFEF4444); break;
          case 'Gelir': typeColor = const Color(0xFF10B981); break;
          case 'Gider': typeColor = const Color(0xFFF59E0B); break;
          default: typeColor = const Color(0xFF64748B);
        }
        return Card(margin: const EdgeInsets.only(bottom: 4), child: ListTile(dense: true,
          leading: Container(width: 40, alignment: Alignment.center,
            child: Text(a['code']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: Color(0xFF1E40AF)))),
          title: Text(a['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          trailing: StatusBadge(label: a['type']!, color: typeColor),
        ));
      },
    );
  }
}

class _JournalEntries extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = [
      {'no': 'YEV-001', 'date': '24.05.2026', 'desc': 'Günlük satış tahsilatı', 'debit': '8.580', 'credit': '8.580'},
      {'no': 'YEV-002', 'date': '24.05.2026', 'desc': 'Satılan mal maliyeti', 'debit': '4.200', 'credit': '4.200'},
      {'no': 'YEV-003', 'date': '24.05.2026', 'desc': 'Kira gideri', 'debit': '5.000', 'credit': '5.000'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        columns: const [
          DataColumn(label: Text('FİŞ NO')), DataColumn(label: Text('TARİH')),
          DataColumn(label: Text('AÇIKLAMA')), DataColumn(label: Text('BORÇ'), numeric: true),
          DataColumn(label: Text('ALACAK'), numeric: true),
        ],
        rows: entries.map((e) => DataRow(cells: [
          DataCell(Text(e['no']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF1E40AF)))),
          DataCell(Text(e['date']!, style: const TextStyle(fontSize: 11))),
          DataCell(Text(e['desc']!, style: const TextStyle(fontSize: 11))),
          DataCell(Text(e['debit']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)))),
          DataCell(Text(e['credit']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)))),
        ])).toList(),
      )),
    );
  }
}

class _TrialBalance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      {'code': '100', 'name': 'KASA', 'debit': '617.300', 'credit': '16.300', 'dBalance': '601.000', 'cBalance': ''},
      {'code': '102', 'name': 'BANKALAR', 'debit': '0', 'credit': '0', 'dBalance': '0', 'cBalance': ''},
      {'code': '120', 'name': 'ALICILAR', 'debit': '159.600', 'credit': '0', 'dBalance': '159.600', 'cBalance': ''},
      {'code': '153', 'name': 'TİCARİ MALLAR', 'debit': '157.200', 'credit': '0', 'dBalance': '157.200', 'cBalance': ''},
      {'code': '320', 'name': 'SATICILAR', 'debit': '0', 'credit': '157.200', 'dBalance': '', 'cBalance': '157.200'},
      {'code': '600', 'name': 'YURTİÇİ SATIŞLAR', 'debit': '0', 'credit': '601.000', 'dBalance': '', 'cBalance': '601.000'},
      {'code': '621', 'name': 'SMM', 'debit': '0', 'credit': '0', 'dBalance': '0', 'cBalance': ''},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
        headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
        dataRowMinHeight: 34, dataRowMaxHeight: 40, columnSpacing: 14,
        columns: const [
          DataColumn(label: Text('KOD')), DataColumn(label: Text('HESAP ADI')),
          DataColumn(label: Text('BORÇ TOP.'), numeric: true), DataColumn(label: Text('ALACAK TOP.'), numeric: true),
          DataColumn(label: Text('BORÇ BAK.'), numeric: true), DataColumn(label: Text('ALACAK BAK.'), numeric: true),
        ],
        rows: rows.map((r) => DataRow(cells: [
          DataCell(Text(r['code']!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w700))),
          DataCell(Text(r['name']!, style: const TextStyle(fontSize: 10))),
          DataCell(Text(r['debit']!, style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444)))),
          DataCell(Text(r['credit']!, style: const TextStyle(fontSize: 10, color: Color(0xFF10B981)))),
          DataCell(Text(r['dBalance']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          DataCell(Text(r['cBalance']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
        ])).toList(),
      )),
    );
  }
}

class _FinancialStatements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('BİLANÇO (Özet)'),
        _balanceRow('AKTİF', '', bold: true, isHeader: true),
        _balanceRow('  Dönen Varlıklar', '917.800'),
        _balanceRow('    Kasa', '601.000'),
        _balanceRow('    Alıcılar', '159.600'),
        _balanceRow('    Stoklar', '157.200'),
        _balanceRow('  Duran Varlıklar', '0'),
        const Divider(),
        _balanceRow('PASİF', '', bold: true, isHeader: true),
        _balanceRow('  Kısa Vadeli Borçlar', '157.200'),
        _balanceRow('    Satıcılar', '157.200'),
        _balanceRow('  Özkaynaklar', '760.600'),
        _balanceRow('    Sermaye', '100.000'),
        _balanceRow('    Dönem Kârı', '660.600'),
        const Divider(height: 30),
        _sectionTitle('GELİR TABLOSU'),
        _balanceRow('Brüt Satışlar', '601.000'),
        _balanceRow('Satışların Maliyeti (-)', '-0'),
        _balanceRow('BRÜT KÂR', '601.000', bold: true),
        _balanceRow('Faaliyet Giderleri (-)', '-5.000'),
        _balanceRow('FAALİYET KÂRI', '596.000', bold: true),
        _balanceRow('Finansman Giderleri (-)', '0'),
        _balanceRow('DÖNEM NET KÂRI', '596.000', bold: true),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 6),
    child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
  );

  Widget _balanceRow(String label, String value, {bool bold = false, bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: bold || isHeader ? FontWeight.w700 : FontWeight.w400,
          color: isHeader ? const Color(0xFF1E40AF) : const Color(0xFF374151))),
        if (value.isNotEmpty) Text('$value IQD', style: TextStyle(fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: bold ? const Color(0xFF1E40AF) : const Color(0xFF374151))),
      ]),
    );
  }
}

// Dosya Adı: past_orders_screen.dart
// Açıklama: Geçmiş adisyonları tam sayfa ve filtreli tablo ile gösteren ekran
// Oluşturulma Tarihi: 2024-06-08
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-06-08

import 'package:flutter/material.dart';
import '../../../../shared/widgets/corporate_pluto_grid_widget.dart'
    as pluto_widget;
import 'package:pluto_grid/pluto_grid.dart';

class PastOrdersScreen extends StatefulWidget {
  const PastOrdersScreen({Key? key}) : super(key: key);

  @override
  State<PastOrdersScreen> createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';

  // PlutoGrid için
  final List<Map<String, dynamic>> orders = [
    {
      'id': 752,
      'musteri': 'Peşin Satış',
      'masa': 'Salon-1',
      'acilis': '16/06/2025',
      'kapanis': '16/06/2025',
      'personel': 'YÖNETİCİ',
      'kurye': '',
      'kisi': 1,
      'tutar': 45,
    },
    {
      'id': 758,
      'musteri': 'Peşin Satış',
      'masa': 'Salon-1',
      'acilis': '18/06/2025',
      'kapanis': '18/06/2025',
      'personel': 'YÖNETİCİ',
      'kurye': '',
      'kisi': 4,
      'tutar': 136,
    },
    {
      'id': 759,
      'musteri': 'Peşin Satış',
      'masa': 'S-1',
      'acilis': '18/06/2025',
      'kapanis': '18/06/2025',
      'personel': 'YÖNETİCİ',
      'kurye': '',
      'kisi': 1,
      'tutar': 136,
    },
    {
      'id': 773,
      'musteri': 'Peşin Satış',
      'masa': 'Salon-1',
      'acilis': '27/06/2025',
      'kapanis': '08/07/2025',
      'personel': 'Gastrospos Yönetici',
      'kurye': '',
      'kisi': 1,
      'tutar': 591,
    },
    {
      'id': 779,
      'musteri': 'Peşin Satış',
      'masa': 'A-7',
      'acilis': '03/07/2025',
      'kapanis': '08/07/2025',
      'personel': 'YÖNETİCİ',
      'kurye': '',
      'kisi': 3,
      'tutar': 187,
    },
    {
      'id': 781,
      'musteri': 'Peşin Satış',
      'masa': 'S-4',
      'acilis': '04/07/2025',
      'kapanis': '04/07/2025',
      'personel': 'YÖNETİCİ',
      'kurye': '',
      'kisi': 3,
      'tutar': 40,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = orders.where((order) {
      final matchesSearch = searchQuery.isEmpty ||
          order['id'].toString().contains(searchQuery) ||
          order['musteri']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          order['masa']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      final acilisDate = DateTime.parse(_toIso(order['acilis']));
      final kapanisDate = DateTime.parse(_toIso(order['kapanis']));
      final matchesStart = startDate == null ||
          acilisDate.isAfter(startDate!.subtract(const Duration(days: 1)));
      final matchesEnd = endDate == null ||
          kapanisDate.isBefore(endDate!.add(const Duration(days: 1)));
      return matchesSearch && matchesStart && matchesEnd;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Geçmiş Adisyonlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filtre',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        ListTile(
                          leading:
                              const Icon(Icons.date_range, color: Colors.blue),
                          title: const Text('Başlangıç Tarihi'),
                          trailing: Text(startDate != null
                              ? _formatDate(startDate!)
                              : '-'),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null)
                              setState(() => startDate = picked);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.event, color: Colors.red),
                          title: const Text('Bitiş Tarihi'),
                          trailing: Text(
                              endDate != null ? _formatDate(endDate!) : '-'),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null)
                              setState(() => endDate = picked);
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Filtreyi Uygula'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Aranacak kelime giriniz',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: pluto_widget.CorporatePlutoGridWidget(
                columns: [
                  PlutoColumn(
                    title: '#',
                    field: 'id',
                    type: PlutoColumnType.number(),
                  ),
                  PlutoColumn(
                    title: 'Müşteri',
                    field: 'musteri',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Masa Adı',
                    field: 'masa',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Açılış Saati',
                    field: 'acilis',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Kapanış Saati',
                    field: 'kapanis',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Oluşturan Personel',
                    field: 'personel',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Üstlenen Kurye',
                    field: 'kurye',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Kişi Sayısı',
                    field: 'kisi',
                    type: PlutoColumnType.number(),
                  ),
                  PlutoColumn(
                    title: 'Ödenen Tutar',
                    field: 'tutar',
                    type: PlutoColumnType.number(),
                  ),
                ],
                rows: _buildPastOrdersPlutoRows(filteredOrders),
                title: 'Geçmiş Adisyonlar',
                enableGrouping: true,
                enableExport: true,
                enableFilter: true,
                enableCopy: true,
                enableSelectAll: true,
                enableEditing: true,
                enableRowActions: true,
                enableFrozenColumns: true,
                enableRowColoring: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Toplam Kayıt : ${filteredOrders.length}'),
            ),
          ),
        ],
      ),
    );
  }

  List<PlutoRow> _buildPastOrdersPlutoRows(
      List<Map<String, dynamic>> filteredOrders) {
    return filteredOrders
        .map((order) => PlutoRow(cells: {
              'id': PlutoCell(value: order['id']),
              'musteri': PlutoCell(value: order['musteri']),
              'masa': PlutoCell(value: order['masa']),
              'acilis': PlutoCell(value: order['acilis']),
              'kapanis': PlutoCell(value: order['kapanis']),
              'personel': PlutoCell(value: order['personel']),
              'kurye': PlutoCell(value: order['kurye']),
              'kisi': PlutoCell(value: order['kisi']),
              'tutar': PlutoCell(value: order['tutar']),
            }))
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _toIso(String date) {
    final parts = date.split('/');
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }
}

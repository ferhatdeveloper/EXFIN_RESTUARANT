import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/orders/presentation/screens/order_screen.dart';
import '../../../../shared/widgets/corporate_pluto_grid_widget.dart'
    as pluto_widget;
import 'package:pluto_grid/pluto_grid.dart';
import '../../../reports/model/report_data_model.dart';
import '../../viewmodel/tables_viewmodel.dart';
// import '../../../../shared/providers/app_providers.dart'; // Çakışma nedeniyle kaldırıldı

List<ReportDataModel> getPastOrdersDialogReportData() {
  final List<Map<String, dynamic>> _data = [
    {'adisyon': '1001', 'saat': '12:30', 'tutar': '350'},
    {'adisyon': '1002', 'saat': '13:15', 'tutar': '420'},
    {'adisyon': '1003', 'saat': '14:05', 'tutar': '180'},
  ];
  return _data.map((order) {
    return ReportDataModel(
      id: order['adisyon'].toString(),
      title: order['adisyon'].toString(),
      value1: 0,
      value2: (order['tutar'] is int)
          ? (order['tutar'] as int).toDouble()
          : double.tryParse(order['tutar'].toString()) ?? 0,
      value3: 0,
      date: DateTime.now(),
    );
  }).toList();
}

class TableModel {
  final int number;
  final String salon;
  final String status; // "empty", "occupied", "reserved", "alert"
  TableModel({required this.number, required this.salon, required this.status});
}

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen>
    with TickerProviderStateMixin {
  int selectedRegionIndex = 0;
  String selectedStatus = 'all';
  bool isMobile = false;
  Map<int, AnimationController> _pulseControllers = {};
  Map<int, Animation<double>> _pulseAnimations = {};

  final List<String> durumlar = [
    "all",
    "Available",
    "occupied",
    "reserved",
    "alert"
  ];

  @override
  void initState() {
    super.initState();
    // TablesViewModel'i ConsumerStatefulWidget ile kullan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tablesViewModel = ref.read(tablesProvider.notifier);
      tablesViewModel.loadTables();
      tablesViewModel.loadRegions();
      tablesViewModel.initializeSignalR();

      // Masa durumu değiştiğinde pulse animasyonunu tetikle (şimdilik boş)
      // tablesViewModel.onTableStatusChanged = (tableId, status) {
      //   _triggerPulseAnimation(tableId);
      // };
    });

    // Animasyon controller'larını başlat
    _initializePulseAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isMobile = MediaQuery.of(context).size.width < 600;
  }

  void _initializePulseAnimations() {
    // Mevcut masalar için animasyon controller'ları oluştur
    final tablesViewModel = ref.read(tablesProvider.notifier);
    for (var table in tablesViewModel.tables) {
      final tableId = _getTableId(table);
      if (!_pulseControllers.containsKey(tableId)) {
        _pulseControllers[tableId] = AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        );
        _pulseAnimations[tableId] = Tween<double>(
          begin: 1.0,
          end: 1.1,
        ).animate(CurvedAnimation(
          parent: _pulseControllers[tableId]!,
          curve: Curves.easeInOut,
        ));
      }
    }
  }

  int _getTableId(dynamic table) {
    // tableId'yi güvenli şekilde int'e çevir
    if (table['id'] is int) {
      return table['id'] as int;
    } else if (table['id'] is String) {
      return int.tryParse(table['id'] as String) ?? 0;
    } else if (table['number'] is int) {
      return table['number'] as int;
    } else if (table['number'] is String) {
      return int.tryParse(table['number'] as String) ?? 0;
    } else {
      return 0;
    }
  }

  void _triggerPulseAnimation(int tableId) {
    if (_pulseControllers.containsKey(tableId)) {
      _pulseControllers[tableId]!.reset();
      _pulseControllers[tableId]!.repeat();

      // 2 saniye sonra animasyonu durdur
      Future.delayed(const Duration(seconds: 2), () {
        if (_pulseControllers.containsKey(tableId)) {
          _pulseControllers[tableId]!.stop();
        }
      });
    }
  }

  List<dynamic> get filteredTables {
    final tablesViewModel = ref.read(tablesProvider.notifier);
    List<dynamic> tables = tablesViewModel.tables;
    List<dynamic> filtered = tables;

    // Bölge filtresi - "Tümü" seçiliyse filtreleme yapma
    if (selectedRegionIndex > 0 && tablesViewModel.regions.isNotEmpty) {
      final selectedRegion =
          tablesViewModel.regions[selectedRegionIndex - 1]['name'];
      debugPrint(
          '🔍 Seçili bölge: $selectedRegion (index: $selectedRegionIndex)');
      debugPrint('📊 Toplam masa sayısı: ${tables.length}');

      filtered = filtered.where((t) {
        final location = (t['location'] ?? '').toString();
        final matches =
            location.toUpperCase().contains(selectedRegion.toUpperCase());
        debugPrint(
            '📍 Masa ${t['name']}: $location - $selectedRegion = $matches');
        return matches;
      }).toList();

      debugPrint('✅ Filtrelenmiş masa sayısı: ${filtered.length}');
    } else {
      debugPrint(
          '🔍 Tümü seçili (selectedRegionIndex: $selectedRegionIndex) - Filtreleme yapılmıyor');
    }

    // Durum filtresi
    if (selectedStatus != 'all') {
      filtered = filtered.where((t) => t['status'] == selectedStatus).toList();
    }

    return filtered;
  }

  void _showStatusFilterModal() async {
    String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) {
        return PopScope(
          canPop: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('Duruma Göre Filtrele',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ...durumlar.map((d) => ListTile(
                    leading: Icon(_getStatusIcon(d)),
                    title: Text(_getStatusLabel(d)),
                    selected: selectedStatus == d,
                    onTap: () => Navigator.pop(context, d),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedStatus = result;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Available':
        return 'Müsait';
      case 'occupied':
        return 'Dolu';
      case 'reserved':
        return 'Rezerve';
      case 'alert':
        return 'Uyarı';
      default:
        return 'Tümü';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      case 'alert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Available':
        return Icons.event_seat;
      case 'occupied':
        return Icons.people;
      case 'reserved':
        return Icons.schedule;
      case 'alert':
        return Icons.cleaning_services;
      default:
        return Icons.all_inclusive;
    }
  }

  // Bölge ikonunu al
  IconData _getRegionIcon(String regionName) {
    switch (regionName.toLowerCase()) {
      case 'bahçe':
        return Icons.park;
      case 'iç mekan':
        return Icons.restaurant;
      case 'teras':
        return Icons.deck;
      case 'bar':
        return Icons.local_bar;
      case 'özel bölüm':
        return Icons.star;
      case 'salon 1':
        return Icons.meeting_room;
      case 'salon 2':
        return Icons.meeting_room;
      case 'teras kat':
        return Icons.deck;
      default:
        return Icons.location_on;
    }
  }

  void _showRegionFilterModal() async {
    final tablesViewModel = ref.read(tablesProvider.notifier);
    String? result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bölge Seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // "Tümü" seçeneği
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Tümü'),
              selected: selectedRegionIndex == 0,
              onTap: () => Navigator.pop(context, 'all'),
            ),
            // Bölge seçenekleri
            ...tablesViewModel.regions.map((region) => ListTile(
                  leading: Icon(_getRegionIcon(region['name'] ?? '')),
                  title: Text(region['name'] ?? 'Bilinmeyen Bölge'),
                  selected: selectedRegionIndex ==
                      tablesViewModel.regions.indexOf(region) + 1,
                  onTap: () => Navigator.pop(context, region['name']),
                )),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result == 'all') {
          selectedRegionIndex = 0;
        } else {
          final index = ref
              .read(tablesProvider.notifier)
              .regions
              .indexWhere((r) => r['name'] == result);
          selectedRegionIndex = index + 1;
        }
      });
    }
  }

  Widget _buildMobileInfoCards() {
    final tablesViewModel = ref.read(tablesProvider.notifier);
    // Durumlara göre sayıları hesapla
    final stats = {
      'Müsait': tablesViewModel.tables
          .where((t) => t['status'] == 'Available')
          .length,
      'Dolu':
          tablesViewModel.tables.where((t) => t['status'] == 'occupied').length,
      'Rezerve':
          tablesViewModel.tables.where((t) => t['status'] == 'reserved').length,
      'Uyarı':
          tablesViewModel.tables.where((t) => t['status'] == 'alert').length,
    };
    final colors = {
      'Müsait': Colors.green,
      'Dolu': Colors.red,
      'Rezerve': Colors.orange,
      'Uyarı': Colors.purple,
    };
    final icons = {
      'Müsait': Icons.event_seat,
      'Dolu': Icons.people,
      'Rezerve': Icons.schedule,
      'Uyarı': Icons.cleaning_services,
    };

    // Seçili bölge bilgisi
    String selectedRegionName = 'Tüm Bölgeler';
    if (selectedRegionIndex > 0 &&
        ref.read(tablesProvider.notifier).regions.isNotEmpty) {
      if (selectedRegionIndex <=
          ref.read(tablesProvider.notifier).regions.length) {
        selectedRegionName = ref
                .read(tablesProvider.notifier)
                .regions[selectedRegionIndex - 1]['name'] ??
            'Bilinmeyen Bölge';
      }
    }

    return Column(
      children: [
        // Bölge bilgisi
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                selectedRegionName,
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Durum istatistikleri
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: stats.entries.map((entry) {
              return Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: colors[entry.key]!.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colors[entry.key]!.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[entry.key],
                          color: colors[entry.key], size: 20),
                      const SizedBox(height: 2),
                      Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color: colors[entry.key],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: colors[entry.key]!.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<PlutoRow> _buildPastOrdersPlutoRows() {
    final data = getPastOrdersDialogReportData();
    return data
        .map((row) => PlutoRow(cells: {
              'adisyon': PlutoCell(value: row.title),
              'saat': PlutoCell(value: '12:30'), // Örnek saat
              'tutar': PlutoCell(value: row.value2),
            }))
        .toList();
  }

  void _showPastOrdersDialog() {
    // Mouse event'lerini engellemek için barrierDismissible false yapıyoruz
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: true,
          child: AlertDialog(
            title: const Text('Geçmiş Adisyonlar'),
            content: SizedBox(
              width: 600,
              height: 400,
              child: pluto_widget.CorporatePlutoGridWidget(
                columns: [
                  PlutoColumn(
                    title: 'Adisyon No',
                    field: 'adisyon',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Saat',
                    field: 'saat',
                    type: PlutoColumnType.text(),
                  ),
                  PlutoColumn(
                    title: 'Tutar',
                    field: 'tutar',
                    type: PlutoColumnType.number(),
                  ),
                ],
                rows: _buildPastOrdersPlutoRows(),
                title: 'Geçmiş Adisyonlar',
                enableGrouping: true,
                enableExport: true,
                enableFilter: true,
                enableCopy: true,
                enableSelectAll: true,
                hideScrollBar: true,
                enableEditing: true,
                enableRowActions: true,
                enableFrozenColumns: true,
                enableRowColoring: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionSelector(TablesViewModel tablesViewModel) {
    return Container(
      width: double.infinity,
      height: 60,
      color: Colors.red[600],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "Tümü" seçeneği
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedRegionIndex = 0;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedRegionIndex == 0
                          ? Colors.yellow
                          : Colors.transparent,
                      width: 4,
                    ),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.all_inclusive,
                        size: 20,
                        color: selectedRegionIndex == 0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tümü',
                        style: TextStyle(
                          color: selectedRegionIndex == 0
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                          fontWeight: selectedRegionIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bölge seçenekleri
            for (int i = 0; i < tablesViewModel.regions.length; i++)
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRegionIndex = i + 1;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedRegionIndex == i + 1
                            ? Colors.yellow
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRegionIcon(
                              tablesViewModel.regions[i]['name'] ?? ''),
                          size: 20,
                          color: selectedRegionIndex == i + 1
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tablesViewModel.regions[i]['name'] ??
                              'Bilinmeyen Bölge',
                          style: TextStyle(
                            color: selectedRegionIndex == i + 1
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.8),
                            fontWeight: selectedRegionIndex == i + 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(dynamic table, TablesViewModel tablesViewModel) {
    final status = table['status'] ?? 'Available';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);
    final tableName = table['name'] ?? 'Masa ${table['id']}';
    final capacity = table['capacity'] ?? 4;
    final location = table['location'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleTableTap(table),
          onLongPress: () => _showTableActionModal(table),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  tableName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$capacity Kişilik',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTableActionModal(dynamic table) {
    int kisiSayisi = 1;
    TextEditingController kisiController = TextEditingController();
    TextEditingController musteriController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: true,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.all(16),
                content: SizedBox(
                  width: 350,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Masa bilgisi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(table['status'] ?? 'Available'),
                            size: 32,
                            color:
                                _getStatusColor(table['status'] ?? 'Available'),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            table['name'] ?? 'Masa ${table['id']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Kişi sayısı seçici
                      Row(
                        children: [
                          const Text('Kişi Sayısı: '),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove,
                                        color: Colors.red),
                                    onPressed: () {
                                      if (kisiSayisi > 1) {
                                        setState(() {
                                          kisiSayisi--;
                                          kisiController.text =
                                              kisiSayisi.toString();
                                        });
                                      }
                                    },
                                  ),
                                  Text(
                                    kisiSayisi.toString(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add,
                                        color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        kisiSayisi++;
                                        kisiController.text =
                                            kisiSayisi.toString();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Müşteri adı
                      TextField(
                        controller: musteriController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person, color: Colors.grey),
                          labelText: 'Müşteri Adı (Opsiyonel)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Telefon
                      TextField(
                        controller: kisiController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone, color: Colors.grey),
                          labelText: 'Telefon (Opsiyonel)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Butonlar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Rezerve Et butonu
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _reserveTable(
                                  table, kisiSayisi, musteriController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.access_time),
                            label: const Text('Rezerve Et'),
                          ),

                          // Doldur butonu
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _fillTable(
                                  table, kisiSayisi, musteriController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.people),
                            label: const Text('Doldur'),
                          ),

                          // Sipariş Al butonu
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _takeOrder(
                                  table, kisiSayisi, musteriController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.restaurant),
                            label: const Text('Sipariş Al'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleTableTap(dynamic table) {
    // Kısa tıklama - direkt sipariş ekranına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(tableNumber: table['id']),
      ),
    );
  }

  void _showPersonCountSelector(
      BuildContext context, Function(int) onCountSelected) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kişi Sayısı Seçin'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 20, // 1-20 arası
              itemBuilder: (context, index) {
                final count = index + 1;
                return InkWell(
                  onTap: () {
                    onCountSelected(count);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _reserveTable(dynamic table, int kisiSayisi, String musteriAdi) {
    // Masayı rezerve et
    final tablesViewModel = ref.read(tablesProvider.notifier);
    tablesViewModel.updateTableStatus(table['id'], 'reserved');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${table['name']} rezerve edildi')),
    );
  }

  void _fillTable(dynamic table, int kisiSayisi, String musteriAdi) {
    // Masayı doldur
    final tablesViewModel = ref.read(tablesProvider.notifier);
    tablesViewModel.updateTableStatus(table['id'], 'occupied');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${table['name']} dolduruldu')),
    );
  }

  void _takeOrder(dynamic table, int kisiSayisi, String musteriAdi) {
    // Masayı doldur ve sipariş ekranına git
    final tablesViewModel = ref.read(tablesProvider.notifier);
    tablesViewModel.updateTableStatus(table['id'], 'occupied');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(tableNumber: table['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesViewModel = ref.watch(tablesProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;
    final isDesktop = width >= 1100;

    int crossAxisCount = isMobile
        ? 2
        : isTablet
            ? 3
            : isDesktop
                ? 6
                : 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Masalar',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppConstants.exfinRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Durum Filtresi',
            onPressed: _showStatusFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: 'Bölge Filtresi',
            onPressed: _showRegionFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () {
              tablesViewModel.loadTables();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // İstatistik kartları
            if (!isMobile) _buildMobileInfoCards(),
            // Bölge seçimi
            _buildRegionSelector(tablesViewModel),
            // Masalar grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: tablesViewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tablesViewModel.tables.isEmpty
                        ? const Center(
                            child: Text('Masa bulunamadı',
                                style: TextStyle(fontSize: 18)))
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isMobile ? 1.1 : 1.2,
                            ),
                            itemCount: tablesViewModel.tables.length,
                            itemBuilder: (context, index) {
                              final table = tablesViewModel.tables[index];
                              return _buildTableCard(table, tablesViewModel);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Animasyon controller'larını temizle
    final tablesViewModel = ref.read(tablesProvider.notifier);
    for (var controller in _pulseControllers.values) {
      controller.dispose();
    }
    _pulseControllers.clear();
    _pulseAnimations.clear();
    super.dispose();
  }
}

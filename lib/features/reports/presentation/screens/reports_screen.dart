// Dosya Adı: reports_screen.dart
// Açıklama: Raporlar ve analiz ekranı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../../../shared/widgets/corporate_pluto_grid_widget.dart'
    as pluto_widget;

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String selectedReport = 'Günlük Satış Raporu';
  String selectedDateRange = 'Bugün';
  String selectedCategory = 'Tümü';
  String selectedStaff = 'Tümü';
  String selectedTable = 'Tümü';
  String selectedProduct = 'Tümü';
  String selectedPaymentType = 'Tümü';
  String selectedChartType = 'Bar'; // Bar, Line, Pie, Area, Scatter, Radar

  final List<String> reportTypes = [
    'Günlük Satış Raporu',
    'Saatlik Analiz',
    'Ürün Bazlı Rapor',
    'Kategori Bazlı Rapor',
    'Personel Performans',
    'Masa Bazlı Rapor',
    'Ödeme Tipi Analizi',
    'Stok Durumu',
    'Kampanya Analizi',
    'Kar/Zarar Analizi',
    'Rezervasyon Raporu',
    'Mutfak Çıkış Raporu',
    'Sipariş Hızı Analizi',
    'Fatura/Fiş Raporu',
    'Müşteri Analizi',
    'Z Raporu',
    'X Raporu',
    'Günlük Kasa Raporu',
    'Haftalık Özet',
    'Aylık Özet',
    'Yıllık Özet',
    'Vergi Raporu',
    'İndirim Raporu',
    'İade Raporu',
    'Sipariş Detay Raporu',
  ];

  final List<String> dateRanges = [
    'Bugün',
    'Dün',
    'Bu Hafta',
    'Geçen Hafta',
    'Bu Ay',
    'Geçen Ay',
    'Bu Yıl',
    'Geçen Yıl',
    'Özel Tarih',
  ];

  final List<String> categories = [
    'Tümü',
    'Ana Yemek',
    'Çorba',
    'Salata',
    'Tatlı',
    'İçecek',
    'Kahvaltı',
    'Fast Food',
  ];

  final List<String> staffMembers = [
    'Tümü',
    'Ahmet Yılmaz',
    'Fatma Demir',
    'Mehmet Kaya',
    'Ayşe Özkan',
  ];

  final List<String> tables = [
    'Tümü',
    'Masa 1',
    'Masa 2',
    'Masa 3',
    'Masa 4',
    'Masa 5',
    'Self Servis',
  ];

  final List<String> products = [
    'Tümü',
    'Döner',
    'Pizza',
    'Hamburger',
    'Çorba',
    'Salata',
    'Tiramisu',
    'Kola',
  ];

  final List<String> paymentTypes = [
    'Tümü',
    'Nakit',
    'Kredi Kartı',
    'QR Kod',
    'Bölüşümlü',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;

    return Scaffold(
      backgroundColor: AppConstants.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConstants.exfinDarkBlue,
        foregroundColor: Colors.white,
        title: const Text('Raporlar & Analiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportReport(),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReport(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showReportSettings(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sol menü - Rapor türleri
          if (!isMobile)
            Container(
              width: isTablet ? 200 : 250,
              color: Colors.white,
              child: Column(
                children: [
                  // Başlık
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.exfinDarkBlue,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'Rapor Türleri',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Rapor listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: reportTypes.length,
                      itemBuilder: (context, index) {
                        final report = reportTypes[index];
                        final isSelected = selectedReport == report;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor:
                              AppConstants.exfinDarkBlue.withValues(alpha: 0.1),
                          leading: Icon(
                            _getReportIcon(report),
                            color: isSelected
                                ? AppConstants.exfinDarkBlue
                                : Colors.grey[600],
                            size: 20,
                          ),
                          title: Text(
                            report,
                            style: TextStyle(
                              color: isSelected
                                  ? AppConstants.exfinDarkBlue
                                  : AppConstants.textColorPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          onTap: () => setState(() => selectedReport = report),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          // Ana içerik alanı
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Filtreler
                  _buildFilters(),
                  // Rapor içeriği
                  _buildReportContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtreler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColorPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFilterDropdown(
                'Tarih Aralığı',
                selectedDateRange,
                dateRanges,
                (value) => setState(() => selectedDateRange = value!),
              ),
              _buildFilterDropdown(
                'Kategori',
                selectedCategory,
                categories,
                (value) => setState(() => selectedCategory = value!),
              ),
              _buildFilterDropdown(
                'Personel',
                selectedStaff,
                staffMembers,
                (value) => setState(() => selectedStaff = value!),
              ),
              _buildFilterDropdown(
                'Masa',
                selectedTable,
                tables,
                (value) => setState(() => selectedTable = value!),
              ),
              _buildFilterDropdown(
                'Ürün',
                selectedProduct,
                products,
                (value) => setState(() => selectedProduct = value!),
              ),
              _buildFilterDropdown(
                'Ödeme Tipi',
                selectedPaymentType,
                paymentTypes,
                (value) => setState(() => selectedPaymentType = value!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 90, maxWidth: 180),
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppConstants.textColorSecondary,
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonFormField<String>(
            value: value,
            isDense: true,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppConstants.exfinDarkBlue),
              ),
            ),
            items: options
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(option,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rapor başlığı
          Row(
            children: [
              Icon(_getReportIcon(selectedReport),
                  color: AppConstants.exfinDarkBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                selectedReport,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColorPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Son güncelleme: ${DateTime.now().toString().substring(0, 19)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textColorSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grafik alanı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildChartTypeButtons(),
                const SizedBox(height: 18),
                _buildChart(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Tablo alanı
          Builder(
            builder: (context) {
              final rowHeight = PlutoGridSettings.rowHeight;
              final headerHeight = 45.0;
              final totalHeight =
                  headerHeight + (_buildPlutoRows().length * rowHeight);
              return Container(
                width: double.infinity,
                height: totalHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: pluto_widget.CorporatePlutoGridWidget(
                  columns: _buildPlutoColumns(),
                  rows: _buildPlutoRows(),
                  title: 'Raporlar',
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeButtons() {
    final chartTypes = ['Bar', 'Line', 'Pie', 'Area'];
    return Row(
      children: chartTypes
          .map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type),
                  selected: selectedChartType == type,
                  onSelected: (selected) {
                    setState(() {
                      selectedChartType = type;
                    });
                  },
                  selectedColor:
                      AppConstants.exfinDarkBlue.withValues(alpha: 0.2),
                  checkmarkColor: AppConstants.exfinDarkBlue,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildChart() {
    switch (selectedChartType) {
      case 'Bar':
        return _buildBarChart();
      case 'Line':
        return _buildLineChart();
      case 'Pie':
        return _buildPieChart();
      case 'Area':
        return _buildAreaChart();
      default:
        return _buildLineChart();
    }
  }

  Widget _buildBarChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(10, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (index + 1) * 8.0,
                  color: AppConstants.exfinDarkBlue,
                  width: 20,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(24, (index) {
                return FlSpot(index.toDouble(), (index + 1) * 10.0);
              }),
              isCurved: true,
              color: AppConstants.exfinDarkBlue,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 40,
              title: 'Ana Yemek\n40%',
              color: AppConstants.exfinDarkBlue,
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            PieChartSectionData(
              value: 25,
              title: 'İçecek\n25%',
              color: AppConstants.exfinBlue,
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            PieChartSectionData(
              value: 20,
              title: 'Tatlı\n20%',
              color: AppConstants.exfinGreen,
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            PieChartSectionData(
              value: 15,
              title: 'Diğer\n15%',
              color: AppConstants.exfinOrange,
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildAreaChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(24, (index) {
                return FlSpot(index.toDouble(), (index + 1) * 8.0);
              }),
              isCurved: true,
              color: AppConstants.exfinDarkBlue,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppConstants.exfinDarkBlue.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PlutoGrid için tablo kolonları
  List<PlutoColumn> _buildPlutoColumns() {
    switch (selectedReport) {
      case 'Günlük Satış Raporu':
        return [
          PlutoColumn(
              title: 'Saat', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Satış',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Sipariş',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Saatlik Analiz':
        return [
          PlutoColumn(
              title: 'Saat', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Gelir', field: 'value2', type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Yoğunluk', field: 'value3', type: PlutoColumnType.text()),
        ];
      case 'Ürün Bazlı Rapor':
        return [
          PlutoColumn(
              title: 'Ürün', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Satış Adedi',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Gelir',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Fiyat',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Kategori Bazlı Rapor':
        return [
          PlutoColumn(
              title: 'Kategori', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Ürün Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Satış',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Fiyat',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Personel Performans':
        return [
          PlutoColumn(
              title: 'Personel', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Satış',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Performans',
              field: 'value3',
              type: PlutoColumnType.text()),
        ];
      case 'Masa Bazlı Rapor':
        return [
          PlutoColumn(
              title: 'Masa', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Gelir',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Sipariş',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Ödeme Tipi Analizi':
        return [
          PlutoColumn(
              title: 'Ödeme Tipi',
              field: 'title',
              type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'İşlem Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Tutar',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Tutar',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Stok Durumu':
        return [
          PlutoColumn(
              title: 'Ürün', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Mevcut Stok',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Minimum Stok',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Durum', field: 'value3', type: PlutoColumnType.text()),
        ];
      case 'Kampanya Analizi':
        return [
          PlutoColumn(
              title: 'Kampanya', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Kullanım Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam İndirim',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama İndirim',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Kar/Zarar Analizi':
        return [
          PlutoColumn(
              title: 'Dönem', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Gelir', field: 'value1', type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Gider', field: 'value2', type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Kar/Zarar',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Rezervasyon Raporu':
        return [
          PlutoColumn(
              title: 'Tarih', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Rezervasyon Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Kişi',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Kişi',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Mutfak Çıkış Raporu':
        return [
          PlutoColumn(
              title: 'Saat', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Hazırlanan',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Bekleyen',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Sipariş Hızı Analizi':
        return [
          PlutoColumn(
              title: 'Saat', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Süre',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Durum', field: 'value3', type: PlutoColumnType.text()),
        ];
      case 'Fatura/Fiş Raporu':
        return [
          PlutoColumn(
              title: 'Fiş No', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Tutar', field: 'value1', type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ödeme Tipi',
              field: 'value2',
              type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Tarih', field: 'value3', type: PlutoColumnType.text()),
        ];
      case 'Müşteri Analizi':
        return [
          PlutoColumn(
              title: 'Müşteri Tipi',
              field: 'title',
              type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Ziyaret Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Harcama',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Harcama',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Z Raporu':
        return [
          PlutoColumn(
              title: 'Kategori', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Satış Adedi',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Tutar',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'KDV', field: 'value3', type: PlutoColumnType.number()),
        ];
      case 'X Raporu':
        return [
          PlutoColumn(
              title: 'Ödeme Tipi',
              field: 'title',
              type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'İşlem Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Tutar',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Komisyon',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Günlük Kasa Raporu':
        return [
          PlutoColumn(
              title: 'Kasa', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Açılış', field: 'value1', type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Kapanış',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Fark', field: 'value3', type: PlutoColumnType.number()),
        ];
      case 'Haftalık Özet':
        return [
          PlutoColumn(
              title: 'Gün', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Gelir',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Sipariş',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Aylık Özet':
        return [
          PlutoColumn(
              title: 'Hafta', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Gelir',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Sipariş',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Yıllık Özet':
        return [
          PlutoColumn(
              title: 'Ay', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Sipariş Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Gelir',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama Sipariş',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'Vergi Raporu':
        return [
          PlutoColumn(
              title: 'Dönem', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Brüt Satış',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'KDV', field: 'value2', type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Net Satış',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'İndirim Raporu':
        return [
          PlutoColumn(
              title: 'İndirim Tipi',
              field: 'title',
              type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Kullanım Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam İndirim',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Ortalama İndirim',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
      case 'İade Raporu':
        return [
          PlutoColumn(
              title: 'Ürün', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'İade Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'İade Tutarı',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Sebep', field: 'value3', type: PlutoColumnType.text()),
        ];
      case 'Sipariş Detay Raporu':
        return [
          PlutoColumn(
              title: 'Sipariş No',
              field: 'title',
              type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Ürün Sayısı',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Toplam Tutar',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Durum', field: 'value3', type: PlutoColumnType.text()),
        ];
      default:
        return [
          PlutoColumn(
              title: 'Başlık', field: 'title', type: PlutoColumnType.text()),
          PlutoColumn(
              title: 'Değer 1',
              field: 'value1',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Değer 2',
              field: 'value2',
              type: PlutoColumnType.number()),
          PlutoColumn(
              title: 'Değer 3',
              field: 'value3',
              type: PlutoColumnType.number()),
        ];
    }
  }

  List<PlutoRow> _buildPlutoRows() {
    final data = _getReportData();
    return data
        .map((row) => PlutoRow(cells: {
              'title': PlutoCell(value: row['title']),
              'value1': PlutoCell(value: row['value1']),
              'value2': PlutoCell(value: row['value2']),
              'value3': PlutoCell(value: row['value3']),
            }))
        .toList();
  }

  List<Map<String, dynamic>> _getReportData() {
    switch (selectedReport) {
      case 'Günlük Satış Raporu':
        return List.generate(
            24,
            (index) => {
                  'title': '${index.toString().padLeft(2, '0')}:00',
                  'value1': (index + 1) * 3 + (index % 5),
                  'value2': (index + 1) * 150.0 + (index * 25.50),
                  'value3': 45.0 + (index * 2.5),
                });
      case 'Saatlik Analiz':
        return List.generate(
            24,
            (index) => {
                  'title': '${index.toString().padLeft(2, '0')}:00',
                  'value1': (index + 1) * 2 + (index % 3),
                  'value2': (index + 1) * 120.0 + (index * 20.0),
                  'value3': index < 8 || index > 20
                      ? 'Düşük'
                      : index < 12 || index > 18
                          ? 'Orta'
                          : 'Yüksek',
                });
      case 'Ürün Bazlı Rapor':
        final products = [
          'Döner',
          'Pizza',
          'Hamburger',
          'Çorba',
          'Salata',
          'Tatlı',
          'İçecek',
          'Kahvaltı'
        ];
        return List.generate(
            products.length,
            (index) => {
                  'title': products[index],
                  'value1': (index + 1) * 5 + (index % 3),
                  'value2': (index + 1) * 200.0 + (index * 35.0),
                  'value3': 25.0 + (index * 3.5),
                });
      case 'Kategori Bazlı Rapor':
        final categories = [
          'Ana Yemek',
          'Çorba',
          'Salata',
          'Tatlı',
          'İçecek',
          'Kahvaltı',
          'Fast Food'
        ];
        return List.generate(
            categories.length,
            (index) => {
                  'title': categories[index],
                  'value1': (index + 1) * 3 + (index % 2),
                  'value2': (index + 1) * 300.0 + (index * 50.0),
                  'value3': 35.0 + (index * 5.0),
                });
      case 'Personel Performans':
        final staff = [
          'Ahmet Yılmaz',
          'Fatma Demir',
          'Mehmet Kaya',
          'Ayşe Özkan',
          'Ali Veli'
        ];
        return List.generate(
            staff.length,
            (index) => {
                  'title': staff[index],
                  'value1': (index + 1) * 8 + (index % 4),
                  'value2': (index + 1) * 400.0 + (index * 60.0),
                  'value3': index < 2
                      ? 'Mükemmel'
                      : index < 4
                          ? 'İyi'
                          : 'Orta',
                });
      case 'Masa Bazlı Rapor':
        return List.generate(
            7,
            (index) => {
                  'title': index == 6 ? 'Self Servis' : 'Masa ${index + 1}',
                  'value1': (index + 1) * 4 + (index % 3),
                  'value2': (index + 1) * 250.0 + (index * 40.0),
                  'value3': 45.0 + (index * 3.0),
                });
      case 'Ödeme Tipi Analizi':
        final paymentTypes = ['Nakit', 'Kredi Kartı', 'QR Kod', 'Bölüşümlü'];
        return List.generate(
            paymentTypes.length,
            (index) => {
                  'title': paymentTypes[index],
                  'value1': (index + 1) * 15 + (index % 5),
                  'value2': (index + 1) * 500.0 + (index * 80.0),
                  'value3': 35.0 + (index * 4.0),
                });
      case 'Stok Durumu':
        final products = [
          'Döner Eti',
          'Pizza Hamuru',
          'Hamburger Eti',
          'Çorba',
          'Salata',
          'Tatlı',
          'İçecek'
        ];
        return List.generate(
            products.length,
            (index) => {
                  'title': products[index],
                  'value1': (index + 1) * 10 + (index % 5),
                  'value2': (index + 1) * 5 + (index % 3),
                  'value3': (index + 1) * 10 + (index % 5) >
                          (index + 1) * 5 + (index % 3)
                      ? 'Yeterli'
                      : 'Kritik',
                });
      case 'Kampanya Analizi':
        final campaigns = [
          'Öğrenci İndirimi',
          'Hafta Sonu',
          'Doğum Günü',
          'Yeni Müşteri'
        ];
        return List.generate(
            campaigns.length,
            (index) => {
                  'title': campaigns[index],
                  'value1': (index + 1) * 8 + (index % 4),
                  'value2': (index + 1) * 150.0 + (index * 25.0),
                  'value3': 15.0 + (index * 2.5),
                });
      case 'Kar/Zarar Analizi':
        final periods = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran'];
        return List.generate(
            periods.length,
            (index) => {
                  'title': periods[index],
                  'value1': (index + 1) * 5000.0 + (index * 500.0),
                  'value2': (index + 1) * 3000.0 + (index * 300.0),
                  'value3': (index + 1) * 2000.0 + (index * 200.0),
                });
      case 'Rezervasyon Raporu':
        return List.generate(
            7,
            (index) => {
                  'title':
                      '${DateTime.now().add(Duration(days: index)).day}/${DateTime.now().month}',
                  'value1': (index + 1) * 3 + (index % 4),
                  'value2': (index + 1) * 12 + (index % 6),
                  'value3': 4.0 + (index * 0.5),
                });
      case 'Mutfak Çıkış Raporu':
        return List.generate(
            24,
            (index) => {
                  'title': '${index.toString().padLeft(2, '0')}:00',
                  'value1': (index + 1) * 2 + (index % 3),
                  'value2': (index + 1) * 1 + (index % 2),
                  'value3': (index + 1) * 1 + (index % 2),
                });
      case 'Sipariş Hızı Analizi':
        return List.generate(
            24,
            (index) => {
                  'title': '${index.toString().padLeft(2, '0')}:00',
                  'value1': (index + 1) * 3 + (index % 4),
                  'value2': 15.0 + (index * 1.5),
                  'value3': 15.0 + (index * 1.5) < 20
                      ? 'Hızlı'
                      : 15.0 + (index * 1.5) < 30
                          ? 'Normal'
                          : 'Yavaş',
                });
      case 'Fatura/Fiş Raporu':
        return List.generate(
            20,
            (index) => {
                  'title': 'F${(index + 1).toString().padLeft(4, '0')}',
                  'value1': (index + 1) * 50.0 + (index * 10.0),
                  'value2': ['Nakit', 'Kredi Kartı', 'QR Kod'][index % 3],
                  'value3':
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                });
      case 'Müşteri Analizi':
        final customerTypes = ['Yeni', 'Düzenli', 'VIP', 'Kurumsal'];
        return List.generate(
            customerTypes.length,
            (index) => {
                  'title': customerTypes[index],
                  'value1': (index + 1) * 25 + (index % 10),
                  'value2': (index + 1) * 800.0 + (index * 150.0),
                  'value3': 35.0 + (index * 8.0),
                });
      case 'Z Raporu':
        final categories = ['Ana Yemek', 'İçecek', 'Tatlı', 'Çorba', 'Salata'];
        return List.generate(
            categories.length,
            (index) => {
                  'title': categories[index],
                  'value1': (index + 1) * 15 + (index % 5),
                  'value2': (index + 1) * 400.0 + (index * 60.0),
                  'value3': (index + 1) * 40.0 + (index * 6.0),
                });
      case 'X Raporu':
        final paymentTypes = ['Nakit', 'Kredi Kartı', 'QR Kod'];
        return List.generate(
            paymentTypes.length,
            (index) => {
                  'title': paymentTypes[index],
                  'value1': (index + 1) * 20 + (index % 8),
                  'value2': (index + 1) * 600.0 + (index * 100.0),
                  'value3': (index + 1) * 15.0 + (index * 2.5),
                });
      case 'Günlük Kasa Raporu':
        return List.generate(
            3,
            (index) => {
                  'title': 'Kasa ${index + 1}',
                  'value1': 1000.0 + (index * 200.0),
                  'value2': 1500.0 + (index * 300.0),
                  'value3': 500.0 + (index * 100.0),
                });
      case 'Haftalık Özet':
        final days = [
          'Pazartesi',
          'Salı',
          'Çarşamba',
          'Perşembe',
          'Cuma',
          'Cumartesi',
          'Pazar'
        ];
        return List.generate(
            days.length,
            (index) => {
                  'title': days[index],
                  'value1': (index + 1) * 12 + (index % 5),
                  'value2': (index + 1) * 800.0 + (index * 120.0),
                  'value3': 45.0 + (index * 3.0),
                });
      case 'Aylık Özet':
        return List.generate(
            4,
            (index) => {
                  'title': '${index + 1}. Hafta',
                  'value1': (index + 1) * 80 + (index % 20),
                  'value2': (index + 1) * 5000.0 + (index * 800.0),
                  'value3': 45.0 + (index * 2.0),
                });
      case 'Yıllık Özet':
        final months = [
          'Ocak',
          'Şubat',
          'Mart',
          'Nisan',
          'Mayıs',
          'Haziran',
          'Temmuz',
          'Ağustos',
          'Eylül',
          'Ekim',
          'Kasım',
          'Aralık'
        ];
        return List.generate(
            months.length,
            (index) => {
                  'title': months[index],
                  'value1': (index + 1) * 300 + (index % 50),
                  'value2': (index + 1) * 20000.0 + (index * 3000.0),
                  'value3': 45.0 + (index * 1.5),
                });
      case 'Vergi Raporu':
        final periods = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran'];
        return List.generate(
            periods.length,
            (index) => {
                  'title': periods[index],
                  'value1': (index + 1) * 10000.0 + (index * 1500.0),
                  'value2': (index + 1) * 1800.0 + (index * 270.0),
                  'value3': (index + 1) * 8200.0 + (index * 1230.0),
                });
      case 'İndirim Raporu':
        final discountTypes = [
          'Öğrenci',
          'Hafta Sonu',
          'Doğum Günü',
          'Yeni Müşteri',
          'Sadakat'
        ];
        return List.generate(
            discountTypes.length,
            (index) => {
                  'title': discountTypes[index],
                  'value1': (index + 1) * 12 + (index % 5),
                  'value2': (index + 1) * 200.0 + (index * 35.0),
                  'value3': 15.0 + (index * 2.0),
                });
      case 'İade Raporu':
        final products = ['Döner', 'Pizza', 'Hamburger', 'Çorba', 'Salata'];
        return List.generate(
            products.length,
            (index) => {
                  'title': products[index],
                  'value1': (index + 1) * 2 + (index % 3),
                  'value2': (index + 1) * 50.0 + (index * 10.0),
                  'value3': [
                    'Kalite',
                    'Hazırlama',
                    'Müşteri',
                    'Diğer'
                  ][index % 4],
                });
      case 'Sipariş Detay Raporu':
        return List.generate(
            20,
            (index) => {
                  'title': 'S${(index + 1).toString().padLeft(4, '0')}',
                  'value1': (index + 1) * 3 + (index % 4),
                  'value2': (index + 1) * 75.0 + (index * 12.0),
                  'value3': [
                    'Hazırlanıyor',
                    'Hazır',
                    'Teslim Edildi'
                  ][index % 3],
                });
      default:
        return List.generate(
            20,
            (index) => {
                  'title': 'Veri ${index + 1}',
                  'value1': (index + 1) * 10.0,
                  'value2': (index + 1) * 25.50,
                  'value3': (index + 1) * 2.50,
                });
    }
  }

  IconData _getReportIcon(String report) {
    switch (report) {
      case 'Günlük Satış Raporu':
        return Icons.trending_up;
      case 'Saatlik Analiz':
        return Icons.schedule;
      case 'Ürün Bazlı Rapor':
        return Icons.inventory;
      case 'Kategori Bazlı Rapor':
        return Icons.category;
      case 'Personel Performans':
        return Icons.people;
      case 'Masa Bazlı Rapor':
        return Icons.table_restaurant;
      case 'Ödeme Tipi Analizi':
        return Icons.payment;
      case 'Stok Durumu':
        return Icons.warehouse;
      case 'Kampanya Analizi':
        return Icons.local_offer;
      case 'Kar/Zarar Analizi':
        return Icons.account_balance;
      case 'Rezervasyon Raporu':
        return Icons.book_online;
      case 'Mutfak Çıkış Raporu':
        return Icons.kitchen;
      case 'Sipariş Hızı Analizi':
        return Icons.speed;
      case 'Fatura/Fiş Raporu':
        return Icons.receipt;
      case 'Müşteri Analizi':
        return Icons.person;
      case 'Z Raporu':
        return Icons.summarize;
      case 'X Raporu':
        return Icons.assessment;
      case 'Günlük Kasa Raporu':
        return Icons.point_of_sale;
      case 'Haftalık Özet':
        return Icons.calendar_view_week;
      case 'Aylık Özet':
        return Icons.calendar_view_month;
      case 'Yıllık Özet':
        return Icons.calendar_today;
      case 'Vergi Raporu':
        return Icons.account_balance_wallet;
      case 'İndirim Raporu':
        return Icons.discount;
      case 'İade Raporu':
        return Icons.undo;
      case 'Sipariş Detay Raporu':
        return Icons.list_alt;
      default:
        return Icons.analytics;
    }
  }

  void _exportReport() {
    // TODO: Rapor dışa aktarma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapor dışa aktarılıyor...')),
    );
  }

  void _printReport() {
    // TODO: Rapor yazdırma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapor yazdırılıyor...')),
    );
  }

  void _showReportSettings() {
    // TODO: Rapor ayarları dialog'u
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapor Ayarları'),
        content: const Text('Rapor ayarları burada gösterilecek'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

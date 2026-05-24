import '../../../core/base/base_viewmodel.dart';

class ReportModel {
  final String id;
  final String title;
  final String type; // 'sales', 'products', 'tables', 'revenue'
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      startDate: DateTime.parse(
          json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate:
          DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      data: json['data'] ?? {},
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ReportsViewModel extends BaseViewModel {
  List<ReportModel> _reports = [];
  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 7));
  DateTime _selectedEndDate = DateTime.now();
  String _selectedReportType = 'sales';

  List<ReportModel> get reports => _reports;
  DateTime get selectedStartDate => _selectedStartDate;
  DateTime get selectedEndDate => _selectedEndDate;
  String get selectedReportType => _selectedReportType;

  ReportsViewModel() {
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setLoading(true);

      // TODO: GraphQL ile raporları yükle
      await Future.delayed(const Duration(milliseconds: 500));

      _reports = [
        ReportModel(
          id: 'report_1',
          title: 'Günlük Satış Raporu',
          type: 'sales',
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now(),
          data: {
            'total_sales': 1250.0,
            'total_orders': 45,
            'average_order_value': 27.78,
            'top_products': [
              {'name': 'Döner', 'quantity': 25, 'revenue': 625.0},
              {'name': 'Ayran', 'quantity': 40, 'revenue': 200.0},
              {'name': 'Künefe', 'quantity': 15, 'revenue': 225.0},
            ],
          },
          createdAt: DateTime.now(),
        ),
        ReportModel(
          id: 'report_2',
          title: 'Haftalık Gelir Raporu',
          type: 'revenue',
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          data: {
            'total_revenue': 8750.0,
            'cash_payments': 5250.0,
            'card_payments': 3500.0,
            'daily_revenue': [
              {'date': '2024-01-01', 'revenue': 1200.0},
              {'date': '2024-01-02', 'revenue': 1350.0},
              {'date': '2024-01-03', 'revenue': 1100.0},
              {'date': '2024-01-04', 'revenue': 1400.0},
              {'date': '2024-01-05', 'revenue': 1600.0},
              {'date': '2024-01-06', 'revenue': 1250.0},
              {'date': '2024-01-07', 'revenue': 850.0},
            ],
          },
          createdAt: DateTime.now(),
        ),
      ];

      notifyListeners();
    } catch (e) {
      setError('Raporlar yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  void setDateRange(DateTime startDate, DateTime endDate) {
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    notifyListeners();
  }

  void setReportType(String type) {
    _selectedReportType = type;
    notifyListeners();
  }

  Future<ReportModel?> generateReport(
      String type, DateTime startDate, DateTime endDate) async {
    try {
      setLoading(true);

      // TODO: GraphQL ile rapor oluştur
      await Future.delayed(const Duration(milliseconds: 1000));

      final report = ReportModel(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_getReportTypeTitle(type)} Raporu',
        type: type,
        startDate: startDate,
        endDate: endDate,
        data: await _generateReportData(type, startDate, endDate),
        createdAt: DateTime.now(),
      );

      _reports.add(report);
      notifyListeners();
      return report;
    } catch (e) {
      setError('Rapor oluşturulurken hata oluştu: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> _generateReportData(
      String type, DateTime startDate, DateTime endDate) async {
    // Mock data generation
    switch (type) {
      case 'sales':
        return {
          'total_sales': 2500.0,
          'total_orders': 85,
          'average_order_value': 29.41,
          'top_products': [
            {'name': 'Döner', 'quantity': 50, 'revenue': 1250.0},
            {'name': 'Ayran', 'quantity': 80, 'revenue': 400.0},
            {'name': 'Künefe', 'quantity': 30, 'revenue': 450.0},
          ],
        };
      case 'revenue':
        return {
          'total_revenue': 2500.0,
          'cash_payments': 1500.0,
          'card_payments': 1000.0,
          'daily_revenue': [
            {
              'date': startDate.toIso8601String().split('T')[0],
              'revenue': 1200.0
            },
            {
              'date': endDate.toIso8601String().split('T')[0],
              'revenue': 1300.0
            },
          ],
        };
      case 'products':
        return {
          'total_products': 25,
          'low_stock_products': 5,
          'out_of_stock_products': 2,
          'top_selling_products': [
            {'name': 'Döner', 'sales_count': 50},
            {'name': 'Ayran', 'sales_count': 80},
            {'name': 'Künefe', 'sales_count': 30},
          ],
        };
      case 'tables':
        return {
          'total_tables': 10,
          'occupied_tables': 6,
          'available_tables': 4,
          'table_utilization': 60.0,
          'average_table_turnover': 2.5,
        };
      default:
        return {};
    }
  }

  String _getReportTypeTitle(String type) {
    switch (type) {
      case 'sales':
        return 'Satış';
      case 'revenue':
        return 'Gelir';
      case 'products':
        return 'Ürün';
      case 'tables':
        return 'Masa';
      default:
        return 'Genel';
    }
  }

  List<ReportModel> getReportsByType(String type) {
    return _reports.where((report) => report.type == type).toList();
  }

  List<ReportModel> getReportsByDateRange(
      DateTime startDate, DateTime endDate) {
    return _reports.where((report) {
      return report.startDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          report.endDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}

import '../../../core/base/base_viewmodel.dart';
import '../../../services/postgres_service.dart';

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
  final PostgresService _postgresService = PostgresService();
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
      await _postgresService.initialize();

      final templates = await _postgresService.getReportTemplates();
      if (templates.isNotEmpty) {
        _reports = templates
            .map(
              (template) => ReportModel(
                id: template['id']?.toString() ?? '',
                title: template['name']?.toString() ?? 'Rapor',
                type: template['category']?.toString() ?? 'custom',
                startDate: _selectedStartDate,
                endDate: _selectedEndDate,
                data: {
                  'description': template['description'],
                  'data_source': template['data_source'],
                  'columns': template['columns'],
                  'chart_config': template['chart_config'],
                },
                createdAt: DateTime.tryParse(
                      template['created_at']?.toString() ?? '',
                    ) ??
                    DateTime.now(),
              ),
            )
            .toList();
      } else {
        final sales = await _postgresService.getDailySalesSummary(
          startDate: _selectedStartDate,
          endDate: _selectedEndDate,
        );
        _reports = [
          ReportModel(
            id: 'daily_sales_summary',
            title: 'Günlük Satış Özeti',
            type: 'sales',
            startDate: _selectedStartDate,
            endDate: _selectedEndDate,
            data: {
              'rows': sales,
              'total_sales': sales.fold<double>(
                0.0,
                (sum, row) =>
                    sum + (double.tryParse('${row['total_revenue']}') ?? 0.0),
              ),
              'total_orders': sales.fold<int>(
                0,
                (sum, row) => sum + (int.tryParse('${row['total_orders']}') ?? 0),
              ),
            },
            createdAt: DateTime.now(),
          ),
        ];
      }

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
      await _postgresService.initialize();
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
    switch (type) {
      case 'sales':
        final rows = await _postgresService.getDailySalesSummary(
          startDate: startDate,
          endDate: endDate,
        );
        return {
          'rows': rows,
          'total_sales': rows.fold<double>(
            0.0,
            (sum, row) =>
                sum + (double.tryParse('${row['total_revenue']}') ?? 0.0),
          ),
          'total_orders': rows.fold<int>(
            0,
            (sum, row) => sum + (int.tryParse('${row['total_orders']}') ?? 0),
          ),
        };
      case 'revenue':
        final rows = await _postgresService.getDailySalesSummary(
          startDate: startDate,
          endDate: endDate,
        );
        final totalRevenue = rows.fold<double>(
          0.0,
          (sum, row) =>
              sum + (double.tryParse('${row['total_revenue']}') ?? 0.0),
        );
        return {
          'total_revenue': totalRevenue,
          'cash_payments': totalRevenue * 0.55,
          'card_payments': totalRevenue * 0.45,
          'daily_revenue': rows,
        };
      case 'products':
        final products = await _postgresService.getProducts();
        return {
          'total_products': products.length,
          'low_stock_products': 0,
          'out_of_stock_products': 0,
          'top_selling_products': products.take(10).toList(),
        };
      case 'tables':
        final stats = await _postgresService.getStatistics();
        return {
          'total_tables': stats['totalTables'] ?? 0,
          'occupied_tables': stats['occupiedTables'] ?? 0,
          'available_tables': stats['availableTables'] ?? 0,
          'table_utilization': stats['utilizationRate'] ?? 0,
          'average_table_turnover': 0,
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

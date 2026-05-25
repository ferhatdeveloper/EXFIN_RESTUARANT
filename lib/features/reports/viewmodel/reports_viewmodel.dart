import '../../../core/base/base_viewmodel.dart';
import '../../../services/postgres_service.dart';

class ReportModel {
  final String id;
  final String title;
  final String type;
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
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      data: json['data'] ?? {},
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
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
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _selectedEndDate = DateTime.now();
  String _selectedReportType = 'sales';

  List<ReportModel> get reports => _reports;
  DateTime get selectedStartDate => _selectedStartDate;
  DateTime get selectedEndDate => _selectedEndDate;
  String get selectedReportType => _selectedReportType;

  ReportsViewModel() {
    _loadReports();
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  Future<void> _loadReports() async {
    try {
      setLoading(true);

      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final salesData = await pg.query(
        "SELECT COUNT(*) as cnt, COALESCE(SUM(net_amount), 0) as total, COALESCE(AVG(net_amount), 0) as avg_val FROM rex_001_01_sales WHERE is_cancelled = false AND DATE(created_at) >= CURRENT_DATE - INTERVAL '7 days'",
      );

      final topProducts = await pg.query(
        "SELECT item_name, SUM(quantity) as qty, SUM(net_amount) as revenue FROM rex_001_01_sale_items WHERE firm_nr = '001' GROUP BY item_name ORDER BY revenue DESC LIMIT 5",
      );

      final paymentData = await pg.query(
        "SELECT payment_method, COUNT(*) as cnt, COALESCE(SUM(net_amount), 0) as total FROM rex_001_01_sales WHERE is_cancelled = false AND DATE(created_at) >= CURRENT_DATE - INTERVAL '7 days' GROUP BY payment_method",
      );

      double totalSales = 0;
      int totalOrders = 0;
      double avgOrder = 0;
      if (salesData.isNotEmpty) {
        totalSales = _toDouble(salesData.first['total']);
        totalOrders = _toInt(salesData.first['cnt']);
        avgOrder = _toDouble(salesData.first['avg_val']);
      }

      double cashPayments = 0;
      double cardPayments = 0;
      double creditPayments = 0;
      for (final p in paymentData) {
        final method = p['payment_method']?.toString() ?? '';
        final total = _toDouble(p['total']);
        if (method == 'cash') cashPayments = total;
        else if (method == 'card') cardPayments = total;
        else if (method == 'credit') creditPayments = total;
      }

      final topProductsList = topProducts.map((p) => {
        'name': p['item_name']?.toString() ?? '-',
        'quantity': _toDouble(p['qty']),
        'revenue': _toDouble(p['revenue']),
      }).toList();

      _reports = [
        ReportModel(
          id: 'report_sales',
          title: 'Satış Raporu (Son 7 Gün)',
          type: 'sales',
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          data: {
            'total_sales': totalSales,
            'total_orders': totalOrders,
            'average_order_value': avgOrder,
            'top_products': topProductsList,
          },
          createdAt: DateTime.now(),
        ),
        ReportModel(
          id: 'report_revenue',
          title: 'Gelir Raporu (Son 7 Gün)',
          type: 'revenue',
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          data: {
            'total_revenue': totalSales,
            'cash_payments': cashPayments,
            'card_payments': cardPayments,
            'credit_payments': creditPayments,
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
      final data = await _generateReportData(type, startDate, endDate);

      final report = ReportModel(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_getReportTypeTitle(type)} Raporu',
        type: type,
        startDate: startDate,
        endDate: endDate,
        data: data,
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

  String _getReportTypeTitle(String type) {
    switch (type) {
      case 'sales': return 'Satış';
      case 'products': return 'Ürün';
      case 'tables': return 'Masa';
      case 'revenue': return 'Gelir';
      case 'staff': return 'Personel';
      default: return 'Genel';
    }
  }

  Future<Map<String, dynamic>> _generateReportData(
      String type, DateTime startDate, DateTime endDate) async {
    final pg = PostgresService();
    if (!pg.isConnected) await pg.initialize();

    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    switch (type) {
      case 'sales':
        final result = await pg.query(
          "SELECT COUNT(*) as cnt, COALESCE(SUM(net_amount), 0) as total, COALESCE(AVG(net_amount), 0) as avg_val FROM rex_001_01_sales WHERE is_cancelled = false AND DATE(created_at) >= '$startStr' AND DATE(created_at) <= '$endStr'",
        );
        return {
          'total_sales': _toDouble(result.isNotEmpty ? result.first['total'] : 0),
          'total_orders': _toInt(result.isNotEmpty ? result.first['cnt'] : 0),
          'average_order_value': _toDouble(result.isNotEmpty ? result.first['avg_val'] : 0),
        };

      case 'revenue':
        final result = await pg.query(
          "SELECT payment_method, COALESCE(SUM(net_amount), 0) as total FROM rex_001_01_sales WHERE is_cancelled = false AND DATE(created_at) >= '$startStr' AND DATE(created_at) <= '$endStr' GROUP BY payment_method",
        );
        double cash = 0, card = 0, credit = 0;
        for (final r in result) {
          final m = r['payment_method']?.toString() ?? '';
          final t = _toDouble(r['total']);
          if (m == 'cash') cash = t;
          else if (m == 'card') card = t;
          else if (m == 'credit') credit = t;
        }
        return {'cash_payments': cash, 'card_payments': card, 'credit_payments': credit, 'total_revenue': cash + card + credit};

      case 'products':
        final result = await pg.query(
          "SELECT item_name, SUM(quantity) as qty, SUM(net_amount) as revenue FROM rex_001_01_sale_items WHERE firm_nr = '001' GROUP BY item_name ORDER BY revenue DESC LIMIT 10",
        );
        return {'top_products': result.map((r) => {'name': r['item_name'], 'quantity': _toDouble(r['qty']), 'revenue': _toDouble(r['revenue'])}).toList()};

      default:
        return {};
    }
  }

  Future<void> refreshReports() async {
    await _loadReports();
  }
}

// Dosya Adı: report_data_model.dart
// Açıklama: Raporlar için veri modeli sınıfları
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

/// {@template ReportDataModel}
/// Rapor verilerini temsil eden temel model sınıfı
/// {@endtemplate}
class ReportDataModel {
  final String id;
  final String title;
  final double value1;
  final double value2;
  final double value3;
  final DateTime date;
  final bool isGroupHeader;
  final String? groupValue;

  ReportDataModel({
    required this.id,
    required this.title,
    required this.value1,
    required this.value2,
    required this.value3,
    required this.date,
    this.isGroupHeader = false,
    this.groupValue,
  });
}

/// {@template DailySalesReportModel}
/// Günlük satış raporu veri modeli
/// {@endtemplate}
class DailySalesReportModel extends ReportDataModel {
  final String hour;
  final int orderCount;
  final double totalSales;
  final double averageOrder;

  DailySalesReportModel({
    required super.id,
    required this.hour,
    required this.orderCount,
    required this.totalSales,
    required this.averageOrder,
    required super.date,
  }) : super(
          title: hour,
          value1: orderCount.toDouble(),
          value2: totalSales,
          value3: averageOrder,
        );
}

/// {@template ProductReportModel}
/// Ürün bazlı rapor veri modeli
/// {@endtemplate}
class ProductReportModel extends ReportDataModel {
  final String productName;
  final int salesQuantity;
  final double totalRevenue;
  final double averagePrice;

  ProductReportModel({
    required super.id,
    required this.productName,
    required this.salesQuantity,
    required this.totalRevenue,
    required this.averagePrice,
    required super.date,
  }) : super(
          title: productName,
          value1: salesQuantity.toDouble(),
          value2: totalRevenue,
          value3: averagePrice,
        );
}

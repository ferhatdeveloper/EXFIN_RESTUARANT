import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../features/home/viewmodel/home_viewmodel.dart';
import '../../features/kitchen/viewmodel/kitchen_viewmodel.dart';
import '../../features/orders/viewmodel/orders_viewmodel.dart';
import '../../features/payment/viewmodel/payment_viewmodel.dart';
import '../../features/products/viewmodel/products_viewmodel.dart';
import '../../features/reports/viewmodel/reports_viewmodel.dart';
import '../../features/tables/viewmodel/tables_viewmodel.dart';
import '../../services/database_service.dart';
import '../../services/postgres_service.dart';
import '../../services/data_service.dart';

// Auth Provider
final authProvider =
    ChangeNotifierProvider<AuthViewModel>((ref) => AuthViewModel());

// Home Provider
final homeProvider =
    ChangeNotifierProvider<HomeViewModel>((ref) => HomeViewModel());

// Database Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// PostgreSQL Service Provider
final postgresServiceProvider = Provider<PostgresService>((ref) {
  return PostgresService();
});

// Data Service Provider
final dataServiceProvider = Provider<DataService>((ref) {
  return DataService();
});

// PostgreSQL Settings Provider
final postgresSettingsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  return await dbService.getPostgresSettings();
});

// PostgreSQL Connection Status Provider
final postgresConnectionProvider = FutureProvider<bool>((ref) async {
  final postgresService = ref.read(postgresServiceProvider);
  return await postgresService.testConnection();
});

// Users Provider
final usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return await dataService.getUsers();
});

// Tables Data Provider
final tablesDataProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return await dataService.getTables();
});

// Regions Provider
final regionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return await dataService.getRegions();
});

// Statistics Provider
final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return await dataService.getStatistics();
});

// Orders Provider
final ordersProvider =
    ChangeNotifierProvider<OrdersViewModel>((ref) => OrdersViewModel());

// Products Provider
final productsProvider =
    ChangeNotifierProvider<ProductsViewModel>((ref) => ProductsViewModel());

// Kitchen Provider
final kitchenProvider =
    ChangeNotifierProvider<KitchenViewModel>((ref) => KitchenViewModel());

// Payment Provider
final paymentProvider =
    ChangeNotifierProvider<PaymentViewModel>((ref) => PaymentViewModel());

// Reports Provider
final reportsProvider =
    ChangeNotifierProvider<ReportsViewModel>((ref) => ReportsViewModel());

// API Service Provider - HTTP Provider'dan import edildi
// final apiServiceProvider = apiServiceProvider;

// SignalR Provider - HTTP Provider'dan import edildi
// final signalRProvider = signalRProvider;

// Theme Provider ve HTTP Provider zaten ilgili dosyalarda tanımlı, burada tekrar tanımlamaya gerek yok.

import 'package:flutter/foundation.dart';
import '../../../../services/postgres_service.dart';
import '../../../../services/signalr_service.dart';

class OrdersViewModel extends ChangeNotifier {
  final PostgresService _postgresService = PostgresService();
  final SignalRService _signalRService = SignalRService();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrders({
    int? tableId,
    String? status,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    setLoading(true);
    clearError();

    try {
      debugPrint('🔍 Siparişler yükleniyor...');
      final ordersData = await _postgresService.getOrders(
        tableId: tableId,
        status: status,
        paymentStatus: paymentStatus,
        startDate: startDate,
        endDate: endDate,
      );

      _orders = ordersData;
      debugPrint('✅ Siparişler yüklendi: ${_orders.length} adet');
    } catch (e) {
      debugPrint('❌ Siparişler yüklenemedi: $e');
      setError('Siparişler yüklenemedi: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      return await _postgresService.getOrderById(orderId);
    } catch (e) {
      debugPrint('❌ Sipariş getirilemedi: $e');
      setError('Sipariş getirilemedi: $e');
      return null;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final success = await _postgresService.updateOrderStatus(orderId, status);
      if (success) {
        // Sipariş listesini yenile
        await loadOrders();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Sipariş durumu güncellenemedi: $e');
      setError('Sipariş durumu güncellenemedi: $e');
      return false;
    }
  }

  Future<bool> updatePaymentStatus(int orderId, String paymentStatus) async {
    try {
      final success =
          await _postgresService.updatePaymentStatus(orderId, paymentStatus);
      if (success) {
        // Sipariş listesini yenile
        await loadOrders();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Ödeme durumu güncellenemedi: $e');
      setError('Ödeme durumu güncellenemedi: $e');
      return false;
    }
  }

  Future<bool> deleteOrder(int orderId) async {
    try {
      final success = await _postgresService.deleteOrder(orderId);
      if (success) {
        // Sipariş listesini yenile
        await loadOrders();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Sipariş silinemedi: $e');
      setError('Sipariş silinemedi: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByTable(int tableId) async {
    try {
      return await _postgresService.getOrdersByTable(tableId);
    } catch (e) {
      debugPrint('❌ Masa siparişleri getirilemedi: $e');
      setError('Masa siparişleri getirilemedi: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      return await _postgresService.getOrderStatistics();
    } catch (e) {
      debugPrint('❌ Sipariş istatistikleri getirilemedi: $e');
      setError('Sipariş istatistikleri getirilemedi: $e');
      return {
        'todayOrders': 0,
        'todayRevenue': 0.0,
        'pendingOrders': 0,
        'unpaidOrders': 0,
        'avgOrderAmount': 0.0,
      };
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void initializeSignalR() {
    _signalRService.onOrderCreated((orderData) {
      debugPrint('🆕 Yeni sipariş oluşturuldu: $orderData');
      loadOrders();
    });

    _signalRService.onOrderUpdated((orderData) {
      debugPrint('🔄 Sipariş güncellendi: $orderData');
      loadOrders();
    });

    _signalRService.onOrderDeleted((orderId) {
      debugPrint('🗑️ Sipariş silindi: $orderId');
      loadOrders();
    });
  }
}

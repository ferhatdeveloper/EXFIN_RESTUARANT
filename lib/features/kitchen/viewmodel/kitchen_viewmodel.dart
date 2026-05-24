import 'package:flutter/foundation.dart';
import '../../../core/base/base_viewmodel.dart';
import '../../../services/postgres_service.dart';
import '../../../services/signalr_service.dart';

class KitchenViewModel extends BaseViewModel {
  List<dynamic> _pendingOrders = [];
  List<dynamic> _preparingOrders = [];
  List<dynamic> _readyOrders = [];
  final SignalRService _signalRService = SignalRService();

  List<dynamic> get pendingOrders => _pendingOrders;
  List<dynamic> get preparingOrders => _preparingOrders;
  List<dynamic> get readyOrders => _readyOrders;

  Future<void> initializeSignalR() async {
    await _signalRService.initialize();
    await _signalRService.connect();
    await _signalRService.joinKitchenGroup();

    // SignalR olaylarını dinle
    _signalRService.onNewOrder((order) {
      // Yeni sipariş geldiğinde listeyi yenile
      loadOrders();
    });

    _signalRService.onOrderStatusChanged((orderId, status) {
      // Sipariş durumu değiştiğinde listeyi yenile
      loadOrders();
    });
  }

  Future<void> loadOrders() async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();
      // Mock sipariş verileri
      final allOrders = [
        {
          'id': '1',
          'status': 'pending',
          'items': ['Pizza', 'Cola']
        },
        {
          'id': '2',
          'status': 'preparing',
          'items': ['Burger', 'Fries']
        },
        {
          'id': '3',
          'status': 'ready',
          'items': ['Salad', 'Water']
        },
      ];

      // Siparişleri durumlarına göre ayır
      _pendingOrders =
          allOrders.where((order) => order['status'] == 'pending').toList();
      _preparingOrders =
          allOrders.where((order) => order['status'] == 'preparing').toList();
      _readyOrders =
          allOrders.where((order) => order['status'] == 'ready').toList();

      notifyListeners();
    } catch (e) {
      setError('Siparişler yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();
      // Mock sipariş güncelleme
      debugPrint('Sipariş durumu güncellendi: $orderId -> $status');
      await loadOrders(); // Listeyi yenile
      return true;
    } catch (e) {
      setError('Sipariş durumu güncellenirken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> moveToPreparing(String orderId) async {
    return await updateOrderStatus(orderId, 'preparing');
  }

  Future<bool> moveToReady(String orderId) async {
    return await updateOrderStatus(orderId, 'ready');
  }

  Future<bool> markAsServed(String orderId) async {
    return await updateOrderStatus(orderId, 'served');
  }

  @override
  void dispose() {
    _signalRService.disconnect();
    super.dispose();
  }
}

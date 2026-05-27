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
    try {
      await _signalRService.initialize();
      await _signalRService.connect();
      await _signalRService.joinKitchenGroup();

      _signalRService.onNewOrder((order) {
        loadOrders();
      });

      _signalRService.onOrderStatusChanged((orderId, status) {
        loadOrders();
      });
    } catch (e) {
      debugPrint('SignalR init error (non-blocking): $e');
    }
  }

  Future<void> loadOrders() async {
    try {
      setLoading(true);
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final results = await pg.query('''
        SELECT ko.id, ko.order_id, ko.table_number, ko.floor_name, ko.waiter,
               ko.status, ko.note, ko.sent_at,
               ki.product_name, ki.quantity, ki.status as item_status
        FROM rest.rex_001_01_rest_kitchen_orders ko
        LEFT JOIN rest.rex_001_01_rest_kitchen_items ki ON ki.kitchen_order_id = ko.id
        ORDER BY ko.sent_at DESC
      ''');

      final Map<String, Map<String, dynamic>> orderMap = {};
      for (final row in results) {
        final orderId = row['id']?.toString() ?? '';
        if (!orderMap.containsKey(orderId)) {
          orderMap[orderId] = {
            'id': orderId,
            'orderId': row['order_id']?.toString(),
            'tableNumber': row['table_number']?.toString() ?? '?',
            'floorName': row['floor_name']?.toString() ?? '',
            'waiter': row['waiter']?.toString() ?? '',
            'status': row['status']?.toString() ?? 'new',
            'note': row['note']?.toString(),
            'sentAt': row['sent_at']?.toString(),
            'items': <String>[],
          };
        }
        if (row['product_name'] != null) {
          final qty = row['quantity'] ?? 1;
          (orderMap[orderId]!['items'] as List<String>)
              .add('${row['product_name']} x$qty');
        }
      }

      final allOrders = orderMap.values.toList();

      _pendingOrders = allOrders
          .where((o) => o['status'] == 'new')
          .toList();
      _preparingOrders = allOrders
          .where((o) => o['status'] == 'preparing' || o['status'] == 'cooking')
          .toList();
      _readyOrders = allOrders
          .where((o) => o['status'] == 'ready' || o['status'] == 'served')
          .toList();

      setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Kitchen loadOrders error: $e');
      setLoading(false);
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      await pg.query(
        "UPDATE rest.rex_001_01_rest_kitchen_orders SET status = @status WHERE id = @id::uuid",
        params: {'status': newStatus, 'id': orderId},
      );

      await loadOrders();
    } catch (e) {
      debugPrint('Kitchen updateStatus error: $e');
    }
  }

  Future<void> moveToPreparing(String orderId) async {
    await updateOrderStatus(orderId, 'preparing');
  }

  Future<void> moveToReady(String orderId) async {
    await updateOrderStatus(orderId, 'ready');
  }

  Future<void> markAsServed(String orderId) async {
    await updateOrderStatus(orderId, 'served');
  }

  @override
  void dispose() {
    super.dispose();
  }
}

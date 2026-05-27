import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../viewmodel/kitchen_viewmodel.dart';
import '../../../../shared/providers/app_providers.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  late KitchenViewModel _kitchenViewModel;

  @override
  void initState() {
    super.initState();
    _kitchenViewModel = ref.read(kitchenProvider.notifier);
    _kitchenViewModel.loadOrders();
    _kitchenViewModel.initializeSignalR();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Mutfak',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppConstants.exfinRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _kitchenViewModel.loadOrders();
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final kitchenVM = ref.watch(kitchenProvider);
          final pendingOrders = kitchenVM.pendingOrders;
          final preparingOrders = kitchenVM.preparingOrders;
          final readyOrders = kitchenVM.readyOrders;

          return Row(
            children: [
              // Sol panel - Durum kartları
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Sipariş Durumları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          // Bekleyen Siparişler
                          Expanded(
                            child: _buildStatusCard(
                              'Bekleyen',
                              pendingOrders.length,
                              Colors.orange,
                              Icons.schedule,
                              () => _showOrdersList(
                                  context, pendingOrders, 'Bekleyen'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Hazırlanan Siparişler
                          Expanded(
                            child: _buildStatusCard(
                              'Hazırlanan',
                              preparingOrders.length,
                              Colors.blue,
                              Icons.restaurant,
                              () => _showOrdersList(
                                  context, preparingOrders, 'Hazırlanan'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Hazır Siparişler
                          Expanded(
                            child: _buildStatusCard(
                              'Hazır',
                              readyOrders.length,
                              Colors.green,
                              Icons.check_circle,
                              () => _showOrdersList(
                                  context, readyOrders, 'Hazır'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Sağ panel - Detaylı sipariş listesi
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sipariş Detayları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildOrdersList(pendingOrders, 'Bekleyen'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
      String title, int count, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColorPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<dynamic> orders, String status) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '$status sipariş bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, status);
      },
    );
  }

  Widget _buildOrderCard(dynamic order, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sipariş #${order['id'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColorPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Masa: ${order['tableNumber'] ?? 'N/A'}',
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textColorSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (order['items'] != null) ...[
            ...(order['items'] as List<dynamic>).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['quantity'] ?? 1}x ${item['product']?['name'] ?? 'Ürün'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${item['product']?['price'] ?? 0} ₺',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam: ${order['total'] ?? 0} ₺',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColorPrimary,
                ),
              ),
              Row(
                children: [
                  if (status == 'Bekleyen')
                    ElevatedButton(
                      onPressed: () => _moveToPreparing(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Hazırlanıyor'),
                    ),
                  if (status == 'Hazırlanan')
                    ElevatedButton(
                      onPressed: () => _moveToReady(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Hazır'),
                    ),
                  if (status == 'Hazır')
                    ElevatedButton(
                      onPressed: () => _markAsServed(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Servis Edildi'),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Bekleyen':
        return Colors.orange;
      case 'Hazırlanan':
        return Colors.blue;
      case 'Hazır':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showOrdersList(
      BuildContext context, List<dynamic> orders, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$status Siparişler'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _buildOrdersList(orders, status),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _moveToPreparing(String orderId) async {
    await _kitchenViewModel.moveToPreparing(orderId);
  }

  void _moveToReady(String orderId) async {
    await _kitchenViewModel.moveToReady(orderId);
  }

  void _markAsServed(String orderId) async {
    await _kitchenViewModel.markAsServed(orderId);
  }
}

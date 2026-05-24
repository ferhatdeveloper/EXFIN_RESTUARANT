import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/postgres_service.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final String? initialTableName;

  const OrdersScreen({Key? key, this.initialTableName}) : super(key: key);

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final PostgresService _postgresService = PostgresService();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String selectedStatus = 'all';
  String selectedPaymentStatus = 'all';

  final List<String> statusOptions = [
    'all',
    'active',
    'completed',
    'cancelled'
  ];
  final List<String> paymentStatusOptions = [
    'all',
    'pending',
    'paid',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ordersData = await _postgresService.getOrders(
        status: selectedStatus == 'all' ? null : selectedStatus,
        paymentStatus:
            selectedPaymentStatus == 'all' ? null : selectedPaymentStatus,
      );

      setState(() {
        orders = ordersData;
        isLoading = false;
      });
    } catch (e) {
      print('Siparişler yüklenemedi: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'paid':
        return 'Ödendi';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showOrderDetails(Map<String, dynamic> order) async {
    final orderDetails = await _postgresService.getOrderById(order['id']);
    if (orderDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş detayları yüklenemedi')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sipariş #${order['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Masa: ${order['tableName'] ?? 'Bilinmiyor'}'),
              Text('Müşteri: ${order['customerName'] ?? 'Belirtilmemiş'}'),
              Text('Telefon: ${order['customerPhone'] ?? 'Belirtilmemiş'}'),
              Text('Durum: ${_getStatusText(order['orderStatus'])}'),
              Text('Ödeme: ${_getPaymentStatusText(order['paymentStatus'])}'),
              Text(
                  'Toplam: ₺${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
              Text(
                  'Final: ₺${order['finalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
              if (order['notes']?.isNotEmpty == true)
                Text('Notlar: ${order['notes']}'),
              const SizedBox(height: 16),
              const Text('Sipariş Kalemleri:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(orderDetails['items'] as List<Map<String, dynamic>>).map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:
                            Text('${item['productName']} x${item['quantity']}'),
                      ),
                      Text(
                          '₺${item['totalPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          if (order['orderStatus'] == 'active')
            ElevatedButton(
              onPressed: () async {
                final success = await _postgresService.updateOrderStatus(
                    order['id'], 'completed');
                if (success) {
                  Navigator.of(context).pop();
                  _loadOrders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sipariş tamamlandı')),
                  );
                }
              },
              child: const Text('Tamamla'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişler'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtreler
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Sipariş Durumu',
                      border: OutlineInputBorder(),
                    ),
                    items: statusOptions
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusText(status)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                      _loadOrders();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPaymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme Durumu',
                      border: OutlineInputBorder(),
                    ),
                    items: paymentStatusOptions
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(_getPaymentStatusText(status)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentStatus = value!;
                      });
                      _loadOrders();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Sipariş listesi
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(
                        child: Text('Sipariş bulunamadı'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getStatusColor(order['orderStatus']),
                                child: Text(
                                  '#${order['id']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                  'Masa ${order['tableName'] ?? 'Bilinmiyor'}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Müşteri: ${order['customerName'] ?? 'Belirtilmemiş'}'),
                                  Text(
                                      '₺${order['finalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                              order['orderStatus']),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(order['orderStatus']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getPaymentStatusColor(
                                              order['paymentStatus']),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getPaymentStatusText(
                                              order['paymentStatus']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info),
                                onPressed: () => _showOrderDetails(order),
                              ),
                              onTap: () => _showOrderDetails(order),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

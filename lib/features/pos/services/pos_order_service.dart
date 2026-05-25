import 'package:flutter/material.dart';
import '../../../services/postgres_service.dart';

class PosOrderService {
  static final PosOrderService _instance = PosOrderService._();
  factory PosOrderService() => _instance;
  PosOrderService._();

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  Future<Map<String, dynamic>> createRestaurantOrder({
    required String tableId,
    required String tableNumber,
    required String waiter,
    required List<Map<String, dynamic>> items,
  }) async {
    final pg = PostgresService();
    if (!pg.isConnected) await pg.initialize();

    final totalAmount = items.fold<double>(0, (s, i) => s + _toDouble(i['total']) - _toDouble(i['discount']));
    final orderNo = 'RES-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';

    final orderResult = await pg.query(
      """INSERT INTO rest.rex_001_01_rest_orders
         (order_no, table_id, floor_id, waiter, status, total_amount, discount_amount, opened_at, created_at, updated_at)
         VALUES (@orderNo, @tableId::uuid, (SELECT floor_id FROM rest.rex_001_rest_tables WHERE id = @tableId::uuid),
                 @waiter, 'open', @total, 0, NOW(), NOW(), NOW())
         RETURNING id, order_no""",
      params: {'orderNo': orderNo, 'tableId': tableId, 'waiter': waiter, 'total': totalAmount},
    );

    if (orderResult.isEmpty) return {'error': 'Sipariş oluşturulamadı'};

    final orderId = orderResult.first['id']?.toString();

    for (final item in items) {
      await pg.query(
        """INSERT INTO rest.rex_001_01_rest_order_items
           (order_id, product_id, product_name, quantity, unit_price, discount_pct, subtotal, status, note, created_at)
           VALUES (@orderId::uuid, @productId::uuid, @name, @qty, @price, 0, @subtotal, 'pending', @note, NOW())""",
        params: {
          'orderId': orderId,
          'productId': item['productId']?.toString(),
          'name': item['name'],
          'qty': item['qty'] ?? 1,
          'price': _toDouble(item['price']),
          'subtotal': _toDouble(item['total']),
          'note': item['note'] ?? '',
        },
      );
    }

    await pg.query(
      "UPDATE rest.rex_001_rest_tables SET status = 'occupied', total = @total, waiter = @waiter, staff_id = NULL, updated_at = NOW() WHERE id = @tableId::uuid",
      params: {'tableId': tableId, 'total': totalAmount, 'waiter': waiter},
    );

    return {'id': orderId, 'orderNo': orderNo, 'total': totalAmount};
  }

  Future<bool> sendToKitchen({
    required String orderId,
    required String tableNumber,
    required String waiter,
    required List<Map<String, dynamic>> items,
  }) async {
    final pg = PostgresService();
    if (!pg.isConnected) await pg.initialize();

    final kitchenResult = await pg.query(
      """INSERT INTO rest.rex_001_01_rest_kitchen_orders
         (order_id, table_number, waiter, status, sent_at)
         VALUES (@orderId::uuid, @tableNo, @waiter, 'new', NOW())
         RETURNING id""",
      params: {'orderId': orderId, 'tableNo': tableNumber, 'waiter': waiter},
    );

    if (kitchenResult.isEmpty) return false;
    final kitchenOrderId = kitchenResult.first['id']?.toString();

    for (final item in items) {
      await pg.query(
        """INSERT INTO rest.rex_001_01_rest_kitchen_items
           (kitchen_order_id, order_item_id, product_name, quantity, status, preparation_time, start_at, estimated_ready_at)
           VALUES (@koId::uuid, NULL, @name, @qty, 'new', 5, NOW(), NOW() + INTERVAL '5 minutes')""",
        params: {'koId': kitchenOrderId, 'name': item['name'], 'qty': item['qty'] ?? 1},
      );
    }

    await pg.query(
      "UPDATE rest.rex_001_01_rest_order_items SET status = 'cooking', sent_to_kitchen_at = NOW() WHERE order_id = @orderId::uuid AND status = 'pending'",
      params: {'orderId': orderId},
    );

    return true;
  }

  Future<Map<String, dynamic>> completePayment({
    required String orderId,
    required String tableId,
    required String paymentMethod,
    required double totalAmount,
    required double discount,
    required double paidAmount,
    required String cashier,
    required List<Map<String, dynamic>> items,
  }) async {
    final pg = PostgresService();
    if (!pg.isConnected) await pg.initialize();

    final netAmount = totalAmount - discount;
    final ficheNo = 'REST-1-${DateTime.now().millisecondsSinceEpoch}';

    await pg.query(
      """UPDATE rest.rex_001_01_rest_orders
         SET status = 'closed', payment_method = @method, total_amount = @total,
             discount_amount = @discount, billed_at = NOW(), closed_at = NOW(), updated_at = NOW()
         WHERE id = @orderId::uuid""",
      params: {'orderId': orderId, 'method': paymentMethod, 'total': netAmount, 'discount': discount},
    );

    await pg.query(
      """INSERT INTO rex_001_01_sales
         (firm_nr, period_nr, fiche_no, document_no, trcode, fiche_type, date, customer_name, total_net, total_vat, net_amount, total_cost, gross_profit, profit_margin, currency, currency_rate, status, payment_method, cashier, is_cancelled, notes, created_at, updated_at)
         VALUES ('001', '01', @ficheNo, @ficheNo, 7, 'sales_invoice', NOW(), 'Peşin Müşteri', @net, 0, @net, 0, @net, 100, 'IQD', 1, 'approved', @method, @cashier, false, @notes, NOW(), NOW())""",
      params: {'ficheNo': ficheNo, 'net': netAmount, 'method': paymentMethod, 'cashier': cashier, 'notes': 'RestoranPOS|rest_order_id:$orderId'},
    );

    for (final item in items) {
      await pg.query(
        """INSERT INTO rex_001_01_sale_items
           (invoice_id, firm_nr, period_nr, item_code, item_name, quantity, unit_price, net_amount, unit, unit_multiplier, base_quantity, currency)
           VALUES ((SELECT id FROM rex_001_01_sales WHERE fiche_no = @ficheNo), '001', '01', @code, @name, @qty, @price, @net, 'Adet', 1, @qty, 'IQD')""",
        params: {
          'ficheNo': ficheNo,
          'code': item['productId']?.toString() ?? item['code']?.toString() ?? '',
          'name': item['name'],
          'qty': item['qty'] ?? 1,
          'price': _toDouble(item['price']),
          'net': _toDouble(item['total']),
        },
      );
    }

    await pg.query(
      """INSERT INTO rex_001_01_cash_lines
         (firm_nr, period_nr, register_id, fiche_no, date, amount, sign, definition, transaction_type, currency_code, exchange_rate, created_at)
         VALUES ('001', '01', '00000000-0000-0000-0000-000000000001', @ficheNo, NOW(), @amount, 1, @desc, 'KASA_GIRIS', 'IQD', 1, NOW())""",
      params: {'ficheNo': ficheNo, 'amount': netAmount, 'desc': 'Restoran Satışı - $ficheNo'},
    );

    await pg.query(
      "UPDATE rex_001_cash_registers SET balance = balance + @amount WHERE id = '00000000-0000-0000-0000-000000000001'::uuid",
      params: {'amount': netAmount},
    );

    await pg.query(
      "UPDATE rest.rex_001_rest_tables SET status = 'empty', total = 0, waiter = NULL, staff_id = NULL, updated_at = NOW() WHERE id = @tableId::uuid",
      params: {'tableId': tableId},
    );

    for (final item in items) {
      if (item['productId'] != null) {
        await pg.query(
          "UPDATE rex_001_products SET stock = stock - @qty WHERE id = @pid::uuid AND stock > 0",
          params: {'pid': item['productId'].toString(), 'qty': item['qty'] ?? 1},
        );
      }
    }

    return {'ficheNo': ficheNo, 'netAmount': netAmount, 'status': 'completed'};
  }

  Future<bool> updateTableStatus(String tableId, String status) async {
    final pg = PostgresService();
    if (!pg.isConnected) await pg.initialize();
    await pg.query(
      "UPDATE rest.rex_001_rest_tables SET status = @status, updated_at = NOW() WHERE id = @id::uuid",
      params: {'id': tableId, 'status': status},
    );
    return true;
  }
}

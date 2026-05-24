import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:logger/logger.dart';
import 'database_service.dart';

class PostgresService {
  static final PostgresService _instance = PostgresService._internal();
  factory PostgresService() => _instance;
  PostgresService._internal();

  PostgreSQLConnection? _connection;
  final Logger _logger = Logger();
  final DatabaseService _dbService = DatabaseService();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> initialize() async {
    try {
      // SQLite'dan PostgreSQL ayarlarını al
      final settings = await _dbService.getPostgresSettings();
      if (settings == null) {
        _logger.e('PostgreSQL ayarları bulunamadı');
        return false;
      }

      _logger.i(
          'PostgreSQL ayarları alındı: ${settings['host']}:${settings['port']}');

      // Gerçek PostgreSQL bağlantısı
      _connection = PostgreSQLConnection(
        settings['host'],
        settings['port'],
        settings['database'],
        username: settings['username'],
        password: settings['password'],
      );

      await _connection!.open();
      _isConnected = true;
      _logger.i('PostgreSQL bağlantısı başarılı');
      return true;
    } catch (e) {
      _logger.e('PostgreSQL bağlantı hatası: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
    _isConnected = false;
    _logger.i('PostgreSQL bağlantısı kapatıldı');
  }

  Future<bool> testConnection() async {
    try {
      if (!_isConnected) {
        await initialize();
      }
      return _isConnected;
    } catch (e) {
      _logger.e('PostgreSQL bağlantı testi başarısız: $e');
      return false;
    }
  }

  // =====================================================
  // FATURA KODU YÖNETİMİ
  // =====================================================

  /// {@template generateFaturaKodu}
  /// Benzersiz fatura kodu oluşturur
  ///
  /// Parametreler:
  /// - [tableId]: Masa ID'si
  ///
  /// Dönüş değeri:
  /// - [String]: Oluşturulan fatura kodu
  ///
  /// Fırlatılan hatalar:
  /// - [Exception]: Veritabanı hatası durumunda
  /// {@endtemplate}
  Future<String> generateFaturaKodu(int tableId) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT generate_fatura_kodu(\$1)
      ''', substitutionValues: {'\$1': tableId});

      if (results.isNotEmpty) {
        return results.first[0] as String;
      }

      throw Exception('Fatura kodu oluşturulamadı');
    } catch (e) {
      _logger.e('Fatura kodu oluşturma hatası: $e');
      rethrow;
    }
  }

  // =====================================================
  // KULLANICI YÖNETİMİ
  // =====================================================

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, username, password, role, is_active, email, first_name, last_name, phone, created_at, updated_at
        FROM users
        WHERE is_active = true
        ORDER BY username
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'username': row[1],
                'password': row[2],
                'role': row[3],
                'isActive': row[4],
                'email': row[5],
                'firstName': row[6],
                'lastName': row[7],
                'phone': row[8],
                'createdAt': row[9]?.toString(),
                'updatedAt': row[10]?.toString(),
              })
          .toList();
    } catch (e) {
      _logger.e('Kullanıcılar getirilemedi: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> authenticateUser(
      String username, String password) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, username, password, role, is_active, email, first_name, last_name
        FROM users
        WHERE username = @username AND password = @password AND is_active = true
      ''', substitutionValues: {
        'username': username,
        'password': password,
      });

      if (results.isNotEmpty) {
        final user = results.first;
        return {
          'id': user[0],
          'username': user[1],
          'password': user[2],
          'role': user[3],
          'isActive': user[4],
          'email': user[5],
          'firstName': user[6],
          'lastName': user[7],
        };
      }
      return null;
    } catch (e) {
      _logger.e('Kullanıcı doğrulama hatası: $e');
      return null;
    }
  }

  // =====================================================
  // BÖLGE VE MASA YÖNETİMİ
  // =====================================================

  Future<List<Map<String, dynamic>>> getTables() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT t.id, t.name, t.capacity, t.status, t.location, t.is_active, 
               t.created_at, t.updated_at, r.name as region_name, r.id as region_id
        FROM tables t
        LEFT JOIN regions r ON t.region_id = r.id
        WHERE t.is_active = true
        ORDER BY t.name
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'capacity': row[2],
                'status': row[3],
                'location': row[4],
                'isActive': row[5],
                'createdAt': row[6]?.toString(),
                'updatedAt': row[7]?.toString(),
                'regionName': row[8],
                'regionId': row[9],
              })
          .toList();
    } catch (e) {
      _logger.e('Masalar getirilemedi: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRegions() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, name, description, is_active, created_at, updated_at
        FROM regions
        WHERE is_active = true
        ORDER BY name
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'description': row[2],
                'isActive': row[3],
                'createdAt': row[4]?.toString(),
                'updatedAt': row[5]?.toString(),
              })
          .toList();
    } catch (e) {
      _logger.e('Bölgeler getirilemedi: $e');
      return [];
    }
  }

  Future<bool> updateTableStatus(int tableId, String status) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      await _connection!.execute('''
        UPDATE tables 
        SET status = @status, updated_at = NOW()
        WHERE id = @tableId
      ''', substitutionValues: {
        'status': status,
        'tableId': tableId,
      });

      _logger.i('Masa durumu güncellendi: $tableId -> $status');
      return true;
    } catch (e) {
      _logger.e('Masa durumu güncellenemedi: $e');
      return false;
    }
  }

  Future<bool> addTable(Map<String, dynamic> tableData) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      await _connection!.execute('''
        INSERT INTO tables (name, capacity, status, location, region_id, is_active, created_at)
        VALUES (@name, @capacity, @status, @location, @regionId, true, NOW())
      ''', substitutionValues: {
        'name': tableData['name'],
        'capacity': tableData['capacity'],
        'status': tableData['status'],
        'location': tableData['location'],
        'regionId': tableData['regionId'],
      });

      _logger.i('Masa eklendi: ${tableData['name']}');
      return true;
    } catch (e) {
      _logger.e('Masa eklenemedi: $e');
      return false;
    }
  }

  Future<bool> updateTable(int tableId, Map<String, dynamic> tableData) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      await _connection!.execute('''
        UPDATE tables 
        SET name = @name, capacity = @capacity, status = @status, 
            location = @location, region_id = @regionId, updated_at = NOW()
        WHERE id = @tableId
      ''', substitutionValues: {
        'name': tableData['name'],
        'capacity': tableData['capacity'],
        'status': tableData['status'],
        'location': tableData['location'],
        'regionId': tableData['regionId'],
        'tableId': tableId,
      });

      _logger.i('Masa güncellendi: $tableId');
      return true;
    } catch (e) {
      _logger.e('Masa güncellenemedi: $e');
      return false;
    }
  }

  Future<bool> deleteTable(int tableId) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      await _connection!.execute('''
        UPDATE tables 
        SET is_active = false, updated_at = NOW()
        WHERE id = @tableId
      ''', substitutionValues: {
        'tableId': tableId,
      });

      _logger.i('Masa silindi: $tableId');
      return true;
    } catch (e) {
      _logger.e('Masa silinemedi: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTablesByRegion(int regionId) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, name, capacity, status, location, is_active, 
               created_at, updated_at
        FROM tables
        WHERE region_id = @regionId AND is_active = true
        ORDER BY name
      ''', substitutionValues: {
        'regionId': regionId,
      });

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'capacity': row[2],
                'status': row[3],
                'location': row[4],
                'isActive': row[5],
                'createdAt': row[6]?.toString(),
                'updatedAt': row[7]?.toString(),
              })
          .toList();
    } catch (e) {
      _logger.e('Bölge masaları getirilemedi: $e');
      return [];
    }
  }

  // =====================================================
  // MENÜ VE ÜRÜN YÖNETİMİ
  // =====================================================

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, name, description, is_active, created_at, updated_at
        FROM categories
        WHERE is_active = true
        ORDER BY name
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'description': row[2],
                'isActive': row[3],
                'createdAt': row[4]?.toString(),
                'updatedAt': row[5]?.toString(),
              })
          .toList();
    } catch (e) {
      _logger.e('Kategoriler getirilemedi: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT p.id, p.name, p.description, p.price, p.is_active, p.image_url, 
               p.preparation_time, p.created_at, p.updated_at, c.name as category_name, c.id as category_id
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.is_active = true
        ORDER BY p.name
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'description': row[2],
                'price': row[3],
                'isActive': row[4],
                'imageUrl': row[5],
                'preparationTime': row[6],
                'createdAt': row[7]?.toString(),
                'updatedAt': row[8]?.toString(),
                'categoryName': row[9],
                'categoryId': row[10],
              })
          .toList();
    } catch (e) {
      _logger.e('Ürünler getirilemedi: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductsByCategory(
      int categoryId) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, name, description, price, is_active, image_url, 
               preparation_time, created_at, updated_at
        FROM products
        WHERE category_id = @categoryId AND is_active = true
        ORDER BY name
      ''', substitutionValues: {
        'categoryId': categoryId,
      });

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'description': row[2],
                'price': row[3],
                'isActive': row[4],
                'imageUrl': row[5],
                'preparationTime': row[6],
                'createdAt': row[7]?.toString(),
                'updatedAt': row[8]?.toString(),
              })
          .toList();
    } catch (e) {
      _logger.e('Kategori ürünleri getirilemedi: $e');
      return [];
    }
  }

  // =====================================================
  // SİPARİŞ YÖNETİMİ
  // =====================================================

  Future<Map<String, dynamic>> createOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double finalAmount,
    double discount = 0.0,
    String? customerName,
    String? customerPhone,
    String? notes,
    String paymentStatus = 'pending',
    String orderStatus = 'active',
  }) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      // Fatura kodu oluştur
      final faturaKodu = await generateFaturaKodu(tableId);

      // Sipariş oluştur
      final orderResult = await _connection!.query('''
        INSERT INTO orders (
          fatura_kodu, table_id, customer_name, customer_phone, notes, 
          total_amount, discount_amount, final_amount, 
          payment_status, status, created_at, updated_at
        ) VALUES (
          @faturaKodu, @tableId, @customerName, @customerPhone, @notes,
          @totalAmount, @discount, @finalAmount,
          @paymentStatus, @orderStatus, NOW(), NOW()
        ) RETURNING id, fatura_kodu
      ''', substitutionValues: {
        'faturaKodu': faturaKodu,
        'tableId': tableId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'notes': notes,
        'totalAmount': totalAmount,
        'discount': discount,
        'finalAmount': finalAmount,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
      });

      final orderId = orderResult.first[0] as int;
      final returnedFaturaKodu = orderResult.first[1] as String;

      // Sipariş kalemlerini ekle
      for (final item in items) {
        await _connection!.query('''
          INSERT INTO order_items (
            order_id, product_id, product_name, quantity, 
            unit_price, total_price, notes, created_at
          ) VALUES (
            @orderId, @productId, @productName, @quantity,
            @unitPrice, @totalPrice, @notes, NOW()
          )
        ''', substitutionValues: {
          'orderId': orderId,
          'productId': item['productId'],
          'productName': item['productName'],
          'quantity': item['quantity'],
          'unitPrice': item['unitPrice'],
          'totalPrice': item['totalPrice'],
          'notes': item['notes'],
        });
      }

      // Masayı dolu olarak işaretle
      await _connection!.query('''
        UPDATE tables SET status = 'occupied', updated_at = NOW()
        WHERE id = @tableId
      ''', substitutionValues: {
        'tableId': tableId,
      });

      return {
        'id': orderId,
        'faturaKodu': returnedFaturaKodu,
        'tableId': tableId,
        'totalAmount': totalAmount,
        'finalAmount': finalAmount,
        'status': orderStatus,
        'message': 'Sipariş başarıyla oluşturuldu',
      };
    } catch (e) {
      _logger.e('Sipariş oluşturma hatası: $e');
      return {
        'error': 'Sipariş oluşturulamadı: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getOrders({
    int? tableId,
    String? status,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      String query = '''
        SELECT 
          o.id, o.fatura_kodu, o.table_id, o.customer_name, o.customer_phone, o.notes,
          o.total_amount, o.discount_amount, o.final_amount,
          o.payment_status, o.status, o.created_at, o.updated_at,
          t.name as table_name, t.capacity as table_capacity
        FROM orders o
        LEFT JOIN tables t ON o.table_id = t.id
        WHERE 1=1
      ''';

      final substitutionValues = <String, dynamic>{};

      if (tableId != null) {
        query += ' AND o.table_id = @tableId';
        substitutionValues['tableId'] = tableId;
      }

      if (status != null) {
        query += ' AND o.status = @status';
        substitutionValues['status'] = status;
      }

      if (paymentStatus != null) {
        query += ' AND o.payment_status = @paymentStatus';
        substitutionValues['paymentStatus'] = paymentStatus;
      }

      if (startDate != null) {
        query += ' AND DATE(o.created_at) >= @startDate';
        substitutionValues['startDate'] =
            startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        query += ' AND DATE(o.created_at) <= @endDate';
        substitutionValues['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      query += ' ORDER BY o.created_at DESC';

      final results = await _connection!
          .query(query, substitutionValues: substitutionValues);

      return results
          .map((row) => {
                'id': row[0],
                'faturaKodu': row[1],
                'tableId': row[2],
                'customerName': row[3],
                'customerPhone': row[4],
                'notes': row[5],
                'totalAmount': row[6],
                'discountAmount': row[7],
                'finalAmount': row[8],
                'paymentStatus': row[9],
                'orderStatus': row[10],
                'createdAt': row[11]?.toString(),
                'updatedAt': row[12]?.toString(),
                'tableName': row[13],
                'tableCapacity': row[14],
              })
          .toList();
    } catch (e) {
      _logger.e('Siparişler getirilemedi: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final orderResult = await _connection!.query('''
        SELECT 
          o.id, o.fatura_kodu, o.table_id, o.customer_name, o.customer_phone, o.notes,
          o.total_amount, o.discount_amount, o.final_amount,
          o.payment_status, o.status, o.created_at, o.updated_at,
          t.name as table_name, t.capacity as table_capacity
        FROM orders o
        LEFT JOIN tables t ON o.table_id = t.id
        WHERE o.id = @orderId
      ''', substitutionValues: {
        'orderId': orderId,
      });

      if (orderResult.isEmpty) {
        return null;
      }

      final order = orderResult.first;

      // Sipariş kalemlerini getir
      final itemsResult = await _connection!.query('''
        SELECT 
          id, product_id, product_name, quantity, 
          unit_price, total_price, notes, created_at
        FROM order_items
        WHERE order_id = @orderId
        ORDER BY created_at
      ''', substitutionValues: {
        'orderId': orderId,
      });

      final items = itemsResult
          .map((row) => {
                'id': row[0],
                'productId': row[1],
                'productName': row[2],
                'quantity': row[3],
                'unitPrice': row[4],
                'totalPrice': row[5],
                'notes': row[6],
                'createdAt': row[7]?.toString(),
              })
          .toList();

      return {
        'id': order[0],
        'tableId': order[1],
        'customerName': order[2],
        'customerPhone': order[3],
        'notes': order[4],
        'totalAmount': order[5],
        'discountAmount': order[6],
        'finalAmount': order[7],
        'paymentStatus': order[8],
        'orderStatus': order[9],
        'createdAt': order[10]?.toString(),
        'updatedAt': order[11]?.toString(),
        'tableName': order[12],
        'tableCapacity': order[13],
        'items': items,
      };
    } catch (e) {
      _logger.e('Sipariş getirilemedi: $e');
      return null;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      await _connection!.query('''
        UPDATE orders 
        SET order_status = @status, updated_at = NOW()
        WHERE id = @orderId
      ''', substitutionValues: {
        'orderId': orderId,
        'status': status,
      });

      return true;
    } catch (e) {
      _logger.e('Sipariş durumu güncellenemedi: $e');
      return false;
    }
  }

  Future<bool> updatePaymentStatus(int orderId, String paymentStatus) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      await _connection!.query('''
        UPDATE orders 
        SET payment_status = @paymentStatus, updated_at = NOW()
        WHERE id = @orderId
      ''', substitutionValues: {
        'orderId': orderId,
        'paymentStatus': paymentStatus,
      });

      return true;
    } catch (e) {
      _logger.e('Ödeme durumu güncellenemedi: $e');
      return false;
    }
  }

  Future<bool> deleteOrder(int orderId) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      // Önce sipariş kalemlerini sil
      await _connection!.query('''
        DELETE FROM order_items WHERE order_id = @orderId
      ''', substitutionValues: {
        'orderId': orderId,
      });

      // Sonra siparişi sil
      await _connection!.query('''
        DELETE FROM orders WHERE id = @orderId
      ''', substitutionValues: {
        'orderId': orderId,
      });

      return true;
    } catch (e) {
      _logger.e('Sipariş silinemedi: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByTable(int tableId) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT 
          o.id, o.table_id, o.customer_name, o.customer_phone, o.notes,
          o.total_amount, o.discount_amount, o.final_amount,
          o.payment_status, o.order_status, o.created_at, o.updated_at,
          t.name as table_name, t.capacity as table_capacity
        FROM orders o
        LEFT JOIN tables t ON o.table_id = t.id
        WHERE o.table_id = @tableId
        ORDER BY o.created_at DESC
      ''', substitutionValues: {
        'tableId': tableId,
      });

      return results
          .map((row) => {
                'id': row[0],
                'tableId': row[1],
                'customerName': row[2],
                'customerPhone': row[3],
                'notes': row[4],
                'totalAmount': row[5],
                'discountAmount': row[6],
                'finalAmount': row[7],
                'paymentStatus': row[8],
                'orderStatus': row[9],
                'createdAt': row[10]?.toString(),
                'updatedAt': row[11]?.toString(),
                'tableName': row[12],
                'tableCapacity': row[13],
              })
          .toList();
    } catch (e) {
      _logger.e('Masa siparişleri getirilemedi: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      // Bugünkü sipariş sayısı
      final todayOrdersResult = await _connection!.query('''
        SELECT COUNT(*) FROM orders 
        WHERE DATE(created_at) = CURRENT_DATE
      ''');
      final todayOrders = todayOrdersResult.first[0] as int;

      // Bugünkü toplam gelir
      final todayRevenueResult = await _connection!.query('''
        SELECT COALESCE(SUM(final_amount), 0) FROM orders 
        WHERE DATE(created_at) = CURRENT_DATE AND payment_status = 'paid'
      ''');
      final todayRevenue = todayRevenueResult.first[0] as double;

      // Bekleyen sipariş sayısı
      final pendingOrdersResult = await _connection!.query('''
        SELECT COUNT(*) FROM orders 
        WHERE order_status = 'active'
      ''');
      final pendingOrders = pendingOrdersResult.first[0] as int;

      // Ödenmemiş sipariş sayısı
      final unpaidOrdersResult = await _connection!.query('''
        SELECT COUNT(*) FROM orders 
        WHERE payment_status = 'pending'
      ''');
      final unpaidOrders = unpaidOrdersResult.first[0] as int;

      // Ortalama sipariş tutarı
      final avgOrderAmountResult = await _connection!.query('''
        SELECT COALESCE(AVG(final_amount), 0) FROM orders 
        WHERE DATE(created_at) = CURRENT_DATE
      ''');
      final avgOrderAmount = avgOrderAmountResult.first[0] as double;

      return {
        'todayOrders': todayOrders,
        'todayRevenue': todayRevenue,
        'pendingOrders': pendingOrders,
        'unpaidOrders': unpaidOrders,
        'avgOrderAmount': avgOrderAmount,
      };
    } catch (e) {
      _logger.e('Sipariş istatistikleri getirilemedi: $e');
      return {
        'todayOrders': 0,
        'todayRevenue': 0.0,
        'pendingOrders': 0,
        'unpaidOrders': 0,
        'avgOrderAmount': 0.0,
      };
    }
  }

  // =====================================================
  // REZERVASYON YÖNETİMİ
  // =====================================================

  Future<List<Map<String, dynamic>>> getReservations() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT r.id, r.table_id, r.customer_name, r.customer_phone, r.customer_email,
               r.reservation_date, r.reservation_time, r.party_size, r.status, r.notes,
               r.created_at, r.updated_at, t.name as table_name
        FROM reservations r
        LEFT JOIN tables t ON r.table_id = t.id
        ORDER BY r.reservation_date DESC, r.reservation_time DESC
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'tableId': row[1],
                'customerName': row[2],
                'customerPhone': row[3],
                'customerEmail': row[4],
                'reservationDate': row[5]?.toString(),
                'reservationTime': row[6]?.toString(),
                'partySize': row[7],
                'status': row[8],
                'notes': row[9],
                'createdAt': row[10]?.toString(),
                'updatedAt': row[11]?.toString(),
                'tableName': row[12],
              })
          .toList();
    } catch (e) {
      _logger.e('Rezervasyonlar getirilemedi: $e');
      return [];
    }
  }

  // =====================================================
  // MÜŞTERİ YÖNETİMİ
  // =====================================================

  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, name, phone, email, address, birth_date, total_orders, 
               total_spent, loyalty_points, is_active, created_at, updated_at
        FROM customers
        WHERE is_active = true
        ORDER BY name
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'phone': row[2],
                'email': row[3],
                'address': row[4],
                'birthDate': row[5]?.toString(),
                'totalOrders': row[6],
                'totalSpent': row[7],
                'loyaltyPoints': row[8],
                'isActive': row[9],
                'createdAt': row[10]?.toString(),
                'updatedAt': row[11]?.toString(),
              })
          .toList();
    } catch (e) {
      _logger.e('Müşteriler getirilemedi: $e');
      return [];
    }
  }

  // =====================================================
  // STOK YÖNETİMİ
  // =====================================================

  Future<List<Map<String, dynamic>>> getIngredients() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final results = await _connection!.query('''
        SELECT id, name, description, unit, current_stock, min_stock, max_stock,
               unit_price, supplier, is_active, created_at, updated_at
        FROM ingredients
        WHERE is_active = true
        ORDER BY name
      ''');

      return results
          .map((row) => {
                'id': row[0],
                'name': row[1],
                'description': row[2],
                'unit': row[3],
                'currentStock': row[4],
                'minStock': row[5],
                'maxStock': row[6],
                'unitPrice': row[7],
                'supplier': row[8],
                'isActive': row[9],
                'createdAt': row[10]?.toString(),
                'updatedAt': row[11]?.toString(),
              })
          .toList();
    } catch (e) {
      _logger.e('Malzemeler getirilemedi: $e');
      return [];
    }
  }

  // =====================================================
  // İSTATİSTİKLER
  // =====================================================

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      // Toplam masa sayısı
      final totalTablesResult = await _connection!.query('''
        SELECT COUNT(*) FROM tables WHERE is_active = true
      ''');
      final totalTables = totalTablesResult.first[0] as int;

      // Müsait masa sayısı
      final availableTablesResult = await _connection!.query('''
        SELECT COUNT(*) FROM tables 
        WHERE is_active = true AND status = 'Available'
      ''');
      final availableTables = availableTablesResult.first[0] as int;

      // Dolu masa sayısı
      final occupiedTablesResult = await _connection!.query('''
        SELECT COUNT(*) FROM tables 
        WHERE is_active = true AND status = 'occupied'
      ''');
      final occupiedTables = occupiedTablesResult.first[0] as int;

      // Toplam bölge sayısı
      final totalRegionsResult = await _connection!.query('''
        SELECT COUNT(*) FROM regions WHERE is_active = true
      ''');
      final totalRegions = totalRegionsResult.first[0] as int;

      // Toplam ürün sayısı
      final totalProductsResult = await _connection!.query('''
        SELECT COUNT(*) FROM products WHERE is_active = true
      ''');
      final totalProducts = totalProductsResult.first[0] as int;

      // Toplam sipariş sayısı (bugün)
      final todayOrdersResult = await _connection!.query('''
        SELECT COUNT(*) FROM orders 
        WHERE DATE(created_at) = CURRENT_DATE
      ''');
      final todayOrders = todayOrdersResult.first[0] as int;

      // Bugünkü toplam gelir
      final todayRevenueResult = await _connection!.query('''
        SELECT COALESCE(SUM(final_amount), 0) FROM orders 
        WHERE DATE(created_at) = CURRENT_DATE AND payment_status = 'paid'
      ''');
      final todayRevenue = todayRevenueResult.first[0] as double;

      return {
        'totalTables': totalTables,
        'availableTables': availableTables,
        'occupiedTables': occupiedTables,
        'totalRegions': totalRegions,
        'totalProducts': totalProducts,
        'todayOrders': todayOrders,
        'todayRevenue': todayRevenue,
        'utilizationRate':
            totalTables > 0 ? (occupiedTables / totalTables * 100).round() : 0,
      };
    } catch (e) {
      _logger.e('İstatistikler getirilemedi: $e');
      return {
        'totalTables': 0,
        'availableTables': 0,
        'occupiedTables': 0,
        'totalRegions': 0,
        'totalProducts': 0,
        'todayOrders': 0,
        'todayRevenue': 0,
        'utilizationRate': 0,
      };
    }
  }
}

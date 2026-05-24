import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'database_service.dart';

class PostgresService {
  static final PostgresService _instance = PostgresService._internal();
  factory PostgresService() => _instance;
  PostgresService._internal();

  final Logger _logger = Logger();
  final DatabaseService _dbService = DatabaseService();

  bool _isConnected = false;
  String _postgrestUrl = '';
  String _postgrestSchema = 'public';
  String? _postgrestAnonKey;

  bool get isConnected => _isConnected;

  Future<bool> initialize() async {
    try {
      final settings = await _dbService.getPostgresSettings();
      if (settings == null) {
        _logger.e('PostgreSQL/PostgREST ayarları bulunamadı');
        return false;
      }

      final host = (settings['host'] ?? 'localhost').toString();
      final postgrestUrl = (settings['postgrestUrl'] ?? '').toString().trim();
      _postgrestUrl =
          postgrestUrl.isNotEmpty ? postgrestUrl : 'http://$host:3002';
      _postgrestSchema =
          (settings['postgrestSchema'] ?? 'public').toString().trim();
      _postgrestAnonKey = (settings['postgrestAnonKey'] ?? '').toString().trim();

      _postgrestUrl = _postgrestUrl.replaceAll(RegExp(r'/+$'), '');

      _logger.i(
        'PostgREST ayarları alındı: $_postgrestUrl (schema: $_postgrestSchema)',
      );

      final isHealthy = await _healthCheck();
      _isConnected = isHealthy;
      if (isHealthy) {
        _logger.i('PostgREST bağlantısı başarılı');
      } else {
        _logger.e('PostgREST bağlantısı başarısız');
      }
      return isHealthy;
    } catch (e) {
      _logger.e('PostgREST bağlantı hatası: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> close() async {
    _isConnected = false;
    _logger.i('PostgREST bağlantısı kapatıldı');
  }

  Future<bool> testConnection() async {
    try {
      if (!_isConnected) {
        await initialize();
      }
      return _isConnected;
    } catch (e) {
      _logger.e('PostgREST bağlantı testi başarısız: $e');
      return false;
    }
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$_postgrestUrl$normalizedPath',
    ).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Map<String, String> _buildHeaders({bool preferRepresentation = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Profile': _postgrestSchema,
      'Content-Profile': _postgrestSchema,
    };
    if ((_postgrestAnonKey ?? '').isNotEmpty) {
      headers['Authorization'] = 'Bearer $_postgrestAnonKey';
    }
    if (preferRepresentation) {
      headers['Prefer'] = 'return=representation';
    }
    return headers;
  }

  Future<bool> _healthCheck() async {
    try {
      final response = await http.get(
        _buildUri('/'),
        headers: _buildHeaders(),
      );
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await http.get(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET $path başarısız: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded;
    }
    return [decoded];
  }

  Future<List<dynamic>> _post(
    String path,
    dynamic body, {
    bool preferRepresentation = true,
  }) async {
    final response = await http.post(
      _buildUri(path),
      headers: _buildHeaders(preferRepresentation: preferRepresentation),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'POST $path başarısız: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded;
    }
    return [decoded];
  }

  Future<List<dynamic>> _patch(
    String path,
    dynamic body, {
    Map<String, dynamic>? queryParameters,
    bool preferRepresentation = true,
  }) async {
    final response = await http.patch(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(preferRepresentation: preferRepresentation),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'PATCH $path başarısız: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded;
    }
    return [decoded];
  }

  Future<void> _delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await http.delete(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'DELETE $path başarısız: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<dynamic> _rpc(String functionName, Map<String, dynamic> args) async {
    final response = await http.post(
      _buildUri('/rpc/$functionName'),
      headers: _buildHeaders(preferRepresentation: true),
      body: jsonEncode(args),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'RPC $functionName başarısız: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
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

      final result = await _rpc(
        'generate_fatura_kodu',
        {'p_table_id': tableId},
      );

      if (result is String && result.isNotEmpty) {
        return result;
      }
      if (result is List && result.isNotEmpty) {
        final first = result.first;
        if (first is String && first.isNotEmpty) {
          return first;
        }
        if (first is Map<String, dynamic>) {
          final value = first.values.isNotEmpty ? first.values.first : null;
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }

      return 'T$tableId-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      _logger.e('Fatura kodu oluşturma hatası: $e');
      return 'T$tableId-${DateTime.now().millisecondsSinceEpoch}';
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

      final rows = await _getList(
        '/users',
        queryParameters: {
          'select':
              'id,username,password,role,is_active,email,first_name,last_name,phone,created_at,updated_at',
          'is_active': 'eq.true',
          'order': 'username.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'id': row['id'],
                'username': row['username'],
                'password': row['password'],
                'role': row['role'],
                'isActive': row['is_active'] == true,
                'email': row['email'],
                'firstName': row['first_name'],
                'lastName': row['last_name'],
                'phone': row['phone'],
                'createdAt': row['created_at']?.toString(),
                'updatedAt': row['updated_at']?.toString(),
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

      final rows = await _getList(
        '/users',
        queryParameters: {
          'select':
              'id,username,password,role,is_active,email,first_name,last_name',
          'username': 'eq.$username',
          'password': 'eq.$password',
          'is_active': 'eq.true',
          'limit': 1,
        },
      );

      if (rows.isNotEmpty && rows.first is Map<String, dynamic>) {
        final user = rows.first as Map<String, dynamic>;
        return {
          'id': user['id'],
          'username': user['username'],
          'password': user['password'],
          'role': user['role'],
          'isActive': user['is_active'] == true,
          'email': user['email'],
          'firstName': user['first_name'],
          'lastName': user['last_name'],
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

      final rows = await _getList(
        '/tables',
        queryParameters: {
          'select':
              'id,name,capacity,status,location,is_active,created_at,updated_at,region_id,regions(id,name)',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final region = row['regions'];
            final regionData = region is Map<String, dynamic>
                ? region
                : (region is List && region.isNotEmpty && region.first is Map
                    ? region.first as Map<String, dynamic>
                    : <String, dynamic>{});
            return {
              'id': row['id'],
              'name': row['name'],
              'capacity': row['capacity'],
              'status': row['status'],
              'location': row['location'],
              'isActive': row['is_active'] == true,
              'createdAt': row['created_at']?.toString(),
              'updatedAt': row['updated_at']?.toString(),
              'regionName': regionData['name'],
              'regionId': row['region_id'] ?? regionData['id'],
            };
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

      final rows = await _getList(
        '/regions',
        queryParameters: {
          'select': 'id,name,description,is_active,created_at,updated_at',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'description': row['description'],
                'isActive': row['is_active'] == true,
                'createdAt': row['created_at']?.toString(),
                'updatedAt': row['updated_at']?.toString(),
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

      await _patch(
        '/tables',
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        queryParameters: {'id': 'eq.$tableId'},
      );

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

      await _post('/tables', {
        'name': tableData['name'],
        'capacity': tableData['capacity'] ?? 4,
        'status': tableData['status'] ?? 'Available',
        'location': tableData['location'],
        'region_id': tableData['regionId'],
        'is_active': true,
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

      await _patch(
        '/tables',
        {
          'name': tableData['name'],
          'capacity': tableData['capacity'],
          'status': tableData['status'],
          'location': tableData['location'],
          'region_id': tableData['regionId'],
          'updated_at': DateTime.now().toIso8601String(),
        },
        queryParameters: {'id': 'eq.$tableId'},
      );

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

      await _patch(
        '/tables',
        {
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        },
        queryParameters: {'id': 'eq.$tableId'},
      );

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

      final rows = await _getList(
        '/tables',
        queryParameters: {
          'select': 'id,name,capacity,status,location,is_active,created_at,updated_at',
          'region_id': 'eq.$regionId',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'capacity': row['capacity'],
                'status': row['status'],
                'location': row['location'],
                'isActive': row['is_active'] == true,
                'createdAt': row['created_at']?.toString(),
                'updatedAt': row['updated_at']?.toString(),
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

      final rows = await _getList(
        '/categories',
        queryParameters: {
          'select': 'id,name,description,is_active,created_at,updated_at',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'description': row['description'],
                'isActive': row['is_active'] == true,
                'createdAt': row['created_at']?.toString(),
                'updatedAt': row['updated_at']?.toString(),
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

      final rows = await _getList(
        '/products',
        queryParameters: {
          'select':
              'id,name,description,price,is_active,image_url,preparation_time,created_at,updated_at,category_id,categories(id,name)',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final category = row['categories'];
            final categoryData = category is Map<String, dynamic>
                ? category
                : (category is List && category.isNotEmpty && category.first is Map
                    ? category.first as Map<String, dynamic>
                    : <String, dynamic>{});
            return {
              'id': row['id'],
              'name': row['name'],
              'description': row['description'],
              'price': row['price'],
              'isActive': row['is_active'] == true,
              'imageUrl': row['image_url'],
              'preparationTime': row['preparation_time'],
              'createdAt': row['created_at']?.toString(),
              'updatedAt': row['updated_at']?.toString(),
              'categoryName': categoryData['name'],
              'categoryId': row['category_id'] ?? categoryData['id'],
            };
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

      final rows = await _getList(
        '/products',
        queryParameters: {
          'select':
              'id,name,description,price,is_active,image_url,preparation_time,created_at,updated_at',
          'category_id': 'eq.$categoryId',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'description': row['description'],
                'price': row['price'],
                'isActive': row['is_active'] == true,
                'imageUrl': row['image_url'],
                'preparationTime': row['preparation_time'],
                'createdAt': row['created_at']?.toString(),
                'updatedAt': row['updated_at']?.toString(),
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

      final orderRows = await _post('/orders', {
        'fatura_kodu': faturaKodu,
        'table_id': tableId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'notes': notes,
        'total_amount': totalAmount,
        'discount_amount': discount,
        'final_amount': finalAmount,
        'payment_status': paymentStatus,
        'status': orderStatus,
      });

      if (orderRows.isEmpty || orderRows.first is! Map<String, dynamic>) {
        throw Exception('Sipariş kaydı oluşturulamadı');
      }
      final orderData = orderRows.first as Map<String, dynamic>;
      final orderId = _asInt(orderData['id']);
      final returnedFaturaKodu =
          (orderData['fatura_kodu'] ?? faturaKodu).toString();

      // Sipariş kalemlerini ekle
      for (final item in items) {
        await _post('/order_items', {
          'order_id': orderId,
          'product_id': item['productId'],
          'quantity': item['quantity'] ?? 1,
          'unit_price': item['unitPrice'] ?? 0,
          'total_price': item['totalPrice'] ?? 0,
          'notes': item['notes'],
          'status': item['status'] ?? 'pending',
        }, preferRepresentation: false);
      }

      // Masayı dolu olarak işaretle
      await _patch(
        '/tables',
        {'status': 'occupied'},
        queryParameters: {'id': 'eq.$tableId'},
        preferRepresentation: false,
      );

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

      final queryParameters = <String, dynamic>{
        'select':
            'id,fatura_kodu,table_id,customer_name,customer_phone,notes,total_amount,discount_amount,final_amount,payment_status,status,created_at,updated_at,tables(name,capacity)',
        'order': 'created_at.desc',
      };

      if (tableId != null) {
        queryParameters['table_id'] = 'eq.$tableId';
      }
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = 'eq.$status';
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        queryParameters['payment_status'] = 'eq.$paymentStatus';
      }
      if (startDate != null && endDate != null) {
        queryParameters['and'] =
            '(created_at.gte.${startDate.toIso8601String()},created_at.lte.${endDate.toIso8601String()})';
      } else if (startDate != null) {
        queryParameters['created_at'] = 'gte.${startDate.toIso8601String()}';
      } else if (endDate != null) {
        queryParameters['created_at'] = 'lte.${endDate.toIso8601String()}';
      }

      final rows = await _getList('/orders', queryParameters: queryParameters);

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final table = row['tables'];
            final tableData = table is Map<String, dynamic>
                ? table
                : (table is List && table.isNotEmpty && table.first is Map
                    ? table.first as Map<String, dynamic>
                    : <String, dynamic>{});
            return {
              'id': row['id'],
              'faturaKodu': row['fatura_kodu'],
              'tableId': row['table_id'],
              'customerName': row['customer_name'],
              'customerPhone': row['customer_phone'],
              'notes': row['notes'],
              'totalAmount': _asDouble(row['total_amount']),
              'discountAmount': _asDouble(row['discount_amount']),
              'finalAmount': _asDouble(row['final_amount']),
              'paymentStatus': row['payment_status'],
              'orderStatus': row['status'],
              'createdAt': row['created_at']?.toString(),
              'updatedAt': row['updated_at']?.toString(),
              'tableName': tableData['name'],
              'tableCapacity': tableData['capacity'],
            };
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

      final rows = await _getList('/orders', queryParameters: {
        'select':
            'id,fatura_kodu,table_id,customer_name,customer_phone,notes,total_amount,discount_amount,final_amount,payment_status,status,created_at,updated_at,tables(name,capacity),order_items(*)',
        'id': 'eq.$orderId',
        'limit': 1,
      });

      if (rows.isEmpty || rows.first is! Map<String, dynamic>) {
        return null;
      }

      final order = rows.first as Map<String, dynamic>;
      final orderItems = order['order_items'] is List
          ? order['order_items'] as List
          : <dynamic>[];
      final table = order['tables'];
      final tableData = table is Map<String, dynamic>
          ? table
          : (table is List && table.isNotEmpty && table.first is Map
              ? table.first as Map<String, dynamic>
              : <String, dynamic>{});

      final items = orderItems.whereType<Map<String, dynamic>>().map((item) {
        return {
          'id': item['id'],
          'productId': item['product_id'],
          'productName': item['product_name'],
          'quantity': item['quantity'],
          'unitPrice': _asDouble(item['unit_price']),
          'totalPrice': _asDouble(item['total_price']),
          'notes': item['notes'],
          'createdAt': item['created_at']?.toString(),
        };
      }).toList();

      return {
        'id': order['id'],
        'faturaKodu': order['fatura_kodu'],
        'tableId': order['table_id'],
        'customerName': order['customer_name'],
        'customerPhone': order['customer_phone'],
        'notes': order['notes'],
        'totalAmount': _asDouble(order['total_amount']),
        'discountAmount': _asDouble(order['discount_amount']),
        'finalAmount': _asDouble(order['final_amount']),
        'paymentStatus': order['payment_status'],
        'orderStatus': order['status'],
        'createdAt': order['created_at']?.toString(),
        'updatedAt': order['updated_at']?.toString(),
        'tableName': tableData['name'],
        'tableCapacity': tableData['capacity'],
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

      await _patch(
        '/orders',
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        queryParameters: {'id': 'eq.$orderId'},
      );

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

      await _patch(
        '/orders',
        {
          'payment_status': paymentStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        queryParameters: {'id': 'eq.$orderId'},
      );

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

      await _delete('/order_items', queryParameters: {'order_id': 'eq.$orderId'});
      await _delete('/orders', queryParameters: {'id': 'eq.$orderId'});

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

      return getOrders(tableId: tableId);
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

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final orders = await getOrders(startDate: todayStart);
      final paidOrders =
          orders.where((order) => order['paymentStatus'] == 'paid').toList();

      final todayOrders = orders.length;
      final todayRevenue = paidOrders.fold<double>(
        0,
        (sum, order) => sum + _asDouble(order['finalAmount']),
      );
      final pendingOrders = orders
          .where((order) => order['orderStatus'] == 'active')
          .length;
      final unpaidOrders = orders
          .where((order) => order['paymentStatus'] == 'pending')
          .length;
      final avgOrderAmount = todayOrders > 0 ? (todayRevenue / todayOrders) : 0.0;

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

      final rows = await _getList(
        '/reservations',
        queryParameters: {
          'select':
              'id,table_id,customer_name,customer_phone,customer_email,reservation_date,reservation_time,party_size,status,notes,created_at,updated_at,tables(name)',
          'order': 'reservation_date.desc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final table = row['tables'];
            final tableData = table is Map<String, dynamic>
                ? table
                : (table is List && table.isNotEmpty && table.first is Map
                    ? table.first as Map<String, dynamic>
                    : <String, dynamic>{});
            return {
              'id': row['id'],
              'tableId': row['table_id'],
              'customerName': row['customer_name'],
              'customerPhone': row['customer_phone'],
              'customerEmail': row['customer_email'],
              'reservationDate': row['reservation_date']?.toString(),
              'reservationTime': row['reservation_time']?.toString(),
              'partySize': row['party_size'],
              'status': row['status'],
              'notes': row['notes'],
              'createdAt': row['created_at']?.toString(),
              'updatedAt': row['updated_at']?.toString(),
              'tableName': tableData['name'],
            };
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

      final rows = await _getList(
        '/customers',
        queryParameters: {
          'select':
              'id,name,phone,email,address,birth_date,total_orders,total_spent,loyalty_points,is_active,created_at,updated_at',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'phone': row['phone'],
                'email': row['email'],
                'address': row['address'],
                'birthDate': row['birth_date']?.toString(),
                'totalOrders': _asInt(row['total_orders']),
                'totalSpent': _asDouble(row['total_spent']),
                'loyaltyPoints': _asInt(row['loyalty_points']),
                'isActive': row['is_active'] == true,
                'createdAt': row['created_at']?.toString(),
                'updatedAt': row['updated_at']?.toString(),
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

      final rows = await _getList(
        '/ingredients',
        queryParameters: {
          'select':
              'id,name,description,unit,current_stock,min_stock,max_stock,unit_price,supplier,is_active,created_at,updated_at',
          'is_active': 'eq.true',
          'order': 'name.asc',
        },
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'description': row['description'],
                'unit': row['unit'],
                'currentStock': _asDouble(row['current_stock']),
                'minStock': _asDouble(row['min_stock']),
                'maxStock': _asDouble(row['max_stock']),
                'unitPrice': _asDouble(row['unit_price']),
                'supplier': row['supplier'],
                'isActive': row['is_active'] == true,
                'createdAt': row['created_at']?.toString(),
                'updatedAt': row['updated_at']?.toString(),
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

  Future<List<Map<String, dynamic>>> getReportTemplates() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final rows = await _getList(
        '/report_templates',
        queryParameters: {
          'select':
              'id,name,description,category,is_system,data_source,columns,filters,grouping,sorting,aggregations,chart_config,is_public,created_at,updated_at',
          'order': 'created_at.desc',
        },
      );

      return rows.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      _logger.e('Rapor şablonları getirilemedi: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getReportExecutions({
    String? templateId,
  }) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final query = <String, dynamic>{
        'select':
            'id,template_id,scheduled_report_id,status,execution_time_ms,row_count,file_url,file_size_bytes,error_message,created_at',
        'order': 'created_at.desc',
      };
      if (templateId != null && templateId.isNotEmpty) {
        query['template_id'] = 'eq.$templateId';
      }

      final rows = await _getList(
        '/report_executions',
        queryParameters: query,
      );
      return rows.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      _logger.e('Rapor çalıştırma kayıtları getirilemedi: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailySalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final query = <String, dynamic>{
        'select':
            'sale_date,total_orders,total_revenue,total_tax,total_discount,average_order_value',
        'order': 'sale_date.desc',
      };
      if (startDate != null && endDate != null) {
        query['and'] =
            '(sale_date.gte.${startDate.toIso8601String().split('T').first},sale_date.lte.${endDate.toIso8601String().split('T').first})';
      }

      final rows = await _getList('/daily_sales', queryParameters: query);
      return rows.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      _logger.e('Günlük satış özeti getirilemedi: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      if (!_isConnected) {
        await initialize();
      }

      final tables = await getTables();
      final regions = await getRegions();
      final products = await getProducts();
      final orderStats = await getOrderStatistics();

      final totalTables = tables.length;
      final availableTables = tables
          .where(
            (table) =>
                (table['status']?.toString().toLowerCase() ?? '') == 'available',
          )
          .length;
      final occupiedTables = tables
          .where(
            (table) =>
                (table['status']?.toString().toLowerCase() ?? '') == 'occupied',
          )
          .length;
      final totalRegions = regions.length;
      final totalProducts = products.length;
      final todayOrders = _asInt(orderStats['todayOrders']);
      final todayRevenue = _asDouble(orderStats['todayRevenue']);

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

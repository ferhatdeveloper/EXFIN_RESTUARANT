import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/postgres_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultTtl = Duration(minutes: 5);
  static const Duration _masterDataTtl = Duration(minutes: 30);

  Future<List<Map<String, dynamic>>> getCached(
    String key,
    Future<List<Map<String, dynamic>>> Function() fetcher, {
    Duration? ttl,
  }) async {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data;
    }

    final data = await fetcher();
    _cache[key] = _CacheEntry(data: data, ttl: ttl ?? _defaultTtl);
    return data;
  }

  Future<List<Map<String, dynamic>>> getCategories() => getCached(
    'categories',
    () async {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      return pg.query("SELECT id, code, name, is_restaurant, is_active FROM rex_001_categories ORDER BY name");
    },
    ttl: _masterDataTtl,
  );

  Future<List<Map<String, dynamic>>> getBrands() => getCached(
    'brands',
    () async {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      return pg.query("SELECT id, code, name FROM rex_001_brands ORDER BY name");
    },
    ttl: _masterDataTtl,
  );

  Future<List<Map<String, dynamic>>> getUnits() => getCached(
    'units',
    () async {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      return pg.query("SELECT id, code, name FROM rex_001_units ORDER BY name");
    },
    ttl: _masterDataTtl,
  );

  Future<List<Map<String, dynamic>>> getRoles() => getCached(
    'roles',
    () async {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      return pg.query("SELECT id, name, color, permissions FROM public.roles ORDER BY name");
    },
    ttl: _masterDataTtl,
  );

  Future<List<Map<String, dynamic>>> getCurrencies() => getCached(
    'currencies',
    () async {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      return pg.query("SELECT id, code, name, symbol, is_base_currency FROM public.currencies WHERE is_active = true ORDER BY sort_order");
    },
    ttl: _masterDataTtl,
  );

  void invalidate(String key) => _cache.remove(key);
  void invalidateAll() => _cache.clear();

  void invalidatePattern(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }
}

class _CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required Duration ttl})
      : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class PaginatedQuery {
  final PostgresService _pg = PostgresService();

  Future<PaginatedResult> fetch({
    required String table,
    String? where,
    String orderBy = 'created_at DESC',
    int page = 1,
    int pageSize = 50,
    Map<String, dynamic>? params,
  }) async {
    if (!_pg.isConnected) await _pg.initialize();

    final offset = (page - 1) * pageSize;
    final whereClause = where != null ? 'WHERE $where' : '';

    final countResult = await _pg.query(
      "SELECT COUNT(*) as total FROM $table $whereClause",
      params: params,
    );
    final total = _toInt(countResult.isNotEmpty ? countResult.first['total'] : 0);

    final data = await _pg.query(
      "SELECT * FROM $table $whereClause ORDER BY $orderBy LIMIT $pageSize OFFSET $offset",
      params: params,
    );

    return PaginatedResult(
      data: data,
      page: page,
      pageSize: pageSize,
      totalCount: total,
      totalPages: (total / pageSize).ceil(),
    );
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }
}

class PaginatedResult {
  final List<Map<String, dynamic>> data;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  PaginatedResult({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

class ConnectionHealthCheck {
  static final ConnectionHealthCheck _instance = ConnectionHealthCheck._();
  factory ConnectionHealthCheck() => _instance;
  ConnectionHealthCheck._();

  bool _isHealthy = false;
  bool get isHealthy => _isHealthy;
  DateTime? _lastCheck;
  Timer? _timer;

  void startMonitoring({int intervalSeconds = 60}) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => check());
    check();
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> check() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      await pg.query("SELECT 1");
      _isHealthy = true;
      _lastCheck = DateTime.now();
      return true;
    } catch (e) {
      _isHealthy = false;
      _lastCheck = DateTime.now();
      debugPrint('❌ DB health check failed: $e');

      try {
        final pg = PostgresService();
        await pg.close();
        await pg.initialize();
        _isHealthy = true;
        debugPrint('✅ DB reconnected');
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}

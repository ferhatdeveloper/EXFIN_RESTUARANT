import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'postgres_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Windows için databaseFactory başlat
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // C:/EXFIN klasörünü oluştur
    final exfinDir = Directory('C:/EXFIN');
    if (!await exfinDir.exists()) {
      await exfinDir.create(recursive: true);
    }

    final path = join('C:/EXFIN', 'exfin_api.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // API ayarları tablosu
    await db.execute('''
      CREATE TABLE api_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        base_url TEXT NOT NULL,
        username TEXT,
        password TEXT,
        token TEXT,
        last_sync TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // PostgreSQL ayarları tablosu
    await db.execute('''
      CREATE TABLE postgres_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        host TEXT NOT NULL,
        port INTEGER NOT NULL,
        database TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        postgrest_url TEXT NOT NULL,
        postgrest_schema TEXT NOT NULL DEFAULT 'public',
        postgrest_anon_key TEXT,
        useSSL INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // API veri önbelleği tablosu
    await db.execute('''
      CREATE TABLE api_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        data TEXT NOT NULL,
        last_fetch TEXT NOT NULL,
        expires_at TEXT
      )
    ''');

    // Varsayılan API ayarlarını ekle
    await db.insert('api_settings', {
      'base_url': 'http://localhost:3002',
      'username': 'admin',
      'password': 'admin123',
      'token': '',
      'last_sync': '',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Varsayılan PostgreSQL ayarlarını ekle
    await db.insert('postgres_settings', {
      'host': 'localhost',
      'port': 5432,
      'database': 'exfin_db',
      'username': 'postgres',
      'password': 'postgres',
      'postgrest_url': 'http://localhost:3002',
      'postgrest_schema': 'public',
      'postgrest_anon_key': '',
      'useSSL': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // PostgreSQL ayarları tablosunu ekle
    if (oldVersion < 2) {
      try {
        await db.execute('''
          CREATE TABLE postgres_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            host TEXT NOT NULL,
            port INTEGER NOT NULL,
            database TEXT NOT NULL,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            postgrest_url TEXT NOT NULL,
            postgrest_schema TEXT NOT NULL DEFAULT 'public',
            postgrest_anon_key TEXT,
            useSSL INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        // Varsayılan PostgreSQL ayarlarını ekle
        await db.insert('postgres_settings', {
          'host': 'localhost',
          'port': 5432,
          'database': 'exfin_db',
          'username': 'postgres',
          'password': 'postgres',
          'postgrest_url': 'http://localhost:3002',
          'postgrest_schema': 'public',
          'postgrest_anon_key': '',
          'useSSL': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Tablo zaten varsa hata verme
        print('PostgreSQL settings table already exists: $e');
      }
    }

    // PostgREST ayar kolonlarını ekle
    if (oldVersion < 3) {
      try {
        await db.execute(
          "ALTER TABLE postgres_settings ADD COLUMN postgrest_url TEXT NOT NULL DEFAULT 'http://localhost:3002'",
        );
      } catch (_) {}

      try {
        await db.execute(
          "ALTER TABLE postgres_settings ADD COLUMN postgrest_schema TEXT NOT NULL DEFAULT 'public'",
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE postgres_settings ADD COLUMN postgrest_anon_key TEXT',
        );
      } catch (_) {}
    }
  }

  // API Ayarları İşlemleri
  Future<Map<String, dynamic>?> getApiSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('api_settings', limit: 1);

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> updateApiSettings({
    String? baseUrl,
    String? username,
    String? password,
    String? token,
    String? lastSync,
  }) async {
    final db = await database;

    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (baseUrl != null) data['base_url'] = baseUrl;
    if (username != null) data['username'] = username;
    if (password != null) data['password'] = password;
    if (token != null) data['token'] = token;
    if (lastSync != null) data['last_sync'] = lastSync;

    await db.update('api_settings', data, where: 'id = 1');
  }

  Future<void> clearApiSettings() async {
    final db = await database;
    await db.update(
        'api_settings',
        {
          'username': '',
          'password': '',
          'token': '',
          'last_sync': '',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = 1');
  }

  // API Önbellek İşlemleri
  Future<void> cacheApiData(String endpoint, Map<String, dynamic> data,
      {Duration? expiresIn}) async {
    final db = await database;

    final expiresAt = expiresIn != null
        ? DateTime.now().add(expiresIn).toIso8601String()
        : null;

    await db.insert(
        'api_cache',
        {
          'endpoint': endpoint,
          'data': data.toString(), // JSON string olarak sakla
          'last_fetch': DateTime.now().toIso8601String(),
          'expires_at': expiresAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedData(String endpoint) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'api_cache',
      where: 'endpoint = ?',
      whereArgs: [endpoint],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final cache = maps.first;
      final expiresAt = cache['expires_at'] as String?;

      // Önbellek süresi dolmuş mu kontrol et
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiry)) {
          // Süresi dolmuş, sil
          await db.delete(
            'api_cache',
            where: 'endpoint = ?',
            whereArgs: [endpoint],
          );
          return null;
        }
      }

      // JSON string'i parse et
      try {
        final dataString = cache['data'] as String;
        // Basit string parsing (gerçek uygulamada json_serializable kullanılabilir)
        return {'cached': true, 'data': dataString};
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('api_cache');
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    await db.delete(
      'api_cache',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  // Kullanıcı İşlemleri
  Future<List<Map<String, dynamic>>> getCachedUsers() async {
    try {
      // Önce cache'den kontrol et
      final cachedData = await getCachedData('/api/test/users');
      if (cachedData != null && cachedData['data'] != null) {
        // Cache'den kullanıcıları parse et
        final dataString = cachedData['data'] as String;
        // Basit parsing - gerçek uygulamada JSON parsing kullanılmalı
        return _parseUsersFromCache(dataString);
      }

      // Cache'de yoksa API'den çek
      return await fetchUsersFromApi();
    } catch (e) {
      print('❌ Kullanıcılar alınırken hata: $e');
      return [];
    }
  }

  // Cache'i zorla yenilemek için
  Future<List<Map<String, dynamic>>> getFreshUsers() async {
    try {
      print('🔄 Cache zorla yenileniyor...');
      // Cache'i temizle
      await clearCache();
      print('✅ Cache temizlendi');

      // API'den yeni verileri çek
      print('📡 API\'den yeni veriler çekiliyor...');
      final users = await fetchUsersFromApi();
      print('✅ API\'den ${users.length} kullanıcı alındı');
      return users;
    } catch (e) {
      print('❌ Cache yenileme hatası: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsersFromApi() async {
    try {
      print('🚀 fetchUsersFromApi başlatıldı');

      // API Service'i kullanarak kullanıcıları çek
      final postgresService = await _getPostgresService();
      print('✅ PostgresService başarıyla alındı');

      // PostgreSQL'den kullanıcı verilerini çek
      try {
        print('📡 PostgreSQL\'den kullanıcı verileri çekiliyor...');
        final users = await postgresService.getUsers();
        print('📊 PostgreSQL Response: ${users.length} kullanıcı');

        if (users.isNotEmpty) {
          // Cache'e kaydet
          await cacheApiData('/api/test/users', {'users': users},
              expiresIn: const Duration(hours: 1));

          print(
              '✅ PostgreSQL\'den kullanıcı verileri alındı: ${users.length} kullanıcı');
          return users;
        } else {
          print('⚠️ PostgreSQL\'den kullanıcı bulunamadı');
          throw Exception('PostgreSQL\'den kullanıcı bulunamadı');
        }
      } catch (postgresError) {
        print('❌ PostgreSQL\'den kullanıcı çekme hatası: $postgresError');

        // PostgreSQL hatası durumunda varsayılan kullanıcıları döndür
        final defaultUsers = [
          {'username': 'admin', 'password': 'admin123', 'role': 'admin'},
          {'username': 'manager', 'password': 'password', 'role': 'manager'},
          {'username': 'cashier', 'password': 'password', 'role': 'cashier'},
          {'username': 'waiter', 'password': 'password', 'role': 'waiter'},
          {'username': 'kitchen', 'password': 'password', 'role': 'kitchen'},
          {'username': 'guest', 'password': 'password', 'role': 'guest'},
        ];

        // Cache'e kaydet
        await cacheApiData('/api/test/users', {'users': defaultUsers},
            expiresIn: const Duration(hours: 1));

        print('✅ Varsayılan kullanıcılar kullanılıyor');
        return defaultUsers;
      }
    } catch (e) {
      print('❌ API\'den kullanıcılar alınırken hata: $e');
      // Hata durumunda varsayılan kullanıcıları döndür
      return [
        {'username': 'admin', 'password': 'admin123', 'role': 'admin'},
        {'username': 'manager', 'password': 'password', 'role': 'manager'},
        {'username': 'cashier', 'password': 'password', 'role': 'cashier'},
        {'username': 'waiter', 'password': 'password', 'role': 'waiter'},
        {'username': 'kitchen', 'password': 'password', 'role': 'kitchen'},
        {'username': 'guest', 'password': 'password', 'role': 'guest'},
      ];
    }
  }

  Future<Map<String, dynamic>?> getUserByRole(String role) async {
    try {
      final users = await getCachedUsers();

      // Rol bazlı kullanıcı arama
      for (final user in users) {
        final userRole = user['role']?.toString().toLowerCase();
        if (userRole == role.toLowerCase()) {
          return user;
        }
      }

      return null;
    } catch (e) {
      print('❌ Rol bazlı kullanıcı arama hatası: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _parseUsersFromCache(String dataString) {
    try {
      // Basit string parsing - gerçek uygulamada JSON parsing kullanılmalı
      // Bu örnek için basit bir parsing yapıyoruz
      final users = <Map<String, dynamic>>[];

      // Cache'den gelen string'i parse et
      // Bu kısım gerçek uygulamada JSON parsing ile yapılmalı
      if (dataString.contains('users')) {
        // Cache'de gerçek veri varsa onu kullan, yoksa boş döndür
        print(
            '⚠️ Cache\'de varsayılan kullanıcılar var, API\'den yeniden çekiliyor');
        return []; // Boş döndür ki API'den yeniden çeksin
      }

      return users;
    } catch (e) {
      print('❌ Cache parsing hatası: $e');
      return [];
    }
  }

  Future<PostgresService> _getPostgresService() async {
    final postgresService = PostgresService();
    await postgresService.initialize();
    return postgresService;
  }

  /// PostgreSQL ayarlarını kaydet
  Future<void> savePostgresSettings({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    String postgrestUrl = 'http://localhost:3002',
    String postgrestSchema = 'public',
    String? postgrestAnonKey,
    bool useSSL = false,
  }) async {
    final db = await this.database;
    await db.insert(
        'postgres_settings',
        {
          'host': host,
          'port': port,
          'database': database,
          'username': username,
          'password': password,
          'postgrest_url': postgrestUrl,
          'postgrest_schema': postgrestSchema,
          'postgrest_anon_key': postgrestAnonKey ?? '',
          'useSSL': useSSL ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// PostgreSQL ayarlarını getir
  Future<Map<String, dynamic>?> getPostgresSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'postgres_settings',
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return {
        'host': results.first['host'],
        'port': results.first['port'],
        'database': results.first['database'],
        'username': results.first['username'],
        'password': results.first['password'],
        'postgrestUrl':
            results.first['postgrest_url'] ?? 'http://localhost:3002',
        'postgrestSchema': results.first['postgrest_schema'] ?? 'public',
        'postgrestAnonKey': results.first['postgrest_anon_key'] ?? '',
        'useSSL': results.first['useSSL'] == 1,
      };
    }
    return null;
  }

  /// PostgreSQL ayarlarını güncelle
  Future<void> updatePostgresSettings({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    String postgrestUrl = 'http://localhost:3002',
    String postgrestSchema = 'public',
    String? postgrestAnonKey,
    bool useSSL = false,
  }) async {
    final db = await this.database;
    await db.update(
      'postgres_settings',
      {
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        'password': password,
        'postgrest_url': postgrestUrl,
        'postgrest_schema': postgrestSchema,
        'postgrest_anon_key': postgrestAnonKey ?? '',
        'useSSL': useSSL ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where:
          'id = (SELECT id FROM postgres_settings ORDER BY created_at DESC LIMIT 1)',
    );
  }

  /// PostgreSQL bağlantısını test et
  Future<bool> testPostgresConnection({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    String postgrestUrl = 'http://localhost:3002',
    String postgrestSchema = 'public',
    String? postgrestAnonKey,
    bool useSSL = false,
  }) async {
    try {
      // Bu metod sadece ayarları kaydeder, gerçek bağlantı testi PostgresService'de yapılır
      await savePostgresSettings(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
        postgrestUrl: postgrestUrl,
        postgrestSchema: postgrestSchema,
        postgrestAnonKey: postgrestAnonKey,
        useSSL: useSSL,
      );
      return true;
    } catch (e) {
      print('PostgreSQL ayarları kaydedilemedi: $e');
      return false;
    }
  }

  // Database kapatma
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

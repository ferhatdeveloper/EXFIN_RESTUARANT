import 'dart:developer' as developer;
import 'postgres_service.dart';
import 'database_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final PostgresService _postgresService = PostgresService();
  final DatabaseService _dbService = DatabaseService();

  /// PostgreSQL ayarlarını kontrol et ve gerekirse hata fırlat
  Future<void> _checkPostgresSettings() async {
    final postgresSettings = await _dbService.getPostgresSettings();
    if (postgresSettings == null) {
      throw Exception(
          'PostgreSQL ayarları bulunamadı. Lütfen PostgreSQL ayarları ekranından yapılandırın.');
    }

    final host = postgresSettings['host'] as String?;
    if (host == null || host.isEmpty) {
      throw Exception(
          'PostgreSQL host ayarlanmamış. Lütfen PostgreSQL ayarlarını kontrol edin.');
    }
  }

  /// PostgreSQL servisini başlat ve ayarları yükle
  Future<void> initialize() async {
    try {
      developer.log('🚀 DataService Initialize Başlatıldı',
          name: 'DataService');

      await _checkPostgresSettings();
      await _postgresService.initialize();

      developer.log('✅ DataService Initialize Tamamlandı', name: 'DataService');
    } catch (e) {
      developer.log('❌ DataService Initialize Hatası: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Kullanıcıları getir
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      developer.log('👥 Kullanıcılar getiriliyor...', name: 'DataService');
      return await _postgresService.getUsers();
    } catch (e) {
      developer.log('❌ Kullanıcılar getirilemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Kullanıcı doğrula
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    try {
      developer.log('🔐 Kullanıcı doğrulama başlatıldı', name: 'DataService');
      return await _postgresService.authenticateUser(username, password);
    } catch (e) {
      developer.log('❌ Kullanıcı doğrulama hatası: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Masaları getir
  Future<List<Map<String, dynamic>>> getTables() async {
    try {
      developer.log('🪑 Masalar getiriliyor...', name: 'DataService');
      return await _postgresService.getTables();
    } catch (e) {
      developer.log('❌ Masalar getirilemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Bölgeleri getir
  Future<List<Map<String, dynamic>>> getRegions() async {
    try {
      developer.log('🗺️ Bölgeler getiriliyor...', name: 'DataService');
      return await _postgresService.getRegions();
    } catch (e) {
      developer.log('❌ Bölgeler getirilemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Masa durumunu güncelle
  Future<bool> updateTableStatus(int tableId, String status) async {
    try {
      developer.log('🔄 Masa durumu güncelleniyor...', name: 'DataService');
      return await _postgresService.updateTableStatus(tableId, status);
    } catch (e) {
      developer.log('❌ Masa durumu güncellenemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Yeni masa ekle
  Future<bool> addTable(Map<String, dynamic> tableData) async {
    try {
      developer.log('➕ Yeni masa ekleniyor...', name: 'DataService');
      return await _postgresService.addTable(tableData);
    } catch (e) {
      developer.log('❌ Masa eklenemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Masa güncelle
  Future<bool> updateTable(int tableId, Map<String, dynamic> tableData) async {
    try {
      developer.log('✏️ Masa güncelleniyor...', name: 'DataService');
      return await _postgresService.updateTable(tableId, tableData);
    } catch (e) {
      developer.log('❌ Masa güncellenemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Masa sil
  Future<bool> deleteTable(int tableId) async {
    try {
      developer.log('🗑️ Masa siliniyor...', name: 'DataService');
      return await _postgresService.deleteTable(tableId);
    } catch (e) {
      developer.log('❌ Masa silinemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Bölgeye göre masaları getir
  Future<List<Map<String, dynamic>>> getTablesByRegion(int regionId) async {
    try {
      developer.log('📍 Bölge masaları getiriliyor...', name: 'DataService');
      return await _postgresService.getTablesByRegion(regionId);
    } catch (e) {
      developer.log('❌ Bölge masaları getirilemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// İstatistikleri getir
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      developer.log('📊 İstatistikler getiriliyor...', name: 'DataService');
      return await _postgresService.getStatistics();
    } catch (e) {
      developer.log('❌ İstatistikler getirilemedi: $e', name: 'DataService');
      rethrow;
    }
  }

  /// Bağlantıyı test et
  Future<bool> testConnection() async {
    try {
      developer.log('🔍 PostgreSQL bağlantısı test ediliyor...', name: 'DataService');
      return await _postgresService.testConnection();
    } catch (e) {
      developer.log('❌ Bağlantı testi başarısız: $e', name: 'DataService');
      return false;
    }
  }

  /// Bağlantıyı kapat
  Future<void> close() async {
    try {
      developer.log('🔌 PostgreSQL bağlantısı kapatılıyor...', name: 'DataService');
      await _postgresService.close();
    } catch (e) {
      developer.log('❌ Bağlantı kapatma hatası: $e', name: 'DataService');
    }
  }
}

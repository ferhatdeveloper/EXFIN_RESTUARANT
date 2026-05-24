import '../../../core/base/base_viewmodel.dart';
import '../model/user_model.dart';
import '../../../services/postgres_service.dart';
import '../../../services/database_service.dart';
import 'dart:developer' as developer;

class AuthViewModel extends BaseViewModel {
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String username, String password) async {
    try {
      setLoading(true);
      clearError();

      developer.log('🚀 AuthViewModel Login Başlatıldı', name: 'AuthViewModel');
      developer.log('👤 Username: $username', name: 'AuthViewModel');
      developer.log('🔑 Password: ${password.replaceAll(RegExp(r'.'), '*')}',
          name: 'AuthViewModel');

      // SQLite'dan PostgreSQL ayarlarını al
      developer.log('📂 DatabaseService başlatılıyor...',
          name: 'AuthViewModel');
      final dbService = DatabaseService();
      final postgresSettings = await dbService.getPostgresSettings();
      developer.log('📊 PostgreSQL Ayarları: $postgresSettings', name: 'AuthViewModel');

      if (postgresSettings == null) {
        developer.log('❌ PostgreSQL ayarları bulunamadı', name: 'AuthViewModel');
        setError(
            'PostgreSQL ayarları bulunamadı. Lütfen PostgreSQL ayarları ekranından yapılandırın.');
        return false;
      }

      final host = postgresSettings['host'] as String?;
      if (host == null || host.isEmpty) {
        developer.log('❌ Host eksik', name: 'AuthViewModel');
        setError(
            'PostgreSQL host ayarlanmamış. Lütfen PostgreSQL ayarlarını kontrol edin.');
        return false;
      }

      developer.log('⚙️ PostgresService başlatılıyor...', name: 'AuthViewModel');
      final postgresService = PostgresService();
      await postgresService.initialize();

      // PostgreSQL bağlantısını test et
      developer.log('🔍 PostgreSQL bağlantısı test ediliyor...', name: 'AuthViewModel');
      final isConnected = await postgresService.testConnection();
      
      if (!isConnected) {
        developer.log('❌ PostgreSQL bağlantısı başarısız', name: 'AuthViewModel');
        setError('PostgreSQL veritabanına bağlanılamıyor. Lütfen ayarları kontrol edin.');
        return false;
      }

      developer.log('✅ PostgreSQL bağlantısı başarılı', name: 'AuthViewModel');

      // Kullanıcı doğrulama
      developer.log('🔐 Kullanıcı doğrulama başlatılıyor...', name: 'AuthViewModel');
      final user = await postgresService.authenticateUser(username, password);

      if (user == null) {
        developer.log('❌ Kullanıcı doğrulama başarısız', name: 'AuthViewModel');
        setError('Kullanıcı adı veya şifre hatalı');
        return false;
      }

      developer.log('✅ Kullanıcı doğrulama başarılı', name: 'AuthViewModel');
      developer.log('👤 Kullanıcı: ${user['username']}', name: 'AuthViewModel');
      developer.log('🎭 Rol: ${user['role']}', name: 'AuthViewModel');

      // Kullanıcı modelini oluştur
      _currentUser = UserModel(
        id: user['id'],
        username: user['username'],
        email: user['email'] ?? '${user['username']}@exfin.com',
        role: user['role'],
        isActive: user['isActive'],
      );

      _isAuthenticated = true;
      setLoading(false);

      developer.log('🎉 Login başarılı', name: 'AuthViewModel');
      return true;
    } catch (e) {
      developer.log('❌ Login hatası: $e', name: 'AuthViewModel');
      
      String errorMessage = 'Giriş yapılırken bir hata oluştu';
      
      if (e.toString().contains('SocketException')) {
        errorMessage = 'PostgreSQL sunucusuna bağlanılamıyor';
      } else if (e.toString().contains('authentication')) {
        errorMessage = 'Kullanıcı adı veya şifre hatalı';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Bağlantı zaman aşımına uğradı';
      }
      
      setError(errorMessage);
      setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      developer.log('🚪 Logout başlatıldı', name: 'AuthViewModel');
      
      _currentUser = null;
      _isAuthenticated = false;
      
      developer.log('✅ Logout tamamlandı', name: 'AuthViewModel');
    } catch (e) {
      developer.log('❌ Logout hatası: $e', name: 'AuthViewModel');
    }
  }

  Future<bool> checkAuthStatus() async {
    try {
      developer.log('🔍 Kimlik doğrulama durumu kontrol ediliyor...', name: 'AuthViewModel');
      
      if (_currentUser != null && _isAuthenticated) {
        developer.log('✅ Kullanıcı zaten giriş yapmış', name: 'AuthViewModel');
        return true;
      }
      
      developer.log('❌ Kullanıcı giriş yapmamış', name: 'AuthViewModel');
      return false;
    } catch (e) {
      developer.log('❌ Kimlik doğrulama durumu kontrol hatası: $e', name: 'AuthViewModel');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      developer.log('👥 Kullanıcılar getiriliyor...', name: 'AuthViewModel');
      
      final postgresService = PostgresService();
      await postgresService.initialize();
      
      final users = await postgresService.getUsers();
      developer.log('✅ ${users.length} kullanıcı getirildi', name: 'AuthViewModel');
      
      return users;
    } catch (e) {
      developer.log('❌ Kullanıcılar getirilemedi: $e', name: 'AuthViewModel');
      rethrow;
    }
  }
}

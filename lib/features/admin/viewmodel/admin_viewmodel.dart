import '../../../core/base/base_viewmodel.dart';
import '../../auth/model/user_model.dart';
import '../../products/model/product_model.dart';

class AdminViewModel extends BaseViewModel {
  List<UserModel> _users = [];
  List<ProductModel> _products = [];
  Map<String, dynamic> _systemStats = {};
  String _selectedSection = 'dashboard';

  List<UserModel> get users => _users;
  List<ProductModel> get products => _products;
  Map<String, dynamic> get systemStats => _systemStats;
  String get selectedSection => _selectedSection;

  AdminViewModel() {
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      setLoading(true);

      await Future.wait([
        _loadUsers(),
        _loadProducts(),
        _loadSystemStats(),
      ]);

      notifyListeners();
    } catch (e) {
      setError('Admin verileri yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadUsers() async {
    // TODO: GraphQL ile kullanıcıları yükle
    await Future.delayed(const Duration(milliseconds: 300));

    _users = [
      UserModel(
        id: 1,
        username: 'admin',
        email: 'admin@exfin.com',
        role: 'admin',
        fullName: 'Admin User',
        isActive: true,
        lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      UserModel(
        id: 2,
        username: 'waiter1',
        email: 'waiter1@exfin.com',
        role: 'waiter',
        fullName: 'Ahmet Garson',
        isActive: true,
        lastLogin: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      UserModel(
        id: 3,
        username: 'kitchen1',
        email: 'kitchen1@exfin.com',
        role: 'kitchen',
        fullName: 'Mehmet Aşçı',
        isActive: true,
        lastLogin: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      UserModel(
        id: 4,
        username: 'cashier1',
        email: 'cashier1@exfin.com',
        role: 'cashier',
        fullName: 'Ayşe Kasiyer',
        isActive: true,
        lastLogin: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  Future<void> _loadProducts() async {
    // TODO: GraphQL ile ürünleri yükle
    await Future.delayed(const Duration(milliseconds: 300));

    _products = [
      ProductModel(
        id: 'prod_1',
        name: 'Döner',
        description: 'Tavuk döner porsiyon',
        price: 25.0,
        category: 'Sıcak Yemek',
        categoryId: 'cat_1',
        stockQuantity: 50,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ProductModel(
        id: 'prod_2',
        name: 'Ayran',
        description: 'Taze ayran',
        price: 5.0,
        category: 'İçecek',
        categoryId: 'cat_2',
        stockQuantity: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      ProductModel(
        id: 'prod_3',
        name: 'Künefe',
        description: 'Antep fıstıklı künefe',
        price: 15.0,
        category: 'Tatlı',
        categoryId: 'cat_3',
        stockQuantity: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  Future<void> _loadSystemStats() async {
    // TODO: GraphQL ile sistem istatistiklerini yükle
    await Future.delayed(const Duration(milliseconds: 300));

    _systemStats = {
      'total_users': 4,
      'active_users': 3,
      'total_products': 25,
      'low_stock_products': 5,
      'total_orders_today': 45,
      'total_revenue_today': 1250.0,
      'total_tables': 10,
      'occupied_tables': 6,
      'system_uptime': '99.9%',
      'last_backup': DateTime.now().subtract(const Duration(hours: 6)),
    };
  }

  void setSelectedSection(String section) {
    _selectedSection = section;
    notifyListeners();
  }

  Future<bool> createUser(UserModel user) async {
    try {
      setLoading(true);

      // TODO: GraphQL ile kullanıcı oluştur
      await Future.delayed(const Duration(milliseconds: 500));

      _users.add(user);
      notifyListeners();
      return true;
    } catch (e) {
      setError('Kullanıcı oluşturulurken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      setLoading(true);

      // TODO: GraphQL ile kullanıcı güncelle
      await Future.delayed(const Duration(milliseconds: 300));

      final index =
          _users.indexWhere((u) => u.id.toString() == user.id.toString());
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      setError('Kullanıcı güncellenirken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      setLoading(true);

      // TODO: GraphQL ile kullanıcı sil
      await Future.delayed(const Duration(milliseconds: 300));

      _users.removeWhere((user) => user.id.toString() == userId);
      notifyListeners();
      return true;
    } catch (e) {
      setError('Kullanıcı silinirken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> toggleUserStatus(String userId) async {
    try {
      setLoading(true);

      // TODO: GraphQL ile kullanıcı durumunu değiştir
      await Future.delayed(const Duration(milliseconds: 300));

      final index = _users.indexWhere((user) => user.id.toString() == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          isActive: !_users[index].isActive,
        );
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      setError('Kullanıcı durumu değiştirilirken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  List<UserModel> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  List<UserModel> getActiveUsers() {
    return _users.where((user) => user.isActive).toList();
  }

  List<ProductModel> getLowStockProducts() {
    return _products.where((product) => product.stockQuantity < 10).toList();
  }

  Map<String, int> getUserRoleCounts() {
    final counts = <String, int>{};
    for (final user in _users) {
      counts[user.role] = (counts[user.role] ?? 0) + 1;
    }
    return counts;
  }
}

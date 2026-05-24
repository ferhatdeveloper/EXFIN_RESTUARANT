import 'package:flutter/foundation.dart';
import '../../../core/base/base_viewmodel.dart';
import '../../../services/postgres_service.dart';
import '../model/product_model.dart';

class ProductsViewModel extends BaseViewModel {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get products => _products;
  List<dynamic> get categories => _categories;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadProducts() async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();
      // Mock ürün verileri
      _products = [
        {
          'id': '1',
          'name': 'Pizza Margherita',
          'description': 'Domates, mozzarella, fesleğen',
          'price': 25.0,
          'categoryId': '1',
          'stockQuantity': 50
        },
        {
          'id': '2',
          'name': 'Burger',
          'description': 'Dana eti, marul, domates',
          'price': 18.0,
          'categoryId': '2',
          'stockQuantity': 30
        },
        {
          'id': '3',
          'name': 'Cola',
          'description': 'Gazlı içecek',
          'price': 5.0,
          'categoryId': '3',
          'stockQuantity': 100
        },
      ];
      notifyListeners();
    } catch (e) {
      setError('Ürünler yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadCategories() async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();
      // Mock kategori verileri
      _categories = [
        {'id': '1', 'name': 'Pizza', 'description': 'İtalyan pizzaları'},
        {'id': '2', 'name': 'Burger', 'description': 'Hamburgerler'},
        {'id': '3', 'name': 'İçecek', 'description': 'Soğuk içecekler'},
      ];
      notifyListeners();
    } catch (e) {
      setError('Kategoriler yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> refresh() async {
    await loadProducts();
    await loadCategories();
  }

  Future<bool> createProduct(ProductModel product) async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();

      final productData = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'categoryId': product.categoryId,
        'stockQuantity': product.stockQuantity,
      };

      // Mock ürün oluşturma
      debugPrint('Ürün oluşturuldu: $productData');
      await loadProducts();
      return true;
    } catch (e) {
      setError('Ürün oluşturulurken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();

      final productData = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'categoryId': product.categoryId,
        'stockQuantity': product.stockQuantity,
      };

      // Mock ürün güncelleme
      debugPrint('Ürün güncellendi: ${product.id} -> $productData');
      await loadProducts();
      return true;
    } catch (e) {
      setError('Ürün güncellenirken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();
      // Mock ürün silme
      debugPrint('Ürün silindi: $productId');
      await loadProducts();
      return true;
    } catch (e) {
      setError('Ürün silinirken hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    try {
      setLoading(true);
      final postgresService = PostgresService();
      await postgresService.initialize();
      // Mock ürün bilgisi
      final result = {
        'id': productId,
        'name': 'Pizza Margherita',
        'description': 'Domates, mozzarella, fesleğen',
        'price': 25.0,
        'categoryId': '1',
        'stockQuantity': 50,
      };
      return result;
    } catch (e) {
      setError('Ürün bilgileri alınırken hata oluştu: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }
}

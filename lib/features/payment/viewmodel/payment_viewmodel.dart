import '../../../core/base/base_viewmodel.dart';
import '../../orders/model/order_model.dart';

class PaymentViewModel extends BaseViewModel {
  List<Order> _pendingPayments = [];
  String _selectedPaymentMethod = 'cash';
  double _totalAmount = 0.0;

  List<Order> get pendingPayments => _pendingPayments;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  double get totalAmount => _totalAmount;

  PaymentViewModel() {
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    try {
      setLoading(true);

      // TODO: GraphQL ile bekleyen ödemeleri yükle
      await Future.delayed(const Duration(milliseconds: 500));

      _pendingPayments = [
        Order(
          id: 'order_1',
          faturaKodu:
              'B0120240321001', // Test verisi - gerçek sistemde dinamik oluşturulur
          tableNumber: 1,
          items: [
            CartItem(
              product: Product(
                name: 'Döner',
                price: 25.0,
                image: 'assets/images/doner.jpg',
                category: 'Sıcak Yemek',
              ),
              quantity: 2,
            ),
            CartItem(
              product: Product(
                name: 'Ayran',
                price: 5.0,
                image: 'assets/images/ayran.jpg',
                category: 'İçecek',
              ),
              quantity: 2,
            ),
            CartItem(
              product: Product(
                name: 'Baklava',
                price: 8.0,
                image: 'assets/images/baklava.jpg',
                category: 'Tatlı',
              ),
              quantity: 1,
            ),
          ],
          status: 'ready',
          total: 68.0,
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      ];

      _calculateTotal();
      notifyListeners();
    } catch (e) {
      setError('Bekleyen ödemeler yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void _calculateTotal() {
    _totalAmount =
        _pendingPayments.fold(0.0, (sum, order) => sum + order.total);
  }

  Future<bool> processPayment(
      String orderId, double amount, String method) async {
    try {
      setLoading(true);

      // TODO: GraphQL ile ödeme işlemini gerçekleştir
      await Future.delayed(const Duration(milliseconds: 1000));

      final order = _pendingPayments.firstWhere((order) => order.id == orderId);
      _pendingPayments.removeWhere((order) => order.id == orderId);

      // Ödeme başarılı olduğunda siparişi kaldır
      _calculateTotal();
      notifyListeners();

      return true;
    } catch (e) {
      setError('Ödeme işlemi sırasında hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> processBatchPayment(
      List<String> orderIds, double totalAmount, String method) async {
    try {
      setLoading(true);

      // TODO: GraphQL ile toplu ödeme işlemini gerçekleştir
      await Future.delayed(const Duration(milliseconds: 1500));

      for (final orderId in orderIds) {
        _pendingPayments.removeWhere((order) => order.id == orderId);
      }

      _calculateTotal();
      notifyListeners();

      return true;
    } catch (e) {
      setError('Toplu ödeme işlemi sırasında hata oluştu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  List<Order> getOrdersByTable(int tableNumber) {
    return _pendingPayments
        .where((order) => order.tableNumber == tableNumber)
        .toList();
  }

  double getTotalByTable(int tableNumber) {
    return _pendingPayments
        .where((order) => order.tableNumber == tableNumber)
        .fold(0.0, (sum, order) => sum + order.total);
  }

  void selectOrders(List<String> orderIds) {
    // TODO: Seçili siparişleri işaretle
    notifyListeners();
  }

  void clearSelection() {
    // TODO: Seçimleri temizle
    notifyListeners();
  }
}

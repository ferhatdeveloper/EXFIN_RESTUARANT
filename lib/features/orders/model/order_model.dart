// Dosya Adı: order_model.dart
// Açıklama: Sipariş işlemleri için model sınıfları
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

/// {@template Product}
/// Ürün modeli - menü öğelerini temsil eder
///
/// Kullanım örneği:
/// ```dart
/// final product = Product(
///   name: 'Pizza Margherita',
///   price: 25.0,
///   image: 'assets/images/pizza.jpg',
///   category: 'Pizza'
/// );
/// ```
/// {@endtemplate}
class Product {
  final String name;
  final double price;
  final String image;
  final String category;

  const Product({
    required this.name,
    required this.price,
    required this.image,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          price == other.price &&
          image == other.image &&
          category == other.category;

  @override
  int get hashCode =>
      name.hashCode ^ price.hashCode ^ image.hashCode ^ category.hashCode;
}

/// {@template CartItem}
/// Sepet öğesi modeli - sepetteki ürünleri temsil eder
///
/// Kullanım örneği:
/// ```dart
/// final cartItem = CartItem(
///   product: product,
///   quantity: 2
/// );
/// ```
/// {@endtemplate}
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get total => product.price * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;
}

/// {@template Order}
/// Sipariş modeli - tamamlanan siparişleri temsil eder
///
/// Kullanım örneği:
/// ```dart
/// final order = Order(
///   id: '1',
///   faturaKodu: 'B0120240321001',
///   tableNumber: 5,
///   items: cartItems,
///   total: 150.0,
///   status: 'completed'
/// );
/// ```
/// {@endtemplate}
class Order {
  final String id;
  final String faturaKodu;
  final int tableNumber;
  final List<CartItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.faturaKodu,
    required this.tableNumber,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          faturaKodu == other.faturaKodu &&
          tableNumber == other.tableNumber &&
          items == other.items &&
          total == other.total &&
          status == other.status &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      faturaKodu.hashCode ^
      tableNumber.hashCode ^
      items.hashCode ^
      total.hashCode ^
      status.hashCode ^
      createdAt.hashCode;
}

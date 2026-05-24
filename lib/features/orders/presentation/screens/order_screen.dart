import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/postgres_service.dart';

class CartItem {
  final Map<String, dynamic> product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}

class OrderScreen extends ConsumerStatefulWidget {
  final int tableNumber;
  const OrderScreen({super.key, required this.tableNumber});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  final PostgresService _postgresService = PostgresService();

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  List<CartItem> cart = [];
  String productSearchQuery = '';
  bool isLoading = true;
  int selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      debugPrint('🔍 Kategoriler yükleniyor...');
      final categoriesData = await _postgresService.getCategories();
      debugPrint('✅ Kategoriler yüklendi: ${categoriesData.length} adet');
      debugPrint(
          '📋 Kategori listesi: ${categoriesData.map((c) => c['name']).toList()}');

      setState(() {
        categories = [
          {
            "id": 0,
            "name": "Tümü",
            "icon": Icons.all_inclusive,
            "color": Colors.grey
          },
          ...categoriesData
              .map((cat) => {
                    "id": cat['id'],
                    "name": cat['name'],
                    "description": cat['description'],
                    "icon": _getCategoryIcon(cat['name']),
                    "color": _getCategoryColor(cat['name']),
                  })
              .toList(),
        ];
      });

      debugPrint('🔍 Ürünler yükleniyor...');
      final productsData = await _postgresService.getProducts();
      debugPrint('✅ Ürünler yüklendi: ${productsData.length} adet');
      if (productsData.isNotEmpty) {
        debugPrint('📦 İlk ürün: ${productsData.first}');
        debugPrint(
            '📦 İlk 3 ürün: ${productsData.take(3).map((p) => '${p['name']} (${p['price']})').toList()}');
      } else {
        debugPrint('❌ Ürün bulunamadı!');
      }

      setState(() {
        products = productsData;
      });
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
      setState(() {
        categories = [
          {
            "id": 0,
            "name": "Tümü",
            "icon": Icons.all_inclusive,
            "color": Colors.grey
          },
          {
            "id": 1,
            "name": "İçecekler",
            "icon": Icons.local_drink,
            "color": Colors.blue
          },
          {
            "id": 2,
            "name": "Başlangıçlar",
            "icon": Icons.soup_kitchen,
            "color": Colors.amber
          },
          {
            "id": 3,
            "name": "Ana Yemekler",
            "icon": Icons.restaurant,
            "color": Colors.red
          },
          {
            "id": 4,
            "name": "Deniz Ürünleri",
            "icon": Icons.set_meal,
            "color": Colors.cyan
          },
          {
            "id": 5,
            "name": "Tatlılar",
            "icon": Icons.cake,
            "color": Colors.pink
          },
        ];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'içecekler':
        return Icons.local_drink;
      case 'başlangıçlar':
        return Icons.soup_kitchen;
      case 'ana yemekler':
        return Icons.restaurant;
      case 'deniz ürünleri':
        return Icons.set_meal;
      case 'tatlılar':
        return Icons.cake;
      default:
        return Icons.restaurant_menu;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'içecekler':
        return Colors.blue;
      case 'başlangıçlar':
        return Colors.amber;
      case 'ana yemekler':
        return Colors.red;
      case 'deniz ürünleri':
        return Colors.cyan;
      case 'tatlılar':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingIndex =
          cart.indexWhere((item) => item.product['id'] == product['id']);
      if (existingIndex >= 0) {
        cart[existingIndex].quantity++;
      } else {
        cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void removeFromCart(Map<String, dynamic> product) {
    setState(() {
      cart.removeWhere((item) => item.product['id'] == product['id']);
    });
  }

  void decreaseQuantity(Map<String, dynamic> product) {
    setState(() {
      final existingIndex =
          cart.indexWhere((item) => item.product['id'] == product['id']);
      if (existingIndex >= 0 && cart[existingIndex].quantity > 1) {
        cart[existingIndex].quantity--;
      } else if (existingIndex >= 0) {
        cart.removeAt(existingIndex);
      }
    });
  }

  double get cartTotal => cart.fold(0.0,
      (sum, item) => sum + _parsePrice(item.product['price']) * item.quantity);

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _saveOrder() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepet boş!')),
      );
      return;
    }

    // Müşteri bilgilerini al
    final customerInfo = await _showCustomerDialog();
    if (customerInfo == null) return;

    // Ödeme yöntemini seç
    final paymentMethod = await _showPaymentDialog();
    if (paymentMethod == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Sipariş kalemlerini hazırla
      final items = cart
          .map((item) => {
                'productId': item.product['id'],
                'productName': item.product['name'],
                'quantity': item.quantity,
                'unitPrice': _parsePrice(item.product['price']),
                'totalPrice':
                    _parsePrice(item.product['price']) * item.quantity,
                'notes': '',
              })
          .toList();

      // Siparişi kaydet
      final result = await _postgresService.createOrder(
        tableId: widget.tableNumber,
        items: items,
        totalAmount: cartTotal,
        finalAmount: cartTotal, // İndirim hesaplaması eklenebilir
        customerName: customerInfo['name'],
        customerPhone: customerInfo['phone'],
        notes: customerInfo['notes'],
        paymentStatus: paymentMethod == 'cash' ? 'paid' : 'pending',
        orderStatus: 'active',
      );

      if (result.containsKey('error')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${result['error']}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Sipariş kaydedildi! Fatura Kodu: ${result['faturaKodu']} - Masa ${widget.tableNumber} dolu olarak işaretlendi')),
          );
        }

        // Sepeti temizle
        setState(() {
          cart.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sipariş kaydedilemedi: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, String>?> _showCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Müşteri Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notlar',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Müşteri adı gerekli!')),
                );
                return;
              }
              Navigator.of(context).pop({
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'notes': notesController.text.trim(),
              });
            },
            child: const Text('Devam'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPaymentDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Yöntemi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green),
              title: const Text('Nakit'),
              onTap: () => Navigator.of(context).pop('cash'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Kredi Kartı'),
              onTap: () => Navigator.of(context).pop('card'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getFilteredProducts() {
    debugPrint('🔍 getFilteredProducts çağrıldı');
    debugPrint('📊 Kategoriler: ${categories.length} adet');
    debugPrint('📊 Ürünler: ${products.length} adet');
    debugPrint('📊 Seçili kategori index: $selectedCategory');

    if (categories.isEmpty || selectedCategory >= categories.length) {
      debugPrint('❌ Kategoriler boş veya geçersiz seçili kategori');
      return [];
    }

    final selectedCategoryName = categories[selectedCategory]['name'];
    debugPrint('🎯 Seçili kategori: $selectedCategoryName');

    final filtered = products.where((product) {
      final matchesCategory = selectedCategoryName == 'Tümü' ||
          product['categoryName'] == selectedCategoryName;
      final matchesSearch = productSearchQuery.isEmpty ||
          product['name']
              .toString()
              .toLowerCase()
              .contains(productSearchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    debugPrint('✅ Filtrelenmiş ürün sayısı: ${filtered.length}');
    if (filtered.isNotEmpty) {
      debugPrint(
          '📦 Filtrelenmiş ürünler: ${filtered.take(3).map((p) => p['name']).toList()}');
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 900;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yükleniyor...'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Sipariş - Masa ${widget.tableNumber}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: isSmallScreen ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Kategori seçimi
        Container(
          height: 60,
          color: Colors.red,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == index;
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = index),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'],
                        color: isSelected ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.red : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Arama kutusu
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => productSearchQuery = value),
          ),
        ),
        // Ürünler
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: getFilteredProducts().length,
            itemBuilder: (context, index) {
              final product = getFilteredProducts()[index];
              return _buildProductCard(product);
            },
          ),
        ),
        // Sepet
        if (cart.isNotEmpty) _buildCartSummary(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (width < 1200) {
      crossAxisCount = 2; // Küçük ekranlar için 2 ürün
    } else if (width < 1400) {
      crossAxisCount = 3; // Orta ekranlar için 3 ürün
    } else {
      crossAxisCount = 6; // Büyük ekranlar için 6 ürün
    }

    return Row(
      children: [
        // Sol kategori menüsü
        Container(
          width: 250,
          color: Colors.grey[100],
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Kategoriler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == index;
                    return ListTile(
                      leading: Icon(
                        category['icon'],
                        color: isSelected ? Colors.red : Colors.grey[600],
                      ),
                      title: Text(
                        category['name'],
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.red : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () => setState(() => selectedCategory = index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Orta alan - ürünler
        Expanded(
          child: Column(
            children: [
              // Arama kutusu
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Ürün ara...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setState(() => productSearchQuery = value),
                ),
              ),
              // Ürünler grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: getFilteredProducts().length,
                  itemBuilder: (context, index) {
                    final product = getFilteredProducts()[index];
                    return _buildProductCard(product);
                  },
                ),
              ),
            ],
          ),
        ),
        // Sağ sepet paneli
        Container(
          width: 550,
          color: Colors.white,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => addToCart(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Ürün Adı',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_parsePrice(product['price']).toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sepet (${cart.length} ürün)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Toplam: ${cartTotal.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Sepet detayını göster
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sepeti Görüntüle'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Üst başlık alanı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Sol tarafta dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1069',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
                const Spacer(),
                // Sağ tarafta yazdırma türleri ve butonlar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Yazdırma Türleri',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Hesap Fişi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Butonlar
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 20),
                        onPressed: () {},
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.flash_on,
                            color: Colors.white, size: 20),
                        onPressed: () {},
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add,
                                color: Colors.white, size: 20),
                            onPressed: () {},
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'Beklet',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sepet içeriği - dinamik içerik
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Text(
                      'Sepet boş',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            // Ürün bilgileri
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product['name'] ?? 'Ürün',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₺ ${_parsePrice(item.product['price']).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Miktar kontrolleri
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () =>
                                      decreaseQuantity(item.product),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () => addToCart(item.product),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => removeFromCart(item.product),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Özet tablosu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sipariş Toplamı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    Text(
                      '₺ ${cartTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ödenen',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      '₺ 0.00',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İndirim',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                    Text(
                      '₺ 0.00',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kalan Toplam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        '₺ ${cartTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alt navigasyon barı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Nakit butonu
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.attach_money,
                            color: Colors.blue[700], size: 24),
                        onPressed: cart.isEmpty ? null : _saveOrder,
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nakit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Kredi Kartı butonu
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.credit_card,
                            color: Colors.blue[700], size: 24),
                        onPressed: cart.isEmpty ? null : _saveOrder,
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kredi Kartı',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Profil butonu
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.person,
                            color: Colors.blue[700], size: 24),
                        onPressed: () {},
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Daha fazla seçenek butonu
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.more_vert,
                            color: Colors.grey[700], size: 24),
                        onPressed: () {},
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

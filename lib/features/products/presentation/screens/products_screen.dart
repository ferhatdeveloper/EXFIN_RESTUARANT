import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../viewmodel/products_viewmodel.dart';
import '../../../../shared/providers/app_providers.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String searchQuery = '';
  String selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    final productsViewModel = ref.read(productsProvider.notifier);
    productsViewModel.loadProducts();
    productsViewModel.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final productsViewModel = ref.watch(productsProvider);
    final products = productsViewModel.products;
    final categories = productsViewModel.categories;
    final isLoading = productsViewModel.isLoading;
    final error = productsViewModel.error;

    // Filtrelenmiş ürünler
    List<dynamic> filteredProducts = products.where((product) {
      final matchesSearch = searchQuery.isEmpty ||
          product['name']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          product['description']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      final matchesCategory = selectedCategoryId.isEmpty ||
          product['categoryId'].toString() == selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppConstants.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConstants.exfinRed,
        foregroundColor: Colors.white,
        title: const Text('Ürün Yönetimi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(context, productsViewModel),
            tooltip: 'Yeni Ürün Ekle',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtre Alanı
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Arama Kutusu
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Ürün ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Kategori Filtreleri
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Tümü butonu
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Tümü'),
                          selected: selectedCategoryId.isEmpty,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategoryId = '';
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor:
                              AppConstants.exfinRed.withValues(alpha: 0.2),
                          checkmarkColor: AppConstants.exfinRed,
                        ),
                      ),
                      // Kategori butonları
                      ...categories.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category['name'] ?? ''),
                              selected: selectedCategoryId ==
                                  category['id'].toString(),
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategoryId =
                                      selected ? category['id'].toString() : '';
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor:
                                  AppConstants.exfinRed.withValues(alpha: 0.2),
                              checkmarkColor: AppConstants.exfinRed,
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ürün Listesi
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                productsViewModel.refresh();
                              },
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 64,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ürün bulunamadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _buildProductCard(
                                  product, productsViewModel);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product, ProductsViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory, color: Colors.grey),
        ),
        title: Text(
          product['name'] ?? 'Ürün Adı',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product['description'] ?? 'Açıklama yok'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${product['price'] ?? 0} ₺',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.exfinRed,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Stok: ${product['stockQuantity'] ?? 0}',
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditProductDialog(context, product, viewModel);
                break;
              case 'delete':
                _showDeleteConfirmation(context, product, viewModel);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(
      BuildContext context, ProductsViewModel viewModel) {
    // TODO: Implement add product dialog
  }

  void _showEditProductDialog(
      BuildContext context, dynamic product, ProductsViewModel viewModel) {
    // TODO: Implement edit product dialog
  }

  void _showDeleteConfirmation(
      BuildContext context, dynamic product, ProductsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text(
            '${product['name']} ürününü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteProduct(product['id'].toString());
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

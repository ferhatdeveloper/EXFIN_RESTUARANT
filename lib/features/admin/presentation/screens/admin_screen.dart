import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../tables/presentation/screens/tables_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../payment/presentation/screens/payment_screen.dart';
import '../../../kitchen/presentation/screens/kitchen_screen.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;

    int crossAxisCount = isMobile
        ? 2
        : isTablet
            ? 3
            : 4;

    final List<AdminMenuItem> menuItems = [
      AdminMenuItem(
        title: 'Ürün Yönetimi',
        subtitle: 'Ürün ekle, düzenle, sil',
        icon: Icons.inventory_2,
        color: const Color(0xFF2196F3),
        route: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductsScreen()),
        ),
      ),
      AdminMenuItem(
        title: 'Masa Yönetimi',
        subtitle: 'Masa durumları ve rezervasyon',
        icon: Icons.table_bar,
        color: const Color(0xFF4CAF50),
        route: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TablesScreen()),
        ),
      ),
      AdminMenuItem(
        title: 'Sipariş Yönetimi',
        subtitle: 'Sipariş takibi ve yönetimi',
        icon: Icons.receipt_long,
        color: const Color(0xFFFF9800),
        route: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
        ),
      ),
      AdminMenuItem(
        title: 'Raporlar',
        subtitle: 'Satış ve performans raporları',
        icon: Icons.bar_chart,
        color: const Color(0xFF9C27B0),
        route: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        ),
      ),
      AdminMenuItem(
        title: 'Ödeme Yönetimi',
        subtitle: 'Ödeme işlemleri ve takibi',
        icon: Icons.payment,
        color: const Color(0xFF607D8B),
        route: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentScreen()),
        ),
      ),
      AdminMenuItem(
        title: 'Mutfak Yönetimi',
        subtitle: 'Sipariş hazırlama takibi',
        icon: Icons.kitchen,
        color: const Color(0xFF795548),
        route: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KitchenScreen()),
        ),
      ),
      AdminMenuItem(
        title: 'Kullanıcı Yönetimi',
        subtitle: 'Personel ve yetki yönetimi',
        icon: Icons.people,
        color: const Color(0xFFE91E63),
        route: () {
          // TODO: Kullanıcı yönetimi sayfası eklenecek
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Kullanıcı yönetimi yakında eklenecek')),
          );
        },
      ),
      AdminMenuItem(
        title: 'Sistem Ayarları',
        subtitle: 'Genel sistem konfigürasyonu',
        icon: Icons.settings,
        color: const Color(0xFF3F51B5),
        route: () {
          // TODO: Sistem ayarları sayfası eklenecek
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sistem ayarları yakında eklenecek')),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppConstants.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConstants.exfinRed,
        foregroundColor: Colors.white,
        title: const Text('Sistem Yönetimi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Bildirimler eklenecek
            },
            tooltip: 'Bildirimler',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve açıklama
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.exfinRed.withValues(alpha: 0.1),
                    AppConstants.exfinRed.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.exfinRed.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.exfinRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yönetici Paneli',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sistem yönetimi ve konfigürasyon işlemleri',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Modül başlığı
            const Text(
              'Yönetim Modülleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColorPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Modül grid'i
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.1 : 1.3,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return AdminMenuCard(item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback route;

  AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class AdminMenuCard extends StatelessWidget {
  final AdminMenuItem item;

  const AdminMenuCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.route,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withValues(alpha: 0.1),
                item.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColorPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

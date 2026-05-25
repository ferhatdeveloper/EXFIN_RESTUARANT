// Dosya Adı: admin_screen.dart
// Açıklama: RetailEX tarzı Yönetim/Backoffice modülü - Sidebar + Router
// Geliştirici: Ferhat NAS

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import 'product_management_screen.dart';
import 'customer_management_screen.dart';
import 'supplier_management_screen.dart';
import 'supplier_extract_screen.dart';
import 'cash_register_screen.dart';
import 'user_management_screen.dart';
import 'role_management_screen.dart';
import 'stock_management_screen.dart';
import 'invoice_screen.dart';
import 'finance_screens.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String _currentScreen = 'dashboard';
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(lang),
          Expanded(child: _buildContent(lang)),
        ],
      ),
      drawer: isMobile ? Drawer(child: _buildSidebar(lang)) : null,
    );
  }

  Widget _buildSidebar(AppLanguage lang) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarCollapsed ? 64 : 260,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          _buildSidebarHeader(lang),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarSection('ANA MENÜ', [
                  _SidebarItem('dashboard', Icons.dashboard_outlined, 'Dashboard'),
                  _SidebarItem('store-management', Icons.store_outlined, 'Mağaza Yönetimi'),
                ]),
                _buildSidebarSection('MALZEME YÖNETİMİ', [
                  _SidebarItem('products', Icons.inventory_2_outlined, 'Ürünler'),
                  _SidebarItem('categories', Icons.category_outlined, 'Kategoriler'),
                  _SidebarItem('brands', Icons.loyalty_outlined, 'Markalar'),
                  _SidebarItem('units', Icons.straighten_outlined, 'Birimler'),
                  _SidebarItem('stock', Icons.warehouse_outlined, 'Stok Hareketleri'),
                  _SidebarItem('services', Icons.build_outlined, 'Hizmet Kartları'),
                ]),
                _buildSidebarSection('FATURALAR', [
                  _SidebarItem('sales-invoice', Icons.receipt_long_outlined, 'Satış Faturaları'),
                  _SidebarItem('purchase-invoice', Icons.shopping_bag_outlined, 'Alış Faturaları'),
                  _SidebarItem('waybills', Icons.local_shipping_outlined, 'İrsaliyeler'),
                ]),
                _buildSidebarSection('FİNANS YÖNETİMİ', [
                  _SidebarItem('customers', Icons.people_outline, 'Müşteriler'),
                  _SidebarItem('suppliers', Icons.business_outlined, 'Tedarikçiler'),
                  _SidebarItem('cash-registers', Icons.point_of_sale_outlined, 'Kasalar'),
                  _SidebarItem('bank-accounts', Icons.account_balance_outlined, 'Banka Hesapları'),
                  _SidebarItem('expenses', Icons.money_off_outlined, 'Gider Kartları'),
                  _SidebarItem('currency', Icons.currency_exchange_outlined, 'Döviz Kurları'),
                ]),
                _buildSidebarSection('RAPORLAR & ANALİZ', [
                  _SidebarItem('reports', Icons.analytics_outlined, 'Genel Raporlar'),
                  _SidebarItem('profit-report', Icons.trending_up_outlined, 'Kâr Analizi'),
                  _SidebarItem('sales-report', Icons.bar_chart_outlined, 'Satış Raporları'),
                ]),
                _buildSidebarSection('SİSTEM YÖNETİMİ', [
                  _SidebarItem('users', Icons.manage_accounts_outlined, 'Kullanıcılar'),
                  _SidebarItem('roles', Icons.security_outlined, 'Roller & Yetkiler'),
                  _SidebarItem('firm-settings', Icons.business_center_outlined, 'Firma / Dönem'),
                  _SidebarItem('db-settings', Icons.storage_outlined, 'Veritabanı'),
                  _SidebarItem('printer', Icons.print_outlined, 'Yazıcı Ayarları'),
                  _SidebarItem('audit-log', Icons.history_outlined, 'Log & Denetim'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(AppLanguage lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          if (!_sidebarCollapsed) ...[
            const Icon(Icons.apps, color: Color(0xFF60A5FA), size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'YÖNETİM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              _sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
              color: Colors.white54,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title, List<_SidebarItem> items) {
    if (_sidebarCollapsed) {
      return Column(
        children: items.map((item) => _buildSidebarTile(item)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildSidebarTile(item)),
      ],
    );
  }

  Widget _buildSidebarTile(_SidebarItem item) {
    final isActive = _currentScreen == item.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2563EB).withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _sidebarCollapsed ? 16 : 12,
        ),
        leading: Icon(
          item.icon,
          size: 18,
          color: isActive ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
        ),
        title: _sidebarCollapsed
            ? null
            : Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                ),
              ),
        onTap: () => setState(() => _currentScreen = item.id),
      ),
    );
  }

  Widget _buildContent(AppLanguage lang) {
    return Column(
      children: [
        _buildTopBar(lang),
        Expanded(child: _buildScreenContent()),
      ],
    );
  }

  Widget _buildTopBar(AppLanguage lang) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text(
            _getScreenTitle(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_outlined, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _getScreenTitle() {
    const titles = {
      'dashboard': 'Dashboard',
      'products': 'Ürün Yönetimi',
      'categories': 'Kategoriler',
      'brands': 'Markalar',
      'units': 'Birimler',
      'stock': 'Stok Hareketleri',
      'services': 'Hizmet Kartları',
      'sales-invoice': 'Satış Faturaları',
      'purchase-invoice': 'Alış Faturaları',
      'waybills': 'İrsaliyeler',
      'customers': 'Müşteriler',
      'suppliers': 'Tedarikçiler',
      'cash-registers': 'Kasalar',
      'bank-accounts': 'Banka Hesapları',
      'expenses': 'Gider Kartları',
      'currency': 'Döviz Kurları',
      'reports': 'Genel Raporlar',
      'profit-report': 'Kâr Analizi',
      'sales-report': 'Satış Raporları',
      'users': 'Kullanıcı Yönetimi',
      'roles': 'Roller & Yetkiler',
      'firm-settings': 'Firma / Dönem Tanımları',
      'db-settings': 'Veritabanı Ayarları',
      'printer': 'Yazıcı Ayarları',
      'audit-log': 'Log & Denetim',
      'store-management': 'Mağaza Yönetimi',
    };
    return titles[_currentScreen] ?? 'Yönetim';
  }

  Widget _buildScreenContent() {
    switch (_currentScreen) {
      case 'dashboard':
        return _buildDashboardContent();
      case 'products':
        return const ProductManagementScreen();
      case 'customers':
        return const CustomerManagementScreen();
      case 'suppliers':
        return const SupplierManagementScreen();
      case 'cash-registers':
        return const CashRegisterScreen();
      case 'users':
        return const UserManagementScreen();
      case 'roles':
        return const RoleManagementScreen();
      case 'stock':
        return const StockManagementScreen();
      case 'sales-invoice':
        return const InvoiceListScreen(
          invoiceType: 'sales',
          title: 'Satış Faturaları',
        );
      case 'purchase-invoice':
        return const InvoiceListScreen(
          invoiceType: 'purchase',
          title: 'Alış Faturaları',
        );
      case 'waybills':
        return const InvoiceListScreen(
          invoiceType: 'return',
          title: 'İrsaliyeler / İadeler',
        );
      case 'bank-accounts':
        return const BankAccountsScreen();
      case 'expenses':
        return const ExpenseCardsScreen();
      case 'currency':
        return const CurrencyRatesScreen();
      default:
        return _buildPlaceholderContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yönetim Paneli',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistem durumu ve hızlı erişim',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildKpiCard('Toplam Ürün', '34', Icons.inventory_2,
                  const Color(0xFF3B82F6)),
              _buildKpiCard('Müşteriler', '11', Icons.people,
                  const Color(0xFF10B981)),
              _buildKpiCard('Bugün Satış', '2', Icons.receipt,
                  const Color(0xFFF59E0B)),
              _buildKpiCard('Aktif Masalar', '6', Icons.table_restaurant,
                  const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Hızlı İşlemler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickAction('Yeni Ürün', Icons.add_box_outlined,
                  const Color(0xFF3B82F6)),
              _buildQuickAction('Yeni Müşteri', Icons.person_add_outlined,
                  const Color(0xFF10B981)),
              _buildQuickAction('Stok Sayımı', Icons.inventory_outlined,
                  const Color(0xFF8B5CF6)),
              _buildQuickAction('Rapor Oluştur', Icons.assessment_outlined,
                  const Color(0xFFF59E0B)),
              _buildQuickAction('Excel İçe Aktar', Icons.upload_file_outlined,
                  const Color(0xFF06B6D4)),
              _buildQuickAction('Yedek Al', Icons.backup_outlined,
                  const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {},
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            _getScreenTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bu modül yakında eklenecek',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final String id;
  final IconData icon;
  final String label;

  _SidebarItem(this.id, this.icon, this.label);
}

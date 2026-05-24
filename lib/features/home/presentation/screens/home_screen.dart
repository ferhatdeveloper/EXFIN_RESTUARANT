// Dosya Adı: home_screen.dart
// Açıklama: RetailEX tarzı Home Dashboard - Header + Stat kartları + Modül grid
// Geliştirici: Ferhat NAS

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../services/postgres_service.dart';
import '../../../../screens/postgres_settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _occupiedTables = 0;
  int _availableTables = 0;
  int _totalTables = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final tables = await pg.getTables();
      if (mounted) {
        setState(() {
          _totalTables = tables.length;
          _occupiedTables = tables
              .where((t) => t['status'] != 'empty' && t['status'] != null)
              .length;
          _availableTables = _totalTables - _occupiedTables;
        });
      }
    } catch (e) {
      // silently handle
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(lang),
          _buildStatCards(lang),
          Expanded(child: _buildModuleGrid(lang)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLanguage lang) {
    final today = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
      ),
      child: Row(
        children: [
          const Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Rest',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(
                text: 'Ex',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]),
          ),
          const Spacer(),
          _headerInfo(Icons.table_restaurant_outlined,
              '$_totalTables ${L.get('tables', lang)}'),
          const SizedBox(width: 16),
          _headerInfo(Icons.notifications_none,
              '${L.get('waiter_request', lang)}: 0'),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${L.get('fiscal_day', lang)}\n$today',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PostgresSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white70),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatCards(AppLanguage lang) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _statCard(
              color: const Color(0xFFEF4444),
              icon: Icons.close,
              value: '$_occupiedTables',
              label: L.get('occupied', lang),
              sublabel: L.get('table_status', lang),
            ),
          ),
          Expanded(
            flex: 3,
            child: _statCard(
              color: const Color(0xFF2563EB),
              icon: Icons.grid_view_rounded,
              value: '$_availableTables',
              label: L.get('available', lang),
              sublabel: L.get('available_table', lang),
            ),
          ),
          Expanded(
            flex: 4,
            child: _statCard(
              color: const Color(0xFF10B981),
              icon: Icons.access_time,
              value: L.get('close_day', lang),
              label: '',
              sublabel:
                  '${L.get('fiscal_day', lang)} (${DateFormat('dd.MM.yyyy').format(DateTime.now())})',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required Color color,
    required IconData icon,
    required String value,
    required String label,
    required String sublabel,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (label.isNotEmpty)
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                Text(sublabel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid(AppLanguage lang) {
    final modules = [
      _ModuleTile(L.get('service', lang), Icons.restaurant,
          const Color(0xFFEF4444), '/tables'),
      _ModuleTile(L.get('package_service', lang), Icons.delivery_dining,
          const Color(0xFF3B82F6), null),
      _ModuleTile(L.get('retail', lang), Icons.shopping_cart_outlined,
          const Color(0xFF10B981), '/retail'),
      _ModuleTile(L.get('takeaway', lang), Icons.takeout_dining,
          const Color(0xFFF59E0B), null),
      _ModuleTile(L.get('self_service', lang), Icons.self_improvement,
          const Color(0xFF8B5CF6), null),
      _ModuleTile(L.get('orders', lang), Icons.receipt_long_outlined,
          const Color(0xFF06B6D4), '/orders'),
      _ModuleTile(L.get('void_report', lang), Icons.assignment_return,
          const Color(0xFFDC2626), null),
      _ModuleTile(L.get('product_qty', lang), Icons.bar_chart,
          const Color(0xFF7C3AED), null),
      _ModuleTile(L.get('reservations', lang), Icons.calendar_month,
          const Color(0xFFF43F5E), null),
      _ModuleTile(L.get('customers', lang), Icons.people_outline,
          const Color(0xFF059669), null),
      _ModuleTile(L.get('reports', lang), Icons.analytics_outlined,
          const Color(0xFF6366F1), '/reports'),
      _ModuleTile(L.get('stock', lang), Icons.inventory_2_outlined,
          const Color(0xFF64748B), null),
      _ModuleTile(L.get('cash', lang), Icons.point_of_sale,
          const Color(0xFFFB923C), null),
      _ModuleTile(L.get('smart_table', lang), Icons.monitor_outlined,
          const Color(0xFF0EA5E9), '/tables'),
      _ModuleTile(L.get('kitchen', lang), Icons.soup_kitchen_outlined,
          const Color(0xFFEC4899), '/kitchen'),
      _ModuleTile(L.get('recipes', lang), Icons.menu_book_outlined,
          const Color(0xFF475569), null),
      _ModuleTile(L.get('settings', lang), Icons.settings_outlined,
          const Color(0xFF0F172A), null),
      _ModuleTile(L.get('management', lang), Icons.apps,
          const Color(0xFFD946EF), '/admin'),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: modules.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          final m = modules[index];
          return _buildTile(m);
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 6;
    if (width > 1100) return 5;
    if (width > 800) return 4;
    if (width > 500) return 3;
    return 2;
  }

  Widget _buildTile(_ModuleTile m) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: m.route != null ? () => context.go(m.route!) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(m.icon, size: 36, color: m.color),
            const SizedBox(height: 8),
            Text(
              m.label,
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
}

class _ModuleTile {
  final String label;
  final IconData icon;
  final Color color;
  final String? route;

  _ModuleTile(this.label, this.icon, this.color, this.route);
}

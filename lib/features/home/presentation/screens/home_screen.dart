import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import '../../../tables/presentation/screens/tables_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../admin/presentation/screens/admin_screen.dart';
import '../../../../screens/postgres_settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;
    int crossAxisCount = isMobile
        ? 2
        : isTablet
            ? 3
            : 6;

    final String today = DateFormat('d MMMM', 'tr_TR').format(DateTime.now());

    // Kart renkleri ve ikonlar yedekten alındı
    final List<Color> cardColors = [
      Color(0xFFFF5252),
      Color(0xFF448AFF),
      Color(0xFF00E676),
      Color(0xFFFF7043),
      Color(0xFFAB47BC),
      Color(0xFFFF4081),
      Color(0xFF1DE9B6),
      Color(0xFF1976D2),
      Color(0xFF536DFE),
      Color(0xFF69F0AE),
      Color(0xFF90CAF9),
      Color(0xFF7C4DFF),
    ];
    final List<IconData> icons = [
      Icons.phone_iphone,
      Icons.receipt_long,
      Icons.bar_chart,
      Icons.compare_arrows,
      Icons.inventory,
      Icons.settings,
      Icons.admin_panel_settings,
      Icons.directions_car,
      Icons.monitor,
      Icons.insert_chart,
      Icons.storage,
      Icons.account_balance,
    ];
    final List<String> labels = [
      'Servis',
      'Paket Servis',
      'Self Servis',
      'Mobil Servis',
      'Siparişler',
      'Akıllı Masa',
      'Raporlar',
      'Trafik',
      'Muhasebe',
      'PostgreSQL',
      'Yönetim',
      'Monitör',
    ];
    double childAspectRatio = isMobile ? 1.2 : 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('EXFIN REST',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppConstants.exfinRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'PostgreSQL Ayarları',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PostgresSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.light_mode),
            tooltip: 'Tema',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCardsRow(isMobile, today),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: labels.length,
                  itemBuilder: (context, i) {
                    final color = cardColors[i % cardColors.length];
                    return _buildMenuCard(
                      icons[i],
                      labels[i],
                      color,
                      onTap: () {
                        switch (labels[i]) {
                          case 'Servis':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TablesScreen(),
                              ),
                            );
                            break;
                          case 'Siparişler':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrdersScreen(),
                              ),
                            );
                            break;
                          case 'Raporlar':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReportsScreen(),
                              ),
                            );
                            break;
                          case 'Self Servis':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrdersScreen(),
                                settings:
                                    RouteSettings(arguments: 'SelfServis'),
                              ),
                            );
                            break;
                          case 'Yönetim':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminScreen(),
                              ),
                            );
                            break;
                          case 'PostgreSQL':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PostgresSettingsScreen(),
                              ),
                            );
                            break;
                          default:
                            // Diğer kartlar için şimdilik bir şey yapma
                            break;
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCardsRow(bool isMobile, String today) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: isMobile ? 120 : 150,
            child: _modernInfoCard(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFE5B5B), Color(0xFFFF8C8C)]),
              icon: Icons.event_seat,
              iconBg: Colors.white.withValues(alpha: 0.08),
              title: '24 Dolu',
              subtitle: 'Masa bilgisi',
              compact: isMobile,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: isMobile ? 120 : 150,
            child: _modernInfoCard(
              gradient: const LinearGradient(
                  colors: [Color(0xFF4F8CFF), Color(0xFF8CC6FF)]),
              icon: Icons.event_seat,
              iconBg: Colors.white.withValues(alpha: 0.08),
              title: '49 Boş',
              subtitle: 'Masa bilgisi',
              compact: isMobile,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: isMobile ? 120 : 150,
            child: _modernInfoCard(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF5B9E), Color(0xFFFFB6D5)]),
              icon: Icons.calendar_today,
              iconBg: Colors.white.withValues(alpha: 0.08),
              title: today,
              subtitle: 'Gün bilgisi',
              compact: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernInfoCard({
    required LinearGradient gradient,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    bool fullWidth = false,
    bool compact = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      height: compact ? 60 : 90,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            bottom: 8,
            child: Icon(
              icon,
              size: compact ? 32 : 54,
              color: iconBg,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 18, vertical: compact ? 8 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 15 : 22,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 10 : 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String label, Color bgColor,
      {VoidCallback? onTap}) {
    final width = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;
    double iconSize = isMobile
        ? 32
        : isTablet
            ? 38
            : 44;
    double circleSize = isMobile
        ? 48
        : isTablet
            ? 56
            : 64;
    final bool isLight =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: iconSize),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

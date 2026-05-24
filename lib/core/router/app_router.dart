import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/tables/presentation/screens/tables_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/kitchen/presentation/screens/kitchen_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/retail/presentation/screens/retail_screen.dart';
import '../../screens/postgres_settings_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String home = '/home';
  static const String tables = '/tables';
  static const String orders = '/orders';
  static const String kitchen = '/kitchen';
  static const String payment = '/payment';
  static const String products = '/products';
  static const String reports = '/reports';
  static const String admin = '/admin';
  static const String retail = '/retail';
  static const String postgresSettings = '/postgres-settings';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: tables,
        builder: (context, state) => const TablesScreen(),
      ),
      GoRoute(
        path: orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: kitchen,
        builder: (context, state) => const KitchenScreen(),
      ),
      GoRoute(
        path: payment,
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: products,
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: admin,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: retail,
        builder: (context, state) => const RetailScreen(),
      ),
      GoRoute(
        path: postgresSettings,
        builder: (context, state) => const PostgresSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route ${state.uri.path} bulunamadı'),
      ),
    ),
  );

  // Eski MaterialPageRoute yapısını korumak için (geriye uyumluluk)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case tables:
        return MaterialPageRoute(builder: (_) => const TablesScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case kitchen:
        return MaterialPageRoute(builder: (_) => const KitchenScreen());
      case payment:
        return MaterialPageRoute(builder: (_) => const PaymentScreen());
      case products:
        return MaterialPageRoute(builder: (_) => const ProductsScreen());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminScreen());
      case retail:
        return MaterialPageRoute(builder: (_) => const RetailScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} bulunamadı'),
            ),
          ),
        );
    }
  }
}

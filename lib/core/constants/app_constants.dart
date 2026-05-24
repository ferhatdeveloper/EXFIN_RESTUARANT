import 'package:flutter/material.dart';

class AppConstants {
  // Colors - EXFIN Brand Colors
  static const Color exfinDarkBlue =
      Color.fromARGB(255, 5, 79, 153); // Koyu lacivert
  static const Color exfinBlue = Color(0xFF1E40AF); // Lacivert
  static const Color exfinRed = Color(0xFFFF0000); // Tam kırmızı renk
  static const Color exfinLightRed = Color(0xFFFF6B6B); // Açık kırmızı
  static const Color exfinGreen = Color(0xFF10B981); // Yeşil
  static const Color exfinLightGreen = Color(0xFF34D399); // Açık yeşil
  static const Color exfinOrange = Color(0xFFF59E0B); // Turuncu
  static const Color exfinLightOrange = Color(0xFFFBBF24); // Açık turuncu
  static const Color exfinPurple = Color(0xFF8B5CF6); // Mor
  static const Color exfinLightPurple = Color(0xFFA78BFA); // Açık mor
  static const Color exfinTeal = Color(0xFF14B8A6); // Turkuaz
  static const Color exfinLightTeal = Color(0xFF5EEAD4); // Açık turkuaz
  static const Color exfinPink = Color(0xFFEC4899); // Pembe
  static const Color exfinLightPink = Color(0xFFF472B6); // Açık pembe
  static const Color exfinLightBlue = Color(0xFF3498DB); // Açık mavi
  static const Color exfinTabGreen =
      Color(0xFF66BB6A); // TabBar için açık yeşil
  static const Color surfaceColor = Color(0xFFF9FAFB);
  static const Color textColorPrimary = Color(0xFF1F2937);
  static const Color textColorSecondary = Color(0xFF6B7280);
  static const Color menuBackgroundColor = Color(0xFF4A6583);

  // Storage
  static const String storageBox = 'exfin_rest_storage';
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';

  // API Endpoints - PostgREST varsayılanları
  static const String defaultApiBaseUrl = 'http://localhost:3002';
  static const String defaultSignalRHubUrl = 'http://localhost:5000/orderHub';
  static const String defaultAuthEndpoint = '$defaultApiBaseUrl/rpc';

  // App Configuration
  static const String appName = 'EXFIN Restaurant';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.exfin.exfin_rest';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Currency
  static const String defaultCurrency = 'TRY';
  static const String currencySymbol = '₺';

  // Tax Rate
  static const double defaultTaxRate = 0.18; // %18 KDV

  // Order Status
  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'served',
    'completed',
    'cancelled',
  ];

  // Table Status
  static const List<String> tableStatuses = [
    'available',
    'occupied',
    'reserved',
    'cleaning',
  ];

  // User Roles
  static const List<String> userRoles = [
    'admin',
    'waiter',
    'kitchen',
    'cashier',
  ];

  // Payment Methods
  static const List<String> paymentMethods = ['cash', 'card', 'qr', 'split'];

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double xsSpacing = 4.0;
  static const double smSpacing = 8.0;
  static const double mdSpacing = 16.0;
  static const double lgSpacing = 24.0;
  static const double xlSpacing = 32.0;

  // Border Radius
  static const double xsRadius = 4.0;
  static const double smRadius = 8.0;
  static const double mdRadius = 12.0;
  static const double lgRadius = 16.0;
  static const double xlRadius = 24.0;

  // Elevation
  static const double xsElevation = 1.0;
  static const double smElevation = 2.0;
  static const double mdElevation = 4.0;
  static const double lgElevation = 8.0;
  static const double xlElevation = 16.0;
}

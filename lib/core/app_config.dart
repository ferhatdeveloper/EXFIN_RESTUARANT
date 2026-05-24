class AppConfig {
  static const String appName = 'EXFIN_REST';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String defaultApiUrl = 'http://localhost:8080';
  static const String graphqlEndpoint = '/v1/graphql';

  // Supported Languages
  static const List<String> supportedLanguages = ['tr', 'en', 'ar', 'ku'];
  static const String defaultLanguage = 'tr';

  // Theme Configuration
  static const bool enableDarkMode = true;

  // Printer Configuration
  static const int printerTimeout = 5000; // milliseconds

  // File Upload Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
}

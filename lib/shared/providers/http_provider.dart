import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/postgres_service.dart';

// PostgreSQL Service Provider
final postgresServiceProvider = Provider<PostgresService>((ref) {
  return PostgresService();
});

// PostgreSQL Connection Status Provider
final postgresConnectionProvider = Provider<bool>((ref) {
  return false; // Başlangıçta bağlantı yok
});

// PostgreSQL Settings Provider
final postgresSettingsProvider = Provider<Map<String, dynamic>?>((ref) {
  return null; // Başlangıçta ayar yok
});

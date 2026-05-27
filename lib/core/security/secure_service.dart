import 'dart:async';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class SecurePostgresService {
  static final SecurePostgresService _instance = SecurePostgresService._();
  factory SecurePostgresService() => _instance;
  SecurePostgresService._();

  PostgreSQLConnection? _connection;
  final Logger _logger = Logger();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _queryTimeout = Duration(seconds: 15);

  String get _host => dotenv.env['PG_HOST'] ?? 'localhost';
  int get _port => int.tryParse(dotenv.env['PG_PORT'] ?? '5432') ?? 5432;
  String get _database => dotenv.env['PG_DATABASE'] ?? 'exfin_db';
  String get _username => dotenv.env['PG_USERNAME'] ?? 'postgres';
  String get _password => dotenv.env['PG_PASSWORD'] ?? '';
  String get firmNr => dotenv.env['FIRM_NR'] ?? '001';

  Future<bool> initialize() async {
    try {
      if (_isConnected && _connection != null) return true;
      _connection = PostgreSQLConnection(_host, _port, _database,
          username: _username, password: _password, timeoutInSeconds: 10);
      await _connection!.open();
      _isConnected = true;
      _retryCount = 0;
      return true;
    } catch (e) {
      _logger.e('Bağlantı hatası: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<bool> _ensureConnection() async {
    if (_isConnected && _connection != null) return true;
    if (_retryCount >= _maxRetries) { _retryCount = 0; return false; }
    _retryCount++;
    return await initialize();
  }

  Future<List<Map<String, dynamic>>> safeQuery(String sql, {Map<String, dynamic>? params}) async {
    if (!await _ensureConnection()) throw AppException('Veritabanı bağlantısı kurulamadı');
    try {
      final results = await _connection!.query(sql, substitutionValues: params).timeout(_queryTimeout);
      return results.map((row) { final m = <String, dynamic>{}; m.addAll(row.toColumnMap()); return m; }).toList();
    } on TimeoutException { throw AppException('Sorgu zaman aşımına uğradı'); }
    on PostgreSQLException catch (e) { throw AppException('Veritabanı hatası: ${e.message}'); }
    catch (e) {
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        _isConnected = false; _connection = null;
        if (await _ensureConnection()) return safeQuery(sql, params: params);
      }
      rethrow;
    }
  }

  Future<T> transaction<T>(Future<T> Function(PostgreSQLExecutionContext ctx) action) async {
    if (!await _ensureConnection()) throw AppException('Transaction başlatılamadı');
    try { return await _connection!.transaction((ctx) async => await action(ctx)); }
    on PostgreSQLException catch (e) { throw AppException('İşlem başarısız (rollback): ${e.message}'); }
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
    _isConnected = false;
  }
}

class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class SessionManager {
  static final SessionManager _instance = SessionManager._();
  factory SessionManager() => _instance;
  SessionManager._();

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get username => _currentUser?['username']?.toString();
  String? get fullName => _currentUser?['fullName']?.toString();
  String? get roleName => _currentUser?['roleName']?.toString();
  List<dynamic>? get permissions => _currentUser?['rolePermissions'] as List?;

  DateTime? _loginTime;
  Timer? _inactivityTimer;
  VoidCallback? onSessionExpired;
  static const Duration _timeout = Duration(minutes: 30);

  void setUser(Map<String, dynamic> user) {
    _currentUser = user;
    _loginTime = DateTime.now();
    _resetTimer();
  }

  void clearUser() {
    _currentUser = null;
    _loginTime = null;
    _inactivityTimer?.cancel();
  }

  void recordActivity() => _resetTimer();

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeout, () { clearUser(); onSessionExpired?.call(); });
  }

  bool hasPermission(String perm) {
    if (permissions == null) return false;
    if (permissions!.contains('*')) return true;
    return permissions!.any((p) => p.toString() == perm || p.toString().startsWith('${perm.split('.').first}.*'));
  }
}

class ErrorHandler {
  static void show(BuildContext context, dynamic error, {String? fallback}) {
    final msg = error is AppException ? error.message : (fallback ?? 'Beklenmeyen hata oluştu');
    debugPrint('❌ $error');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  static Future<T?> tryAsync<T>(Future<T> Function() action, {BuildContext? context, String? errorMsg}) async {
    try { return await action(); }
    catch (e) { if (context != null) show(context, e, fallback: errorMsg); return null; }
  }
}

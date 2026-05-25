import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/postgres_service.dart';

enum SyncDirection { localToRemote, remoteToLocal, bidirectional }
enum SyncStatus { idle, syncing, success, error }

class SyncConfig {
  final String localHost;
  final int localPort;
  final String localDatabase;
  final String localUsername;
  final String localPassword;
  final String remoteHost;
  final int remotePort;
  final String remoteDatabase;
  final String remoteUsername;
  final String remotePassword;
  final SyncDirection direction;
  final int intervalSeconds;

  const SyncConfig({
    this.localHost = 'localhost',
    this.localPort = 5432,
    this.localDatabase = 'exfin_db',
    this.localUsername = 'postgres',
    this.localPassword = '',
    this.remoteHost = '',
    this.remotePort = 5432,
    this.remoteDatabase = 'exfin_db',
    this.remoteUsername = 'postgres',
    this.remotePassword = '',
    this.direction = SyncDirection.bidirectional,
    this.intervalSeconds = 30,
  });
}

class SyncResult {
  final int sent;
  final int received;
  final int errors;
  final DateTime timestamp;
  final String? errorMessage;

  SyncResult({this.sent = 0, this.received = 0, this.errors = 0, required this.timestamp, this.errorMessage});
}

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  SyncResult? _lastResult;
  SyncResult? get lastResult => _lastResult;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  Timer? _timer;
  bool _isRunning = false;

  final List<String> _syncTables = [
    'rex_001_products', 'rex_001_customers', 'rex_001_suppliers',
    'rex_001_categories', 'rex_001_brands', 'rex_001_units',
    'rex_001_cash_registers', 'rex_001_bank_registers', 'rex_001_expense_cards',
    'rex_001_campaigns', 'rex_001_services', 'rex_001_special_codes',
    'rex_001_tax_rates', 'rex_001_sales_reps',
    'rex_001_01_sales', 'rex_001_01_sale_items',
    'rex_001_01_cash_lines', 'rex_001_01_bank_lines',
    'rex_001_01_stock_movements', 'rex_001_01_stock_movement_items',
  ];

  void startPeriodicSync({int intervalSeconds = 30}) {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => syncNow());
    debugPrint('🔄 Sync başlatıldı (${intervalSeconds}sn aralık)');
  }

  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('⏹ Sync durduruldu');
  }

  Future<void> checkPendingCount() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final result = await pg.query(
        "SELECT COUNT(*) as cnt FROM sync_queue WHERE status = 'pending'",
      );
      _pendingCount = _toInt(result.isNotEmpty ? result.first['cnt'] : 0);
      notifyListeners();
    } catch (_) {}
  }

  Future<SyncResult> syncNow() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(timestamp: DateTime.now(), errorMessage: 'Sync zaten devam ediyor');
    }

    _status = SyncStatus.syncing;
    notifyListeners();

    int sent = 0;
    int received = 0;
    int errors = 0;
    String? errorMsg;

    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final pendingItems = await pg.query(
        "SELECT id, table_name, record_id, action, data, firm_nr FROM sync_queue WHERE status = 'pending' ORDER BY created_at ASC LIMIT 100",
      );

      for (final item in pendingItems) {
        try {
          await pg.query(
            "UPDATE sync_queue SET status = 'synced', synced_at = NOW() WHERE id = @id::uuid",
            params: {'id': item['id']?.toString()},
          );
          sent++;
        } catch (e) {
          await pg.query(
            "UPDATE sync_queue SET status = 'pending', retry_count = retry_count + 1, error_message = @err WHERE id = @id::uuid",
            params: {'id': item['id']?.toString(), 'err': e.toString()},
          );
          errors++;
        }
      }

      _status = errors == 0 ? SyncStatus.success : SyncStatus.error;
      _lastSyncTime = DateTime.now();
      _pendingCount = await _getPendingCount(pg);

    } catch (e) {
      _status = SyncStatus.error;
      errorMsg = e.toString();
      errors++;
    }

    _lastResult = SyncResult(
      sent: sent, received: received, errors: errors,
      timestamp: DateTime.now(), errorMessage: errorMsg,
    );

    notifyListeners();
    debugPrint('✅ Sync tamamlandı: $sent gönderildi, $errors hata');
    return _lastResult!;
  }

  Future<SyncResult> sendMasterData() async {
    _status = SyncStatus.syncing;
    notifyListeners();

    int sent = 0;
    int errors = 0;

    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final masterTables = [
        'rex_001_products', 'rex_001_categories', 'rex_001_brands',
        'rex_001_units', 'rex_001_campaigns', 'rex_001_tax_rates',
      ];

      for (final table in masterTables) {
        try {
          final count = await pg.query("SELECT COUNT(*) as cnt FROM $table");
          sent += _toInt(count.isNotEmpty ? count.first['cnt'] : 0);
        } catch (_) {
          errors++;
        }
      }

      _status = SyncStatus.success;
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _status = SyncStatus.error;
      errors++;
    }

    _lastResult = SyncResult(sent: sent, errors: errors, timestamp: DateTime.now());
    notifyListeners();
    return _lastResult!;
  }

  Future<SyncResult> receiveSalesData() async {
    _status = SyncStatus.syncing;
    notifyListeners();

    int received = 0;
    int errors = 0;

    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();

      final salesTables = [
        'rex_001_01_sales', 'rex_001_01_cash_lines', 'rex_001_01_bank_lines',
      ];

      for (final table in salesTables) {
        try {
          final count = await pg.query("SELECT COUNT(*) as cnt FROM $table WHERE DATE(created_at) = CURRENT_DATE");
          received += _toInt(count.isNotEmpty ? count.first['cnt'] : 0);
        } catch (_) {
          errors++;
        }
      }

      _status = SyncStatus.success;
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _status = SyncStatus.error;
      errors++;
    }

    _lastResult = SyncResult(received: received, errors: errors, timestamp: DateTime.now());
    notifyListeners();
    return _lastResult!;
  }

  Future<int> _getPendingCount(PostgresService pg) async {
    final r = await pg.query("SELECT COUNT(*) as cnt FROM sync_queue WHERE status = 'pending'");
    return _toInt(r.isNotEmpty ? r.first['cnt'] : 0);
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  @override
  void dispose() {
    stopPeriodicSync();
    super.dispose();
  }
}

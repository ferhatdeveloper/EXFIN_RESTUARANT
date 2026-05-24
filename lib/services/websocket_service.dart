import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'database_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _clientId;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  // Stream getters
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  // Connection status
  bool get isConnected => _isConnected;
  String? get clientId => _clientId;

  /// WebSocket bağlantısını başlat
  Future<void> connect({String? baseUrl, String? clientId}) async {
    try {
      // SQLite'dan API ayarlarını al
      String wsBaseUrl = baseUrl ?? 'ws://localhost:5000/ws';

      try {
        final dbService = DatabaseService();
        final apiSettings = await dbService.getApiSettings();

        if (apiSettings != null && apiSettings['base_url'] != null) {
          // HTTP URL'yi WebSocket URL'ye çevir
          final httpUrl = apiSettings['base_url'] as String;
          wsBaseUrl = httpUrl
              .replaceFirst('http://', 'ws://')
              .replaceFirst('https://', 'wss://');
          if (!wsBaseUrl.endsWith('/ws')) {
            wsBaseUrl = '$wsBaseUrl/ws';
          }
          debugPrint('✅ SQLite\'dan WebSocket URL alındı: $wsBaseUrl');
        } else {
          debugPrint(
              '⚠️ SQLite\'da ayar yok, varsayılan WebSocket URL kullanılıyor');
        }
      } catch (e) {
        debugPrint(
            '❌ SQLite hatası, varsayılan WebSocket URL kullanılıyor: $e');
      }

      final url = '$wsBaseUrl/${clientId ?? 'flutter_client'}';

      _channel = WebSocketChannel.connect(Uri.parse(url));
      _clientId =
          clientId ?? 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';

      // Bağlantı durumunu dinle
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _handleError(error);
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      _isConnected = true;
      _connectionStatusController.add('connected');

      debugPrint('🔌 WebSocket bağlantısı başarılı: $url');
    } catch (e) {
      debugPrint('❌ WebSocket bağlantı hatası: $e');
      _connectionStatusController.add('error');
      rethrow;
    }
  }

  /// WebSocket bağlantısını kapat
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close(status.goingAway);
      _isConnected = false;
      _clientId = null;
      _connectionStatusController.add('disconnected');
      debugPrint('🔌 WebSocket bağlantısı kapatıldı');
    } catch (e) {
      debugPrint('❌ WebSocket kapatma hatası: $e');
    }
  }

  /// Mesaj gönder
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket bağlantısı yok');
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      debugPrint('📤 WebSocket mesajı gönderildi: $jsonMessage');
    } catch (e) {
      debugPrint('❌ WebSocket mesaj gönderme hatası: $e');
      rethrow;
    }
  }

  /// Database'e abone ol
  Future<void> subscribeToDatabase(String database) async {
    await sendMessage({
      'type': 'subscribe_database',
      'database': database,
    });
  }

  /// Tabloya abone ol
  Future<void> subscribeToTable(String table) async {
    await sendMessage({
      'type': 'subscribe_table',
      'table': table,
    });
  }

  /// Kullanıcıya abone ol
  Future<void> subscribeToUser(String userId) async {
    await sendMessage({
      'type': 'subscribe_user',
      'user_id': userId,
    });
  }

  /// Database aboneliğinden çık
  Future<void> unsubscribeFromDatabase(String database) async {
    await sendMessage({
      'type': 'unsubscribe_database',
      'database': database,
    });
  }

  /// Tablo aboneliğinden çık
  Future<void> unsubscribeFromTable(String table) async {
    await sendMessage({
      'type': 'unsubscribe_table',
      'table': table,
    });
  }

  /// Kullanıcı aboneliğinden çık
  Future<void> unsubscribeFromUser(String userId) async {
    await sendMessage({
      'type': 'unsubscribe_user',
      'user_id': userId,
    });
  }

  /// Ping gönder
  Future<void> ping() async {
    await sendMessage({
      'type': 'ping',
    });
  }

  /// İstatistikleri al
  Future<void> getStats() async {
    await sendMessage({
      'type': 'get_stats',
    });
  }

  /// Gelen mesajları işle
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString()) as Map<String, dynamic>;
      debugPrint('📥 WebSocket mesajı alındı: $message');
      _messageController.add(message);
    } catch (e) {
      debugPrint('❌ WebSocket mesaj işleme hatası: $e');
    }
  }

  /// Hata durumunu işle
  void _handleError(dynamic error) {
    debugPrint('❌ WebSocket hatası: $error');
    _isConnected = false;
    _connectionStatusController.add('error');
  }

  /// Bağlantı kesme durumunu işle
  void _handleDisconnect() {
    debugPrint('🔌 WebSocket bağlantısı kesildi');
    _isConnected = false;
    _connectionStatusController.add('disconnected');
  }

  /// Belirli tip mesajları dinle
  Stream<Map<String, dynamic>> listenToEventType(String eventType) {
    return messageStream.where((message) => message['type'] == eventType);
  }

  /// Database olaylarını dinle
  Stream<Map<String, dynamic>> listenToDatabaseEvents(String database) {
    return messageStream.where((message) =>
        message['type'] == 'database_event' && message['database'] == database);
  }

  /// Tablo olaylarını dinle
  Stream<Map<String, dynamic>> listenToTableEvents(String table) {
    return messageStream.where((message) =>
        message['type'] == 'table_event' && message['table'] == table);
  }

  /// Kullanıcı olaylarını dinle
  Stream<Map<String, dynamic>> listenToUserEvents(String userId) {
    return messageStream.where((message) =>
        message['type'] == 'user_event' && message['user_id'] == userId);
  }

  /// Sistem olaylarını dinle
  Stream<Map<String, dynamic>> listenToSystemEvents() {
    return messageStream.where((message) => message['type'] == 'system_event');
  }

  /// Servisi temizle
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStatusController.close();
  }
}

// Realtime event types
class RealtimeEventTypes {
  static const String databaseEvent = 'database_event';
  static const String tableEvent = 'table_event';
  static const String userEvent = 'user_event';
  static const String systemEvent = 'system_event';
  static const String connectionEstablished = 'connection_established';
  static const String subscriptionConfirmed = 'subscription_confirmed';
  static const String unsubscriptionConfirmed = 'unsubscription_confirmed';
  static const String pong = 'pong';
  static const String connectionStats = 'connection_stats';
  static const String error = 'error';
}

// Database event types
class DatabaseEventTypes {
  static const String tableUpdated = 'table_updated';
  static const String recordCreated = 'record_created';
  static const String recordUpdated = 'record_updated';
  static const String recordDeleted = 'record_deleted';
  static const String databaseConnected = 'database_connected';
  static const String databaseDisconnected = 'database_disconnected';
}

// Table event types
class TableEventTypes {
  static const String recordCreated = 'record_created';
  static const String recordUpdated = 'record_updated';
  static const String recordDeleted = 'record_deleted';
  static const String tableRefreshed = 'table_refreshed';
}

// User event types
class UserEventTypes {
  static const String userLoggedIn = 'user_logged_in';
  static const String userLoggedOut = 'user_logged_out';
  static const String userUpdated = 'user_updated';
  static const String userDeleted = 'user_deleted';
}

// System event types
class SystemEventTypes {
  static const String serverStarted = 'server_started';
  static const String serverStopped = 'server_stopped';
  static const String maintenanceMode = 'maintenance_mode';
  static const String databaseBackup = 'database_backup';
}

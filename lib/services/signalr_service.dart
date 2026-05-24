import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  String? _baseUrl;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // SQLite'dan API ayarlarını al
    try {
      final dbService = DatabaseService();
      final apiSettings = await dbService.getApiSettings();

      if (apiSettings != null && apiSettings['base_url'] != null) {
        _baseUrl = apiSettings['base_url'];
        debugPrint('✅ SQLite\'dan SignalR URL alındı: $_baseUrl');
      } else {
        // SQLite'da ayar yoksa SharedPreferences'tan al
        final prefs = await SharedPreferences.getInstance();
        _baseUrl = prefs.getString('api_base_url') ?? 'http://localhost:5000';
        debugPrint('⚠️ SQLite\'da ayar yok, SharedPreferences kullanılıyor');
      }
    } catch (e) {
      // Hata durumunda SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString('api_base_url') ?? 'http://localhost:5000';
      debugPrint('❌ SQLite hatası, SharedPreferences kullanılıyor: $e');
    }

    // Hub URL'ini oluştur - /api/hub/orderHub formatında
    final hubUrl = '$_baseUrl/api/hub/orderHub';
    debugPrint('🔗 SignalR Hub URL: $hubUrl');

    _hubConnection =
        HubConnectionBuilder().withUrl(hubUrl).withAutomaticReconnect().build();
  }

  Future<void> connect() async {
    if (_hubConnection == null) {
      await initialize();
    }

    try {
      await _hubConnection!.start();
      _isConnected = true;
      debugPrint('✅ SignalR bağlantısı başarılı');
    } catch (e) {
      debugPrint('❌ SignalR bağlantı hatası: $e');
      _isConnected = false;

      // Bağlantı başarısız olursa 10 saniye sonra tekrar dene (daha uzun süre)
      Future.delayed(const Duration(seconds: 10), () {
        if (!_isConnected) {
          debugPrint('🔄 SignalR bağlantısı tekrar deneniyor...');
          connect();
        }
      });
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _isConnected = false;
      debugPrint('SignalR bağlantısı kesildi');
    }
  }

  // Mutfak grubuna katıl
  Future<void> joinKitchenGroup() async {
    if (_hubConnection != null && _isConnected) {
      await _hubConnection!.invoke('JoinKitchenGroup');
      debugPrint('Mutfak grubuna katıldı');
    }
  }

  // Garson grubuna katıl
  Future<void> joinWaiterGroup() async {
    if (_hubConnection != null && _isConnected) {
      await _hubConnection!.invoke('JoinWaiterGroup');
      debugPrint('Garson grubuna katıldı');
    }
  }

  // Kasa grubuna katıl
  Future<void> joinCashierGroup() async {
    if (_hubConnection != null && _isConnected) {
      await _hubConnection!.invoke('JoinCashierGroup');
      debugPrint('Kasa grubuna katıldı');
    }
  }

  // Yeni sipariş dinle
  void onNewOrder(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('NewOrder', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as Map<String, dynamic>);
      }
    });
  }

  // Sipariş oluşturuldu dinle
  void onOrderCreated(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('OrderCreated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          Map<String, dynamic> orderData = {};
          if (arguments[0] is Map<String, dynamic>) {
            orderData = arguments[0] as Map<String, dynamic>;
          }
          callback(orderData);
        } catch (e) {
          debugPrint('❌ OrderCreated callback hatası: $e');
        }
      }
    });
  }

  // Sipariş güncellendi dinle
  void onOrderUpdated(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('OrderUpdated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          Map<String, dynamic> orderData = {};
          if (arguments[0] is Map<String, dynamic>) {
            orderData = arguments[0] as Map<String, dynamic>;
          }
          callback(orderData);
        } catch (e) {
          debugPrint('❌ OrderUpdated callback hatası: $e');
        }
      }
    });
  }

  // Sipariş silindi dinle
  void onOrderDeleted(Function(int) callback) {
    _hubConnection?.on('OrderDeleted', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          // orderId'yi güvenli şekilde int'e çevir
          int orderId;
          if (arguments[0] is int) {
            orderId = arguments[0] as int;
          } else if (arguments[0] is String) {
            orderId = int.tryParse(arguments[0] as String) ?? 0;
          } else {
            orderId = 0;
          }

          callback(orderId);
        } catch (e) {
          debugPrint('❌ OrderDeleted callback hatası: $e');
        }
      }
    });
  }

  // Sipariş durumu değişikliği dinle
  void onOrderStatusChanged(Function(int, String) callback) {
    _hubConnection?.on('OrderStatusChanged', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          // orderId'yi güvenli şekilde int'e çevir
          int orderId;
          if (arguments[0] is int) {
            orderId = arguments[0] as int;
          } else if (arguments[0] is String) {
            orderId = int.tryParse(arguments[0] as String) ?? 0;
          } else {
            orderId = 0;
          }

          // status'u güvenli şekilde String'e çevir
          String status = arguments[1]?.toString() ?? '';

          callback(orderId, status);
        } catch (e) {
          debugPrint('❌ OrderStatusChanged callback hatası: $e');
        }
      }
    });
  }

  // Masa durumu değişikliği dinle
  void onTableStatusChanged(Function(int, String) callback) {
    _hubConnection?.on('TableStatusChanged', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          // tableId'yi güvenli şekilde int'e çevir
          int tableId;
          if (arguments[0] is int) {
            tableId = arguments[0] as int;
          } else if (arguments[0] is String) {
            tableId = int.tryParse(arguments[0] as String) ?? 0;
          } else {
            tableId = 0;
          }

          // status'u güvenli şekilde String'e çevir
          String status = arguments[1]?.toString() ?? '';

          callback(tableId, status);
        } catch (e) {
          debugPrint('❌ TableStatusChanged callback hatası: $e');
        }
      }
    });
  }

  // Masa güncellendi dinle
  void onTableUpdated(Function(int, Map<String, dynamic>) callback) {
    _hubConnection?.on('TableUpdated', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          // tableId'yi güvenli şekilde int'e çevir
          int tableId;
          if (arguments[0] is int) {
            tableId = arguments[0] as int;
          } else if (arguments[0] is String) {
            tableId = int.tryParse(arguments[0] as String) ?? 0;
          } else {
            tableId = 0;
          }

          // tableData'yı güvenli şekilde Map'e çevir
          Map<String, dynamic> tableData = {};
          if (arguments[1] is Map<String, dynamic>) {
            tableData = arguments[1] as Map<String, dynamic>;
          }

          callback(tableId, tableData);
        } catch (e) {
          debugPrint('❌ TableUpdated callback hatası: $e');
        }
      }
    });
  }

  // Yeni masa oluşturuldu dinle
  void onTableCreated(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('TableCreated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          Map<String, dynamic> tableData = {};
          if (arguments[0] is Map<String, dynamic>) {
            tableData = arguments[0] as Map<String, dynamic>;
          }
          callback(tableData);
        } catch (e) {
          debugPrint('❌ TableCreated callback hatası: $e');
        }
      }
    });
  }

  // Masa silindi dinle
  void onTableDeleted(Function(int) callback) {
    _hubConnection?.on('TableDeleted', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          // tableId'yi güvenli şekilde int'e çevir
          int tableId;
          if (arguments[0] is int) {
            tableId = arguments[0] as int;
          } else if (arguments[0] is String) {
            tableId = int.tryParse(arguments[0] as String) ?? 0;
          } else {
            tableId = 0;
          }

          callback(tableId);
        } catch (e) {
          debugPrint('❌ TableDeleted callback hatası: $e');
        }
      }
    });
  }

  // Genel mesaj dinle
  void onReceiveMessage(Function(String) callback) {
    _hubConnection?.on('ReceiveMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as String);
      }
    });
  }

  // Mesaj gönder
  Future<void> sendMessage(String message) async {
    if (_hubConnection != null && _isConnected) {
      await _hubConnection!.invoke('SendMessage', args: [message]);
    }
  }
}

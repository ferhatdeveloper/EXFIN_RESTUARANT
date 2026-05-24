# ExfinRestAPI - API Kullanım Dokümantasyonu

## 📋 İçindekiler
- [Genel Bilgiler](#genel-bilgiler)
- [Kurulum](#kurulum)
- [Authentication](#authentication)
- [Endpoint Kategorileri](#endpoint-kategorileri)
- [CRUD İşlemleri](#crud-işlemleri)
- [Multi-Database Desteği](#multi-database-desteği)
- [WebSocket Desteği](#websocket-desteği)
- [Developer Mode](#developer-mode)
- [Migration Sistemi](#migration-sistemi)
- [Hata Yönetimi](#hata-yönetimi)
- [Örnek Kullanımlar](#örnek-kullanımlar)

## 🚀 Genel Bilgiler

**API Adı:** ExfinRestAPI - Multi-Database FastAPI Backend  
**Versiyon:** 3.2.0  
**Base URL:** `http://localhost:8000`  
**Swagger UI:** `http://localhost:8000/docs`  
**ReDoc:** `http://localhost:8000/redoc`

### Temel Özellikler
- ✅ Multi-Database Support (PostgreSQL, MySQL, MSSQL, SQLite)
- ✅ Identity Key Yönetimi
- ✅ Dynamic CRUD Operations
- ✅ Table Relationship Management
- ✅ Soft Delete Support
- ✅ JWT Authentication
- ✅ Real-time WebSocket Desteği
- ✅ Developer Mode Kontrolü
- ✅ Database Migration Sistemi

## 🔧 Kurulum

### Gereksinimler
```bash
pip install -r requirements.txt
```

### Konfigürasyon Dosyaları

#### 1. db_config.json
```json
{
  "default_database": "DatabaseA",
  "transfer_interval_minutes": 1,
  "developer_mode": true,
  "databases": [
    {
      "Name": "DatabaseA",
      "Type": "MSSQL",
      "Server": ".",
      "Database": "EXFIN_MERKEZ",
      "Username": "sa",
      "Password": "Logo123"
    },
    {
      "Name": "DatabaseB",
      "Type": "MSSQL",
      "Server": ".",
      "Database": "EXFIN_MERKEZ_B",
      "Username": "sa",
      "Password": "Logo123"
    }
  ]
}
```

#### 2. table_schema.json
```json
{
  "identity_keys": {
    "FATURA": {
      "primary_keys": ["FATURA_ID", "FATURA_KODU"],
      "identity_columns": ["FATURA_ID"],
      "unique_columns": ["FATURA_KODU"]
    }
  },
  "relationships": {
    "FATURA": {
      "FATURA_KODU": {
        "target_table": "FATURA_DETAY",
        "target_column": "FATURA_KODU",
        "type": "one_to_many"
      }
    }
  },
  "settings": {
    "soft_delete_column": "DURUM",
    "soft_delete_value": "PASIF"
  }
}
```

### Uygulamayı Başlatma
```bash
python main.py
```

## 🔐 Authentication

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "password",
  "database": "DatabaseA"
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user": {
    "username": "admin",
    "database": "DatabaseA"
  }
}
```

### Token Kullanımı
```http
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

## 📊 Endpoint Kategorileri

### 1. Sistem Endpoint'leri

#### Ana Sayfa
```http
GET /
```

#### Sağlık Kontrolü
```http
GET /health
```

#### Sistem Durumu
```http
GET /api/status?database=DatabaseA
```

**Response:**
```json
{
  "categories": 5,
  "products": 150,
  "tables": 25,
  "users": 50,
  "total": 230,
  "message": "API çalışıyor",
  "database": "DatabaseA",
  "available_databases": ["DatabaseA", "DatabaseB"],
  "available_tables": ["FATURA", "FATURA_DETAY", "MUSTERI", "URUN"],
  "developer_mode": true
}
```

### 2. Database Yönetimi

#### Database Listesi
```http
GET /api/databases
```

#### Database Bağlantı Testi
```http
POST /api/databases/{db_name}/test
```

### 3. Developer Mode Yönetimi

#### Developer Mode Durumu
```http
GET /api/developer/mode
```

#### Developer Mode Değiştirme
```http
POST /api/developer/mode
Content-Type: application/json

{
  "enabled": true
}
```

### 4. Migration Sistemi

#### Migration Çalıştırma
```http
POST /api/migrations/run/{db_name}
```

#### Migration Durumu
```http
GET /api/migrations/status/{db_name}
```

#### Database Oluşturma
```http
POST /api/migrations/create-database/{db_name}
```

## 🗄️ CRUD İşlemleri

### 1. Veri Alma

#### Tablo Verilerini Alma
```http
GET /api/tables/{table_name}/data?database=DatabaseA&page=1&page_size=50
```

**Parametreler:**
- `table_name`: Tablo adı
- `database`: Database adı (opsiyonel)
- `page`: Sayfa numarası (varsayılan: 1)
- `page_size`: Sayfa başına kayıt sayısı (varsayılan: 50, max: 1000)
- `include_related`: İlişkili verileri dahil et (opsiyonel)
- `filters`: JSON formatında filtreler (opsiyonel)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "FATURA_ID": 1,
      "FATURA_KODU": "FAT-2024-001",
      "FATURA_TARIHI": "2024-01-01T00:00:00",
      "MUSTERI_ID": 1,
      "TOPLAM_TUTAR": 1000.00,
      "DURUM": "AKTIF"
    }
  ],
  "total": 150,
  "page": 1,
  "page_size": 50,
  "total_pages": 3,
  "has_identity_config": true,
  "main_primary_key": "FATURA_ID"
}
```

### 2. Veri Ekleme

#### Yeni Kayıt Ekleme
```http
POST /api/tables/{table_name}/data?database=DatabaseA
Content-Type: application/json

{
  "data": {
    "FATURA_KODU": "FAT-2024-002",
    "FATURA_TARIHI": "2024-01-02",
    "MUSTERI_ID": 2,
    "TOPLAM_TUTAR": 1500.00,
    "DURUM": "AKTIF"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Veri başarıyla eklendi",
  "new_id": 2
}
```

### 3. Veri Güncelleme

#### Kayıt Güncelleme
```http
PUT /api/tables/{table_name}/data/{record_id}?database=DatabaseA
Content-Type: application/json

{
  "data": {
    "TOPLAM_TUTAR": 1200.00,
    "DURUM": "AKTIF"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Veri başarıyla güncellendi"
}
```

### 4. Veri Silme

#### Soft Delete ile Silme
```http
DELETE /api/tables/{table_name}/data/{record_id}?database=DatabaseA&soft_delete=true
```

**Response:**
```json
{
  "success": true,
  "message": "Veri başarıyla silindi (soft delete)"
}
```

## 🔄 Multi-Database Desteği

### Aynı Anda Birden Fazla Database'e Bağlanma

#### Farklı Database'lerden Veri Alma
```bash
# DatabaseA'dan FATURA verileri
curl "http://localhost:8000/api/tables/FATURA/data?database=DatabaseA&page=1&page_size=5"

# DatabaseB'den FATURA verileri
curl "http://localhost:8000/api/tables/FATURA/data?database=DatabaseB&page=1&page_size=5"
```

#### Database Karşılaştırma
```bash
# DatabaseA'dan MUSTERI tablosu
curl "http://localhost:8000/api/tables/MUSTERI/data?database=DatabaseA"

# DatabaseB'den URUN tablosu
curl "http://localhost:8000/api/tables/URUN/data?database=DatabaseB"
```

### Database Bağlantı Testi
```bash
# DatabaseA bağlantı testi
curl -X POST "http://localhost:8000/api/databases/DatabaseA/test"

# DatabaseB bağlantı testi
curl -X POST "http://localhost:8000/api/databases/DatabaseB/test"
```

## 🔌 WebSocket Desteği

### WebSocket Bağlantısı
```javascript
// WebSocket bağlantısı
const ws = new WebSocket('ws://localhost:8000/ws/client123');

// Database değişikliklerini dinle
ws.send(JSON.stringify({
  tip: "subscribe_database",
  database: "DatabaseA"
}));

// Tablo değişikliklerini dinle
ws.send(JSON.stringify({
  tip: "subscribe_table",
  table: "FATURA"
}));

// Kullanıcı bazlı bildirimleri dinle
ws.send(JSON.stringify({
  tip: "subscribe_user",
  user_id: "user123"
}));
```

### WebSocket Mesaj Tipleri

#### Subscription Mesajları
```json
{
  "tip": "subscribe_database",
  "database": "DatabaseA"
}
```

```json
{
  "tip": "subscribe_table",
  "table": "FATURA"
}
```

```json
{
  "tip": "subscribe_user",
  "user_id": "user123"
}
```

#### Bildirim Mesajları
```json
{
  "tip": "database_change",
  "event_type": "table_updated",
  "data": {
    "table": "FATURA",
    "operation": "INSERT",
    "record_count": 1
  }
}
```

```json
{
  "tip": "table_change",
  "event_type": "record_created",
  "data": {
    "table": "FATURA",
    "database": "DatabaseA",
    "record": {"id": 1, "musteri_id": 1},
    "operation": "INSERT"
  }
}
```

### WebSocket İstatistikleri
```http
GET /api/websocket/stats
```

## 🛠️ Developer Mode

### Developer Mode Kontrolü
```http
GET /api/developer/mode
```

**Response:**
```json
{
  "developer_mode": true,
  "swagger_available": true,
  "docs_url": "/docs",
  "redoc_url": "/redoc"
}
```

### Developer Mode Değiştirme
```http
POST /api/developer/mode
Content-Type: application/json

{
  "enabled": false
}
```

**Response:**
```json
{
  "success": true,
  "developer_mode": false,
  "message": "Developer mode kapatıldı",
  "swagger_available": false
}
```

## 📦 Migration Sistemi

### Migration Çalıştırma
```http
POST /api/migrations/run/DatabaseA
```

**Response:**
```json
{
  "success": true,
  "database": "DatabaseA",
  "applied_migrations": ["001_initial_schema"],
  "failed_migrations": [],
  "total_migrations": 1,
  "message": "Migration işlemi tamamlandı. 1 migration uygulandı, 0 başarısız."
}
```

### Migration Durumu
```http
GET /api/migrations/status/DatabaseA
```

**Response:**
```json
{
  "database": "DatabaseA",
  "applied_migrations": ["001_initial_schema"],
  "pending_migrations": [],
  "total_applied": 1,
  "total_pending": 0,
  "database_exists": true
}
```

### Database Oluşturma
```http
POST /api/migrations/create-database/DatabaseA
```

**Response:**
```json
{
  "success": true,
  "database": "DatabaseA",
  "message": "Database 'DatabaseA' başarıyla oluşturuldu"
}
```

## ⚠️ Hata Yönetimi

### Yaygın Hata Kodları

| Kod | Mesaj | Açıklama |
|-----|-------|----------|
| 400 | Bad Request | Geçersiz istek parametreleri |
| 401 | Unauthorized | Kimlik doğrulama gerekli |
| 403 | Forbidden | Yetki yetersiz |
| 404 | Not Found | Kaynak bulunamadı |
| 500 | Internal Server Error | Sunucu hatası |

### Hata Response Formatı
```json
{
  "detail": "Hata mesajı",
  "error_code": "ERROR_CODE",
  "timestamp": "2024-01-01T12:00:00"
}
```

### Yaygın Hatalar ve Çözümleri

#### Database Bağlantı Hatası
```json
{
  "detail": "Database bağlantısı kurulamadı",
  "error_code": "DB_CONNECTION_ERROR"
}
```
**Çözüm:** Database konfigürasyonunu kontrol edin

#### Tablo Bulunamadı
```json
{
  "detail": "Tablo bulunamadı",
  "error_code": "TABLE_NOT_FOUND"
}
```
**Çözüm:** Tablo adını kontrol edin

#### Identity Konfigürasyon Hatası
```json
{
  "detail": "Identity konfigürasyonu bulunamadı",
  "error_code": "IDENTITY_CONFIG_NOT_FOUND"
}
```
**Çözüm:** table_schema.json dosyasını kontrol edin

## 📝 Örnek Kullanımlar

### 1. Temel CRUD İşlemleri

#### Veri Ekleme
```bash
curl -X POST "http://localhost:8000/api/tables/FATURA/data?database=DatabaseA" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "FATURA_KODU": "FAT-2024-003",
      "FATURA_TARIHI": "2024-01-03",
      "MUSTERI_ID": 3,
      "TOPLAM_TUTAR": 2000.00,
      "DURUM": "AKTIF"
    }
  }'
```

#### Veri Güncelleme
```bash
curl -X PUT "http://localhost:8000/api/tables/FATURA/data/1?database=DatabaseA" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "TOPLAM_TUTAR": 1500.00
    }
  }'
```

#### Veri Silme
```bash
curl -X DELETE "http://localhost:8000/api/tables/FATURA/data/1?database=DatabaseA&soft_delete=true"
```

### 2. Multi-Database Kullanımı

#### Database Karşılaştırma
```bash
# DatabaseA'dan veri
curl "http://localhost:8000/api/tables/FATURA/data?database=DatabaseA&page=1&page_size=5"

# DatabaseB'den veri
curl "http://localhost:8000/api/tables/FATURA/data?database=DatabaseB&page=1&page_size=5"
```

### 3. Developer Mode Yönetimi

#### Developer Mode Kapatma
```bash
curl -X POST "http://localhost:8000/api/developer/mode" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```

### 4. Migration İşlemleri

#### Migration Çalıştırma
```bash
curl -X POST "http://localhost:8000/api/migrations/run/DatabaseA"
```

#### Migration Durumu Kontrolü
```bash
curl "http://localhost:8000/api/migrations/status/DatabaseA"
```

### 5. WebSocket Kullanımı

#### JavaScript WebSocket Örneği
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/client123');

ws.onopen = function() {
  console.log('WebSocket bağlantısı kuruldu');
  
  // Database değişikliklerini dinle
  ws.send(JSON.stringify({
    tip: "subscribe_database",
    database: "DatabaseA"
  }));
};

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Gelen mesaj:', data);
  
  if (data.tip === 'database_change') {
    console.log('Database değişikliği:', data.data);
  }
};

ws.onclose = function() {
  console.log('WebSocket bağlantısı kapandı');
};
```

### 6. Flutter Kullanım Örnekleri

#### Flutter HTTP Client Servisi
```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static String? _token;

  // Token ayarlama
  static void setToken(String token) {
    _token = token;
  }

  // HTTP Headers
  static Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Login işlemi
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? database,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
          if (database != null) 'database': database,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        return data;
      } else {
        throw Exception('Login başarısız: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login hatası: $e');
    }
  }

  // Tablo verilerini alma
  static Future<Map<String, dynamic>> getTableData({
    required String tableName,
    String? database,
    int page = 1,
    int pageSize = 50,
    bool includeRelated = false,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = {
        if (database != null) 'database': database,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (includeRelated) 'include_related': 'true',
        if (filters != null) 'filters': jsonEncode(filters),
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/tables/$tableName/data').replace(queryParameters: queryParams),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Veri alma hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Veri alma hatası: $e');
    }
  }

  // Yeni kayıt ekleme
  static Future<Map<String, dynamic>> createRecord({
    required String tableName,
    required Map<String, dynamic> data,
    String? database,
  }) async {
    try {
      final queryParams = {
        if (database != null) 'database': database,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/tables/$tableName/data').replace(queryParameters: queryParams),
        headers: _headers,
        body: jsonEncode({'data': data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Kayıt ekleme hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kayıt ekleme hatası: $e');
    }
  }

  // Kayıt güncelleme
  static Future<Map<String, dynamic>> updateRecord({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    String? database,
  }) async {
    try {
      final queryParams = {
        if (database != null) 'database': database,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/api/tables/$tableName/data/$recordId').replace(queryParameters: queryParams),
        headers: _headers,
        body: jsonEncode({'data': data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Güncelleme hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Güncelleme hatası: $e');
    }
  }

  // Kayıt silme
  static Future<Map<String, dynamic>> deleteRecord({
    required String tableName,
    required String recordId,
    String? database,
    bool softDelete = true,
  }) async {
    try {
      final queryParams = {
        if (database != null) 'database': database,
        'soft_delete': softDelete.toString(),
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/api/tables/$tableName/data/$recordId').replace(queryParameters: queryParams),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Silme hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Silme hatası: $e');
    }
  }

  // Database listesi alma
  static Future<Map<String, dynamic>> getDatabases() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/databases'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Database listesi alma hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Database listesi alma hatası: $e');
    }
  }

  // Sistem durumu alma
  static Future<Map<String, dynamic>> getStatus({String? database}) async {
    try {
      final queryParams = {
        if (database != null) 'database': database,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/status').replace(queryParameters: queryParams),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Sistem durumu alma hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sistem durumu alma hatası: $e');
    }
  }
}
```

#### Flutter WebSocket Servisi
```dart
// lib/services/websocket_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static StreamController<Map<String, dynamic>>? _messageController;
  static String? _clientId;

  // WebSocket bağlantısı kurma
  static Future<void> connect(String clientId) async {
    try {
      _clientId = clientId;
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8000/ws/$clientId'),
      );

      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            final data = jsonDecode(message);
            _messageController!.add(data);
          }
        },
        onError: (error) {
          print('WebSocket hatası: $error');
        },
        onDone: () {
          print('WebSocket bağlantısı kapandı');
        },
      );

      print('WebSocket bağlantısı kuruldu: $clientId');
    } catch (e) {
      print('WebSocket bağlantı hatası: $e');
    }
  }

  // Database subscription
  static void subscribeToDatabase(String database) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'tip': 'subscribe_database',
        'database': database,
      }));
    }
  }

  // Tablo subscription
  static void subscribeToTable(String table) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'tip': 'subscribe_table',
        'table': table,
      }));
    }
  }

  // Kullanıcı subscription
  static void subscribeToUser(String userId) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'tip': 'subscribe_user',
        'user_id': userId,
      }));
    }
  }

  // Mesaj dinleme
  static Stream<Map<String, dynamic>> get messageStream {
    return _messageController?.stream ?? Stream.empty();
  }

  // Bağlantıyı kapatma
  static void disconnect() {
    _channel?.sink.close();
    _messageController?.close();
    _channel = null;
    _messageController = null;
  }
}
```

#### Flutter Provider/Riverpod Kullanımı
```dart
// lib/providers/api_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// API Provider
final apiProvider = Provider<ApiService>((ref) => ApiService());

// Login Provider
final loginProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>(
  (ref, credentials) async {
    final apiService = ref.read(apiProvider);
    return await apiService.login(
      username: credentials['username']!,
      password: credentials['password']!,
      database: credentials['database'],
    );
  },
);

// Tablo verileri Provider
final tableDataProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, params) async {
    final apiService = ref.read(apiProvider);
    return await apiService.getTableData(
      tableName: params['tableName'],
      database: params['database'],
      page: params['page'] ?? 1,
      pageSize: params['pageSize'] ?? 50,
      includeRelated: params['includeRelated'] ?? false,
      filters: params['filters'],
    );
  },
);

// Database listesi Provider
final databasesProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final apiService = ref.read(apiProvider);
    return await apiService.getDatabases();
  },
);

// Sistem durumu Provider
final statusProvider = FutureProvider.family<Map<String, dynamic>, String?>(
  (ref, database) async {
    final apiService = ref.read(apiProvider);
    return await apiService.getStatus(database: database);
  },
);
```

#### Flutter UI Örnekleri

##### Login Ekranı
```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedDatabase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giriş Yap'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Kullanıcı adı gerekli';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Şifre gerekli';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDatabase,
                decoration: InputDecoration(
                  labelText: 'Database',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'DatabaseA', child: Text('Database A')),
                  DropdownMenuItem(value: 'DatabaseB', child: Text('Database B')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDatabase = value;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                child: Text('Giriş Yap'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credentials = {
          'username': _usernameController.text,
          'password': _passwordController.text,
          if (_selectedDatabase != null) 'database': _selectedDatabase!,
        };

        final result = await ref.read(loginProvider(credentials).future);
        
        // Token'ı kaydet
        ApiService.setToken(result['access_token']);
        
        // Ana sayfaya yönlendir
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş hatası: $e')),
        );
      }
    }
  }
}
```

##### Tablo Verileri Ekranı
```dart
// lib/screens/table_data_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';

class TableDataScreen extends ConsumerStatefulWidget {
  final String tableName;
  final String? database;

  TableDataScreen({required this.tableName, this.database});

  @override
  ConsumerState<TableDataScreen> createState() => _TableDataScreenState();
}

class _TableDataScreenState extends ConsumerState<TableDataScreen> {
  int _currentPage = 1;
  int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final tableDataAsync = ref.watch(tableDataProvider({
      'tableName': widget.tableName,
      'database': widget.database,
      'page': _currentPage,
      'pageSize': _pageSize,
    }));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tableName} Verileri'),
        backgroundColor: Colors.blue,
      ),
      body: tableDataAsync.when(
        data: (data) {
          final records = data['data'] as List;
          final total = data['total'] as int;
          final totalPages = data['total_pages'] as int;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text('ID: ${record['FATURA_ID'] ?? record['id']}'),
                        subtitle: Text(record.toString()),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Text('Düzenle'),
                              value: 'edit',
                            ),
                            PopupMenuItem(
                              child: Text('Sil'),
                              value: 'delete',
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editRecord(record);
                            } else if (value == 'delete') {
                              _deleteRecord(record);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Sayfalama
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                      child: Text('Önceki'),
                    ),
                    Text('Sayfa $_currentPage / $totalPages'),
                    ElevatedButton(
                      onPressed: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                      child: Text('Sonraki'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Hata: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRecord,
        child: Icon(Icons.add),
      ),
    );
  }

  void _addNewRecord() {
    // Yeni kayıt ekleme dialog'u
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yeni Kayıt Ekle'),
        content: Text('Bu özellik implement edilecek'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _editRecord(Map<String, dynamic> record) {
    // Kayıt düzenleme dialog'u
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kayıt Düzenle'),
        content: Text('Bu özellik implement edilecek'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _deleteRecord(Map<String, dynamic> record) {
    // Silme onayı
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kayıt Sil'),
        content: Text('Bu kaydı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Silme işlemi
            },
            child: Text('Sil'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
```

##### WebSocket Kullanımı
```dart
// lib/screens/realtime_screen.dart
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class RealtimeScreen extends StatefulWidget {
  @override
  _RealtimeScreenState createState() => _RealtimeScreenState();
}

class _RealtimeScreenState extends State<RealtimeScreen> {
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    await WebSocketService.connect('flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    
    // Database değişikliklerini dinle
    WebSocketService.subscribeToDatabase('DatabaseA');
    
    // Tablo değişikliklerini dinle
    WebSocketService.subscribeToTable('FATURA');
    
    // Mesajları dinle
    WebSocketService.messageStream.listen((message) {
      setState(() {
        _messages.add('${DateTime.now()}: ${message.toString()}');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Bildirimler'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_messages[index]),
            leading: Icon(Icons.notifications),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WebSocketService.disconnect();
    super.dispose();
  }
}
```

#### Flutter pubspec.yaml Bağımlılıkları
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  web_socket_channel: ^2.4.0
  flutter_riverpod: ^2.4.0
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  json_serializable: ^6.7.1
  build_runner: ^2.4.6
```

## 🔒 Güvenlik

### Best Practices
1. **JWT Token Kullanımı:** Tüm API isteklerinde JWT token kullanın
2. **Database İzolasyonu:** Farklı database'ler için ayrı konfigürasyonlar kullanın
3. **Input Validation:** Tüm input verilerini doğrulayın
4. **SQL Injection Koruması:** Parametreli sorgular kullanın
5. **Production Güvenliği:** Production'da developer mode'u kapatın

### Güvenlik Ayarları
```json
{
  "jwt_secret_key": "your-secret-key",
  "jwt_algorithm": "HS256",
  "access_token_expire_minutes": 30,
  "developer_mode": false
}
```

## 📊 Monitoring ve Logging

### Log İstatistikleri
```http
GET /api/logs/statistics
```

### Log Temizleme
```http
POST /api/logs/cleanup?days=30
```

## 🚀 Performance Optimizasyonu

### Öneriler
1. **Sayfalama Kullanımı:** Büyük veri setleri için sayfalama kullanın
2. **Database İndeksleri:** Sık kullanılan sorgular için indeksler oluşturun
3. **Connection Pooling:** Database bağlantı havuzu kullanın
4. **Caching:** Sık kullanılan veriler için cache mekanizması ekleyin

## 📞 Destek

### Swagger UI
- **URL:** `http://localhost:8000/docs`
- **Açıklama:** Interaktif API dokümantasyonu

### ReDoc
- **URL:** `http://localhost:8000/redoc`
- **Açıklama:** Detaylı API dokümantasyonu

### Log Dosyaları
- **App Log:** `logs/app.log`
- **Database Log:** `logs/database.log`
- **Error Log:** `logs/error.log`
- **WebSocket Log:** `logs/websocket.log`

---

**Son Güncelleme:** 2024-01-01  
**Versiyon:** 3.2.0  
**Dokümantasyon Versiyonu:** 1.0 
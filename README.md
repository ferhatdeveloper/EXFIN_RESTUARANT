# EXFIN_REST Flutter Frontend

Bu klasör, EXFIN_REST restoran yönetim sisteminin Flutter frontend uygulamasını içerir.

## Teknoloji Stack

- **Framework**: Flutter 3.16+
- **State Management**: Riverpod
- **GraphQL**: GraphQL Flutter
- **HTTP Client**: Dio
- **Local Storage**: Shared Preferences
- **UI Components**: Material Design 3
- **Package Name**: `com.exfin.exfin_rest`

## Kurulum

### Gereksinimler

- Flutter SDK 3.16+
- Dart SDK 3.2+
- Android Studio / VS Code
- Android SDK (Android için)
- Xcode (iOS için)

### Kurulum Adımları

1. **Flutter'ı kurun**:
   ```bash
   # Flutter SDK'yı indirin ve kurun
   # https://flutter.dev/docs/get-started/install
   ```

2. **Projeyi klonlayın**:
   ```bash
   cd frontend
   ```

3. **Bağımlılıkları yükleyin**:
   ```bash
   flutter pub get
   ```

4. **Environment dosyasını oluşturun**:
   ```bash
   cp .env.example .env
   # .env dosyasını düzenleyin
   ```

5. **Uygulamayı çalıştırın**:
   ```bash
   flutter run
   ```

## Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── app/
│   ├── app.dart             # Ana uygulama widget'ı
│   └── theme.dart           # Tema konfigürasyonu
├── core/
│   ├── constants/           # Sabitler
│   ├── errors/              # Hata yönetimi
│   ├── network/             # Ağ istekleri
│   └── utils/               # Yardımcı fonksiyonlar
├── features/
│   ├── auth/                # Kimlik doğrulama
│   ├── tables/              # Masa yönetimi
│   ├── orders/              # Sipariş yönetimi
│   ├── kitchen/             # Mutfak ekranı
│   ├── payment/             # Ödeme ekranı
│   └── admin/               # Admin paneli
├── shared/
│   ├── models/              # Veri modelleri
│   ├── widgets/             # Ortak widget'lar
│   └── providers/           # Riverpod provider'ları
└── generated/               # GraphQL generated dosyaları
```

## Özellikler

### 1. Kimlik Doğrulama
- Rol tabanlı giriş (admin, waiter, kitchen, cashier)
- JWT token yönetimi
- Otomatik token yenileme

### 2. Masa Yönetimi
- Masa listesi görüntüleme
- Masa durumu takibi
- Masa oluşturma/katılma

### 3. Sipariş Yönetimi
- Ürün katalog görüntüleme
- Sipariş oluşturma
- Modifikatör ekleme
- Sipariş düzenleme

### 4. Mutfak Ekranı
- Gerçek zamanlı sipariş takibi
- Sipariş durumu güncelleme
- Hazırlanan siparişleri işaretleme

### 5. Ödeme Ekranı
- Çoklu ödeme yöntemi
- Bölümlü ödeme
- Fatura yazdırma

### 6. Admin Paneli
- Satış raporları
- Stok yönetimi
- Kullanıcı yönetimi

## GraphQL Entegrasyonu

### Queries
- Kullanıcı bilgileri
- Masa listesi
- Ürün katalog
- Sipariş geçmişi

### Mutations
- Sipariş oluşturma
- Sipariş güncelleme
- Ödeme işlemi

### Subscriptions
- Gerçek zamanlı sipariş güncellemeleri
- Masa durumu değişiklikleri

## State Management

Riverpod kullanarak state management yapılandırması:

```dart
// Provider örneği
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// Kullanım
final authState = ref.watch(authProvider);
```

## Tema ve UI

Material Design 3 kullanarak modern ve tutarlı UI:

```dart
// Tema konfigürasyonu
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: Brightness.light,
  ),
);
```

## Build ve Deploy

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Test

```bash
# Unit testler
flutter test

# Integration testler
flutter test integration_test/
```

## Debugging

```bash
# Debug modunda çalıştırma
flutter run --debug

# Profile modunda çalıştırma
flutter run --profile
```

## Environment Variables

`.env` dosyasında aşağıdaki değişkenleri tanımlayın:

```
API_BASE_URL=http://localhost:3000
GRAPHQL_ENDPOINT=http://localhost:8080/v1/graphql
HASURA_ADMIN_SECRET=exfin_admin_secret_2024
```

## Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. 
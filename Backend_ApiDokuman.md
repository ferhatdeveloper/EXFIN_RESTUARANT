# Exfin REST - PostgREST API Dokümantasyonu

## Genel Mimari

Bu projede backend katmanı **FastAPI yerine PostgREST + PostgreSQL**
üzerinden çalışır.

- Veritabanı: PostgreSQL
- API Katmanı: PostgREST
- İstemci: Flutter

> Not: FastAPI/Swagger tabanlı eski akış sistemden çıkarılmıştır.

## Varsayılan Bağlantı Bilgileri

- PostgREST Base URL: `http://localhost:3002`
- Varsayılan schema: `public`
- PostgreSQL portu: `5432`

## Kurulum

1. PostgreSQL veritabanını oluşturun.
2. `/workspace/Sql/database_setup.sql` scriptini çalıştırın.
3. (Yeni) RetailEX rapor şeması için:
   `/workspace/Sql/retailex_reporting_schema.sql` scriptini çalıştırın.
4. PostgREST servisini `public` schema için başlatın.

## PostgREST Kullanım Örnekleri

### Kullanıcılar

```http
GET /users?select=id,username,role,is_active&is_active=eq.true&order=username.asc
```

### Masalar

```http
GET /tables?select=id,name,status,capacity,location,regions(name)&is_active=eq.true
```

### Siparişler

```http
GET /orders?select=id,fatura_kodu,table_id,total_amount,final_amount,payment_status,status,created_at&order=created_at.desc
```

### Sipariş Oluşturma

```http
POST /orders
Content-Type: application/json
Prefer: return=representation

{
  "fatura_kodu": "B0120260524001",
  "table_id": 1,
  "customer_name": "Demo Müşteri",
  "total_amount": 250.0,
  "discount_amount": 0,
  "final_amount": 250.0,
  "payment_status": "pending",
  "status": "active"
}
```

### Sipariş Güncelleme

```http
PATCH /orders?id=eq.1
Content-Type: application/json

{
  "status": "completed",
  "payment_status": "paid"
}
```

### Sipariş Silme

```http
DELETE /orders?id=eq.1
```

### RPC Örneği (Fatura Kodu)

```http
POST /rpc/generate_fatura_kodu
Content-Type: application/json

{
  "p_table_id": 1
}
```

## RetailEX Rapor Şeması (Uyarlanan Yapı)

Bu projeye RetailEX raporlama yaklaşımına uyumlu aşağıdaki tablolar
eklenmiştir:

- `report_templates`
- `scheduled_reports`
- `report_executions`

Ayrıca rapor okumalarını kolaylaştıran view:

- `v_report_execution_summary`

### Örnek Rapor Şablonları

```http
GET /report_templates?select=id,name,category,data_source,chart_config&order=created_at.desc
```

### Örnek Rapor Çalıştırma Geçmişi

```http
GET /report_executions?select=id,status,execution_time_ms,row_count,created_at&order=created_at.desc
```

## Güvenlik

- PostgREST için `Accept-Profile` / `Content-Profile` header'ları
  kullanılmalıdır.
- Üretimde JWT ile Authorization header zorunlu olmalıdır.
- Doğrudan SQL erişimi istemci katmanından açılmamalıdır.

## Flutter Entegrasyon Notu

`lib/services/postgres_service.dart` artık doğrudan SQL sürücüsü yerine
PostgREST HTTP uçlarını kullanır.

## Hata Yönetimi

Sık karşılaşılan durumlar:

- `404`: tablo / RPC fonksiyonu bulunamadı
- `406`: profile/schema header eksik veya uyumsuz
- `42501`: yetki hatası (RLS / grant)
- `500`: veritabanı veya fonksiyon hatası

## Özet

- FastAPI bağımlılığı kaldırıldı.
- PostgreSQL + PostgREST akışı standardize edildi.
- RetailEX rapor veritabanı yapısı entegre edildi.

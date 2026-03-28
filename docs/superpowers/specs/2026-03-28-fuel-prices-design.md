# Yakıt Fiyat Entegrasyonu — Tasarım Dokümanı

**Tarih:** 2026-03-28
**Proje:** YakitYonet (Flutter)
**Kapsam:** Supabase edge function + Flutter yakıt fiyat servisi + UI entegrasyonu

---

## 1. Genel Bakış

Petrol Ofisi'nden günlük yakıt fiyatları (Benzin, Dizel, LPG) otomatik olarak çekilip Supabase'de saklanacak. Flutter uygulaması bu verileri 6 saatlik yerel cache ile okuyacak; ana ekranda fiyat barı gösterecek, seyahat hesaplayıcıda ise araç yakıt türüne göre otomatik fiyat dolduracak.

---

## 2. Supabase Veritabanı

### Tablo: `prices`

```sql
CREATE TABLE prices (
  id         BIGSERIAL PRIMARY KEY,
  date       DATE        NOT NULL UNIQUE,
  benzin     NUMERIC(8,2),
  dizel      NUMERIC(8,2),
  lpg        NUMERIC(8,2),
  elektrik   NUMERIC(8,2) DEFAULT 15.90,
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon read" ON prices FOR SELECT TO anon USING (true);
```

- `date` UNIQUE kısıtı upsert anahtarı olarak kullanılır — her gün için tek satır.
- `elektrik` 15.90 ₺ sabit (ileride ayrı bir edge function tarafından güncellenecek).
  - **Not:** `trip_screen.dart`'taki `_defaultPrice('Elektrik')` değeri de 15.90'a güncellenecek (mevcut 3.5 yanlış).
- RLS: anon okuma açık, yazma sadece service_role.

---

## 3. Supabase Edge Function: `fetch-fuel-prices`

**Konum:** `supabase/functions/fetch-fuel-prices/index.ts`
**Çağrı kaynağı:** Yalnızca `pg_cron` tarafından çağrılır. Flutter bu endpoint'i doğrudan çağırmaz.

**Akış:**
1. `https://www.petrolofisi.com.tr/Fuel/Search` adresine multipart form-data ile POST:
   - `template: 1`
   - `cityId: 06` (Ankara)
   - `districtId: ` (boş)
   - `isBp: false`
2. HTML yanıtını regex ile parse et. Örnek response yapısı:
   ```html
   <h4>...<br/>Kurşunsuz 95</h4>
   <span class="scrollspy js-counter">63.49</span>
   <h4>...<br/>Diesel</h4>
   <span class="scrollspy js-counter">76.00</span>
   <h4>...<br/>Otogaz</h4>
   <span class="scrollspy js-counter">30.37</span>
   ```
   Regex: `js-counter` span'ları sırasıyla Kurşunsuz 95, Diesel, Otogaz'a karşılık gelir.
3. Parse başarısız olursa (site yapısı değişti, timeout vb.) → hata logla, upsert yapma (önceki gün verisi tabloda kalır).
4. `elektrik = 15.90` sabit olarak upsert payload'a ekle.
5. Bugünün tarihini UTC+3 (Türkiye) olarak `YYYY-MM-DD` formatında al.
6. Dört kolonu da (`benzin`, `dizel`, `lpg`, `elektrik`) içeren payload ile upsert:

```sql
INSERT INTO prices (date, benzin, dizel, lpg, elektrik, updated_at)
VALUES ($1, $2, $3, $4, $5, now())
ON CONFLICT (date) DO UPDATE SET
  benzin = EXCLUDED.benzin,
  dizel = EXCLUDED.dizel,
  lpg = EXCLUDED.lpg,
  elektrik = EXCLUDED.elektrik,
  updated_at = now();
```

**Zamanlama (pg_cron) — Türkiye UTC+3, DST yok:**

```sql
-- 00:00 Türkiye = 21:00 UTC (önceki gün)
-- Not: Gece yarısı çalışması muhtemelen önceki günün fiyatlarını çeker,
--      sabah çalışması güncel fiyatları üzerine yazar (UPDATE).
SELECT cron.schedule('fetch-prices-midnight', '0 21 * * *',
  $$SELECT net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/fetch-fuel-prices',
    headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>"}'::jsonb
  ) $$);

-- 12:00 Türkiye = 09:00 UTC (güncellenen fiyatlar için asıl çalışma)
SELECT cron.schedule('fetch-prices-noon', '0 9 * * *',
  $$SELECT net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/fetch-fuel-prices',
    headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>"}'::jsonb
  ) $$);
```

**Gerekli Supabase Extensions:** `pg_cron`, `pg_net`

---

## 4. Flutter Servis Katmanı

### `lib/services/fuel_price_service.dart`

**Model:**
```dart
class FuelPrices {
  final double benzin;
  final double dizel;
  final double lpg;
  final double elektrik;   // 15.90 ₺
  final DateTime updatedAt; // updated_at kolonundan, SnackBar için kullanılır
}
```

**`FuelPriceService` (singleton):**

| Metod | Açıklama |
|---|---|
| `getPrices()` | Cache geçerliyse cache'den, değilse Supabase'den çeker |
| `_fetchFromApi()` | REST GET, parse, SharedPreferences'a yazar |
| `_loadFromCache()` | SharedPreferences'tan okur |
| `priceFor(String fuelType)` | Yakıt türü string'ine göre double döner (`null` olabilir) |

**Cache Stratejisi:**
- SharedPreferences anahtarları: `fuel_cache_json`, `fuel_cache_timestamp`
- TTL: 6 saat **VE** aynı takvim günü (her ikisi de sağlanmalı)
  - Örnek: 23:55'te cache'lendi, 00:10'da açıldı → 6 saat dolmasa da yeni gün → cache geçersiz
- Hata durumunda (ağ yok, parse hatası) son başarılı cache döner
- Cache yoksa ve ağ da yoksa → `null` döner (UI `--` gösterir)

**Supabase REST Endpoint:**
```
GET <SUPABASE_URL>/rest/v1/prices?select=*&order=date.desc&limit=1
Headers:
  apikey: <SUPABASE_ANON_KEY>
  Authorization: Bearer <SUPABASE_ANON_KEY>
```

**.env anahtarları (tam isimler):**
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
```
Erişim: `dotenv.env['SUPABASE_URL']`, `dotenv.env['SUPABASE_ANON_KEY']`

**Paket değişiklikleri:** Yok (`http` ve `shared_preferences` zaten mevcut).

---

## 5. UI Değişiklikleri

### 5.1 `vehicle_list_screen.dart` — Yakıt Fiyat Barı

**Konum:** `_buildGreeting()` çıktısının hemen altına, `Expanded` widget'ının üstüne yeni `_buildFuelPriceBar()` widget'ı eklenir. Fiyat barı araç durumundan bağımsız — yüklenirken ve araç yokken de görünür.

**Veri yükleme:**
- `initState`'de `FuelPriceService.instance.getPrices()` asenkron çağrılır
- `setState` ile `_fuelPrices` güncellenir (UI bloklanmaz)

**Yapı:**
```
Padding(horizontal: 16, bottom: 8)
└── SingleChildScrollView(scrollDirection: horizontal)
    └── Row
        ├── _FuelPriceChip('Benzin',  benzin,  AppTheme.fuelColor)
        ├── SizedBox(width: 8)
        ├── _FuelPriceChip('Dizel',   dizel,   AppTheme.maintColor)
        ├── SizedBox(width: 8)
        ├── _FuelPriceChip('LPG',     lpg,     AppTheme.successColor)
        ├── SizedBox(width: 8)
        └── _FuelPriceChip('Elektrik',elektrik, Color(0xFF0891B2))
```

**`_FuelPriceChip` tasarımı:**
- Yükseklik: 54px, padding: horizontal 12, vertical 8
- Arka plan: `AppTheme.surfaceAltFor(context)` (dark/light uyumlu)
- Kenarlık: `AppTheme.borderFor(context)`
- Border radius: 12
- Fiyat yüklenmediyse veya `priceFor()` null dönerse: `--` göster (chip gizlenmez)
- Herhangi bir chip'e tap → `ScaffoldMessenger.showSnackBar`:
  `"Fiyatlar Ankara (06) bazlıdır · Güncelleme: HH:mm"`
  - `HH:mm` → `FuelPrices.updatedAt` alanının `DateFormat('HH:mm').format()` ile biçimlendirilmesi

### 5.2 `trip_screen.dart` — Akıllı Fiyat Doldurma

**Yeni state alanı:**
```dart
bool _priceAutofilled = false;
```

**`_loadStatsForVehicle()` değişikliği:**

Mevcut mantığa dokunulmaz (tarihsel ortalama hesabı korunur). Mevcut `setState`'den **önce** `_priceAutofilled = false` sıfırlanır (araç değişiminde temizleme). Ardından fiyat öncelik sırası:

1. `avgPrice > 0` ise → tarihsel ortalama kullanılır (`_priceAutofilled = false`)
2. `avgPrice == 0` ise → `FuelPriceService.instance.getPrices()` çağrılır:
   - Live fiyat alındıysa → `_priceCtrl.text` live fiyat, `_priceAutofilled = true`
   - Alınamadıysa → `_defaultPrice()` fallback, `_priceAutofilled = false`
3. Her iki `await` sonrasında `mounted` kontrolü yapılır.

**`_defaultPrice()` güncelleme:**
```dart
// Eski:
case 'Elektrik': return 3.5;
// Yeni:
case 'Elektrik': return 15.90;
```

**Autofill göstergesi (`_inputField` içinde):**
- Yakıt fiyatı `_inputField`'ında `helperText` parametresi kullanılır (tüketim alanındaki `'Gecmis veriden'` ile aynı pattern)
- Yakıt fiyatı alanı için `helperText` dinamik: `_priceAutofilled ? '✓ Güncel fiyat uygulandı' : null`
- Tüketim alanının `helperText: 'Gecmis veriden'` değerine dokunulmaz
- Kullanıcı `_priceCtrl`'ı değiştirirse listener'da `_priceAutofilled = false` set edilir

---

## 6. Hata Yönetimi

| Senaryo | Davranış |
|---|---|
| İnternet yok, cache var (aynı gün, 6 saat içi) | Cache döner, UI normal çalışır |
| İnternet yok, cache yok | `null` döner, fiyat barı `--` gösterir; trip fallback'e gider |
| Yeni gün ama cache eskimiş, internet yok | Cache geçersiz sayılır, `null` döner |
| Petrol Ofisi site yapısı değişti | Parse başarısız → edge function upsert yapmaz → eski tablo verisi korunur |
| Supabase down | HTTP hata → Flutter cache fallback |
| pg_cron başarısız | Önceki gün verisi tabloda kalır, uygulama bunu kullanır |

---

## 7. Yeni Dosyalar ve Değişiklikler

| Dosya | Değişiklik |
|---|---|
| `supabase/functions/fetch-fuel-prices/index.ts` | **Yeni** — Edge function |
| `lib/services/fuel_price_service.dart` | **Yeni** — Servis + `FuelPrices` modeli |
| `lib/screens/vehicle_list_screen.dart` | **Güncelleme** — Fiyat barı + `_fuelPrices` state |
| `lib/screens/trip_screen.dart` | **Güncelleme** — Akıllı autofill, `_priceAutofilled` flag, `_defaultPrice` Elektrik fix |
| `.env` | **Güncelleme** — `SUPABASE_URL`, `SUPABASE_ANON_KEY` eklenir |
| `.env.example` | **Güncelleme** — Aynı anahtarlar placeholder olarak |

---

## 8. Supabase Kurulum Adımları (Manuel)

1. Supabase Dashboard > SQL Editor'da `prices` tablosu + RLS policy oluştur (Bölüm 2 SQL)
2. Extensions: `pg_cron` ve `pg_net` aktif et
3. Edge function deploy: `supabase functions deploy fetch-fuel-prices`
4. pg_cron schedule SQL'lerini çalıştır (`<PROJECT_REF>` ve `<SERVICE_ROLE_KEY>` doldurularak)
5. `.env` dosyasına `SUPABASE_URL` ve `SUPABASE_ANON_KEY` ekle

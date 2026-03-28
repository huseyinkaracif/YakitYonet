# Fuel Price Integration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Petrol Ofisi'nden günlük yakıt fiyatlarını çekip Supabase'de saklayan edge function, Flutter'da 6 saatlik cache ile fiyat okuyan servis, ana ekranda fiyat barı ve seyahat hesaplayıcıda akıllı autofill.

**Architecture:** Supabase edge function (Deno/TypeScript) pg_cron ile günde 2 kez tetiklenir, `prices` tablosuna upsert yapar. Flutter `FuelPriceService` singleton'ı `http` paketi ile Supabase REST API'den okur, SharedPreferences'ta 6 saatlik cache tutar. `vehicle_list_screen`'de fiyat barı, `trip_screen`'de araç seçiminde otomatik fiyat doldurma.

**Tech Stack:** Deno (Supabase edge function), Flutter, Dart, `http` paketi, `shared_preferences` paketi, `flutter_dotenv`, Supabase REST API, pg_cron, pg_net

---

## File Map

| Dosya | İşlem | Sorumluluk |
|---|---|---|
| `supabase/functions/fetch-fuel-prices/index.ts` | Oluştur | HTML parse, Supabase upsert |
| `lib/services/fuel_price_service.dart` | Oluştur | FuelPrices model + cache + REST fetch |
| `lib/screens/vehicle_list_screen.dart` | Güncelle | `_buildFuelPriceBar()` + `_fuelPrices` state |
| `lib/screens/trip_screen.dart` | Güncelle | `_priceAutofilled` flag + smart autofill |
| `.env` | Güncelle | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| `.env.example` | Güncelle | Aynı anahtarlar placeholder ile |

---

## Task 1: .env Anahtarlarını Ekle

**Files:**
- Modify: `.env`
- Modify: `.env.example`

Bu adımları uygulamak için Supabase Dashboard > Project Settings > API sekmesinden değerleri al.

- [ ] **Step 1: `.env` dosyasına Supabase anahtarlarını ekle**

`.env` dosyasının sonuna şunları ekle (gerçek değerlerle):
```
SUPABASE_URL=https://XXXX.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

- [ ] **Step 2: `.env.example` dosyasına placeholder ekle**

`.env.example` dosyasının sonuna şunları ekle:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

- [ ] **Step 3: Commit**

```bash
git add .env.example
git commit -m "chore: add Supabase env keys to .env.example"
```
Not: `.env` commit edilmez (`.gitignore`'da olmalı — `git status` ile kontrol et, eğer tracked ise `.gitignore`'a ekle).

---

## Task 2: Supabase Veritabanı Kurulumu (Manuel)

Bu task Supabase Dashboard'da yapılır, kod değişikliği yoktur.

- [ ] **Step 1: `prices` tablosunu ve RLS policy'yi oluştur**

Supabase Dashboard > SQL Editor'a git ve şu SQL'i çalıştır:

```sql
CREATE TABLE IF NOT EXISTS prices (
  id         BIGSERIAL PRIMARY KEY,
  date       DATE        NOT NULL UNIQUE,
  benzin     NUMERIC(8,2),
  dizel      NUMERIC(8,2),
  lpg        NUMERIC(8,2),
  elektrik   NUMERIC(8,2) DEFAULT 15.90,
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE prices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon read" ON prices
  FOR SELECT TO anon USING (true);
```

- [ ] **Step 2: `pg_cron` ve `pg_net` extension'larını aktif et**

Supabase Dashboard > Database > Extensions'a git:
- `pg_cron` → Enable
- `pg_net` → Enable (genellikle varsayılan açık gelir)

- [ ] **Step 3: Tabloyu doğrula**

SQL Editor'da çalıştır:
```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'prices' ORDER BY ordinal_position;
```
Beklenen: `id`, `date`, `benzin`, `dizel`, `lpg`, `elektrik`, `updated_at` sütunları görünmeli.

---

## Task 3: Supabase Edge Function

**Files:**
- Create: `supabase/functions/fetch-fuel-prices/index.ts`

- [ ] **Step 1: Dizin oluştur**

```bash
mkdir -p supabase/functions/fetch-fuel-prices
```

- [ ] **Step 2: Edge function dosyasını oluştur**

`supabase/functions/fetch-fuel-prices/index.ts` dosyasını oluştur:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (_req) => {
  try {
    // 1. Petrol Ofisi'nden fiyat çek
    const formData = new FormData();
    formData.append("template", "1");
    formData.append("cityId", "06");
    formData.append("districtId", "");
    formData.append("isBp", "false");

    const response = await fetch("https://www.petrolofisi.com.tr/Fuel/Search", {
      method: "POST",
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Petrol Ofisi HTTP ${response.status}`);
    }

    const html = await response.text();

    // 2. js-counter span'larından fiyatları parse et
    const counterRegex = /class="scrollspy js-counter">\s*([\d.]+)\s*<\/span>/g;
    const matches: number[] = [];
    let match;
    while ((match = counterRegex.exec(html)) !== null) {
      matches.push(parseFloat(match[1]));
    }

    // Sıra: Kurşunsuz 95 → benzin, Diesel → dizel, Otogaz → lpg
    if (matches.length < 3) {
      throw new Error(`Parse failed: only ${matches.length} prices found. Site structure may have changed.`);
    }

    const benzin = matches[0];
    const dizel = matches[1];
    const lpg = matches[2];
    const elektrik = 15.90;

    // 3. Türkiye saatine göre bugünün tarihi (UTC+3)
    const now = new Date();
    const trOffset = 3 * 60 * 60 * 1000;
    const trDate = new Date(now.getTime() + trOffset);
    const dateStr = trDate.toISOString().split("T")[0]; // YYYY-MM-DD

    // 4. Supabase'e upsert
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { error } = await supabase
      .from("prices")
      .upsert(
        { date: dateStr, benzin, dizel, lpg, elektrik, updated_at: new Date().toISOString() },
        { onConflict: "date" }
      );

    if (error) throw error;

    return new Response(
      JSON.stringify({ success: true, date: dateStr, benzin, dizel, lpg, elektrik }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("fetch-fuel-prices error:", err);
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
```

- [ ] **Step 3: Edge function'ı deploy et**

Supabase CLI kurulu değilse önce kur: `npm install -g supabase`

```bash
supabase login
supabase link --project-ref <PROJECT_REF>
supabase functions deploy fetch-fuel-prices
```

`<PROJECT_REF>` → Supabase Dashboard > Project Settings > General'daki Reference ID.

- [ ] **Step 4: Edge function'ı manuel test et**

```bash
supabase functions invoke fetch-fuel-prices --no-verify-jwt
```

Beklenen yanıt:
```json
{"success": true, "date": "2026-03-28", "benzin": 63.49, "dizel": 76.00, "lpg": 30.37, "elektrik": 15.90}
```

- [ ] **Step 5: pg_cron schedule'larını kur**

Supabase Dashboard > SQL Editor'da çalıştır (`<PROJECT_REF>` ve `<SERVICE_ROLE_KEY>` ile doldur):

```sql
-- 00:00 Türkiye = 21:00 UTC
SELECT cron.schedule(
  'fetch-prices-midnight',
  '0 21 * * *',
  $$
  SELECT net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/fetch-fuel-prices',
    headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>", "Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 12:00 Türkiye = 09:00 UTC
SELECT cron.schedule(
  'fetch-prices-noon',
  '0 9 * * *',
  $$
  SELECT net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/fetch-fuel-prices',
    headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>", "Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

Schedule'ları doğrula:
```sql
SELECT jobname, schedule, command FROM cron.job;
```

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/fetch-fuel-prices/index.ts
git commit -m "feat: add fetch-fuel-prices edge function"
```

---

## Task 4: FuelPriceService

**Files:**
- Create: `lib/services/fuel_price_service.dart`

- [ ] **Step 1: Servis dosyasını oluştur**

`lib/services/fuel_price_service.dart`:

```dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FuelPrices {
  final double benzin;
  final double dizel;
  final double lpg;
  final double elektrik;
  final DateTime updatedAt;

  const FuelPrices({
    required this.benzin,
    required this.dizel,
    required this.lpg,
    required this.elektrik,
    required this.updatedAt,
  });

  factory FuelPrices.fromJson(Map<String, dynamic> json) {
    return FuelPrices(
      benzin: (json['benzin'] as num).toDouble(),
      dizel: (json['dizel'] as num).toDouble(),
      lpg: (json['lpg'] as num).toDouble(),
      elektrik: (json['elektrik'] as num?)?.toDouble() ?? 15.90,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'benzin': benzin,
        'dizel': dizel,
        'lpg': lpg,
        'elektrik': elektrik,
        'updated_at': updatedAt.toIso8601String(),
      };

  double? priceFor(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'benzin':
        return benzin;
      case 'dizel':
        return dizel;
      case 'lpg':
        return lpg;
      case 'elektrik':
        return elektrik;
      default:
        return null;
    }
  }
}

class FuelPriceService {
  FuelPriceService._();
  static final FuelPriceService instance = FuelPriceService._();

  static const _cacheJsonKey = 'fuel_cache_json';
  static const _cacheTimestampKey = 'fuel_cache_timestamp';
  static const _cacheTtlHours = 6;

  /// Ana metod: cache geçerliyse cache'den, değilse API'den çeker.
  Future<FuelPrices?> getPrices() async {
    final cached = await _loadFromCache();
    if (cached != null) return cached;
    return _fetchFromApi();
  }

  /// Cache geçerlilik kontrolü: 6 saat içi VE aynı takvim günü
  Future<FuelPrices?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheJsonKey);
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (json == null || timestamp == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final elapsed = now.difference(cachedAt);
    final sameDay = cachedAt.year == now.year &&
        cachedAt.month == now.month &&
        cachedAt.day == now.day;

    if (!sameDay || elapsed.inHours >= _cacheTtlHours) return null;

    try {
      return FuelPrices.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<FuelPrices?> _fetchFromApi() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || anonKey == null) return null;

    try {
      final uri = Uri.parse(
        '$url/rest/v1/prices?select=*&order=date.desc&limit=1',
      );
      final response = await http.get(uri, headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return _fallbackFromCache();

      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return _fallbackFromCache();

      final prices = FuelPrices.fromJson(list[0] as Map<String, dynamic>);
      await _saveToCache(prices);
      return prices;
    } catch (_) {
      return _fallbackFromCache();
    }
  }

  Future<FuelPrices?> _fallbackFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheJsonKey);
    if (json == null) return null;
    try {
      return FuelPrices.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(FuelPrices prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheJsonKey, jsonEncode(prices.toJson()));
    await prefs.setInt(
        _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }
}
```

- [ ] **Step 2: Servisin derlenmesini doğrula**

```bash
flutter analyze lib/services/fuel_price_service.dart
```

Beklenen: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/services/fuel_price_service.dart
git commit -m "feat: add FuelPriceService with 6-hour cache"
```

---

## Task 5: vehicle_list_screen — Yakıt Fiyat Barı

**Files:**
- Modify: `lib/screens/vehicle_list_screen.dart`

- [ ] **Step 1: Import ve state alanı ekle**

`vehicle_list_screen.dart` dosyasının başına, mevcut import'ların yanına ekle:

```dart
import '../services/fuel_price_service.dart';
import 'package:intl/intl.dart'; // zaten mevcut, iki kez ekleme
```

`_VehicleListScreenState` içine yeni state alanı ekle:

```dart
FuelPrices? _fuelPrices;
```

- [ ] **Step 2: `initState`'e async fiyat yükleme ekle**

Mevcut `initState` metodunda `_loadVehicles()` ve `_initLocationSharing()` çağrılarından sonra ekle:

```dart
_loadFuelPrices();
```

Sınıfa yeni metod ekle:

```dart
Future<void> _loadFuelPrices() async {
  final prices = await FuelPriceService.instance.getPrices();
  if (!mounted) return;
  setState(() => _fuelPrices = prices);
}
```

- [ ] **Step 3: `_buildFuelPriceBar()` ve `_FuelPriceChip` ekle**

`_buildGreeting()` metodundan önce yeni metodları ekle:

```dart
Widget _buildFuelPriceBar() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FuelPriceChip(
            label: 'Benzin',
            icon: Icons.local_gas_station_rounded,
            price: _fuelPrices?.benzin,
            color: AppTheme.fuelColor,
            updatedAt: _fuelPrices?.updatedAt,
          ),
          const SizedBox(width: 8),
          _FuelPriceChip(
            label: 'Dizel',
            icon: Icons.local_gas_station_rounded,
            price: _fuelPrices?.dizel,
            color: AppTheme.maintColor,
            updatedAt: _fuelPrices?.updatedAt,
          ),
          const SizedBox(width: 8),
          _FuelPriceChip(
            label: 'LPG',
            icon: Icons.propane_tank_rounded,
            price: _fuelPrices?.lpg,
            color: AppTheme.successColor,
            updatedAt: _fuelPrices?.updatedAt,
          ),
          const SizedBox(width: 8),
          _FuelPriceChip(
            label: 'Elektrik',
            icon: Icons.bolt_rounded,
            price: _fuelPrices?.elektrik,
            color: const Color(0xFF0891B2),
            updatedAt: _fuelPrices?.updatedAt,
          ),
        ],
      ),
    ),
  );
}
```

Sınıfın dışına (dosyanın sonuna) yeni private widget ekle:

```dart
class _FuelPriceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? price;
  final Color color;
  final DateTime? updatedAt;

  const _FuelPriceChip({
    required this.label,
    required this.icon,
    required this.price,
    required this.color,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF3C3836) : AppTheme.surfaceAlt;
    final border = isDark ? const Color(0xFF44403C) : AppTheme.borderSubtle;
    final priceText = price != null
        ? '${price!.toStringAsFixed(2)} ₺'
        : '--';

    return GestureDetector(
      onTap: () {
        final timeStr = updatedAt != null
            ? DateFormat('HH:mm').format(updatedAt!.toLocal())
            : '--:--';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fiyatlar Ankara (06) bazlıdır · Güncelleme: $timeStr'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFFA8A29E) : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  priceText,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: `build()` içinde fiyat barını ekle**

`vehicle_list_screen.dart` içindeki `build()` metodunda, `_buildGreeting()` çağrısından sonra, `Expanded(` satırından önce ekle:

```dart
_buildFuelPriceBar(),
```

Sonuç:
```dart
children: [
  _buildAppBar(),
  _buildGreeting(),
  _buildFuelPriceBar(),   // ← yeni
  Expanded(
    child: _loading ? ...
```

- [ ] **Step 5: Uygulamayı çalıştır ve fiyat barını doğrula**

```bash
flutter run
```

Ana ekranda greeting altında 4 yakıt chip'i görünmeli. `.env` değerleri henüz girilmemişse `--` göstermeli (bu beklenen davranış).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/vehicle_list_screen.dart
git commit -m "feat: add fuel price bar to vehicle list screen"
```

---

## Task 6: trip_screen — Akıllı Fiyat Doldurma

**Files:**
- Modify: `lib/screens/trip_screen.dart`

- [ ] **Step 1: Import ekle**

Dosyanın başına, diğer import'ların yanına:

```dart
import '../services/fuel_price_service.dart';
```

- [ ] **Step 2: `_priceAutofilled` state alanı ekle**

`_TripScreenState` içine ekle:

```dart
bool _priceAutofilled = false;
```

- [ ] **Step 3: `_priceCtrl` listener'ını güncelle**

`initState` içinde listener zaten var: `_priceCtrl.addListener(_onInputChange)`. Bunu değiştirmeden, `_onInputChange` metodunu şöyle güncelle — mevcut `setState` çağrısında `_priceAutofilled = false` sıfırlamasını ekle:

Mevcut `_onInputChange`:
```dart
void _onInputChange() {
  ...
  setState(() {});
  ...
}
```

`setState(() {})` içine ekle:
```dart
setState(() {
  _priceAutofilled = false;
});
```

Not: Tam değişiklik — mevcut metod yapısını koruyarak sadece `setState(() {})` → `setState(() { _priceAutofilled = false; })` yap.

- [ ] **Step 4: `_defaultPrice` metodunda Elektrik değerini düzelt**

`trip_screen.dart` içinde `_defaultPrice` metodunu bul (satır ~95-101):

```dart
double _defaultPrice(String fuelType) {
  switch (fuelType) {
    case 'LPG': return 18.0;
    case 'Elektrik': return 3.5;   // ← BU SATIR
    default: return 45.0;
  }
}
```

`return 3.5` satırını `return 15.90` olarak değiştir.

- [ ] **Step 5: `_loadStatsForVehicle` metodunu güncelle**

Mevcut metod (`trip_screen.dart` satır ~70-84):

```dart
Future<void> _loadStatsForVehicle(Vehicle v) async {
  if (v.id == null) return;
  final stats = await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
  final l100 = (stats['litersPer100Km'] as num).toDouble();
  final avgPrice = (stats['avgPrice'] as num).toDouble();
  final defaultL100 = _defaultConsumption(v.fuelType);
  final defaultPrice = _defaultPrice(v.fuelType);
  if (!mounted) return;
  setState(() {
    _consumCtrl.text =
        (l100 > 0 ? l100 : defaultL100).toStringAsFixed(1);
    _priceCtrl.text =
        (avgPrice > 0 ? avgPrice : defaultPrice).toStringAsFixed(2);
  });
}
```

Bunu şununla değiştir:

```dart
Future<void> _loadStatsForVehicle(Vehicle v) async {
  if (v.id == null) return;

  // Araç değişiminde autofill göstergesini sıfırla
  if (mounted) setState(() => _priceAutofilled = false);

  final stats = await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
  final l100 = (stats['litersPer100Km'] as num).toDouble();
  final avgPrice = (stats['avgPrice'] as num).toDouble();
  final defaultL100 = _defaultConsumption(v.fuelType);
  final defaultPrice = _defaultPrice(v.fuelType);

  if (!mounted) return;
  setState(() {
    _consumCtrl.text =
        (l100 > 0 ? l100 : defaultL100).toStringAsFixed(1);
    // Tarihsel ortalama varsa onu kullan (autofill değil)
    if (avgPrice > 0) {
      _priceCtrl.text = avgPrice.toStringAsFixed(2);
      _priceAutofilled = false;
    } else {
      // Tarihsel veri yoksa live fiyatı doldur (sonraki satırda async)
      _priceCtrl.text = defaultPrice.toStringAsFixed(2);
    }
  });

  // Tarihsel veri yoksa live fiyatı dene
  if (avgPrice <= 0) {
    final livePrices = await FuelPriceService.instance.getPrices();
    if (!mounted) return;
    final livePrice = livePrices?.priceFor(v.fuelType);
    if (livePrice != null) {
      setState(() {
        _priceCtrl.text = livePrice.toStringAsFixed(2);
        _priceAutofilled = true;
      });
    }
  }
}
```

- [ ] **Step 6: Fiyat alanına autofill göstergesi ekle**

`_buildInputSection` içindeki `Yakit Fiyati / Sarj Fiyati` input alanını bul (satır ~404-411):

```dart
_inputField(
  controller: _priceCtrl,
  label: isElectric ? 'Sarj Fiyati' : 'Yakit Fiyati',
  suffix: isElectric ? 'TL/kWh' : 'TL/L',
  icon: isElectric ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
  iconColor: const Color(0xFFD97706),
  hint: '0.00',
),
```

`helperText` parametresini ekle:

```dart
_inputField(
  controller: _priceCtrl,
  label: isElectric ? 'Sarj Fiyati' : 'Yakit Fiyati',
  suffix: isElectric ? 'TL/kWh' : 'TL/L',
  icon: isElectric ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
  iconColor: const Color(0xFFD97706),
  hint: '0.00',
  helperText: _priceAutofilled ? '✓ Güncel fiyat uygulandı' : null,
),
```

- [ ] **Step 7: `_inputField` metodunda `helperText` renk desteği ekle**

`_inputField` metodunu bul. Mevcut `helperText` parametresi zaten var. `TextField`'ın `decoration` içinde `helperText` ve `helperStyle` ekle:

```dart
// Mevcut decoration içine ekle:
helperText: helperText,
helperStyle: helperText != null && helperText!.startsWith('✓')
    ? const TextStyle(color: AppTheme.successColor, fontSize: 11)
    : const TextStyle(color: AppTheme.textHint, fontSize: 11),
```

- [ ] **Step 8: Analiz çalıştır**

```bash
flutter analyze lib/screens/trip_screen.dart
```

Beklenen: `No issues found!`

- [ ] **Step 9: Manuel test — araç seçimi**

```bash
flutter run
```

Test senaryosu:
1. Seyahat hesaplayıcıyı aç
2. Hiç yakıt kaydı olmayan bir araç seç → `"✓ Güncel fiyat uygulandı"` görünmeli
3. Yakıt fiyatı alanını elle değiştir → gösterge kaybolmalı
4. Yakıt kaydı olan bir araç seç → tarihsel ortalama gelmeli, gösterge olmamalı

- [ ] **Step 10: Commit**

```bash
git add lib/screens/trip_screen.dart
git commit -m "feat: add smart price autofill to trip screen"
```

---

## Task 7: Final Kontrol

- [ ] **Step 1: Tüm değişiklikleri analiz et**

```bash
flutter analyze
```

Beklenen: `No issues found!`

- [ ] **Step 2: Uygulamayı release modda derle (isteğe bağlı)**

```bash
flutter build apk --debug
```

Beklenen: Build başarılı, hata yok.

- [ ] **Step 3: Edge function'ın tabloyu güncellediğini doğrula**

Supabase Dashboard > SQL Editor:
```sql
SELECT * FROM prices ORDER BY date DESC LIMIT 5;
```

Edge function manuel tetiklendikten sonra buraya kayıt düşmeli.

- [ ] **Step 4: Final commit**

```bash
git add .env.example
git status  # .env tracked değilse sorun yok
git commit -m "feat: fuel price integration complete"
```

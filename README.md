# Yakıt Yönet

Araç yakıt ve masraf takibi için Türkçe, çevrimdışı öncelikli (offline-first) Android uygulaması. Verileriniz cihazınızda kalır; reklam, analitik veya üçüncü taraf izleme yoktur.

- **Sürüm:** 1.0.0 · **Platform:** Android · **Paket:** `com.yakityonet.yakit_yonet`

## Özellikler

- **Çoklu araç takibi** — fotoğraflı araç kartları
- **Yakıt kayıtları** — tam depo bazlı tüketim hesabı (L/100km, TL/km) ve grafikler (fl_chart)
- **OCR ile fiş tarama** — ML Kit, tamamen cihaz üzerinde
- **Bakım kayıtları** — km ve maliyet takibi
- **Sigorta / vergi takibi** — MTV, trafik, kasko, muayene; bitiş tarihi hatırlatmaları (yerel bildirimler)
- **Yaklaşan ödemeler paneli** ve genel istatistikler
- **Yolculuk maliyeti hesaplama** — mesafe, fiyat ve tüketime göre tahmini yakıt gideri
- **PDF / Excel raporları** — çevrimdışı Noto fontları ile
- **JSON dışa/içe aktarma** — içe aktarmadan önce otomatik güvenlik yedeği
- **Google Drive yedekleme** — OAuth `appDataFolder`; haftalık/aylık otomatik telafi yedeği
- **Güncel yakıt fiyatı referansı** — Supabase REST (anonim, kişisel veri gönderilmez)
- **Ana ekran widget'ları** — 4x2 ve 4x1 Android widget'ları
- **Karanlık / aydınlık tema**, Türkçe yerel ayar (virgüllü ondalık girişi dahil)

## Gizlilik

Tüm veriler cihazdaki SQLite veritabanında saklanır. Cihaz dışına çıkan tek veri:

1. Kullanıcının kendi Google Drive `appDataFolder` yedekleri (isteğe bağlı)
2. Anonim yakıt fiyatı sorguları (Supabase, kişisel veri içermez)

## Ekran Yapısı

| Ekran | Açıklama |
|---|---|
| Splash / Onboarding | Açılış ve ilk kullanım tanıtımı |
| Araç Listesi | Araç kartları, yaklaşan ödemeler paneli |
| Araç Ekle/Düzenle | Fotoğraf, plaka, km bilgileri |
| Araç Detayı | Sekmeler: Yakıt · Bakım · Sigorta/Vergi |
| İstatistikler | Tüketim ve maliyet grafikleri |
| Raporlar | PDF / Excel çıktıları |
| Yolculuk | Yolculuk maliyeti hesaplayıcı |
| Yedekleme | Google Drive yedekleme/geri yükleme, JSON dışa/içe aktarma |

## Mimari

Flutter + sqflite üzerine katmanlı yapı:

- **`lib/database/`** — `DatabaseHelper` (singleton): SQLite şeması, transaction'lı CRUD, km bütünlüğü (currentKm ratchet), WAL checkpoint
- **`lib/models/`** — `Vehicle`, `FuelRecord`, `MaintenanceRecord`, `InsuranceTaxRecord`
- **`lib/services/`** — Google Drive yedekleme, OCR (ML Kit), bildirimler, yakıt fiyatı (Supabase REST), PDF/Excel rapor, ana ekran widget'ı, konum paylaşımı
- **`lib/screens/`** — ekranlar ve sekmeler (UI)
- **`lib/utils/`** — `fuel_math.dart` (tüketim/istatistik hesapları), `parsing.dart` (virgüllü ondalık ayrıştırma)
- **`lib/theme/`** — tema tanımları

## Kurulum

```bash
git clone <repo-url>
cd YakitYonet
cp .env.example .env   # SUPABASE_URL ve SUPABASE_ANON_KEY değerlerini doldur
flutter pub get
```

`.env` dosyası yalnızca yakıt fiyatı servisi için Supabase bilgilerini içerir; boş bırakılırsa uygulama fiyat önerisi olmadan çalışır.

## Build

```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Google Play için App Bundle
flutter build appbundle --release
```

## Test

```bash
flutter test
```

Testler: `test/fuel_math_test.dart`, `test/parsing_test.dart`, `test/widget_test.dart`

## Klasör Yapısı

```
lib/
├── main.dart
├── database/        # SQLite (sqflite) katmanı
├── models/          # Veri modelleri
├── screens/         # Ekranlar (tabs/ dahil)
├── services/        # Drive, OCR, bildirim, rapor, fiyat, widget
├── theme/           # Tema
├── utils/           # Hesap ve ayrıştırma yardımcıları
└── widgets/         # Ortak widget'lar
android/             # Android platform kodu + home screen widget'ları
assets/              # Görseller ve çevrimdışı fontlar (Noto)
supabase/            # Yakıt fiyatı servisi şema/fonksiyonları
test/                # Birim ve widget testleri
```

## Lisans

TBD — lisans dosyası eklenecek.

## İletişim

Soru ve geri bildirim için: <iletişim adresi eklenecek>

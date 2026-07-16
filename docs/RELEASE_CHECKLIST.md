# Yakıt Yönet — Yayın Kontrol Listesi (v1.0.0)

Google Play'e ilk yayın öncesi adım adım kontrol listesi. Sıralama önemlidir:
önce **manuel engelleyiciler**, sonra build, test ve mağaza adımları.

---

## 🚨 KRİTİK MANUEL ENGELLEYİCİLER — bunlar yapılmadan yayınlamayın

### 1. google-services.json yalnızca DEBUG SHA-1 içeriyor → Drive yedekleme release'te ÇALIŞMAZ

**Durum:** `android/app/google-services.json` şu an tek bir `certificate_hash`
içeriyor ve bu **debug keystore**'un SHA-1'i. Release imzalı APK/AAB'de Google
girişi `DEVELOPER_ERROR` (ApiException 10) ile başarısız olur → Drive
yedekleme/geri yükleme tamamen ölü kalır.

**Yapılacaklar:**

- [ ] Upload keystore SHA-1'ini al:
  ```
  keytool -list -v -keystore android/app/upload-keystore.jks
  ```
  (Şifre: `android/key.properties` içindeki `storePassword`. Çıktıdaki
  `SHA1:` satırını kopyala.)
- [ ] **Play App Signing SHA-1**'ini al: Play Console → *Test and release →
  Setup → App integrity → App signing key certificate* altındaki SHA-1.
  Play, kullanıcıya dağıtılan APK'yı kendi anahtarıyla yeniden imzalar; bu
  SHA-1 eklenmezse mağazadan inen uygulamada giriş yine kırılır.
- [ ] Google Cloud Console → *APIs & Services → Credentials* → paket adı
  `com.yakityonet.yakit_yonet` için **iki yeni Android OAuth client** oluştur:
  biri upload keystore SHA-1, biri Play App Signing SHA-1 ile.
  (Alternatif: Firebase kullanılıyorsa Firebase Console → Project settings →
  Android app → "Add fingerprint" ile aynı iki SHA-1'i ekle.)
- [ ] `google-services.json`'u **yeniden indir** ve `android/app/` içine koy
  (yeni dosyada 3 `certificate_hash` görünmeli: debug + upload + Play signing).
- [ ] Release imzalı build ile fiziksel cihazda **Google girişi + Drive
  yedeklemeyi fiilen test et** (aşağıdaki cihaz test listesine dahil).

### 2. Gizlilik politikası URL'si (Play Console zorunlu alan)

- [ ] `docs/PRIVACY_POLICY.md` içeriğini herkese açık bir URL'de barındır.
  Öneri: repo'da **GitHub Pages** aç (Settings → Pages → main branch, /docs
  klasörü) → `https://<kullanici>.github.io/YakitYonet/PRIVACY_POLICY`
  benzeri bir adres elde edilir.
- [ ] URL'yi Play Console → *App content → Privacy policy* alanına gir.
- [ ] URL'nin oturum açmadan, mobilde açıldığını doğrula.

### 3. Data Safety (Veri Güvenliği) formu

- [ ] Play Console → *App content → Data safety* formunu
  `docs/PLAY_STORE_LISTING.md` içindeki hazır cevaplarla doldur.
- [ ] Özet beyan tutarlı olmalı: veri cihazda kalır; toplanan/paylaşılan
  kullanıcı verisi yok; Drive yedekleri kullanıcının kendi hesabındaki
  `appDataFolder`'a gider (geliştiriciye veri akışı yok); yakıt fiyatı
  sorgusu anonim, kişisel veri içermez; reklam/analitik/üçüncü taraf
  izleme yok.

---

## Sürüm numarası

- [ ] `pubspec.yaml` → `version: 1.0.0+1` bu ilk yayın için uygun.
  Sonraki her yükleme öncesi **build numarasını artır** (`1.0.1+2` gibi).
  `android/app/build.gradle.kts` artık `flutter.versionCode` /
  `flutter.versionName` okuyor — gradle tarafında elle değişiklik gerekmez,
  tek doğruluk kaynağı pubspec'tir.

## Kod kalitesi ve build

- [ ] `flutter analyze` — sıfır hata (uyarıları gözden geçir).
- [ ] `flutter test` — tüm testler geçiyor.
- [ ] `flutter build appbundle --release` — AAB üret
  (`build/app/outputs/bundle/release/app-release.aab`).
  İmzalama `android/key.properties` + `upload-keystore.jks` üzerinden
  otomatik; build sonunda "signed" olduğundan emin ol.
- [ ] Cihaz testi için ayrıca: `flutter build apk --release`.

## Fiziksel cihazda release APK testi

Release APK'yı gerçek bir Android cihaza kur (`flutter install --release`
veya APK'yı elle yükle) ve şunları tek tek doğrula:

- [ ] **Google girişi** — hesap seçimi başarılı, DEVELOPER_ERROR yok
  (Engelleyici #1'in kanıtı).
- [ ] **Drive yedekleme + geri yükleme** — yedek al, uygulamayı sil/veriyi
  değiştir, geri yükle; kayıtların ve hatırlatıcıların geri geldiğini kontrol et.
- [ ] **Bildirim izni ve hatırlatıcı** — Android 13+ cihazda izin isteği
  geliyor mu; yakın tarihli bir sigorta/MTV kaydı ekleyip hatırlatıcı
  bildirimin fiilen düştüğünü test et.
- [ ] **OCR fiş tarama** — gerçek bir akaryakıt fişi tara; tutar, litre ve
  litre fiyatı alanlarının dolduğunu kontrol et (ML Kit cihaz üstü model,
  release'te ProGuard/R8 sonrası çalıştığını özellikle doğrula).
- [ ] **Widget ekleme** — 4x2 ve 4x1 widget'ları ana ekrana ekle, veri
  değişince güncellendiklerini gör.
- [ ] **Virgüllü sayı girişi** — `12,5` gibi virgüllü litre/tutar girişleri
  doğru kaydediliyor ve raporlarda doğru görünüyor.
- [ ] **JSON dışa/içe aktarma** — dışa aktar, içe aktar; onay uyarılarının
  çıktığını ve import öncesi güvenlik yedeğinin oluştuğunu doğrula.
- [ ] Karanlık/aydınlık tema geçişi, çoklu araç + fotoğraf, grafikler,
  PDF/Excel rapor üretimi (çevrimdışı Noto fontları ile Türkçe karakterler).
- [ ] Uçak modunda temel akışlar (offline-first iddiasının doğrulaması).

## Play Console yayın adımları

- [ ] AAB'yi önce **Internal testing** kanalına yükle; kendine + birkaç
  test kullanıcısına dağıt, mağazadan inen (Play imzalı) sürümde Google
  girişini bir kez daha doğrula. Sorun yoksa Production'a terfi ettir.
- [ ] **Ekran görüntüleri** çek (telefon, en az 2–8 adet): ana ekran /
  yaklaşan ödemeler paneli, yakıt kayıtları + tüketim grafiği, OCR tarama,
  istatistikler, sigorta/vergi takibi, karanlık tema örneği, widget'lı
  ana ekran. 512x512 ikon ve 1024x500 feature graphic hazırla.
- [ ] Mağaza metinlerini `docs/PLAY_STORE_LISTING.md`'den kopyala
  (başlık, kısa açıklama, uzun açıklama — Türkçe).
- [ ] İçerik derecelendirme anketini doldur (Herkes / Everyone beklenir).
- [ ] Hedef kitle: 18+ ya da 13+ seç; çocuklara yönelik değil.

## Sürüm notları taslağı (v1.0.0)

```
İlk sürüm 🎉
• Çoklu araç takibi (fotoğraflı)
• Yakıt kayıtları, ortalama tüketim (L/100km) ve maliyet (TL/km) grafikleri
• Fişten otomatik okuma (OCR) — tamamen cihaz üstü
• Bakım kayıtları; MTV, trafik, kasko ve muayene takibi + hatırlatıcılar
• Yaklaşan ödemeler paneli ve genel istatistikler
• PDF/Excel rapor, JSON yedekleme/geri yükleme
• Google Drive'a otomatik yedekleme (haftalık/aylık)
• Ana ekran widget'ları, karanlık tema
Reklamsız, izleyicisiz — verileriniz cihazınızda kalır.
```

## Bilinen sınırlamalar

- **Supabase anon key APK içinde gömülü** (`lib/services/fuel_price_service.dart`,
  `apikey` + `Bearer` header'ları). Anon key'in APK'dan çıkarılabileceği
  varsayılmalıdır; bu yüzden Supabase tarafında **RLS ve salt-okunur policy
  ZORUNLU**:
  - [ ] Yakıt fiyatı tablosunda RLS açık, `anon` rolüne yalnızca `SELECT`
    policy tanımlı; `INSERT/UPDATE/DELETE` yok.
  - [ ] Projedeki diğer tablolar `anon` rolüne tamamen kapalı.
  - [ ] Doğrulama: anon key ile REST üzerinden bir `INSERT` denemesi yap,
    reddedildiğini gör.
- **iOS desteklenmiyor** — uygulama yalnızca Android hedefler (widget'lar,
  bildirim ve imzalama akışı Android'e özgü). iOS talebi gelirse ayrı
  çalışma gerektirir.
- Yakıt fiyatı verisi internete bağlıdır; çevrimdışıyken 6 saatlik önbellek
  kullanılır, önbellek yoksa fiyat referansı gösterilmez (uygulamanın geri
  kalanı tamamen çevrimdışı çalışır).

## Bağımlılık notları (build kırılmasın diye)

- **`home_widget` 0.9.0'a sabitlendi** (`pubspec.yaml`, `^` yok): 0.9.2+1
  sürümü Kotlin derleme hatası içeriyor (`Unresolved reference
  'HomeWidgetLaunchIntent'`). Yükseltmeden önce release build ile test edin.
- **`androidx.glance` 1.1.1'e zorlandı** (`android/build.gradle.kts`
  `resolutionStrategy.force`): home_widget `glance-appwidget:1.+` açık aralığı
  bildiriyor ve bu, compileSdk 37 isteyen alpha sürümlere kayıyor.
- **Alt projeler JVM 11'e sabitlendi** (`android/build.gradle.kts`) ve
  `kotlin.jvm.target.validation.mode=warning` (`gradle.properties`):
  home_widget Java 1.8 + Kotlin karışımı derliyor; bunlar olmadan
  `compileReleaseKotlin` başarısız olur.
- Majör paket yükseltmeleri (google_sign_in 7.x, flutter_map 8.x, fl_chart
  1.x) bilinçli olarak YAPILMADI — yayın sonrası ayrı bir çalışmada, tek tek
  ve release build testiyle yükseltin.

# Yakıt Yönetimi Uygulaması (YakıtYonet) - Geliştirme Planı

## 1. Proje Özeti
*   **Platform:** Sadece Android
*   **Teknoloji:** Flutter (UI/UX), Core Framework
*   **Veritabanı:** Yerel Veritabanı (SQLite)
*   **Depolama:** Fotoğraflar doğrudan cihaz hafızasında (local storage) tutulacak.
*   **Yedekleme Modeli:** Cihazdan Google Drive'a SQLite yedeği (Manuel & Otomatik).

---

## 2. Uygulama Akışı ve Ekranlar

### 2.1. Açılış ve Karşılama (Onboarding)
*   **Splash Screen:** Uygulama açıldığında gösterilecek akıcı, çok kısa bir yakıt simülasyonu animasyonu (Lottie veya Rive kullanılabilir).
*   **İlk Giriş / Tutorial:** Kullanıcının uygulamayı ilk açışında temel özellikleri kısaca tanıtan 3-4 sayfalık swipe (kaydırılabilir) ekran.
*   **Yedekleme Tercihi:** Tutorial aşamasının sonunda veya hemen sonrasında, kullanıcıya "Otomatik Yedekleme" özelliği sorulacak. Seçenekler: *Kapalı*, *Haftalık*, *Aylık*.

### 2.2. Araç Listesi (Ana Ekran)
*   Uygulama açıldıktan sonra (splash arkası) ana sayfa olarak karşımıza çıkacak.
*   **Görünüm:** Eklenmiş tüm araçların şık araç kartları şeklinde alt alta sıralandığı bir liste (Örn: 3 araç bir arada görünür).
*   **Araç Kartı İçeriği:** Seçilen Araç Fotoğrafı, Araç Adı, Güncel Kilometresi, Yakıt Tüketim Özeti (TL/KM maliyeti vb.).
*   **Aksiyon:** Ekranın sağ üst köşesinde yeni araç eklemek için belirgin bir `+` butonu. Kartların üzerine tıklandığında "Araç Detay" sayfasına geçiş.
*   **Genel Menü/Drawer (Yan veya Alt Menü):** Genel İstatistikler, Veri İçe/Dışa Aktar, Drive Yedekleme Ayarları gibi seçeneklere ulaşım.

### 2.3. Yeni Araç Ekleme Ekranı
*   Kullanıcıya "+ "butonuna basınca sunulacak veri giriş formu.
*   **Veri Alanları:**
    *   **Fotoğraf:** Kameradan yeni çekim ya da galeriden seçme.
    *   **Araç Adı:** (Örn: "Şahsi Arabam", "Şirket Aracı")
    *   **Mevcut KM:** Başlangıç kilometresi.
    *   **Yakıt Türü:** Dropdown / Seçenekli (LPG, Benzin, Dizel, Elektrik).
    *   **Depo Kapasitesi:** (Litre / kWh türünden tam depo hacmi).

### 2.4. Araç Detay Ekranı
*   Tıklanan aracın detaylı profili.
*   **Üst Bilgi Kartı:** Son girilen KM, Toplam yapılan KM vb. kümülatif ana veriler.
*   **Sekmeli (Tab) Yapı:** 3 Ana Sekme (Akaryakıt, Bakım, Vergi ve Sigorta).

#### Sekme 1: Akaryakıt Verileri
*   **Metrikler / Göstergeler:** 
    *   İlk yakıt alınan tarih.
    *   Tüketim (TL/KM) ve Tüketim (L/100KM).
    *   Ortalama akaryakıt (veya kWh) fiyatı.
    *   Toplam alım sayısı.
    *   Toplam maliyet ve Toplam miktar.
    *   *Önemli Kural:* **Son yakıt alımı** "Toplam maliyete ve miktara" sistem doğruluğu (Tüketim hesaplaması tam depo arası yapıldığı varsayımıyla) gereği DAHİL EDİLMEYECEK. Kullanıcıya sayfa altında *"Not: Araç tüketim hesaplamalarının doğruluğu amacıyla yapılan son akaryakıt alımı toplam maliyet ve miktara dahil edilmemiştir."* şeklinde şık, ufak renkli bir uyarı gösterilecek.
*   **Grafikler (Min. 2 Adet):**
    1.  Fiyat - Akaryakıt Miktarı (Tarihe göre değişimi gösteren çizgi/bar grafik).
    2.  TL/KM - L/100KM (Zamana veya kilometreye bağlı tüketim eğrisi).
*   **Aksiyon:** "Yeni Yakıt Alımı Ekle" butonu (Tarih, KM, Alınan Litre, Litre Fiyatı, Toplam Tutar, Depo Doldu mu? bilgileri).

#### Sekme 2: Bakım Verileri
*   Aracın geçmiş bakımlarının kronolojik listesi (Tarih, KM, Yapılan İşlemler, Maliyet).
*   **Grafikler:** Aylık veya yıllık bakım maliyet trendleri, parça bazlı harcama dağılımı vb.
*   **Aksiyon:** "Yeni Bakım Ekle" butonu.

#### Sekme 3: Vergi ve Sigorta Verileri
*   Trafik Sigortası, Kasko, MTV (Motorlu Taşıtlar Vergisi) vb. sabit/yıllık giderler tablosu.
*   **Grafikler:** Yıllara veya ödeme türlerine göre (Vergi vs. Sigorta) oransal pasta/çubuk grafikler.
*   **Aksiyon:** "Yeni Poliçe / Vergi Ödemesi Ekle" butonu.

### 2.5. Genel İstatistikler Sayfası
*   Ana ekrandan/menüden erişilen global pencere.
*   Kullanıcının kayıtlı tüm araçlarını kapsayan konsolide raporlar.
*   **Grafik & Tablolar:** Tüm filonun (tüm araçların) aylık toplam gideri, araçlar arası maliyet kıyaslaması (Hangi araç daha masraflı?), kategorilere göre (Yakıt vs Bakım) toplam dağılım pasta grafiği.

---

## 3. Veri Yönetimi, Dışa Aktarım ve Yedekleme

*   **İçe Aktar / Dışa Aktar (Yerel Cihaz):** 
    *   Kullanıcı ayarlardan sisteme ait tüm DB verilerini (fotoğraflar hariç) CSV veya JSON dosyası olarak cihazına Dışa Aktarabilir.
    *   Aynı şekilde bu dosyayı içeri alarak verileri (sıfır kurulumda vb.) İçe Aktarabilir.
*   **Google Drive Otomatik Yedekleme Modülü:**
    *   Google hesabı ile yetkilendirme (OAuth).
    *   Kullanıcının tutorial'da veya ayarlarda seçtiği periyoda göre (Haftalık, Aylık) arkaplan işlemi (WorkManager) ile SQLite dosyasının gizli "appDataFolder" Drive dizinine yedeklenmesi.
    *   Uygulama çökerse veya silinirse, yeni kurulumda "Drive'dan Geri Yükle" diyerek tüm verilerin sorunsuz geri gelmesi.
    *   İstenildiği an Menüden "Manuel Olarak Şimdi Yedekle" butonu ile Drive'a zorunlu veri gönderimi yapılabilmesi.

---

## 4. Geliştirme Yaklaşımı (Fazlar)
1.  **Faz 1:** Temel Mimari (UI Tema ve Renk Paleti), DB/SQLite tablolarının (Araç, Yakıt, Bakım, Vergi) oluşturulması. Ana Ekran ve Araç Ekleme Ekranı.
2.  **Faz 2:** Akaryakıt Hesaplama Algoritmaları (Son kaydı hariç tutma dahil) ve Grafikler.
3.  **Faz 3:** Bakım ve Sigorta Sekmeleri, Genel İstatistik panosunun tamamlanması.
4.  **Faz 4:** Splash simülasyonu ve Tutorial sayfalarının yapılması. İçe/Dışa JSON veri aktarımının test edilmesi.
5.  **Faz 5:** Google Drive Entegrasyonu, Arkaplan görevlisiyle otomatik yedeklemenin çalışır hale getirilmesi. Son hata düzeltmeleri ve Canlıya Hazırlık (Release).

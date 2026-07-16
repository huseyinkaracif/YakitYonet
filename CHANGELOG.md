# Changelog

Bu projedeki tüm önemli değişiklikler bu dosyada belgelenir.

Format [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) standardına,
sürümleme [Semantic Versioning](https://semver.org/lang/tr/) kurallarına uygundur.

## [1.0.0] - 2026-07-16

İlk kararlı sürüm. Yakıt Yönet; Türkçe, yalnızca Android, çevrimdışı öncelikli
(offline-first) bir yakıt ve araç gideri takip uygulamasıdır. Reklam, analitik
veya üçüncü taraf izleme içermez; veriler cihazda kalır (kullanıcının kendi
Google Drive appData yedekleri ve anonim yakıt fiyatı sorguları hariç).

### Eklendi

- **Çoklu araç takibi**: Fotoğraflı araç kayıtları, araç bazlı istatistikler.
- **Yakıt kayıtları**: Litre, tutar, km ve tarih girişi; tam depo (full-tank)
  kayıtları arasında gerçek tüketim hesabı (L/100km ve TL/km).
- **Grafikler**: fl_chart ile tüketim, maliyet ve fiyat eğilimi grafikleri.
- **Fiş tarama (OCR)**: ML Kit ile cihaz üzerinde çalışan metin tanıma;
  fişten toplam tutar, litre ve litre fiyatı çıkarımı. Görüntüler cihaz
  dışına gönderilmez.
- **Bakım kayıtları**: Bakım türü, maliyet ve km takibi.
- **Sigorta ve vergi takibi**: MTV, trafik sigortası, kasko ve muayene
  kayıtları; bitiş tarihlerine göre yerel bildirimlerle hatırlatma.
- **Yaklaşan ödemeler paneli**: Vadesi yaklaşan sigorta/vergi/muayene
  kalemlerinin tek ekranda özeti.
- **Genel istatistikler**: Tüm araçlar için toplam maliyet, ortalama fiyat
  ve tüketim özetleri.
- **PDF ve Excel raporları**: Çevrimdışı gömülü Noto fontlarıyla Türkçe
  karakter destekli rapor üretimi ve paylaşım.
- **JSON dışa/içe aktarma**: Tüm verinin tek dosyada yedeklenmesi;
  içe aktarmada güvenlik onayları.
- **Google Drive yedekleme**: Google ile giriş (OAuth, yalnızca
  appDataFolder kapsamı); haftalık/aylık otomatik telafi (catch-up)
  yedekleme; manuel yedekleme ve geri yükleme.
- **Yakıt fiyatı referansı**: Supabase REST üzerinden anonim güncel fiyat
  bilgisi; kişisel veri gönderilmez.
- **Android ana ekran widget'ları**: 4x2 detaylı ve 4x1 kompakt widget.
- **Karanlık/aydınlık tema**: Sistem temasına uyumlu arayüz.
- **Türkçe yerelleştirme**: Virgül ondalık ayraçlı sayı girişi dahil tam
  Türkçe deneyim.

### Düzeltildi

Yayın hazırlığı sırasında yapılan veri bütünlüğü ve kararlılık iyileştirmeleri:

- **Yabancı anahtar bütünlüğü**: SQLite bağlantısında `PRAGMA foreign_keys = ON`
  etkinleştirildi; araç silme işlemi tek transaction içinde ilgili yakıt,
  bakım ve sigorta/vergi kayıtlarını (önceden kalmış yetim kayıtlar dahil)
  temizliyor ve araç fotoğrafını diskten güvenle siliyor.
- **Güncel km tutarlılığı**: Yakıt/bakım kaydı ekleme, düzenleme ve silme
  işlemlerinde aracın güncel km değeri aynı transaction içinde yeniden
  hesaplanıyor; kayıt silindiğinde km artık geride kalan en yüksek değere
  güvenle geri dönüyor.
- **Güvenli Drive geri yükleme**: İndirilen yedek dosyası SQLite başlık ve
  `integrity_check` doğrulamasından geçiyor; mevcut veritabanı `.bak` olarak
  saklanıp değişim atomik yapılıyor, hata durumunda otomatik geri alınıyor;
  geri yükleme sonrası bildirimler veritabanından yeniden planlanıyor.
- **WAL checkpoint'li yedekleme**: Drive yedeklemesi öncesi
  `PRAGMA wal_checkpoint(TRUNCATE)` çalıştırılıp anlık dosya kopyasından
  (snapshot) yükleme yapılıyor; eski yedek, yeni yükleme başarılı olmadan
  silinmiyor.
- **İçe aktarma güvenliği**: JSON içe aktarma öncesi sürüm ve tablo yapısı
  doğrulanıyor; mevcut veri otomatik güvenlik yedeğine
  (`yedek_oncesi_import_<zaman>.json`) yazılıyor; içe aktarma tek transaction
  içinde ve yalnızca bilinen sütunlarla yapılıyor.
- **Türkçe virgül ondalık desteği**: Litre, tutar ve fiyat alanlarında virgül
  ile ondalık giriş tutarlı şekilde işleniyor.
- **Android 13+ bildirim izni**: `POST_NOTIFICATIONS` izni çalışma zamanında
  isteniyor; hatırlatmalar cihaz yeniden başlatıldığında da korunuyor.
- **Tam depo bazlı tüketim hesabı**: L/100km ve TL/km hesapları ortak
  `fuel_math` modülünde toplandı; ortalama fiyat ağırlıklı ortalama
  (toplam tutar / toplam litre) olarak hesaplanıyor; kayıtlar tarih + km
  sırasıyla tutarlı sıralanıyor.
- **Kayıt düzenleme ve geri alma**: Yakıt/bakım kayıtları düzenlenebiliyor;
  silme işlemleri onaylı ve veri bütünlüğünü bozmadan geri hesaplanıyor.
- **Yaklaşan ödemeler paneli** ve **sigorta bitiş hatırlatıcıları** yayın
  öncesi gözden geçirilip bildirim planlaması güvenilir hale getirildi.
- **Çevrimdışı PDF fontları**: Noto fontları uygulamaya gömüldü; rapor
  üretimi internet bağlantısı gerektirmiyor.
- **Sürüm kodu düzeltmesi**: Google Play yayını için sürüm `1.0.0+1` olarak
  düzenlendi.
- **Gereksiz izinlerin kaldırılması**: Manifest yalnızca gerekli izinlerle
  sadeleştirildi (INTERNET, CAMERA, POST_NOTIFICATIONS, VIBRATE,
  RECEIVE_BOOT_COMPLETED); kamera donanımı zorunlu olmaktan çıkarıldı.

[1.0.0]: https://github.com/huseyinkaracif/YakitYonet/releases/tag/v1.0.0

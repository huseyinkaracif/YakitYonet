# Gizlilik Politikası — Yakıt Yönet

**Yürürlük Tarihi:** 16 Temmuz 2026
**Uygulama:** Yakıt Yönet (com.yakityonet.yakit_yonet)
**Platform:** Android

> **Not (yayıncı için):** Google Play Console'a bu politikanın herkese açık, barındırılmış bir URL'si verilmelidir (örneğin GitHub Pages üzerinden yayınlanabilir). Bu dosyanın deposundaki hali tek başına yeterli değildir.

---

## 1. Özet

Yakıt Yönet, araç ve yakıt giderlerinizi takip etmenizi sağlayan, **çevrimdışı öncelikli (offline-first)** bir uygulamadır. Verileriniz **yalnızca kendi cihazınızda** saklanır. Uygulamada **reklam yoktur, analitik yoktur ve üçüncü taraf takip teknolojisi kullanılmaz**. Bize (geliştiriciye) hiçbir kişisel veriniz iletilmez.

## 2. Toplanan ve Saklanan Veriler

Uygulamaya girdiğiniz tüm veriler cihazınızdaki yerel bir veritabanında (SQLite) tutulur:

- Araç bilgileri (marka, model, plaka, kilometre, araç fotoğrafı vb.)
- Yakıt kayıtları (tarih, litre, tutar, kilometre, istasyon vb.)
- Bakım kayıtları
- Sigorta ve vergi kayıtları (MTV, trafik sigortası, kasko, muayene)
- Uygulama tercihleri (tema, ayarlar)

Bu veriler cihazınızdan dışarı çıkmaz. İstisnalar yalnızca aşağıda açıklanan, **sizin başlattığınız** Google Drive yedekleme ile anonim yakıt fiyatı sorgusudur.

## 3. Google ile Giriş ve Google Drive Yedekleme

- Google Drive yedekleme özelliği **isteğe bağlıdır** ve yalnızca siz Google hesabınızla giriş yaptığınızda çalışır.
- Uygulama, Google Drive'ın yalnızca **uygulamaya özel gizli alanına** (`appDataFolder` kapsamı) erişim ister. Drive'ınızdaki diğer dosyalarınızı **göremez ve erişemez**.
- Yedek dosyası, veritabanınızın bir kopyasıdır ve **sizin kendi Google hesabınızda** saklanır. Geliştirici olarak bizim bu yedeğe **hiçbir erişimimiz yoktur**; veriler bize ait herhangi bir sunucuya gönderilmez.
- Yedekler haftalık veya aylık otomatik aralıkla (uygulama açıldığında telafi mantığıyla) veya elle alınabilir. Bu tercih cihazınızda saklanır.
- Google hesabı bağlantısını istediğiniz zaman uygulama içinden kesebilirsiniz.
- Google ile giriş sürecinde Google'ın kendi gizlilik politikası geçerlidir: <https://policies.google.com/privacy>

## 4. Fiş Tarama (OCR)

- Yakıt fişi tarama özelliği, Google **ML Kit Text Recognition** kullanır ve **tamamen cihaz üzerinde** çalışır.
- Taranan fiş görüntüleri ve tanınan metinler hiçbir sunucuya gönderilmez; işlem sonrası yalnızca sizin onayladığınız değerler yerel kayda yazılır.

## 5. Yakıt Fiyatı Bilgisi (Supabase)

- Uygulama, güncel referans yakıt fiyatlarını (benzin, dizel, LPG, elektrik) internet üzerinden anonim bir REST isteğiyle çeker.
- Bu istekte **hiçbir kişisel veri, kimlik veya araç bilgisi gönderilmez**; yalnızca güncel fiyat listesi indirilir ve cihazda önbelleğe alınır.
- İnternet bağlantısı yoksa uygulama önbellekteki son fiyatlarla veya fiyat bilgisi olmadan çalışmaya devam eder.

## 6. İzinler

| İzin | Kullanım Amacı |
|---|---|
| İnternet (`INTERNET`) | Anonim yakıt fiyatı çekme ve isteğe bağlı Google Drive yedekleme |
| Kamera (`CAMERA`) | Fiş tarama (OCR) ve araç fotoğrafı çekme; yalnızca siz kullandığınızda |
| Galeri / fotoğraf seçici | Araç fotoğrafı veya fiş görseli seçme; yalnızca seçtiğiniz görsele erişilir |
| Bildirimler (`POST_NOTIFICATIONS`) | Sigorta, vergi ve muayene son tarihleri için **yerel** hatırlatmalar; bildirimler cihaz üzerinde planlanır, sunucu kullanılmaz |
| Açılışta çalışma (`RECEIVE_BOOT_COMPLETED`) | Cihaz yeniden başlatıldığında planlanmış hatırlatmaların yeniden kurulması |
| Titreşim (`VIBRATE`) | Bildirim titreşimi |

Kamera ve bildirim izinleri isteğe bağlıdır; reddederseniz ilgili özellik dışında uygulama normal çalışır.

## 7. Reklam, Analitik ve Takip

- Uygulamada **reklam yoktur**.
- **Analitik veya telemetri toplanmaz** (Firebase Analytics, Crashlytics vb. yoktur).
- **Üçüncü taraf takip SDK'sı bulunmaz.**
- Kullanım davranışlarınız hiçbir şekilde izlenmez veya profillenmez.

## 8. Veri Paylaşımı

Verileriniz hiçbir üçüncü tarafla paylaşılmaz, satılmaz veya kiralanmaz. Uygulamadan ürettiğiniz PDF/Excel raporlarını veya JSON dışa aktarımlarını paylaşmak tamamen sizin kontrolünüzdedir.

## 9. Veri Saklama ve Silme

Tüm verilerinizin kontrolü sizdedir:

1. **Uygulama içinden:** Kayıtları ve araçları tek tek silebilir veya JSON dışa aktarma/içe aktarma ile verilerinizi yönetebilirsiniz.
2. **Tamamen silmek için:** Uygulamayı cihazınızdan kaldırın (veya uygulama verilerini temizleyin) — yerel veritabanı ve fotoğraflar dahil tüm veriler silinir.
3. **Drive yedeği:** Google Drive'daki uygulama yedeğini uygulama içinden veya Google hesap ayarlarınızdan (Ayarlar → Google Hesabı → Veriler ve gizlilik → Üçüncü taraf uygulamalar) silebilirsiniz. Uygulamanın Drive erişimini kaldırdığınızda `appDataFolder` içeriği Google tarafından temizlenir.

Bizim tarafımızda saklanan veri olmadığı için ayrıca bir silme talebi gerekmez.

## 10. Çocukların Gizliliği

Uygulama genel kitleye yöneliktir ve çocuklara özel içerik sunmaz; hiçbir kullanıcıdan kişisel veri toplanmadığı için çocuklardan da veri toplanmaz.

## 11. Değişiklikler

Bu politika güncellendiğinde yeni sürüm aynı adreste yayınlanır ve yürürlük tarihi güncellenir. Önemli değişiklikler uygulama güncelleme notlarında belirtilir.

## 12. İletişim

Sorularınız için: **[EMAIL]**

---

## English Summary

**Effective date: July 16, 2026 — Yakıt Yönet (com.yakityonet.yakit_yonet), Android**

- Yakıt Yönet is an **offline-first** fuel and vehicle expense tracker. All your data (vehicles, fuel, maintenance, insurance/tax records, photos) is stored **only on your device** in a local database.
- **No ads, no analytics, no third-party tracking.** The developer receives no personal data and operates no server that stores user data.
- **Google Sign-In / Drive backup (optional):** backups are stored in the hidden, app-specific `appDataFolder` of **your own Google account**. The app cannot see your other Drive files, and the developer has **no access** to your backups.
- **Receipt scanning (OCR)** uses Google ML Kit and runs **entirely on-device**; images and recognized text are never uploaded.
- **Fuel price reference:** the app fetches current fuel prices via an anonymous request (Supabase REST). No personal data is sent.
- **Permissions:** Camera (receipt scanning, vehicle photos), photo picker (selecting images), Notifications (local expiry reminders for insurance/tax/inspection), Boot-completed (rescheduling reminders after restart), Internet (price fetch and optional Drive backup).
- **Data deletion:** uninstall the app (or clear app data) to remove all local data; delete the Drive backup from within the app or via your Google account settings (third-party app access). Since we store nothing, no deletion request to the developer is needed.
- Contact: **[EMAIL]**

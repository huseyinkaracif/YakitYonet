# YakıtYonet - Gelecekte Eklenebilecek Özellikler (Feature Backlog)

Uygulamanın temel MVP (Minimum Viable Product) sürümü tamamlandıktan sonra eklenebilecek, kullanıcı deneyimini ve uygulamanın değerini artıracak vizyoner özellikler aşağıda listelenmiştir.

---

## 1. Akıllı Fiş/Fatura Okuma (OCR Entegrasyonu)
*   **Açıklama:** Kullanıcılar akaryakıt aldıktan sonra istasyondan verilen fişin fotoğrafını çekerler. Uygulama, Google ML Kit veya benzeri bir OCR (Optik Karakter Tanıma) kütüphanesi kullanarak fiş üzerindeki metinleri (Tarih, Alınan Litre, Toplam Tutar, İstasyon Adı vb.) otomatik olarak okur.
*   **Fayda:** Kullanıcıyı manuel veri giriş derdinden kurtarır, "Yakıt Ekle" formunu saniyeler içinde doldurur.

## 2. Akıllı Hatırlatıcılar ve Bildirimler (Push Notifications)
*   **Açıklama:** Belirli periyotlarda veya belirlenmiş kilometre/tarih kısıtlarında kullanıcıya bildirim gönderilmesi.
*   **Örnekler:**
    *   Kasko ve Zorunlu Trafik Sigortası bitiş tarihlerine 15 gün ve 3 gün kala uyarı bildirimi.
    *   Kilometre bazlı periyodik bakım (örn. her 10.000 veya 15.000 KM'de bir) yaklaştığında "Bakım Zamanınız Yaklaştı" bildirimi.
    *   TÜVTÜRK Araç Muayene randevu zamanı hatırlatıcıları.

## 3. Yakınlardaki Akıllı İstasyonlar ve Fiyat Karşılaştırması (Lokasyon Bazlı)
*   **Açıklama:** Platformun (veya 3. parti güncel yakıt fiyat API'lerinin) sunduğu veriler doğrultusunda kullanıcının bulunduğu lokasyona en yakın akaryakıt istasyonlarını haritada gösterme.
*   **Fayda:** "En ucuz yakıt nerede?" veya "Şu an bana en yakın LPG istasyonu nerede?" gibi sorulara yanıt verir. Belirli markalardaki kampanyaları gösterebilir.

## 4. Gerçek Zamanlı Araç Verisi: OBD-II Cihazı Entegrasyonu (Bluetooth)
*   **Açıklama:** Araca takılan ucuz bir OBD-II (On-Board Diagnostics) ELM327 adaptöründen Bluetooth veya Wi-Fi aracılığıyla uygulamanın doğrudan, gerçek zamanlı veri çekmesi.
*   **Fayda:** Anlık yakıt tüketimi, hız, akü voltajı, soğutma suyu sıcaklığı ve motor arıza kodları (Check Engine hataları) uygulamanın bir sekmesinde görünür. Yakıt girişleri tam otomatik/hatasız yapılabilir.

## 5. Web Platformu ve Çoklu Platform Senkronizasyonu (Cloud)
*   **Açıklama:** Sadece Android değil; uygulamanın iOS (App Store) veya Web üzerinden de kullanılabilmesi. Kullanıcılar hesaplarıyla giriş yaparak bulut altyapısı (örn: Firebase Firestore, Supabase) üzerinden verilerine tüm cihazlardan anlık erişebilirler.
*   **Fayda:** Yerel veritabanından (SQLite) çıkıp tamamen cloud tabanlı bir "Filo Yönetimi" sistemine evrilme.

## 6. Sürücü Davranış Analizi ve Puanlama (Telematics)
*   **Açıklama:** Akıllı telefonun dahili sensörlerini (İvmeölçer, Jiroskop, GPS) kullanarak yolculuklar boyunca agresif hızlanma, sert fren yapma veya sert viraj alma gibi ivme değişkenlerini takip etmek.
*   **Fayda:** Her sürüşe bir "Tasarruf veya Güvenlik Puanı" verilir. Sakin kullanan sürücülerin aynı yolda ne kadar yakıt tasarrufu sağladığı oyunlaştırılarak (gamification) gösterilir.

## 7. Elektrikli Araçlar (EV) İçin Şarj İstasyonları Haritası
*   **Açıklama:** Araç tipi "Elektrik" seçildiğinde uygulamanın arayüzünde sadece Şarj İstasyonları (AC/DC hızları ve soket tipleri ile birlikte) gösteren özel bir harita/modül açılır.
*   **Fayda:** Geleceğin trendine uygunluk göstererek EV sahiplerini de uygulamaya çeker.

## 8. Karanlık Mod (Dark Mode) / Kullanıcıya Özel Renk Temaları
*   **Açıklama:** Varsayılan karanlık/aydınlık mod dışında, kullanıcının "Araç Rengine Göre" temanın ana renk paletini değiştirebilmesi (Material You tarzında dinamik renk veya manuel seçim).

## 9. Profesyonel PDF/Excel Raporlama Modülü
*   **Açıklama:** Özellikle uygulamayı kullanan küçük işletmeler, kuryeler, satış temsilcileri veya filo yöneticileri için, "Dışa Aktar" bölümüne "Detaylı Yönetici Raporu (PDF)" eklenmesi.
*   **Fayda:** Tüm araç masrafları tek tıkla şık bir fatura/rapor gibi tasarlanıp Whatsapp veya E-posta yoluyla direkt şirketin muhasebe departmanına iletilebilir.

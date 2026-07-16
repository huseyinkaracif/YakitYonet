# Play Store Listeleme Hazırlığı — Yakıt Yönet

> Sürüm: 1.0.0+1 · applicationId: `com.yakityonet.yakit_yonet` · Platform: Yalnızca Android
> Bu doküman Play Console'daki **Store presence → Main store listing**, **App content** ve **Data safety** bölümlerinin satır satır doldurulması içindir.

---

## 1. Uygulama Adı (Title, ≤30 karakter)

| Aday | Karakter | Durum |
|---|---|---|
| Yakıt Yönet – Araç Masraf Takibi | **32** | ❌ Limit aşımı (30'u geçiyor) |
| **Yakıt Yönet – Araç Masrafları** | 29 | ✅ Önerilen |
| Yakıt Yönet: Araç Masraf Takip | 30 | ✅ Tam sınırda, geçerli |
| Yakıt Yönet – Araç Gideri | 25 | ✅ Alternatif |
| Yakıt Yönet | 11 | ✅ Sade alternatif |

**Öneri:** `Yakıt Yönet – Araç Masrafları` (29 karakter). İlk düşünülen "Yakıt Yönet – Araç Masraf Takibi" 32 karakter olduğu için Play Console kabul etmez.

Not: Tire olarak `–` (en dash) yerine `-` kullanılırsa karakter sayısı değişmez; ikisi de 1 karakterdir. AndroidManifest'teki `android:label` "Yakıt Yönet" olarak kalabilir — cihazdaki ad ile mağaza adı birebir aynı olmak zorunda değildir.

---

## 2. Kısa Açıklama (Short description, ≤80 karakter)

| # | Metin | Karakter |
|---|---|---|
| 1 (önerilen) | `Yakıt tüketimi, araç masrafı, bakım ve MTV takibi. Reklamsız, tamamen ücretsiz.` | 79 |
| 2 | `Yakıt, bakım, sigorta ve MTV masraflarını takip edin; tüketiminizi hesaplayın.` | 78 |
| 3 | `Aracınızın tüm masrafları tek uygulamada. Yakıt, bakım, MTV, sigorta. Reklamsız.` | 80 |

ASO notu: Kısa açıklamada "yakıt tüketimi", "araç masrafı", "MTV" anahtar kelimeleri geçiyor; 1 numaralı aday hem anahtar kelime hem "reklamsız/ücretsiz" güven mesajını taşır.

---

## 3. Tam Açıklama (Full description, ≤4000 karakter)

Aşağıdaki metin ~2.600 karakterdir (4000 limitinin altında). ASO anahtar kelimeleri doğal biçimde yerleştirilmiştir: **yakıt takibi, araç masraf, benzin hesaplama, MTV, yakıt tüketimi**.

```
Yakıt Yönet, aracınızın tüm masraflarını tek yerden yönetmeniz için tasarlanmış, tamamen ücretsiz ve reklamsız bir yakıt takibi ve araç masraf uygulamasıdır. Yakıt tüketimi hesaplama, bakım kayıtları, MTV ve sigorta hatırlatmaları — hepsi cihazınızda, internetsiz çalışır.

⛽ YAKIT TAKİBİ VE TÜKETİM HESAPLAMA
• Her yakıt alımını litre, tutar ve kilometre ile kaydedin
• Tam depo kayıtlarından otomatik yakıt tüketimi hesaplama (L/100km) ve km başına maliyet (TL/km)
• Benzin, motorin ve LPG fiyat gelişimini grafiklerle izleyin
• Güncel akaryakıt fiyatlarını referans olarak görüntüleyin

📷 FİŞ TARAMA (OCR)
• Pompa fişini kameranızla tarayın; litre, tutar ve litre fiyatı otomatik okunsun
• Tamamen cihaz üzerinde çalışır, fiş görüntüsü hiçbir sunucuya gönderilmez

🚗 ÇOKLU ARAÇ DESTEĞİ
• Birden fazla aracı fotoğraflarıyla birlikte yönetin
• Araç bazında masraf, tüketim ve istatistik takibi

🔧 BAKIM KAYITLARI
• Yağ değişimi, lastik, servis ve tüm bakım masraflarını kilometre bilgisiyle kaydedin

📋 MTV, SİGORTA VE MUAYENE TAKİBİ
• MTV, trafik sigortası, kasko ve araç muayenesi için son tarih takibi
• Süresi yaklaşan ödemeler için bildirim hatırlatmaları
• Yaklaşan ödemeler paneli ile hiçbir tarihi kaçırmayın

📊 İSTATİSTİK VE RAPORLAR
• Aylık ve yıllık araç masraf özetleri, grafikler
• PDF ve Excel rapor oluşturma (tamamen çevrimdışı)
• JSON dışa/içe aktarma ile verileriniz her zaman sizin kontrolünüzde

☁️ GOOGLE DRIVE YEDEKLEME (İSTEĞE BAĞLI)
• Verilerinizi kendi Google Drive hesabınızın özel uygulama alanına yedekleyin
• Haftalık veya aylık otomatik yedekleme
• Yedeğe yalnızca siz erişebilirsiniz

📱 ANA EKRAN WIDGET'LARI
• 4x2 ve 4x1 widget'larla son yakıt tüketimi ve masraf özetini ana ekranda görün

🌙 DİĞER ÖZELLİKLER
• Koyu ve açık tema
• Türkçe arayüz, virgüllü ondalık giriş desteği
• İnternet bağlantısı gerektirmeden çalışır (çevrimdışı öncelikli)

🔒 GİZLİLİK ÖNCE GELİR
• Reklam yok, analitik yok, üçüncü taraf takip yok
• Tüm verileriniz cihazınızda saklanır
• İnternet yalnızca isteğe bağlı Drive yedeklemesi ve anonim yakıt fiyatı sorgusu için kullanılır
• Hesap zorunluluğu yok; uygulama giriş yapmadan tam çalışır

Yakıt Yönet ile benzin hesaplama, yakıt tüketimi takibi ve araç masraf yönetimi artık çok kolay. Aracınıza ne kadar harcadığınızı bugün öğrenin!
```

Kontrol listesi:
- [x] ≤4000 karakter
- [x] Emoji'li özellik listesi
- [x] Anahtar kelimeler: yakıt takibi ✓, araç masraf ✓, benzin hesaplama ✓, MTV ✓, yakıt tüketimi ✓
- [x] Anahtar kelime yığma (keyword stuffing) yok — Google politikası gereği tekrar sınırlı tutuldu

---

## 4. Kategori ve Etiketler

- **Uygulama türü:** Uygulama (App)
- **Kategori:** **Araçlar (Auto & Vehicles)**
  - Alternatif: Finans (masraf takibi vurgusu) — önerilmez; hedef kitle araç sahipleri, keşfedilebilirlik Auto & Vehicles'ta daha iyi.
- **Etiketler (Tags, en fazla 5):** Play Console'un sunduğu listeden seçilir; şu adayları arayın:
  1. Otomobil / Cars
  2. Ulaşım / Transportation
  3. Kişisel finans / Personal finance (varsa)
  4. Verimlilik / Productivity
  5. Araçlar (yardımcı) / Tools

---

## 5. İçerik Derecelendirme Anketi (IARC) — Cevap Rehberi

Hedef sonuç: **Herkes (Everyone) / PEGI 3**.

Play Console → App content → Content ratings → Anketi başlat:

| Soru | Cevap | Not |
|---|---|---|
| E-posta adresi | Geliştirici e-postanız | akriel1998@gmail.com veya kurumsal adres |
| Uygulama kategorisi | "Yardımcı Program, Verimlilik, İletişim veya Diğer" (Utility) | Oyun değil |
| Şiddet içeriyor mu? | **Hayır** | |
| Cinsellik / müstehcenlik? | **Hayır** | |
| Küfür / kaba dil? | **Hayır** | |
| Uyuşturucu, alkol, tütün referansı? | **Hayır** | |
| Kumar / şans oyunları (simüle dahil)? | **Hayır** | |
| Korku / dehşet öğeleri? | **Hayır** | |
| Kullanıcılar birbiriyle etkileşebilir mi (sohbet, içerik paylaşımı)? | **Hayır** | Uygulamada kullanıcılar arası hiçbir etkileşim yok |
| Kullanıcının konumunu diğer kullanıcılarla paylaşır mı? | **Hayır** | |
| Kişisel bilgileri üçüncü taraflarla paylaşır mı? | **Hayır** | Veri cihazda kalır |
| Uygulama içi dijital ürün satın alma? | **Hayır** | Ücretsiz, IAP yok |
| Web tarayıcı veya arama motoru içeriyor mu? | **Hayır** | url_launcher harici tarayıcı açar; uygulama içi tarayıcı sayılmaz |
| Kumar teşviki / gerçek para ödülü? | **Hayır** | |

Beklenen sonuç: IARC tüm bölgeler için en düşük derecelendirme — **PEGI 3 / ESRB Everyone / USK 0 / Herkes**.

---

## 6. Data Safety (Veri Güvenliği) Formu — Satır Satır

Ön bilgi (formun mantığı): Google'ın tanımına göre "toplama (collect)" = verinin cihaz dışına, **geliştiriciye veya üçüncü tarafa** aktarılması. Yakıt Yönet'te:

- Tüm kayıtlar (araç, yakıt, bakım, sigorta) **yalnızca cihazdaki SQLite veritabanında** durur. Geliştiricinin sunucusu yoktur.
- **Google Sign-In:** Kimlik doğrulamayı Google Play Hizmetleri yürütür; uygulama yalnızca kullanıcının e-postasını **cihaz üzerinde göstermek** için okur, hiçbir sunucuya iletmez.
- **Drive yedeklemesi:** Kullanıcının **kendi başlattığı**, kendi Google hesabının `appDataFolder` alanına aktarımdır. Google politikasındaki "kullanıcının başlattığı, verinin gideceği tarafı açıkça beklediği aktarım" muafiyeti kapsamındadır (veri geliştiriciye gitmez).
- **Yakıt fiyatı sorgusu:** Supabase REST'e **anonim** GET isteği; istekte hiçbir kişisel veri, kimlik veya tanımlayıcı gönderilmez.
- Reklam SDK'sı, analitik, crash raporlama, üçüncü taraf takip **yok**.

### Form cevapları

| Form sorusu | Cevap |
|---|---|
| **Does your app collect or share any of the required user data types?** (Uygulamanız zorunlu kullanıcı verisi türlerinden herhangi birini topluyor veya paylaşıyor mu?) | **Hayır (No)** |
| *(Hayır seçilince kalan sorular kapanır; aşağıdakiler yalnızca form akışı "Evet" yorumlanırsa gerekir)* | |
| Is all of the user data collected by your app encrypted in transit? | (Sorulmaz — toplama yok. Bilgi: tüm ağ trafiği HTTPS'tir) |
| Do you provide a way for users to request that their data is deleted? | (Sorulmaz. Bilgi: kullanıcı Drive yedeğini ve yerel veriyi kendisi silebilir) |

### Store listing'de görünecek özet
"Veri toplanmıyor" + "Üçüncü taraflarla veri paylaşılmıyor" rozetleri.

### Gerekçe dosyası (olası Google incelemesine hazır cevap)
1. Uygulamanın hiçbir backend'i yok; geliştirici hiçbir kullanıcı verisine erişemez.
2. Google Sign-In yalnızca Drive `appDataFolder` OAuth kapsamı için; e-posta cihazda görüntülenir, iletilmez.
3. Yedek dosyası kullanıcının kendi Drive hesabına, kullanıcının açık eylemiyle yüklenir (user-initiated transfer muafiyeti).
4. Yakıt fiyatı isteği anonimdir; gövdede/başlıkta kişisel veri yoktur (IP adresi yalnızca bağlantı kurulumunda geçici işlenir — "ephemeral processing" muafiyeti).
5. AndroidManifest'te yalnızca INTERNET, CAMERA (isteğe bağlı, OCR için), POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, VIBRATE izinleri vardır; konum, kişiler, depolama okuma izni yoktur.

> Not: Gizlilik politikası URL'si zorunludur (bkz. bölüm 9). Politika metni yukarıdaki 5 maddeyi kapsamalıdır.

---

## 7. Grafik Varlık Gereksinimleri

| Varlık | Boyut / Format | Zorunlu | Not |
|---|---|---|---|
| Uygulama ikonu | **512 x 512 px**, 32-bit PNG (alfa kanallı), ≤1 MB | ✅ | Mevcut `assets/images/app_icon.png` kaynağından üretilebilir; Play, ikonu kendi maskesiyle yuvarlar — kenarlara taşan önemli öğe koymayın |
| Feature graphic (öne çıkan görsel) | **1024 x 500 px**, PNG veya JPEG, alfa yok, ≤15 MB | ✅ | Uygulama adı + 1 slogan + ekran görüntüsü kolajı önerilir; koyu tema arkaplanı (#1C1917) marka tutarlılığı sağlar |
| Telefon ekran görüntüleri | **En az 2, en fazla 8**; PNG/JPEG, her biri ≤8 MB; en-boy 16:9 veya 9:16; kısa kenar ≥320 px, uzun kenar ≤3840 px | ✅ | Önerilen: **1080 x 1920** (9:16). Çekilecek ekranlar: 1) Ana ekran/araç listesi, 2) Yakıt kayıtları + tüketim grafiği, 3) OCR fiş tarama, 4) Yaklaşan ödemeler/MTV, 5) İstatistikler, 6) Koyu tema örneği |
| 7" tablet ekran görüntüleri | 16:9 / 9:16, ≤8 ekran | ⬜ İsteğe bağlı | Telefon uygulaması için zorunlu değil |
| 10" tablet ekran görüntüleri | 16:9 / 9:16, ≤8 ekran | ⬜ İsteğe bağlı | |
| Tanıtım videosu (YouTube URL) | — | ⬜ İsteğe bağlı | |

Ekran görüntüsü alma: `flutter run --release` + cihazda `adb exec-out screencap -p > screen1.png` (1080p cihazda doğrudan 1080x2400 gelir; 9:16'ya kırpılabilir — Play 9:16'dan uzun oranları da çoğunlukla kabul eder ama 16:9/9:16 güvenli sınırdır).

---

## 8. Hedef Kitle (Target audience and content)

- **Hedef yaş grubu:** **18 ve üzeri** (önerilen). İstenirse 16-17 eklenebilir.
  - **13 yaş altı hiçbir grup seçilmemeli** — aksi halde Google Families politikası devreye girer (ek gereksinimler, tasarım incelemesi).
- "Uygulamanız istemeden çocukların ilgisini çekebilir mi?" → **Hayır** (araç masraf/finans yardımcı uygulaması, çocuklara yönelik görsel öğe yok).

---

## 9. App Content Bölümleri — Tam Liste

Play Console → App content altındaki her beyan:

| Bölüm | Cevap |
|---|---|
| **Privacy policy** | Zorunlu — URL girin (ör. GitHub Pages'te barındırılan `privacy-policy.html`). Politika: veri cihazda kalır, Drive yedeği kullanıcı hesabında, anonim fiyat isteği, izinlerin amacı |
| **Ads (Reklamlar)** | **Hayır — uygulama reklam içermiyor** |
| **App access (Uygulama erişimi)** | **"All functionality is available without special access"** — Google girişi isteğe bağlıdır, inceleme ekibi girişsiz tüm özellikleri kullanabilir (Drive yedekleme hariç; bu da beyanı değiştirmez çünkü giriş herkese açık standart Google OAuth'tur) |
| **Content ratings** | Bölüm 5'teki anket → Herkes / PEGI 3 |
| **Target audience** | 18+ (bölüm 8) |
| **News app** | **Hayır** |
| **COVID-19 contact tracing / status app** | **Hayır** |
| **Data safety** | Bölüm 6 |
| **Government app** | **Hayır** |
| **Financial features** | **"Uygulamam finansal özellik sağlamıyor / My app doesn't provide any financial features"** — masraf takibi kişisel kayıt tutmadır; kredi, ödeme, yatırım işlevi yok |
| **Health apps** | **Hayır / sağlık özelliği yok** |
| **Advertising ID** | **Hayır — uygulama reklam kimliği kullanmıyor** (AD_ID izni manifest'te yok; Play Console bunu sorar, "No" işaretleyin. `com.google.android.gms.permission.AD_ID` bir kütüphane tarafından merge edilirse `flutter build appbundle` sonrası merged manifest kontrol edin) |

---

## 10. Yayın Öncesi Hızlı Kontrol Listesi

- [ ] Uygulama adı ≤30 karakter seçildi (bölüm 1)
- [ ] Kısa açıklama ≤80, tam açıklama ≤4000
- [ ] 512x512 ikon + 1024x500 feature graphic + ≥2 telefon ekran görüntüsü yüklendi
- [ ] Gizlilik politikası URL'si canlı
- [ ] Data safety: "Veri toplanmıyor" beyan edildi
- [ ] İçerik derecelendirme anketi tamamlandı (Herkes/PEGI 3)
- [ ] Ads: No · Target audience: 18+ · Financial features: none
- [ ] Merged manifest'te AD_ID izni olmadığı doğrulandı
- [ ] Release AAB `com.yakityonet.yakit_yonet` imzalı ve internal test track'te denendi
- [ ] Google Cloud Console'da OAuth consent screen "In production" durumda (Drive yedekleme release imza SHA-1'i ile test edildi)

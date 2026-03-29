# ML Kit — sadece Latin script kullandığımız için diğer dil modülleri
# APK'ya dahil edilmiyor; R8'in eksik sınıf hatasını bastır.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Latin script tanıyıcıyı koru
-keep class com.google.mlkit.vision.text.latin.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Optik Okuyucu App - Flutter

Bu proje, mevcut web uygulamasının Flutter SDK kullanılarak Android ve iOS platformları için geliştirilmiş sürümüdür.

## Özellikler
- **Cross-Platform:** Tek kod tabanı ile hem Android hem iOS desteği.
- **Premium UI:** Modern ve şık kullanıcı arayüzü.
- **Local Storage:** Veriler cihazın yerel hafızasında (SharedPreferences) saklanır.
- **Analiz:** Radar grafikli öğrenci karnesi.
- **OMR Arayüzü:** Kamera tabanlı tarama ekranı.

## Kurulum
1. Flutter SDK'nın yüklü olduğundan emin olun.
2. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
3. Uygulamayı başlatın:
   ```bash
   flutter run
   ```

## Klasör Yapısı
- `lib/core`: Tema ve renk tanımlamaları.
- `lib/models`: Veri modelleri (Exam, Subject).
- `lib/providers`: State management (ExamProvider).
- `lib/screens`: Uygulama sayfaları.

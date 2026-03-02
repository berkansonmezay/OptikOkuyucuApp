# OMR Backend Kurulum Rehberi

Bu backend, OpenCV ve FastAPI kullanarak yüksek hassasiyetli optik okuma yapar.

## Gereksinimler
- Python 3.8 veya üzeri
- Bilgisayarınızda `pip` yüklü olmalı

## Kurulum
1. `backend` klasörüne gidin:
   ```bash
   cd backend
   ```
2. Gerekli kütüphaneleri yükleyin:
   ```bash
   pip install -r requirements.txt
   ```

## Çalıştırma
Aşağıdaki komutla sunucuyu başlatın:
```bash
python main.py
```
Sunucu varsayılan olarak `http://localhost:8000` adresinde çalışacaktır.

## Çözüm: "Failed to fetch" Hatası

Eğer mobil uygulamada (gerçek cihazda) "Failed to fetch" hatası alıyorsanız:
1.  **Aynı Ağda Olun**: Telefonunuz ve bilgisayarınız aynı Wi-Fi ağına bağlı olmalıdır.
2.  **IP Adresini Bulun**: Bilgisayarınızın yerel IP adresini bulun (Windows için `ipconfig`, Mac/Linux için `ifconfig`). Örn: `192.168.1.50`.
3.  **Uygulamayı Güncelleyin**: 
    - `flutter_app/lib/screens/scanner_screen.dart` içinde `10.0.2.2` olan yeri kendi IP'nizle değiştirin: `http://192.168.1.50:8000/process-omr`.
    - `camera.html` içinde de `localhost` yerine IP'nizi yazın.
4.  **Güvenlik Duvarı**: Bilgisayarınızın güvenlik duvarının (Firewall) 8000 portuna izin verdiğinden emin olun.

## Notlar
- Flutter uygulamasını Android Simülatöründe test ediyorsanız, localhost adresi otomatik olarak `10.0.2.2` olarak ayarlanmıştır.
- Web üzerinden test ediyorsanız, tarayıcınızın CORS politikası gereği backend'in aynı domainde veya uygun CORS ayarlarıyla çalışması gerekebilir. (Şu anki kurulumda en hızlı test için web arayüzü doğrudan localhost:8000'e erişir).

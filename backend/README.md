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

## Notlar
- Flutter uygulamasını Android Simülatöründe test ediyorsanız, localhost adresi otomatik olarak `10.0.2.2` olarak ayarlanmıştır.
- Web üzerinden test ediyorsanız, tarayıcınızın CORS politikası gereği backend'in aynı domainde veya uygun CORS ayarlarıyla çalışması gerekebilir. (Şu anki kurulumda en hızlı test için web arayüzü doğrudan localhost:8000'e erişir).

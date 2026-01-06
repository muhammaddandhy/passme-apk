# Setup dan Testing di Android

## ✅ Aplikasi Sudah Siap Dijalankan di Android!

Aplikasi sudah dikonfigurasi dengan baik dan siap untuk dijalankan di Android. Berikut adalah langkah-langkah untuk menjalankannya:

## Cara Menjalankan di Android

### 1. Pastikan Flutter SDK Terinstall
```bash
flutter doctor
```

### 2. Connect Android Device atau Emulator
- Pastikan device/emulator sudah terhubung
- Cek dengan: `flutter devices`

### 3. Build dan Run
```bash
cd karimove
flutter run
```

Atau build APK untuk instalasi manual:
```bash
flutter build apk
```

## Fitur yang Sudah Bekerja

✅ **Autentikasi User**
- Register akun baru
- Login dengan email/password
- Data user tersimpan di database

✅ **Password Manager**
- Tambah password baru
- Edit password
- Hapus password
- Data tersimpan permanen (tidak hilang saat keluar app)

✅ **Icon Auto-Detection**
- Icon otomatis terdeteksi dari nama akun
- Support Gmail, Facebook, Instagram, dll

✅ **Premium Feature**
- UI premium sudah tersedia
- Billing service sudah terintegrasi (perlu setup di Play Console untuk production)

## Catatan Penting

### Untuk Development/Testing:
- ✅ Aplikasi **BISA** dijalankan tanpa setup billing
- ✅ Billing service tidak akan crash jika belum di-setup
- ✅ Semua fitur utama (login, password manager) sudah bekerja
- ✅ Fitur premium akan menampilkan error yang jelas jika billing belum di-setup

### Untuk Production:
- ⚠️ Setup billing di Play Console (lihat `BILLING_SETUP.md`)
- ⚠️ Update Product ID di `lib/services/billing_service.dart`
- ⚠️ Upload aplikasi ke Play Console untuk testing billing

## Troubleshooting

### Error: "In-app purchase tidak tersedia"
- **Normal untuk development** - Billing hanya bekerja pada aplikasi dari Play Store
- Fitur lain tetap berfungsi normal
- Untuk testing billing, upload ke Play Console dulu

### Error: Database tidak tersimpan
- Pastikan permission storage sudah diberikan
- Cek log untuk error database
- Database otomatis dibuat di: `/data/data/com.example.karimove/databases/`

### Error saat build
```bash
flutter clean
flutter pub get
flutter run
```

## Testing Checklist

- [ ] Register akun baru
- [ ] Login dengan akun yang sudah dibuat
- [ ] Tambah password baru
- [ ] Edit password
- [ ] Hapus password
- [ ] Logout dan login lagi (data harus tetap ada)
- [ ] Icon otomatis terdeteksi
- [ ] Premium screen bisa dibuka (meskipun billing belum di-setup)

## Build APK untuk Testing

```bash
# Debug APK
flutter build apk --debug

# Release APK (untuk testing di device)
flutter build apk --release
```

APK akan berada di: `build/app/outputs/flutter-apk/app-release.apk`


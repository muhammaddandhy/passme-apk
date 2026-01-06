# Changelog - Fitur Baru

## Perubahan yang Telah Diimplementasikan

### 1. ✅ Sistem Autentikasi Pengguna
- **Model User**: Dibuat `UserModel` untuk menyimpan data pengguna
- **Database Users**: Tabel `users` ditambahkan ke database untuk menyimpan email dan password (ter-hash)
- **Auth Service**: Service baru untuk handle registrasi dan login
- **Login Screen**: Sekarang menggunakan autentikasi dari database, bukan hardcoded password
- **Register Screen**: Sekarang menyimpan user baru ke database
- **Logout**: Fitur logout yang menghapus session user

### 2. ✅ Persistensi Data Password
- **Database Migration**: Database version di-upgrade ke v2 dengan migration handler
- **Data Persistence**: Password sekarang tersimpan secara permanen di SQLite database
- **Auto-migration**: Database otomatis melakukan migration saat update aplikasi

### 3. ✅ Icon untuk Berbagai Jenis Akun
- **Icon Helper**: Utility baru untuk mendeteksi jenis akun dari title/username
- **Icon Types**: Support untuk:
  - Gmail, Facebook, Instagram, Twitter/X
  - WhatsApp, LinkedIn, YouTube, TikTok
  - Telegram, Discord, GitHub
  - Amazon, Netflix, Spotify, PayPal
  - Default icon untuk akun lainnya
- **Auto-detection**: Icon otomatis terdeteksi saat menambah/edit password
- **Color-coded Icons**: Setiap jenis akun memiliki warna icon yang sesuai

### 4. ✅ Integrasi Google Play Billing
- **Billing Service**: Service baru untuk handle in-app purchases
- **Premium Service**: Di-update untuk menggunakan billing real dari Play Store
- **Premium Screen**: UI di-update dengan info produk dan tombol restore purchases
- **Purchase Flow**: Flow pembelian premium terintegrasi dengan Play Store

## File yang Ditambahkan

1. `lib/models/user_model.dart` - Model untuk user data
2. `lib/services/auth_service.dart` - Service untuk autentikasi
3. `lib/services/billing_service.dart` - Service untuk Play Store billing
4. `lib/utils/icon_helper.dart` - Helper untuk icon detection
5. `BILLING_SETUP.md` - Panduan setup billing
6. `CHANGELOG.md` - File ini

## File yang Diupdate

1. `lib/models/password_model.dart` - Ditambahkan field `iconType`
2. `lib/services/database_helper.dart` - Ditambahkan tabel users dan migration
3. `lib/services/premium_service.dart` - Integrasi dengan billing service
4. `lib/screens/login_screen.dart` - Autentikasi dari database
5. `lib/screens/register_screen.dart` - Simpan user ke database
6. `lib/screens/home_screen.dart` - Tampilkan icon dan logout
7. `lib/screens/add_password_screen.dart` - Auto-detect icon type
8. `lib/screens/edit_password_screen.dart` - Auto-detect icon type
9. `lib/screens/premium_screen.dart` - Integrasi billing
10. `lib/main.dart` - Initialize premium service
11. `pubspec.yaml` - Tambah dependencies untuk billing

## Dependencies Baru

- `in_app_purchase: ^3.1.11` - Untuk Play Store billing
- `in_app_purchase_android: ^0.2.0` - Android-specific billing
- `in_app_purchase_storekit: ^0.3.7` - iOS-specific billing

## Cara Menggunakan

### 1. Setup Billing (Wajib untuk Premium)
Lihat file `BILLING_SETUP.md` untuk panduan lengkap setup Google Play Billing.

### 2. Testing
1. **Registrasi**: Buat akun baru melalui halaman register
2. **Login**: Login dengan email dan password yang sudah didaftarkan
3. **Tambah Password**: Password akan otomatis terdeteksi icon-nya
4. **Premium**: Untuk testing premium, setup billing terlebih dahulu

### 3. Database
- Database otomatis dibuat saat pertama kali app dijalankan
- Data tersimpan secara permanen di device
- Migration otomatis saat update aplikasi

## Catatan Penting

1. **Billing**: In-app purchase hanya bekerja pada aplikasi yang di-install dari Play Store (bukan debug build)
2. **Product ID**: Ganti `premium_monthly` di `billing_service.dart` dengan Product ID yang dibuat di Play Console
3. **Testing**: Gunakan akun tester untuk testing billing
4. **Data Persistence**: Data sekarang tersimpan secara permanen, tidak akan hilang saat keluar aplikasi

## Troubleshooting

### Data Password Hilang
- Pastikan database sudah di-initialize dengan benar
- Check apakah ada error di console saat save password
- Pastikan permission storage sudah diberikan (untuk Android)

### Billing Tidak Bekerja
- Pastikan aplikasi sudah di-upload ke Play Console
- Pastikan Product ID sudah dibuat di Play Console
- Pastikan menggunakan akun tester
- Pastikan aplikasi di-install dari Play Store

### Icon Tidak Muncul
- Icon akan otomatis terdeteksi dari title/username
- Jika tidak terdeteksi, akan menggunakan default icon
- Edit password untuk update icon type


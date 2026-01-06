# Setup Google Play Billing

## Langkah-langkah Setup:

1. **Buka Google Play Console**
   - Masuk ke https://play.google.com/console
   - Pilih aplikasi Anda

2. **Buat Produk In-App Purchase**
   - Buka menu "Monetize" > "Products" > "Subscriptions" atau "In-app products"
   - Klik "Create subscription" atau "Create product"
   - Isi detail produk:
     - Product ID: `premium_monthly` (atau sesuai kebutuhan)
     - Name: Premium Monthly
     - Description: Akses premium tanpa batas
     - Price: Sesuaikan dengan kebutuhan

3. **Update Product ID di Kode**
   - Buka file `lib/services/billing_service.dart`
   - Ganti `_premiumProductId = 'premium_monthly'` dengan Product ID yang Anda buat di Play Console

4. **Testing**
   - Untuk testing, gunakan akun tester yang ditambahkan di Play Console
   - Pastikan aplikasi sudah di-upload ke Internal Testing atau Alpha/Beta track
   - Install aplikasi dari Play Store (bukan dari build langsung)

5. **Catatan Penting**
   - In-app purchase hanya bekerja pada aplikasi yang di-install dari Play Store
   - Untuk development, gunakan test account
   - Pastikan aplikasi sudah di-sign dengan release key

## Troubleshooting

- Jika purchase tidak muncul, pastikan:
  - Product ID sudah dibuat di Play Console
  - Aplikasi sudah di-upload ke Play Console
  - Menggunakan akun tester yang terdaftar
  - Aplikasi di-install dari Play Store (bukan debug build)


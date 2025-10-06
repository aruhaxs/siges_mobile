# SIGES Mobile — Panduan Setup & Pengujian

Ini adalah panduan ringkas dan praktis untuk developer / QA agar dapat men-setup, menjalankan, dan menguji aplikasi mobile SIGES (Flutter) secara cepat.

Catatan singkat tentang arsitektur:

- Frontend: Flutter (Dart), entrypoint: `lib/main.dart`
- Backend: Firebase Realtime Database (path utama: `buildings`) dan Firebase Authentication untuk login/signup
- Integrasi: Google Drive dipakai untuk menyimpan foto (service: `lib/src/google_drive_service.dart`)
- Peta: `flutter_map` (OpenStreetMap)

---

## Clone & Multi-environment Setup

Berikut panduan langkah demi langkah untuk meng-clone repository ini dan menyiapkan lingkungan kerja pada beberapa OS umum.

1. Clone repository

- Windows (PowerShell):

```powershell
# Clone repo
git clone https://github.com/aruhaxs/siges_mobile.git
cd siges_mobile
```

- macOS / Linux (bash):

```bash
# Clone repo
git clone https://github.com/aruhaxs/siges_mobile.git
cd siges_mobile
```

2. Install dependencies

```powershell
flutter pub get
```

3. Platform-specific setup

- Android

  - Pastikan Android SDK & platform-tools terinstal.
  - Jika build ke perangkat Android, hubungkan device atau jalankan AVD (Android Virtual Device).
  - Pastikan `android/app/google-services.json` ada jika ingin build release atau test push notifications.

- iOS (macOS saja)
  - Pastikan Xcode terinstal dan lisensi sudah diaccept.
  - Pastikan `ios/Runner/GoogleService-Info.plist` ada untuk integrasi Firebase pada iOS.
  - Jalankan `flutter build ios` atau buka `ios/Runner.xcworkspace` di Xcode untuk debug.

4. Firebase setup

- Jika repo sudah berisi `lib/firebase_options.dart`, aplikasi biasanya sudah terkonfigurasi untuk build dasar.
- Jika tidak atau ingin mengaitkan ke project Firebase yang berbeda, jalankan:

```powershell
# Install/aktifkan FlutterFire CLI jika perlu
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

- Pilih project Firebase yang sesuai saat prompt.

## Prasyarat

- Flutter SDK (disarankan versi yang kompatibel dengan SDK >= 3.9)

- image_picker

- flutter_map, latlong2

flutter pub get

````

---


## Konfigurasi Firebase



Jika repository sudah menyertakan `lib/firebase_options.dart`, Anda bisa langsung menjalankan aplikasi. Jika tidak, gunakan FlutterFire CLI:

```powershell
# (jika belum terpasang)
dart pub global activate flutterfire_cli
firebase login

flutterfire configure

````

## Konfigurasi Google Drive (upload/download gambar)

- Di Google Cloud Console untuk project Google API, aktifkan Drive API.

- Untuk testing cepat pada perangkat, aplikasi menggunakan `google_sign_in` (OAuth consent popup). Pastikan akun Google tersedia pada emulator/perangkat.

---

## Menjalankan Aplikasi (Debug)

```powershell


flutter analyze



# Jalankan aplikasi di emulator atau perangkat

flutter run
```

Build release

- Android

```powershell
flutter build apk --release
```

- iOS (macOS)

```bash
flutter build ios --release
```

---

## Skenario Pengujian (Checklist)

Gunakan langkah di bawah untuk verifikasi fitur utama. Sertakan langkah, ekspektasi hasil, dan cara verifikasi data di Firebase/Google Drive.

1. Autentikasi — Sign Up / Login

   - Langkah: Buka aplikasi, lakukan registrasi (signup) atau login.
   - Ekspektasi: Setelah berhasil, masuk ke `MainScreen`.
   - Verifikasi: Firebase Authentication console → user terdaftar.

2. Dashboard & Statistik

   - Langkah: Lihat halaman dashboard (biasanya terletak di menu utama).

   - Ekspektasi: Pie chart menampilkan distribusi kategori bangunan.

3. Peta (Map)

   - Langkah: Buka halaman peta.

   - Ekspektasi: Semua marker bangunan muncul; menekan marker menampilkan info/preview.

   - Tambah Data

     - Langkah: FAB → isi form (nama, kategori, alamat, koordinat: `lat, lng`), upload gambar via gallery
     - Ekspektasi: Data muncul di list dan peta; jika upload gambar: file dibuat di Google Drive di folder `SIGES/buildings` dan `driveImageId` tersimpan di record RTDB.
     - Verifikasi: Firebase Realtime Database → cek `buildings/<generated_key>`; Google Drive → cek folder `SIGES/buildings`.

     - Langkah: Tekan tombol delete pada item → konfirmasi

     - Ekspektasi: Record terhapus dari RTDB; jika ada `driveImageId`, file Drive juga dihapus.

4. Detail Bangunan

   - Langkah: Buka detail dari list

   - Ekspektasi: Menampilkan informasi lengkap dan peta embed dengan marker di posisi yang benar.

5. Pencarian, Filter, Sort

   - Langkah: Coba pencarian nama, filter kategori, dan tombol sortir

   - Langkah: Submit form dengan data yang salah (mis. koordinat kosong atau salah format)

6. Offline / Koneksi Jelek

   - Ekspektasi: Aplikasi menangani error jaringan (beberapa fitur yang memerlukan network akan gagal). Periksa pesan kesalahan atau behavior UI.

---

## Test Case Detail (Contoh)

- Test: Upload gambar saat tambah bangunan
  1. Tekan Add → tap area gambar → pilih foto dari gallery
  2. Jika belum login ke Google untuk Drive, `google_sign_in` akan meminta akun
  3. Setelah simpan, periksa `driveImageId` di RTDB
  4. Buka Google Drive akun yang dipakai → pastikan file ada di `SIGES/buildings`

---

## Debugging & Troubleshooting

- Jika upload gambar gagal: periksa konsol log (adb logcat / flutter run) untuk pesan dari `GoogleDriveService`
- Pastikan Drive API diaktifkan dan akun Google yang dipakai memiliki akses
- Jika ada error terkait Firebase auth/database: cek `lib/firebase_options.dart` apakah sesuai dengan project yang dimaksud
- Analyzer warnings yang mungkin muncul (non-blocking): penggunaan `print` di beberapa service, beberapa API Flutter deprecated notices — bukan blocking.

Contoh perintah cepat untuk diagnosis:

```powershell
# Jalankan analyzer
flutter analyze

# Jalankan aplikasi dengan logs verbose
flutter run -v

# Jalankan logcat (Android) untuk melihat stack traces
adb logcat -s flutter
```

---

## Known Issues / Catatan Pengembang

- `GoogleDriveService` menggunakan `google_sign_in` dan membuat client OAuth yang berbasis header akun; pada beberapa konfigurasi emulator, popup OAuth mungkin tidak muncul. Gunakan perangkat fisik jika perlu.
- Pada awalnya, ada missing method `downloadFile` — sudah ditambahkan di `lib/src/google_drive_service.dart`.
- Beberapa widget menggunakan properti yang memberi peringatan deprecation (mis. `value` di beberapa form field) — bukan blocking.

---

## Informasi Kontak / Referensi

- Repo: https://github.com/aruhaxs/siges_mobile
- Untuk masalah akses Firebase/Drive, hubungi pemilik proyek atau admin GCP/Firebase yang mengelola kredensial.

Terakhir: jika tim ingin, saya bisa menambahkan skrip pengujian otomatis (widget tests) untuk alur login dan CRUD dasar. Sampaikan prioritas tes yang dibutuhkan.

---

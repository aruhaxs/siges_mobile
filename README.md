🗺️ SIGES Mobile: Sistem Informasi Geografis Kelurahan Sukorame
Aplikasi mobile berbasis Flutter untuk Sistem Informasi Geografis (SIG) Kelurahan Sukorame, Kota Kediri. Aplikasi ini berfungsi untuk mendata, memetakan, dan memvisualisasikan informasi bangunan di wilayah tersebut, dilengkapi dengan sistem autentikasi pengguna.

✨ Fitur Utama
Dashboard Interaktif: Menampilkan ringkasan data bangunan dalam bentuk Pie Chart untuk analisis cepat berdasarkan kategori.

Peta Sebaran: Visualisasi lokasi semua bangunan yang terdata dalam peta interaktif menggunakan OpenStreetMap.

Manajemen Data (CRUD): Fitur lengkap untuk menambah, melihat daftar, mengedit, dan menghapus data bangunan.

Pencarian & Filter: Memudahkan pencarian data bangunan berdasarkan nama pada halaman daftar dan peta.

Sortir Data: Mengurutkan daftar bangunan berdasarkan nama (A-Z, Z-A) dan memfilter berdasarkan kategori.

Detail Bangunan: Halaman detail untuk setiap bangunan, menampilkan semua informasi dan peta lokasi individual.

Autentikasi Pengguna: Sistem login dan registrasi menggunakan Firebase Authentication untuk mengamankan akses data.

🛠️ Teknologi yang Digunakan
Framework: Flutter

Bahasa: Dart

Database: Firebase Realtime Database

Autentikasi: Firebase Authentication

Peta: flutter_map (OpenStreetMap)

Chart: fl_chart

Manajemen State: StatefulWidget (setState)

⚙️ Panduan Setup & Instalasi
Ikuti langkah-langkah ini untuk menjalankan proyek di komputer Anda.

Prasyarat
Flutter SDK: Pastikan Flutter sudah terinstal. Cek dengan flutter --version.

IDE: Visual Studio Code atau Android Studio.

Akun Firebase: Anda memerlukan akses ke proyek Firebase yang digunakan.

Langkah-langkah Instalasi
Clone Repository Ini

git clone [https://github.com/aruhaxs/siges_mobile.git](https://github.com/aruhaxs/siges_mobile.git)
cd siges_mobile

Dapatkan Dependensi Flutter

flutter pub get

Konfigurasi Firebase (Langkah Paling Penting)
Aplikasi ini membutuhkan koneksi ke proyek Firebase. Gunakan FlutterFire CLI untuk mengaturnya secara otomatis.

# Instal FlutterFire CLI jika belum ada
dart pub global activate flutterfire_cli

# Login ke akun Firebase Anda
firebase login

# Hubungkan proyek Flutter dengan proyek Firebase
flutterfire configure

Saat diminta, pilih proyek Firebase yang sesuai dari daftar yang muncul. Perintah ini akan secara otomatis membuat file lib/firebase_options.dart dan mengunduh google-services.json untuk Android.

▶️ Cara Menjalankan Aplikasi
Pastikan emulator Anda berjalan atau perangkat fisik terhubung.

Jalankan perintah berikut dari direktori utama proyek:

flutter run

📁 Struktur Proyek
Proyek ini menggunakan struktur folder berlapis untuk menjaga kerapian kode:

lib/
├── main.dart         # Titik masuk utama aplikasi
└── src/              # Folder utama untuk kode sumber
    └── screens/      # File untuk setiap halaman/tampilan di aplikasi
        ├── auth_gate.dart
        ├── login_screen.dart
        ├── signup_screen.dart
        ├── main_screen.dart
        ├── dashboard_screen.dart
        ├── map_screen.dart
        ├── manage_data_screen.dart
        ├── add_edit_screen.dart
        └── detail_screen.dart

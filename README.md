# OOTDMate - Frontend

OOTDMate adalah aplikasi *virtual wardrobe* pintar bergaya modern/cyberpunk yang memanfaatkan AI untuk membantu pengguna mengelola lemari pakaian dan menghasilkan rekomendasi Outfit of the Day (OOTD) berdasarkan kemiripan visual.

Aplikasi ini merupakan bagian dari sistem terintegrasi yang dibangun menggunakan **Flutter (Frontend)** dan **FastAPI (Backend)** dengan model *Deep Learning* (MobileNetV2).

---

## ✨ Fitur Utama

- **Cyberpunk / Modern Aesthetic**: Antarmuka pengguna (UI) berdesain gelap (*dark mode*) yang memukau dengan aksen warna Acid Green, Neon Blue, dan Glitch Magenta.
- **Beranda (Dashboard & Insights)**: Menampilkan ringkasan lemari pakaian Anda, termasuk grafik donat interaktif (*Wardrobe Donut Chart*) dan statistik komposisi pakaian.
- **Kelola Lemari (Wardrobe Management)**: Lihat, edit, hapus, dan simpan detail pakaian Anda (termasuk foto resolusi penuh, catatan personal, dan *confidence score* dari AI saat proses *auto-tagging*).
- **AI OOTD Matcher (Recommendation)**: 
  - Memungkinkan Anda memilih 1 pakaian acuan (*anchor item*).
  - AI akan memindai lemari Anda dan mencarikan padanan pakaian dari kategori lain (misal: Atasan -> mencarikan Celana & Sepatu) menggunakan *Cross-Category Semantic Similarity*.
  - Menampilkan persentase Tingkat Keserasian (*Compatibility Score*) secara *real-time*.
  - **Insta-Shuffle**: Dapatkan alternatif gaya lain dalam sekejap tanpa *loading* ulang!
- **Koleksi Favorit (Saved Outfits)**: Simpan kombinasi OOTD terbaik yang direkomendasikan AI ke daftar Favorit agar mudah dilihat kembali atau dihapus jika sudah bosan.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **HTTP Client**: `dio` (dengan *interceptor* kustom untuk injeksi token otomatis)
- **State Management**: Standar *setState* dengan pemisahan State vs API Service (Arsitektur MVCS ringan).
- **Theme System**: Terpusat pada `lib/core/theme/app_theme.dart` (Token Warna, Tipografi, Style Global).
- **Backend Integrations**: FastAPI (Python) - *Repositori backend terpisah.*

---

## 📂 Struktur Direktori

```text
lib/
├── core/
│   ├── constants/        # Base URL, API Config, Error Handlers
│   ├── theme/            # AppTheme, Colors, Typography
│   └── utils/            # Helper functions
├── models/               # Data model / DTO (Wardrobe, Recommendation, dll)
├── screens/
│   ├── auth/             # Login & Register
│   └── core/
│       ├── home/         # Dashboard & Statistik
│       ├── wardrobes/    # List Pakaian & Item Details
│       ├── recommendation/ # AI OOTD Matcher
│       ├── favorite/     # Saved Outfits
│       └── main_screen.dart # Bottom Navigation Shell
├── services/
│   ├── api-services/     # Komunikasi HTTP dengan Backend
│   └── auth-services/    # Token management & User profile
└── widgets/              # Reusable UI components (Custom Charts, NavBars, dll)
```

---

## 🚀 Panduan Memulai (Getting Started)

### Prasyarat
1. Pastikan Anda telah menginstal [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Pastikan repositori **OOTDMate Backend** sudah berjalan di mesin lokal Anda (atau URL *cloud*).

### Instalasi
1. Kloning repositori ini.
2. Buka terminal di *root* proyek, lalu jalankan perintah:
   ```bash
   flutter pub get
   ```
3. Sesuaikan *Base URL* API di `lib/core/constants/dio_client.dart` jika backend Anda berjalan pada port atau alamat IP yang berbeda (misalnya, ganti ke alamat IPv4 laptop Anda saat melakukan testing di *physical device*).
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 🎨 Design Guideline (Bagi Kontributor)

Untuk menjaga konsistensi gaya aplikasi, perhatikan panduan berikut saat membuat komponen baru:
- **Warna Latar Utama**: Gunakan `AppTheme.primary` (Gelap/Hitam) atau `AppTheme.secondary` (Kartu/Kontainer abu-abu gelap).
- **Aksen Primer**: Gunakan `AppTheme.acidGreen` untuk tombol Call to Action (CTA) dan interaksi positif.
- **Aksen Sekunder**: Gunakan `AppTheme.neonBlue` atau `AppTheme.glitchMagenta` untuk indikator status, *loading pulse*, atau elemen kosmetik *cyberpunk*.
- Hindari penggunaan bayangan (*drop shadows*) yang berlebihan; utamakan garis batas (*border*) tipis berwarna neon transparan untuk kesan futuristik.

---

*Dibuat untuk Tugas Akhir / Skripsi 2026*

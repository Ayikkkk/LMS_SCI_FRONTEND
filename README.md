# LMS SCI Media — Frontend (Flutter)

Aplikasi mobile LMS untuk siswa SD/MI berbasis **Flutter**. Target platform utama adalah **Android**.

---

## Prasyarat

| Tool | Versi Minimum |
|------|--------------|
| Flutter SDK | 3.22+ |
| Dart SDK | 3.0+ |
| Android Studio | Hedgehog / Koala |
| Android SDK | API 21+ (Android 5.0) |
| Java | 17 |

> Cek versi Flutter: `flutter --version`
> Cek environment: `flutter doctor`

---

## Instalasi & Setup

### 1. Clone repository

```bash
git clone https://github.com/Ayikkkk/LMS_SCI_FRONTEND.git
cd LMS_SCI_FRONTEND
```

### 2. Install dependensi

```bash
flutter pub get
```

### 3. Konfigurasi API URL

Edit file `lib/core/config/environment.dart`:

```dart
// Development (lokal Laragon)
defaultValue: 'http://192.168.1.x:8000/api/',   // Sesuaikan IP lokal Anda

// Staging / Production (VPS)
// Sudah dikonfigurasi di case Environment.staging dan production
```

Atau gunakan `--dart-define` saat run/build tanpa mengubah file:

```bash
# Development lokal
flutter run --dart-define=DEV_API_URL=http://192.168.1.x:8000/api/

# Staging (VPS)
flutter run --dart-define=ENV=staging

# Production (VPS)
flutter run --dart-define=ENV=production
```

---

## Menjalankan Aplikasi

### Android (HP/Emulator)

```bash
# Development lokal
flutter run

# Dengan VPS backend
flutter run --dart-define=ENV=staging
```

### Chrome (Web — untuk testing UI)

```bash
# Development lokal
flutter run -d chrome

# Dengan VPS backend
flutter run -d chrome --dart-define=ENV=staging
```

> **Catatan**: Firebase (Crashlytics & Analytics) hanya aktif di Android. Di Web, Firebase dinonaktifkan secara otomatis.

---

## Build Release

### APK (distribusi langsung)

```bash
flutter build apk --release --dart-define=ENV=production
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (Google Play Store)

```bash
flutter build appbundle --release --dart-define=ENV=production
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Struktur Project

```
lib/
├── core/
│   ├── config/          # Konfigurasi environment (API URL, timeout)
│   ├── network/         # Dio client & interceptors
│   ├── services/        # Firebase, Crashlytics, Analytics, Version
│   ├── theme/           # Dark/Light theme
│   └── widgets/         # Widget reusable (splash, error, empty state)
├── features/
│   ├── auth/            # Login, onboarding, change password
│   ├── home/            # Dashboard utama
│   ├── course/          # Materi, tugas, submit tugas, komentar
│   ├── quiz/            # Daftar & kerjakan quiz
│   ├── grades/          # Rekap nilai
│   ├── online_class/    # Kelas online (Jitsi Meet)
│   ├── laporan_harian/  # Laporan harian siswa
│   └── profile/         # Profil siswa & pengaturan
├── navigation_service.dart
├── auth_redirector.dart
└── main.dart
```

---

## Fitur Utama

- **Login siswa** dengan token Sanctum (7 hari)
- **Dashboard** — statistik akademik, tugas pending, kelas online hari ini
- **Materi & Tugas** — lihat, download lampiran, submit jawaban dengan file attachment
- **Quiz** — pilihan ganda, multiple answer, benar/salah, essay, isian singkat
  - Timer countdown
  - Auto-submit saat waktu habis
  - Retry otomatis saat offline (pending submit)
  - Monitoring aktivitas (suspicious flag)
- **Kelas Online** — integrasi Jitsi Meet
- **Rekap Nilai** — per mata pelajaran, export PDF
- **Laporan Harian** — isi laporan harian dengan foto dokumentasi
- **Profil** — edit nama, username, foto; ganti password; mode gelap

---

## Konfigurasi Firebase (Android)

Firebase sudah dikonfigurasi untuk Android. File `google-services.json` sudah ada di `android/app/`.

Jika file tidak ada (project baru / file terhapus):
1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project → Project Settings → Android app
3. Download `google-services.json`
4. Letakkan di `android/app/google-services.json`

> Firebase **tidak** digunakan di Web — sudah di-skip otomatis via `kIsWeb`.

---

## Environment Variables

| Variable | Default | Keterangan |
|----------|---------|------------|
| `ENV` | `development` | `development` / `staging` / `production` |
| `DEV_API_URL` | `http://192.168.1.107:8000/api/` | API URL untuk mode development |
| `DEV_API_HOST` | `http://192.168.1.107:8000` | API Host untuk mode development |

---

## Troubleshooting

### `flutter doctor` menunjukkan error

```bash
flutter doctor --verbose
```

Ikuti instruksi yang ditampilkan untuk menginstall komponen yang kurang.

### API tidak bisa diakses dari HP

Pastikan:
1. HP dan komputer terhubung ke jaringan WiFi yang sama
2. Backend berjalan dengan `php artisan serve --host=0.0.0.0 --port=8000`
3. Firewall tidak memblokir port 8000
4. IP di `DEV_API_URL` sesuai IP komputer di jaringan lokal (`ipconfig`)

### Build error saat `flutter pub get`

```bash
flutter clean
flutter pub get
```

### `media_store_plus` error di Web

Normal — package ini khusus Android. Error sudah di-handle secara conditional di kode.

---

## Tech Stack

- **Framework**: Flutter 3.22+
- **State Management**: Riverpod 2.x
- **HTTP Client**: Dio 5.x
- **Auth Storage**: Flutter Secure Storage
- **Video Konferensi**: Jitsi Meet Flutter SDK
- **Firebase**: Crashlytics + Analytics (Android only)
- **PDF Viewer**: open_filex
- **Local Storage**: SharedPreferences

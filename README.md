# EduTech SMK — Learning Management System

> Tugas UAS Mobile And Cross-Platform Development  
> Kelompok 1 — RPL 6-A

Aplikasi LMS berbasis Flutter + Firebase untuk SMK, mendukung 6 role pengguna dengan fitur lengkap manajemen pembelajaran.

## Anggota Kelompok

| No | Nama | NIM | Kelas |
|----|------|-----|-------|
| 1  | JUSRIADI LIWANG | 105841117023  | RPL 6A |
| 2  | HASRIANA | 105841107623  | RPL 6A |
| 3  | ANDI NAIVA NOOR | 105841122223 | RPL 6A |
| 4  | M ARFAN MAULANA IRWANSYAH | 105841122523  | RPL 6A |
| 5  | GUSHRYANTO LIBELS| 105841118523| RPL 6A |


## Live Demo

| Platform | URL |
|----------|-----|
| Web App (Firebase Hosting) | [https://edutech-smk-app-71383.web.app](https://edutech-smk-app-71383.web.app) |
| Firebase Console | [console.firebase.google.com](https://console.firebase.google.com/project/edutech-smk-app-71383) |
| Link Youtube |  https://youtu.be/MvUt-6WpoSQ?feature=shared 

### Akun Demo

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@gmail.com` | `kelompok1` |
| Siswa | `siswa@demo.com` | `demo1234` |
| Guru Mapel | `guru@demo.com` | `demo1234` |
| Wali Kelas | `wali@demo.com` | `demo1234` |
| Guru BK | `bk@demo.com` | `demo1234` |
| Guru Piket | `piket@demo.com` | `demo1234` |

---

## Fitur Aplikasi

### Role Siswa
- Dashboard dengan statistik real-time (tugas aktif, rata-rata nilai, kehadiran)
- Akses materi pembelajaran (PDF & Video)
- Pengumpulan tugas dengan upload file ke Firebase Storage
- **Kuis online** (Multiple Choice dengan timer countdown, auto-grading)
- **Tab Nilai** — riwayat nilai + rata-rata per siswa
- Jadwal pelajaran (Senin–Jumat)
- Rekap absensi bulanan
- Chat dengan guru (Forum Diskusi & Chat langsung)
- Ajukan konseling BK
- Lihat poin pelanggaran

### Role Guru Mapel
- Dashboard dengan daftar submisi yang perlu dinilai
- Upload materi (PDF/Video ke Firebase Storage)
- Buat dan kelola tugas dengan deadline
- **Quiz Builder** — buat soal MC dengan pilihan jawaban
- Input absensi per kelas (Hadir/Alpha/Izin/Sakit)
- Nilai submisi siswa dengan feedback
- **Statistik** — distribusi nilai, rekap absensi, daftar kuis

### Role Wali Kelas
- Dashboard overview kelas perwalian
- Monitoring nilai akademik siswa per kelas
- Rekap absensi kelas
- Manajemen pelanggaran siswa (tambah, lihat riwayat)
- Alert sistem otomatis
- Buku penghubung (chat)
- Kirim notifikasi ke orang tua

### Role Guru BK
- Dashboard konseling (stats Open/On Going/Resolved)
- Approve/Reject pengajuan konseling siswa
- Manajemen kasus per kategori (Akademik/Sosial/Pribadi/Karir/Pelanggaran)
- Chat konfidensial dengan siswa
- Case tracking (Open → In Progress → Resolved)

### Role Guru Piket
- Dashboard kehadiran harian (Hadir/Terlambat/Tidak Hadir)
- Scan QR absensi siswa
- Input manual via NISN
- Catat kejadian & buku piket digital
- Broadcast darurat ke semua pengguna

### Role Admin
- Dashboard statistik pengguna per role
- Kelola pengguna (tambah, cari, filter, hapus)
- **Tambah pengguna baru** dengan kirim email otomatis
- Kelola pengumuman (buat, hapus)
- Laporan absensi & pelanggaran sekolah

---

## Cara Menjalankan (Development)

### Prasyarat

```bash
# Install Flutter SDK (versi 3.24+)
# Download: https://docs.flutter.dev/get-started/install/windows

# Install Node.js (versi 18+)
# Download: https://nodejs.org

# Install Firebase CLI
npm install -g firebase-tools

# Login Firebase
firebase login
```

### Setup Project

```bash
# Clone repository
git clone https://github.com/Jusriadiliwang/edutech-smk-uas-mobile-kelompok-1-rpl-6-A.git
cd edutech-smk-uas-mobile-kelompok-1-rpl-6-A

# Install Flutter dependencies
flutter pub get

# Install Node dependencies (untuk seed script)
npm install
```

### Menjalankan Aplikasi (Cara Cepat)

Gunakan script otomatis yang menangani semua setup:

```powershell
# Windows PowerShell
.\start_dev.ps1
```

Script ini otomatis:
1. Cek dan start Firebase Emulator (jika pakai emulator)
2. Jalankan seed data
3. Buka Chrome dengan aplikasi di `localhost:58715`

### Menjalankan Manual

```bash
# Mode Development (Chrome)
flutter run -d chrome --web-port 58715

# Mode Production (pakai Firebase real)
# Pastikan useEmulator = false di lib/main.dart
flutter run -d chrome --web-port 58715

# Build untuk Web
flutter build web --release

# Build untuk Android APK
flutter build apk --release
```

### Deploy ke Firebase Hosting

```bash
# Build release
flutter build web --release

# Deploy
firebase deploy --only hosting --project edutech-smk-app-71383
```

### Seed Data Production

```bash
# Isi akun demo ke Firebase production
node seed_production.js

# Isi data ke Firebase Emulator (lokal)
node seed_data.js
```

---

## Konfigurasi Firebase

File konfigurasi: `lib/firebase_options.dart`

```dart
// Ganti mode di lib/main.dart:
const bool useEmulator = false;  // false = production Firebase
const bool useEmulator = true;   // true  = local emulator
```

### Firebase Services yang Digunakan
- **Authentication** — Email/Password login
- **Cloud Firestore** — Database real-time
- **Firebase Storage** — Upload file materi & tugas
- **Firebase Hosting** — Web deployment
- **Cloud Messaging (FCM)** — Push notification

---

## Struktur Project

```
lib/
├── main.dart                    # Entry point + AuthWrapper
├── firebase_options.dart        # Firebase config
├── core/
│   ├── constants/
│   │   ├── roles.dart           # Role constants (SISWA, GURU_MAPEL, dll)
│   │   └── firebase_constants.dart  # Collection names
│   ├── services/
│   │   ├── fcm_service.dart     # Push notification service
│   │   └── storage_service.dart # Firebase Storage service
│   └── theme/
│       └── app_theme.dart       # UI theme & reusable widgets
└── features/
    ├── auth/
    │   ├── login_page.dart      # Halaman login
    │   ├── register_page.dart   # Registrasi siswa baru
    │   └── role_selection.dart  # Router berdasarkan role
    ├── student/
    │   ├── student_dashboard_page.dart
    │   ├── assignment_view.dart  # Kumpul tugas
    │   └── quiz_page.dart       # Kuis online
    ├── teacher/
    │   ├── teacher_dashboard_page.dart
    │   └── upload_material_page.dart
    ├── wali_kelas/
    │   ├── wali_dashboard_page.dart
    │   └── alert_system_widget.dart
    ├── bk/
    │   ├── bk_dashboard_page.dart
    │   └── case_tracking_page.dart
    ├── piket/
    │   ├── piket_dashboard_page.dart
    │   └── quick_scan_page.dart
    ├── admin/
    │   └── admin_dashboard_page.dart
    └── shared/
        ├── chat_room_page.dart
        └── notification_list_page.dart
```

---

## Firestore Collections

| Collection | Deskripsi |
|-----------|-----------|
| `users` | Data pengguna + role |
| `materials` | Materi pembelajaran |
| `assignments` | Tugas yang diberikan guru |
| `submissions` | Pengumpulan tugas siswa |
| `quizzes` | Soal kuis |
| `quiz_answers` | Jawaban kuis siswa |
| `absences` | Data absensi |
| `violations` | Pelanggaran siswa |
| `counseling` | Sesi konseling BK |
| `announcements` | Pengumuman sekolah |
| `schedules` | Jadwal pelajaran |
| `notifications` | Notifikasi pengguna |
| `chats/{id}/messages` | Pesan chat |
| `piket_log` | Buku piket digital |

---

## Tech Stack

| Technology | Version |
|-----------|---------|
| Flutter | 3.24.5 |
| Dart | 3.x |
| firebase_core | ^2.27.0 |
| firebase_auth | ^4.17.8 |
| cloud_firestore | ^4.15.8 |
| firebase_storage | ^11.6.9 |
| firebase_messaging | ^14.7.19 |
| intl | ^0.19.0 |

---

## Tim Pengembang

Kelompok 1 — RPL 6-A  
Mata Kuliah: Mobile And Cross-Platform Development  
Universitas Muhammadiyah Makassar

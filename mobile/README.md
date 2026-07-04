# Mobile (Flutter)

## Setup

```bash
flutter pub get
```

Backend (`../backend`) harus sudah jalan di `localhost:3000` sebelum login/mendaftar dari app.

## Menjalankan

**Web (Chrome) — paling cepat untuk pratinjau:**
```bash
flutter run -d chrome
```

**Android (emulator):**
```bash
flutter run
```
lalu pilih device emulator yang sudah menyala.

Base URL backend otomatis menyesuaikan platform (`lib/api.dart`):
- Web → `http://localhost:3000/api`
- Android emulator → `http://10.0.2.2:3000/api` (alias localhost host dari sudut pandang emulator)

Kalau menjalankan di **HP fisik** (bukan emulator), ganti base URL di `lib/api.dart` ke alamat IP LAN laptop.

## Struktur kode

Tiap modul = 1 file di `lib/modules/`:
- `auth.dart` — Welcome / Login / Register
- `people_to_project.dart` — 3 tab (Rekomendasi/Terdaftar/Proyek Saya) + Detail Proyek + Kelola Proyek + Buat Proyek
- `people_to_people.dart` — 2 tab utama (Rekomendasi/Koneksi) + Detail Partner:
  - Rekomendasi: filter band skor (Semua/Sangat Cocok/Cocok/Cukup Cocok) + filter atribut (minat/peran/gaya kerja/waktu) lewat bottom sheet, kartu tinggi konsisten, status tombol Simpan/Tertarik tersimpan per kandidat
  - Koneksi: 4 sub-tab — Terhubung (dengan tag asal koneksi "Saling tertarik"/"Via koneksi"), Permintaan, Disimpan, Menyukai (cuma jumlah, identitas dirahasiakan sampai mutual)
  - Badge merah di tab Koneksi untuk permintaan pending + koneksi baru yang belum dilihat
- `profil.dart` — tab Profil (lihat & edit 6 atribut kolaboratif + asal kampus/jurusan/angkatan/bio + kontak) + tombol Keluar
- `team_formation.dart` — placeholder, belum ada isinya

`main.dart` menyimpan navigasi login (`masukKeApp`) dan logout (`keluarDariApp`) sebagai fungsi bersama.

## Akun demo

Tidak ada akun demo bawaan — lihat README root bagian "Akun demo" untuk cara membuat akun testing lewat halaman Register + Edit Profil.

## Catatan

- Hot reload (`r`) cukup untuk perubahan tampilan kecil. Kalau ada class/halaman baru atau perubahan navigasi, pakai hot restart (`R`).
- Kalau `flutter` tidak dikenali di terminal padahal sudah terpasang, biasanya karena terminal dibuka sebelum PATH diperbarui — buka terminal baru, atau pakai path lengkap `C:\src\flutter\bin\flutter.bat`.

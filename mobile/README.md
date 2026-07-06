# Mobile (Flutter)

## Setup

```bash
flutter pub get
```

Backend (`../backend`) harus sudah jalan di `localhost:3000` sebelum login/daftar dari app.

## Menjalankan

Paling cepat untuk pratinjau, pakai web:
```bash
flutter run -d chrome
```

Atau di emulator Android:
```bash
flutter run
```
lalu pilih device emulator yang sudah menyala.

Base URL backend menyesuaikan otomatis (lihat `lib/api.dart`): web ke `localhost:3000`, emulator Android ke `10.0.2.2:3000` (alias localhost dari sudut pandang emulator). Kalau dites di HP fisik, ganti base URL itu manual ke alamat IP LAN laptop.

## Struktur

- `lib/design_system.dart` — komponen & warna yang dipakai bersama semua modul, supaya tampilannya konsisten.
- `lib/main.dart` — navigasi, tema, bottom nav, dan alur tur pengenalan fitur untuk user baru.
- `lib/modules/auth.dart` — Welcome, Login, Register.
- `lib/modules/profil.dart` — lihat & edit profil kolaboratif.
- `lib/modules/people_to_project.dart`, `people_to_people.dart`, `team_formation.dart` — satu file per modul.

## Catatan

- Hot reload (`r`) cukup untuk perubahan tampilan kecil. Kalau ada class/halaman baru atau perubahan navigasi, pakai hot restart (`R`).
- Kalau `flutter` tidak dikenali di terminal padahal sudah terpasang, biasanya PATH belum ke-refresh di terminal itu — buka terminal baru.

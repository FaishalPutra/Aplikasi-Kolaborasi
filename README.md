# Aplikasi Kolaborasi Mahasiswa

Aplikasi pencarian peluang kolaborasi mahasiswa, terdiri dari 3 modul rekomendasi berbasis *Affinity Based Matching*. Monorepo: `backend/` (Express + Prisma + PostgreSQL) dan `mobile/` (Flutter).

## Status modul

| Modul | PIC (TA) | Status |
|---|---|---|
| **People-to-Project** — mahasiswa ⇄ proyek/kegiatan | Muhammad Faishal Putra | ✅ Selesai (backend + UI, tersambung penuh) |
| **People-to-People** — mahasiswa ⇄ mahasiswa | Ahmad Fawwazi | ✅ Selesai (backend + UI, tersambung penuh) |
| **Team Formation** — pembentukan tim | Muhammad Faishal Firdaus | ⛔ Belum dikerjakan (baru placeholder `/health`) |
| **General Features** — auth, profil, tab Profil | bersama | ✅ Selesai |

## Arsitektur singkat

```
mobile (Flutter)  --HTTP JSON-->  backend (Express)  --Prisma-->  PostgreSQL
```

- **Dua mesin Affinity Engine independen**, masing-masing sesuai TA-nya sendiri:
  - `backend/src/affinityProject.ts` — People-to-Project (2 sub-algoritma, kombinasi 50:50, + hard-constraint jadwal)
  - `backend/src/affinityPeople.ts` — People-to-People (1 weighted-sum ROC, simetris)
- **Skor kecocokan selalu dihitung ulang saat itu juga** setiap kali feed/detail/kelola dibuka — bukan dijadwalkan atau di-cache. Efek edit profil langsung terlihat begitu halaman dibuka ulang.
- `ketersediaanWaktu` pada People-to-Project adalah **hard-constraint filter** (gerbang lolos/tidak, Tahap 0), bukan bagian dari skor berbobot.

## Menjalankan (2 terminal)

**1) Backend**
```bash
cd backend
npm install
cp .env.example .env        # isi DATABASE_URL (lihat backend/README.md)
npm run prisma:generate
npm run prisma:migrate
npm run dev                 # http://localhost:3000
```

**2) Mobile**
```bash
cd mobile
flutter pub get
flutter run -d chrome       # atau: flutter run (pilih emulator Android)
```

PostgreSQL harus sudah jalan (service lokal) sebelum backend dinyalakan. Detail lengkap ada di `backend/README.md` dan `mobile/README.md`.

## Akun demo

Sudah tersedia di database lokal (password sama semua: `123456`), profil sudah lengkap:

| Email | Nama | Catatan |
|---|---|---|
| `sarah@test.id` | Sarah Wijaya | Pembuat 3 proyek demo (skor 100%/71,5%/43,1% terhadap satu sama lain) |
| `budi@test.id` | Budi Santoso | Pembuat 3 proyek demo di atas |
| `citra.uji@test.id` | Citra Uji | Akun uji alur signup → isi profil → pencocokan |
| `a@b.com` | Faishal A | Akun demo awal |

## Struktur folder

```
backend/
  prisma/schema.prisma       # semua model (ditandai [SHARED]/[P2P-PROJECT]/[P2P-PEOPLE]/[TEAM-FORM])
  src/
    affinityProject.ts       # Affinity Engine People-to-Project
    affinityPeople.ts        # Affinity Engine People-to-People
    modules/
      general.ts             # auth + profil (UC01-04)
      peopleToProject.ts      # UC05-11
      peopleToPeople.ts       # UC05-12
      teamFormation.ts        # placeholder
mobile/
  lib/
    api.dart                 # base URL (web vs Android emulator) + helper HTTP
    main.dart                # navigasi, tema, bottom nav 4 tab
    modules/
      auth.dart               # Welcome/Login/Register
      people_to_project.dart  # Rekomendasi/Terdaftar/Proyek Saya + detail/kelola/buat
      people_to_people.dart   # Rekomendasi/Koneksi + detail partner
      profil.dart              # tab Profil (baca + edit)
      team_formation.dart      # placeholder
```

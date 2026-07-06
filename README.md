# Aplikasi Kolaborasi Mahasiswa

Aplikasi untuk membantu mahasiswa menemukan rekan kolaborasi yang cocok, baik itu teman satu proyek/kegiatan, teman satu minat, maupun tim untuk ikut lomba. Semuanya dicocokkan pakai algoritma affinity matching, bukan sekadar pencarian biasa.

Ada 3 modul utama:

- **People-to-Project** — mencocokkan mahasiswa dengan proyek/kegiatan yang lagi butuh anggota.
- **People-to-People** — mencocokkan mahasiswa dengan mahasiswa lain untuk berkolaborasi.
- **Team Formation** — bantu mahasiswa membentuk tim lomba, lengkap dengan pembagian peran berdasarkan profil TREO.

Project ini dikerjakan bertiga sebagai Tugas Akhir, masing-masing pegang satu modul: Ahmad Fawwazi (People-to-People), Muhammad Faishal Putra (People-to-Project), dan Muhammad Faishal Firdaus (Team Formation).

## Teknologi

Backend pakai Express + Prisma + PostgreSQL, mobile app pakai Flutter. Repo ini monorepo — `backend/` dan `mobile/` jadi satu supaya gampang disinkronkan.

## Cara menjalankan

Butuh 2 terminal terpisah, dan PostgreSQL sudah harus jalan duluan.

**Backend:**
```bash
cd backend
npm install
cp .env.example .env   # isi DATABASE_URL, lihat backend/README.md
npm run prisma:generate
npm run prisma:migrate
npm run dev             # jalan di http://localhost:3000
```

**Mobile:**
```bash
cd mobile
flutter pub get
flutter run -d chrome   # atau `flutter run` lalu pilih emulator Android
```

Detail lebih lanjut ada di `backend/README.md` dan `mobile/README.md`.

## Akun untuk testing

Database kosong begitu migrasi pertama selesai — belum ada akun bawaan. Daftar akun sendiri lewat halaman Register, atau lewat `POST /api/auth/register`, lalu lengkapi profil di halaman Profil supaya bisa dapat rekomendasi. Butuh minimal 2 akun dengan profil lengkap kalau mau coba alur dua arah (kirim minat, hubungkan, gabung tim, dll).

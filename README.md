# Aplikasi Kolaborasi Mahasiswa

Aplikasi Kolaborasi Mahasiswa adalah platform yang dirancang untuk membantu mahasiswa menemukan rekan kolaborasi yang sesuai, baik untuk proyek, kegiatan, minat yang sama, maupun pembentukan tim lomba. Sistem ini tidak hanya menggunakan pencarian biasa, tetapi menerapkan algoritma **affinity matching** untuk mencocokkan profil mahasiswa dengan kebutuhan kolaborasi secara lebih relevan.

## Modul Utama

Aplikasi ini terdiri dari tiga modul utama:

### People-to-Project

Modul ini mencocokkan mahasiswa dengan proyek atau kegiatan yang sedang membutuhkan anggota. Rekomendasi diberikan berdasarkan kesesuaian antara profil mahasiswa dengan kebutuhan proyek, seperti minat, kemampuan, pengalaman, preferensi peran, dan ketersediaan.

### People-to-People

Modul ini mencocokkan mahasiswa dengan mahasiswa lain yang memiliki potensi kolaborasi. Pencocokan dilakukan berdasarkan profil kolaboratif, seperti kesamaan minat, kemampuan, gaya kerja, pengalaman, dan preferensi dalam bekerja sama.

### Team Formation

Modul ini membantu mahasiswa membentuk tim lomba dengan pembagian peran yang lebih terarah. Proses pembentukan tim mempertimbangkan profil mahasiswa dan pendekatan TREO agar komposisi tim menjadi lebih seimbang.

## Tim Pengembang

Project ini dikembangkan oleh tiga mahasiswa sebagai bagian dari Tugas Akhir. Setiap anggota bertanggung jawab pada satu modul utama:

| Nama                     | Modul             |
| ------------------------ | ----------------- |
| Ahmad Fawwazi            | People-to-People  |
| Muhammad Faishal Putra   | People-to-Project |
| Muhammad Faishal Firdaus | Team Formation    |

## Teknologi yang Digunakan

Project ini menggunakan arsitektur monorepo, sehingga kode backend dan mobile app berada dalam satu repository agar lebih mudah disinkronkan selama pengembangan.

| Bagian        | Teknologi                   |
| ------------- | --------------------------- |
| Backend       | Express, Prisma, PostgreSQL |
| Mobile App    | Flutter                     |
| Database      | PostgreSQL                  |
| Struktur Repo | Monorepo                    |

Struktur utama repository:

```bash
.
├── backend/
└── mobile/
```

## Cara Menjalankan Project

Sebelum menjalankan aplikasi, pastikan PostgreSQL sudah aktif dan dapat diakses. Project ini membutuhkan dua terminal terpisah: satu untuk backend dan satu untuk mobile app.

## Menjalankan Backend

Masuk ke folder backend:

```bash
cd backend
```

Install dependency:

```bash
npm install
```

Buat file environment dari contoh yang tersedia:

```bash
cp .env.example .env
```

Isi konfigurasi `DATABASE_URL` pada file `.env`. Detail konfigurasi dapat dilihat pada `backend/README.md`.

Generate Prisma Client:

```bash
npm run prisma:generate
```

Jalankan migrasi database:

```bash
npm run prisma:migrate
```

Jalankan server backend:

```bash
npm run dev
```

Backend akan berjalan di:

```bash
http://localhost:3000
```

## Menjalankan Mobile App

Buka terminal baru, lalu masuk ke folder mobile:

```bash
cd mobile
```

Install dependency Flutter:

```bash
flutter pub get
```

Jalankan aplikasi melalui browser Chrome:

```bash
flutter run -d chrome
```

Atau jalankan menggunakan emulator Android:

```bash
flutter run
```

Lalu pilih emulator Android yang tersedia.

## Akun untuk Testing

Setelah migrasi pertama dijalankan, database masih dalam kondisi kosong dan belum memiliki akun bawaan.

Untuk melakukan testing, buat akun baru melalui salah satu cara berikut:

1. Melalui halaman Register pada aplikasi.
2. Melalui endpoint:

```bash
POST /api/auth/register
```

Setelah akun berhasil dibuat, lengkapi profil kolaboratif melalui halaman Profil agar sistem dapat memberikan rekomendasi.

Untuk menguji alur kolaborasi dua arah, seperti mengirim minat, terhubung dengan mahasiswa lain, atau bergabung ke tim, disarankan menggunakan minimal dua akun dengan profil yang sudah lengkap.


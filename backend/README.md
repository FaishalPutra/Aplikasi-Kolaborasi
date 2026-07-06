# Backend

Express + Prisma + PostgreSQL. Tiap modul punya file sendiri di `src/modules/`, digabung lewat `src/routes.ts`.

## Setup

```bash
npm install
cp .env.example .env
```

Isi `.env`:
```
DATABASE_URL="postgresql://<user>:<password>@localhost:5432/collab_platform?schema=public"
PORT=3000
JWT_SECRET="ganti-dengan-secret-acak"
```

PostgreSQL harus sudah jalan lokal, database `collab_platform` akan dibuat otomatis lewat migrasi pertama.

```bash
npm run prisma:generate     # generate Prisma Client
npm run prisma:migrate      # buat/sinkronkan tabel dari schema.prisma
npm run dev                 # jalan di http://localhost:3000, auto-reload
```

Kalau baru mengubah `schema.prisma`, jalankan `npm run prisma:migrate` lagi — perubahan skema tidak ikut auto-reload seperti kode `.ts` biasa.

Mau lihat isi database lewat GUI, bisa pakai `npx prisma studio` (default buka di `http://localhost:5555`).

## Struktur

- `src/modules/` — satu file per modul (`general.ts`, `peopleToProject.ts`, `peopleToPeople.ts`, `teamFormation.ts`), semuanya butuh header `Authorization: Bearer <token>` kecuali endpoint `/health` dan `/hitung`.
- `src/affinityProject.ts` & `src/affinityPeople.ts` — mesin pencocokan tiap modul, ditulis sebagai pure function (tidak menyentuh database) jadi gampang dites lewat endpoint `/hitung` masing-masing tanpa perlu data asli.
- `prisma/schema.prisma` — semua model database, ditandai per modul di komentarnya.

## Akun untuk testing

Tidak ada seed data bawaan — lihat README di root project bagian "Akun untuk testing".

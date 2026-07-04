# Backend (Express + Prisma + PostgreSQL)

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

PostgreSQL harus sudah jalan lokal (service Windows `postgresql-x64-16` atau setara) dan database `collab_platform` bisa dibuat otomatis oleh migrasi pertama.

```bash
npm run prisma:generate     # generate Prisma Client
npm run prisma:migrate      # buat/sinkronkan tabel dari schema.prisma
npm run dev                 # jalankan server, auto-reload (ts-node-dev) -> http://localhost:3000
```

Setelah mengubah `schema.prisma`, **selalu** jalankan `npm run prisma:migrate` lagi (perubahan skema tidak auto-reload seperti kode `.ts`).

Melihat isi database lewat GUI: `npx prisma studio` (buka `http://localhost:5555`).

## Struktur kode

Setiap modul = 1 file di `src/modules/`, digabung di `src/routes.ts`. Dua Affinity Engine terpisah (`src/affinityProject.ts`, `src/affinityPeople.ts`) — pure functions, tidak menyentuh database, jadi mudah diuji lewat endpoint `/hitung` masing-masing tanpa perlu data nyata.

## Endpoint

### General (`/api/auth`)
| Method | Path | Keterangan |
|---|---|---|
| POST | `/register` | UC01 |
| POST | `/login` | UC02 |
| POST | `/logout` | UC03 |
| GET/PUT | `/profil` | UC04 — 6 atribut kolaboratif |
| GET | `/me` | akun + profil sekaligus (dipakai tab Profil) |
| PUT | `/akun` | ubah nama, **asal kampus (wajib)**, jurusan, angkatan, bio, kontak, jenis kontak |

### People-to-Project (`/api/people-to-project`)
| Method | Path | Keterangan |
|---|---|---|
| POST | `/hitung` | demo Affinity Engine tanpa DB |
| GET | `/feed` | UC06 — rekomendasi (hitung ulang live) |
| POST | `/projects` | UC09 — buat kegiatan |
| GET | `/projects/:id` | UC07 — detail + breakdown skor |
| DELETE | `/projects/:id` | hapus kegiatan (khusus pembuat) |
| POST | `/projects/:id/daftar` | UC08 |
| DELETE | `/pendaftaran/:id` | batalkan pendaftaran (kuota dikembalikan jika sudah diterima) |
| GET | `/projects/:id/pendaftar` | UC10 — daftar pendaftar + skor live (khusus pembuat) |
| PATCH | `/pendaftaran/:id` | UC11 — terima/tolak |
| GET | `/terdaftar` | proyek yang diikuti (tab Terdaftar) |
| GET | `/saya` | proyek buatan sendiri (tab Proyek Saya) |

### People-to-People (`/api/people-to-people`)
| Method | Path | Keterangan |
|---|---|---|
| POST | `/hitung` | demo Affinity Engine tanpa DB |
| PATCH | `/visibility` | UC05 — muncul/sembunyi dari feed orang lain |
| GET | `/feed` | UC06+07 — rekomendasi. Filter band skor eksklusif `?tier=sangat\|cocok\|cukup`, dikombinasikan dengan filter atribut `?minat=`, `?peran=`, `?gaya=`, `?waktu=` (comma-separated, bisa gabung semua) |
| GET | `/profil/:id` | UC08 — detail calon partner, termasuk `sudahDisimpan`/`sudahTertarik` |
| POST | `/saved` / GET `/saved` | UC09 — GET sudah di-enrich (nama, institusi, skor) |
| POST | `/interest` | UC10 — **auto-connect kalau saling tertarik** (mutual express interest) |
| GET | `/menyukai-saya` | jumlah orang yang tertarik ke kita (`{ jumlah }`) — identitas sengaja dirahasiakan sampai mutual |
| POST | `/connect` | UC11 — kirim permintaan (auto-connect jika lawan sudah kirim duluan) |
| GET | `/requests` | daftar permintaan masuk |
| PATCH | `/connect/:id` | terima/tolak permintaan |
| GET | `/connections` | UC12 — daftar koneksi + kontak terbuka + `asal` (`INTEREST`/`REQUEST`, cara koneksi terbentuk) |

Semua endpoint (kecuali `/health` dan `/hitung`) butuh header `Authorization: Bearer <token>`.

## Akun demo

Tidak ada seed data — lihat README root bagian "Akun demo" untuk cara membuat akun testing sendiri.

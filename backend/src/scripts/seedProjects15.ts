// Tambah data dummy Project (People-to-Project) supaya SEMUA 15 akun dummy (lihat
// resetAndSeedDummy.ts) masing-masing jadi pembuat tepat satu proyek, dengan total
// kuota per proyek > 2. Elena & Kirana sudah punya proyek dari seed sebelumnya —
// script ini hanya menambah proyek untuk 13 mahasiswa lain (tidak menghapus apa pun).
//
// Jalankan: npx ts-node src/scripts/seedProjects15.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface RoleInput {
  namaRole: string; // taksonomi generik: Leader/Coordinator | Contributor/Executor | Supporter/Facilitator
  skillDicari: string[];
  kuota: number;
}

interface ProjectSeed {
  emailPembuat: string;
  judul: string;
  deskripsi: string;
  timeline: string;
  durasi: string;
  format: string;
  jadwalSlot: string[];
  pengalamanReq: number;
  minatTag: string[];
  gayaKerja: string;
  roles: RoleInput[];
}

const data: ProjectSeed[] = [
  {
    emailPembuat: 'bintang.pratama@dummy.test',
    judul: 'Sistem Rekomendasi Beasiswa Berbasis AI',
    deskripsi: 'Membangun sistem yang mencocokkan mahasiswa dengan program beasiswa yang relevan berdasarkan profil akademik.',
    timeline: '7 hari lagi', durasi: '4 bulan', format: 'Hybrid',
    jadwalSlot: ['Senin malam', 'Rabu sore'],
    pengalamanReq: 2, minatTag: ['AI', 'Data Science'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'SQL'], kuota: 2 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Analisis Data'], kuota: 1 },
    ],
  },
  {
    emailPembuat: 'citra.ayu@dummy.test',
    judul: 'Redesain Aplikasi Layanan Kampus',
    deskripsi: 'Merancang ulang UI/UX aplikasi layanan akademik kampus supaya lebih ramah pengguna.',
    timeline: '10 hari lagi', durasi: '2 bulan', format: 'Online',
    jadwalSlot: ['Selasa sore', 'Sabtu pagi'],
    pengalamanReq: 1, minatTag: ['Desain', 'UI/UX'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['UI Design'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Figma', 'Riset Pengguna'], kuota: 2 },
    ],
  },
  {
    emailPembuat: 'dimas.aditya@dummy.test',
    judul: 'Dashboard Analitik Data Akademik',
    deskripsi: 'Menyusun dashboard visualisasi data nilai & kehadiran mahasiswa untuk membantu keputusan akademik.',
    timeline: '14 hari lagi', durasi: '3 bulan', format: 'Hybrid',
    jadwalSlot: ['Kamis malam'],
    pengalamanReq: 2, minatTag: ['Data Science', 'AI'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Analisis Data'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'SQL'], kuota: 2 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 1 },
    ],
  },
  {
    emailPembuat: 'fajar.nugroho@dummy.test',
    judul: 'Website Marketplace UMKM Lokal',
    deskripsi: 'Membangun website marketplace sederhana untuk membantu UMKM di sekitar kampus berjualan daring.',
    timeline: '9 hari lagi', durasi: '3 bulan', format: 'Online',
    jadwalSlot: ['Senin malam'],
    pengalamanReq: 2, minatTag: ['Pengembangan Web'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['JavaScript'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['JavaScript', 'SQL'], kuota: 3 },
    ],
  },
  {
    emailPembuat: 'gita.amelia@dummy.test',
    judul: 'Inkubator Bisnis Mahasiswa',
    deskripsi: 'Program pendampingan rintisan usaha mahasiswa dari ide sampai purwarupa siap pitching.',
    timeline: '20 hari lagi', durasi: '5 bulan', format: 'Hybrid',
    jadwalSlot: ['Rabu sore', 'Sabtu pagi'],
    pengalamanReq: 2, minatTag: ['Kewirausahaan'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Public Speaking'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 2 },
    ],
  },
  {
    emailPembuat: 'hendra.setiawan@dummy.test',
    judul: 'Aplikasi Pengingat Tugas Kuliah',
    deskripsi: 'Aplikasi mobile sederhana untuk membantu mahasiswa mengelola deadline tugas dan jadwal kuliah.',
    timeline: '6 hari lagi', durasi: '2 bulan', format: 'Online',
    jadwalSlot: ['Selasa sore'],
    pengalamanReq: 1, minatTag: ['Pengembangan Mobile'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Flutter'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Flutter', 'JavaScript'], kuota: 2 },
    ],
  },
  {
    emailPembuat: 'indah.permata@dummy.test',
    judul: 'Konten Edukasi Literasi Digital',
    deskripsi: 'Membuat rangkaian konten edukasi seputar literasi digital untuk pelajar dan masyarakat umum.',
    timeline: '11 hari lagi', durasi: '2 bulan', format: 'Online',
    jadwalSlot: ['Minggu malam'],
    pengalamanReq: 1, minatTag: ['Kewirausahaan', 'Riset'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Penulisan'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Copywriting'], kuota: 2 },
    ],
  },
  {
    emailPembuat: 'joko.susilo@dummy.test',
    judul: 'Platform Manajemen Organisasi Kampus',
    deskripsi: 'Sistem untuk membantu organisasi mahasiswa mengelola anggota, agenda, dan keuangan secara digital.',
    timeline: '15 hari lagi', durasi: '4 bulan', format: 'Hybrid',
    jadwalSlot: ['Kamis malam', 'Jumat sore'],
    pengalamanReq: 2, minatTag: ['Pengembangan Web', 'AI'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['JavaScript'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'JavaScript', 'SQL'], kuota: 3 },
    ],
  },
  {
    emailPembuat: 'lukman.hakim@dummy.test',
    judul: 'Riset Prediksi Kelulusan Mahasiswa',
    deskripsi: 'Riset data historis akademik untuk memprediksi risiko keterlambatan kelulusan mahasiswa.',
    timeline: '13 hari lagi', durasi: '3 bulan', format: 'Online',
    jadwalSlot: ['Senin malam', 'Selasa sore'],
    pengalamanReq: 2, minatTag: ['Data Science'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Analisis Data'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['SQL', 'Analisis Data'], kuota: 2 },
    ],
  },
  {
    emailPembuat: 'mira.anggraini@dummy.test',
    judul: 'Survei Kepuasan Mahasiswa Terhadap Fasilitas Kampus',
    deskripsi: 'Survei dan analisis kepuasan mahasiswa terhadap fasilitas kampus untuk bahan masukan pihak kampus.',
    timeline: '8 hari lagi', durasi: '1 bulan', format: 'Online',
    jadwalSlot: ['Minggu malam'],
    pengalamanReq: 1, minatTag: ['Riset', 'Kewirausahaan'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 2 },
    ],
  },
  {
    emailPembuat: 'naufal.rizky@dummy.test',
    judul: 'Chatbot Konsultasi Akademik',
    deskripsi: 'Chatbot berbasis AI untuk membantu mahasiswa mendapatkan info akademik dengan cepat lewat aplikasi mobile.',
    timeline: '16 hari lagi', durasi: '3 bulan', format: 'Hybrid',
    jadwalSlot: ['Rabu sore'],
    pengalamanReq: 2, minatTag: ['Pengembangan Mobile', 'AI'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Flutter'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'Flutter'], kuota: 2 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['UI Design'], kuota: 1 },
    ],
  },
  {
    emailPembuat: 'oktavia.sari@dummy.test',
    judul: 'Kompetisi Ide Bisnis Mahasiswa',
    deskripsi: 'Menyelenggarakan kompetisi internal ide bisnis mahasiswa dari tahap ide sampai presentasi ke investor kampus.',
    timeline: '18 hari lagi', durasi: '2 bulan', format: 'Onsite',
    jadwalSlot: ['Jumat sore', 'Minggu malam'],
    pengalamanReq: 2, minatTag: ['Kewirausahaan'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Public Speaking'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 1 },
    ],
  },
  {
    emailPembuat: 'putra.wijaya@dummy.test',
    judul: 'Portal Informasi Lowongan Magang Mahasiswa',
    deskripsi: 'Portal agregator info lowongan magang dari berbagai sumber, disesuaikan dengan minat jurusan mahasiswa.',
    timeline: '12 hari lagi', durasi: '3 bulan', format: 'Online',
    jadwalSlot: ['Selasa sore', 'Kamis malam'],
    pengalamanReq: 1, minatTag: ['AI', 'Pengembangan Web'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['JavaScript'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'JavaScript'], kuota: 2 },
    ],
  },
];

async function main() {
  console.log('Menambahkan proyek dummy untuk 13 mahasiswa yang belum jadi pembuat proyek...');
  for (const p of data) {
    const mhs = await prisma.mahasiswa.findUnique({ where: { email: p.emailPembuat } });
    if (!mhs) {
      console.log(`  ! Lewati (mahasiswa tidak ditemukan): ${p.emailPembuat}`);
      continue;
    }
    const sudahPunya = await prisma.project.findFirst({ where: { pembuatId: mhs.id } });
    if (sudahPunya) {
      console.log(`  ! Lewati (sudah punya proyek): ${mhs.nama} -> ${sudahPunya.judul}`);
      continue;
    }
    const totalKuota = p.roles.reduce((s, r) => s + r.kuota, 0);
    const project = await prisma.project.create({
      data: {
        judul: p.judul,
        deskripsi: p.deskripsi,
        timeline: p.timeline,
        durasi: p.durasi,
        format: p.format,
        jadwalSlot: p.jadwalSlot,
        pengalamanReq: p.pengalamanReq,
        minatTag: p.minatTag,
        gayaKerja: p.gayaKerja,
        pembuatId: mhs.id,
        roles: {
          create: p.roles.map((r) => ({
            namaRole: r.namaRole,
            skillDicari: r.skillDicari,
            kuota: r.kuota,
            sisaKuota: r.kuota,
          })),
        },
      },
    });
    console.log(`  - ${mhs.nama} -> "${project.judul}" (total kuota: ${totalKuota})`);
  }
  console.log('Selesai.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

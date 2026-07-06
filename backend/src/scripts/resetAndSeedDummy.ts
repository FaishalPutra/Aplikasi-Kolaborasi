// Reset total database dev + seed 15 akun dummy "serius" yang mencakup semua aspek
// ketiga modul (People-to-People, People-to-Project, Team Formation), supaya ada
// state nyata untuk demo/testing: sudah terhubung, sudah gabung proyek, sudah gabung
// tim, ada yang masih pending, ada yang sudah keluar, dll.
//
// Jalankan: npx ts-node src/scripts/resetAndSeedDummy.ts
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { treoNorm, TREO_DIMENSIONS, type TreoDimensi } from '../affinityTeam';

const prisma = new PrismaClient();
const PASSWORD = '123456';

function hariLagi(hari: number): Date {
  return new Date(Date.now() + hari * 24 * 60 * 60 * 1000);
}

// Bikin jawaban TREO 3 Likert(1..5) per 6 dimensi. `dominan` dapat nilai tinggi (4-5),
// sisanya nilai sedang/rendah bervariasi — supaya skor norm tiap orang terlihat berbeda-beda.
function buatJawabanTreo(dominan: TreoDimensi[]): Record<TreoDimensi, number[]> {
  const jawaban = {} as Record<TreoDimensi, number[]>;
  for (const d of TREO_DIMENSIONS) {
    jawaban[d] = dominan.includes(d) ? [5, 4, 5] : [3, 2, 3];
  }
  return jawaban;
}

function hitungRawNorm(jawaban: Record<TreoDimensi, number[]>) {
  const raw = {} as Record<TreoDimensi, number>;
  const norm = {} as Record<TreoDimensi, number>;
  for (const d of TREO_DIMENSIONS) {
    const arr = jawaban[d];
    const rerata = arr.reduce((a, b) => a + b, 0) / arr.length;
    raw[d] = rerata;
    norm[d] = treoNorm(rerata);
  }
  return { raw, norm };
}

interface ProfilInput {
  skill: string[];
  pengalaman: number;
  minatTag: string[];
  gayaKerja: string;
  preferensiPeran: string;
  ketersediaanWaktu: string[];
}

interface Persona {
  key: string; // dipakai untuk referensi silang antar-relasi di script ini saja
  nama: string;
  email: string;
  institusi: string;
  jurusan: string;
  angkatan: number;
  bio: string;
  kontak: string;
  kontakJenis: string;
  profil?: ProfilInput;
  treoDominan?: TreoDimensi[];
}

const personas: Persona[] = [
  {
    key: 'bintang', nama: 'Bintang Pratama Wijaya', email: 'bintang.pratama@dummy.test',
    institusi: 'Institut Teknologi Bandung', jurusan: 'Informatika', angkatan: 2022,
    bio: 'Backend developer yang suka membangun sistem dari nol. Pernah jadi ketua tim di 2 hackathon nasional.',
    kontak: '081234500001', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'SQL', 'Analisis Data'], pengalaman: 3, minatTag: ['AI', 'Data Science'], gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Senin malam', 'Rabu sore'] },
    treoDominan: ['organizer', 'doer'],
  },
  {
    key: 'citra', nama: 'Citra Ayu Lestari', email: 'citra.ayu@dummy.test',
    institusi: 'Universitas Indonesia', jurusan: 'Desain Komunikasi Visual', angkatan: 2022,
    bio: 'UI/UX designer, senang riset pengguna sebelum mulai desain. Portofolio fokus ke produk edukasi.',
    kontak: '081234500002', kontakJenis: 'LINE',
    profil: { skill: ['Figma', 'UI Design'], pengalaman: 2, minatTag: ['Desain', 'UI/UX'], gayaKerja: 'Fleksibel', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Selasa sore', 'Sabtu pagi'] },
    treoDominan: ['innovator', 'connector'],
  },
  {
    key: 'dimas', nama: 'Dimas Aditya Nugraha', email: 'dimas.aditya@dummy.test',
    institusi: 'Institut Pertanian Bogor', jurusan: 'Statistika', angkatan: 2021,
    bio: 'Data scientist dengan minat besar di pemodelan prediktif dan visualisasi data.',
    kontak: '081234500003', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'SQL', 'Analisis Data'], pengalaman: 3, minatTag: ['Data Science', 'AI'], gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Kamis malam'] },
    treoDominan: ['doer', 'challenger'],
  },
  {
    key: 'elena', nama: 'Elena Putri Maharani', email: 'elena.putri@dummy.test',
    institusi: 'Universitas Gadjah Mada', jurusan: 'Sistem Informasi', angkatan: 2023,
    bio: 'Frontend developer, lagi belajar Flutter buat side-project sendiri.',
    kontak: '081234500004', kontakJenis: 'WHATSAPP',
    profil: { skill: ['JavaScript', 'Flutter'], pengalaman: 2, minatTag: ['Pengembangan Web', 'Pengembangan Mobile'], gayaKerja: 'Fleksibel', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Jumat sore', 'Minggu malam'] },
    treoDominan: ['innovator'],
  },
  {
    key: 'fajar', nama: 'Fajar Nugroho Santoso', email: 'fajar.nugroho@dummy.test',
    institusi: 'Universitas Diponegoro', jurusan: 'Teknik Informatika', angkatan: 2021,
    bio: 'Suka ngulik web development, terutama sisi backend dan database.',
    kontak: '081234500005', kontakJenis: 'WHATSAPP',
    profil: { skill: ['JavaScript', 'SQL'], pengalaman: 2, minatTag: ['Pengembangan Web'], gayaKerja: 'Terstruktur', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Senin malam'] },
    treoDominan: ['teamBuilder'],
  },
  {
    key: 'gita', nama: 'Gita Amelia Ramadhani', email: 'gita.amelia@dummy.test',
    institusi: 'Universitas Padjadjaran', jurusan: 'Manajemen', angkatan: 2022,
    bio: 'Suka mengelola proyek dari perencanaan sampai eksekusi. Aktif di organisasi kewirausahaan kampus.',
    kontak: '081234500006', kontakJenis: 'LINKEDIN',
    profil: { skill: ['Manajemen Proyek', 'Public Speaking'], pengalaman: 3, minatTag: ['Kewirausahaan'], gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Rabu sore', 'Sabtu pagi'] },
    treoDominan: ['organizer', 'teamBuilder'],
  },
  {
    key: 'hendra', nama: 'Hendra Setiawan Putra', email: 'hendra.setiawan@dummy.test',
    institusi: 'Telkom University', jurusan: 'Ilmu Komputer', angkatan: 2023,
    bio: 'Mobile developer pemula, sedang aktif belajar Flutter lewat proyek kampus.',
    kontak: '081234500007', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Flutter', 'JavaScript'], pengalaman: 1, minatTag: ['Pengembangan Mobile'], gayaKerja: 'Fleksibel', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Selasa sore'] },
    treoDominan: ['connector'],
  },
  {
    key: 'indah', nama: 'Indah Permatasari', email: 'indah.permata@dummy.test',
    institusi: 'Universitas Airlangga', jurusan: 'Sastra Inggris', angkatan: 2022,
    bio: 'Penulis konten dan suka riset pasar, sering bantu tim kewirausahaan bikin copy.',
    kontak: '081234500008', kontakJenis: 'LINE',
    profil: { skill: ['Penulisan', 'Copywriting'], pengalaman: 2, minatTag: ['Kewirausahaan', 'Riset'], gayaKerja: 'Fleksibel', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Minggu malam'] },
    treoDominan: ['challenger'],
  },
  {
    key: 'joko', nama: 'Joko Susilo Wibowo', email: 'joko.susilo@dummy.test',
    institusi: 'Institut Teknologi Sepuluh Nopember', jurusan: 'Teknik Informatika', angkatan: 2020,
    bio: 'Full-stack developer, paling senang kalau dikasih masalah teknis yang kompleks.',
    kontak: '081234500009', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'JavaScript', 'SQL'], pengalaman: 3, minatTag: ['Pengembangan Web', 'AI'], gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Kamis malam', 'Jumat sore'] },
    treoDominan: ['doer'],
  },
  {
    key: 'kirana', nama: 'Kirana Dewi Anggraeni', email: 'kirana.dewi@dummy.test',
    institusi: 'Institut Seni Indonesia', jurusan: 'Desain Komunikasi Visual', angkatan: 2023,
    bio: 'Baru mulai serius di UI/UX, suka riset pengguna kecil-kecilan buat validasi desain.',
    kontak: '081234500010', kontakJenis: 'LINE',
    profil: { skill: ['Figma', 'UI Design', 'Riset Pengguna'], pengalaman: 1, minatTag: ['UI/UX', 'Desain'], gayaKerja: 'Fleksibel', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Sabtu pagi'] },
    treoDominan: ['innovator', 'connector'],
  },
  {
    key: 'lukman', nama: 'Lukman Hakim Nasution', email: 'lukman.hakim@dummy.test',
    institusi: 'Universitas Sumatera Utara', jurusan: 'Sistem Informasi', angkatan: 2021,
    bio: 'Suka kerja dengan data, dari pembersihan sampai analisis akhir.',
    kontak: '081234500011', kontakJenis: 'WHATSAPP',
    profil: { skill: ['SQL', 'Analisis Data'], pengalaman: 2, minatTag: ['Data Science'], gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Senin malam', 'Selasa sore'] },
    treoDominan: ['challenger'],
  },
  {
    key: 'mira', nama: 'Mira Anggraini Putri', email: 'mira.anggraini@dummy.test',
    institusi: 'Universitas Brawijaya', jurusan: 'Manajemen', angkatan: 2023,
    bio: 'Baru daftar, masih menjajaki fitur aplikasi ini.',
    kontak: '081234500012', kontakJenis: 'WHATSAPP',
    // sengaja TIDAK diisi profil & TREO — mensimulasikan user baru daftar yang belum
    // melengkapi profil (edge case: skor affinity tidak muncul, tapi tetap bisa mendaftar).
  },
  {
    key: 'naufal', nama: 'Naufal Rizky Ramadhan', email: 'naufal.rizky@dummy.test',
    institusi: 'Institut Teknologi Bandung', jurusan: 'Teknik Informatika', angkatan: 2022,
    bio: 'Mobile developer dengan ketertarikan ke AI, senang eksplorasi teknologi baru.',
    kontak: '081234500013', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'Flutter'], pengalaman: 3, minatTag: ['Pengembangan Mobile', 'AI'], gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Rabu sore'] },
    treoDominan: ['organizer'],
  },
  {
    key: 'oktavia', nama: 'Oktavia Sari Dewanti', email: 'oktavia.sari@dummy.test',
    institusi: 'Universitas Padjadjaran', jurusan: 'Manajemen Bisnis', angkatan: 2021,
    bio: 'Aktif di kompetisi bisnis mahasiswa, suka menyusun strategi dan presentasi.',
    kontak: '081234500014', kontakJenis: 'LINKEDIN',
    profil: { skill: ['Manajemen Proyek', 'Public Speaking'], pengalaman: 3, minatTag: ['Kewirausahaan'], gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Jumat sore', 'Minggu malam'] },
    treoDominan: ['teamBuilder', 'organizer'],
  },
  {
    key: 'putra', nama: 'Putra Wijaya Kusuma', email: 'putra.wijaya@dummy.test',
    institusi: 'Universitas Gadjah Mada', jurusan: 'Ilmu Komputer', angkatan: 2022,
    bio: 'Generalis yang suka bantu di berbagai peran, dari teknis sampai koordinasi kecil.',
    kontak: '081234500015', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'JavaScript'], pengalaman: 2, minatTag: ['AI', 'Pengembangan Web'], gayaKerja: 'Fleksibel', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Selasa sore', 'Kamis malam'] },
    treoDominan: ['connector', 'doer'],
  },
];

async function main() {
  console.log('Menghapus semua data lama...');
  await prisma.diskusiTim.deleteMany();
  await prisma.teamFormationScore.deleteMany();
  await prisma.affinityScoreRoleTeam.deleteMany();
  await prisma.pendaftaranAnggota.deleteMany();
  await prisma.roleLobiTim.deleteMany();
  await prisma.studentLobby.deleteMany();
  await prisma.lomba.deleteMany();
  await prisma.affinityScoreProject.deleteMany();
  await prisma.pendaftaranProject.deleteMany();
  await prisma.kebutuhanRole.deleteMany();
  await prisma.project.deleteMany();
  await prisma.connection.deleteMany();
  await prisma.connectRequest.deleteMany();
  await prisma.expressInterest.deleteMany();
  await prisma.savedProfile.deleteMany();
  await prisma.affinityScorePeople.deleteMany();
  await prisma.treoProfil.deleteMany();
  await prisma.profil.deleteMany();
  await prisma.mahasiswa.deleteMany();
  console.log('Selesai menghapus data lama.\n');

  console.log('Membuat 15 akun dummy...');
  const hash = await bcrypt.hash(PASSWORD, 10);
  const id: Record<string, string> = {};

  for (const p of personas) {
    const mhs = await prisma.mahasiswa.create({
      data: {
        nama: p.nama,
        email: p.email,
        password: hash,
        institusi: p.institusi,
        jurusan: p.jurusan,
        angkatan: p.angkatan,
        bio: p.bio,
        kontak: p.kontak,
        kontakJenis: p.kontakJenis,
      },
    });
    id[p.key] = mhs.id;

    if (p.profil) {
      await prisma.profil.create({
        data: {
          mahasiswaId: mhs.id,
          skill: p.profil.skill,
          pengalaman: p.profil.pengalaman,
          minatTag: p.profil.minatTag,
          gayaKerja: p.profil.gayaKerja,
          preferensiPeran: p.profil.preferensiPeran,
          ketersediaanWaktu: p.profil.ketersediaanWaktu,
          lengkap: true,
        },
      });
    }

    if (p.treoDominan) {
      const jawaban = buatJawabanTreo(p.treoDominan);
      const { raw, norm } = hitungRawNorm(jawaban);
      await prisma.treoProfil.create({
        data: {
          mahasiswaId: mhs.id,
          organizerRaw: raw.organizer, doerRaw: raw.doer, challengerRaw: raw.challenger,
          innovatorRaw: raw.innovator, teamBuilderRaw: raw.teamBuilder, connectorRaw: raw.connector,
          organizerNorm: norm.organizer, doerNorm: norm.doer, challengerNorm: norm.challenger,
          innovatorNorm: norm.innovator, teamBuilderNorm: norm.teamBuilder, connectorNorm: norm.connector,
          jawaban: jawaban as any,
          diisi: true,
        },
      });
    }
    console.log(`  - ${p.nama} (${p.email})`);
  }
  console.log('Selesai membuat akun.\n');

  console.log('Membuat data People-to-People (koneksi, minat, disimpan)...');
  // Koneksi mutual via "Hubungkan" (connect request diterima kedua arah)
  await prisma.connectRequest.create({ data: { senderId: id.bintang, receiverId: id.elena, status: 'ACCEPTED' } });
  await prisma.connection.create({ data: { mahasiswaAId: id.bintang, mahasiswaBId: id.elena, asal: 'REQUEST' } });

  // Koneksi otomatis via saling tertarik ("Tertarik" dua arah)
  await prisma.expressInterest.create({ data: { senderId: id.citra, receiverId: id.hendra } });
  await prisma.expressInterest.create({ data: { senderId: id.hendra, receiverId: id.citra } });
  await prisma.connection.create({ data: { mahasiswaAId: id.citra, mahasiswaBId: id.hendra, asal: 'INTEREST' } });

  // Permintaan koneksi masih PENDING (belum diputuskan)
  await prisma.connectRequest.create({ data: { senderId: id.joko, receiverId: id.kirana, status: 'PENDING' } });
  await prisma.connectRequest.create({ data: { senderId: id.naufal, receiverId: id.oktavia, status: 'PENDING' } });

  // "Menyukai Saya" satu arah (belum saling tertarik) — Gita & Indah jadi populer
  await prisma.expressInterest.create({ data: { senderId: id.putra, receiverId: id.indah } });
  await prisma.expressInterest.create({ data: { senderId: id.fajar, receiverId: id.gita } });
  await prisma.expressInterest.create({ data: { senderId: id.lukman, receiverId: id.gita } });

  // Profil disimpan
  await prisma.savedProfile.create({ data: { ownerId: id.bintang, targetId: id.gita } });
  await prisma.savedProfile.create({ data: { ownerId: id.elena, targetId: id.kirana } });
  await prisma.savedProfile.create({ data: { ownerId: id.dimas, targetId: id.naufal } });
  console.log('Selesai People-to-People.\n');

  console.log('Membuat data People-to-Project (proyek, kebutuhan role, pendaftaran)...');
  const proyek1 = await prisma.project.create({
    data: {
      judul: 'Platform Edukasi Daring untuk UMKM',
      deskripsi: 'Membangun platform pembelajaran daring sederhana untuk membantu pelaku UMKM naik kelas secara digital.',
      timeline: '5 hari lagi', durasi: '3 bulan', format: 'Hybrid',
      jadwalSlot: ['Jumat sore', 'Minggu malam'],
      pengalamanReq: 2, minatTag: ['Pengembangan Web', 'Kewirausahaan'], gayaKerja: 'Fleksibel',
      pembuatId: id.elena,
      roles: {
        create: [
          { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1, sisaKuota: 0 },
          { namaRole: 'Contributor/Executor', skillDicari: ['JavaScript', 'Flutter'], kuota: 2, sisaKuota: 0 },
          { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 1, sisaKuota: 0 },
        ],
      },
    },
    include: { roles: true },
  });
  const roleLeader1 = proyek1.roles.find((r) => r.namaRole === 'Leader/Coordinator')!;
  const roleKontrib1 = proyek1.roles.find((r) => r.namaRole === 'Contributor/Executor')!;
  const roleSupport1 = proyek1.roles.find((r) => r.namaRole === 'Supporter/Facilitator')!;

  // Pembuat proyek otomatis jadi anggota (ACCEPTED) di role Leader
  await prisma.pendaftaranProject.create({ data: { mahasiswaId: id.elena, projectId: proyek1.id, roleId: roleLeader1.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranProject.create({ data: { mahasiswaId: id.naufal, projectId: proyek1.id, roleId: roleKontrib1.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranProject.create({ data: { mahasiswaId: id.putra, projectId: proyek1.id, roleId: roleSupport1.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranProject.create({ data: { mahasiswaId: id.fajar, projectId: proyek1.id, roleId: roleKontrib1.id, status: 'PENDING' } });

  const proyek2 = await prisma.project.create({
    data: {
      judul: 'Riset Perilaku Pengguna Aplikasi Mobile',
      deskripsi: 'Riset kualitatif untuk memahami kebiasaan pengguna aplikasi mobile lokal, dipakai sebagai dasar redesain UX.',
      timeline: '12 hari lagi', durasi: '2 bulan', format: 'Online',
      jadwalSlot: ['Sabtu pagi'],
      pengalamanReq: 1, minatTag: ['Riset', 'UI/UX'], gayaKerja: 'Terstruktur',
      pembuatId: id.kirana,
      roles: {
        create: [
          { namaRole: 'Leader/Coordinator', skillDicari: ['Riset Pengguna'], kuota: 1, sisaKuota: 0 },
          { namaRole: 'Contributor/Executor', skillDicari: ['Analisis Data'], kuota: 2, sisaKuota: 1 },
        ],
      },
    },
    include: { roles: true },
  });
  const roleLeader2 = proyek2.roles.find((r) => r.namaRole === 'Leader/Coordinator')!;
  const roleKontrib2 = proyek2.roles.find((r) => r.namaRole === 'Contributor/Executor')!;

  await prisma.pendaftaranProject.create({ data: { mahasiswaId: id.kirana, projectId: proyek2.id, roleId: roleLeader2.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranProject.create({ data: { mahasiswaId: id.indah, projectId: proyek2.id, roleId: roleKontrib2.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranProject.create({ data: { mahasiswaId: id.mira, projectId: proyek2.id, roleId: roleKontrib2.id, status: 'PENDING' } });
  console.log('Selesai People-to-Project.\n');

  console.log('Membuat data Team Formation (lomba, lobi/tim, pendaftaran anggota)...');
  const lomba1 = await prisma.lomba.create({
    data: {
      judul: 'Hackathon Inovasi Digital 2026',
      deskripsi: 'Kompetisi membangun solusi digital inovatif dalam 48 jam untuk berbagai isu sosial.',
      kategoriLomba: ['AI', 'Pengembangan Web'],
      maxAnggotaTim: 4, minAnggotaTim: 2,
      tenggat: hariLagi(20),
      penyelenggara: 'Kementerian Komunikasi dan Digital',
      hadiah: 'Rp50 juta', cakupan: 'Nasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
      pengusulId: id.bintang,
    },
  });
  const lomba2 = await prisma.lomba.create({
    data: {
      judul: 'Kompetisi Bisnis Mahasiswa Nusantara',
      deskripsi: 'Kompetisi rencana bisnis untuk mahasiswa se-Indonesia, dari ide sampai purwarupa.',
      kategoriLomba: ['Kewirausahaan'],
      maxAnggotaTim: 3, minAnggotaTim: 2,
      tenggat: hariLagi(30),
      penyelenggara: 'Bank Mandiri', hadiah: 'Rp75 juta', cakupan: 'Nasional',
      jenisBiaya: 'BERBAYAR', nominalBiaya: 'Rp100.000/tim',
      pengusulId: id.gita,
    },
  });

  // Tim A — dikoordinatori Bintang, di bawah Lomba 1
  const timA = await prisma.studentLobby.create({
    data: {
      lombaId: lomba1.id, judul: 'Tim Elang Data', deskripsi: 'Fokus ke solusi berbasis data untuk isu pendidikan.',
      koordinatorId: id.bintang, status: 'OPEN',
      roles: {
        create: [
          { namaRole: 'Backend Developer', kuota: 2, sisaKuota: 0 },
          { namaRole: 'Data Scientist', kuota: 1, sisaKuota: 0 },
          { namaRole: 'UI/UX Designer', kuota: 1, sisaKuota: 0 },
        ],
      },
    },
    include: { roles: true },
  });
  const roleBackendA = timA.roles.find((r) => r.namaRole === 'Backend Developer')!;
  const roleDataA = timA.roles.find((r) => r.namaRole === 'Data Scientist')!;
  const roleUiA = timA.roles.find((r) => r.namaRole === 'UI/UX Designer')!;

  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.bintang, lobiId: timA.id, roleId: roleBackendA.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.dimas, lobiId: timA.id, roleId: roleDataA.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.kirana, lobiId: timA.id, roleId: roleUiA.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.hendra, lobiId: timA.id, roleId: roleBackendA.id, status: 'PENDING' } });
  await prisma.diskusiTim.create({ data: { lobiId: timA.id, mahasiswaId: id.bintang, pesan: 'Halo tim, yuk mulai diskusi ide untuk hackathon ini!' } });
  await prisma.diskusiTim.create({ data: { lobiId: timA.id, mahasiswaId: id.dimas, pesan: 'Aku sudah siapkan beberapa dataset kandidat, nanti kita bahas ya.' } });

  // Tim B — dikoordinatori Gita, di bawah Lomba 2
  const timB = await prisma.studentLobby.create({
    data: {
      lombaId: lomba2.id, judul: 'Tim Wirausaha Muda', deskripsi: 'Rencana bisnis di sektor F&B berbasis komunitas lokal.',
      koordinatorId: id.gita, status: 'OPEN',
      roles: {
        create: [
          { namaRole: 'Project Manager', kuota: 1, sisaKuota: 0 },
          { namaRole: 'Content/Business Analyst', kuota: 2, sisaKuota: 1 },
        ],
      },
    },
    include: { roles: true },
  });
  const rolePmB = timB.roles.find((r) => r.namaRole === 'Project Manager')!;
  const roleBaB = timB.roles.find((r) => r.namaRole === 'Content/Business Analyst')!;

  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.gita, lobiId: timB.id, roleId: rolePmB.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.indah, lobiId: timB.id, roleId: roleBaB.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.oktavia, lobiId: timB.id, roleId: roleBaB.id, status: 'PENDING' } });

  // Tim C — dikoordinatori Joko, dipakai untuk mensimulasikan anggota yang sudah KELUAR
  const timC = await prisma.studentLobby.create({
    data: {
      lombaId: lomba1.id, judul: 'Tim Cerdas Nusantara', deskripsi: 'Solusi AI untuk deteksi dini masalah lingkungan.',
      koordinatorId: id.joko, status: 'OPEN',
      roles: { create: [{ namaRole: 'Backend Developer', kuota: 2, sisaKuota: 1 }] },
    },
    include: { roles: true },
  });
  const roleBackendC = timC.roles[0];
  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.joko, lobiId: timC.id, roleId: roleBackendC.id, status: 'ACCEPTED' } });
  await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id.lukman, lobiId: timC.id, roleId: roleBackendC.id, status: 'LEFT' } });

  console.log('Selesai Team Formation.\n');

  console.log('✅ Reset & seed selesai. Semua akun dummy pakai password: 123456');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

// Reset total database + seed 30 akun dummy "berkualitas" yang mencakup semua aspek
// ketiga modul (People-to-People, People-to-Project, Team Formation), supaya ada
// state nyata untuk demo/testing: sudah terhubung, sudah gabung proyek, sudah gabung
// tim, ada yang masih pending, ada yang sudah keluar, dll. Data lomba dibuat merepresentasikan
// ajang mahasiswa nyata di Indonesia/internasional (GEMASTIK, PIMNAS, KBMI, dst.) supaya
// terasa realistis saat demo.
//
// Jalankan: DATABASE_URL="..." npx ts-node src/scripts/resetAndSeedDummy.ts
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
  {
    key: 'rangga', nama: 'Rangga Saputra Wijaya', email: 'rangga.saputra@dummy.test',
    institusi: 'Universitas Bina Nusantara', jurusan: 'Teknik Informatika', angkatan: 2022,
    bio: 'Teliti dan suka memastikan sistem bebas bug sebelum rilis, mulai serius belajar analisis data.',
    kontak: '081234500016', kontakJenis: 'WHATSAPP',
    profil: { skill: ['SQL', 'Analisis Data'], pengalaman: 2, minatTag: ['Pengembangan Web'], gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Senin siang', 'Kamis malam'] },
    treoDominan: ['challenger', 'doer'],
  },
  {
    key: 'salsa', nama: 'Salsabila Nur Azizah', email: 'salsabila.nur@dummy.test',
    institusi: 'Universitas Negeri Yogyakarta', jurusan: 'Pendidikan Teknik Informatika', angkatan: 2023,
    bio: 'Content writer yang senang menulis untuk produk edukasi, aktif di komunitas menulis kampus.',
    kontak: '081234500017', kontakJenis: 'LINE',
    profil: { skill: ['Penulisan', 'Copywriting'], pengalaman: 1, minatTag: ['Riset', 'Kewirausahaan'], gayaKerja: 'Fleksibel', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Rabu malam'] },
    treoDominan: ['connector'],
  },
  {
    key: 'teguh', nama: 'Teguh Firmansyah', email: 'teguh.firmansyah@dummy.test',
    institusi: 'Institut Teknologi Sepuluh Nopember', jurusan: 'Sistem Informasi', angkatan: 2021,
    bio: 'Backend enthusiast yang mulai belajar DevOps, suka memimpin diskusi teknis tim.',
    kontak: '081234500018', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'SQL', 'JavaScript'], pengalaman: 3, minatTag: ['AI', 'Pengembangan Web'], gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Selasa malam', 'Jumat malam'] },
    treoDominan: ['doer', 'organizer'],
  },
  {
    key: 'umi', nama: 'Umi Kalsum Ramadhani', email: 'umi.kalsum@dummy.test',
    institusi: 'Universitas Hasanuddin', jurusan: 'Ilmu Komputer', angkatan: 2022,
    bio: 'Mobile developer yang senang eksplorasi desain antarmuka baru.',
    kontak: '081234500019', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Flutter', 'JavaScript'], pengalaman: 2, minatTag: ['Pengembangan Mobile'], gayaKerja: 'Fleksibel', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Sabtu siang', 'Minggu siang'] },
    treoDominan: ['innovator'],
  },
  {
    key: 'vino', nama: 'Vino Alamsyah Pratama', email: 'vino.alamsyah@dummy.test',
    institusi: 'Universitas Sriwijaya', jurusan: 'Teknik Informatika', angkatan: 2020,
    bio: 'Full-stack developer senior, senang membimbing anggota tim yang lebih junior.',
    kontak: '081234500020', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'JavaScript', 'SQL'], pengalaman: 3, minatTag: ['Data Science', 'AI'], gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Senin malam', 'Rabu malam', 'Jumat sore'] },
    treoDominan: ['organizer', 'challenger'],
  },
  {
    key: 'wulan', nama: 'Wulan Sartika Dewi', email: 'wulan.sartika@dummy.test',
    institusi: 'Universitas Pendidikan Indonesia', jurusan: 'Manajemen', angkatan: 2023,
    bio: 'Suka menyusun rencana bisnis dan menjaga kekompakan tim saat lomba.',
    kontak: '081234500021', kontakJenis: 'LINE',
    profil: { skill: ['Public Speaking', 'Manajemen Proyek'], pengalaman: 1, minatTag: ['Kewirausahaan'], gayaKerja: 'Fleksibel', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Kamis sore'] },
    treoDominan: ['teamBuilder', 'connector'],
  },
  {
    key: 'yusuf', nama: 'Yusuf Ibrahim Al Fatih', email: 'yusuf.ibrahim@dummy.test',
    institusi: 'Universitas Muhammadiyah Yogyakarta', jurusan: 'Informatika', angkatan: 2022,
    bio: 'Suka eksperimen model machine learning kecil-kecilan dan ikut lomba data science.',
    kontak: '081234500022', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'Analisis Data'], pengalaman: 2, minatTag: ['AI', 'Data Science'], gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Selasa siang', 'Kamis malam'] },
    treoDominan: ['doer', 'innovator'],
  },
  {
    key: 'zahra', nama: 'Zahra Amelia Husna', email: 'zahra.amelia@dummy.test',
    institusi: 'Universitas Diponegoro', jurusan: 'Desain Komunikasi Visual', angkatan: 2023,
    bio: 'Ilustrator dan UI designer, suka membuat desain yang hangat dan personal.',
    kontak: '081234500023', kontakJenis: 'LINE',
    profil: { skill: ['Figma', 'UI Design'], pengalaman: 1, minatTag: ['Desain', 'UI/UX'], gayaKerja: 'Fleksibel', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Sabtu sore'] },
    treoDominan: ['innovator', 'connector'],
  },
  {
    key: 'abimanyu', nama: 'Abimanyu Kusuma Jaya', email: 'abimanyu.kusuma@dummy.test',
    institusi: 'Institut Teknologi Bandung', jurusan: 'Teknik Elektro', angkatan: 2021,
    bio: 'Awalnya di hardware/IoT, sekarang mendalami pengembangan aplikasi berbasis AI.',
    kontak: '081234500024', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Python', 'SQL'], pengalaman: 2, minatTag: ['AI', 'Pengembangan Mobile'], gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Minggu malam'] },
    treoDominan: ['doer'],
  },
  {
    key: 'bella', nama: 'Bella Anastasya Putri', email: 'bella.anastasya@dummy.test',
    institusi: 'Universitas Kristen Petra', jurusan: 'Sistem Informasi', angkatan: 2022,
    bio: 'Product-minded, suka riset kebutuhan pengguna sebelum tim mulai eksekusi.',
    kontak: '081234500025', kontakJenis: 'WHATSAPP',
    profil: { skill: ['Manajemen Proyek', 'Riset Pengguna'], pengalaman: 2, minatTag: ['UI/UX', 'Kewirausahaan'], gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Rabu sore', 'Sabtu pagi'] },
    treoDominan: ['organizer', 'teamBuilder'],
  },
  {
    key: 'cahyo', nama: 'Cahyo Dwi Prasetyo', email: 'cahyo.dwi@dummy.test',
    institusi: 'Universitas Jenderal Soedirman', jurusan: 'Teknik Informatika', angkatan: 2023,
    bio: 'Baru belajar web development dari nol, semangat ikut proyek kolaborasi pertama.',
    kontak: '081234500026', kontakJenis: 'WHATSAPP',
    profil: { skill: ['JavaScript'], pengalaman: 1, minatTag: ['Pengembangan Web'], gayaKerja: 'Fleksibel', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Jumat malam'] },
    treoDominan: ['connector'],
  },
  {
    key: 'della', nama: 'Della Ayu Kirana', email: 'della.ayu@dummy.test',
    institusi: 'Universitas Sebelas Maret', jurusan: 'Statistika', angkatan: 2021,
    bio: 'Data analyst berpengalaman ikut beberapa lomba data science tingkat nasional.',
    kontak: '081234500027', kontakJenis: 'WHATSAPP',
    profil: { skill: ['SQL', 'Analisis Data', 'Python'], pengalaman: 3, minatTag: ['Data Science', 'Riset'], gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Senin sore', 'Rabu sore'] },
    treoDominan: ['challenger', 'doer'],
  },
  {
    key: 'eka', nama: 'Eka Prasetya Nugraha', email: 'eka.prasetya@dummy.test',
    institusi: 'Universitas Andalas', jurusan: 'Sistem Informasi', angkatan: 2022,
    bio: 'Aktivis kewirausahaan kampus, suka menyusun pitch deck dan presentasi bisnis.',
    kontak: '081234500028', kontakJenis: 'LINKEDIN',
    profil: { skill: ['Public Speaking', 'Manajemen Proyek'], pengalaman: 2, minatTag: ['Kewirausahaan'], gayaKerja: 'Fleksibel', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Selasa sore', 'Minggu pagi'] },
    treoDominan: ['organizer'],
  },
  {
    key: 'farah', nama: 'Farah Nabila Zahra', email: 'farah.nabila@dummy.test',
    institusi: 'Universitas Trisakti', jurusan: 'Desain Produk', angkatan: 2023,
    bio: 'Baru mendaftar, masih menjajaki fitur aplikasi ini.',
    kontak: '081234500029', kontakJenis: 'WHATSAPP',
    // sengaja TIDAK diisi profil & TREO juga — edge case kedua utk user yang belum lengkapi profil.
  },
  {
    key: 'galih', nama: 'Galih Mahardika Putra', email: 'galih.mahardika@dummy.test',
    institusi: 'Politeknik Elektronika Negeri Surabaya', jurusan: 'Teknik Informatika', angkatan: 2021,
    bio: 'Suka detail dan dokumentasi rapi, sering jadi QA dadakan di tim proyek kampus.',
    kontak: '081234500030', kontakJenis: 'WHATSAPP',
    profil: { skill: ['SQL', 'JavaScript', 'Analisis Data'], pengalaman: 2, minatTag: ['Pengembangan Web', 'Data Science'], gayaKerja: 'Terstruktur', preferensiPeran: 'Supporter/Facilitator', ketersediaanWaktu: ['Kamis sore', 'Sabtu malam'] },
    treoDominan: ['challenger', 'connector'],
  },
];

// ---------- People-to-Project: 20 proyek dummy, tersebar ke berbagai persona ----------
interface RoleInput {
  namaRole: string; // Leader/Coordinator | Contributor/Executor | Supporter/Facilitator
  skillDicari: string[];
  kuota: number;
}
interface ProjectSeed {
  pembuat: string; // key persona
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
  // pelamar tambahan (di luar pembuat) — key persona + index role (0-based) + status
  pelamar?: { key: string; roleIndex: number; status: 'ACCEPTED' | 'PENDING' }[];
}

const projectSeeds: ProjectSeed[] = [
  {
    pembuat: 'elena', judul: 'Platform Edukasi Daring untuk UMKM',
    deskripsi: 'Membangun platform pembelajaran daring sederhana untuk membantu pelaku UMKM naik kelas secara digital.',
    timeline: '5 hari lagi', durasi: '3 bulan', format: 'Hybrid', jadwalSlot: ['Jumat sore', 'Minggu malam'],
    pengalamanReq: 2, minatTag: ['Pengembangan Web', 'Kewirausahaan'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['JavaScript', 'Flutter'], kuota: 2 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 1 },
    ],
    pelamar: [
      { key: 'naufal', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'putra', roleIndex: 2, status: 'ACCEPTED' },
      { key: 'fajar', roleIndex: 1, status: 'PENDING' },
    ],
  },
  {
    pembuat: 'kirana', judul: 'Riset Perilaku Pengguna Aplikasi Mobile',
    deskripsi: 'Riset kualitatif untuk memahami kebiasaan pengguna aplikasi mobile lokal, dipakai sebagai dasar redesain UX.',
    timeline: '12 hari lagi', durasi: '2 bulan', format: 'Online', jadwalSlot: ['Sabtu pagi'],
    pengalamanReq: 1, minatTag: ['Riset', 'UI/UX'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Riset Pengguna'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Analisis Data'], kuota: 2 },
    ],
    pelamar: [
      { key: 'indah', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'mira', roleIndex: 1, status: 'PENDING' },
    ],
  },
  {
    pembuat: 'bintang', judul: 'Sistem Rekomendasi Beasiswa Berbasis AI',
    deskripsi: 'Membangun sistem yang mencocokkan mahasiswa dengan program beasiswa yang relevan berdasarkan profil akademik.',
    timeline: '7 hari lagi', durasi: '4 bulan', format: 'Hybrid', jadwalSlot: ['Senin malam', 'Rabu sore'],
    pengalamanReq: 2, minatTag: ['AI', 'Data Science'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'SQL'], kuota: 2 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Analisis Data'], kuota: 1 },
    ],
    pelamar: [
      { key: 'yusuf', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'della', roleIndex: 2, status: 'ACCEPTED' },
    ],
  },
  {
    pembuat: 'citra', judul: 'Redesain Aplikasi Layanan Kampus',
    deskripsi: 'Merancang ulang UI/UX aplikasi layanan akademik kampus supaya lebih ramah pengguna.',
    timeline: '10 hari lagi', durasi: '2 bulan', format: 'Online', jadwalSlot: ['Selasa sore', 'Sabtu pagi'],
    pengalamanReq: 1, minatTag: ['Desain', 'UI/UX'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['UI Design'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Figma', 'Riset Pengguna'], kuota: 2 },
    ],
    pelamar: [{ key: 'zahra', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    pembuat: 'dimas', judul: 'Dashboard Analitik Data Akademik',
    deskripsi: 'Menyusun dashboard visualisasi data nilai & kehadiran mahasiswa untuk membantu keputusan akademik.',
    timeline: '14 hari lagi', durasi: '3 bulan', format: 'Hybrid', jadwalSlot: ['Kamis malam'],
    pengalamanReq: 2, minatTag: ['Data Science', 'AI'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Analisis Data'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'SQL'], kuota: 2 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 1 },
    ],
    pelamar: [{ key: 'lukman', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    pembuat: 'fajar', judul: 'Website Marketplace UMKM Lokal',
    deskripsi: 'Membangun website marketplace sederhana untuk membantu UMKM di sekitar kampus berjualan daring.',
    timeline: '9 hari lagi', durasi: '3 bulan', format: 'Online', jadwalSlot: ['Senin malam'],
    pengalamanReq: 2, minatTag: ['Pengembangan Web'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['JavaScript'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['JavaScript', 'SQL'], kuota: 3 },
    ],
    pelamar: [
      { key: 'cahyo', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'teguh', roleIndex: 1, status: 'PENDING' },
    ],
  },
  {
    pembuat: 'gita', judul: 'Inkubator Bisnis Mahasiswa',
    deskripsi: 'Program pendampingan rintisan usaha mahasiswa dari ide sampai purwarupa siap pitching.',
    timeline: '20 hari lagi', durasi: '5 bulan', format: 'Hybrid', jadwalSlot: ['Rabu sore', 'Sabtu pagi'],
    pengalamanReq: 2, minatTag: ['Kewirausahaan'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Public Speaking'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 2 },
    ],
    pelamar: [
      { key: 'eka', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'wulan', roleIndex: 2, status: 'ACCEPTED' },
      { key: 'salsa', roleIndex: 2, status: 'PENDING' },
    ],
  },
  {
    pembuat: 'hendra', judul: 'Aplikasi Pengingat Tugas Kuliah',
    deskripsi: 'Aplikasi mobile sederhana untuk membantu mahasiswa mengelola deadline tugas dan jadwal kuliah.',
    timeline: '6 hari lagi', durasi: '2 bulan', format: 'Online', jadwalSlot: ['Selasa sore'],
    pengalamanReq: 1, minatTag: ['Pengembangan Mobile'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Flutter'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Flutter', 'JavaScript'], kuota: 2 },
    ],
    pelamar: [{ key: 'umi', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    pembuat: 'indah', judul: 'Konten Edukasi Literasi Digital',
    deskripsi: 'Membuat rangkaian konten edukasi seputar literasi digital untuk pelajar dan masyarakat umum.',
    timeline: '11 hari lagi', durasi: '2 bulan', format: 'Online', jadwalSlot: ['Minggu malam'],
    pengalamanReq: 1, minatTag: ['Kewirausahaan', 'Riset'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Penulisan'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Copywriting'], kuota: 2 },
    ],
    pelamar: [{ key: 'salsa', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    pembuat: 'joko', judul: 'Platform Manajemen Organisasi Kampus',
    deskripsi: 'Sistem untuk membantu organisasi mahasiswa mengelola anggota, agenda, dan keuangan secara digital.',
    timeline: '15 hari lagi', durasi: '4 bulan', format: 'Hybrid', jadwalSlot: ['Kamis malam', 'Jumat sore'],
    pengalamanReq: 2, minatTag: ['Pengembangan Web', 'AI'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['JavaScript'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'JavaScript', 'SQL'], kuota: 3 },
    ],
    pelamar: [
      { key: 'teguh', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'galih', roleIndex: 1, status: 'ACCEPTED' },
    ],
  },
  {
    pembuat: 'lukman', judul: 'Riset Prediksi Kelulusan Mahasiswa',
    deskripsi: 'Riset data historis akademik untuk memprediksi risiko keterlambatan kelulusan mahasiswa.',
    timeline: '13 hari lagi', durasi: '3 bulan', format: 'Online', jadwalSlot: ['Senin malam', 'Selasa sore'],
    pengalamanReq: 2, minatTag: ['Data Science'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Analisis Data'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['SQL', 'Analisis Data'], kuota: 2 },
    ],
    pelamar: [{ key: 'della', roleIndex: 1, status: 'PENDING' }],
  },
  {
    pembuat: 'naufal', judul: 'Chatbot Konsultasi Akademik',
    deskripsi: 'Chatbot berbasis AI untuk membantu mahasiswa mendapatkan info akademik dengan cepat lewat aplikasi mobile.',
    timeline: '16 hari lagi', durasi: '3 bulan', format: 'Hybrid', jadwalSlot: ['Rabu sore'],
    pengalamanReq: 2, minatTag: ['Pengembangan Mobile', 'AI'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Flutter'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'Flutter'], kuota: 2 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['UI Design'], kuota: 1 },
    ],
    pelamar: [
      { key: 'abimanyu', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'zahra', roleIndex: 2, status: 'PENDING' },
    ],
  },
  {
    pembuat: 'oktavia', judul: 'Kompetisi Ide Bisnis Mahasiswa',
    deskripsi: 'Menyelenggarakan kompetisi internal ide bisnis mahasiswa dari tahap ide sampai presentasi ke investor kampus.',
    timeline: '18 hari lagi', durasi: '2 bulan', format: 'Onsite', jadwalSlot: ['Jumat sore', 'Minggu malam'],
    pengalamanReq: 2, minatTag: ['Kewirausahaan'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Public Speaking'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Penulisan'], kuota: 1 },
    ],
  },
  {
    pembuat: 'putra', judul: 'Portal Informasi Lowongan Magang Mahasiswa',
    deskripsi: 'Portal agregator info lowongan magang dari berbagai sumber, disesuaikan dengan minat jurusan mahasiswa.',
    timeline: '12 hari lagi', durasi: '3 bulan', format: 'Online', jadwalSlot: ['Selasa sore', 'Kamis malam'],
    pengalamanReq: 1, minatTag: ['AI', 'Pengembangan Web'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['JavaScript'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'JavaScript'], kuota: 2 },
    ],
  },
  {
    pembuat: 'vino', judul: 'Optimalisasi Query Sistem Akademik',
    deskripsi: 'Audit dan optimasi performa query database sistem akademik kampus yang mulai melambat.',
    timeline: '8 hari lagi', durasi: '2 bulan', format: 'Hybrid', jadwalSlot: ['Senin malam', 'Rabu malam'],
    pengalamanReq: 3, minatTag: ['Data Science'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['SQL'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['SQL', 'Python'], kuota: 2 },
    ],
    pelamar: [{ key: 'rangga', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    pembuat: 'bella', judul: 'Riset Kepuasan Pengguna Layanan Kampus Digital',
    deskripsi: 'Riset pengalaman mahasiswa memakai layanan digital kampus, hasilnya dipakai untuk rekomendasi perbaikan.',
    timeline: '10 hari lagi', durasi: '2 bulan', format: 'Online', jadwalSlot: ['Rabu sore', 'Sabtu pagi'],
    pengalamanReq: 1, minatTag: ['UI/UX', 'Riset'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Riset Pengguna'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Figma'], kuota: 1 },
    ],
    pelamar: [{ key: 'kirana', roleIndex: 1, status: 'PENDING' }],
  },
  {
    pembuat: 'teguh', judul: 'Automasi Deployment untuk Proyek Kampus',
    deskripsi: 'Menyusun pipeline CI/CD sederhana supaya proyek-proyek tim kampus lebih mudah dirilis.',
    timeline: '9 hari lagi', durasi: '2 bulan', format: 'Online', jadwalSlot: ['Selasa malam'],
    pengalamanReq: 2, minatTag: ['Pengembangan Web', 'AI'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Python'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['JavaScript', 'SQL'], kuota: 2 },
    ],
    pelamar: [{ key: 'joko', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    pembuat: 'della', judul: 'Analisis Tren Harga Komoditas Pangan',
    deskripsi: 'Riset dan visualisasi data harga pangan untuk membantu edukasi publik soal inflasi bahan pokok.',
    timeline: '15 hari lagi', durasi: '3 bulan', format: 'Online', jadwalSlot: ['Senin sore', 'Rabu sore'],
    pengalamanReq: 2, minatTag: ['Data Science', 'Riset'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Analisis Data'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['Python', 'SQL'], kuota: 2 },
    ],
    pelamar: [{ key: 'yusuf', roleIndex: 1, status: 'PENDING' }],
  },
  {
    pembuat: 'eka', judul: 'Kampanye Sosial Digital untuk UMKM Difabel',
    deskripsi: 'Menyusun strategi dan materi kampanye digital untuk mempromosikan UMKM yang dikelola penyandang difabel.',
    timeline: '17 hari lagi', durasi: '2 bulan', format: 'Hybrid', jadwalSlot: ['Selasa sore', 'Minggu pagi'],
    pengalamanReq: 1, minatTag: ['Kewirausahaan', 'Riset'], gayaKerja: 'Fleksibel',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Public Speaking'], kuota: 1 },
      { namaRole: 'Supporter/Facilitator', skillDicari: ['Copywriting', 'Penulisan'], kuota: 2 },
    ],
    pelamar: [{ key: 'indah', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    pembuat: 'galih', judul: 'Pengujian Kualitas Aplikasi Akademik Kampus',
    deskripsi: 'Menyusun rencana pengujian dan menjalankan uji fungsional untuk aplikasi akademik kampus sebelum rilis besar.',
    timeline: '6 hari lagi', durasi: '1 bulan', format: 'Online', jadwalSlot: ['Kamis sore', 'Sabtu malam'],
    pengalamanReq: 2, minatTag: ['Pengembangan Web'], gayaKerja: 'Terstruktur',
    roles: [
      { namaRole: 'Leader/Coordinator', skillDicari: ['Manajemen Proyek'], kuota: 1 },
      { namaRole: 'Contributor/Executor', skillDicari: ['SQL', 'JavaScript'], kuota: 2 },
    ],
    pelamar: [{ key: 'cahyo', roleIndex: 1, status: 'PENDING' }],
  },
];

// ---------- Team Formation: lomba yang merepresentasikan ajang mahasiswa nyata ----------
interface LombaSeed {
  key: string;
  pengusul: string; // key persona
  judul: string;
  deskripsi: string;
  kategoriLomba: string[];
  maxAnggotaTim: number;
  minAnggotaTim: number;
  tenggatHari: number;
  penyelenggara: string;
  hadiah: string;
  cakupan: string;
  jenisBiaya: string;
  nominalBiaya: string | null;
  kontakInstagram?: string;
  kontakWebsite?: string;
  kontakNarahubung?: string;
}

const lombaSeeds: LombaSeed[] = [
  {
    key: 'gemastik', pengusul: 'bintang',
    judul: 'GEMASTIK — Pagelaran Mahasiswa Nasional Bidang TIK',
    deskripsi: 'Ajang tahunan Kemendikbudristek untuk mahasiswa bidang teknologi informasi dan komunikasi, terdiri dari berbagai divisi lomba seperti pengembangan aplikasi, keamanan siber, dan penambangan data.',
    kategoriLomba: ['AI', 'Data Science', 'Pengembangan Web'], maxAnggotaTim: 3, minAnggotaTim: 2, tenggatHari: 25,
    penyelenggara: 'Kementerian Pendidikan, Kebudayaan, Riset, dan Teknologi', hadiah: 'Rp25 juta + tropi & sertifikat nasional',
    cakupan: 'Nasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@gemastik.kemdikbud', kontakWebsite: 'gemastik.kemdikbud.go.id', kontakNarahubung: '0812-1000-2026 (Panitia GEMASTIK)',
  },
  {
    key: 'kbmi', pengusul: 'gita',
    judul: 'KBMI — Kompetisi Bisnis Mahasiswa Indonesia',
    deskripsi: 'Kompetisi rencana bisnis tingkat nasional untuk mahasiswa yang sudah merintis usaha, mulai dari seleksi proposal hingga pitching di hadapan investor dan praktisi.',
    kategoriLomba: ['Kewirausahaan'], maxAnggotaTim: 3, minAnggotaTim: 2, tenggatHari: 30,
    penyelenggara: 'Direktorat Jenderal Pendidikan Tinggi (Belmawa)', hadiah: 'Rp15 juta + pendanaan modal usaha',
    cakupan: 'Nasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@kbmi.belmawa', kontakWebsite: 'belmawa.kemdikbud.go.id/kbmi', kontakNarahubung: '0813-4400-7788 (Sekretariat KBMI)',
  },
  {
    key: 'hackmerdeka', pengusul: 'teguh',
    judul: 'Hackathon Merdeka Digital 2026',
    deskripsi: 'Kompetisi coding 48 jam bagi mahasiswa se-Indonesia untuk membangun solusi digital yang menjawab isu sosial, mulai dari pendidikan hingga lingkungan hidup.',
    kategoriLomba: ['AI', 'Pengembangan Mobile', 'Pengembangan Web'], maxAnggotaTim: 4, minAnggotaTim: 3, tenggatHari: 18,
    penyelenggara: 'Kementerian Komunikasi dan Digital', hadiah: 'Rp50 juta',
    cakupan: 'Nasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@hackathon.merdeka', kontakWebsite: 'hackmerdeka.id', kontakNarahubung: '0857-2233-4455 (Reza)',
  },
  {
    key: 'garudahacks', pengusul: 'vino',
    judul: 'Garuda Hacks',
    deskripsi: 'Hackathon mahasiswa terbesar di Indonesia yang berjalan non-stop selama 36 jam, mengumpulkan ratusan developer muda untuk membangun produk digital inovatif dari nol.',
    kategoriLomba: ['Pengembangan Web', 'AI'], maxAnggotaTim: 4, minAnggotaTim: 2, tenggatHari: 22,
    penyelenggara: 'Garuda Hacks Organizing Committee', hadiah: 'Rp40 juta + kesempatan magang',
    cakupan: 'Nasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@garudahacks', kontakWebsite: 'garudahacks.com', kontakNarahubung: '0821-5566-7788 (Tim Garuda Hacks)',
  },
  {
    key: 'compfest', pengusul: 'joko',
    judul: 'COMPFEST Competition',
    deskripsi: 'Rangkaian kompetisi teknologi dan bisnis digital yang diselenggarakan Fakultas Ilmu Komputer UI, mencakup jalur pengembangan aplikasi, data science, hingga UI/UX design.',
    kategoriLomba: ['Pengembangan Web', 'Data Science', 'UI/UX'], maxAnggotaTim: 3, minAnggotaTim: 2, tenggatHari: 27,
    penyelenggara: 'Fakultas Ilmu Komputer Universitas Indonesia', hadiah: 'Rp20 juta',
    cakupan: 'Nasional', jenisBiaya: 'BERBAYAR', nominalBiaya: 'Rp150.000/tim',
    kontakInstagram: '@compfest', kontakWebsite: 'compfest.id', kontakNarahubung: '0812-9900-1234 (Panitia COMPFEST)',
  },
  {
    key: 'aseandse', pengusul: 'dimas',
    judul: 'ASEAN Data Science Explorers',
    deskripsi: 'Kompetisi tingkat Asia Tenggara yang mengajak mahasiswa mengolah data terbuka untuk menghasilkan solusi berdampak sosial, dari kesehatan hingga mitigasi bencana.',
    kategoriLomba: ['Data Science', 'AI'], maxAnggotaTim: 3, minAnggotaTim: 2, tenggatHari: 35,
    penyelenggara: 'ASEAN Foundation & SAP', hadiah: 'USD 3.000',
    cakupan: 'Internasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@asean.dse', kontakWebsite: 'aseandse.org', kontakNarahubung: '+62 811-2233-9900 (Regional Coordinator)',
  },
  {
    key: 'gsc', pengusul: 'naufal',
    judul: 'Google Solution Challenge',
    deskripsi: 'Kompetisi global tahunan Google Developer Student Clubs, menantang mahasiswa membangun aplikasi mobile berbasis teknologi Google untuk mendukung Sustainable Development Goals.',
    kategoriLomba: ['Pengembangan Mobile', 'AI'], maxAnggotaTim: 4, minAnggotaTim: 2, tenggatHari: 40,
    penyelenggara: 'Google Developer Student Clubs', hadiah: 'Mentorship Google + swag eksklusif',
    cakupan: 'Internasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@gdsc.global', kontakWebsite: 'developers.google.com/community/gdsc-solution-challenge', kontakNarahubung: 'solutionchallenge@google-support.dummy',
  },
  {
    key: 'shopeecl', pengusul: 'della',
    judul: 'Shopee Code League',
    deskripsi: 'Kompetisi teknologi tahunan Shopee untuk talenta digital muda se-Asia Tenggara, mencakup jalur algoritma, data science, dan pengembangan produk.',
    kategoriLomba: ['Pengembangan Web', 'Data Science'], maxAnggotaTim: 3, minAnggotaTim: 1, tenggatHari: 15,
    penyelenggara: 'Shopee Indonesia', hadiah: 'Rp30 juta + kesempatan magang',
    cakupan: 'Regional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@shopeecodeleague', kontakWebsite: 'careers.shopee.sg/codeleague', kontakNarahubung: '0817-1122-3344 (Tim Rekrutmen Shopee)',
  },
  {
    key: 'pimnas', pengusul: 'lukman',
    judul: 'PIMNAS — Pekan Ilmiah Mahasiswa Nasional',
    deskripsi: 'Ajang puncak Program Kreativitas Mahasiswa, mempertemukan tim-tim riset terbaik se-Indonesia untuk mempresentasikan hasil penelitian dan inovasi di hadapan dewan juri nasional.',
    kategoriLomba: ['Riset'], maxAnggotaTim: 4, minAnggotaTim: 3, tenggatHari: 50,
    penyelenggara: 'Direktorat Jenderal Pendidikan Tinggi (Belmawa)', hadiah: 'Rp20 juta + Piala Bergilir Presiden',
    cakupan: 'Nasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@pimnas.belmawa', kontakWebsite: 'belmawa.kemdikbud.go.id/pimnas', kontakNarahubung: '0813-7788-9900 (Sekretariat PIMNAS)',
  },
  {
    key: 'uiuxnusantara', pengusul: 'citra',
    judul: 'UI/UX Design Challenge Nusantara',
    deskripsi: 'Kompetisi desain antarmuka dan pengalaman pengguna untuk mahasiswa se-Indonesia, menantang peserta merancang solusi digital yang inklusif dan mudah dipakai.',
    kategoriLomba: ['Desain', 'UI/UX'], maxAnggotaTim: 3, minAnggotaTim: 2, tenggatHari: 20,
    penyelenggara: 'Komunitas Desainer Indonesia', hadiah: 'Rp12 juta',
    cakupan: 'Nasional', jenisBiaya: 'GRATIS', nominalBiaya: null,
    kontakInstagram: '@uiux.nusantara', kontakWebsite: 'uiuxnusantara.id', kontakNarahubung: '0821-6677-8899 (Panitia UI/UX Nusantara)',
  },
];

// ---------- Team Formation: tim/lobi per lomba ----------
interface TimRoleSeed { namaRole: string; kuota: number }
interface TimAnggotaSeed { key: string; roleIndex: number; status: 'ACCEPTED' | 'PENDING' | 'LEFT'; dikeluarkan?: boolean }
interface TimSeed {
  lombaKey: string;
  koordinator: string; // key persona — otomatis ACCEPTED di roleIndex 0
  judul: string;
  deskripsi: string;
  roles: TimRoleSeed[];
  anggota: TimAnggotaSeed[]; // di luar koordinator
  diskusi?: { key: string; pesan: string }[];
}

const timSeeds: TimSeed[] = [
  {
    lombaKey: 'gemastik', koordinator: 'bintang', judul: 'Tim Elang Data',
    deskripsi: 'Fokus ke solusi berbasis data untuk isu pendidikan di daerah 3T.',
    roles: [{ namaRole: 'Backend Developer', kuota: 1 }, { namaRole: 'Data Scientist', kuota: 1 }, { namaRole: 'UI/UX Designer', kuota: 1 }],
    anggota: [
      { key: 'dimas', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'kirana', roleIndex: 2, status: 'ACCEPTED' },
      { key: 'hendra', roleIndex: 0, status: 'PENDING' },
    ],
    diskusi: [
      { key: 'bintang', pesan: 'Halo tim, yuk mulai diskusi ide untuk GEMASTIK tahun ini!' },
      { key: 'dimas', pesan: 'Aku sudah siapkan beberapa dataset kandidat, nanti kita bahas ya.' },
    ],
  },
  {
    lombaKey: 'kbmi', koordinator: 'gita', judul: 'Tim Wirausaha Muda',
    deskripsi: 'Rencana bisnis di sektor F&B berbasis komunitas lokal.',
    roles: [{ namaRole: 'Project Manager', kuota: 1 }, { namaRole: 'Content/Business Analyst', kuota: 2 }],
    anggota: [
      { key: 'indah', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'oktavia', roleIndex: 1, status: 'PENDING' },
    ],
  },
  {
    lombaKey: 'hackmerdeka', koordinator: 'joko', judul: 'Tim Cerdas Nusantara',
    deskripsi: 'Solusi AI untuk deteksi dini masalah lingkungan di kawasan urban.',
    roles: [{ namaRole: 'Backend Developer', kuota: 2 }, { namaRole: 'Mobile Developer', kuota: 1 }],
    anggota: [
      { key: 'lukman', roleIndex: 0, status: 'LEFT', dikeluarkan: false },
      { key: 'teguh', roleIndex: 0, status: 'ACCEPTED' },
      { key: 'umi', roleIndex: 1, status: 'PENDING' },
    ],
    diskusi: [{ key: 'joko', pesan: 'Ide awal: sistem deteksi banjir berbasis laporan warga + citra satelit.' }],
  },
  {
    lombaKey: 'garudahacks', koordinator: 'vino', judul: 'Tim Sriwijaya Coders',
    deskripsi: 'Membangun platform kolaborasi UMKM digital dalam 36 jam.',
    roles: [{ namaRole: 'Backend Developer', kuota: 2 }, { namaRole: 'Frontend Developer', kuota: 1 }, { namaRole: 'UI/UX Designer', kuota: 1 }],
    anggota: [
      { key: 'rangga', roleIndex: 0, status: 'ACCEPTED' },
      { key: 'cahyo', roleIndex: 1, status: 'ACCEPTED' },
      { key: 'zahra', roleIndex: 2, status: 'ACCEPTED' },
    ],
    diskusi: [
      { key: 'vino', pesan: 'Tim sudah lengkap, mari kita bagi task untuk 36 jam ke depan.' },
      { key: 'zahra', pesan: 'Aku mulai dari wireframe dulu ya, target selesai 3 jam.' },
    ],
  },
  {
    lombaKey: 'compfest', koordinator: 'joko', judul: 'Tim Fasilkom Bersatu',
    deskripsi: 'Membangun aplikasi web untuk transparansi dana desa.',
    roles: [{ namaRole: 'Frontend Developer', kuota: 1 }, { namaRole: 'Backend Developer', kuota: 1 }],
    anggota: [{ key: 'fajar', roleIndex: 1, status: 'ACCEPTED' }],
  },
  {
    lombaKey: 'aseandse', koordinator: 'dimas', judul: 'Tim Insight Bencana',
    deskripsi: 'Analisis data terbuka untuk pemetaan risiko bencana alam di Indonesia.',
    roles: [{ namaRole: 'Data Scientist', kuota: 2 }, { namaRole: 'Data Analyst', kuota: 1 }],
    anggota: [
      { key: 'yusuf', roleIndex: 0, status: 'ACCEPTED' },
      { key: 'della', roleIndex: 1, status: 'PENDING' },
    ],
  },
  {
    lombaKey: 'gsc', koordinator: 'naufal', judul: 'Tim Solusi Kampus Hijau',
    deskripsi: 'Aplikasi mobile untuk mendorong kebiasaan hidup berkelanjutan di lingkungan kampus.',
    roles: [{ namaRole: 'Mobile Developer', kuota: 2 }, { namaRole: 'UI/UX Designer', kuota: 1 }],
    anggota: [
      { key: 'abimanyu', roleIndex: 0, status: 'ACCEPTED' },
      { key: 'umi', roleIndex: 0, status: 'PENDING' },
    ],
  },
  {
    lombaKey: 'pimnas', koordinator: 'lukman', judul: 'Tim Riset Ketahanan Pangan',
    deskripsi: 'Riset dampak perubahan iklim terhadap produktivitas pertanian lokal.',
    roles: [{ namaRole: 'Data Analyst', kuota: 2 }, { namaRole: 'Content/Business Analyst', kuota: 1 }],
    anggota: [
      { key: 'galih', roleIndex: 0, status: 'ACCEPTED' },
      { key: 'salsa', roleIndex: 1, status: 'ACCEPTED' },
    ],
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

  console.log(`Membuat ${personas.length} akun dummy...`);
  const hash = await bcrypt.hash(PASSWORD, 10);
  const id: Record<string, string> = {};

  for (const p of personas) {
    const mhs = await prisma.mahasiswa.create({
      data: {
        nama: p.nama, email: p.email, password: hash,
        institusi: p.institusi, jurusan: p.jurusan, angkatan: p.angkatan,
        bio: p.bio, kontak: p.kontak, kontakJenis: p.kontakJenis,
      },
    });
    id[p.key] = mhs.id;

    if (p.profil) {
      await prisma.profil.create({
        data: {
          mahasiswaId: mhs.id, skill: p.profil.skill, pengalaman: p.profil.pengalaman,
          minatTag: p.profil.minatTag, gayaKerja: p.profil.gayaKerja, preferensiPeran: p.profil.preferensiPeran,
          ketersediaanWaktu: p.profil.ketersediaanWaktu, lengkap: true,
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
          jawaban: jawaban as any, diisi: true,
        },
      });
    }
    console.log(`  - ${p.nama} (${p.email})`);
  }
  console.log('Selesai membuat akun.\n');

  console.log('Membuat data People-to-People (koneksi, minat, disimpan)...');
  await prisma.connectRequest.create({ data: { senderId: id.bintang, receiverId: id.elena, status: 'ACCEPTED' } });
  await prisma.connection.create({ data: { mahasiswaAId: id.bintang, mahasiswaBId: id.elena, asal: 'REQUEST' } });

  await prisma.expressInterest.create({ data: { senderId: id.citra, receiverId: id.hendra } });
  await prisma.expressInterest.create({ data: { senderId: id.hendra, receiverId: id.citra } });
  await prisma.connection.create({ data: { mahasiswaAId: id.citra, mahasiswaBId: id.hendra, asal: 'INTEREST' } });

  await prisma.expressInterest.create({ data: { senderId: id.vino, receiverId: id.della } });
  await prisma.expressInterest.create({ data: { senderId: id.della, receiverId: id.vino } });
  await prisma.connection.create({ data: { mahasiswaAId: id.vino, mahasiswaBId: id.della, asal: 'INTEREST' } });

  await prisma.connectRequest.create({ data: { senderId: id.teguh, receiverId: id.rangga, status: 'ACCEPTED' } });
  await prisma.connection.create({ data: { mahasiswaAId: id.teguh, mahasiswaBId: id.rangga, asal: 'REQUEST' } });

  await prisma.connectRequest.create({ data: { senderId: id.joko, receiverId: id.kirana, status: 'PENDING' } });
  await prisma.connectRequest.create({ data: { senderId: id.naufal, receiverId: id.oktavia, status: 'PENDING' } });
  await prisma.connectRequest.create({ data: { senderId: id.bella, receiverId: id.eka, status: 'PENDING' } });

  await prisma.expressInterest.create({ data: { senderId: id.putra, receiverId: id.indah } });
  await prisma.expressInterest.create({ data: { senderId: id.fajar, receiverId: id.gita } });
  await prisma.expressInterest.create({ data: { senderId: id.lukman, receiverId: id.gita } });
  await prisma.expressInterest.create({ data: { senderId: id.yusuf, receiverId: id.zahra } });
  await prisma.expressInterest.create({ data: { senderId: id.abimanyu, receiverId: id.wulan } });
  await prisma.expressInterest.create({ data: { senderId: id.galih, receiverId: id.salsa } });

  await prisma.savedProfile.create({ data: { ownerId: id.bintang, targetId: id.gita } });
  await prisma.savedProfile.create({ data: { ownerId: id.elena, targetId: id.kirana } });
  await prisma.savedProfile.create({ data: { ownerId: id.dimas, targetId: id.naufal } });
  await prisma.savedProfile.create({ data: { ownerId: id.eka, targetId: id.wulan } });
  await prisma.savedProfile.create({ data: { ownerId: id.zahra, targetId: id.citra } });
  console.log('Selesai People-to-People.\n');

  console.log(`Membuat ${projectSeeds.length} data People-to-Project (proyek, kebutuhan role, pendaftaran)...`);
  for (const p of projectSeeds) {
    const project = await prisma.project.create({
      data: {
        judul: p.judul, deskripsi: p.deskripsi, timeline: p.timeline, durasi: p.durasi, format: p.format,
        jadwalSlot: p.jadwalSlot, pengalamanReq: p.pengalamanReq, minatTag: p.minatTag, gayaKerja: p.gayaKerja,
        pembuatId: id[p.pembuat],
        roles: { create: p.roles.map((r) => ({ namaRole: r.namaRole, skillDicari: r.skillDicari, kuota: r.kuota, sisaKuota: r.kuota })) },
      },
      include: { roles: true },
    });

    // pembuat otomatis ACCEPTED di role pertama
    const roleUtama = project.roles[0];
    await prisma.pendaftaranProject.create({ data: { mahasiswaId: id[p.pembuat], projectId: project.id, roleId: roleUtama.id, status: 'ACCEPTED' } });
    await prisma.kebutuhanRole.update({ where: { id: roleUtama.id }, data: { sisaKuota: { decrement: 1 } } });

    for (const pel of p.pelamar ?? []) {
      const role = project.roles[pel.roleIndex];
      await prisma.pendaftaranProject.create({ data: { mahasiswaId: id[pel.key], projectId: project.id, roleId: role.id, status: pel.status } });
      if (pel.status === 'ACCEPTED') {
        await prisma.kebutuhanRole.update({ where: { id: role.id }, data: { sisaKuota: { decrement: 1 } } });
      }
    }
    console.log(`  - "${project.judul}" oleh ${p.pembuat}`);
  }
  console.log('Selesai People-to-Project.\n');

  console.log(`Membuat ${lombaSeeds.length} data lomba (Team Formation)...`);
  const lombaId: Record<string, string> = {};
  for (const l of lombaSeeds) {
    const created = await prisma.lomba.create({
      data: {
        judul: l.judul, deskripsi: l.deskripsi, kategoriLomba: l.kategoriLomba,
        maxAnggotaTim: l.maxAnggotaTim, minAnggotaTim: l.minAnggotaTim, tenggat: hariLagi(l.tenggatHari),
        penyelenggara: l.penyelenggara, hadiah: l.hadiah, cakupan: l.cakupan,
        jenisBiaya: l.jenisBiaya, nominalBiaya: l.nominalBiaya,
        kontakInstagram: l.kontakInstagram, kontakWebsite: l.kontakWebsite, kontakNarahubung: l.kontakNarahubung,
        pengusulId: id[l.pengusul],
      },
    });
    lombaId[l.key] = created.id;
    console.log(`  - ${created.judul}`);
  }
  console.log('Selesai membuat lomba.\n');

  console.log(`Membuat ${timSeeds.length} tim/lobi + pendaftaran anggota...`);
  for (const t of timSeeds) {
    const lobi = await prisma.studentLobby.create({
      data: {
        lombaId: lombaId[t.lombaKey], judul: t.judul, deskripsi: t.deskripsi,
        koordinatorId: id[t.koordinator], status: 'OPEN',
        roles: { create: t.roles.map((r) => ({ namaRole: r.namaRole, kuota: r.kuota, sisaKuota: r.kuota })) },
      },
      include: { roles: true },
    });

    // koordinator otomatis ACCEPTED di role pertama
    const roleUtama = lobi.roles[0];
    await prisma.pendaftaranAnggota.create({ data: { mahasiswaId: id[t.koordinator], lobiId: lobi.id, roleId: roleUtama.id, status: 'ACCEPTED' } });
    await prisma.roleLobiTim.update({ where: { id: roleUtama.id }, data: { sisaKuota: { decrement: 1 } } });

    for (const a of t.anggota) {
      const role = lobi.roles[a.roleIndex];
      await prisma.pendaftaranAnggota.create({
        data: { mahasiswaId: id[a.key], lobiId: lobi.id, roleId: role.id, status: a.status, dikeluarkan: a.dikeluarkan ?? false },
      });
      if (a.status === 'ACCEPTED') {
        await prisma.roleLobiTim.update({ where: { id: role.id }, data: { sisaKuota: { decrement: 1 } } });
      }
    }

    for (const d of t.diskusi ?? []) {
      await prisma.diskusiTim.create({ data: { lobiId: lobi.id, mahasiswaId: id[d.key], pesan: d.pesan } });
    }
    console.log(`  - "${t.judul}" (${t.lombaKey})`);
  }
  console.log('Selesai Team Formation.\n');

  console.log(`✅ Reset & seed selesai. ${personas.length} akun dummy, ${projectSeeds.length} proyek, ${lombaSeeds.length} lomba, ${timSeeds.length} tim.`);
  console.log('Semua akun dummy pakai password: 123456');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

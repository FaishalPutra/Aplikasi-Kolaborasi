// Tambah 2 akun dummy yang sengaja dirancang supaya skor People-to-People mereka
// berdua sangat tinggi (mendekati 100%, label "Sangat Cocok") — dipakai untuk demo
// menunjukkan tampilan skor kecocokan tinggi. Tidak menghapus data lain, cuma nambah.
//
// Perhitungan (lihat affinityPeople.ts, Persamaan IV.2-IV.8):
//   skill      (bobot 0,241) -> dibuat TIDAK ada irisan sama sekali -> skor 1,0 (komplementer maksimal)
//   minat      (bobot 0,198) -> dibuat IDENTIK                      -> skor 1,0
//   gayaKerja  (bobot 0,178) -> dibuat SAMA                         -> skor 1,0
//   pengalaman (bobot 0,162) -> dibuat SAMA level                   -> skor 1,0
//   ketersediaan (bobot 0,111) -> dibuat IDENTIK                    -> skor 1,0
//   peran      (bobot 0,111) -> dibuat BEDA                         -> skor 1,0
//   Total ~1,001 -> persen ~100,1% -> "Sangat Cocok"
//
// Jalankan: DATABASE_URL="..." npx ts-node src/scripts/addPerfectMatchPair.ts
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { treoNorm, TREO_DIMENSIONS, type TreoDimensi } from '../affinityTeam';

const prisma = new PrismaClient();
const PASSWORD = '123456';

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

async function buatAkun(opts: {
  nama: string; email: string; institusi: string; jurusan: string; angkatan: number; bio: string;
  kontak: string; kontakJenis: string;
  skill: string[]; pengalaman: number; minatTag: string[]; gayaKerja: string; preferensiPeran: string;
  ketersediaanWaktu: string[]; treoDominan: TreoDimensi[];
}) {
  const hash = await bcrypt.hash(PASSWORD, 10);
  const mhs = await prisma.mahasiswa.create({
    data: {
      nama: opts.nama, email: opts.email, password: hash,
      institusi: opts.institusi, jurusan: opts.jurusan, angkatan: opts.angkatan,
      bio: opts.bio, kontak: opts.kontak, kontakJenis: opts.kontakJenis,
    },
  });
  await prisma.profil.create({
    data: {
      mahasiswaId: mhs.id, skill: opts.skill, pengalaman: opts.pengalaman, minatTag: opts.minatTag,
      gayaKerja: opts.gayaKerja, preferensiPeran: opts.preferensiPeran, ketersediaanWaktu: opts.ketersediaanWaktu,
      lengkap: true, visibilitas: true,
    },
  });
  const jawaban = buatJawabanTreo(opts.treoDominan);
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
  return mhs;
}

async function main() {
  const raka = await buatAkun({
    nama: 'Raka Dwi Saputra', email: 'raka.dwi@dummy.test',
    institusi: 'Institut Teknologi Bandung', jurusan: 'Teknik Informatika', angkatan: 2022,
    bio: 'Backend developer yang suka memimpin diskusi teknis dan menyusun rencana proyek dari awal.',
    kontak: '081234500031', kontakJenis: 'WHATSAPP',
    skill: ['Python', 'SQL', 'Analisis Data'], pengalaman: 3, minatTag: ['AI', 'Data Science'],
    gayaKerja: 'Terstruktur', preferensiPeran: 'Leader/Coordinator', ketersediaanWaktu: ['Senin malam', 'Rabu sore'],
    treoDominan: ['organizer', 'doer'],
  });
  const salma = await buatAkun({
    nama: 'Salma Wijaya Kusuma', email: 'salma.wijaya@dummy.test',
    institusi: 'Universitas Indonesia', jurusan: 'Desain Komunikasi Visual', angkatan: 2022,
    bio: 'UI/UX designer yang senang mendukung tim dari sisi presentasi dan riset pengguna.',
    kontak: '081234500032', kontakJenis: 'LINE',
    skill: ['Figma', 'UI Design', 'Public Speaking'], pengalaman: 3, minatTag: ['AI', 'Data Science'],
    gayaKerja: 'Terstruktur', preferensiPeran: 'Contributor/Executor', ketersediaanWaktu: ['Senin malam', 'Rabu sore'],
    treoDominan: ['innovator', 'connector'],
  });

  console.log(`✅ Dibuat: ${raka.nama} (${raka.email}) & ${salma.nama} (${salma.email})`);
  console.log('Password keduanya: 123456');
  console.log('Login sebagai salah satu, buka tab Rekomendasi di modul People-to-People — yang satu lagi akan muncul dengan skor ~100% "Sangat Cocok".');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

function hariLagi(hari: number): Date {
  return new Date(Date.now() + hari * 24 * 60 * 60 * 1000);
}

async function main() {
  let pengusul = await prisma.mahasiswa.findFirst();
  if (!pengusul) {
    const hash = await bcrypt.hash('seed12345', 10);
    pengusul = await prisma.mahasiswa.create({
      data: {
        nama: 'Admin Penyelenggara',
        email: 'admin.dummy@seed.local',
        password: hash,
        institusi: 'Universitas Contoh',
        jurusan: 'Ilmu Komputer',
        angkatan: 2021,
      },
    });
    console.log(`Tidak ada mahasiswa, dibuat akun pengusul dummy: ${pengusul.email} (password: seed12345)`);
  }

  const dataLomba = [
    {
      judul: 'Gojik DataFest 2026',
      deskripsi:
        'Kompetisi analisis data nasional yang menantang mahasiswa untuk mengolah dataset transaksi ride-hailing dan menghasilkan insight bisnis yang actionable. Terbuka untuk tim lintas jurusan.',
      kategoriLomba: ['Data Science', 'AI'],
      maxAnggotaTim: 5,
      minAnggotaTim: 3,
      tenggat: hariLagi(12),
      penyelenggara: 'PT Gojik Teknologi Indonesia',
      hadiah: 'Rp30 juta',
      cakupan: 'Nasional',
      jenisBiaya: 'GRATIS',
      nominalBiaya: null,
      kontakInstagram: '@gojik.datafest',
      kontakWebsite: 'datafest.gojik.id',
      kontakNarahubung: '0813-2200-9988 (Dinda)',
    },
    {
      judul: 'Nusantara Web Dev Challenge',
      deskripsi:
        'Ajang tahunan pengembangan aplikasi web untuk UMKM lokal. Peserta membangun solusi digital end-to-end mulai dari riset kebutuhan hingga deployment.',
      kategoriLomba: ['Pengembangan Web', 'UI/UX'],
      maxAnggotaTim: 4,
      minAnggotaTim: 2,
      tenggat: hariLagi(20),
      penyelenggara: 'Kementerian Komunikasi dan Digital',
      hadiah: 'Rp25 juta',
      cakupan: 'Nasional',
      jenisBiaya: 'BERBAYAR',
      nominalBiaya: 'Rp150.000/tim',
      kontakInstagram: '@nusantarawebdev',
      kontakWebsite: 'nwdc.id',
      kontakNarahubung: '0812-3344-5566 (Rian)',
    },
    {
      judul: 'ASEAN Mobile Innovation Award',
      deskripsi:
        'Kompetisi tingkat Asia Tenggara untuk aplikasi mobile inovatif di bidang kesehatan, pendidikan, atau lingkungan. Penilaian mencakup dampak sosial dan kualitas teknis.',
      kategoriLomba: ['Pengembangan Mobile', 'Kewirausahaan'],
      maxAnggotaTim: 5,
      minAnggotaTim: 3,
      tenggat: hariLagi(45),
      penyelenggara: 'ASEAN Digital Innovation Network',
      hadiah: 'USD 5.000',
      cakupan: 'Internasional',
      jenisBiaya: 'GRATIS',
      nominalBiaya: null,
      kontakInstagram: '@asean.mia',
      kontakWebsite: 'asean-mia.org',
      kontakNarahubung: '+62 811-9900-1122 (Sarah)',
    },
    {
      judul: 'Riset Cepat Jawa Barat 2026',
      deskripsi:
        'Kompetisi riset singkat tingkat regional Jawa Barat untuk mahasiswa, mengangkat isu-isu lokal seperti mobilitas kota dan ketahanan pangan. Cocok untuk tim kecil yang gesit.',
      kategoriLomba: ['Riset'],
      maxAnggotaTim: 3,
      minAnggotaTim: 2,
      tenggat: hariLagi(7),
      penyelenggara: 'Forum Riset Mahasiswa Jawa Barat',
      hadiah: 'Rp8 juta',
      cakupan: 'Regional',
      jenisBiaya: 'GRATIS',
      nominalBiaya: null,
      kontakInstagram: '@frmjabar',
      kontakWebsite: null,
      kontakNarahubung: '0857-1234-8899 (Fajar)',
    },
  ];

  const lombaDibuat: { judul: string; id: string }[] = [];
  for (const l of dataLomba) {
    const created = await prisma.lomba.create({
      data: { ...l, pengusulId: pengusul.id },
    });
    lombaDibuat.push({ judul: created.judul, id: created.id });
    console.log(`Dibuat: ${created.judul} (${created.id})`);
  }

  const dataFestId = lombaDibuat.find((l) => l.judul === 'Gojik DataFest 2026')!.id;

  const dummyAnggota = [
    {
      nama: 'Rania Putri Wibowo',
      email: 'rania.dummy@seed.local',
      skill: ['Python', 'Statistika', 'Machine Learning', 'SQL'],
      pengalaman: 3,
      minatTag: ['Data Science', 'AI'],
      gayaKerja: 'Analitis',
      preferensiPeran: 'Data Scientist',
      treo: { organizer: 3, doer: 5, challenger: 3, innovator: 4, teamBuilder: 2, connector: 2 },
      role: 'Data Scientist',
    },
    {
      nama: 'Bagas Aditya Nugroho',
      email: 'bagas.dummy@seed.local',
      skill: ['Python', 'SQL', 'Visualisasi Data', 'Excel'],
      pengalaman: 2,
      minatTag: ['Data Science'],
      gayaKerja: 'Terstruktur',
      preferensiPeran: 'Data Analyst',
      treo: { organizer: 4, doer: 4, challenger: 2, innovator: 2, teamBuilder: 3, connector: 3 },
      role: 'Data Analyst',
    },
    {
      nama: 'Citra Ayu Lestari',
      email: 'citra.dummy@seed.local',
      skill: ['Manajemen Proyek', 'Komunikasi', 'Perencanaan', 'Dokumentasi'],
      pengalaman: 3,
      minatTag: ['AI', 'Kewirausahaan'],
      gayaKerja: 'Kolaboratif',
      preferensiPeran: 'Project Manager',
      treo: { organizer: 5, doer: 2, challenger: 2, innovator: 3, teamBuilder: 5, connector: 4 },
      role: 'Project Manager',
    },
  ];

  const passwordHash = await bcrypt.hash('seed12345', 10);
  const anggotaDibuat: { id: string; nama: string; role: string }[] = [];

  for (const a of dummyAnggota) {
    const mhs = await prisma.mahasiswa.upsert({
      where: { email: a.email },
      update: {},
      create: {
        nama: a.nama,
        email: a.email,
        password: passwordHash,
        institusi: 'Universitas Contoh',
        jurusan: 'Ilmu Komputer',
        angkatan: 2022,
      },
    });

    await prisma.profil.upsert({
      where: { mahasiswaId: mhs.id },
      update: {},
      create: {
        mahasiswaId: mhs.id,
        skill: a.skill,
        pengalaman: a.pengalaman,
        minatTag: a.minatTag,
        gayaKerja: a.gayaKerja,
        preferensiPeran: a.preferensiPeran,
        ketersediaanWaktu: ['Weekday Malam', 'Weekend'],
        lengkap: true,
        visibilitas: true,
      },
    });

    const norm = (raw: number) => (raw - 1) / 4;
    await prisma.treoProfil.upsert({
      where: { mahasiswaId: mhs.id },
      update: {},
      create: {
        mahasiswaId: mhs.id,
        organizerRaw: a.treo.organizer,
        doerRaw: a.treo.doer,
        challengerRaw: a.treo.challenger,
        innovatorRaw: a.treo.innovator,
        teamBuilderRaw: a.treo.teamBuilder,
        connectorRaw: a.treo.connector,
        organizerNorm: norm(a.treo.organizer),
        doerNorm: norm(a.treo.doer),
        challengerNorm: norm(a.treo.challenger),
        innovatorNorm: norm(a.treo.innovator),
        teamBuilderNorm: norm(a.treo.teamBuilder),
        connectorNorm: norm(a.treo.connector),
        jawaban: {},
        diisi: true,
      },
    });

    anggotaDibuat.push({ id: mhs.id, nama: mhs.nama, role: a.role });
    console.log(`Dummy mahasiswa dibuat/diperbarui: ${mhs.nama} (${mhs.id})`);
  }

  const koordinator = anggotaDibuat[0];

  const lobiExisting = await prisma.studentLobby.findFirst({
    where: { lombaId: dataFestId, judul: 'Tim Insight Ride-Hailing' },
  });

  if (!lobiExisting) {
    const lobi = await prisma.studentLobby.create({
      data: {
        lombaId: dataFestId,
        judul: 'Tim Insight Ride-Hailing',
        deskripsi:
          'Fokus membangun model prediksi permintaan dan dashboard insight untuk juri. Mencari anggota yang gesit dan terbuka diskusi.',
        koordinatorId: koordinator.id,
        status: 'OPEN',
        roles: {
          create: [
            { namaRole: 'Data Scientist', pengalamanReq: 3, kuota: 2, sisaKuota: 1 },
            { namaRole: 'Data Analyst', pengalamanReq: 2, kuota: 2, sisaKuota: 1 },
            { namaRole: 'Project Manager', pengalamanReq: 2, kuota: 1, sisaKuota: 0 },
          ],
        },
      },
      include: { roles: true },
    });

    for (const a of anggotaDibuat) {
      const role = lobi.roles.find((r) => r.namaRole === a.role);
      if (!role) continue;
      await prisma.pendaftaranAnggota.create({
        data: {
          mahasiswaId: a.id,
          lobiId: lobi.id,
          roleId: role.id,
          status: 'ACCEPTED',
        },
      });
    }

    console.log(`Dummy lobi dibuat: ${lobi.judul} (${lobi.id}) di lomba ${dataFestId}`);
  } else {
    console.log('Dummy lobi sudah ada, dilewati.');
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

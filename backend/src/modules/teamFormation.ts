import { Router } from 'express';
import { prisma } from '../prisma';
import { wajibLogin, AuthedRequest } from '../auth';
import {
  technicalRoleAffinity,
  technicalRoleAffinityTeam,
  distributedRoleCoverage,
  teamFunctionAffinity,
  teamFormationEffectivenessScore,
  TREO_DIMENSIONS,
  TreoDimensi,
  treoNorm,
  ProfilTeknis,
  RoleInput,
  AnggotaTreo,
} from '../affinityTeam';

// Modul Team Formation (Faishal). UC21-an — usul lomba, buat lobi/tim, daftar role,
// terima/tolak anggota, finalisasi skor tim (Algoritma IV.1-IV.3), kuesioner TREO, diskusi tim.
const router = Router();

router.get('/health', (_req, res) => res.json({ module: 'team-formation', ok: true }));

async function ambilProfilTeknis(mahasiswaId: string): Promise<ProfilTeknis | null> {
  const profil = await prisma.profil.findUnique({ where: { mahasiswaId } });
  if (!profil || !profil.lengkap) return null;
  return { skill: profil.skill, pengalaman: profil.pengalaman, minatTag: profil.minatTag };
}

const SATU_JAM_MS = 60 * 60 * 1000;

// Batas waktu 1 jam sejak inisiasi finalisasi — kalau lewat & belum semua anggota setuju,
// lobi dikembalikan ke OPEN supaya pembuat tim bisa inisiasi ulang.
async function revertFinalisasiKedaluwarsa(
  lobiId: string,
  status: string,
  waktuInisiasi: Date | null,
): Promise<boolean> {
  if (status !== 'FINALIZING' || !waktuInisiasi) return false;
  if (Date.now() - waktuInisiasi.getTime() < SATU_JAM_MS) return false;
  await prisma.$transaction([
    prisma.studentLobby.update({ where: { id: lobiId }, data: { status: 'OPEN', waktuInisiasiFinalisasi: null } }),
    prisma.pendaftaranAnggota.updateMany({ where: { lobiId, setujuFinalisasi: true }, data: { setujuFinalisasi: false } }),
  ]);
  return true;
}

function toRoleInput(role: { namaRole: string; pengalamanReq: number | null }, kategoriLomba: string[]): RoleInput {
  return { namaRole: role.namaRole, kategoriLomba, pengalamanReq: role.pengalamanReq };
}

// Label tampilan 6 dimensi TREO (dipakai untuk daftar "Dimensi terbuka" di kartu lobi)
const TREO_DIM_LABEL: Record<TreoDimensi, string> = {
  organizer: 'Organizer',
  doer: 'Doer',
  challenger: 'Challenger',
  innovator: 'Innovator',
  teamBuilder: 'Team Builder',
  connector: 'Connector',
};
const AMBANG_DIMENSI_TERTUTUP = 0.5;

// Dimensi TREO yang masih "terbuka" (belum ada anggota diterima yang mewakilinya secara kuat)
function dimensiTerbukaDariAnggota(normList: Record<TreoDimensi, number>[]): string[] {
  if (normList.length === 0) return TREO_DIMENSIONS.map((d) => TREO_DIM_LABEL[d]);
  return TREO_DIMENSIONS.filter((d) => {
    const terbaik = Math.max(...normList.map((n) => n[d]));
    return terbaik < AMBANG_DIMENSI_TERTUTUP;
  }).map((d) => TREO_DIM_LABEL[d]);
}

// --- Lomba -------------------------------------------------------------------------------------

// UC21 List lomba aktif
router.get('/lomba', wajibLogin, async (req: AuthedRequest, res) => {
  const lomba = await prisma.lomba.findMany({
    where: { status: 'ACTIVE' },
    include: { lobi: { select: { id: true, koordinatorId: true, status: true } } },
    orderBy: { createdAt: 'desc' },
  });
  const pendaftaranSaya = await prisma.pendaftaranAnggota.findMany({
    where: { mahasiswaId: req.mahasiswaId!, lobi: { lombaId: { in: lomba.map((l) => l.id) } } },
    select: { lobiId: true, status: true, lobi: { select: { lombaId: true } } },
  });
  const diikutiIds = new Set(pendaftaranSaya.map((p) => p.lobi.lombaId));
  const lobiSayaTerlibatIds = new Set(
    pendaftaranSaya.filter((p) => ['PENDING', 'ACCEPTED', 'REJECTED', 'LEFT'].includes(p.status)).map((p) => p.lobiId),
  );
  return res.json(
    lomba.map((l) => ({
      id: l.id,
      judul: l.judul,
      deskripsi: l.deskripsi,
      kategoriLomba: l.kategoriLomba,
      maxAnggotaTim: l.maxAnggotaTim,
      minAnggotaTim: l.minAnggotaTim,
      tenggat: l.tenggat,
      penyelenggara: l.penyelenggara,
      hadiah: l.hadiah,
      cakupan: l.cakupan,
      jenisBiaya: l.jenisBiaya,
      nominalBiaya: l.nominalBiaya,
      kontakInstagram: l.kontakInstagram,
      kontakWebsite: l.kontakWebsite,
      kontakNarahubung: l.kontakNarahubung,
      jumlahLobi: l.lobi.filter(
        (x: { id: string; koordinatorId: string; status: string }) =>
          x.koordinatorId !== req.mahasiswaId && x.status !== 'FINAL' && !lobiSayaTerlibatIds.has(x.id),
      ).length,
      diikuti: diikutiIds.has(l.id),
    })),
  );
});

// UC21 Usul lomba baru — langsung ACTIVE (tanpa moderasi Pengelola Platform)
router.post('/lomba', wajibLogin, async (req: AuthedRequest, res) => {
  const {
    judul,
    deskripsi,
    kategoriLomba,
    maxAnggotaTim,
    minAnggotaTim,
    tenggat,
    penyelenggara,
    hadiah,
    cakupan,
    jenisBiaya,
    nominalBiaya,
    kontakInstagram,
    kontakWebsite,
    kontakNarahubung,
  } = req.body ?? {};
  if (!judul || !deskripsi || !Array.isArray(kategoriLomba) || kategoriLomba.length === 0) {
    return res.status(400).json({ error: 'judul, deskripsi, dan minimal satu kategoriLomba wajib' });
  }
  if (typeof maxAnggotaTim !== 'number' || maxAnggotaTim < 1) {
    return res.status(400).json({ error: 'maxAnggotaTim wajib >= 1' });
  }
  if (typeof minAnggotaTim === 'number' && minAnggotaTim > maxAnggotaTim) {
    return res.status(400).json({ error: 'minAnggotaTim tidak boleh lebih besar dari maxAnggotaTim' });
  }
  let tenggatDate: Date | null = null;
  if (tenggat) {
    tenggatDate = new Date(tenggat);
    if (isNaN(tenggatDate.getTime())) {
      return res.status(400).json({ error: 'tenggat tidak valid' });
    }
  }
  const lomba = await prisma.lomba.create({
    data: {
      judul,
      deskripsi,
      kategoriLomba,
      maxAnggotaTim,
      minAnggotaTim: typeof minAnggotaTim === 'number' ? minAnggotaTim : null,
      tenggat: tenggatDate,
      penyelenggara: penyelenggara ?? null,
      hadiah: hadiah ?? null,
      cakupan: cakupan ?? null,
      jenisBiaya: jenisBiaya ?? null,
      nominalBiaya: jenisBiaya === 'BERBAYAR' ? nominalBiaya ?? null : null,
      kontakInstagram: kontakInstagram ?? null,
      kontakWebsite: kontakWebsite ?? null,
      kontakNarahubung: kontakNarahubung ?? null,
      pengusulId: req.mahasiswaId!,
    },
  });
  return res.status(201).json(lomba);
});

// Detail lomba + daftar lobi (tim) yang terbentuk untuknya
router.get('/lomba/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const lomba = await prisma.lomba.findUnique({
    where: { id: req.params.id },
    include: {
      lobi: {
        include: {
          roles: true,
          pendaftaran: { where: { status: 'ACCEPTED' }, include: { mahasiswa: { select: { nama: true } } } },
        },
      },
    },
  });
  if (!lomba) return res.status(404).json({ error: 'Lomba tidak ditemukan' });

  const pendaftaranSayaDiLomba = await prisma.pendaftaranAnggota.findMany({
    where: {
      mahasiswaId: req.mahasiswaId!,
      status: { in: ['PENDING', 'ACCEPTED', 'REJECTED', 'LEFT'] },
      lobi: { lombaId: lomba.id },
    },
    select: { lobiId: true },
  });
  const lobiDiikutiIds = new Set(pendaftaranSayaDiLomba.map((p) => p.lobiId));

  const lobiList = await Promise.all(
    lomba.lobi
      .filter(
        (l: (typeof lomba.lobi)[number]) =>
          l.koordinatorId !== req.mahasiswaId && l.status !== 'FINAL' && !lobiDiikutiIds.has(l.id),
      )
      .map(async (l: (typeof lomba.lobi)[number]) => {
      const koordinator = await prisma.mahasiswa.findUnique({ where: { id: l.koordinatorId }, select: { nama: true } });
      const totalKuota = l.roles.reduce((s, r) => s + r.kuota, 0);
      const rolesTerbuka = Array.from(new Set(l.roles.map((r) => r.namaRole)));

      const treoList = await prisma.treoProfil.findMany({
        where: { mahasiswaId: { in: l.pendaftaran.map((p) => p.mahasiswaId) } },
      });
      const treoMap = new Map(treoList.map((t) => [t.mahasiswaId, t]));
      const normList: Record<TreoDimensi, number>[] = l.pendaftaran
        .map((p) => treoMap.get(p.mahasiswaId))
        .filter((t): t is NonNullable<typeof t> => !!t)
        .map((t) => ({
          organizer: t.organizerNorm,
          doer: t.doerNorm,
          challenger: t.challengerNorm,
          innovator: t.innovatorNorm,
          teamBuilder: t.teamBuilderNorm,
          connector: t.connectorNorm,
        }));
      const dimensiTerbuka = dimensiTerbukaDariAnggota(normList);

      return {
        id: l.id,
        judul: l.judul,
        deskripsi: l.deskripsi,
        status: l.status,
        namaKoordinator: koordinator?.nama ?? '-',
        jumlahAnggota: l.pendaftaran.length,
        totalKuota,
        anggota: l.pendaftaran.map((p) => ({ mahasiswaId: p.mahasiswaId, nama: p.mahasiswa.nama })),
        rolesTerbuka,
        dimensiTerbuka,
      };
    }),
  );

  return res.json({
    id: lomba.id,
    judul: lomba.judul,
    deskripsi: lomba.deskripsi,
    kategoriLomba: lomba.kategoriLomba,
    maxAnggotaTim: lomba.maxAnggotaTim,
    minAnggotaTim: lomba.minAnggotaTim,
    tenggat: lomba.tenggat,
    penyelenggara: lomba.penyelenggara,
    hadiah: lomba.hadiah,
    cakupan: lomba.cakupan,
    jenisBiaya: lomba.jenisBiaya,
    nominalBiaya: lomba.nominalBiaya,
    kontakInstagram: lomba.kontakInstagram,
    kontakWebsite: lomba.kontakWebsite,
    kontakNarahubung: lomba.kontakNarahubung,
    lobi: lobiList,
  });
});

// --- Lobi / Tim ----------------------------------------------------------------------------------

// Buat lobi/tim baru untuk mengikuti sebuah lomba (+ minimal satu role)
router.post('/lomba/:id/lobi', wajibLogin, async (req: AuthedRequest, res) => {
  const lomba = await prisma.lomba.findUnique({ where: { id: req.params.id } });
  if (!lomba) return res.status(404).json({ error: 'Lomba tidak ditemukan' });

  const { judul, deskripsi, roles } = req.body ?? {};
  if (!judul || !Array.isArray(roles) || roles.length === 0) {
    return res.status(400).json({ error: 'judul dan minimal satu role wajib' });
  }
  for (const r of roles) {
    if (!r.namaRole || typeof r.kuota !== 'number' || r.kuota < 1) {
      return res.status(400).json({ error: 'setiap role wajib namaRole dan kuota >= 1' });
    }
  }

  const lobi = await prisma.studentLobby.create({
    data: {
      lombaId: lomba.id,
      judul,
      deskripsi: deskripsi ?? null,
      koordinatorId: req.mahasiswaId!,
      roles: {
        create: roles.map((r: any) => ({
          namaRole: r.namaRole,
          pengalamanReq: typeof r.pengalamanReq === 'number' ? r.pengalamanReq : null,
          kuota: r.kuota,
          sisaKuota: r.kuota,
        })),
      },
    },
    include: { roles: true },
  });

  // Pembuat lobi otomatis masuk sebagai anggota (ACCEPTED) di peran pertama yang dibuka
  const roleUntukPembuat = lobi.roles[0];
  if (roleUntukPembuat) {
    await prisma.$transaction([
      prisma.pendaftaranAnggota.create({
        data: { mahasiswaId: req.mahasiswaId!, lobiId: lobi.id, roleId: roleUntukPembuat.id, status: 'ACCEPTED' },
      }),
      prisma.roleLobiTim.update({ where: { id: roleUntukPembuat.id }, data: { sisaKuota: { decrement: 1 } } }),
    ]);
  }

  return res.status(201).json(lobi);
});

// Detail lobi: role + sisa kuota, anggota diterima, status pendaftaran saya, affinity role saya (jika belum daftar)
router.get('/lobi/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({
    where: { id: req.params.id },
    include: {
      lomba: true,
      roles: true,
      pendaftaran: { include: { mahasiswa: { select: { id: true, nama: true, kontak: true, kontakJenis: true } }, role: true } },
      skorTim: true,
    },
  });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });

  const direvert = await revertFinalisasiKedaluwarsa(lobi.id, lobi.status, lobi.waktuInisiasiFinalisasi);
  if (direvert) {
    lobi.status = 'OPEN' as any;
    lobi.waktuInisiasiFinalisasi = null;
    for (const p of lobi.pendaftaran) p.setujuFinalisasi = false;
  }

  const koordinator = await prisma.mahasiswa.findUnique({ where: { id: lobi.koordinatorId }, select: { nama: true } });
  const milikSaya = lobi.koordinatorId === req.mahasiswaId;

  const anggotaAccepted = lobi.pendaftaran.filter((p) => p.status === 'ACCEPTED');
  const treoAnggota = await prisma.treoProfil.findMany({
    where: { mahasiswaId: { in: anggotaAccepted.map((p) => p.mahasiswaId) } },
  });
  const treoAnggotaMap = new Map(treoAnggota.map((t) => [t.mahasiswaId, t]));
  const pendaftaranSaya = lobi.pendaftaran.find((p) => p.mahasiswaId === req.mahasiswaId);
  const bolehLihatKontak = lobi.status === 'FINAL' && (milikSaya || pendaftaranSaya?.status === 'ACCEPTED');
  const anggotaDiterima = anggotaAccepted.map((p) => {
    const t = treoAnggotaMap.get(p.mahasiswaId);
    let treoDominan: string | null = null;
    if (t) {
      const skor: Record<TreoDimensi, number> = {
        organizer: t.organizerNorm,
        doer: t.doerNorm,
        challenger: t.challengerNorm,
        innovator: t.innovatorNorm,
        teamBuilder: t.teamBuilderNorm,
        connector: t.connectorNorm,
      };
      treoDominan = (Object.keys(skor) as TreoDimensi[]).reduce((a, b) => (skor[b] > skor[a] ? b : a));
    }
    return {
      pendaftaranId: p.id,
      mahasiswaId: p.mahasiswaId,
      nama: p.mahasiswa.nama,
      role: p.role.namaRole,
      roleId: p.roleId,
      treoDominan,
      kontak: bolehLihatKontak ? p.mahasiswa.kontak : null,
      kontakJenis: bolehLihatKontak ? p.mahasiswa.kontakJenis : null,
    };
  });

  const pendingCount = lobi.pendaftaran.filter((p) => p.status === 'PENDING').length;
  const jumlahSetujuFinalisasi = anggotaAccepted.filter((p) => p.setujuFinalisasi).length;

  // Berapa role (dari yang ditentukan pembuat tim) yang sudah terisi minimal 1 anggota diterima
  const roleNamaTerisi = new Set(anggotaAccepted.map((p) => p.role.namaRole));
  const totalRole = lobi.roles.length;
  const roleTerisiCount = lobi.roles.filter((r) => roleNamaTerisi.has(r.namaRole)).length;
  const roleDibutuhkan = lobi.roles.filter((r) => !roleNamaTerisi.has(r.namaRole)).map((r) => r.namaRole);

  // Affinity role saya per role terbuka (hanya kalau belum daftar & profil lengkap)
  let affinityPerRole: any[] = [];
  if (!pendaftaranSaya) {
    const profil = await ambilProfilTeknis(req.mahasiswaId!);
    if (profil) {
      affinityPerRole = lobi.roles
        .map((r) => {
          const hasil = technicalRoleAffinity(profil, toRoleInput(r, lobi.lomba.kategoriLomba));
          return {
            roleId: r.id,
            namaRole: r.namaRole,
            skorPersen: Math.round(hasil.nilaiTotal * 1000) / 10,
            breakdown: hasil.detail,
          };
        });
    }
  }

  return res.json({
    id: lobi.id,
    judul: lobi.judul,
    deskripsi: lobi.deskripsi,
    status: lobi.status,
    lomba: {
      id: lobi.lomba.id,
      judul: lobi.lomba.judul,
      maxAnggotaTim: lobi.lomba.maxAnggotaTim,
      minAnggotaTim: lobi.lomba.minAnggotaTim,
      kategoriLomba: lobi.lomba.kategoriLomba,
    },
    namaKoordinator: koordinator?.nama ?? '-',
    milikSaya,
    roles: lobi.roles.map((r) => ({ id: r.id, namaRole: r.namaRole, pengalamanReq: r.pengalamanReq, kuota: r.kuota })),
    anggota: anggotaDiterima,
    statusSaya: pendaftaranSaya?.status ?? null,
    pendaftaranIdSaya: pendaftaranSaya?.id ?? null,
    roleSaya: pendaftaranSaya?.role.namaRole ?? null,
    pendingCount,
    affinityPerRole,
    finalisasiDiinisiasi: lobi.status === 'FINALIZING' || lobi.status === 'FINAL',
    setujuFinalisasiSaya: pendaftaranSaya?.setujuFinalisasi ?? false,
    jumlahSetujuFinalisasi,
    totalAnggotaAccepted: anggotaAccepted.length,
    roleTerisiCount,
    totalRole,
    roleDibutuhkan,
    skorTim: lobi.skorTim
      ? {
          technicalRoleAffinity: lobi.skorTim.technicalRoleAffinity,
          distributedRoleCoverage: lobi.skorTim.distributedRoleCoverage,
          m: lobi.skorTim.m,
          teamFunctionAffinity: lobi.skorTim.teamFunctionAffinity,
          effectivenessScore: lobi.skorTim.effectivenessScore,
          detail: lobi.skorTim.detail,
        }
      : null,
  });
});

// Ubah nama tim & deskripsi — hanya pembuat tim, selama tim masih OPEN
router.patch('/lobi/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({ where: { id: req.params.id } });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat mengubah tim' });
  }
  if (lobi.status !== 'OPEN') {
    return res.status(409).json({ error: 'Tim sudah dalam proses/selesai finalisasi, tim tidak bisa diubah' });
  }

  const { judul, deskripsi } = req.body ?? {};
  if (judul !== undefined && !judul.toString().trim()) {
    return res.status(400).json({ error: 'Nama tim tidak boleh kosong' });
  }

  const updated = await prisma.studentLobby.update({
    where: { id: lobi.id },
    data: {
      ...(judul !== undefined ? { judul: judul.toString().trim() } : {}),
      ...(deskripsi !== undefined ? { deskripsi: deskripsi?.toString().trim() || null } : {}),
    },
  });
  return res.json({ id: updated.id, judul: updated.judul, deskripsi: updated.deskripsi });
});

// Tambah peran (role) baru yang dibuka — hanya pembuat tim, selama tim masih OPEN
router.post('/lobi/:id/roles', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({ where: { id: req.params.id }, include: { roles: true } });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat mengubah peran' });
  }
  if (lobi.status !== 'OPEN') {
    return res.status(409).json({ error: 'Tim sudah dalam proses/selesai finalisasi, peran tidak bisa diubah' });
  }

  const { namaRole, pengalamanReq, kuota } = req.body ?? {};
  if (!namaRole || !namaRole.toString().trim()) {
    return res.status(400).json({ error: 'namaRole wajib' });
  }
  const kuotaFinal = typeof kuota === 'number' && kuota >= 1 ? kuota : 1;
  const sudahTerbuka = lobi.roles.some(
    (r) => r.namaRole.toLowerCase() === namaRole.toString().trim().toLowerCase(),
  );
  if (sudahTerbuka) return res.status(409).json({ error: 'Peran tersebut sudah terbuka' });

  const role = await prisma.roleLobiTim.create({
    data: {
      lobiId: lobi.id,
      namaRole: namaRole.toString().trim(),
      pengalamanReq: typeof pengalamanReq === 'number' ? pengalamanReq : null,
      kuota: kuotaFinal,
      sisaKuota: kuotaFinal,
    },
  });
  return res.status(201).json(role);
});

// Tutup/hapus peran yang dibuka — hanya pembuat tim, selama tim masih OPEN
router.delete('/lobi/:id/roles/:roleId', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({ where: { id: req.params.id } });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat mengubah peran' });
  }
  if (lobi.status !== 'OPEN') {
    return res.status(409).json({ error: 'Tim sudah dalam proses/selesai finalisasi, peran tidak bisa diubah' });
  }

  const role = await prisma.roleLobiTim.findUnique({ where: { id: req.params.roleId } });
  if (!role || role.lobiId !== lobi.id) return res.status(404).json({ error: 'Peran tidak ditemukan pada lobi ini' });

  const jumlahPendaftar = await prisma.pendaftaranAnggota.count({ where: { roleId: role.id } });
  if (jumlahPendaftar === 0) {
    await prisma.roleLobiTim.delete({ where: { id: role.id } });
  } else {
    return res.status(409).json({ error: 'Peran ini masih memiliki anggota, tidak bisa dihapus' });
  }
  return res.json({ ok: true });
});

// Ubah peran teknis seorang anggota — hanya pembuat tim, selama tim masih OPEN
router.patch('/lobi/:id/anggota/:pendaftaranId', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({ where: { id: req.params.id }, include: { lomba: true } });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat mengubah anggota' });
  }
  if (lobi.status !== 'OPEN') {
    return res.status(409).json({ error: 'Tim sudah dalam proses/selesai finalisasi, anggota tidak bisa diubah' });
  }

  const { roleId } = req.body ?? {};
  if (!roleId) return res.status(400).json({ error: 'roleId wajib' });

  const pendaftaran = await prisma.pendaftaranAnggota.findUnique({ where: { id: req.params.pendaftaranId } });
  if (!pendaftaran || pendaftaran.lobiId !== lobi.id || pendaftaran.status !== 'ACCEPTED') {
    return res.status(404).json({ error: 'Anggota tidak ditemukan' });
  }
  if (pendaftaran.roleId === roleId) return res.json({ ok: true });

  const roleBaru = await prisma.roleLobiTim.findUnique({ where: { id: roleId } });
  if (!roleBaru || roleBaru.lobiId !== lobi.id) return res.status(404).json({ error: 'Peran tidak ditemukan pada lobi ini' });

  const profil = await ambilProfilTeknis(pendaftaran.mahasiswaId);
  const hasil = profil ? technicalRoleAffinity(profil, toRoleInput(roleBaru, lobi.lomba.kategoriLomba)) : null;

  await prisma.$transaction([
    prisma.pendaftaranAnggota.update({ where: { id: pendaftaran.id }, data: { roleId } }),
    prisma.affinityScoreRoleTeam.deleteMany({
      where: { mahasiswaId: pendaftaran.mahasiswaId, lobiId: pendaftaran.lobiId, roleId: pendaftaran.roleId },
    }),
    ...(hasil
      ? [
          prisma.affinityScoreRoleTeam.create({
            data: {
              mahasiswaId: pendaftaran.mahasiswaId,
              lobiId: pendaftaran.lobiId,
              roleId,
              nilaiTotal: hasil.nilaiTotal,
              detail: hasil.detail as any,
            },
          }),
        ]
      : []),
  ]);
  return res.json({ ok: true });
});

// Keluarkan anggota dari tim — hanya pembuat tim, selama tim masih OPEN, tidak bisa mengeluarkan diri sendiri
router.delete('/lobi/:id/anggota/:pendaftaranId', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({ where: { id: req.params.id } });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat mengeluarkan anggota' });
  }
  if (lobi.status !== 'OPEN') {
    return res.status(409).json({ error: 'Tim sudah dalam proses/selesai finalisasi, anggota tidak bisa diubah' });
  }

  const pendaftaran = await prisma.pendaftaranAnggota.findUnique({ where: { id: req.params.pendaftaranId } });
  if (!pendaftaran || pendaftaran.lobiId !== lobi.id || pendaftaran.status !== 'ACCEPTED') {
    return res.status(404).json({ error: 'Anggota tidak ditemukan' });
  }
  if (pendaftaran.mahasiswaId === lobi.koordinatorId) {
    return res.status(400).json({ error: 'Pembuat tim tidak bisa mengeluarkan diri sendiri' });
  }

  await prisma.$transaction([
    prisma.pendaftaranAnggota.update({
      where: { id: pendaftaran.id },
      data: { status: 'LEFT', dikeluarkan: true },
    }),
    prisma.affinityScoreRoleTeam.deleteMany({
      where: { mahasiswaId: pendaftaran.mahasiswaId, lobiId: pendaftaran.lobiId, roleId: pendaftaran.roleId },
    }),
  ]);
  return res.json({ ok: true });
});

// Daftar ke sebuah role dalam lobi
router.post('/lobi/:id/daftar', wajibLogin, async (req: AuthedRequest, res) => {
  const { roleId } = req.body ?? {};
  if (!roleId) return res.status(400).json({ error: 'roleId wajib' });

  const lobi = await prisma.studentLobby.findUnique({ where: { id: req.params.id }, include: { lomba: true } });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.status !== 'OPEN') return res.status(409).json({ error: 'Lobi sudah tidak menerima pendaftaran' });

  const role = await prisma.roleLobiTim.findUnique({ where: { id: roleId } });
  if (!role || role.lobiId !== req.params.id) {
    return res.status(404).json({ error: 'Role tidak ditemukan pada lobi ini' });
  }

  const jumlahAnggota = await prisma.pendaftaranAnggota.count({ where: { lobiId: lobi.id, status: 'ACCEPTED' } });
  if (jumlahAnggota >= lobi.lomba.maxAnggotaTim) {
    return res.status(409).json({ error: 'Lobi sudah penuh' });
  }

  const duplikat = await prisma.pendaftaranAnggota.findUnique({
    where: { mahasiswaId_lobiId: { mahasiswaId: req.mahasiswaId!, lobiId: req.params.id } },
  });
  if (duplikat) return res.status(409).json({ error: 'Sudah pernah mendaftar ke lobi ini' });

  const pendaftaran = await prisma.pendaftaranAnggota.create({
    data: { mahasiswaId: req.mahasiswaId!, lobiId: req.params.id, roleId, status: 'PENDING' },
  });
  return res.status(201).json(pendaftaran);
});

// Batalkan pendaftaran saya. Kalau sudah ACCEPTED, kuota dikembalikan + skor terkunci dihapus.
router.delete('/pendaftaran/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const pendaftaran = await prisma.pendaftaranAnggota.findUnique({ where: { id: req.params.id } });
  if (!pendaftaran) return res.status(404).json({ error: 'Pendaftaran tidak ditemukan' });
  if (pendaftaran.mahasiswaId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Bukan pendaftaran Anda' });
  }
  const lobiPendaftaran = await prisma.studentLobby.findUnique({
    where: { id: pendaftaran.lobiId },
    select: { status: true, koordinatorId: true },
  });
  if (lobiPendaftaran?.status !== 'OPEN') {
    return res.status(409).json({ error: 'Tim sudah dalam proses/selesai finalisasi, anggota tidak bisa diubah' });
  }

  if (lobiPendaftaran.koordinatorId === pendaftaran.mahasiswaId) {
    const anggotaLainMasihAda = await prisma.pendaftaranAnggota.count({
      where: { lobiId: pendaftaran.lobiId, status: 'ACCEPTED', id: { not: pendaftaran.id } },
    });
    if (anggotaLainMasihAda > 0) {
      return res.status(400).json({ error: 'Pembuat tim tidak bisa keluar selagi masih ada anggota lain di lobi' });
    }
    // Pembuat tim adalah anggota terakhir yang keluar — lobi otomatis dihapus
    await prisma.$transaction([
      prisma.pendaftaranAnggota.deleteMany({ where: { lobiId: pendaftaran.lobiId } }),
      prisma.affinityScoreRoleTeam.deleteMany({ where: { lobiId: pendaftaran.lobiId } }),
      prisma.teamFormationScore.deleteMany({ where: { lobiId: pendaftaran.lobiId } }),
      prisma.studentLobby.delete({ where: { id: pendaftaran.lobiId } }),
    ]);
    return res.json({ ok: true, lobiDihapus: true });
  }

  if (pendaftaran.status === 'ACCEPTED') {
    await prisma.$transaction([
      prisma.pendaftaranAnggota.update({ where: { id: pendaftaran.id }, data: { status: 'LEFT' } }),
      prisma.affinityScoreRoleTeam.deleteMany({
        where: { mahasiswaId: pendaftaran.mahasiswaId, lobiId: pendaftaran.lobiId, roleId: pendaftaran.roleId },
      }),
    ]);
  } else {
    // Membatalkan pendaftaran yang masih PENDING (belum jadi anggota) — hapus saja agar bisa mendaftar ulang nanti
    await prisma.pendaftaranAnggota.delete({ where: { id: pendaftaran.id } });
  }
  return res.json({ ok: true });
});

// Tab "Tim Saya" — lobi yang saya koordinatori atau saya anggota (diterima/pernah keluar) di dalamnya
router.get('/saya', wajibLogin, async (req: AuthedRequest, res) => {
  const [dikoordinatori, sebagaiAnggota] = await Promise.all([
    prisma.studentLobby.findMany({
      where: { koordinatorId: req.mahasiswaId! },
      include: { lomba: true, roles: true, pendaftaran: { where: { status: { in: ['ACCEPTED', 'PENDING'] } } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.pendaftaranAnggota.findMany({
      where: { mahasiswaId: req.mahasiswaId!, status: { in: ['ACCEPTED', 'LEFT'] } },
      include: {
        role: true,
        lobi: { include: { lomba: true, roles: true, pendaftaran: { where: { status: 'ACCEPTED' } } } },
      },
    }),
  ]);

  const map = new Map<string, any>();
  for (const l of dikoordinatori) {
    const accepted = l.pendaftaran.filter((p: { status: string }) => p.status === 'ACCEPTED');
    const pending = l.pendaftaran.filter((p: { status: string }) => p.status === 'PENDING');
    map.set(l.id, {
      lobi: l,
      peranSaya: 'Koordinator',
      statusSaya: 'ACCEPTED',
      dikeluarkan: false,
      jumlahAnggota: accepted.length,
      pendingCount: pending.length,
      roleSaya: null,
    });
  }
  for (const p of sebagaiAnggota) {
    if (!map.has(p.lobi.id)) {
      map.set(p.lobi.id, {
        lobi: p.lobi,
        peranSaya: 'Anggota',
        statusSaya: p.status,
        dikeluarkan: p.dikeluarkan,
        jumlahAnggota: p.lobi.pendaftaran.length,
        pendingCount: 0,
        roleSaya: p.role.namaRole,
      });
    }
  }

  const out = Array.from(map.values()).map(
    ({ lobi, peranSaya, statusSaya, dikeluarkan, jumlahAnggota, pendingCount, roleSaya }) => ({
      id: lobi.id,
      judul: lobi.judul,
      status: lobi.status,
      namaLomba: lobi.lomba.judul,
      kategoriLomba: Array.isArray(lobi.lomba.kategoriLomba) ? lobi.lomba.kategoriLomba[0] : lobi.lomba.kategoriLomba,
      peranSaya,
      statusSaya,
      dikeluarkan,
      roleSaya,
      jumlahAnggota,
      pendingCount,
      totalKuota: lobi.roles.reduce((s: number, r: any) => s + r.kuota, 0),
      rolesTerbuka: lobi.roles.map((r: any) => r.namaRole),
    })
  );
  return res.json(out);
});

// Riwayat pengajuan saya — HANYA pendaftaran sungguhan (PENDING/ACCEPTED/REJECTED) ke role
// tim orang lain. Baris keanggotaan otomatis milik pembuat lobi (koordinator) dan status LEFT
// (keluar/dikeluarkan, riwayatnya sudah ada di tab "Tim Saya") sengaja tidak ikut ditampilkan
// di sini, supaya label yang muncul di halaman "Riwayat Pengajuan" konsisten hanya 3: Menunggu/Diterima/Ditolak.
router.get('/pendaftaran-saya', wajibLogin, async (req: AuthedRequest, res) => {
  const daftar = await prisma.pendaftaranAnggota.findMany({
    where: {
      mahasiswaId: req.mahasiswaId!,
      status: { in: ['PENDING', 'ACCEPTED', 'REJECTED'] },
      lobi: { koordinatorId: { not: req.mahasiswaId! } },
    },
    include: { lobi: { include: { lomba: true } }, role: true },
    orderBy: { updatedAt: 'desc' },
  });

  const out = daftar.map((p) => ({
    id: p.id,
    lobiId: p.lobiId,
    judul: p.lobi.judul,
    namaLomba: p.lobi.lomba.judul,
    kategoriLomba: Array.isArray(p.lobi.lomba.kategoriLomba)
      ? p.lobi.lomba.kategoriLomba[0]
      : p.lobi.lomba.kategoriLomba,
    roleNama: p.role.namaRole,
    status: p.status,
    dikeluarkan: p.dikeluarkan,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
  }));
  return res.json(out);
});

// List pendaftar (hanya pembuat tim) dengan skor affinity dihitung ulang live
router.get('/lobi/:id/pendaftar', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({
    where: { id: req.params.id },
    include: { lomba: true, roles: true },
  });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat melihat pendaftar' });
  }

  const pendaftar = await prisma.pendaftaranAnggota.findMany({
    where: { lobiId: req.params.id, mahasiswaId: { not: lobi.koordinatorId } },
    include: { mahasiswa: { select: { id: true, nama: true, email: true, institusi: true, jurusan: true } }, role: true },
    orderBy: { createdAt: 'asc' },
  });

  const treoSemua = await prisma.treoProfil.findMany({
    where: { mahasiswaId: { in: pendaftar.map((p) => p.mahasiswaId) } },
  });
  const treoMap = new Map(treoSemua.map((t) => [t.mahasiswaId, t]));

  const out = [];
  for (const p of pendaftar) {
    const profil = await ambilProfilTeknis(p.mahasiswaId);
    const skorPersen = profil
      ? Math.round(technicalRoleAffinity(profil, toRoleInput(p.role, lobi.lomba.kategoriLomba)).nilaiTotal * 1000) / 10
      : null;

    let treoDominan: string | null = null;
    const t = treoMap.get(p.mahasiswaId);
    if (t) {
      const skor: Record<TreoDimensi, number> = {
        organizer: t.organizerNorm,
        doer: t.doerNorm,
        challenger: t.challengerNorm,
        innovator: t.innovatorNorm,
        teamBuilder: t.teamBuilderNorm,
        connector: t.connectorNorm,
      };
      treoDominan = (Object.keys(skor) as TreoDimensi[]).reduce((a, b) => (skor[b] > skor[a] ? b : a));
    }

    out.push({
      pendaftaranId: p.id,
      mahasiswa: p.mahasiswa,
      role: p.role.namaRole,
      roleId: p.roleId,
      status: p.status,
      skorPersen,
      treoDominan,
    });
  }
  return res.json(out);
});

// Terima/tolak pendaftar — hanya pembuat tim. Saat diterima, skor role dikunci (AffinityScoreRoleTeam).
router.patch('/pendaftaran/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const { keputusan } = req.body ?? {};
  if (keputusan !== 'ACCEPTED' && keputusan !== 'REJECTED') {
    return res.status(400).json({ error: 'keputusan harus ACCEPTED atau REJECTED' });
  }

  const pendaftaran = await prisma.pendaftaranAnggota.findUnique({
    where: { id: req.params.id },
    include: { lobi: { include: { lomba: true } }, role: true, mahasiswa: true },
  });
  if (!pendaftaran) return res.status(404).json({ error: 'Pendaftaran tidak ditemukan' });
  if (pendaftaran.lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat memproses' });
  }
  if (pendaftaran.status !== 'PENDING') {
    return res.status(409).json({ error: 'Pendaftaran sudah diproses' });
  }
  if (pendaftaran.lobi.status !== 'OPEN') {
    return res.status(409).json({ error: 'Tim sudah dalam proses/selesai finalisasi, anggota tidak bisa diubah' });
  }

  if (keputusan === 'ACCEPTED') {
    const jumlahAnggota = await prisma.pendaftaranAnggota.count({
      where: { lobiId: pendaftaran.lobiId, status: 'ACCEPTED' },
    });
    if (jumlahAnggota >= pendaftaran.lobi.lomba.maxAnggotaTim) {
      return res.status(409).json({ error: 'Lobi sudah penuh' });
    }
    const profil = await ambilProfilTeknis(pendaftaran.mahasiswaId);
    const hasil = profil
      ? technicalRoleAffinity(profil, toRoleInput(pendaftaran.role, pendaftaran.lobi.lomba.kategoriLomba))
      : null;

    await prisma.$transaction([
      prisma.pendaftaranAnggota.update({ where: { id: pendaftaran.id }, data: { status: 'ACCEPTED' } }),
      ...(hasil
        ? [
            prisma.affinityScoreRoleTeam.upsert({
              where: {
                mahasiswaId_lobiId_roleId: {
                  mahasiswaId: pendaftaran.mahasiswaId,
                  lobiId: pendaftaran.lobiId,
                  roleId: pendaftaran.roleId,
                },
              },
              create: {
                mahasiswaId: pendaftaran.mahasiswaId,
                lobiId: pendaftaran.lobiId,
                roleId: pendaftaran.roleId,
                nilaiTotal: hasil.nilaiTotal,
                detail: hasil.detail as any,
              },
              update: { nilaiTotal: hasil.nilaiTotal, detail: hasil.detail as any, timestamp: new Date() },
            }),
          ]
        : []),
    ]);
    return res.json({
      status: 'ACCEPTED',
      kontak: pendaftaran.mahasiswa.kontak ?? pendaftaran.mahasiswa.email,
      kontakJenis: pendaftaran.mahasiswa.kontak ? pendaftaran.mahasiswa.kontakJenis ?? 'EMAIL' : 'EMAIL',
    });
  }

  await prisma.pendaftaranAnggota.update({ where: { id: pendaftaran.id }, data: { status: 'REJECTED' } });
  return res.json({ status: 'REJECTED' });
});

// Inisiasi finalisasi — hanya pembuat tim. Memindahkan status OPEN -> FINALIZING, menunggu semua anggota setuju.
router.post('/lobi/:id/finalisasi/inisiasi', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({
    where: { id: req.params.id },
    include: { lomba: true, pendaftaran: { where: { status: 'ACCEPTED' } } },
  });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });
  if (lobi.koordinatorId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat tim yang dapat menginisiasi finalisasi' });
  }

  const direvert = await revertFinalisasiKedaluwarsa(lobi.id, lobi.status, lobi.waktuInisiasiFinalisasi);
  if (direvert) lobi.status = 'OPEN' as any;

  if (lobi.status !== 'OPEN') return res.status(409).json({ error: 'Lobi sudah dalam proses/selesai finalisasi' });
  if (lobi.pendaftaran.length === 0) {
    return res.status(409).json({ error: 'Minimal satu anggota diterima sebelum finalisasi' });
  }
  if (lobi.lomba.minAnggotaTim != null && lobi.pendaftaran.length < lobi.lomba.minAnggotaTim) {
    return res.status(409).json({ error: `Anggota tim belum memenuhi minimal ${lobi.lomba.minAnggotaTim} orang` });
  }

  // Pembuat tim yang menginisiasi finalisasi otomatis dianggap sudah setuju — tidak perlu menyetujui lagi/ditunggu.
  const pendaftaranKoordinator = lobi.pendaftaran.find((p) => p.mahasiswaId === lobi.koordinatorId);

  await prisma.$transaction([
    prisma.studentLobby.update({ where: { id: lobi.id }, data: { status: 'FINALIZING', waktuInisiasiFinalisasi: new Date() } }),
    ...(pendaftaranKoordinator
      ? [prisma.pendaftaranAnggota.update({ where: { id: pendaftaranKoordinator.id }, data: { setujuFinalisasi: true } })]
      : []),
  ]);
  return res.json({ status: 'FINALIZING' });
});

// Setuju finalisasi — anggota ACCEPTED menyetujui. Saat semua anggota sudah setuju, skor tim dihitung & status jadi FINAL.
router.post('/lobi/:id/finalisasi/setuju', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({
    where: { id: req.params.id },
    include: {
      lomba: true,
      roles: true,
      pendaftaran: { include: { mahasiswa: true } },
    },
  });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });

  const direvert = await revertFinalisasiKedaluwarsa(lobi.id, lobi.status, lobi.waktuInisiasiFinalisasi);
  if (direvert) {
    return res.status(409).json({ error: 'Waktu finalisasi sudah habis (1 jam) — pembuat tim perlu menginisiasi ulang' });
  }

  if (lobi.status !== 'FINALIZING') {
    return res.status(409).json({ error: 'Finalisasi belum diinisiasi oleh pembuat tim' });
  }

  const pendaftaranSaya = lobi.pendaftaran.find((p) => p.mahasiswaId === req.mahasiswaId && p.status === 'ACCEPTED');
  if (!pendaftaranSaya) {
    return res.status(403).json({ error: 'Hanya anggota tim yang diterima yang dapat menyetujui finalisasi' });
  }

  if (!pendaftaranSaya.setujuFinalisasi) {
    await prisma.pendaftaranAnggota.update({ where: { id: pendaftaranSaya.id }, data: { setujuFinalisasi: true } });
  }

  const anggotaAccepted = lobi.pendaftaran.filter((p) => p.status === 'ACCEPTED');
  const semuaSetuju = anggotaAccepted.every((p) => p.id === pendaftaranSaya.id || p.setujuFinalisasi);
  if (!semuaSetuju) {
    return res.json({ status: 'FINALIZING' });
  }

  const totalKuota = lobi.roles.reduce((s, r) => s + r.kuota, 0);

  const skorRole = await prisma.affinityScoreRoleTeam.findMany({ where: { lobiId: lobi.id } });
  const technicalRoleAffinityTeamNilai = technicalRoleAffinityTeam(
    skorRole.map((s) => s.nilaiTotal),
    totalKuota,
  );

  const treoList = await prisma.treoProfil.findMany({
    where: { mahasiswaId: { in: anggotaAccepted.map((p) => p.mahasiswaId) } },
  });
  const treoMap = new Map(treoList.map((t) => [t.mahasiswaId, t]));

  const anggotaTreo: AnggotaTreo[] = anggotaAccepted.map((p) => {
    const t = treoMap.get(p.mahasiswaId);
    const norm: Record<TreoDimensi, number> = t
      ? {
          organizer: t.organizerNorm,
          doer: t.doerNorm,
          challenger: t.challengerNorm,
          innovator: t.innovatorNorm,
          teamBuilder: t.teamBuilderNorm,
          connector: t.connectorNorm,
        }
      : { organizer: 0, doer: 0, challenger: 0, innovator: 0, teamBuilder: 0, connector: 0 };
    return { mahasiswaId: p.mahasiswaId, nama: p.mahasiswa.nama, treoNorm: norm };
  });

  const drc = distributedRoleCoverage(anggotaTreo);
  const tfa = teamFunctionAffinity(drc.coverage, drc.m, totalKuota > 0 ? totalKuota : lobi.lomba.maxAnggotaTim);
  const efektivitas = teamFormationEffectivenessScore(technicalRoleAffinityTeamNilai, tfa);

  const detail = {
    assignment: drc.assignment,
    totalKuota,
    jumlahAnggota: anggotaAccepted.length,
  };

  const skorTim = await prisma.teamFormationScore.upsert({
    where: { lobiId: lobi.id },
    create: {
      lobiId: lobi.id,
      technicalRoleAffinity: technicalRoleAffinityTeamNilai,
      distributedRoleCoverage: drc.coverage,
      m: drc.m,
      teamFunctionAffinity: tfa,
      effectivenessScore: efektivitas,
      detail: detail as any,
    },
    update: {
      technicalRoleAffinity: technicalRoleAffinityTeamNilai,
      distributedRoleCoverage: drc.coverage,
      m: drc.m,
      teamFunctionAffinity: tfa,
      effectivenessScore: efektivitas,
      detail: detail as any,
      timestamp: new Date(),
    },
  });

  await prisma.studentLobby.update({ where: { id: lobi.id }, data: { status: 'FINAL' } });

  return res.json(skorTim);
});

// Tolak finalisasi — anggota ACCEPTED menolak. Membatalkan inisiasi, status kembali OPEN, semua persetujuan direset.
router.post('/lobi/:id/finalisasi/tolak', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({
    where: { id: req.params.id },
    include: { pendaftaran: { where: { status: 'ACCEPTED' } } },
  });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });

  const direvert = await revertFinalisasiKedaluwarsa(lobi.id, lobi.status, lobi.waktuInisiasiFinalisasi);
  if (direvert) {
    return res.status(409).json({ error: 'Waktu finalisasi sudah habis (1 jam), finalisasi sudah otomatis dibatalkan' });
  }

  if (lobi.status !== 'FINALIZING') {
    return res.status(409).json({ error: 'Finalisasi belum diinisiasi oleh pembuat tim' });
  }

  const pendaftaranSaya = lobi.pendaftaran.find((p) => p.mahasiswaId === req.mahasiswaId);
  if (!pendaftaranSaya) {
    return res.status(403).json({ error: 'Hanya anggota tim yang diterima yang dapat menolak finalisasi' });
  }

  await prisma.$transaction([
    prisma.studentLobby.update({ where: { id: lobi.id }, data: { status: 'OPEN', waktuInisiasiFinalisasi: null } }),
    prisma.pendaftaranAnggota.updateMany({ where: { lobiId: lobi.id }, data: { setujuFinalisasi: false } }),
  ]);
  return res.json({ status: 'OPEN' });
});

// --- TREO ----------------------------------------------------------------------------------------

// Ambil profil TREO saya (jawaban tersimpan + status diisi)
router.get('/treo', wajibLogin, async (req: AuthedRequest, res) => {
  const profil = await prisma.treoProfil.findUnique({ where: { mahasiswaId: req.mahasiswaId! } });
  if (!profil) return res.json({ diisi: false, jawaban: null, norm: null });
  return res.json({
    diisi: profil.diisi,
    jawaban: profil.jawaban,
    norm: {
      organizer: profil.organizerNorm,
      doer: profil.doerNorm,
      challenger: profil.challengerNorm,
      innovator: profil.innovatorNorm,
      teamBuilder: profil.teamBuilderNorm,
      connector: profil.connectorNorm,
    },
  });
});

// Submit kuesioner TREO — body: { jawaban: { organizer: number[3], doer: number[3], ... } } (Likert 1..5)
router.post('/treo', wajibLogin, async (req: AuthedRequest, res) => {
  const { jawaban } = req.body ?? {};
  if (!jawaban || typeof jawaban !== 'object') {
    return res.status(400).json({ error: 'jawaban wajib' });
  }
  for (const d of TREO_DIMENSIONS) {
    const arr = jawaban[d];
    if (!Array.isArray(arr) || arr.length !== 3 || arr.some((v: any) => typeof v !== 'number' || v < 1 || v > 5)) {
      return res.status(400).json({ error: `jawaban.${d} wajib array 3 angka 1..5` });
    }
  }

  const raw: Record<TreoDimensi, number> = {} as any;
  const norm: Record<TreoDimensi, number> = {} as any;
  for (const d of TREO_DIMENSIONS) {
    const arr = jawaban[d] as number[];
    const rerata = arr.reduce((a, b) => a + b, 0) / arr.length;
    raw[d] = rerata;
    norm[d] = treoNorm(rerata);
  }

  const profil = await prisma.treoProfil.upsert({
    where: { mahasiswaId: req.mahasiswaId! },
    create: {
      mahasiswaId: req.mahasiswaId!,
      organizerRaw: raw.organizer,
      doerRaw: raw.doer,
      challengerRaw: raw.challenger,
      innovatorRaw: raw.innovator,
      teamBuilderRaw: raw.teamBuilder,
      connectorRaw: raw.connector,
      organizerNorm: norm.organizer,
      doerNorm: norm.doer,
      challengerNorm: norm.challenger,
      innovatorNorm: norm.innovator,
      teamBuilderNorm: norm.teamBuilder,
      connectorNorm: norm.connector,
      jawaban: jawaban as any,
      diisi: true,
    },
    update: {
      organizerRaw: raw.organizer,
      doerRaw: raw.doer,
      challengerRaw: raw.challenger,
      innovatorRaw: raw.innovator,
      teamBuilderRaw: raw.teamBuilder,
      connectorRaw: raw.connector,
      organizerNorm: norm.organizer,
      doerNorm: norm.doer,
      challengerNorm: norm.challenger,
      innovatorNorm: norm.innovator,
      teamBuilderNorm: norm.teamBuilder,
      connectorNorm: norm.connector,
      jawaban: jawaban as any,
      diisi: true,
    },
  });
  return res.json({ ok: true, norm: { organizer: profil.organizerNorm, doer: profil.doerNorm, challenger: profil.challengerNorm, innovator: profil.innovatorNorm, teamBuilder: profil.teamBuilderNorm, connector: profil.connectorNorm } });
});

// Breakdown DistributedRoleCoverage tim (dari TeamFormationScore tersimpan, kalau sudah final)
// atau preview live dari anggota diterima saat ini (kalau masih OPEN).
router.get('/lobi/:id/treo-tim', wajibLogin, async (req: AuthedRequest, res) => {
  const lobi = await prisma.studentLobby.findUnique({
    where: { id: req.params.id },
    include: {
      lomba: true,
      skorTim: true,
      roles: true,
      pendaftaran: { where: { status: 'ACCEPTED' }, include: { mahasiswa: true, role: true } },
    },
  });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });

  const rolesTerbuka = lobi.roles.map((r: { namaRole: string }) => r.namaRole);

  const treoList = await prisma.treoProfil.findMany({
    where: { mahasiswaId: { in: lobi.pendaftaran.map((p: { mahasiswaId: string }) => p.mahasiswaId) } },
  });
  const treoMap = new Map(treoList.map((t) => [t.mahasiswaId, t]));
  const normList: Record<TreoDimensi, number>[] = lobi.pendaftaran.map((p: { mahasiswaId: string }) => {
    const t = treoMap.get(p.mahasiswaId);
    return t
      ? {
          organizer: t.organizerNorm,
          doer: t.doerNorm,
          challenger: t.challengerNorm,
          innovator: t.innovatorNorm,
          teamBuilder: t.teamBuilderNorm,
          connector: t.connectorNorm,
        }
      : { organizer: 0, doer: 0, challenger: 0, innovator: 0, teamBuilder: 0, connector: 0 };
  });
  const dimensiTerbuka = dimensiTerbukaDariAnggota(normList);

  if (lobi.skorTim) {
    return res.json({
      final: true,
      coverage: lobi.skorTim.distributedRoleCoverage,
      m: lobi.skorTim.m,
      teamFunctionAffinity: lobi.skorTim.teamFunctionAffinity,
      technicalRoleAffinityTeam: lobi.skorTim.technicalRoleAffinity,
      effectivenessScore: lobi.skorTim.effectivenessScore,
      assignment: (lobi.skorTim.detail as any)?.assignment ?? null,
      rolesTerbuka,
      dimensiTerbuka,
    });
  }

  const anggotaTreo: AnggotaTreo[] = lobi.pendaftaran.map((p: { mahasiswaId: string; mahasiswa: { nama: string } }, i: number) => ({
    mahasiswaId: p.mahasiswaId,
    nama: p.mahasiswa.nama,
    treoNorm: normList[i],
  }));
  const drc = distributedRoleCoverage(anggotaTreo);
  const totalKuota = lobi.roles.reduce((s: number, r: { kuota: number }) => s + r.kuota, 0);
  const tfa = teamFunctionAffinity(drc.coverage, drc.m, totalKuota > 0 ? totalKuota : lobi.lomba.maxAnggotaTim);

  const skorAnggota: number[] = [];
  for (const p of lobi.pendaftaran) {
    const profil = await ambilProfilTeknis(p.mahasiswaId);
    if (profil) {
      skorAnggota.push(technicalRoleAffinity(profil, toRoleInput(p.role, lobi.lomba.kategoriLomba)).nilaiTotal);
    }
  }
  const traTeam = totalKuota > 0 ? technicalRoleAffinityTeam(skorAnggota, totalKuota) : 0;
  const effectiveness = teamFormationEffectivenessScore(traTeam, tfa);

  return res.json({
    final: false,
    coverage: drc.coverage,
    m: drc.m,
    teamFunctionAffinity: tfa,
    technicalRoleAffinityTeam: traTeam,
    effectivenessScore: effectiveness,
    assignment: drc.assignment,
    rolesTerbuka,
    dimensiTerbuka,
  });
});

// --- Diskusi Tim -----------------------------------------------------------------------------------

router.get('/lobi/:id/diskusi', wajibLogin, async (req: AuthedRequest, res) => {
  const pesan = await prisma.diskusiTim.findMany({ where: { lobiId: req.params.id }, orderBy: { createdAt: 'asc' } });
  const mahasiswaIds = Array.from(new Set(pesan.map((p) => p.mahasiswaId)));
  const orang = await prisma.mahasiswa.findMany({ where: { id: { in: mahasiswaIds } }, select: { id: true, nama: true } });
  const namaMap = new Map(orang.map((o) => [o.id, o.nama]));
  return res.json(
    pesan.map((p) => ({ id: p.id, mahasiswaId: p.mahasiswaId, nama: namaMap.get(p.mahasiswaId) ?? '-', pesan: p.pesan, createdAt: p.createdAt })),
  );
});

router.post('/lobi/:id/diskusi', wajibLogin, async (req: AuthedRequest, res) => {
  const { pesan } = req.body ?? {};
  if (!pesan || typeof pesan !== 'string' || !pesan.trim()) {
    return res.status(400).json({ error: 'pesan wajib' });
  }
  const lobi = await prisma.studentLobby.findUnique({ where: { id: req.params.id } });
  if (!lobi) return res.status(404).json({ error: 'Lobi tidak ditemukan' });

  const anggota = await prisma.pendaftaranAnggota.findUnique({
    where: { mahasiswaId_lobiId: { mahasiswaId: req.mahasiswaId!, lobiId: req.params.id } },
  });
  const bolehKirim = lobi.koordinatorId === req.mahasiswaId || anggota?.status === 'ACCEPTED';
  if (!bolehKirim) return res.status(403).json({ error: 'Hanya pembuat tim/anggota tim yang dapat mengirim pesan' });

  const dibuat = await prisma.diskusiTim.create({
    data: { lobiId: req.params.id, mahasiswaId: req.mahasiswaId!, pesan: pesan.trim() },
  });
  return res.status(201).json(dibuat);
});

export default router;

import { Router } from 'express';
import { prisma } from '../prisma';
import { wajibLogin, AuthedRequest } from '../auth';
import {
  hitungAffinity,
  isEligible,
  badge,
  FEED_THRESHOLD,
  ProfilMhs,
  ProjectInput,
} from '../affinity';

// Modul People-to-Project (Faishal). UC05–UC11.
const router = Router();

router.get('/health', (_req, res) => res.json({ module: 'people-to-project', ok: true }));

// [DEMO/TANPA-DB] Hitung Affinity Score langsung dari body. Tidak menyentuh database.
// Berguna untuk memverifikasi algoritma (Bab IV.3) tanpa setup PostgreSQL.
// Body: { profil: ProfilMhs, project: ProjectInput }
router.post('/hitung', (req, res) => {
  const { profil, project } = req.body ?? {};
  if (!profil || !project) {
    return res.status(400).json({ error: 'body harus berisi { profil, project }' });
  }
  const eligible = isEligible(profil as ProfilMhs, project as ProjectInput);
  const hasil = hitungAffinity(profil as ProfilMhs, project as ProjectInput);
  return res.json({
    eligible,
    skorPersen: Math.round(hasil.affinityScore * 1000) / 10,
    badge: badge(hasil.affinityScore),
    skorAlgo1: hasil.skorAlgo1,
    skorAlgo2: hasil.skorAlgo2,
    breakdown: hasil.breakdown,
  });
});

function ambilProjectAktif() {
  return prisma.project.findMany({
    where: { status: 'ACTIVE' },
    include: { roles: true },
  });
}

// Bangun input Affinity Engine dari project + role-nya.
function toProjectInput(p: { roles: { namaRole: string; skillDicari: string[] }[]; pengalamanReq: number; minatTag: string[]; gayaKerja: string | null; jadwalSlot: string[] }): ProjectInput {
  return {
    skillDicari: Array.from(new Set(p.roles.flatMap((r) => r.skillDicari))),
    pengalamanReq: p.pengalamanReq,
    minatTag: p.minatTag,
    gayaKerja: p.gayaKerja ?? '',
    rolesDibutuhkan: p.roles.map((r) => r.namaRole),
    jadwalSlot: p.jadwalSlot,
  };
}

async function ambilProfil(mahasiswaId: string): Promise<ProfilMhs | null> {
  const profil = await prisma.profil.findUnique({ where: { mahasiswaId } });
  if (!profil || !profil.lengkap) return null;
  return {
    skill: profil.skill,
    pengalaman: profil.pengalaman,
    minatTag: profil.minatTag,
    gayaKerja: profil.gayaKerja,
    preferensiPeran: profil.preferensiPeran,
    ketersediaanWaktu: profil.ketersediaanWaktu,
  };
}

// UC09 Membuat kegiatan kolaboratif (+ minimal satu role)
router.post('/projects', wajibLogin, async (req: AuthedRequest, res) => {
  const {
    judul,
    deskripsi,
    kategori,
    timeline,
    jadwalSlot,
    pengalamanReq,
    minatTag,
    gayaKerja,
    roles,
  } = req.body ?? {};

  if (!judul || !deskripsi || !Array.isArray(roles) || roles.length === 0) {
    return res.status(400).json({ error: 'judul, deskripsi, dan minimal satu role wajib' });
  }
  for (const r of roles) {
    if (!r.namaRole || typeof r.kuota !== 'number' || r.kuota < 1) {
      return res.status(400).json({ error: 'setiap role wajib namaRole dan kuota >= 1' });
    }
  }

  const project = await prisma.project.create({
    data: {
      judul,
      deskripsi,
      kategori: kategori ?? null,
      timeline: timeline ?? null,
      jadwalSlot: Array.isArray(jadwalSlot) ? jadwalSlot : [],
      pengalamanReq: typeof pengalamanReq === 'number' ? pengalamanReq : 1,
      minatTag: Array.isArray(minatTag) ? minatTag : [],
      gayaKerja: gayaKerja ?? null,
      pembuatId: req.mahasiswaId!,
      roles: {
        create: roles.map((r: any) => ({
          namaRole: r.namaRole,
          skillDicari: Array.isArray(r.skillDicari) ? r.skillDicari : [],
          kuota: r.kuota,
          sisaKuota: r.kuota,
        })),
      },
    },
    include: { roles: true },
  });
  return res.status(201).json(project);
});

// UC05 + UC06 Jalankan pencocokan lalu tampilkan feed rekomendasi.
// Affinity dihitung untuk seluruh project aktif yang lolos hard constraint,
// disimpan ke AffinityScoreProject, lalu di-feed (>= threshold, urut desc).
router.get('/feed', wajibLogin, async (req: AuthedRequest, res) => {
  const profil = await ambilProfil(req.mahasiswaId!);
  if (!profil) return res.status(409).json({ error: 'Profil belum lengkap', feed: [] });

  const projects = await ambilProjectAktif();
  const feed: any[] = [];

  for (const p of projects) {
    if (p.pembuatId === req.mahasiswaId) continue; // jangan rekomendasikan project sendiri
    const input = toProjectInput(p);
    if (!isEligible(profil, input)) continue; // UC05 hard constraint

    const hasil = hitungAffinity(profil, input);

    // UC05 simpan skor (upsert agar idempoten)
    await prisma.affinityScoreProject.upsert({
      where: { mahasiswaId_projectId: { mahasiswaId: req.mahasiswaId!, projectId: p.id } },
      create: {
        mahasiswaId: req.mahasiswaId!,
        projectId: p.id,
        nilaiTotal: hasil.affinityScore,
        detail: hasil.breakdown as any,
      },
      update: { nilaiTotal: hasil.affinityScore, detail: hasil.breakdown as any, timestamp: new Date() },
    });

    if (hasil.affinityScore >= FEED_THRESHOLD) {
      feed.push({
        projectId: p.id,
        judul: p.judul,
        kategori: p.kategori,
        skorPersen: Math.round(hasil.affinityScore * 1000) / 10,
        badge: badge(hasil.affinityScore),
      });
    }
  }

  feed.sort((a, b) => b.skorPersen - a.skorPersen); // UC06 urut desc
  return res.json({ feed });
});

// UC07 Detail kegiatan + skor kecocokan & breakdown untuk mahasiswa ini
router.get('/projects/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const project = await prisma.project.findUnique({
    where: { id: req.params.id },
    include: { roles: true },
  });
  if (!project) return res.status(404).json({ error: 'Project tidak ditemukan' });

  const profil = await ambilProfil(req.mahasiswaId!);
  let affinity = null;
  if (profil) {
    const hasil = hitungAffinity(profil, toProjectInput(project));
    affinity = {
      skorPersen: Math.round(hasil.affinityScore * 1000) / 10,
      badge: badge(hasil.affinityScore),
      breakdown: hasil.breakdown,
    };
  }

  const kuotaPenuh = project.roles.every((r) => r.sisaKuota <= 0);
  return res.json({ ...project, affinity, kuotaPenuh });
});

// UC08 Mendaftar ke role di kegiatan
router.post('/projects/:id/daftar', wajibLogin, async (req: AuthedRequest, res) => {
  const { roleId } = req.body ?? {};
  if (!roleId) return res.status(400).json({ error: 'roleId wajib' });

  const role = await prisma.kebutuhanRole.findUnique({ where: { id: roleId } });
  if (!role || role.projectId !== req.params.id) {
    return res.status(404).json({ error: 'Role tidak ditemukan pada project ini' });
  }
  if (role.sisaKuota <= 0) return res.status(409).json({ error: 'Kuota role sudah penuh' });

  const duplikat = await prisma.pendaftaranProject.findUnique({
    where: { mahasiswaId_projectId: { mahasiswaId: req.mahasiswaId!, projectId: req.params.id } },
  });
  if (duplikat) return res.status(409).json({ error: 'Sudah pernah mendaftar ke kegiatan ini' });

  const pendaftaran = await prisma.pendaftaranProject.create({
    data: {
      mahasiswaId: req.mahasiswaId!,
      projectId: req.params.id,
      roleId,
      status: 'PENDING',
    },
  });
  return res.status(201).json(pendaftaran);
});

// UC10 List pendaftar (hanya pembuat kegiatan)
router.get('/projects/:id/pendaftar', wajibLogin, async (req: AuthedRequest, res) => {
  const project = await prisma.project.findUnique({ where: { id: req.params.id } });
  if (!project) return res.status(404).json({ error: 'Project tidak ditemukan' });
  if (project.pembuatId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat kegiatan yang dapat melihat pendaftar' });
  }

  const pendaftar = await prisma.pendaftaranProject.findMany({
    where: { projectId: req.params.id },
    include: { mahasiswa: { select: { id: true, nama: true, email: true } }, role: true },
  });

  // Lampirkan skor kecocokan tiap pendaftar (jika sudah dihitung)
  const skor = await prisma.affinityScoreProject.findMany({
    where: { projectId: req.params.id },
  });
  const skorMap = new Map(skor.map((s) => [s.mahasiswaId, s.nilaiTotal]));

  return res.json(
    pendaftar.map((p) => ({
      pendaftaranId: p.id,
      mahasiswa: p.mahasiswa,
      role: p.role.namaRole,
      status: p.status,
      skorPersen: skorMap.has(p.mahasiswaId)
        ? Math.round((skorMap.get(p.mahasiswaId) as number) * 1000) / 10
        : null,
    })),
  );
});

// UC11 Memproses pendaftaran (terima/tolak) — hanya pembuat kegiatan
router.patch('/pendaftaran/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const { keputusan } = req.body ?? {}; // "ACCEPTED" | "REJECTED"
  if (keputusan !== 'ACCEPTED' && keputusan !== 'REJECTED') {
    return res.status(400).json({ error: 'keputusan harus ACCEPTED atau REJECTED' });
  }

  const pendaftaran = await prisma.pendaftaranProject.findUnique({
    where: { id: req.params.id },
    include: { project: true, role: true, mahasiswa: true },
  });
  if (!pendaftaran) return res.status(404).json({ error: 'Pendaftaran tidak ditemukan' });
  if (pendaftaran.project.pembuatId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat kegiatan yang dapat memproses' });
  }
  if (pendaftaran.status !== 'PENDING') {
    return res.status(409).json({ error: 'Pendaftaran sudah diproses' });
  }

  if (keputusan === 'ACCEPTED') {
    if (pendaftaran.role.sisaKuota <= 0) {
      return res.status(409).json({ error: 'Kuota role sudah penuh' });
    }
    // transaksi: update status + kurangi kuota
    await prisma.$transaction([
      prisma.pendaftaranProject.update({
        where: { id: pendaftaran.id },
        data: { status: 'ACCEPTED' },
      }),
      prisma.kebutuhanRole.update({
        where: { id: pendaftaran.roleId },
        data: { sisaKuota: { decrement: 1 } },
      }),
    ]);
    return res.json({
      status: 'ACCEPTED',
      kontak: pendaftaran.mahasiswa.kontak ?? pendaftaran.mahasiswa.email, // kontak ditampilkan saat diterima
    });
  }

  await prisma.pendaftaranProject.update({
    where: { id: pendaftaran.id },
    data: { status: 'REJECTED' },
  });
  return res.json({ status: 'REJECTED' });
});

export default router;

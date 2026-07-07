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
} from '../affinityProject';

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
    timeline,
    durasi,
    format,
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
      timeline: timeline ?? null,
      durasi: durasi ?? null,
      format: format ?? null,
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

  // project yang sudah didaftari mahasiswa ini → jangan tampilkan lagi di rekomendasi
  const sudahDaftar = await prisma.pendaftaranProject.findMany({
    where: { mahasiswaId: req.mahasiswaId! },
    select: { projectId: true },
  });
  const daftarSet = new Set(sudahDaftar.map((d) => d.projectId));

  for (const p of projects) {
    if (p.pembuatId === req.mahasiswaId) continue; // jangan rekomendasikan project sendiri
    const input = toProjectInput(p);
    if (!isEligible(profil, input)) continue; // UC05 hard constraint

    const hasil = hitungAffinity(profil, input);

    // UC05 simpan skor (upsert agar idempoten) — tetap dihitung walau sudah terdaftar
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

    if (daftarSet.has(p.id)) continue; // sudah terdaftar → keluar dari feed rekomendasi

    const slotTerbuka = p.roles.reduce((s, r) => s + r.sisaKuota, 0);
    if (slotTerbuka <= 0) continue; // kuota penuh → keluar dari feed rekomendasi

    if (hasil.affinityScore >= FEED_THRESHOLD) {
      feed.push({
        projectId: p.id,
        judul: p.judul,
        timeline: p.timeline,
        slotTerbuka,
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
    include: {
      roles: true,
      pembuat: { select: { nama: true, jurusan: true, angkatan: true, kontak: true, kontakJenis: true, email: true } },
    },
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

  // status pendaftaran si pemanggil (untuk tombol "Daftar" vs "Terdaftar · <role>")
  const pendaftaranSaya = await prisma.pendaftaranProject.findUnique({
    where: { mahasiswaId_projectId: { mahasiswaId: req.mahasiswaId!, projectId: req.params.id } },
    include: { role: true },
  });

  // Kontak pembuat dibuka ke pendaftar hanya jika sudah DITERIMA (mutual, seperti sisi sebaliknya).
  const { pembuat, ...projectData } = project;
  const diterima = pendaftaranSaya?.status === 'ACCEPTED';

  return res.json({
    ...projectData,
    affinity,
    kuotaPenuh,
    sudahDaftar: !!pendaftaranSaya,
    pendaftaranIdSaya: pendaftaranSaya?.id ?? null,
    roleSaya: pendaftaranSaya?.role.namaRole ?? null,
    statusSaya: pendaftaranSaya?.status ?? null,
    milikSaya: project.pembuatId === req.mahasiswaId,
    namaPembuat: pembuat.nama,
    jurusanPembuat: pembuat.jurusan,
    angkatanPembuat: pembuat.angkatan,
    kontakPembuat: diterima ? (pembuat.kontak ?? pembuat.email) : null,
    kontakJenisPembuat: diterima ? (pembuat.kontak ? pembuat.kontakJenis ?? 'EMAIL' : 'EMAIL') : null,
  });
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

// Batalkan pendaftaran (oleh mahasiswa yang mendaftar). Jika sudah ACCEPTED,
// kuota role dikembalikan karena slot yang terpakai jadi bebas lagi.
router.delete('/pendaftaran/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const pendaftaran = await prisma.pendaftaranProject.findUnique({ where: { id: req.params.id } });
  if (!pendaftaran) return res.status(404).json({ error: 'Pendaftaran tidak ditemukan' });
  if (pendaftaran.mahasiswaId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Bukan pendaftaran Anda' });
  }

  if (pendaftaran.status === 'ACCEPTED') {
    await prisma.$transaction([
      prisma.pendaftaranProject.delete({ where: { id: pendaftaran.id } }),
      prisma.kebutuhanRole.update({
        where: { id: pendaftaran.roleId },
        data: { sisaKuota: { increment: 1 } },
      }),
    ]);
  } else {
    await prisma.pendaftaranProject.delete({ where: { id: pendaftaran.id } });
  }
  return res.json({ ok: true });
});

// Tab "Terdaftar" — daftar project yang si mahasiswa daftar (semua status)
router.get('/terdaftar', wajibLogin, async (req: AuthedRequest, res) => {
  const rows = await prisma.pendaftaranProject.findMany({
    where: { mahasiswaId: req.mahasiswaId! },
    include: {
      project: { include: { pembuat: { select: { nama: true, kontak: true, kontakJenis: true, email: true } } } },
      role: true,
    },
    orderBy: { tanggal: 'desc' },
  });
  return res.json(
    rows.map((r) => ({
      pendaftaranId: r.id,
      projectId: r.projectId,
      judul: r.project.judul,
      role: r.role.namaRole,
      status: r.status,
      namaPembuat: r.project.pembuat.nama,
      // kontak hanya dibuka setelah diterima, sama seperti detail proyek
      kontakPembuat:
        r.status === 'ACCEPTED' ? r.project.pembuat.kontak ?? r.project.pembuat.email : null,
      kontakJenisPembuat:
        r.status === 'ACCEPTED' ? (r.project.pembuat.kontak ? r.project.pembuat.kontakJenis ?? 'EMAIL' : 'EMAIL') : null,
    })),
  );
});

// Tab "Proyek Saya" — project yang dibuat si mahasiswa + ringkasan pendaftar/kuota
router.get('/saya', wajibLogin, async (req: AuthedRequest, res) => {
  const projects = await prisma.project.findMany({
    where: { pembuatId: req.mahasiswaId! },
    include: { roles: true, pendaftaran: true },
    orderBy: { createdAt: 'desc' },
  });
  return res.json(
    projects.map((p) => {
      const totalKuota = p.roles.reduce((s, r) => s + r.kuota, 0);
      const sisaKuota = p.roles.reduce((s, r) => s + r.sisaKuota, 0);
      return {
        projectId: p.id,
        judul: p.judul,
        totalPendaftar: p.pendaftaran.length,
        pendingBaru: p.pendaftaran.filter((x) => x.status === 'PENDING').length,
        terisi: totalKuota - sisaKuota,
        totalKuota,
      };
    }),
  );
});

// Edit proyek yang sudah dibuat (hanya pembuat). Role dicocokkan lewat namaRole
// (satu project cuma boleh punya 1 role per kategori — sama seperti aturan saat Buat Proyek):
// - namaRole yang sudah ada -> kuota/skillDicari di-update (kuota tidak boleh kurang dari yang sudah terisi)
// - namaRole baru -> role baru dibuat
// - namaRole lama yang tidak dikirim lagi -> dihapus, TAPI ditolak kalau sudah ada pendaftar sama sekali
router.put('/projects/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const project = await prisma.project.findUnique({
    where: { id: req.params.id },
    include: { roles: { include: { pendaftaran: true } } },
  });
  if (!project) return res.status(404).json({ error: 'Project tidak ditemukan' });
  if (project.pembuatId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat kegiatan yang dapat mengedit' });
  }

  const {
    judul,
    deskripsi,
    timeline,
    durasi,
    format,
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

  const namaRoleBaru = new Set(roles.map((r: any) => r.namaRole));
  const dihapus = project.roles.filter((r) => !namaRoleBaru.has(r.namaRole));
  const rolePunyaPendaftar = dihapus.find((r) => r.pendaftaran.length > 0);
  if (rolePunyaPendaftar) {
    return res.status(409).json({
      error: `Tidak bisa menghapus role "${rolePunyaPendaftar.namaRole}" karena sudah ada pendaftar`,
    });
  }

  for (const r of roles) {
    const existing = project.roles.find((x) => x.namaRole === r.namaRole);
    if (existing) {
      const terisi = existing.kuota - existing.sisaKuota;
      if (r.kuota < terisi) {
        return res.status(409).json({
          error: `Kuota "${r.namaRole}" tidak boleh kurang dari ${terisi} (sudah terisi)`,
        });
      }
    }
  }

  await prisma.$transaction([
    prisma.project.update({
      where: { id: req.params.id },
      data: {
        judul,
        deskripsi,
        timeline: timeline ?? null,
        durasi: durasi ?? null,
        format: format ?? null,
        jadwalSlot: Array.isArray(jadwalSlot) ? jadwalSlot : [],
        pengalamanReq: typeof pengalamanReq === 'number' ? pengalamanReq : 1,
        minatTag: Array.isArray(minatTag) ? minatTag : [],
        gayaKerja: gayaKerja ?? null,
      },
    }),
    ...dihapus.map((r) => prisma.kebutuhanRole.delete({ where: { id: r.id } })),
    ...roles.map((r: any) => {
      const existing = project.roles.find((x) => x.namaRole === r.namaRole);
      const skillDicari = Array.isArray(r.skillDicari) ? r.skillDicari : [];
      if (existing) {
        const terisi = existing.kuota - existing.sisaKuota;
        return prisma.kebutuhanRole.update({
          where: { id: existing.id },
          data: { skillDicari, kuota: r.kuota, sisaKuota: r.kuota - terisi },
        });
      }
      return prisma.kebutuhanRole.create({
        data: { projectId: req.params.id, namaRole: r.namaRole, skillDicari, kuota: r.kuota, sisaKuota: r.kuota },
      });
    }),
  ]);

  const updated = await prisma.project.findUnique({ where: { id: req.params.id }, include: { roles: true } });
  return res.json(updated);
});

// Hapus proyek (hanya pembuat). Menghapus juga pendaftaran & skor affinity terkait,
// karena relasi itu tidak cascade otomatis (KebutuhanRole tetap cascade lewat schema).
router.delete('/projects/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const project = await prisma.project.findUnique({ where: { id: req.params.id } });
  if (!project) return res.status(404).json({ error: 'Project tidak ditemukan' });
  if (project.pembuatId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat kegiatan yang dapat menghapus' });
  }

  await prisma.$transaction([
    prisma.affinityScoreProject.deleteMany({ where: { projectId: req.params.id } }),
    prisma.pendaftaranProject.deleteMany({ where: { projectId: req.params.id } }),
    prisma.project.delete({ where: { id: req.params.id } }), // cascade ke KebutuhanRole
  ]);
  return res.json({ ok: true });
});

// UC10 List pendaftar (hanya pembuat kegiatan)
router.get('/projects/:id/pendaftar', wajibLogin, async (req: AuthedRequest, res) => {
  const project = await prisma.project.findUnique({ where: { id: req.params.id }, include: { roles: true } });
  if (!project) return res.status(404).json({ error: 'Project tidak ditemukan' });
  if (project.pembuatId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat kegiatan yang dapat melihat pendaftar' });
  }

  const pendaftar = await prisma.pendaftaranProject.findMany({
    where: { projectId: req.params.id },
    include: {
      mahasiswa: { select: { id: true, nama: true, email: true, jurusan: true, angkatan: true } },
      role: true,
    },
  });

  // Skor dihitung ulang live (bukan baca dari cache AffinityScoreProject) agar selalu
  // mencerminkan profil pendaftar TERKINI, walau mereka edit profil setelah mendaftar.
  const projectInput = toProjectInput(project);
  const out = [];
  for (const p of pendaftar) {
    const profil = await ambilProfil(p.mahasiswaId);
    const skorPersen = profil ? Math.round(hitungAffinity(profil, projectInput).affinityScore * 1000) / 10 : null;
    out.push({
      pendaftaranId: p.id,
      mahasiswa: p.mahasiswa,
      role: p.role.namaRole,
      status: p.status,
      skorPersen,
    });
  }
  return res.json(out);
});

// Lihat profil lengkap satu pendaftar (khusus pembuat kegiatan) — dibuka dari Kelola Proyek
router.get('/pendaftaran/:id/profil', wajibLogin, async (req: AuthedRequest, res) => {
  const pendaftaran = await prisma.pendaftaranProject.findUnique({
    where: { id: req.params.id },
    include: {
      project: { include: { roles: true } },
      mahasiswa: {
        select: {
          nama: true,
          institusi: true,
          jurusan: true,
          angkatan: true,
          bio: true,
          kontak: true,
          kontakJenis: true,
          email: true,
        },
      },
      role: true,
    },
  });
  if (!pendaftaran) return res.status(404).json({ error: 'Pendaftaran tidak ditemukan' });
  if (pendaftaran.project.pembuatId !== req.mahasiswaId) {
    return res.status(403).json({ error: 'Hanya pembuat kegiatan yang dapat melihat profil pendaftar' });
  }

  const profil = await prisma.profil.findUnique({ where: { mahasiswaId: pendaftaran.mahasiswaId } });
  const profilMhs = await ambilProfil(pendaftaran.mahasiswaId);
  const affinity = profilMhs
    ? (() => {
        const hasil = hitungAffinity(profilMhs, toProjectInput(pendaftaran.project));
        return {
          skorPersen: Math.round(hasil.affinityScore * 1000) / 10,
          badge: badge(hasil.affinityScore),
          breakdown: hasil.breakdown,
        };
      })()
    : null;

  // Kontak pendaftar hanya dibuka ke pembuat kegiatan kalau pendaftarannya sudah DITERIMA
  // (mutual dengan sisi sebaliknya: kontak pembuat juga baru terbuka ke pendaftar setelah diterima).
  const diterima = pendaftaran.status === 'ACCEPTED';

  return res.json({
    mahasiswaId: pendaftaran.mahasiswaId,
    nama: pendaftaran.mahasiswa.nama,
    institusi: pendaftaran.mahasiswa.institusi,
    jurusan: pendaftaran.mahasiswa.jurusan,
    angkatan: pendaftaran.mahasiswa.angkatan,
    bio: pendaftaran.mahasiswa.bio,
    role: pendaftaran.role.namaRole,
    status: pendaftaran.status,
    skill: profil?.skill ?? [],
    pengalaman: profil?.pengalaman ?? null,
    minatTag: profil?.minatTag ?? [],
    gayaKerja: profil?.gayaKerja ?? null,
    preferensiPeran: profil?.preferensiPeran ?? null,
    ketersediaanWaktu: profil?.ketersediaanWaktu ?? [],
    affinity,
    kontak: diterima ? (pendaftaran.mahasiswa.kontak ?? pendaftaran.mahasiswa.email) : null,
    kontakJenis: diterima
      ? (pendaftaran.mahasiswa.kontak ? pendaftaran.mahasiswa.kontakJenis ?? 'EMAIL' : 'EMAIL')
      : null,
  });
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
      kontakJenis: pendaftaran.mahasiswa.kontak ? pendaftaran.mahasiswa.kontakJenis ?? 'EMAIL' : 'EMAIL',
    });
  }

  await prisma.pendaftaranProject.update({
    where: { id: pendaftaran.id },
    data: { status: 'REJECTED' },
  });
  return res.json({ status: 'REJECTED' });
});

export default router;

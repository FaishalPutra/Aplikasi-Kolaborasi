import { Router } from 'express';
import { prisma } from '../prisma';
import { wajibLogin, AuthedRequest } from '../auth';
import { hitungAffinityPeople, ProfilOrang } from '../affinityPeople';

// Modul People-to-People (Ahmad). UC05–UC12 + AffinityEngine orang-ke-orang (Bab IV.3).
const router = Router();

router.get('/health', (_req, res) => res.json({ module: 'people-to-people', ok: true }));

// [DEMO/TANPA-DB] verifikasi algoritma: body { a: ProfilOrang, b: ProfilOrang }
router.post('/hitung', (req, res) => {
  const { a, b } = req.body ?? {};
  if (!a || !b) return res.status(400).json({ error: 'body harus berisi { a, b }' });
  return res.json(hitungAffinityPeople(a as ProfilOrang, b as ProfilOrang));
});

type ProfilRow = {
  mahasiswaId: string;
  skill: string[];
  minatTag: string[];
  pengalaman: number;
  gayaKerja: string;
  ketersediaanWaktu: string[];
  preferensiPeran: string;
};

function toProfilOrang(p: ProfilRow): ProfilOrang {
  return {
    skill: p.skill,
    minat: p.minatTag,
    pengalaman: p.pengalaman,
    gayaKerja: p.gayaKerja,
    ketersediaan: p.ketersediaanWaktu,
    peran: p.preferensiPeran,
  };
}

// pasangan koneksi dinormalisasi (urut) supaya unik dua arah
function pair(a: string, b: string): [string, string] {
  return a < b ? [a, b] : [b, a];
}

async function sudahTerhubung(a: string, b: string): Promise<boolean> {
  const [x, y] = pair(a, b);
  const c = await prisma.connection.findUnique({
    where: { mahasiswaAId_mahasiswaBId: { mahasiswaAId: x, mahasiswaBId: y } },
  });
  return !!c;
}

// ---------- UC05: atur visibilitas profil ----------
router.patch('/visibility', wajibLogin, async (req: AuthedRequest, res) => {
  const { visible } = req.body ?? {};
  const profil = await prisma.profil.findUnique({ where: { mahasiswaId: req.mahasiswaId! } });
  if (!profil) return res.status(404).json({ error: 'Profil belum ada' });
  const updated = await prisma.profil.update({
    where: { mahasiswaId: req.mahasiswaId! },
    data: { visibilitas: visible !== false },
  });
  return res.json({ visibilitas: updated.visibilitas });
});

// ---------- UC06 + UC07: feed rekomendasi partner (+filter) ----------
router.get('/feed', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const myProfil = await prisma.profil.findUnique({ where: { mahasiswaId: me } });
  if (!myProfil || !myProfil.lengkap) {
    return res.json({ feed: [], error: 'Lengkapi profil dulu untuk melihat rekomendasi.' });
  }

  // kandidat: profil lengkap, visible, bukan diri sendiri
  const kandidat = await prisma.profil.findMany({
    where: { lengkap: true, visibilitas: true, mahasiswaId: { not: me } },
    include: { mahasiswa: { select: { nama: true, institusi: true, jurusan: true, angkatan: true, bio: true } } },
  });

  const meOrang = toProfilOrang(myProfil);

  // Lapis 1: band skor (eksklusif, ikut label yang sama dengan AffinityEngine)
  const TIER_LABEL: Record<string, string> = {
    sangat: 'Sangat Cocok',
    cocok: 'Cocok',
    cukup: 'Cukup Cocok',
  };
  const tier = (req.query.tier as string) || 'semua';

  // Lapis 2: filter atribut (bisa dikombinasikan, tiap kategori di-OR-kan lalu di-AND-kan antar kategori)
  const splitParam = (v: unknown) =>
    typeof v === 'string' ? v.split(',').map((s) => s.trim()).filter(Boolean) : [];
  const minatFilter = splitParam(req.query.minat);
  const waktuFilter = splitParam(req.query.waktu);
  const peranFilter = (req.query.peran as string) || '';
  const gayaFilter = (req.query.gaya as string) || '';

  const hasil = [];
  for (const k of kandidat) {
    // sembunyikan yang sudah terhubung dari feed
    if (await sudahTerhubung(me, k.mahasiswaId)) continue;

    const skor = hitungAffinityPeople(meOrang, toProfilOrang(k));

    // simpan skor (UC05/UC06 pencocokan)
    await prisma.affinityScorePeople.upsert({
      where: { mahasiswaAId_mahasiswaBId: { mahasiswaAId: me, mahasiswaBId: k.mahasiswaId } },
      create: {
        mahasiswaAId: me,
        mahasiswaBId: k.mahasiswaId,
        nilaiTotal: skor.nilaiTotal,
        detail: skor.breakdown as any,
      },
      update: { nilaiTotal: skor.nilaiTotal, detail: skor.breakdown as any },
    });

    // filter UC07
    if (tier !== 'semua' && skor.label !== TIER_LABEL[tier]) continue;
    if (minatFilter.length && !k.minatTag.some((m) => minatFilter.includes(m))) continue;
    if (peranFilter && k.preferensiPeran !== peranFilter) continue;
    if (gayaFilter && k.gayaKerja !== gayaFilter) continue;
    if (waktuFilter.length && !k.ketersediaanWaktu.some((w) => waktuFilter.includes(w))) continue;

    hasil.push({
      mahasiswaId: k.mahasiswaId,
      nama: k.mahasiswa.nama,
      institusi: k.mahasiswa.institusi ?? '',
      jurusan: k.mahasiswa.jurusan ?? '',
      angkatan: k.mahasiswa.angkatan,
      bio: k.mahasiswa.bio ?? '',
      persen: skor.persen,
      label: skor.label,
      alasan: alasanCocok(skor.breakdown, meOrang, toProfilOrang(k)),
    });
  }

  hasil.sort((a, b) => b.persen - a.persen);
  return res.json({ feed: hasil, total: hasil.length });
});

// alasan "kenapa kalian cocok" — ambil atribut dengan skor tertinggi
function alasanCocok(
  bd: Record<string, { skor: number }>,
  a: ProfilOrang,
  b: ProfilOrang
): string[] {
  const out: string[] = [];
  if (bd.minat.skor > 0) {
    const sama = a.minat.filter((x) => b.minat.includes(x));
    if (sama.length) out.push(`Minat sama: ${sama.join(', ')}`);
  }
  if (bd.skill.skor > 0) out.push('Skill saling melengkapi');
  if (bd.gayaKerja.skor === 1) out.push(`Gaya kerja sama: ${a.gayaKerja}`);
  if (bd.ketersediaan.skor > 0) {
    const slot = a.ketersediaan.filter((x) => b.ketersediaan.includes(x));
    if (slot.length) out.push(`${slot.length} slot waktu beririsan`);
  }
  return out;
}

// ---------- UC08: detail profil calon partner ----------
router.get('/profil/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const targetId = req.params.id;
  const target = await prisma.profil.findUnique({
    where: { mahasiswaId: targetId },
    include: {
      mahasiswa: { select: { nama: true, institusi: true, jurusan: true, angkatan: true, bio: true, kontak: true } },
    },
  });
  if (!target || !target.lengkap) return res.status(404).json({ error: 'Profil tidak tersedia' });

  const myProfil = await prisma.profil.findUnique({ where: { mahasiswaId: me } });
  const affinity = myProfil ? hitungAffinityPeople(toProfilOrang(myProfil), toProfilOrang(target)) : null;
  const terhubung = await sudahTerhubung(me, targetId);
  const sudahDisimpan = !!(await prisma.savedProfile.findUnique({
    where: { ownerId_targetId: { ownerId: me, targetId } },
  }));
  const sudahTertarik = !!(await prisma.expressInterest.findUnique({
    where: { senderId_receiverId: { senderId: me, receiverId: targetId } },
  }));

  return res.json({
    mahasiswaId: targetId,
    nama: target.mahasiswa.nama,
    institusi: target.mahasiswa.institusi ?? '',
    jurusan: target.mahasiswa.jurusan ?? '',
    angkatan: target.mahasiswa.angkatan,
    bio: target.mahasiswa.bio ?? '',
    minat: target.minatTag,
    skill: target.skill,
    pengalaman: target.pengalaman,
    gayaKerja: target.gayaKerja,
    preferensiPeran: target.preferensiPeran,
    ketersediaanWaktu: target.ketersediaanWaktu,
    affinity,
    terhubung,
    sudahDisimpan,
    sudahTertarik,
    // kontak hanya dibuka jika sudah terhubung (mockup: "terbuka setelah terhubung")
    kontak: terhubung ? target.mahasiswa.kontak ?? '' : null,
  });
});

// ---------- UC09: simpan profil ----------
router.post('/saved', wajibLogin, async (req: AuthedRequest, res) => {
  const { targetId } = req.body ?? {};
  if (!targetId) return res.status(400).json({ error: 'targetId wajib' });
  await prisma.savedProfile.upsert({
    where: { ownerId_targetId: { ownerId: req.mahasiswaId!, targetId } },
    create: { ownerId: req.mahasiswaId!, targetId },
    update: {},
  });
  return res.json({ ok: true });
});

router.get('/saved', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const rows = await prisma.savedProfile.findMany({ where: { ownerId: me } });
  const myProfil = await prisma.profil.findUnique({ where: { mahasiswaId: me } });
  const out = [];
  for (const r of rows) {
    const p = await prisma.profil.findUnique({
      where: { mahasiswaId: r.targetId },
      include: { mahasiswa: { select: { nama: true, institusi: true } } },
    });
    const aff = p && myProfil ? hitungAffinityPeople(toProfilOrang(myProfil), toProfilOrang(p)) : null;
    out.push({
      targetId: r.targetId,
      nama: p?.mahasiswa.nama ?? '',
      institusi: p?.mahasiswa.institusi ?? '',
      persen: aff?.persen ?? 0,
      label: aff?.label ?? '',
    });
  }
  return res.json({ saved: out });
});

// ---------- UC10: express interest ----------
router.post('/interest', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const { receiverId } = req.body ?? {};
  if (!receiverId) return res.status(400).json({ error: 'receiverId wajib' });
  if (receiverId === me) return res.status(400).json({ error: 'Tidak bisa ke diri sendiri' });
  await prisma.expressInterest.upsert({
    where: { senderId_receiverId: { senderId: me, receiverId } },
    create: { senderId: me, receiverId },
    update: {},
  });

  // jika lawan juga sudah menandai tertarik ke saya → saling tertarik, otomatis terhubung
  const balasan = await prisma.expressInterest.findUnique({
    where: { senderId_receiverId: { senderId: receiverId, receiverId: me } },
  });
  if (balasan) {
    const [x, y] = pair(me, receiverId);
    await prisma.connection.upsert({
      where: { mahasiswaAId_mahasiswaBId: { mahasiswaAId: x, mahasiswaBId: y } },
      create: { mahasiswaAId: x, mahasiswaBId: y, asal: 'INTEREST' },
      update: {},
    });
    return res.json({ ok: true, status: 'CONNECTED', pesan: 'Koneksi terbentuk (saling tertarik)' });
  }

  return res.json({ ok: true, status: 'PENDING', pesan: 'Kamu menandai tertarik' });
});

// ---------- Ekstra: berapa orang yang tertarik ke saya (identitas dirahasiakan
// sampai saling tertarik — bukan daftar, cuma jumlah) ----------
router.get('/menyukai-saya', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const rows = await prisma.expressInterest.findMany({ where: { receiverId: me } });
  let jumlah = 0;
  for (const r of rows) {
    if (await sudahTerhubung(me, r.senderId)) continue; // sudah terhubung, cukup muncul di tab Terhubung
    jumlah++;
  }
  return res.json({ jumlah });
});

// ---------- UC11: kirim connect request ----------
router.post('/connect', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const { receiverId } = req.body ?? {};
  if (!receiverId) return res.status(400).json({ error: 'receiverId wajib' });
  if (receiverId === me) return res.status(400).json({ error: 'Tidak bisa ke diri sendiri' });

  // jika lawan sudah mengirim request ke saya → langsung terbentuk koneksi (saling tertarik)
  const balasan = await prisma.connectRequest.findUnique({
    where: { senderId_receiverId: { senderId: receiverId, receiverId: me } },
  });
  if (balasan && balasan.status === 'PENDING') {
    await prisma.connectRequest.update({ where: { id: balasan.id }, data: { status: 'ACCEPTED' } });
    const [x, y] = pair(me, receiverId);
    await prisma.connection.upsert({
      where: { mahasiswaAId_mahasiswaBId: { mahasiswaAId: x, mahasiswaBId: y } },
      create: { mahasiswaAId: x, mahasiswaBId: y },
      update: {},
    });
    return res.json({ status: 'CONNECTED', pesan: 'Koneksi terbentuk (saling tertarik)' });
  }

  await prisma.connectRequest.upsert({
    where: { senderId_receiverId: { senderId: me, receiverId } },
    create: { senderId: me, receiverId },
    update: { status: 'PENDING' },
  });
  return res.json({ status: 'PENDING', pesan: 'Permintaan koneksi dikirim' });
});

// daftar permintaan koneksi masuk (tab "Permintaan")
router.get('/requests', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const reqs = await prisma.connectRequest.findMany({
    where: { receiverId: me, status: 'PENDING' },
  });
  const myProfil = await prisma.profil.findUnique({ where: { mahasiswaId: me } });
  const out = [];
  for (const r of reqs) {
    const p = await prisma.profil.findUnique({
      where: { mahasiswaId: r.senderId },
      include: { mahasiswa: { select: { nama: true, institusi: true } } },
    });
    const aff = p && myProfil ? hitungAffinityPeople(toProfilOrang(myProfil), toProfilOrang(p)) : null;
    out.push({
      requestId: r.id,
      senderId: r.senderId,
      nama: p?.mahasiswa.nama ?? '',
      institusi: p?.mahasiswa.institusi ?? '',
      persen: aff?.persen ?? 0,
      label: aff?.label ?? '',
    });
  }
  return res.json({ permintaan: out });
});

// terima / tolak permintaan koneksi
router.patch('/connect/:id', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const { aksi } = req.body ?? {}; // "ACCEPTED" | "REJECTED"
  const cr = await prisma.connectRequest.findUnique({ where: { id: req.params.id } });
  if (!cr) return res.status(404).json({ error: 'Permintaan tidak ditemukan' });
  if (cr.receiverId !== me) return res.status(403).json({ error: 'Bukan penerima permintaan ini' });

  if (aksi === 'ACCEPTED') {
    await prisma.connectRequest.update({ where: { id: cr.id }, data: { status: 'ACCEPTED' } });
    const [x, y] = pair(cr.senderId, cr.receiverId);
    await prisma.connection.upsert({
      where: { mahasiswaAId_mahasiswaBId: { mahasiswaAId: x, mahasiswaBId: y } },
      create: { mahasiswaAId: x, mahasiswaBId: y },
      update: {},
    });
    return res.json({ status: 'ACCEPTED', pesan: 'Koneksi diterima' });
  }
  await prisma.connectRequest.update({ where: { id: cr.id }, data: { status: 'REJECTED' } });
  return res.json({ status: 'REJECTED', pesan: 'Permintaan ditolak' });
});

// ---------- UC12: daftar koneksi (kontak terbuka) ----------
router.get('/connections', wajibLogin, async (req: AuthedRequest, res) => {
  const me = req.mahasiswaId!;
  const conns = await prisma.connection.findMany({
    where: { OR: [{ mahasiswaAId: me }, { mahasiswaBId: me }] },
  });
  const out = [];
  for (const c of conns) {
    const otherId = c.mahasiswaAId === me ? c.mahasiswaBId : c.mahasiswaAId;
    const m = await prisma.mahasiswa.findUnique({
      where: { id: otherId },
      select: { nama: true, institusi: true, jurusan: true, angkatan: true, kontak: true, kontakJenis: true },
    });
    out.push({
      mahasiswaId: otherId,
      nama: m?.nama ?? '',
      institusi: m?.institusi ?? '',
      jurusan: m?.jurusan ?? '',
      angkatan: m?.angkatan,
      kontak: m?.kontak ?? '', // terbuka karena sudah terhubung
      kontakJenis: m?.kontakJenis ?? '',
      asal: c.asal,
      connectedAt: c.connectedAt,
    });
  }
  return res.json({ koneksi: out });
});

export default router;

import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../prisma';
import { buatToken, wajibLogin, AuthedRequest } from '../auth';

// [SHARED] General Features: autentikasi & profil kolaboratif (UC01–UC04).
const router = Router();

// UC01 Register
router.post('/register', async (req, res) => {
  const { nama, email, password, institusi } = req.body ?? {};
  if (!nama || !email || !password) {
    return res.status(400).json({ error: 'nama, email, password wajib diisi' });
  }
  const sudahAda = await prisma.mahasiswa.findUnique({ where: { email } });
  if (sudahAda) return res.status(409).json({ error: 'Email sudah terdaftar' });

  const hash = await bcrypt.hash(password, 10);
  const mhs = await prisma.mahasiswa.create({
    data: { nama, email, password: hash, institusi: institusi ?? null },
  });
  return res.status(201).json({ id: mhs.id, nama: mhs.nama, email: mhs.email });
});

// UC02 Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body ?? {};
  const mhs = await prisma.mahasiswa.findUnique({ where: { email } });
  if (!mhs || !(await bcrypt.compare(password ?? '', mhs.password))) {
    return res.status(401).json({ error: 'Email atau password salah' });
  }
  const profil = await prisma.profil.findUnique({ where: { mahasiswaId: mhs.id } });
  return res.json({
    token: buatToken(mhs.id),
    mahasiswa: { id: mhs.id, nama: mhs.nama, email: mhs.email },
    profilLengkap: profil?.lengkap ?? false,
  });
});

// UC03 Logout — sesi JWT stateless, dihapus di klien. Endpoint untuk konsistensi.
router.post('/logout', wajibLogin, (_req, res) => res.json({ ok: true }));

// UC04 Lihat profil kolaboratif sendiri
router.get('/profil', wajibLogin, async (req: AuthedRequest, res) => {
  const profil = await prisma.profil.findUnique({ where: { mahasiswaId: req.mahasiswaId } });
  return res.json(profil);
});

// UC04 Buat / perbarui profil kolaboratif (upsert)
router.put('/profil', wajibLogin, async (req: AuthedRequest, res) => {
  const { skill, pengalaman, minatTag, gayaKerja, preferensiPeran, ketersediaanWaktu } =
    req.body ?? {};

  // Validasi field wajib
  if (
    !Array.isArray(skill) ||
    typeof pengalaman !== 'number' ||
    !Array.isArray(minatTag) ||
    !gayaKerja ||
    !preferensiPeran ||
    !Array.isArray(ketersediaanWaktu)
  ) {
    return res.status(400).json({ error: 'Field profil tidak lengkap atau tipe salah' });
  }
  if (pengalaman < 1 || pengalaman > 3) {
    return res.status(400).json({ error: 'pengalaman harus 1..3' });
  }

  const data = {
    skill,
    pengalaman,
    minatTag,
    gayaKerja,
    preferensiPeran,
    ketersediaanWaktu,
    lengkap: true,
  };
  const profil = await prisma.profil.upsert({
    where: { mahasiswaId: req.mahasiswaId! },
    create: { mahasiswaId: req.mahasiswaId!, ...data },
    update: data,
  });
  return res.json(profil);
});

export default router;

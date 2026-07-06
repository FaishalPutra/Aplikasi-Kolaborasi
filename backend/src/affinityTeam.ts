// [TEAM-FORM] Affinity Engine Team Formation (TA Faishal, Bab IV — Bab4_Algoritma_Affinity_Matching_Final).
// Beda rumus & bobot dari affinityProject.ts dan affinityPeople.ts — mesin sendiri, tidak reuse.
// Pure functions, deterministik. Tidak ada akses DB di sini.

// --- Algoritma IV.1 — Technical Role Affinity -------------------------------------------------

// Bobot ROC dari ranking survei (skill 64.0% > minat 53.5% > pengalaman 37.2%)
export const W_ROLE = {
  skill: 0.611,
  minat: 0.278,
  pengalaman: 0.111,
} as const;

// Domain Skill Role — pool tag terkurasi sistem per kategori peran (bukan diisi Koordinator)
// Hanya memakai 12 tag skill yang benar-benar bisa dipilih mahasiswa di UI.
export const DOMAIN_SKILL_ROLE: Record<string, string[]> = {
  Programmer: ['Python', 'JavaScript', 'SQL'],
  'Backend Developer': ['Python', 'SQL', 'JavaScript'],
  'Frontend Developer': ['JavaScript', 'Flutter', 'UI Design'],
  'Mobile Developer': ['Flutter', 'JavaScript', 'UI Design'],
  'UI/UX Designer': ['Figma', 'UI Design', 'Riset Pengguna'],
  'Data Analyst': ['SQL', 'Analisis Data', 'Python'],
  'Data Scientist': ['Python', 'Analisis Data', 'SQL'],
  'Project Manager': ['Manajemen Proyek', 'Public Speaking', 'Penulisan'],
  'QA/Tester': ['Analisis Data', 'SQL', 'Penulisan'],
  'Content/Business Analyst': ['Copywriting', 'Penulisan', 'Public Speaking'],
};

export interface ProfilTeknis {
  skill: string[];
  pengalaman: number; // 1..3
  minatTag: string[];
}

export interface RoleInput {
  namaRole: string; // key ke DOMAIN_SKILL_ROLE
  kategoriLomba: string[]; // req_minat(r) — sama untuk semua role di satu lomba
  pengalamanReq?: number | null; // 1..3, opsional (kalau null exclude dari IV.1)
}

export interface TechnicalRoleAffinityResult {
  nilaiTotal: number; // 0..1
  detail: {
    skill: number;
    minat: number;
    pengalaman: number | null;
    bobotDipakai: { skill: number; minat: number; pengalaman: number };
  };
}

// Rasio cakupan |attr ∩ req| / |req|. Jika |req| = 0 → 1 (tak ada tuntutan).
function coverage(milik: string[], dibutuhkan: string[]): number {
  if (dibutuhkan.length === 0) return 1;
  const set = new Set(milik.map((s) => s.toLowerCase()));
  const cocok = dibutuhkan.filter((d) => set.has(d.toLowerCase())).length;
  return cocok / dibutuhkan.length;
}

// Algoritma IV.1 — TechnicalRoleAffinity(i, r)
export function technicalRoleAffinity(
  profil: ProfilTeknis,
  role: RoleInput,
): TechnicalRoleAffinityResult {
  const reqSkill = DOMAIN_SKILL_ROLE[role.namaRole] ?? [];
  const skorSkill = coverage(profil.skill, reqSkill);
  const skorMinat = coverage(profil.minatTag, role.kategoriLomba);

  if (role.pengalamanReq == null) {
    // Renormalisasi proporsional bobot skill & minat (pengalaman dikeluarkan)
    const totalW = W_ROLE.skill + W_ROLE.minat;
    const wSkill = W_ROLE.skill / totalW;
    const wMinat = W_ROLE.minat / totalW;
    const nilaiTotal = wSkill * skorSkill + wMinat * skorMinat;
    return {
      nilaiTotal,
      detail: { skill: skorSkill, minat: skorMinat, pengalaman: null, bobotDipakai: { skill: wSkill, minat: wMinat, pengalaman: 0 } },
    };
  }

  const skorPengalaman = 1 - Math.abs(profil.pengalaman - role.pengalamanReq) / 2;
  const nilaiTotal = W_ROLE.skill * skorSkill + W_ROLE.minat * skorMinat + W_ROLE.pengalaman * skorPengalaman;
  return {
    nilaiTotal,
    detail: { skill: skorSkill, minat: skorMinat, pengalaman: skorPengalaman, bobotDipakai: { ...W_ROLE } },
  };
}

// Persamaan IV.5 — agregasi tingkat tim. Sum hanya anggota ACCEPTED, dibagi totalKuota (bukan N).
export function technicalRoleAffinityTeam(skorAnggota: number[], totalKuota: number): number {
  if (totalKuota <= 0) return 0;
  const jumlah = skorAnggota.reduce((a, b) => a + b, 0);
  return jumlah / totalKuota;
}

// --- Algoritma IV.2 — Team Function Affinity berbasis TREO -----------------------------------

export const TREO_DIMENSIONS = [
  'organizer',
  'doer',
  'challenger',
  'innovator',
  'teamBuilder',
  'connector',
] as const;

export type TreoDimensi = (typeof TREO_DIMENSIONS)[number];

// Ambang kelayakan memegang dimensi TREO (reuse batas bawah badge "kuning" People-to-Project).
// Fungsional: nilai treoNorm harus > ambang ini agar seseorang boleh memegang dimensi tsb.
export const TREO_DISPLAY_THRESHOLD = 0.6;

// Maks dimensi yang boleh dipegang 1 orang sekaligus (1 dimensi tetap hanya utk 1 orang).
export const MAX_DIMENSI_PER_ORANG = 2;

export interface AnggotaTreo {
  mahasiswaId: string;
  nama: string;
  treoNorm: Record<TreoDimensi, number>; // 0..1, hasil Persamaan IV.7
}

export interface AssignmentSlot {
  mahasiswaId: string;
  nama: string;
  nilai: number;
}

export interface DistributedRoleCoverageResult {
  coverage: number; // rata-rata 6 nilai terbaik (Persamaan IV.8)
  assignment: Record<TreoDimensi, AssignmentSlot>;
  m: number; // jumlah anggota berbeda yang terpakai pada assignment optimal
}

// Persamaan IV.6/IV.7 — konversi skala Likert 1..5 (raw) ke 0..1 (norm)
export function treoNorm(raw: number): number {
  return (raw - 1) / 4;
}

// Persamaan IV.8/IV.9 — DistributedRoleCoverage(team) dengan optimal assignment g.
// Beda dengan Technical Role Affinity (1 role bisa dipegang banyak orang, tapi 1 orang cuma 1
// role): di TREO 1 orang boleh memegang banyak dimensi (maks MAX_DIMENSI_PER_ORANG), tapi tiap
// dimensi tetap hanya dipegang 1 orang. Syarat kelayakan memegang dimensi d: treoNorm(d) di atas
// TREO_DISPLAY_THRESHOLD DAN merupakan nilai tertinggi di antara kandidat yang masih tersedia
// (belum kena batas kuota) untuk dimensi tsb. Diimplementasikan via greedy menurun nilai —
// kandidat bernilai tertinggi utk suatu dimensi selalu diproses lebih dulu, sehingga otomatis
// menang kecuali kuotanya sudah habis dipakai dimensi lain yang nilainya lebih tinggi.
export function distributedRoleCoverage(anggota: AnggotaTreo[]): DistributedRoleCoverageResult {
  const dims = TREO_DIMENSIONS;

  const buatKosong = () => {
    const a = {} as Record<TreoDimensi, AssignmentSlot>;
    for (const d of dims) a[d] = { mahasiswaId: '', nama: '', nilai: 0 };
    return a;
  };

  if (anggota.length === 0) {
    return { coverage: 0, assignment: buatKosong(), m: 0 };
  }

  const kandidat: { anggota: AnggotaTreo; dim: TreoDimensi; nilai: number }[] = [];
  for (const a of anggota) {
    for (const d of dims) {
      if (a.treoNorm[d] > TREO_DISPLAY_THRESHOLD) {
        kandidat.push({ anggota: a, dim: d, nilai: a.treoNorm[d] });
      }
    }
  }
  kandidat.sort((x, y) => y.nilai - x.nilai);

  const assignment = buatKosong();
  const dimensiTerisi = new Set<TreoDimensi>();
  const jumlahDimensiPerOrang = new Map<string, number>();
  let total = 0;

  for (const k of kandidat) {
    if (dimensiTerisi.has(k.dim)) continue;
    const dipegang = jumlahDimensiPerOrang.get(k.anggota.mahasiswaId) ?? 0;
    if (dipegang >= MAX_DIMENSI_PER_ORANG) continue;

    assignment[k.dim] = { mahasiswaId: k.anggota.mahasiswaId, nama: k.anggota.nama, nilai: k.nilai };
    dimensiTerisi.add(k.dim);
    jumlahDimensiPerOrang.set(k.anggota.mahasiswaId, dipegang + 1);
    total += k.nilai;
  }

  const dipakai = new Set(
    dims.filter((d) => assignment[d].mahasiswaId !== '').map((d) => assignment[d].mahasiswaId),
  );
  return { coverage: total / 6, assignment, m: dipakai.size };
}

// Persamaan IV.10 — TeamFunctionAffinity(team) dengan pengali keberagaman M/min(6, maxAnggotaTim)
export function teamFunctionAffinity(coverage: number, m: number, maxAnggotaTim: number): number {
  const pengali = m / Math.min(6, maxAnggotaTim);
  return coverage * pengali;
}

// --- Algoritma IV.3 — Team Formation Effectiveness Score --------------------------------------

// Persamaan IV.11 — kombinasi 50:50, tak ada dominasi konsisten technical vs functional (literatur)
export function teamFormationEffectivenessScore(technicalRoleAffinityTeam: number, teamFunctionAffinity: number): number {
  return 0.5 * technicalRoleAffinityTeam + 0.5 * teamFunctionAffinity;
}

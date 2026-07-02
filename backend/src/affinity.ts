// [SHARED] Affinity Engine — Affinity Based Matching (TA Bab IV.3).
// Pure functions, deterministik. Dipakai bersama oleh modul (lihat Deployment Diagram).

// Bobot internal (Rank Order Centroid, Bab IV.3.2)
export const W = {
  // Algoritma 1 — Demands-Abilities Fit
  skill: 0.75,
  pengalaman: 0.25,
  // Algoritma 2 — Needs-Supplies Fit
  minat: 0.611,
  gayaKerja: 0.194,
  peran: 0.194,
  // Kombinasi dua sub-algoritma (50:50)
  algo: 0.5,
} as const;

export const FEED_THRESHOLD = 0.3; // skor minimum tampil di feed (Bab IV.3.4)

export interface ProfilMhs {
  skill: string[];
  pengalaman: number; // 1..3
  minatTag: string[];
  gayaKerja: string;
  preferensiPeran: string;
  ketersediaanWaktu: string[];
}

export interface ProjectInput {
  skillDicari: string[]; // gabungan skill seluruh role yang dibutuhkan
  pengalamanReq: number; // 1..3
  minatTag: string[];
  gayaKerja: string;
  rolesDibutuhkan: string[]; // taksonomi peran generik
  jadwalSlot: string[];
}

export interface AtributBreakdown {
  skor: number;        // skor mentah atribut (0..1)
  kontribusi: number;  // 0.5 * bobot_internal * skor
}

export interface AffinityResult {
  affinityScore: number; // 0..1
  skorAlgo1: number;
  skorAlgo2: number;
  breakdown: Record<'skill' | 'pengalaman' | 'minat' | 'gayaKerja' | 'peran', AtributBreakdown>;
}

// Rasio cakupan (coverage): |S ∩ P| / |P|. Jika |P| = 0 → 1 (tak ada tuntutan).
function coverage(milik: string[], dibutuhkan: string[]): number {
  if (dibutuhkan.length === 0) return 1;
  const set = new Set(milik.map((s) => s.toLowerCase()));
  const cocok = dibutuhkan.filter((d) => set.has(d.toLowerCase())).length;
  return cocok / dibutuhkan.length;
}

// Tahap 0 — hard constraint filtering (ketersediaan waktu).
// Eligible jika jadwal project overlap dengan ketersediaan mahasiswa,
// atau project tidak menetapkan jadwal sama sekali.
export function isEligible(profil: ProfilMhs, project: ProjectInput): boolean {
  if (project.jadwalSlot.length === 0) return true;
  const avail = new Set(profil.ketersediaanWaktu.map((s) => s.toLowerCase()));
  return project.jadwalSlot.some((slot) => avail.has(slot.toLowerCase()));
}

export function hitungAffinity(profil: ProfilMhs, project: ProjectInput): AffinityResult {
  // --- skor per atribut ---
  const skorSkill = coverage(profil.skill, project.skillDicari);
  const skorPengalaman = 1 - Math.abs(profil.pengalaman - project.pengalamanReq) / 2;
  const skorMinat = coverage(profil.minatTag, project.minatTag);
  const skorGaya =
    profil.gayaKerja.toLowerCase() === project.gayaKerja.toLowerCase() ? 1 : 0;

  let skorPeran: number;
  if (project.rolesDibutuhkan.length === 0) {
    skorPeran = 0.5; // project tak menetapkan peran spesifik → netral
  } else {
    const roles = new Set(project.rolesDibutuhkan.map((r) => r.toLowerCase()));
    skorPeran = roles.has(profil.preferensiPeran.toLowerCase()) ? 1 : 0;
  }

  // --- sub-algoritma (weighted sum) ---
  const skorAlgo1 = W.skill * skorSkill + W.pengalaman * skorPengalaman;
  const skorAlgo2 = W.minat * skorMinat + W.gayaKerja * skorGaya + W.peran * skorPeran;

  // --- skor akhir (kombinasi 50:50) ---
  const affinityScore = W.algo * skorAlgo1 + W.algo * skorAlgo2;

  const k = (bobot: number, skor: number) => W.algo * bobot * skor;

  return {
    affinityScore,
    skorAlgo1,
    skorAlgo2,
    breakdown: {
      skill: { skor: skorSkill, kontribusi: k(W.skill, skorSkill) },
      pengalaman: { skor: skorPengalaman, kontribusi: k(W.pengalaman, skorPengalaman) },
      minat: { skor: skorMinat, kontribusi: k(W.minat, skorMinat) },
      gayaKerja: { skor: skorGaya, kontribusi: k(W.gayaKerja, skorGaya) },
      peran: { skor: skorPeran, kontribusi: k(W.peran, skorPeran) },
    },
  };
}

// Kategori badge berdasarkan persentase (Bab IV.3.4)
export function badge(score: number): 'hijau' | 'kuning' | 'abu' | 'none' {
  const p = score * 100;
  if (p >= 85) return 'hijau';
  if (p >= 60) return 'kuning';
  if (p >= 30) return 'abu';
  return 'none';
}

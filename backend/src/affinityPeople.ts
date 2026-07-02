// [P2P-PEOPLE] Affinity Engine orang-ke-orang (TA Ahmad, Bab IV.3).
// Simetris: skor(a,b) == skor(b,a). Contoh tervalidasi A↔B = 0,685 (68,5%).

// Bobot ROC dari survei (Tabel IV.35). Jumlah = 1,000.
export const W_PEOPLE = {
  skill: 0.241, // Komplementer
  minat: 0.198, // Suplementer
  gayaKerja: 0.178, // Suplementer
  pengalaman: 0.162, // Suplementer
  ketersediaan: 0.111, // Suplementer
  peran: 0.111, // Komplementer
} as const;

export interface ProfilOrang {
  skill: string[];
  minat: string[];
  pengalaman: number; // 1..3
  gayaKerja: string; // "Terstruktur" | "Fleksibel"
  ketersediaan: string[];
  peran: string; // preferensi peran
}

export interface HasilAffinityPeople {
  nilaiTotal: number; // 0..1
  persen: number; // 0..100 (1 desimal)
  label: string; // "Sangat Cocok" | "Cocok" | "Cukup Cocok"
  breakdown: Record<string, { skor: number; bobot: number; kontribusi: number }>;
}

// Jaccard: |A∩B| / |A∪B| (suplementer, dinilai dari kesamaan)
function jaccard(a: string[], b: string[]): number {
  const A = new Set(a);
  const B = new Set(b);
  if (A.size === 0 && B.size === 0) return 0;
  const inter = [...A].filter((x) => B.has(x)).length;
  const union = new Set([...A, ...B]).size;
  return union === 0 ? 0 : inter / union;
}

// ---- skor per atribut (Persamaan IV.2–IV.7) ----
const sMinat = (a: ProfilOrang, b: ProfilOrang) => jaccard(a.minat, b.minat); // IV.2
const sGaya = (a: ProfilOrang, b: ProfilOrang) => (a.gayaKerja === b.gayaKerja ? 1 : 0); // IV.3
const sPengalaman = (a: ProfilOrang, b: ProfilOrang) => 1 - Math.abs(a.pengalaman - b.pengalaman) / 2; // IV.4
const sWaktu = (a: ProfilOrang, b: ProfilOrang) => jaccard(a.ketersediaan, b.ketersediaan); // IV.5

// Skill: komplementer = 1 - Jaccard (semakin sedikit tumpang tindih, semakin tinggi) — IV.6
function sSkill(a: ProfilOrang, b: ProfilOrang): number {
  const A = new Set(a.skill);
  const B = new Set(b.skill);
  const union = new Set([...A, ...B]).size;
  if (union === 0) return 0;
  const inter = [...A].filter((x) => B.has(x)).length;
  return (union - inter) / union;
}

// Peran: komplementer — beda = 1, sama = 0,5 (IV.7)
const sPeran = (a: ProfilOrang, b: ProfilOrang) => (a.peran !== b.peran ? 1 : 0.5);

export function labelPeople(nilai: number): string {
  if (nilai >= 0.75) return 'Sangat Cocok';
  if (nilai >= 0.5) return 'Cocok';
  return 'Cukup Cocok';
}

// AffinityScore(a,b) = Σ Wi·Si  (Persamaan IV.8)
export function hitungAffinityPeople(a: ProfilOrang, b: ProfilOrang): HasilAffinityPeople {
  const skor = {
    skill: sSkill(a, b),
    minat: sMinat(a, b),
    gayaKerja: sGaya(a, b),
    pengalaman: sPengalaman(a, b),
    ketersediaan: sWaktu(a, b),
    peran: sPeran(a, b),
  };
  const breakdown: HasilAffinityPeople['breakdown'] = {};
  let total = 0;
  (Object.keys(W_PEOPLE) as (keyof typeof W_PEOPLE)[]).forEach((k) => {
    const bobot = W_PEOPLE[k];
    const kontribusi = bobot * skor[k];
    breakdown[k] = { skor: skor[k], bobot, kontribusi };
    total += kontribusi;
  });
  return {
    nilaiTotal: total,
    persen: Math.round(total * 1000) / 10,
    label: labelPeople(total),
    breakdown,
  };
}

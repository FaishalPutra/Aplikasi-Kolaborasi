import { Router } from 'express';
// Modul Team Formation (Muhammad Faishal Firdaus, TA terpisah). Belum ada Affinity Engine-nya —
// masih placeholder health-check. Isi endpoint + affinityTeam.ts sendiri di sini kalau diperlukan,
// jangan pakai affinity.ts (People-to-Project) atau affinityPeople.ts (People-to-People).
const router = Router();
router.get('/health', (_req, res) => res.json({ module: 'team-formation', ok: true }));
export default router;

import { Router } from 'express';
// Modul Team Formation (Faishal). Isi endpoint di sini.
const router = Router();
router.get('/health', (_req, res) => res.json({ module: 'team-formation', ok: true }));
export default router;

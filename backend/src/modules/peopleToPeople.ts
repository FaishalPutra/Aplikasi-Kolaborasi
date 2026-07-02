import { Router } from 'express';
// Modul People-to-People (Ahmad). Isi endpoint di sini.
const router = Router();
router.get('/health', (_req, res) => res.json({ module: 'people-to-people', ok: true }));
export default router;

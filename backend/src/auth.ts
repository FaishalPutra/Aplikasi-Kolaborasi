// [SHARED] Helper sesi JWT + middleware autentikasi.
import jwt from 'jsonwebtoken';
import type { Request, Response, NextFunction } from 'express';

const SECRET = process.env.JWT_SECRET ?? 'dev-secret-ganti-di-produksi';

export interface AuthedRequest extends Request {
  mahasiswaId?: string;
}

export function buatToken(mahasiswaId: string): string {
  return jwt.sign({ sub: mahasiswaId }, SECRET, { expiresIn: '7d' });
}

// Middleware: wajib login. Set req.mahasiswaId dari token.
export function wajibLogin(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token tidak ada' });
  }
  try {
    const payload = jwt.verify(header.slice(7), SECRET) as { sub: string };
    req.mahasiswaId = payload.sub;
    next();
  } catch {
    return res.status(401).json({ error: 'Token tidak valid' });
  }
}

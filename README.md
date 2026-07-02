# Backend (Express + Prisma)
```bash
npm install
cp .env.example .env      # isi DATABASE_URL
npm run prisma:generate
npm run prisma:migrate
npm run dev               # http://localhost:3000
```
Tiap modul = 1 file di `src/modules/`. Digabung di `src/routes.ts`.

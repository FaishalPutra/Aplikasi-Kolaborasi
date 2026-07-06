-- AlterEnum
ALTER TYPE "StatusLobi" ADD VALUE 'FINALIZING';

-- AlterTable
ALTER TABLE "PendaftaranAnggota" ADD COLUMN     "setujuFinalisasi" BOOLEAN NOT NULL DEFAULT false;

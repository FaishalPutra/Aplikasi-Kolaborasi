-- AlterTable
ALTER TABLE "Connection" ADD COLUMN     "asal" TEXT NOT NULL DEFAULT 'REQUEST';

-- AlterTable
ALTER TABLE "Mahasiswa" ADD COLUMN     "angkatan" INTEGER,
ADD COLUMN     "bio" TEXT,
ADD COLUMN     "jurusan" TEXT;

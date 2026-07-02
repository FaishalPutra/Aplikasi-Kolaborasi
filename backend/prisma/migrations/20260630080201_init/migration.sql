-- CreateEnum
CREATE TYPE "StatusProject" AS ENUM ('ACTIVE', 'CLOSED');

-- CreateEnum
CREATE TYPE "StatusPendaftaran" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');

-- CreateTable
CREATE TABLE "Mahasiswa" (
    "id" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "institusi" TEXT,
    "kontak" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Mahasiswa_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Profil" (
    "id" TEXT NOT NULL,
    "mahasiswaId" TEXT NOT NULL,
    "skill" TEXT[],
    "pengalaman" INTEGER NOT NULL,
    "minatTag" TEXT[],
    "gayaKerja" TEXT NOT NULL,
    "preferensiPeran" TEXT NOT NULL,
    "ketersediaanWaktu" TEXT[],
    "lengkap" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Profil_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Project" (
    "id" TEXT NOT NULL,
    "judul" TEXT NOT NULL,
    "deskripsi" TEXT NOT NULL,
    "kategori" TEXT,
    "timeline" TEXT,
    "jadwalSlot" TEXT[],
    "pengalamanReq" INTEGER NOT NULL DEFAULT 1,
    "minatTag" TEXT[],
    "gayaKerja" TEXT,
    "status" "StatusProject" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "pembuatId" TEXT NOT NULL,

    CONSTRAINT "Project_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KebutuhanRole" (
    "id" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "namaRole" TEXT NOT NULL,
    "skillDicari" TEXT[],
    "kuota" INTEGER NOT NULL,
    "sisaKuota" INTEGER NOT NULL,

    CONSTRAINT "KebutuhanRole_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PendaftaranProject" (
    "id" TEXT NOT NULL,
    "mahasiswaId" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,
    "status" "StatusPendaftaran" NOT NULL DEFAULT 'PENDING',
    "tanggal" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PendaftaranProject_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AffinityScoreProject" (
    "id" TEXT NOT NULL,
    "mahasiswaId" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "nilaiTotal" DOUBLE PRECISION NOT NULL,
    "detail" JSONB NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AffinityScoreProject_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Mahasiswa_email_key" ON "Mahasiswa"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Profil_mahasiswaId_key" ON "Profil"("mahasiswaId");

-- CreateIndex
CREATE UNIQUE INDEX "PendaftaranProject_mahasiswaId_projectId_key" ON "PendaftaranProject"("mahasiswaId", "projectId");

-- CreateIndex
CREATE UNIQUE INDEX "AffinityScoreProject_mahasiswaId_projectId_key" ON "AffinityScoreProject"("mahasiswaId", "projectId");

-- AddForeignKey
ALTER TABLE "Profil" ADD CONSTRAINT "Profil_mahasiswaId_fkey" FOREIGN KEY ("mahasiswaId") REFERENCES "Mahasiswa"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Project" ADD CONSTRAINT "Project_pembuatId_fkey" FOREIGN KEY ("pembuatId") REFERENCES "Mahasiswa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KebutuhanRole" ADD CONSTRAINT "KebutuhanRole_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendaftaranProject" ADD CONSTRAINT "PendaftaranProject_mahasiswaId_fkey" FOREIGN KEY ("mahasiswaId") REFERENCES "Mahasiswa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendaftaranProject" ADD CONSTRAINT "PendaftaranProject_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendaftaranProject" ADD CONSTRAINT "PendaftaranProject_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "KebutuhanRole"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AffinityScoreProject" ADD CONSTRAINT "AffinityScoreProject_mahasiswaId_fkey" FOREIGN KEY ("mahasiswaId") REFERENCES "Mahasiswa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AffinityScoreProject" ADD CONSTRAINT "AffinityScoreProject_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

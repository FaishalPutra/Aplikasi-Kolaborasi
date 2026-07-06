-- CreateEnum
CREATE TYPE "StatusLomba" AS ENUM ('ACTIVE', 'CLOSED');

-- CreateEnum
CREATE TYPE "StatusLobi" AS ENUM ('OPEN', 'FINAL', 'CLOSED');

-- CreateTable
CREATE TABLE "Lomba" (
    "id" TEXT NOT NULL,
    "judul" TEXT NOT NULL,
    "deskripsi" TEXT NOT NULL,
    "kategoriLomba" TEXT[],
    "maxAnggotaTim" INTEGER NOT NULL,
    "tenggat" TEXT,
    "penyelenggara" TEXT,
    "status" "StatusLomba" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "pengusulId" TEXT NOT NULL,

    CONSTRAINT "Lomba_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudentLobby" (
    "id" TEXT NOT NULL,
    "lombaId" TEXT NOT NULL,
    "judul" TEXT NOT NULL,
    "deskripsi" TEXT,
    "koordinatorId" TEXT NOT NULL,
    "status" "StatusLobi" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StudentLobby_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RoleLobiTim" (
    "id" TEXT NOT NULL,
    "lobiId" TEXT NOT NULL,
    "namaRole" TEXT NOT NULL,
    "pengalamanReq" INTEGER,
    "kuota" INTEGER NOT NULL,
    "sisaKuota" INTEGER NOT NULL,

    CONSTRAINT "RoleLobiTim_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PendaftaranAnggota" (
    "id" TEXT NOT NULL,
    "mahasiswaId" TEXT NOT NULL,
    "lobiId" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,
    "status" "StatusPendaftaran" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PendaftaranAnggota_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AffinityScoreRoleTeam" (
    "id" TEXT NOT NULL,
    "mahasiswaId" TEXT NOT NULL,
    "lobiId" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,
    "nilaiTotal" DOUBLE PRECISION NOT NULL,
    "detail" JSONB NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AffinityScoreRoleTeam_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TeamFormationScore" (
    "id" TEXT NOT NULL,
    "lobiId" TEXT NOT NULL,
    "technicalRoleAffinity" DOUBLE PRECISION NOT NULL,
    "distributedRoleCoverage" DOUBLE PRECISION NOT NULL,
    "m" INTEGER NOT NULL,
    "teamFunctionAffinity" DOUBLE PRECISION NOT NULL,
    "effectivenessScore" DOUBLE PRECISION NOT NULL,
    "detail" JSONB NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TeamFormationScore_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TreoProfil" (
    "id" TEXT NOT NULL,
    "mahasiswaId" TEXT NOT NULL,
    "organizerRaw" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "doerRaw" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "challengerRaw" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "innovatorRaw" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "teamBuilderRaw" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "connectorRaw" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "organizerNorm" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "doerNorm" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "challengerNorm" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "innovatorNorm" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "teamBuilderNorm" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "connectorNorm" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "jawaban" JSONB NOT NULL,
    "diisi" BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TreoProfil_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DiskusiTim" (
    "id" TEXT NOT NULL,
    "lobiId" TEXT NOT NULL,
    "mahasiswaId" TEXT NOT NULL,
    "pesan" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DiskusiTim_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PendaftaranAnggota_mahasiswaId_lobiId_key" ON "PendaftaranAnggota"("mahasiswaId", "lobiId");

-- CreateIndex
CREATE UNIQUE INDEX "AffinityScoreRoleTeam_mahasiswaId_lobiId_roleId_key" ON "AffinityScoreRoleTeam"("mahasiswaId", "lobiId", "roleId");

-- CreateIndex
CREATE UNIQUE INDEX "TeamFormationScore_lobiId_key" ON "TeamFormationScore"("lobiId");

-- CreateIndex
CREATE UNIQUE INDEX "TreoProfil_mahasiswaId_key" ON "TreoProfil"("mahasiswaId");

-- AddForeignKey
ALTER TABLE "StudentLobby" ADD CONSTRAINT "StudentLobby_lombaId_fkey" FOREIGN KEY ("lombaId") REFERENCES "Lomba"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RoleLobiTim" ADD CONSTRAINT "RoleLobiTim_lobiId_fkey" FOREIGN KEY ("lobiId") REFERENCES "StudentLobby"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendaftaranAnggota" ADD CONSTRAINT "PendaftaranAnggota_mahasiswaId_fkey" FOREIGN KEY ("mahasiswaId") REFERENCES "Mahasiswa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendaftaranAnggota" ADD CONSTRAINT "PendaftaranAnggota_lobiId_fkey" FOREIGN KEY ("lobiId") REFERENCES "StudentLobby"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendaftaranAnggota" ADD CONSTRAINT "PendaftaranAnggota_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "RoleLobiTim"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AffinityScoreRoleTeam" ADD CONSTRAINT "AffinityScoreRoleTeam_mahasiswaId_fkey" FOREIGN KEY ("mahasiswaId") REFERENCES "Mahasiswa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AffinityScoreRoleTeam" ADD CONSTRAINT "AffinityScoreRoleTeam_lobiId_fkey" FOREIGN KEY ("lobiId") REFERENCES "StudentLobby"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AffinityScoreRoleTeam" ADD CONSTRAINT "AffinityScoreRoleTeam_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "RoleLobiTim"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamFormationScore" ADD CONSTRAINT "TeamFormationScore_lobiId_fkey" FOREIGN KEY ("lobiId") REFERENCES "StudentLobby"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TreoProfil" ADD CONSTRAINT "TreoProfil_mahasiswaId_fkey" FOREIGN KEY ("mahasiswaId") REFERENCES "Mahasiswa"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DiskusiTim" ADD CONSTRAINT "DiskusiTim_lobiId_fkey" FOREIGN KEY ("lobiId") REFERENCES "StudentLobby"("id") ON DELETE CASCADE ON UPDATE CASCADE;

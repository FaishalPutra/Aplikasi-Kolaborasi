-- AlterTable
ALTER TABLE "Profil" ADD COLUMN     "visibilitas" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable
CREATE TABLE "AffinityScorePeople" (
    "id" TEXT NOT NULL,
    "mahasiswaAId" TEXT NOT NULL,
    "mahasiswaBId" TEXT NOT NULL,
    "nilaiTotal" DOUBLE PRECISION NOT NULL,
    "detail" JSONB NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AffinityScorePeople_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SavedProfile" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "savedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SavedProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExpressInterest" (
    "id" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "receiverId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExpressInterest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ConnectRequest" (
    "id" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "receiverId" TEXT NOT NULL,
    "status" "StatusPendaftaran" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ConnectRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Connection" (
    "id" TEXT NOT NULL,
    "mahasiswaAId" TEXT NOT NULL,
    "mahasiswaBId" TEXT NOT NULL,
    "connectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Connection_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AffinityScorePeople_mahasiswaAId_mahasiswaBId_key" ON "AffinityScorePeople"("mahasiswaAId", "mahasiswaBId");

-- CreateIndex
CREATE UNIQUE INDEX "SavedProfile_ownerId_targetId_key" ON "SavedProfile"("ownerId", "targetId");

-- CreateIndex
CREATE UNIQUE INDEX "ExpressInterest_senderId_receiverId_key" ON "ExpressInterest"("senderId", "receiverId");

-- CreateIndex
CREATE UNIQUE INDEX "ConnectRequest_senderId_receiverId_key" ON "ConnectRequest"("senderId", "receiverId");

-- CreateIndex
CREATE UNIQUE INDEX "Connection_mahasiswaAId_mahasiswaBId_key" ON "Connection"("mahasiswaAId", "mahasiswaBId");

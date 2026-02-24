-- Add Area Management tables
-- Creates Area and AreaCaptainAssignment tables for attendant department
-- area-based captain groups. Areas group posts by physical location and
-- allow captain assignment for walk-through coordination.

-- CreateTable
CREATE TABLE "Area" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "category" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "departmentId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Area_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AreaCaptain" (
    "id" TEXT NOT NULL,
    "areaId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AreaCaptain_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "Post" ADD COLUMN "areaId" TEXT;

-- CreateIndex
CREATE INDEX "Area_departmentId_idx" ON "Area"("departmentId");

-- CreateIndex
CREATE UNIQUE INDEX "Area_departmentId_category_name_key" ON "Area"("departmentId", "category", "name");

-- CreateIndex
CREATE INDEX "AreaCaptain_eventVolunteerId_idx" ON "AreaCaptain"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "AreaCaptain_sessionId_idx" ON "AreaCaptain"("sessionId");

-- CreateIndex
CREATE UNIQUE INDEX "AreaCaptain_areaId_sessionId_key" ON "AreaCaptain"("areaId", "sessionId");

-- CreateIndex
CREATE INDEX "Post_areaId_idx" ON "Post"("areaId");

-- AddForeignKey
ALTER TABLE "Post" ADD CONSTRAINT "Post_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Area" ADD CONSTRAINT "Area_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaCaptain" ADD CONSTRAINT "AreaCaptain_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaCaptain" ADD CONSTRAINT "AreaCaptain_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaCaptain" ADD CONSTRAINT "AreaCaptain_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

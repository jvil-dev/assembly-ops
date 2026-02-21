-- Cleanup descoped AttendantSection/SectionAssignment tables
-- The database has leftover tables and sectionId columns from the section
-- management feature that was descoped in Sprint 6.6. The schema expects
-- postId on AttendanceCount and SafetyIncident instead.

-- Also add missing SafetyIncidentType enum values
ALTER TYPE "SafetyIncidentType" ADD VALUE IF NOT EXISTS 'SEVERE_WEATHER';
ALTER TYPE "SafetyIncidentType" ADD VALUE IF NOT EXISTS 'ACTIVE_SHOOTER';

-- DropForeignKey
ALTER TABLE "AttendanceCount" DROP CONSTRAINT IF EXISTS "AttendanceCount_sectionId_fkey";

-- DropForeignKey
ALTER TABLE "AttendantSection" DROP CONSTRAINT IF EXISTS "AttendantSection_eventId_fkey";

-- DropForeignKey
ALTER TABLE "SafetyIncident" DROP CONSTRAINT IF EXISTS "SafetyIncident_sectionId_fkey";

-- DropForeignKey
ALTER TABLE "SectionAssignment" DROP CONSTRAINT IF EXISTS "SectionAssignment_eventVolunteerId_fkey";

-- DropForeignKey
ALTER TABLE "SectionAssignment" DROP CONSTRAINT IF EXISTS "SectionAssignment_sectionId_fkey";

-- DropForeignKey
ALTER TABLE "SectionAssignment" DROP CONSTRAINT IF EXISTS "SectionAssignment_sessionId_fkey";

-- DropIndex
DROP INDEX IF EXISTS "AttendanceCount_sectionId_idx";

-- AlterTable: AttendanceCount - drop sectionId, add postId
ALTER TABLE "AttendanceCount" DROP COLUMN IF EXISTS "sectionId",
ADD COLUMN     "postId" TEXT;

-- AlterTable: SafetyIncident - drop sectionId, add postId
ALTER TABLE "SafetyIncident" DROP COLUMN IF EXISTS "sectionId",
ADD COLUMN     "postId" TEXT;

-- DropTable
DROP TABLE IF EXISTS "SectionAssignment";

-- DropTable
DROP TABLE IF EXISTS "AttendantSection";

-- CreateIndex
CREATE INDEX IF NOT EXISTS "AttendanceCount_postId_idx" ON "AttendanceCount"("postId");

-- AddForeignKey
ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;

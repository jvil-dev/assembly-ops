/*
  Warnings:

  - You are about to drop the column `eventId` on the `AttendanceCount` table. All the data in the column will be lost.
  - You are about to drop the column `sessionId` on the `CheckIn` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[sessionId]` on the table `AttendanceCount` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `submittedById` to the `AttendanceCount` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "CheckInStatus" AS ENUM ('CHECKED_IN', 'CHECKED_OUT', 'NO_SHOW');

-- DropForeignKey
ALTER TABLE "AttendanceCount" DROP CONSTRAINT "AttendanceCount_eventId_fkey";

-- DropForeignKey
ALTER TABLE "CheckIn" DROP CONSTRAINT "CheckIn_sessionId_fkey";

-- DropIndex
DROP INDEX "AttendanceCount_eventId_idx";

-- DropIndex
DROP INDEX "AttendanceCount_eventId_sessionId_key";

-- DropIndex
DROP INDEX "CheckIn_checkInTime_idx";

-- DropIndex
DROP INDEX "CheckIn_sessionId_idx";

-- AlterTable
ALTER TABLE "AttendanceCount" DROP COLUMN "eventId",
ADD COLUMN     "submittedById" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "CheckIn" DROP COLUMN "sessionId",
ADD COLUMN     "checkedInById" TEXT,
ADD COLUMN     "notes" TEXT,
ADD COLUMN     "status" "CheckInStatus" NOT NULL DEFAULT 'CHECKED_IN';

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceCount_sessionId_key" ON "AttendanceCount"("sessionId");

-- CreateIndex
CREATE INDEX "AttendanceCount_sessionId_idx" ON "AttendanceCount"("sessionId");

-- CreateIndex
CREATE INDEX "CheckIn_assignmentId_idx" ON "CheckIn"("assignmentId");

-- AddForeignKey
ALTER TABLE "CheckIn" ADD CONSTRAINT "CheckIn_checkedInById_fkey" FOREIGN KEY ("checkedInById") REFERENCES "Admin"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "Admin"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

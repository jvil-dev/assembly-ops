/*
  Warnings:

  - A unique constraint covering the columns `[sessionId,section]` on the table `AttendanceCount` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "AssignmentStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'AUTO_DECLINED');

-- AlterTable
ALTER TABLE "AttendanceCount" ADD COLUMN     "section" TEXT;

-- AlterTable
ALTER TABLE "Event" ADD COLUMN     "acceptDeadlineDays" INTEGER NOT NULL DEFAULT 5;

-- AlterTable
ALTER TABLE "ScheduleAssignment" ADD COLUMN     "acceptedDeadline" TIMESTAMP(3),
ADD COLUMN     "declineReason" TEXT,
ADD COLUMN     "forceAssigned" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isCaptain" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "respondedAt" TIMESTAMP(3),
ADD COLUMN     "status" "AssignmentStatus" NOT NULL DEFAULT 'PENDING';

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceCount_sessionId_section_key" ON "AttendanceCount"("sessionId", "section");

-- CreateIndex
CREATE INDEX "ScheduleAssignment_status_idx" ON "ScheduleAssignment"("status");

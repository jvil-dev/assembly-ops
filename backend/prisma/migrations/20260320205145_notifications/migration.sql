-- DropForeignKey
ALTER TABLE "AVDamageReport" DROP CONSTRAINT "AVDamageReport_reportedById_fkey";

-- DropForeignKey
ALTER TABLE "AVEquipmentCheckout" DROP CONSTRAINT "AVEquipmentCheckout_checkedOutById_fkey";

-- DropForeignKey
ALTER TABLE "AVHazardAssessment" DROP CONSTRAINT "AVHazardAssessment_completedById_fkey";

-- DropForeignKey
ALTER TABLE "AVSafetyBriefing" DROP CONSTRAINT "AVSafetyBriefing_conductedById_fkey";

-- DropForeignKey
ALTER TABLE "AVSafetyBriefingAttendee" DROP CONSTRAINT "AVSafetyBriefingAttendee_eventVolunteerId_fkey";

-- DropForeignKey
ALTER TABLE "AttendanceCount" DROP CONSTRAINT "AttendanceCount_submittedById_fkey";

-- DropForeignKey
ALTER TABLE "AttendantMeeting" DROP CONSTRAINT "AttendantMeeting_createdById_fkey";

-- DropForeignKey
ALTER TABLE "EventNote" DROP CONSTRAINT "EventNote_createdById_fkey";

-- DropForeignKey
ALTER TABLE "LostPersonAlert" DROP CONSTRAINT "LostPersonAlert_reportedById_fkey";

-- DropForeignKey
ALTER TABLE "MeetingAttendance" DROP CONSTRAINT "MeetingAttendance_eventVolunteerId_fkey";

-- DropForeignKey
ALTER TABLE "PostSessionStatus" DROP CONSTRAINT "PostSessionStatus_updatedById_fkey";

-- DropForeignKey
ALTER TABLE "SafetyIncident" DROP CONSTRAINT "SafetyIncident_reportedById_fkey";

-- AlterTable
ALTER TABLE "AVHazardAssessment" ALTER COLUMN "completedById" DROP NOT NULL;

-- AlterTable
ALTER TABLE "AVSafetyBriefing" ALTER COLUMN "conductedById" DROP NOT NULL;

-- AlterTable
ALTER TABLE "AttendanceCount" ALTER COLUMN "submittedById" DROP NOT NULL;

-- AlterTable
ALTER TABLE "AttendantMeeting" ALTER COLUMN "createdById" DROP NOT NULL;

-- AlterTable
ALTER TABLE "EventNote" ALTER COLUMN "createdById" DROP NOT NULL;

-- CreateTable
CREATE TABLE "DeviceToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL DEFAULT 'ios',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DeviceToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DeviceToken_token_key" ON "DeviceToken"("token");

-- CreateIndex
CREATE INDEX "DeviceToken_userId_idx" ON "DeviceToken"("userId");

-- CreateIndex
CREATE INDEX "Notification_userId_eventId_idx" ON "Notification"("userId", "eventId");

-- CreateIndex
CREATE INDEX "Notification_createdAt_idx" ON "Notification"("createdAt");

-- AddForeignKey
ALTER TABLE "DeviceToken" ADD CONSTRAINT "DeviceToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendantMeeting" ADD CONSTRAINT "AttendantMeeting_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventNote" ADD CONSTRAINT "EventNote_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingAttendance" ADD CONSTRAINT "MeetingAttendance_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PostSessionStatus" ADD CONSTRAINT "PostSessionStatus_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVEquipmentCheckout" ADD CONSTRAINT "AVEquipmentCheckout_checkedOutById_fkey" FOREIGN KEY ("checkedOutById") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVDamageReport" ADD CONSTRAINT "AVDamageReport_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVHazardAssessment" ADD CONSTRAINT "AVHazardAssessment_completedById_fkey" FOREIGN KEY ("completedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVSafetyBriefing" ADD CONSTRAINT "AVSafetyBriefing_conductedById_fkey" FOREIGN KEY ("conductedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVSafetyBriefingAttendee" ADD CONSTRAINT "AVSafetyBriefingAttendee_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- RenameIndex
ALTER INDEX "ScheduleAssignment_eventVolunteerId_postId_sessionId_shiftId_ke" RENAME TO "ScheduleAssignment_eventVolunteerId_postId_sessionId_shiftI_key";

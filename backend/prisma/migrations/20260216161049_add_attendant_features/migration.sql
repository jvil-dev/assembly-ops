-- CreateEnum
CREATE TYPE "SafetyIncidentType" AS ENUM ('BUILDING_DEFECT', 'WET_FLOOR', 'UNSAFE_CONDITION', 'MEDICAL_EMERGENCY', 'DISRUPTIVE_INDIVIDUAL', 'OTHER');

-- AlterTable
ALTER TABLE "AttendanceCount" ADD COLUMN     "postId" TEXT;

-- CreateTable
CREATE TABLE "AttendantMeeting" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "meetingDate" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AttendantMeeting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LostPersonAlert" (
    "id" TEXT NOT NULL,
    "personName" TEXT NOT NULL,
    "age" INTEGER,
    "description" TEXT NOT NULL,
    "lastSeenLocation" TEXT,
    "lastSeenTime" TIMESTAMP(3),
    "contactName" TEXT NOT NULL,
    "contactPhone" TEXT,
    "reportedById" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "resolvedAt" TIMESTAMP(3),
    "resolvedById" TEXT,
    "resolutionNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,

    CONSTRAINT "LostPersonAlert_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MeetingAttendance" (
    "id" TEXT NOT NULL,
    "meetingId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,

    CONSTRAINT "MeetingAttendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SafetyIncident" (
    "id" TEXT NOT NULL,
    "type" "SafetyIncidentType" NOT NULL,
    "description" TEXT NOT NULL,
    "location" TEXT,
    "postId" TEXT,
    "reportedById" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "resolvedAt" TIMESTAMP(3),
    "resolvedById" TEXT,
    "resolutionNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,

    CONSTRAINT "SafetyIncident_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AttendantMeeting_eventId_idx" ON "AttendantMeeting"("eventId");

-- CreateIndex
CREATE INDEX "LostPersonAlert_eventId_idx" ON "LostPersonAlert"("eventId");

-- CreateIndex
CREATE INDEX "LostPersonAlert_resolved_idx" ON "LostPersonAlert"("resolved");

-- CreateIndex
CREATE UNIQUE INDEX "MeetingAttendance_meetingId_eventVolunteerId_key" ON "MeetingAttendance"("meetingId", "eventVolunteerId");

-- CreateIndex
CREATE INDEX "SafetyIncident_eventId_idx" ON "SafetyIncident"("eventId");

-- CreateIndex
CREATE INDEX "SafetyIncident_resolved_idx" ON "SafetyIncident"("resolved");

-- CreateIndex
CREATE INDEX "AttendanceCount_postId_idx" ON "AttendanceCount"("postId");

-- AddForeignKey
ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendantMeeting" ADD CONSTRAINT "AttendantMeeting_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendantMeeting" ADD CONSTRAINT "AttendantMeeting_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendantMeeting" ADD CONSTRAINT "AttendantMeeting_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "Admin"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "Admin"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingAttendance" ADD CONSTRAINT "MeetingAttendance_meetingId_fkey" FOREIGN KEY ("meetingId") REFERENCES "AttendantMeeting"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingAttendance" ADD CONSTRAINT "MeetingAttendance_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingAttendance" ADD CONSTRAINT "MeetingAttendance_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "Admin"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

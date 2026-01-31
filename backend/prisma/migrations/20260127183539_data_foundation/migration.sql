/*
  Warnings:

  - A unique constraint covering the columns `[eventVolunteerId,sessionId]` on the table `ScheduleAssignment` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "Admin" ADD COLUMN     "congregationId" TEXT;

-- AlterTable
ALTER TABLE "CheckIn" ADD COLUMN     "checkedInByVolId" TEXT;

-- AlterTable
ALTER TABLE "EventTemplate" ADD COLUMN     "circuitId" TEXT;

-- AlterTable
ALTER TABLE "Message" ADD COLUMN     "eventVolunteerId" TEXT;

-- AlterTable
ALTER TABLE "RefreshToken" ADD COLUMN     "eventVolunteerId" TEXT;

-- AlterTable
ALTER TABLE "ScheduleAssignment" ADD COLUMN     "eventVolunteerId" TEXT,
ALTER COLUMN "volunteerId" DROP NOT NULL;

-- CreateTable
CREATE TABLE "Circuit" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "region" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'E',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Circuit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Congregation" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'E',
    "circuitId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Congregation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VolunteerProfile" (
    "id" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "appointmentStatus" "AppointmentStatus" NOT NULL DEFAULT 'PUBLISHER',
    "notes" TEXT,
    "congregationId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VolunteerProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventVolunteer" (
    "id" TEXT NOT NULL,
    "volunteerId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "volunteerProfileId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "departmentId" TEXT,
    "roleId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventVolunteer_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Circuit_code_key" ON "Circuit"("code");

-- CreateIndex
CREATE INDEX "Circuit_region_idx" ON "Circuit"("region");

-- CreateIndex
CREATE INDEX "Circuit_language_idx" ON "Circuit"("language");

-- CreateIndex
CREATE INDEX "Congregation_circuitId_idx" ON "Congregation"("circuitId");

-- CreateIndex
CREATE INDEX "Congregation_state_language_idx" ON "Congregation"("state", "language");

-- CreateIndex
CREATE UNIQUE INDEX "Congregation_name_city_state_key" ON "Congregation"("name", "city", "state");

-- CreateIndex
CREATE INDEX "VolunteerProfile_congregationId_idx" ON "VolunteerProfile"("congregationId");

-- CreateIndex
CREATE INDEX "VolunteerProfile_lastName_firstName_idx" ON "VolunteerProfile"("lastName", "firstName");

-- CreateIndex
CREATE UNIQUE INDEX "EventVolunteer_volunteerId_key" ON "EventVolunteer"("volunteerId");

-- CreateIndex
CREATE INDEX "EventVolunteer_eventId_idx" ON "EventVolunteer"("eventId");

-- CreateIndex
CREATE INDEX "EventVolunteer_departmentId_idx" ON "EventVolunteer"("departmentId");

-- CreateIndex
CREATE INDEX "EventVolunteer_volunteerProfileId_idx" ON "EventVolunteer"("volunteerProfileId");

-- CreateIndex
CREATE UNIQUE INDEX "EventVolunteer_volunteerProfileId_eventId_key" ON "EventVolunteer"("volunteerProfileId", "eventId");

-- CreateIndex
CREATE INDEX "Admin_congregationId_idx" ON "Admin"("congregationId");

-- CreateIndex
CREATE INDEX "EventTemplate_circuitId_idx" ON "EventTemplate"("circuitId");

-- CreateIndex
CREATE INDEX "Message_eventVolunteerId_idx" ON "Message"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "RefreshToken_eventVolunteerId_idx" ON "RefreshToken"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "ScheduleAssignment_eventVolunteerId_idx" ON "ScheduleAssignment"("eventVolunteerId");

-- CreateIndex
CREATE UNIQUE INDEX "ScheduleAssignment_eventVolunteerId_sessionId_key" ON "ScheduleAssignment"("eventVolunteerId", "sessionId");

-- AddForeignKey
ALTER TABLE "Congregation" ADD CONSTRAINT "Congregation_circuitId_fkey" FOREIGN KEY ("circuitId") REFERENCES "Circuit"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VolunteerProfile" ADD CONSTRAINT "VolunteerProfile_congregationId_fkey" FOREIGN KEY ("congregationId") REFERENCES "Congregation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_volunteerProfileId_fkey" FOREIGN KEY ("volunteerProfileId") REFERENCES "VolunteerProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Admin" ADD CONSTRAINT "Admin_congregationId_fkey" FOREIGN KEY ("congregationId") REFERENCES "Congregation"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CheckIn" ADD CONSTRAINT "CheckIn_checkedInByVolId_fkey" FOREIGN KEY ("checkedInByVolId") REFERENCES "EventVolunteer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventTemplate" ADD CONSTRAINT "EventTemplate_circuitId_fkey" FOREIGN KEY ("circuitId") REFERENCES "Circuit"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduleAssignment" ADD CONSTRAINT "ScheduleAssignment_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

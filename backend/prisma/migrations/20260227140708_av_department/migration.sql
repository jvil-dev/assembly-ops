-- CreateEnum
CREATE TYPE "AVEquipmentCategory" AS ENUM ('CAMERA_PTZ', 'CAMERA_MANNED', 'TRIPOD', 'AUDIO_MIXER', 'VIDEO_SWITCHER', 'MEDIA_PLAYER', 'LED_PANEL', 'LOUDSPEAKER', 'MICROPHONE', 'STAGE_MONITOR', 'INTERCOM', 'CABLE', 'STAGE_LIGHTING', 'RECORDING_DEVICE', 'ASSISTIVE_LISTENING', 'ACCESSORY');

-- CreateEnum
CREATE TYPE "AVEquipmentCondition" AS ENUM ('GOOD', 'NEEDS_REPAIR', 'OUT_OF_SERVICE');

-- CreateEnum
CREATE TYPE "AVDamageSeverity" AS ENUM ('MINOR', 'MODERATE', 'SEVERE');

-- CreateEnum
CREATE TYPE "AVHazardType" AS ENUM ('WORKING_AT_HEIGHT', 'ELECTRICAL_EXPOSURE', 'ELEVATED_PLATFORM', 'POWER_TOOLS', 'MOVING_EQUIPMENT', 'NEAR_STAIRS', 'UNEVEN_SURFACE', 'HEAVY_LIFTING', 'PINCH_CRUSH_CUT', 'EXTREME_CONDITIONS');

-- AlterEnum
ALTER TYPE "HierarchyRole" ADD VALUE 'AREA_OVERSEER';

-- AlterTable
ALTER TABLE "DepartmentHierarchy" ADD COLUMN     "areaId" TEXT;

-- AlterTable
ALTER TABLE "WalkThroughCompletion" ADD COLUMN     "checklistType" TEXT;

-- CreateTable
CREATE TABLE "AVEquipmentItem" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "model" TEXT,
    "serialNumber" TEXT,
    "category" "AVEquipmentCategory" NOT NULL,
    "condition" "AVEquipmentCondition" NOT NULL DEFAULT 'GOOD',
    "location" TEXT,
    "notes" TEXT,
    "areaId" TEXT,
    "eventId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AVEquipmentItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AVEquipmentCheckout" (
    "id" TEXT NOT NULL,
    "equipmentId" TEXT NOT NULL,
    "checkedOutById" TEXT NOT NULL,
    "checkedOutAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "checkedInAt" TIMESTAMP(3),
    "sessionId" TEXT,
    "notes" TEXT,

    CONSTRAINT "AVEquipmentCheckout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AVDamageReport" (
    "id" TEXT NOT NULL,
    "equipmentId" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "severity" "AVDamageSeverity" NOT NULL,
    "reportedById" TEXT NOT NULL,
    "sessionId" TEXT,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "resolvedAt" TIMESTAMP(3),
    "resolvedById" TEXT,
    "resolutionNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AVDamageReport_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AVHazardAssessment" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "hazardType" "AVHazardType" NOT NULL,
    "description" TEXT NOT NULL,
    "controls" TEXT NOT NULL,
    "ppeRequired" TEXT[],
    "completedById" TEXT NOT NULL,
    "sessionId" TEXT,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AVHazardAssessment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AVSafetyBriefing" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "topic" TEXT NOT NULL,
    "notes" TEXT,
    "conductedById" TEXT NOT NULL,
    "conductedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AVSafetyBriefing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AVSafetyBriefingAttendee" (
    "id" TEXT NOT NULL,
    "briefingId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AVSafetyBriefingAttendee_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AVEquipmentItem_eventId_idx" ON "AVEquipmentItem"("eventId");

-- CreateIndex
CREATE INDEX "AVEquipmentItem_areaId_idx" ON "AVEquipmentItem"("areaId");

-- CreateIndex
CREATE INDEX "AVEquipmentItem_category_idx" ON "AVEquipmentItem"("category");

-- CreateIndex
CREATE INDEX "AVEquipmentCheckout_equipmentId_idx" ON "AVEquipmentCheckout"("equipmentId");

-- CreateIndex
CREATE INDEX "AVEquipmentCheckout_checkedOutById_idx" ON "AVEquipmentCheckout"("checkedOutById");

-- CreateIndex
CREATE INDEX "AVEquipmentCheckout_checkedInAt_idx" ON "AVEquipmentCheckout"("checkedInAt");

-- CreateIndex
CREATE INDEX "AVDamageReport_equipmentId_idx" ON "AVDamageReport"("equipmentId");

-- CreateIndex
CREATE INDEX "AVDamageReport_resolved_idx" ON "AVDamageReport"("resolved");

-- CreateIndex
CREATE INDEX "AVHazardAssessment_eventId_idx" ON "AVHazardAssessment"("eventId");

-- CreateIndex
CREATE INDEX "AVSafetyBriefing_eventId_idx" ON "AVSafetyBriefing"("eventId");

-- CreateIndex
CREATE UNIQUE INDEX "AVSafetyBriefingAttendee_briefingId_eventVolunteerId_key" ON "AVSafetyBriefingAttendee"("briefingId", "eventVolunteerId");

-- CreateIndex
CREATE INDEX "DepartmentHierarchy_areaId_idx" ON "DepartmentHierarchy"("areaId");

-- AddForeignKey
ALTER TABLE "DepartmentHierarchy" ADD CONSTRAINT "DepartmentHierarchy_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVEquipmentItem" ADD CONSTRAINT "AVEquipmentItem_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVEquipmentItem" ADD CONSTRAINT "AVEquipmentItem_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVEquipmentCheckout" ADD CONSTRAINT "AVEquipmentCheckout_equipmentId_fkey" FOREIGN KEY ("equipmentId") REFERENCES "AVEquipmentItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVEquipmentCheckout" ADD CONSTRAINT "AVEquipmentCheckout_checkedOutById_fkey" FOREIGN KEY ("checkedOutById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVEquipmentCheckout" ADD CONSTRAINT "AVEquipmentCheckout_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVDamageReport" ADD CONSTRAINT "AVDamageReport_equipmentId_fkey" FOREIGN KEY ("equipmentId") REFERENCES "AVEquipmentItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVDamageReport" ADD CONSTRAINT "AVDamageReport_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVDamageReport" ADD CONSTRAINT "AVDamageReport_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVDamageReport" ADD CONSTRAINT "AVDamageReport_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVHazardAssessment" ADD CONSTRAINT "AVHazardAssessment_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVHazardAssessment" ADD CONSTRAINT "AVHazardAssessment_completedById_fkey" FOREIGN KEY ("completedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVHazardAssessment" ADD CONSTRAINT "AVHazardAssessment_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVSafetyBriefing" ADD CONSTRAINT "AVSafetyBriefing_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVSafetyBriefing" ADD CONSTRAINT "AVSafetyBriefing_conductedById_fkey" FOREIGN KEY ("conductedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVSafetyBriefingAttendee" ADD CONSTRAINT "AVSafetyBriefingAttendee_briefingId_fkey" FOREIGN KEY ("briefingId") REFERENCES "AVSafetyBriefing"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AVSafetyBriefingAttendee" ADD CONSTRAINT "AVSafetyBriefingAttendee_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

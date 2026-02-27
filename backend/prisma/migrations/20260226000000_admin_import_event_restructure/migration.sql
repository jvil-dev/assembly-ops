-- =====================================================
-- Sprint 6.12.5: Admin Import Pipeline + Event Restructure
-- =====================================================

-- Step 0: Remove city from Congregation
ALTER TABLE "Congregation" DROP COLUMN "city";
DROP INDEX IF EXISTS "Congregation_name_city_state_key";
CREATE UNIQUE INDEX "Congregation_name_state_key" ON "Congregation"("name", "state");

-- Step 1: Add isAppAdmin to User
ALTER TABLE "User" ADD COLUMN "isAppAdmin" BOOLEAN NOT NULL DEFAULT false;

-- Step 2: Add Department enhancements (accessCode, isPublic, DepartmentHierarchy)
ALTER TABLE "Department" ADD COLUMN "accessCode" TEXT;
ALTER TABLE "Department" ADD COLUMN "isPublic" BOOLEAN NOT NULL DEFAULT true;
CREATE UNIQUE INDEX "Department_accessCode_key" ON "Department"("accessCode");
CREATE INDEX "Department_accessCode_idx" ON "Department"("accessCode");

-- HierarchyRole enum
CREATE TYPE "HierarchyRole" AS ENUM ('ASSISTANT_OVERSEER');

-- DepartmentHierarchy table
CREATE TABLE "DepartmentHierarchy" (
    "id" TEXT NOT NULL,
    "departmentId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "hierarchyRole" "HierarchyRole" NOT NULL,
    "assignedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "DepartmentHierarchy_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "DepartmentHierarchy_departmentId_hierarchyRole_eventVolunteerId_key" ON "DepartmentHierarchy"("departmentId", "hierarchyRole", "eventVolunteerId");
CREATE INDEX "DepartmentHierarchy_departmentId_idx" ON "DepartmentHierarchy"("departmentId");
CREATE INDEX "DepartmentHierarchy_eventVolunteerId_idx" ON "DepartmentHierarchy"("eventVolunteerId");
ALTER TABLE "DepartmentHierarchy" ADD CONSTRAINT "DepartmentHierarchy_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "DepartmentHierarchy" ADD CONSTRAINT "DepartmentHierarchy_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Step 3: Fix EventRole enum (remove APP_ADMIN if present)
-- Create new enum without APP_ADMIN
CREATE TYPE "EventRole_new" AS ENUM ('DEPARTMENT_OVERSEER');
ALTER TABLE "EventAdmin" ALTER COLUMN "role" TYPE "EventRole_new" USING ("role"::text::"EventRole_new");
ALTER TYPE "EventRole" RENAME TO "EventRole_old";
ALTER TYPE "EventRole_new" RENAME TO "EventRole";
DROP TYPE "EventRole_old";

-- Step 4: EventType enum — replace CIRCUIT_ASSEMBLY with CO/BR variants
-- Strategy: create new enum, migrate column, swap
CREATE TYPE "EventType_new" AS ENUM ('CIRCUIT_ASSEMBLY_CO', 'CIRCUIT_ASSEMBLY_BR', 'REGIONAL_CONVENTION', 'SPECIAL_CONVENTION');

-- Migrate EventTemplate.eventType to new enum (map old CIRCUIT_ASSEMBLY → CIRCUIT_ASSEMBLY_CO)
ALTER TABLE "EventTemplate" ALTER COLUMN "eventType" TYPE "EventType_new"
  USING (CASE WHEN "eventType"::text = 'CIRCUIT_ASSEMBLY' THEN 'CIRCUIT_ASSEMBLY_CO'::"EventType_new" ELSE "eventType"::text::"EventType_new" END);

ALTER TYPE "EventType" RENAME TO "EventType_old";
ALTER TYPE "EventType_new" RENAME TO "EventType";
DROP TYPE "EventType_old";

-- Step 5: Absorb EventTemplate into Event
-- 5a: Add new columns to Event (temporarily nullable)
ALTER TABLE "Event" ADD COLUMN "eventType" "EventType";
ALTER TABLE "Event" ADD COLUMN "name" TEXT;
ALTER TABLE "Event" ADD COLUMN "circuit" TEXT;
ALTER TABLE "Event" ADD COLUMN "circuitId" TEXT;
ALTER TABLE "Event" ADD COLUMN "region" TEXT;
ALTER TABLE "Event" ADD COLUMN "state" TEXT;
ALTER TABLE "Event" ADD COLUMN "serviceYear" INTEGER;
ALTER TABLE "Event" ADD COLUMN "theme" TEXT;
ALTER TABLE "Event" ADD COLUMN "themeScripture" TEXT;
ALTER TABLE "Event" ADD COLUMN "venue" TEXT;
ALTER TABLE "Event" ADD COLUMN "address" TEXT;
ALTER TABLE "Event" ADD COLUMN "startDate" TIMESTAMP(3);
ALTER TABLE "Event" ADD COLUMN "endDate" TIMESTAMP(3);
ALTER TABLE "Event" ADD COLUMN "language" TEXT DEFAULT 'en';

-- 5b: Copy data from EventTemplate to Event
UPDATE "Event" e SET
  "eventType" = et."eventType",
  "name" = et."name",
  "circuit" = et."circuit",
  "circuitId" = et."circuitId",
  "region" = et."region",
  "serviceYear" = et."serviceYear",
  "theme" = et."theme",
  "themeScripture" = et."themeScripture",
  "venue" = et."venue",
  "address" = et."address",
  "startDate" = et."startDate",
  "endDate" = et."endDate",
  "language" = et."language"
FROM "EventTemplate" et
WHERE e."templateId" = et."id";

-- 5c: Derive state from region
UPDATE "Event" SET "state" = SUBSTRING("region" FROM 4) WHERE "region" LIKE 'US-%';

-- 5d: For any Events without a template match, set required fields to defaults
-- (shouldn't happen but safeguard)
UPDATE "Event" SET
  "eventType" = 'CIRCUIT_ASSEMBLY_CO',
  "name" = 'Unknown Event',
  "region" = 'US-XX',
  "serviceYear" = 2026,
  "venue" = 'Unknown',
  "address" = 'Unknown',
  "startDate" = NOW(),
  "endDate" = NOW(),
  "language" = 'en'
WHERE "eventType" IS NULL;

-- 5e: Set NOT NULL on required columns
ALTER TABLE "Event" ALTER COLUMN "eventType" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "name" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "region" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "serviceYear" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "venue" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "address" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "startDate" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "endDate" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "language" SET NOT NULL;
ALTER TABLE "Event" ALTER COLUMN "language" SET DEFAULT 'en';

-- 5f: Drop templateId column and constraints
DROP INDEX IF EXISTS "Event_templateId_idx";
ALTER TABLE "Event" DROP CONSTRAINT IF EXISTS "Event_templateId_fkey";
ALTER TABLE "Event" DROP COLUMN "templateId";

-- 5g: Drop EventTemplate table
DROP TABLE "EventTemplate";

-- 5h: Add new indexes and constraints on Event
CREATE UNIQUE INDEX "Event_eventType_venue_startDate_language_key" ON "Event"("eventType", "venue", "startDate", "language");
CREATE INDEX "Event_circuitId_idx" ON "Event"("circuitId");
CREATE INDEX "Event_region_idx" ON "Event"("region");
CREATE INDEX "Event_serviceYear_idx" ON "Event"("serviceYear");
CREATE INDEX "Event_state_idx" ON "Event"("state");

-- 5i: Add FK from Event.circuitId to Circuit
ALTER TABLE "Event" ADD CONSTRAINT "Event_circuitId_fkey" FOREIGN KEY ("circuitId") REFERENCES "Circuit"("id") ON DELETE SET NULL ON UPDATE CASCADE;

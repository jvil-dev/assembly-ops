-- Drop FacilityLocation table and add floorPlanKey to Event
DROP TABLE IF EXISTS "FacilityLocation";

ALTER TABLE "Event" ADD COLUMN IF NOT EXISTS "floorPlanKey" TEXT;

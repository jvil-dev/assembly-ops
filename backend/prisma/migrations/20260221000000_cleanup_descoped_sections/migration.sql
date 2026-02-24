-- Cleanup descoped AttendantSection/SectionAssignment tables
-- The production database may have leftover tables and sectionId columns from
-- the section management feature that was descoped in Sprint 6.6.
-- On a fresh database (shadow DB), these objects don't exist, so all
-- statements use IF EXISTS / IF NOT EXISTS for idempotency.

-- Add missing SafetyIncidentType enum values
ALTER TYPE "SafetyIncidentType" ADD VALUE IF NOT EXISTS 'SEVERE_WEATHER';
ALTER TYPE "SafetyIncidentType" ADD VALUE IF NOT EXISTS 'ACTIVE_SHOOTER';

-- Drop stale foreign keys (only exist if sectionId columns were pushed outside migrations)
ALTER TABLE "AttendanceCount" DROP CONSTRAINT IF EXISTS "AttendanceCount_sectionId_fkey";
ALTER TABLE "SafetyIncident" DROP CONSTRAINT IF EXISTS "SafetyIncident_sectionId_fkey";

-- Drop stale index
DROP INDEX IF EXISTS "AttendanceCount_sectionId_idx";

-- Drop stale sectionId columns (no-op on fresh DB where they never existed)
ALTER TABLE "AttendanceCount" DROP COLUMN IF EXISTS "sectionId";
ALTER TABLE "SafetyIncident" DROP COLUMN IF EXISTS "sectionId";

-- Drop descoped tables (no-op on fresh DB)
DROP TABLE IF EXISTS "SectionAssignment";
DROP TABLE IF EXISTS "AttendantSection";

-- Ensure postId column exists (already added by 20260216161049_add_attendant_features,
-- but needed if that migration ran against a DB with conflicting state)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'AttendanceCount' AND column_name = 'postId'
    ) THEN
        ALTER TABLE "AttendanceCount" ADD COLUMN "postId" TEXT;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'SafetyIncident' AND column_name = 'postId'
    ) THEN
        ALTER TABLE "SafetyIncident" ADD COLUMN "postId" TEXT;
    END IF;
END $$;

-- Ensure index exists
CREATE INDEX IF NOT EXISTS "AttendanceCount_postId_idx" ON "AttendanceCount"("postId");

-- Ensure foreign keys exist (use DO block to check before adding)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'AttendanceCount_postId_fkey'
    ) THEN
        ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_postId_fkey"
            FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'SafetyIncident_postId_fkey'
    ) THEN
        ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_postId_fkey"
            FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

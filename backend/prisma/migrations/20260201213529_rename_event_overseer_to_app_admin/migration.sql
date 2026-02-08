-- AlterEnum: Rename EVENT_OVERSEER to APP_ADMIN with data migration
BEGIN;

-- Step 1: Add APP_ADMIN to existing enum
ALTER TYPE "EventRole" ADD VALUE 'APP_ADMIN';

COMMIT;

-- Step 2: Migrate existing data (separate transaction required)
UPDATE "EventAdmin" SET "role" = 'APP_ADMIN' WHERE "role" = 'EVENT_OVERSEER';

-- Step 3: Recreate enum without EVENT_OVERSEER
BEGIN;

CREATE TYPE "EventRole_new" AS ENUM ('APP_ADMIN', 'DEPARTMENT_OVERSEER');
ALTER TABLE "EventAdmin" ALTER COLUMN "role" TYPE "EventRole_new" USING ("role"::text::"EventRole_new");
ALTER TYPE "EventRole" RENAME TO "EventRole_old";
ALTER TYPE "EventRole_new" RENAME TO "EventRole";
DROP TYPE "EventRole_old";

COMMIT;

-- AlterTable: Drop Circuit.name column
ALTER TABLE "Circuit" DROP COLUMN IF EXISTS "name";

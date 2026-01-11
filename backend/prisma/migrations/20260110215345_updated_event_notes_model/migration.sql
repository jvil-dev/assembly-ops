/*
  Warnings:

  - The values [INFORMATION_VOLUNTEER_SERVICE] on the enum `RecipientType` will be removed. If these variants are still used in the database, this will fail.
  - Migrating "content" column to "body" in EventNote table.
  - Adding required "createdById" column to EventNote table.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "RecipientType_new" AS ENUM ('VOLUNTEER', 'DEPARTMENT', 'EVENT');
ALTER TABLE "Message" ALTER COLUMN "recipientType" TYPE "RecipientType_new" USING ("recipientType"::text::"RecipientType_new");
ALTER TYPE "RecipientType" RENAME TO "RecipientType_old";
ALTER TYPE "RecipientType_new" RENAME TO "RecipientType";
DROP TYPE "public"."RecipientType_old";
COMMIT;

-- AlterTable: Add new columns as nullable first
ALTER TABLE "EventNote"
ADD COLUMN IF NOT EXISTS "body" TEXT,
ADD COLUMN IF NOT EXISTS "createdById" TEXT,
ADD COLUMN IF NOT EXISTS "title" TEXT;

-- Migrate data: Copy content to body for existing rows
UPDATE "EventNote" SET "body" = "content" WHERE "body" IS NULL AND "content" IS NOT NULL;

-- Set createdById for existing rows: use the event overseer admin if available
UPDATE "EventNote" en
SET "createdById" = (
    SELECT ea."adminId"
    FROM "EventAdmin" ea
    WHERE ea."eventId" = en."eventId" AND ea."role" = 'EVENT_OVERSEER'
    LIMIT 1
)
WHERE en."createdById" IS NULL;

-- Fallback: If no event overseer, use any admin associated with the event
UPDATE "EventNote" en
SET "createdById" = (
    SELECT ea."adminId"
    FROM "EventAdmin" ea
    WHERE ea."eventId" = en."eventId"
    LIMIT 1
)
WHERE en."createdById" IS NULL;

-- Make columns NOT NULL after data migration
ALTER TABLE "EventNote" ALTER COLUMN "body" SET NOT NULL;
ALTER TABLE "EventNote" ALTER COLUMN "createdById" SET NOT NULL;

-- Drop old content column
ALTER TABLE "EventNote" DROP COLUMN IF EXISTS "content";

-- AddForeignKey
ALTER TABLE "EventNote" ADD CONSTRAINT "EventNote_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "Admin"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AlterTable
ALTER TABLE "assignments" ADD COLUMN     "deleted_at" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "check_ins" ADD COLUMN     "deleted_at" TIMESTAMP(3);

-- AlterTable: Add columns to messages
-- First add updated_at with a default for existing rows
ALTER TABLE "messages" ADD COLUMN     "deleted_at" TIMESTAMP(3);
ALTER TABLE "messages" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL DEFAULT NOW();

-- Update existing rows to use created_at as updated_at
UPDATE "messages" SET "updated_at" = "created_at" WHERE "updated_at" = NOW();

-- Remove the default (Prisma will handle it via @updatedAt)
ALTER TABLE "messages" ALTER COLUMN "updated_at" DROP DEFAULT;

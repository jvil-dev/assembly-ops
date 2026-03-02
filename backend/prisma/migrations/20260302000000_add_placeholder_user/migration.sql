-- AlterTable
ALTER TABLE "User" ADD COLUMN "isPlaceholder" BOOLEAN NOT NULL DEFAULT false;

-- Retroactively mark existing shell users as placeholders
UPDATE "User" SET "isPlaceholder" = true WHERE email LIKE '%@placeholder.assemblyops.io';

-- CreateIndex
CREATE INDEX "User_isPlaceholder_idx" ON "User"("isPlaceholder");

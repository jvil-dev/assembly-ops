-- AlterTable
ALTER TABLE "Post" ADD COLUMN     "category" TEXT,
ADD COLUMN     "sortOrder" INTEGER NOT NULL DEFAULT 0;

/*
  Warnings:

  - You are about to drop the column `encryptedToken` on the `EventVolunteer` table. All the data in the column will be lost.
  - You are about to drop the column `tokenHash` on the `EventVolunteer` table. All the data in the column will be lost.
  - You are about to drop the column `volunteerId` on the `EventVolunteer` table. All the data in the column will be lost.
  - You are about to drop the column `eventVolunteerId` on the `RefreshToken` table. All the data in the column will be lost.
  - Made the column `userId` on table `RefreshToken` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "RefreshToken" DROP CONSTRAINT "RefreshToken_eventVolunteerId_fkey";

-- DropIndex
DROP INDEX "EventVolunteer_volunteerId_key";

-- DropIndex
DROP INDEX "RefreshToken_eventVolunteerId_idx";

-- AlterTable
ALTER TABLE "EventVolunteer" DROP COLUMN "encryptedToken",
DROP COLUMN "tokenHash",
DROP COLUMN "volunteerId";

-- AlterTable
ALTER TABLE "RefreshToken" DROP COLUMN "eventVolunteerId",
ALTER COLUMN "userId" SET NOT NULL;

-- RenameIndex
ALTER INDEX "DepartmentHierarchy_departmentId_hierarchyRole_eventVolunteerId" RENAME TO "DepartmentHierarchy_departmentId_hierarchyRole_eventVolunte_key";

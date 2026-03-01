/*
  Warnings:

  - The values [AUDIO_VIDEO] on the enum `DepartmentType` will be removed. If these variants are still used in the database, this will fail.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "DepartmentType_new" AS ENUM ('ACCOUNTS', 'ATTENDANT', 'AUDIO', 'BAPTISM', 'CLEANING', 'FIRST_AID', 'INFORMATION_VOLUNTEER_SERVICE', 'INSTALLATION', 'LOST_FOUND_CHECKROOM', 'PARKING', 'ROOMING', 'STAGE', 'TRUCKING_EQUIPMENT', 'VIDEO');
ALTER TABLE "EventJoinRequest" ALTER COLUMN "departmentType" TYPE "DepartmentType_new" USING ("departmentType"::text::"DepartmentType_new");
ALTER TABLE "Department" ALTER COLUMN "departmentType" TYPE "DepartmentType_new" USING ("departmentType"::text::"DepartmentType_new");
ALTER TYPE "DepartmentType" RENAME TO "DepartmentType_old";
ALTER TYPE "DepartmentType_new" RENAME TO "DepartmentType";
DROP TYPE "public"."DepartmentType_old";
COMMIT;

/*
  Warnings:

  - The values [ZONE] on the enum `RecipientType` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `assignment_id` on the `check_ins` table. All the data in the column will be lost.
  - You are about to drop the column `deleted_at` on the `check_ins` table. All the data in the column will be lost.
  - You are about to drop the column `deleted_at` on the `messages` table. All the data in the column will be lost.
  - You are about to drop the column `target_zone_id` on the `messages` table. All the data in the column will be lost.
  - You are about to drop the column `name` on the `volunteers` table. All the data in the column will be lost.
  - You are about to drop the column `roleId` on the `volunteers` table. All the data in the column will be lost.
  - The `appointment` column on the `volunteers` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the `assignments` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `message_recepientes` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `swap_requests` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `zone` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[schedule_assignment_id]` on the table `check_ins` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `schedule_assignment_id` to the `check_ins` table without a default value. This is not possible if the table is not empty.
  - Added the required column `volunteer_id` to the `check_ins` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `volunteer_availability` table without a default value. This is not possible if the table is not empty.
  - Added the required column `first_name` to the `volunteers` table without a default value. This is not possible if the table is not empty.
  - Added the required column `last_name` to the `volunteers` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "AdminType" AS ENUM ('EVENT_ADMIN', 'DEPARTMENT_ADMIN');

-- CreateEnum
CREATE TYPE "DepartmentType" AS ENUM ('ACCOUNTS', 'ATTENDANT', 'AUDIO_VIDEO', 'BAPTISM', 'CLEANING', 'FIRST_AID', 'INFORMATION_VOLUNTEER_SERVICE', 'INSTALLATION', 'LOST_FOUND_CHECKROOM', 'PARKING', 'ROOMING', 'TRUCKING_EQUIPMENT');

-- CreateEnum
CREATE TYPE "Appointment" AS ENUM ('PUBLISHER', 'MINISTERIAL_SERVANT', 'ELDER');

-- CreateEnum
CREATE TYPE "NoteCategory" AS ENUM ('GENERAL', 'IMPROVEMENT', 'ISSUE', 'STAFFING', 'LOGISTICS', 'COMMUNICATION');

-- AlterEnum
BEGIN;
CREATE TYPE "RecipientType_new" AS ENUM ('INDIVIDUAL', 'POST', 'ROLE', 'DEPARTMENT', 'BROADCAST');
ALTER TABLE "messages" ALTER COLUMN "recipientType" TYPE "RecipientType_new" USING ("recipientType"::text::"RecipientType_new");
ALTER TYPE "RecipientType" RENAME TO "RecipientType_old";
ALTER TYPE "RecipientType_new" RENAME TO "RecipientType";
DROP TYPE "public"."RecipientType_old";
COMMIT;

-- DropForeignKey
ALTER TABLE "assignments" DROP CONSTRAINT "assignments_session_id_fkey";

-- DropForeignKey
ALTER TABLE "assignments" DROP CONSTRAINT "assignments_volunteer_id_fkey";

-- DropForeignKey
ALTER TABLE "assignments" DROP CONSTRAINT "assignments_zone_id_fkey";

-- DropForeignKey
ALTER TABLE "check_ins" DROP CONSTRAINT "check_ins_assignment_id_fkey";

-- DropForeignKey
ALTER TABLE "message_recepientes" DROP CONSTRAINT "message_recepientes_message_id_fkey";

-- DropForeignKey
ALTER TABLE "message_recepientes" DROP CONSTRAINT "message_recepientes_volunteer_id_fkey";

-- DropForeignKey
ALTER TABLE "messages" DROP CONSTRAINT "messages_target_zone_id_fkey";

-- DropForeignKey
ALTER TABLE "swap_requests" DROP CONSTRAINT "swap_requests_assignment_id_fkey";

-- DropForeignKey
ALTER TABLE "swap_requests" DROP CONSTRAINT "swap_requests_resolved_by_id_fkey";

-- DropForeignKey
ALTER TABLE "swap_requests" DROP CONSTRAINT "swap_requests_suggested_volunteer_id_fkey";

-- DropForeignKey
ALTER TABLE "volunteers" DROP CONSTRAINT "volunteers_roleId_fkey";

-- DropForeignKey
ALTER TABLE "zone" DROP CONSTRAINT "zone_event_id_fkey";

-- DropIndex
DROP INDEX "check_ins_assignment_id_key";

-- AlterTable
ALTER TABLE "admins" ADD COLUMN     "admin_type" "AdminType" NOT NULL DEFAULT 'DEPARTMENT_ADMIN',
ADD COLUMN     "department_id" TEXT;

-- AlterTable
ALTER TABLE "check_ins" DROP COLUMN "assignment_id",
DROP COLUMN "deleted_at",
ADD COLUMN     "schedule_assignment_id" TEXT NOT NULL,
ADD COLUMN     "volunteer_id" TEXT NOT NULL,
ALTER COLUMN "check_in_time" DROP NOT NULL;

-- AlterTable
ALTER TABLE "events" ADD COLUMN     "status" "EventStatus" NOT NULL DEFAULT 'DRAFT';

-- AlterTable
ALTER TABLE "messages" DROP COLUMN "deleted_at",
DROP COLUMN "target_zone_id",
ADD COLUMN     "is_quick_alert" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "target_department_id" TEXT,
ADD COLUMN     "target_post_id" TEXT;

-- AlterTable
ALTER TABLE "roles" ADD COLUMN     "description" TEXT;

-- AlterTable
ALTER TABLE "sessions" ADD COLUMN     "display_order" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "volunteer_availability" ADD COLUMN     "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "volunteers" DROP COLUMN "name",
DROP COLUMN "roleId",
ADD COLUMN     "department_id" TEXT,
ADD COLUMN     "first_name" TEXT NOT NULL,
ADD COLUMN     "is_active" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "last_name" TEXT NOT NULL,
ADD COLUMN     "notes" TEXT,
ADD COLUMN     "role_id" TEXT,
DROP COLUMN "appointment",
ADD COLUMN     "appointment" "Appointment" NOT NULL DEFAULT 'PUBLISHER';

-- DropTable
DROP TABLE "assignments";

-- DropTable
DROP TABLE "message_recepientes";

-- DropTable
DROP TABLE "swap_requests";

-- DropTable
DROP TABLE "zone";

-- DropEnum
DROP TYPE "SwapRequestStatus";

-- DropEnum
DROP TYPE "VolunteerAppointment";

-- CreateTable
CREATE TABLE "departments" (
    "id" TEXT NOT NULL,
    "department_type" "DepartmentType" NOT NULL,
    "custom_name" TEXT,
    "description" TEXT,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "event_id" TEXT NOT NULL,

    CONSTRAINT "departments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "posts" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "capacity" INTEGER NOT NULL DEFAULT 1,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "event_id" TEXT NOT NULL,
    "department_id" TEXT NOT NULL,

    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "schedule_assignments" (
    "id" TEXT NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "volunteer_id" TEXT NOT NULL,
    "session_id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,

    CONSTRAINT "schedule_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attendance_counts" (
    "id" TEXT NOT NULL,
    "count" INTEGER NOT NULL,
    "count_time" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "session_id" TEXT NOT NULL,
    "post_id" TEXT,
    "submitted_by_id" TEXT NOT NULL,

    CONSTRAINT "attendance_counts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_recipients" (
    "id" TEXT NOT NULL,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "message_id" TEXT NOT NULL,
    "volunteer_id" TEXT NOT NULL,

    CONSTRAINT "message_recipients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "event_notes" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "category" "NoteCategory" NOT NULL DEFAULT 'GENERAL',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "event_id" TEXT NOT NULL,
    "created_by_id" TEXT NOT NULL,

    CONSTRAINT "event_notes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "departments_event_id_department_type_key" ON "departments"("event_id", "department_type");

-- CreateIndex
CREATE UNIQUE INDEX "schedule_assignments_volunteer_id_session_id_key" ON "schedule_assignments"("volunteer_id", "session_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_recipients_message_id_volunteer_id_key" ON "message_recipients"("message_id", "volunteer_id");

-- CreateIndex
CREATE UNIQUE INDEX "check_ins_schedule_assignment_id_key" ON "check_ins"("schedule_assignment_id");

-- AddForeignKey
ALTER TABLE "admins" ADD CONSTRAINT "admins_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "departments" ADD CONSTRAINT "departments_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "volunteers" ADD CONSTRAINT "volunteers_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "volunteers" ADD CONSTRAINT "volunteers_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "schedule_assignments" ADD CONSTRAINT "schedule_assignments_volunteer_id_fkey" FOREIGN KEY ("volunteer_id") REFERENCES "volunteers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "schedule_assignments" ADD CONSTRAINT "schedule_assignments_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "schedule_assignments" ADD CONSTRAINT "schedule_assignments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_ins" ADD CONSTRAINT "check_ins_schedule_assignment_id_fkey" FOREIGN KEY ("schedule_assignment_id") REFERENCES "schedule_assignments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_ins" ADD CONSTRAINT "check_ins_volunteer_id_fkey" FOREIGN KEY ("volunteer_id") REFERENCES "volunteers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_counts" ADD CONSTRAINT "attendance_counts_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_counts" ADD CONSTRAINT "attendance_counts_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_counts" ADD CONSTRAINT "attendance_counts_submitted_by_id_fkey" FOREIGN KEY ("submitted_by_id") REFERENCES "volunteers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_target_post_id_fkey" FOREIGN KEY ("target_post_id") REFERENCES "posts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_target_department_id_fkey" FOREIGN KEY ("target_department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_recipients" ADD CONSTRAINT "message_recipients_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_recipients" ADD CONSTRAINT "message_recipients_volunteer_id_fkey" FOREIGN KEY ("volunteer_id") REFERENCES "volunteers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "event_notes" ADD CONSTRAINT "event_notes_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "event_notes" ADD CONSTRAINT "event_notes_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "admins"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

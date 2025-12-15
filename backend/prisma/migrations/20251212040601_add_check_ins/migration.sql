-- CreateEnum
CREATE TYPE "CheckInStatus" AS ENUM ('CHECKED_IN', 'CHECKED_OUT', 'MISSED');

-- CreateTable
CREATE TABLE "check_ins" (
    "id" TEXT NOT NULL,
    "check_in_time" TIMESTAMP(3) NOT NULL,
    "check_out_time" TIMESTAMP(3) NOT NULL,
    "status" "CheckInStatus" NOT NULL DEFAULT 'CHECKED_IN',
    "is_late" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "assignment_id" TEXT NOT NULL,

    CONSTRAINT "check_ins_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "check_ins_assignment_id_key" ON "check_ins"("assignment_id");

-- AddForeignKey
ALTER TABLE "check_ins" ADD CONSTRAINT "check_ins_assignment_id_fkey" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

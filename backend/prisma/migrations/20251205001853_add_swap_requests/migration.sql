-- CreateEnum
CREATE TYPE "SwapRequestStatus" AS ENUM ('PENDING', 'APPROVED', 'DENIED');

-- CreateTable
CREATE TABLE "swap_requests" (
    "id" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "SwapRequestStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "resolved_at" TIMESTAMP(3),
    "assignment_id" TEXT NOT NULL,
    "suggested_volunteer_id" TEXT,
    "resolved_by_id" TEXT,

    CONSTRAINT "swap_requests_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "swap_requests" ADD CONSTRAINT "swap_requests_assignment_id_fkey" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "swap_requests" ADD CONSTRAINT "swap_requests_suggested_volunteer_id_fkey" FOREIGN KEY ("suggested_volunteer_id") REFERENCES "volunteers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "swap_requests" ADD CONSTRAINT "swap_requests_resolved_by_id_fkey" FOREIGN KEY ("resolved_by_id") REFERENCES "admins"("id") ON DELETE SET NULL ON UPDATE CASCADE;

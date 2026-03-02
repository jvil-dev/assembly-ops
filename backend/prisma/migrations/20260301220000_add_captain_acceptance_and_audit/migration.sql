-- Step 1A: Add acceptance fields to AreaCaptain
ALTER TABLE "AreaCaptain" ADD COLUMN "status" "AssignmentStatus" NOT NULL DEFAULT 'ACCEPTED';
ALTER TABLE "AreaCaptain" ADD COLUMN "respondedAt" TIMESTAMP(3);
ALTER TABLE "AreaCaptain" ADD COLUMN "declineReason" TEXT;
ALTER TABLE "AreaCaptain" ADD COLUMN "acceptedDeadline" TIMESTAMP(3);
ALTER TABLE "AreaCaptain" ADD COLUMN "forceAssigned" BOOLEAN NOT NULL DEFAULT true;

-- Grandfather existing rows as accepted+forced, then change defaults for new rows
-- (Prisma applies schema defaults for new rows, so we only need to set existing rows above)

-- Now change the column default for new rows to PENDING
ALTER TABLE "AreaCaptain" ALTER COLUMN "status" SET DEFAULT 'PENDING';
ALTER TABLE "AreaCaptain" ALTER COLUMN "forceAssigned" SET DEFAULT false;

-- Add index on status
CREATE INDEX "AreaCaptain_status_idx" ON "AreaCaptain"("status");

-- Step 1B: Add createdByUserId to Shift
ALTER TABLE "Shift" ADD COLUMN "createdByUserId" TEXT;
ALTER TABLE "Shift" ADD CONSTRAINT "Shift_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Step 1C: Add createdByUserId to ScheduleAssignment
ALTER TABLE "ScheduleAssignment" ADD COLUMN "createdByUserId" TEXT;
ALTER TABLE "ScheduleAssignment" ADD CONSTRAINT "ScheduleAssignment_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

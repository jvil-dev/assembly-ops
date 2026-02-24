-- Add Attendant Enhancement tables
-- Creates WalkThroughCompletion, PostSessionStatus, and FacilityLocation tables
-- for walk-through persistence, seating section status tracking, and facility guide.
-- Also adds SeatingSectionStatus enum (OPEN, FILLING, FULL).

-- CreateEnum
CREATE TYPE "SeatingSectionStatus" AS ENUM ('OPEN', 'FILLING', 'FULL');

-- CreateTable
CREATE TABLE "WalkThroughCompletion" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "itemCount" INTEGER NOT NULL,
    "notes" TEXT,

    CONSTRAINT "WalkThroughCompletion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PostSessionStatus" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "status" "SeatingSectionStatus" NOT NULL DEFAULT 'OPEN',
    "updatedById" TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PostSessionStatus_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FacilityLocation" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "location" TEXT NOT NULL,
    "description" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "FacilityLocation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "WalkThroughCompletion_eventId_sessionId_idx" ON "WalkThroughCompletion"("eventId", "sessionId");

-- CreateIndex
CREATE INDEX "WalkThroughCompletion_eventVolunteerId_idx" ON "WalkThroughCompletion"("eventVolunteerId");

-- CreateIndex
CREATE UNIQUE INDEX "PostSessionStatus_postId_sessionId_key" ON "PostSessionStatus"("postId", "sessionId");

-- CreateIndex
CREATE INDEX "PostSessionStatus_sessionId_idx" ON "PostSessionStatus"("sessionId");

-- CreateIndex
CREATE INDEX "FacilityLocation_eventId_idx" ON "FacilityLocation"("eventId");

-- AddForeignKey
ALTER TABLE "WalkThroughCompletion" ADD CONSTRAINT "WalkThroughCompletion_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalkThroughCompletion" ADD CONSTRAINT "WalkThroughCompletion_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalkThroughCompletion" ADD CONSTRAINT "WalkThroughCompletion_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PostSessionStatus" ADD CONSTRAINT "PostSessionStatus_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PostSessionStatus" ADD CONSTRAINT "PostSessionStatus_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PostSessionStatus" ADD CONSTRAINT "PostSessionStatus_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FacilityLocation" ADD CONSTRAINT "FacilityLocation_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

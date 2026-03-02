-- CreateTable
CREATE TABLE "Shift" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "startTime" TIME(6) NOT NULL,
    "endTime" TIME(6) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Shift_pkey" PRIMARY KEY ("id")
);

-- AddColumn: nullable shiftId on ScheduleAssignment
ALTER TABLE "ScheduleAssignment" ADD COLUMN "shiftId" TEXT;

-- DropIndex: old unique constraint
DROP INDEX "ScheduleAssignment_eventVolunteerId_sessionId_key";

-- CreateIndex: new compound unique with nullable shiftId
CREATE UNIQUE INDEX "ScheduleAssignment_eventVolunteerId_sessionId_shiftId_key" ON "ScheduleAssignment"("eventVolunteerId", "sessionId", "shiftId");

-- CreateIndex: shiftId index on ScheduleAssignment
CREATE INDEX "ScheduleAssignment_shiftId_idx" ON "ScheduleAssignment"("shiftId");

-- CreateIndex: sessionId index on Shift
CREATE INDEX "Shift_sessionId_idx" ON "Shift"("sessionId");

-- AddForeignKey: Shift -> Session
ALTER TABLE "Shift" ADD CONSTRAINT "Shift_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: ScheduleAssignment -> Shift
ALTER TABLE "ScheduleAssignment" ADD CONSTRAINT "ScheduleAssignment_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "Shift"("id") ON DELETE CASCADE ON UPDATE CASCADE;

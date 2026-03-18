-- AlterTable: Relax unique constraint on ScheduleAssignment
-- Old: @@unique([eventVolunteerId, sessionId, shiftId])
-- New: @@unique([eventVolunteerId, postId, sessionId, shiftId])
-- This allows the same volunteer to be assigned to multiple posts in the same session/shift,
-- while still preventing true duplicates (same volunteer + same post + same session + same shift).

-- Drop the old unique constraint
DROP INDEX IF EXISTS "ScheduleAssignment_eventVolunteerId_sessionId_shiftId_key";

-- Create the new unique constraint including postId
CREATE UNIQUE INDEX "ScheduleAssignment_eventVolunteerId_postId_sessionId_shiftId_key" ON "ScheduleAssignment"("eventVolunteerId", "postId", "sessionId", "shiftId");

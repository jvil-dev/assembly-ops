-- Delete any existing shifts (pre-beta, no production data)
-- This cascades to ScheduleAssignment.shiftId and ReminderConfirmation.shiftId
DELETE FROM "Shift";

-- AddColumn: postId on Shift (required FK to Post)
ALTER TABLE "Shift" ADD COLUMN "postId" TEXT NOT NULL;

-- CreateIndex: postId index on Shift
CREATE INDEX "Shift_postId_idx" ON "Shift"("postId");

-- CreateIndex: unique constraint on (sessionId, postId, name) to prevent duplicate shift names per slot
CREATE UNIQUE INDEX "Shift_sessionId_postId_name_key" ON "Shift"("sessionId", "postId", "name");

-- AddForeignKey: Shift -> Post
ALTER TABLE "Shift" ADD CONSTRAINT "Shift_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;

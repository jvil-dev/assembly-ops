-- DropIndex
DROP INDEX IF EXISTS "Shift_sessionId_postId_name_key";

-- CreateIndex
CREATE UNIQUE INDEX "Shift_sessionId_postId_startTime_key" ON "Shift"("sessionId", "postId", "startTime");

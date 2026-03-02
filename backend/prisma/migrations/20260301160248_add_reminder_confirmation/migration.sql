-- CreateTable
CREATE TABLE "ReminderConfirmation" (
    "id" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "shiftId" TEXT,
    "sessionId" TEXT,
    "confirmedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ReminderConfirmation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ReminderConfirmation_eventVolunteerId_idx" ON "ReminderConfirmation"("eventVolunteerId");

-- CreateIndex
CREATE UNIQUE INDEX "ReminderConfirmation_eventVolunteerId_shiftId_key" ON "ReminderConfirmation"("eventVolunteerId", "shiftId");

-- CreateIndex
CREATE UNIQUE INDEX "ReminderConfirmation_eventVolunteerId_sessionId_key" ON "ReminderConfirmation"("eventVolunteerId", "sessionId");

-- AddForeignKey
ALTER TABLE "ReminderConfirmation" ADD CONSTRAINT "ReminderConfirmation_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReminderConfirmation" ADD CONSTRAINT "ReminderConfirmation_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "Shift"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReminderConfirmation" ADD CONSTRAINT "ReminderConfirmation_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

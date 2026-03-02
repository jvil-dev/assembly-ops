-- CreateTable
CREATE TABLE "LanyardCheckout" (
    "id" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "pickedUpAt" TIMESTAMP(3),
    "returnedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LanyardCheckout_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "LanyardCheckout_eventId_date_idx" ON "LanyardCheckout"("eventId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "LanyardCheckout_eventVolunteerId_date_key" ON "LanyardCheckout"("eventVolunteerId", "date");

-- AddForeignKey
ALTER TABLE "LanyardCheckout" ADD CONSTRAINT "LanyardCheckout_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LanyardCheckout" ADD CONSTRAINT "LanyardCheckout_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

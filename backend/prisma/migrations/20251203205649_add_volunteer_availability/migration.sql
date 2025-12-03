-- CreateTable
CREATE TABLE "volunteer_availability" (
    "id" TEXT NOT NULL,
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "volunteer_id" TEXT NOT NULL,
    "session_id" TEXT NOT NULL,

    CONSTRAINT "volunteer_availability_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "volunteer_availability_volunteer_id_session_id_key" ON "volunteer_availability"("volunteer_id", "session_id");

-- AddForeignKey
ALTER TABLE "volunteer_availability" ADD CONSTRAINT "volunteer_availability_volunteer_id_fkey" FOREIGN KEY ("volunteer_id") REFERENCES "volunteers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "volunteer_availability" ADD CONSTRAINT "volunteer_availability_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

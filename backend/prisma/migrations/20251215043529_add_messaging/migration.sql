-- CreateEnum
CREATE TYPE "MessagePriority" AS ENUM ('NORMAL', 'URGENT');

-- CreateEnum
CREATE TYPE "RecipientType" AS ENUM ('INDIVIDUAL', 'ZONE', 'ROLE', 'BROADCAST');

-- CreateTable
CREATE TABLE "messages" (
    "id" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "priority" "MessagePriority" NOT NULL DEFAULT 'NORMAL',
    "recipientType" "RecipientType" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "event_id" TEXT NOT NULL,
    "sender_admin_id" TEXT,
    "sender_volunteer_id" TEXT,
    "target_volunteer_id" TEXT,
    "target_zone_id" TEXT,
    "target_role_id" TEXT,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_recepientes" (
    "id" TEXT NOT NULL,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "message_id" TEXT NOT NULL,
    "volunteer_id" TEXT NOT NULL,

    CONSTRAINT "message_recepientes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "message_recepientes_message_id_volunteer_id_key" ON "message_recepientes"("message_id", "volunteer_id");

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_admin_id_fkey" FOREIGN KEY ("sender_admin_id") REFERENCES "admins"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_volunteer_id_fkey" FOREIGN KEY ("sender_volunteer_id") REFERENCES "volunteers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_target_volunteer_id_fkey" FOREIGN KEY ("target_volunteer_id") REFERENCES "volunteers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_target_zone_id_fkey" FOREIGN KEY ("target_zone_id") REFERENCES "zone"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_target_role_id_fkey" FOREIGN KEY ("target_role_id") REFERENCES "roles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_recepientes" ADD CONSTRAINT "message_recepientes_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_recepientes" ADD CONSTRAINT "message_recepientes_volunteer_id_fkey" FOREIGN KEY ("volunteer_id") REFERENCES "volunteers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

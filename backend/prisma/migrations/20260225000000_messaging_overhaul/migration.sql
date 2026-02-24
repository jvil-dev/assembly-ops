-- CreateEnum
CREATE TYPE "MessageSenderType" AS ENUM ('ADMIN', 'VOLUNTEER');

-- AlterEnum
ALTER TYPE "RecipientType" ADD VALUE 'ADMIN';

-- CreateTable
CREATE TABLE "Conversation" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "subject" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Conversation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ConversationParticipant" (
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "participantType" "MessageSenderType" NOT NULL,
    "participantId" TEXT NOT NULL,
    "lastReadAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ConversationParticipant_pkey" PRIMARY KEY ("id")
);

-- AlterTable: Add new columns to Message
ALTER TABLE "Message" ADD COLUMN "senderType" "MessageSenderType";
ALTER TABLE "Message" ADD COLUMN "senderAdminId" TEXT;
ALTER TABLE "Message" ADD COLUMN "senderVolId" TEXT;
ALTER TABLE "Message" ADD COLUMN "conversationId" TEXT;
ALTER TABLE "Message" ADD COLUMN "deletedBySender" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Message" ADD COLUMN "deletedByRecipient" BOOLEAN NOT NULL DEFAULT false;

-- Backfill: Populate senderType and senderAdminId from legacy senderId
UPDATE "Message"
SET "senderType" = 'ADMIN'::"MessageSenderType",
    "senderAdminId" = "senderId"
WHERE "senderId" IS NOT NULL;

-- CreateIndex
CREATE INDEX "Conversation_eventId_idx" ON "Conversation"("eventId");

-- CreateIndex
CREATE UNIQUE INDEX "ConversationParticipant_conversationId_participantType_partici_key" ON "ConversationParticipant"("conversationId", "participantType", "participantId");

-- CreateIndex
CREATE INDEX "ConversationParticipant_participantType_participantId_idx" ON "ConversationParticipant"("participantType", "participantId");

-- CreateIndex
CREATE INDEX "ConversationParticipant_conversationId_idx" ON "ConversationParticipant"("conversationId");

-- CreateIndex
CREATE INDEX "Message_conversationId_idx" ON "Message"("conversationId");

-- CreateIndex
CREATE INDEX "Message_senderType_senderAdminId_idx" ON "Message"("senderType", "senderAdminId");

-- CreateIndex
CREATE INDEX "Message_senderType_senderVolId_idx" ON "Message"("senderType", "senderVolId");

-- AddForeignKey
ALTER TABLE "Conversation" ADD CONSTRAINT "Conversation_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConversationParticipant" ADD CONSTRAINT "ConversationParticipant_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_senderAdminId_fkey" FOREIGN KEY ("senderAdminId") REFERENCES "Admin"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_senderVolId_fkey" FOREIGN KEY ("senderVolId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

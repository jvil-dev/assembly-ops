-- CreateEnum
CREATE TYPE "ConversationType" AS ENUM ('DIRECT', 'DEPARTMENT_BROADCAST', 'EVENT_BROADCAST');

-- AlterTable
ALTER TABLE "Conversation" ADD COLUMN "type" "ConversationType" NOT NULL DEFAULT 'DIRECT',
ADD COLUMN "departmentId" TEXT;

-- AddForeignKey
ALTER TABLE "Conversation" ADD CONSTRAINT "Conversation_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "Conversation_type_eventId_departmentId_idx" ON "Conversation"("type", "eventId", "departmentId");

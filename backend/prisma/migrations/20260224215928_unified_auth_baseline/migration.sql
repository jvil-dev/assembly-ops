-- CreateEnum
CREATE TYPE "AppointmentStatus" AS ENUM ('PUBLISHER', 'MINISTERIAL_SERVANT', 'ELDER');

-- CreateEnum
CREATE TYPE "AssignmentStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'AUTO_DECLINED');

-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('EMAIL', 'GOOGLE', 'APPLE');

-- CreateEnum
CREATE TYPE "CheckInStatus" AS ENUM ('CHECKED_IN', 'CHECKED_OUT', 'NO_SHOW');

-- CreateEnum
CREATE TYPE "DateFilter" AS ENUM ('UPCOMING', 'PAST', 'ALL');

-- CreateEnum
CREATE TYPE "DepartmentType" AS ENUM ('ACCOUNTS', 'ATTENDANT', 'AUDIO_VIDEO', 'BAPTISM', 'CLEANING', 'FIRST_AID', 'INFORMATION_VOLUNTEER_SERVICE', 'INSTALLATION', 'LOST_FOUND_CHECKROOM', 'PARKING', 'ROOMING', 'TRUCKING_EQUIPMENT');

-- CreateEnum
CREATE TYPE "EventRole" AS ENUM ('APP_ADMIN', 'DEPARTMENT_OVERSEER');

-- CreateEnum
CREATE TYPE "EventType" AS ENUM ('CIRCUIT_ASSEMBLY', 'REGIONAL_CONVENTION', 'SPECIAL_CONVENTION');

-- CreateEnum
CREATE TYPE "JoinRequestStatus" AS ENUM ('PENDING', 'APPROVED', 'DENIED');

-- CreateEnum
CREATE TYPE "MessageSenderType" AS ENUM ('USER', 'VOLUNTEER');

-- CreateEnum
CREATE TYPE "RecipientType" AS ENUM ('VOLUNTEER', 'DEPARTMENT', 'EVENT', 'USER');

-- CreateEnum
CREATE TYPE "SeatingSectionStatus" AS ENUM ('OPEN', 'FILLING', 'FULL');

-- CreateEnum
CREATE TYPE "SafetyIncidentType" AS ENUM ('BUILDING_DEFECT', 'WET_FLOOR', 'UNSAFE_CONDITION', 'MEDICAL_EMERGENCY', 'DISRUPTIVE_INDIVIDUAL', 'BOMB_THREAT', 'VIOLENT_INDIVIDUAL', 'SEVERE_WEATHER', 'ACTIVE_SHOOTER', 'OTHER');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "phone" TEXT,
    "appointmentStatus" "AppointmentStatus",
    "congregation" TEXT,
    "congregationId" TEXT,
    "isOverseer" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventJoinRequest" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "departmentType" "DepartmentType",
    "status" "JoinRequestStatus" NOT NULL DEFAULT 'PENDING',
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolvedAt" TIMESTAMP(3),
    "resolvedById" TEXT,

    CONSTRAINT "EventJoinRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceCount" (
    "id" TEXT NOT NULL,
    "count" INTEGER NOT NULL,
    "section" TEXT,
    "notes" TEXT,
    "sessionId" TEXT NOT NULL,
    "postId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "submittedById" TEXT NOT NULL,

    CONSTRAINT "AttendanceCount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendantMeeting" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "meetingDate" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AttendantMeeting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CheckIn" (
    "id" TEXT NOT NULL,
    "checkInTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "checkOutTime" TIMESTAMP(3),
    "assignmentId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "checkedInById" TEXT,
    "checkedInByVolId" TEXT,
    "notes" TEXT,
    "status" "CheckInStatus" NOT NULL DEFAULT 'CHECKED_IN',

    CONSTRAINT "CheckIn_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Circuit" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "region" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'E',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Circuit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Congregation" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'E',
    "circuitId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Congregation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Department" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "departmentType" "DepartmentType" NOT NULL,
    "description" TEXT,
    "eventId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Department_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Event" (
    "id" TEXT NOT NULL,
    "templateId" TEXT NOT NULL,
    "joinCode" TEXT NOT NULL,
    "isPublic" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "acceptDeadlineDays" INTEGER NOT NULL DEFAULT 5,

    CONSTRAINT "Event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventAdmin" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "role" "EventRole" NOT NULL,
    "departmentId" TEXT,
    "claimedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EventAdmin_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventNote" (
    "id" TEXT NOT NULL,
    "title" TEXT,
    "body" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "departmentId" TEXT,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventNote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventTemplate" (
    "id" TEXT NOT NULL,
    "eventType" "EventType" NOT NULL,
    "circuit" TEXT,
    "circuitId" TEXT,
    "region" TEXT NOT NULL,
    "serviceYear" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "theme" TEXT,
    "themeScripture" TEXT,
    "venue" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'en',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventTemplate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventVolunteer" (
    "id" TEXT NOT NULL,
    "volunteerId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "encryptedToken" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "departmentId" TEXT,
    "roleId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventVolunteer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LostPersonAlert" (
    "id" TEXT NOT NULL,
    "encryptedPersonName" TEXT NOT NULL,
    "age" INTEGER,
    "description" TEXT NOT NULL,
    "lastSeenLocation" TEXT,
    "lastSeenTime" TIMESTAMP(3),
    "encryptedContactName" TEXT NOT NULL,
    "encryptedContactPhone" TEXT,
    "reportedById" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "resolvedAt" TIMESTAMP(3),
    "resolvedById" TEXT,
    "resolutionNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,

    CONSTRAINT "LostPersonAlert_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MeetingAttendance" (
    "id" TEXT NOT NULL,
    "meetingId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,

    CONSTRAINT "MeetingAttendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Message" (
    "id" TEXT NOT NULL,
    "subject" TEXT,
    "body" TEXT NOT NULL,
    "recipientType" "RecipientType" NOT NULL,
    "recipientId" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "readAt" TIMESTAMP(3),
    "eventId" TEXT NOT NULL,
    "senderType" "MessageSenderType",
    "senderUserId" TEXT,
    "senderVolId" TEXT,
    "conversationId" TEXT,
    "deletedBySender" BOOLEAN NOT NULL DEFAULT false,
    "deletedByRecipient" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "eventVolunteerId" TEXT,

    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);

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

-- CreateTable
CREATE TABLE "OAuthConnection" (
    "id" TEXT NOT NULL,
    "provider" "AuthProvider" NOT NULL,
    "providerId" TEXT NOT NULL,
    "encryptedEmail" TEXT,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OAuthConnection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Post" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "location" TEXT,
    "capacity" INTEGER NOT NULL DEFAULT 1,
    "category" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "departmentId" TEXT NOT NULL,
    "areaId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Post_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revoked" BOOLEAN NOT NULL DEFAULT false,
    "userId" TEXT,
    "eventVolunteerId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Role" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "eventId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Role_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SafetyIncident" (
    "id" TEXT NOT NULL,
    "type" "SafetyIncidentType" NOT NULL,
    "description" TEXT NOT NULL,
    "location" TEXT,
    "postId" TEXT,
    "reportedById" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "resolvedAt" TIMESTAMP(3),
    "resolvedById" TEXT,
    "resolutionNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,

    CONSTRAINT "SafetyIncident_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ScheduleAssignment" (
    "id" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "status" "AssignmentStatus" NOT NULL DEFAULT 'PENDING',
    "isCaptain" BOOLEAN NOT NULL DEFAULT false,
    "respondedAt" TIMESTAMP(3),
    "declineReason" TEXT,
    "acceptedDeadline" TIMESTAMP(3),
    "forceAssigned" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ScheduleAssignment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "startTime" TIME(6) NOT NULL,
    "endTime" TIME(6) NOT NULL,
    "eventId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Area" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "category" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "departmentId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Area_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AreaCaptain" (
    "id" TEXT NOT NULL,
    "areaId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AreaCaptain_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WalkThroughCompletion" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "eventVolunteerId" TEXT NOT NULL,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "itemCount" INTEGER NOT NULL,
    "notes" TEXT,

    CONSTRAINT "WalkThroughCompletion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PostSessionStatus" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "status" "SeatingSectionStatus" NOT NULL DEFAULT 'OPEN',
    "updatedById" TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PostSessionStatus_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FacilityLocation" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "location" TEXT NOT NULL,
    "description" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "FacilityLocation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_userId_key" ON "User"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_userId_idx" ON "User"("userId");

-- CreateIndex
CREATE INDEX "User_congregationId_idx" ON "User"("congregationId");

-- CreateIndex
CREATE INDEX "EventJoinRequest_eventId_idx" ON "EventJoinRequest"("eventId");

-- CreateIndex
CREATE INDEX "EventJoinRequest_userId_idx" ON "EventJoinRequest"("userId");

-- CreateIndex
CREATE INDEX "EventJoinRequest_status_idx" ON "EventJoinRequest"("status");

-- CreateIndex
CREATE UNIQUE INDEX "EventJoinRequest_eventId_userId_key" ON "EventJoinRequest"("eventId", "userId");

-- CreateIndex
CREATE INDEX "AttendanceCount_sessionId_idx" ON "AttendanceCount"("sessionId");

-- CreateIndex
CREATE INDEX "AttendanceCount_postId_idx" ON "AttendanceCount"("postId");

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceCount_sessionId_section_key" ON "AttendanceCount"("sessionId", "section");

-- CreateIndex
CREATE INDEX "AttendantMeeting_eventId_idx" ON "AttendantMeeting"("eventId");

-- CreateIndex
CREATE UNIQUE INDEX "CheckIn_assignmentId_key" ON "CheckIn"("assignmentId");

-- CreateIndex
CREATE INDEX "CheckIn_assignmentId_idx" ON "CheckIn"("assignmentId");

-- CreateIndex
CREATE UNIQUE INDEX "Circuit_code_key" ON "Circuit"("code");

-- CreateIndex
CREATE INDEX "Circuit_region_idx" ON "Circuit"("region");

-- CreateIndex
CREATE INDEX "Circuit_language_idx" ON "Circuit"("language");

-- CreateIndex
CREATE INDEX "Congregation_circuitId_idx" ON "Congregation"("circuitId");

-- CreateIndex
CREATE INDEX "Congregation_state_language_idx" ON "Congregation"("state", "language");

-- CreateIndex
CREATE UNIQUE INDEX "Congregation_name_city_state_key" ON "Congregation"("name", "city", "state");

-- CreateIndex
CREATE INDEX "Department_eventId_idx" ON "Department"("eventId");

-- CreateIndex
CREATE UNIQUE INDEX "Department_eventId_departmentType_key" ON "Department"("eventId", "departmentType");

-- CreateIndex
CREATE UNIQUE INDEX "Event_joinCode_key" ON "Event"("joinCode");

-- CreateIndex
CREATE INDEX "Event_joinCode_idx" ON "Event"("joinCode");

-- CreateIndex
CREATE INDEX "Event_templateId_idx" ON "Event"("templateId");

-- CreateIndex
CREATE UNIQUE INDEX "EventAdmin_departmentId_key" ON "EventAdmin"("departmentId");

-- CreateIndex
CREATE INDEX "EventAdmin_userId_idx" ON "EventAdmin"("userId");

-- CreateIndex
CREATE INDEX "EventAdmin_eventId_idx" ON "EventAdmin"("eventId");

-- CreateIndex
CREATE UNIQUE INDEX "EventAdmin_userId_eventId_key" ON "EventAdmin"("userId", "eventId");

-- CreateIndex
CREATE INDEX "EventNote_departmentId_idx" ON "EventNote"("departmentId");

-- CreateIndex
CREATE INDEX "EventNote_eventId_idx" ON "EventNote"("eventId");

-- CreateIndex
CREATE INDEX "EventTemplate_region_idx" ON "EventTemplate"("region");

-- CreateIndex
CREATE INDEX "EventTemplate_serviceYear_idx" ON "EventTemplate"("serviceYear");

-- CreateIndex
CREATE INDEX "EventTemplate_circuitId_idx" ON "EventTemplate"("circuitId");

-- CreateIndex
CREATE UNIQUE INDEX "EventTemplate_eventType_circuit_startDate_key" ON "EventTemplate"("eventType", "circuit", "startDate");

-- CreateIndex
CREATE UNIQUE INDEX "EventVolunteer_volunteerId_key" ON "EventVolunteer"("volunteerId");

-- CreateIndex
CREATE INDEX "EventVolunteer_eventId_idx" ON "EventVolunteer"("eventId");

-- CreateIndex
CREATE INDEX "EventVolunteer_departmentId_idx" ON "EventVolunteer"("departmentId");

-- CreateIndex
CREATE INDEX "EventVolunteer_userId_idx" ON "EventVolunteer"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "EventVolunteer_userId_eventId_key" ON "EventVolunteer"("userId", "eventId");

-- CreateIndex
CREATE INDEX "LostPersonAlert_eventId_idx" ON "LostPersonAlert"("eventId");

-- CreateIndex
CREATE INDEX "LostPersonAlert_resolved_idx" ON "LostPersonAlert"("resolved");

-- CreateIndex
CREATE UNIQUE INDEX "MeetingAttendance_meetingId_eventVolunteerId_key" ON "MeetingAttendance"("meetingId", "eventVolunteerId");

-- CreateIndex
CREATE INDEX "Message_eventId_idx" ON "Message"("eventId");

-- CreateIndex
CREATE INDEX "Message_conversationId_idx" ON "Message"("conversationId");

-- CreateIndex
CREATE INDEX "Message_senderType_senderUserId_idx" ON "Message"("senderType", "senderUserId");

-- CreateIndex
CREATE INDEX "Message_senderType_senderVolId_idx" ON "Message"("senderType", "senderVolId");

-- CreateIndex
CREATE INDEX "Message_recipientType_recipientId_idx" ON "Message"("recipientType", "recipientId");

-- CreateIndex
CREATE INDEX "Message_eventVolunteerId_idx" ON "Message"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "Conversation_eventId_idx" ON "Conversation"("eventId");

-- CreateIndex
CREATE INDEX "ConversationParticipant_participantType_participantId_idx" ON "ConversationParticipant"("participantType", "participantId");

-- CreateIndex
CREATE INDEX "ConversationParticipant_conversationId_idx" ON "ConversationParticipant"("conversationId");

-- CreateIndex
CREATE UNIQUE INDEX "ConversationParticipant_conversationId_participantType_part_key" ON "ConversationParticipant"("conversationId", "participantType", "participantId");

-- CreateIndex
CREATE INDEX "OAuthConnection_userId_idx" ON "OAuthConnection"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "OAuthConnection_provider_providerId_key" ON "OAuthConnection"("provider", "providerId");

-- CreateIndex
CREATE INDEX "Post_departmentId_idx" ON "Post"("departmentId");

-- CreateIndex
CREATE INDEX "Post_areaId_idx" ON "Post"("areaId");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_token_key" ON "RefreshToken"("token");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- CreateIndex
CREATE INDEX "RefreshToken_eventVolunteerId_idx" ON "RefreshToken"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "RefreshToken_expiresAt_idx" ON "RefreshToken"("expiresAt");

-- CreateIndex
CREATE INDEX "RefreshToken_token_idx" ON "RefreshToken"("token");

-- CreateIndex
CREATE INDEX "Role_eventId_idx" ON "Role"("eventId");

-- CreateIndex
CREATE UNIQUE INDEX "Role_eventId_name_key" ON "Role"("eventId", "name");

-- CreateIndex
CREATE INDEX "SafetyIncident_eventId_idx" ON "SafetyIncident"("eventId");

-- CreateIndex
CREATE INDEX "SafetyIncident_resolved_idx" ON "SafetyIncident"("resolved");

-- CreateIndex
CREATE INDEX "ScheduleAssignment_postId_idx" ON "ScheduleAssignment"("postId");

-- CreateIndex
CREATE INDEX "ScheduleAssignment_sessionId_idx" ON "ScheduleAssignment"("sessionId");

-- CreateIndex
CREATE INDEX "ScheduleAssignment_eventVolunteerId_idx" ON "ScheduleAssignment"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "ScheduleAssignment_status_idx" ON "ScheduleAssignment"("status");

-- CreateIndex
CREATE UNIQUE INDEX "ScheduleAssignment_eventVolunteerId_sessionId_key" ON "ScheduleAssignment"("eventVolunteerId", "sessionId");

-- CreateIndex
CREATE INDEX "Session_date_idx" ON "Session"("date");

-- CreateIndex
CREATE INDEX "Session_eventId_idx" ON "Session"("eventId");

-- CreateIndex
CREATE INDEX "Area_departmentId_idx" ON "Area"("departmentId");

-- CreateIndex
CREATE UNIQUE INDEX "Area_departmentId_category_name_key" ON "Area"("departmentId", "category", "name");

-- CreateIndex
CREATE INDEX "AreaCaptain_eventVolunteerId_idx" ON "AreaCaptain"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "AreaCaptain_sessionId_idx" ON "AreaCaptain"("sessionId");

-- CreateIndex
CREATE UNIQUE INDEX "AreaCaptain_areaId_sessionId_key" ON "AreaCaptain"("areaId", "sessionId");

-- CreateIndex
CREATE INDEX "WalkThroughCompletion_eventId_sessionId_idx" ON "WalkThroughCompletion"("eventId", "sessionId");

-- CreateIndex
CREATE INDEX "WalkThroughCompletion_eventVolunteerId_idx" ON "WalkThroughCompletion"("eventVolunteerId");

-- CreateIndex
CREATE INDEX "PostSessionStatus_sessionId_idx" ON "PostSessionStatus"("sessionId");

-- CreateIndex
CREATE UNIQUE INDEX "PostSessionStatus_postId_sessionId_key" ON "PostSessionStatus"("postId", "sessionId");

-- CreateIndex
CREATE INDEX "FacilityLocation_eventId_idx" ON "FacilityLocation"("eventId");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_congregationId_fkey" FOREIGN KEY ("congregationId") REFERENCES "Congregation"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventJoinRequest" ADD CONSTRAINT "EventJoinRequest_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventJoinRequest" ADD CONSTRAINT "EventJoinRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventJoinRequest" ADD CONSTRAINT "EventJoinRequest_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceCount" ADD CONSTRAINT "AttendanceCount_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendantMeeting" ADD CONSTRAINT "AttendantMeeting_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendantMeeting" ADD CONSTRAINT "AttendantMeeting_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendantMeeting" ADD CONSTRAINT "AttendantMeeting_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CheckIn" ADD CONSTRAINT "CheckIn_assignmentId_fkey" FOREIGN KEY ("assignmentId") REFERENCES "ScheduleAssignment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CheckIn" ADD CONSTRAINT "CheckIn_checkedInById_fkey" FOREIGN KEY ("checkedInById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CheckIn" ADD CONSTRAINT "CheckIn_checkedInByVolId_fkey" FOREIGN KEY ("checkedInByVolId") REFERENCES "EventVolunteer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Congregation" ADD CONSTRAINT "Congregation_circuitId_fkey" FOREIGN KEY ("circuitId") REFERENCES "Circuit"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Department" ADD CONSTRAINT "Department_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Event" ADD CONSTRAINT "Event_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES "EventTemplate"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventAdmin" ADD CONSTRAINT "EventAdmin_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventAdmin" ADD CONSTRAINT "EventAdmin_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventAdmin" ADD CONSTRAINT "EventAdmin_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventNote" ADD CONSTRAINT "EventNote_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventNote" ADD CONSTRAINT "EventNote_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventNote" ADD CONSTRAINT "EventNote_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventTemplate" ADD CONSTRAINT "EventTemplate_circuitId_fkey" FOREIGN KEY ("circuitId") REFERENCES "Circuit"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventVolunteer" ADD CONSTRAINT "EventVolunteer_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LostPersonAlert" ADD CONSTRAINT "LostPersonAlert_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingAttendance" ADD CONSTRAINT "MeetingAttendance_meetingId_fkey" FOREIGN KEY ("meetingId") REFERENCES "AttendantMeeting"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingAttendance" ADD CONSTRAINT "MeetingAttendance_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingAttendance" ADD CONSTRAINT "MeetingAttendance_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_senderUserId_fkey" FOREIGN KEY ("senderUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_senderVolId_fkey" FOREIGN KEY ("senderVolId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Conversation" ADD CONSTRAINT "Conversation_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConversationParticipant" ADD CONSTRAINT "ConversationParticipant_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OAuthConnection" ADD CONSTRAINT "OAuthConnection_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Post" ADD CONSTRAINT "Post_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Post" ADD CONSTRAINT "Post_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Role" ADD CONSTRAINT "Role_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafetyIncident" ADD CONSTRAINT "SafetyIncident_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduleAssignment" ADD CONSTRAINT "ScheduleAssignment_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduleAssignment" ADD CONSTRAINT "ScheduleAssignment_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduleAssignment" ADD CONSTRAINT "ScheduleAssignment_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Area" ADD CONSTRAINT "Area_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaCaptain" ADD CONSTRAINT "AreaCaptain_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaCaptain" ADD CONSTRAINT "AreaCaptain_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaCaptain" ADD CONSTRAINT "AreaCaptain_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalkThroughCompletion" ADD CONSTRAINT "WalkThroughCompletion_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalkThroughCompletion" ADD CONSTRAINT "WalkThroughCompletion_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalkThroughCompletion" ADD CONSTRAINT "WalkThroughCompletion_eventVolunteerId_fkey" FOREIGN KEY ("eventVolunteerId") REFERENCES "EventVolunteer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PostSessionStatus" ADD CONSTRAINT "PostSessionStatus_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PostSessionStatus" ADD CONSTRAINT "PostSessionStatus_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PostSessionStatus" ADD CONSTRAINT "PostSessionStatus_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "EventVolunteer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FacilityLocation" ADD CONSTRAINT "FacilityLocation_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;

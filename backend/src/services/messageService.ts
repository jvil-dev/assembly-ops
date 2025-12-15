import { prisma } from "../config/database.js";
import { MessagePriority, RecipientType } from "../generated/prisma/client.js";

interface SendMessageInput {
  content: string;
  priority?: MessagePriority;
  recipientType: RecipientType;
  targetVolunteerId?: string;
  targetZoneId?: string;
  targetRoleId?: string;
  eventId: string;
}

export async function sendMessage(input: SendMessageInput, adminId: string) {
  const {
    content,
    priority = "NORMAL",
    recipientType,
    targetVolunteerId,
    targetZoneId,
    targetRoleId,
    eventId,
  } = input;

  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  // Resolve recipients based on type
  let recipientVolunteerIds: string[] = [];

  switch (recipientType) {
    case "INDIVIDUAL": {
      if (!targetVolunteerId) {
        throw new Error("TARGET_VOLUNTEER_REQUIRED");
      }

      const volunteer = await prisma.volunteer.findFirst({
        where: {
          id: targetVolunteerId,
          eventId,
        },
      });
      if (!volunteer) {
        throw new Error("VOLUNTEER_NOT_FOUND");
      }
      recipientVolunteerIds = [targetVolunteerId];
      break;
    }

    case "ZONE": {
      if (!targetZoneId) {
        throw new Error("TARGET_ZONE_REQUIRED");
      }

      const zone = await prisma.zone.findFirst({
        where: {
          id: targetZoneId,
          eventId,
        },
      });
      if (!zone) {
        throw new Error("ZONE_NOT_FOUND");
      }

      const zoneAssignments = await prisma.assignment.findMany({
        where: {
          zoneId: targetZoneId,
        },
        select: {
          volunteerId: true,
        },
        distinct: ["volunteerId"],
      });
      recipientVolunteerIds = zoneAssignments.map((a) => a.volunteerId);
      break;
    }

    case "ROLE": {
      if (!targetRoleId) {
        throw new Error("TARGET_ROLE_REQUIRED");
      }
      // Verify role exists in this event
      const role = await prisma.role.findFirst({
        where: { id: targetRoleId, eventId },
      });
      if (!role) {
        throw new Error("ROLE_NOT_FOUND");
      }
      // Get volunteers with this role
      const roleVolunteers = await prisma.volunteer.findMany({
        where: { roleId: targetRoleId, eventId },
        select: { id: true },
      });
      recipientVolunteerIds = roleVolunteers.map((v) => v.id);
      break;
    }

    case "BROADCAST": {
      // Get all volunteers in the event
      const allVolunteers = await prisma.volunteer.findMany({
        where: { eventId },
        select: { id: true },
      });
      recipientVolunteerIds = allVolunteers.map((v) => v.id);
      break;
    }

    default:
      throw new Error("INVALID_RECIPIENT_TYPE");
  }

  if (recipientVolunteerIds.length === 0) {
    throw new Error("NO_RECIPIENTS");
  }

  // Create message with recipients in a transaction
  const message = await prisma.message.create({
    data: {
      content,
      priority,
      recipientType,
      eventId,
      senderAdminId: adminId,
      targetVolunteerId:
        recipientType === "INDIVIDUAL" ? targetVolunteerId ?? null : null,
      targetZoneId: recipientType === "ZONE" ? targetZoneId ?? null : null,
      targetRoleId: recipientType === "ROLE" ? targetRoleId ?? null : null,
      recipients: {
        create: recipientVolunteerIds.map((volunteerId) => ({
          volunteerId,
        })),
      },
    },
    include: {
      senderAdmin: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      targetVolunteer: {
        select: {
          id: true,
          name: true,
          generatedId: true,
        },
      },
      targetZone: {
        select: {
          id: true,
          name: true,
        },
      },
      targetRole: {
        select: {
          id: true,
          name: true,
        },
      },
      recipients: {
        include: {
          volunteer: {
            select: {
              id: true,
              name: true,
              generatedId: true,
            },
          },
        },
      },
    },
  });

  return {
    ...message,
    recipientCount: recipientVolunteerIds.length,
  };
}

export async function getMessagesByEvent(eventId: string, adminId: string) {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  const messages = await prisma.message.findMany({
    where: { eventId },
    include: {
      senderAdmin: {
        select: { id: true, name: true },
      },
      senderVolunteer: {
        select: { id: true, name: true, generatedId: true },
      },
      targetVolunteer: {
        select: { id: true, name: true },
      },
      targetZone: {
        select: { id: true, name: true },
      },
      targetRole: {
        select: { id: true, name: true },
      },
      _count: {
        select: { recipients: true },
      },
    },
    orderBy: { createdAt: "desc" },
  });

  // Add read stats
  const messagesWithStats = await Promise.all(
    messages.map(async (msg) => {
      const readCount = await prisma.messageRecipient.count({
        where: {
          messageId: msg.id,
          readAt: { not: null },
        },
      });

      return {
        ...msg,
        recipientCount: msg._count.recipients,
        readCount,
        _count: undefined,
      };
    })
  );

  return messagesWithStats;
}

export async function getMessageById(
  messageId: string,
  eventId: string,
  adminId: string
) {
  // Verify admin owns the event
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  const message = await prisma.message.findFirst({
    where: {
      id: messageId,
      eventId,
    },
    include: {
      senderAdmin: {
        select: { id: true, name: true, email: true },
      },
      senderVolunteer: {
        select: { id: true, name: true, generatedId: true },
      },
      targetVolunteer: {
        select: { id: true, name: true, generatedId: true },
      },
      targetZone: {
        select: { id: true, name: true },
      },
      targetRole: {
        select: { id: true, name: true },
      },
      recipients: {
        include: {
          volunteer: {
            select: { id: true, name: true, generatedId: true },
          },
        },
        orderBy: { createdAt: "asc" },
      },
    },
  });

  if (!message) {
    throw new Error("MESSAGE_NOT_FOUND");
  }

  // Calculate stats
  const readCount = message.recipients.filter((r) => r.readAt !== null).length;

  return {
    ...message,
    recipientCount: message.recipients.length,
    readCount,
  };
}

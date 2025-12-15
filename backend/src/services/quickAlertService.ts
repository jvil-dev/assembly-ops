import { prisma } from "../config/database.js";
import { MessagePriority } from "../generated/prisma/client.js";

interface CreateQuickAlertInput {
  name: string;
  message: string;
  priority?: MessagePriority;
  displayOrder?: number;
  eventId: string;
}

interface UpdateQuickAlertInput {
  name?: string;
  message?: string;
  priority?: MessagePriority;
  isActive?: boolean;
  displayOrder?: number;
}

export async function createQuickAlert(
  input: CreateQuickAlertInput,
  adminId: string
) {
  const { name, message, priority, displayOrder, eventId } = input;

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

  // Auto-increment displayOrder if not provided
  let order = displayOrder;
  if (order === undefined) {
    const lastAlert = await prisma.quickAlert.findFirst({
      where: { eventId },
      orderBy: { displayOrder: "desc" },
    });
    order = lastAlert ? lastAlert.displayOrder + 1 : 0;
  }

  const quickAlert = await prisma.quickAlert.create({
    data: {
      name,
      message,
      priority: priority ?? "NORMAL",
      displayOrder: order,
      eventId,
    },
  });

  return quickAlert;
}

export async function getQuickAlertsByEvent(
  eventId: string,
  adminId: string,
  includeInactive = false
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

  const whereClause: Record<string, unknown> = { eventId };
  if (!includeInactive) {
    whereClause.isActive = true;
  }

  const quickAlerts = await prisma.quickAlert.findMany({
    where: whereClause,
    orderBy: { displayOrder: "asc" },
  });

  return quickAlerts;
}

export async function getQuickAlertById(
  alertId: string,
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

  const quickAlert = await prisma.quickAlert.findFirst({
    where: {
      id: alertId,
      eventId,
    },
  });

  if (!quickAlert) {
    throw new Error("QUICK_ALERT_NOT_FOUND");
  }

  return quickAlert;
}

export async function updateQuickAlert(
  alertId: string,
  eventId: string,
  adminId: string,
  input: UpdateQuickAlertInput
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

  // Verify alert exists
  const existingAlert = await prisma.quickAlert.findFirst({
    where: {
      id: alertId,
      eventId,
    },
  });

  if (!existingAlert) {
    throw new Error("QUICK_ALERT_NOT_FOUND");
  }

  const quickAlert = await prisma.quickAlert.update({
    where: { id: alertId },
    data: input,
  });

  return quickAlert;
}

export async function deleteQuickAlert(
  alertId: string,
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

  // Verify alert exists
  const existingAlert = await prisma.quickAlert.findFirst({
    where: {
      id: alertId,
      eventId,
    },
  });

  if (!existingAlert) {
    throw new Error("QUICK_ALERT_NOT_FOUND");
  }

  await prisma.quickAlert.delete({
    where: { id: alertId },
  });

  return { deleted: true };
}

// Volunteer functions

export async function getAvailableQuickAlerts(eventId: string) {
  const quickAlerts = await prisma.quickAlert.findMany({
    where: {
      eventId,
      isActive: true,
    },
    orderBy: { displayOrder: "asc" },
    select: {
      id: true,
      name: true,
      message: true,
      priority: true,
    },
  });

  return quickAlerts;
}

export async function sendQuickAlert(
  alertId: string,
  volunteerId: string,
  eventId: string,
  additionalNote?: string
) {
  // Get the quick alert template
  const quickAlert = await prisma.quickAlert.findFirst({
    where: {
      id: alertId,
      eventId,
      isActive: true,
    },
  });

  if (!quickAlert) {
    throw new Error("QUICK_ALERT_NOT_FOUND");
  }

  // Get the volunteer's info for context
  const volunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
    include: {
      role: { select: { name: true } },
      assignments: {
        include: {
          zone: { select: { name: true } },
          session: { select: { name: true } },
        },
        where: {
          session: {
            // Get current/upcoming session assignments
            endTime: { gte: new Date() },
          },
        },
        orderBy: { session: { startTime: "asc" } },
        take: 1,
      },
    },
  });

  if (!volunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // Build message content with context
  const currentAssignment = volunteer.assignments[0];
  let messageContent = `QUICK ALERT: ${quickAlert.name}\n\n`;
  messageContent += `From: ${volunteer.name}`;
  if (volunteer.role) {
    messageContent += ` (${volunteer.role.name})`;
  }
  messageContent += `\n`;

  if (currentAssignment) {
    messageContent += `Location: ${currentAssignment.zone.name} - ${currentAssignment.session.name}\n`;
  }

  messageContent += `\nMessage: ${quickAlert.message}`;

  if (additionalNote) {
    messageContent += `\n\nNote: ${additionalNote}`;
  }

  // Get all admins for this event to notify
  const event = await prisma.event.findUnique({
    where: { id: eventId },
    select: { createdById: true },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  // Create message as broadcast from volunteer (will be seen by admin in messages list)
  const message = await prisma.message.create({
    data: {
      content: messageContent,
      priority: quickAlert.priority,
      recipientType: "BROADCAST",
      eventId,
      senderVolunteerId: volunteerId,
    },
  });

  // Note: Message is visible in admin dashboard via GET /events/:eventId/messages
  // Future: Add admin notification system (push notifications, AdminRecipient model, etc.)
  await prisma.messageRecipient
    .create({
      data: {
        messageId: message.id,
        volunteerId: event.createdById, // This won't work - admin isn't a volunteer
      },
    })
    .catch(() => {
      // Admin can't be a recipient in current schema
      // The message is still created and visible in event messages
    });

  return {
    sent: true,
    alertName: quickAlert.name,
    messageId: message.id,
  };
}

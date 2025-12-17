import { prisma } from "../config/database.js";

interface SyncStatus {
  eventId: string;
  eventName: string;
  lastModified: Date;
  counts: {
    sessions: number;
    zones: number;
    roles: number;
    volunteers: number;
    assignments: number;
    messages: number;
    quickAlerts: number;
  };
}

interface FullSyncData {
  syncedAt: string;
  event: {
    id: string;
    name: string;
    type: string;
    location: string;
    startDate: string;
    endDate: string;
  };
  sessions: Array<{
    id: string;
    name: string;
    date: Date;
    startTime: Date;
    endTime: Date;
  }>;
  zones: Array<{
    id: string;
    name: string;
    description: string | null;
    requiredCount: number;
    displayOrder: number;
  }>;
  roles: Array<{
    id: string;
    name: string;
    displayOrder: number;
  }>;
  volunteers: Array<{
    id: string;
    name: string;
    congregation: string;
    appointment: string | null;
    roleId: string | null;
    roleName: string | null;
  }>;
  assignments: Array<{
    id: string;
    volunteerId: string;
    sessionId: string;
    zoneId: string;
    notes: string | null;
    updatedAt: Date;
  }>;
  messages: Array<{
    id: string;
    content: string;
    priority: string;
    recipientType: string;
    senderAdminId: string | null;
    senderVolunteerId: string | null;
    senderName: string | null;
    targetZoneId: string | null;
    targetRoleId: string | null;
    createdAt: Date;
  }>;
  quickAlerts: Array<{
    id: string;
    name: string;
    message: string;
    priority: string;
    displayOrder: number;
  }>;
  checkIns: Array<{
    id: string;
    assignmentId: string;
    checkInTime: Date;
    checkOutTime: Date | null;
    status: string;
  }>;
}

export async function getSyncStatus(
  eventId: string,
  adminId: string
): Promise<SyncStatus> {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  // Get counts
  const [
    sessions,
    zones,
    roles,
    volunteers,
    assignments,
    messages,
    quickAlerts,
  ] = await Promise.all([
    prisma.session.count({ where: { eventId } }),
    prisma.zone.count({ where: { eventId } }),
    prisma.role.count({ where: { eventId } }),
    prisma.volunteer.count({ where: { eventId } }),
    prisma.assignment.count({
      where: {
        volunteer: { eventId },
        deletedAt: null,
      },
    }),
    prisma.message.count({
      where: { eventId, deletedAt: null },
    }),
    prisma.quickAlert.count({
      where: { eventId, isActive: true },
    }),
  ]);

  // Find most recent modification
  const lastModified = event.updatedAt;

  return {
    eventId: event.id,
    eventName: event.name,
    lastModified,
    counts: {
      sessions,
      zones,
      roles,
      volunteers,
      assignments,
      messages,
      quickAlerts,
    },
  };
}

export async function getFullSync(
  eventId: string,
  adminId: string
): Promise<FullSyncData> {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  // Fetch all data in parallel
  const [
    sessions,
    zones,
    roles,
    volunteers,
    assignments,
    messages,
    quickAlerts,
    checkIns,
  ] = await Promise.all([
    // Sessions
    prisma.session.findMany({
      where: { eventId },
      orderBy: [{ date: "asc" }, { startTime: "asc" }],
      select: {
        id: true,
        name: true,
        date: true,
        startTime: true,
        endTime: true,
      },
    }),

    // Zones
    prisma.zone.findMany({
      where: { eventId },
      orderBy: { displayOrder: "asc" },
      select: {
        id: true,
        name: true,
        description: true,
        requiredCount: true,
        displayOrder: true,
      },
    }),

    // Roles
    prisma.role.findMany({
      where: { eventId },
      orderBy: { displayOrder: "asc" },
      select: {
        id: true,
        name: true,
        displayOrder: true,
      },
    }),

    // Volunteers (sanitized - no tokens, limited personal info)
    prisma.volunteer.findMany({
      where: { eventId },
      orderBy: { name: "asc" },
      select: {
        id: true,
        name: true,
        congregation: true,
        appointment: true,
        roleId: true,
        role: {
          select: { name: true },
        },
      },
    }),

    // Assignments (not deleted)
    prisma.assignment.findMany({
      where: {
        volunteer: { eventId },
        deletedAt: null,
      },
      select: {
        id: true,
        volunteerId: true,
        sessionId: true,
        zoneId: true,
        notes: true,
        updatedAt: true,
      },
    }),

    // Messages (not deleted)
    prisma.message.findMany({
      where: { eventId, deletedAt: null },
      orderBy: { createdAt: "desc" },
      select: {
        id: true,
        content: true,
        priority: true,
        recipientType: true,
        senderAdminId: true,
        senderVolunteerId: true,
        senderAdmin: {
          select: { name: true },
        },
        senderVolunteer: {
          select: { name: true },
        },
        targetZoneId: true,
        targetRoleId: true,
        createdAt: true,
      },
    }),

    // Quick Alerts (active only)
    prisma.quickAlert.findMany({
      where: { eventId, isActive: true },
      orderBy: { displayOrder: "asc" },
      select: {
        id: true,
        name: true,
        message: true,
        priority: true,
        displayOrder: true,
      },
    }),

    // Check-ins (for today or event dates)
    prisma.checkIn.findMany({
      where: {
        assignment: {
          volunteer: { eventId },
        },
        deletedAt: null,
      },
      orderBy: { checkInTime: "desc" },
      select: {
        id: true,
        assignmentId: true,
        checkInTime: true,
        checkOutTime: true,
        status: true,
      },
    }),
  ]);

  // Transform volunteers to include roleName
  const transformedVolunteers = volunteers.map((v) => ({
    id: v.id,
    name: v.name,
    congregation: v.congregation,
    appointment: v.appointment,
    roleId: v.roleId,
    roleName: v.role?.name || null,
  }));

  // Transform messages to include senderName
  const transformedMessages = messages.map((m) => ({
    id: m.id,
    content: m.content,
    priority: m.priority,
    recipientType: m.recipientType,
    senderAdminId: m.senderAdminId,
    senderVolunteerId: m.senderVolunteerId,
    senderName: m.senderAdmin?.name || m.senderVolunteer?.name || null,
    targetZoneId: m.targetZoneId,
    targetRoleId: m.targetRoleId,
    createdAt: m.createdAt,
  }));

  return {
    syncedAt: new Date().toISOString(),
    event: {
      id: event.id,
      name: event.name,
      type: event.type,
      location: event.location,
      startDate: event.startDate.toISOString(),
      endDate: event.endDate.toISOString(),
    },
    sessions,
    zones,
    roles,
    volunteers: transformedVolunteers,
    assignments,
    messages: transformedMessages,
    quickAlerts,
    checkIns,
  };
}

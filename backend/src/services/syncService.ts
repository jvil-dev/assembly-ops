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

interface DeltaChanges<T> {
  created: T[];
  updated: T[];
  deleted: string[];
}

interface DeltaSyncData {
  syncedAt: string;
  since: string;
  changes: {
    sessions: DeltaChanges<{
      id: string;
      name: string;
      date: Date;
      startTime: Date;
      endTime: Date;
    }>;
    zones: DeltaChanges<{
      id: string;
      name: string;
      description: string | null;
      requiredCount: number;
      displayOrder: number;
    }>;
    roles: DeltaChanges<{
      id: string;
      name: string;
      displayOrder: number;
    }>;
    volunteers: DeltaChanges<{
      id: string;
      name: string;
      congregation: string;
      appointment: string | null;
      roleId: string | null;
      roleName: string | null;
    }>;
    assignments: DeltaChanges<{
      id: string;
      volunteerId: string;
      sessionId: string;
      zoneId: string;
      notes: string | null;
      updatedAt: Date;
    }>;
    messages: DeltaChanges<{
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
    checkIns: DeltaChanges<{
      id: string;
      assignmentId: string;
      checkInTime: Date;
      checkOutTime: Date | null;
      status: string;
    }>;
  };
}
type ActionType = "CHECK_IN" | "CHECK_OUT" | "QUICK_ALERT" | "MESSAGE_READ";

interface QueuedAction {
  id: string;
  type: ActionType;
  timestamp: string;
  data: Record<string, unknown>;
}

interface ActionResult {
  clientId: string;
  status: "success" | "error";
  serverId?: string;
  error?: string;
}

interface QueueProcessingResult {
  processed: number;
  succeeded: number;
  failed: number;
  results: ActionResult[];
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

export async function getDeltaSync(
  eventId: string,
  adminId: string,
  since: Date
): Promise<DeltaSyncData> {
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

  // Helper to categorize records
  const categorize = <
    T extends { id: string; createdAt: Date; updatedAt: Date },
  >(
    records: T[],
    since: Date
  ): { created: T[]; updated: T[] } => {
    const created: T[] = [];
    const updated: T[] = [];

    for (const record of records) {
      if (record.createdAt > since) {
        created.push(record);
      } else if (record.updatedAt > since) {
        updated.push(record);
      }
    }

    return { created, updated };
  };

  // Fetch all changed data in parallel
  const [
    changedSessions,
    changedZones,
    changedRoles,
    changedVolunteers,
    changedAssignments,
    deletedAssignments,
    changedMessages,
    deletedMessages,
    changedCheckIns,
    deletedCheckIns,
  ] = await Promise.all([
    // Sessions (no soft delete, just created/updated)
    prisma.session.findMany({
      where: {
        eventId,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        name: true,
        date: true,
        startTime: true,
        endTime: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Zones (no soft delete)
    prisma.zone.findMany({
      where: {
        eventId,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        name: true,
        description: true,
        requiredCount: true,
        displayOrder: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Roles (no soft delete)
    prisma.role.findMany({
      where: {
        eventId,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        name: true,
        displayOrder: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Volunteers (no soft delete, sanitized)
    prisma.volunteer.findMany({
      where: {
        eventId,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        name: true,
        congregation: true,
        appointment: true,
        roleId: true,
        role: { select: { name: true } },
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Assignments (created or updated, not deleted)
    prisma.assignment.findMany({
      where: {
        volunteer: { eventId },
        deletedAt: null,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        volunteerId: true,
        sessionId: true,
        zoneId: true,
        notes: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Deleted assignments
    prisma.assignment.findMany({
      where: {
        volunteer: { eventId },
        deletedAt: { gt: since },
      },
      select: { id: true },
    }),

    // Messages (created or updated, not deleted)
    prisma.message.findMany({
      where: {
        eventId,
        deletedAt: null,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        content: true,
        priority: true,
        recipientType: true,
        senderAdminId: true,
        senderVolunteerId: true,
        senderAdmin: { select: { name: true } },
        senderVolunteer: { select: { name: true } },
        targetZoneId: true,
        targetRoleId: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Deleted messages
    prisma.message.findMany({
      where: {
        eventId,
        deletedAt: { gt: since },
      },
      select: { id: true },
    }),

    // CheckIns (created or updated, not deleted)
    prisma.checkIn.findMany({
      where: {
        assignment: { volunteer: { eventId } },
        deletedAt: null,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        assignmentId: true,
        checkInTime: true,
        checkOutTime: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Deleted checkIns
    prisma.checkIn.findMany({
      where: {
        assignment: { volunteer: { eventId } },
        deletedAt: { gt: since },
      },
      select: { id: true },
    }),
  ]);

  // Categorize sessions
  const sessionChanges = categorize(changedSessions, since);

  // Categorize zones
  const zoneChanges = categorize(changedZones, since);

  // Categorize roles
  const roleChanges = categorize(changedRoles, since);

  // Categorize and transform volunteers
  const volunteerChanges = categorize(changedVolunteers, since);
  const transformVolunteer = (v: (typeof changedVolunteers)[0]) => ({
    id: v.id,
    name: v.name,
    congregation: v.congregation,
    appointment: v.appointment,
    roleId: v.roleId,
    roleName: v.role?.name || null,
  });

  // Categorize assignments
  const assignmentChanges = categorize(changedAssignments, since);

  // Categorize and transform messages
  const messageChanges = categorize(changedMessages, since);
  const transformMessage = (m: (typeof changedMessages)[0]) => ({
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
  });

  // Categorize checkIns
  const checkInChanges = categorize(changedCheckIns, since);

  return {
    syncedAt: new Date().toISOString(),
    since: since.toISOString(),
    changes: {
      sessions: {
        created: sessionChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: sessionChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: [],
      },
      zones: {
        created: zoneChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: zoneChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: [],
      },
      roles: {
        created: roleChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: roleChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: [],
      },
      volunteers: {
        created: volunteerChanges.created.map(transformVolunteer),
        updated: volunteerChanges.updated.map(transformVolunteer),
        deleted: [],
      },
      assignments: {
        created: assignmentChanges.created.map(
          ({ createdAt: _createdAt, ...rest }) => rest
        ),
        updated: assignmentChanges.updated.map(
          ({ createdAt: _createdAt, ...rest }) => rest
        ),
        deleted: deletedAssignments.map((a) => a.id),
      },
      messages: {
        created: messageChanges.created.map(transformMessage),
        updated: messageChanges.updated.map(transformMessage),
        deleted: deletedMessages.map((m) => m.id),
      },
      checkIns: {
        created: checkInChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: checkInChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: deletedCheckIns.map((c) => c.id),
      },
    },
  };
}

export async function processActionQueue(
  eventId: string,
  adminId: string | null,
  volunteerId: string | null,
  actions: QueuedAction[]
): Promise<QueueProcessingResult> {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      ...(adminId ? { createdById: adminId } : {}),
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  if (volunteerId) {
    const volunteer = await prisma.volunteer.findFirst({
      where: {
        id: volunteerId,
        eventId,
      },
    });

    if (!volunteer) {
      throw new Error("VOLUNTEER_NOT_FOUND");
    }
  }

  const results: ActionResult[] = [];

  for (const action of actions) {
    try {
      const actionResult = await processAction(eventId, volunteerId, action);

      results.push({
        clientId: action.id,
        status: "success",
        serverId: actionResult.serverId,
      });
    } catch (error) {
      results.push({
        clientId: action.id,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }

  const succeeded = results.filter(
    (r: ActionResult) => r.status === "success"
  ).length;
  const failed = results.filter(
    (r: ActionResult) => r.status === "error"
  ).length;

  return {
    processed: actions.length,
    succeeded,
    failed,
    results,
  };
}

async function processAction(
  eventId: string,
  volunteerId: string | null,
  action: QueuedAction
): Promise<{ serverId: string }> {
  switch (action.type) {
    case "CHECK_IN":
      return processCheckIn(eventId, volunteerId, action);
    case "CHECK_OUT":
      return processCheckOut(eventId, volunteerId, action);
    case "QUICK_ALERT":
      return processQuickAlert(eventId, volunteerId, action);
    case "MESSAGE_READ":
      return processMessageRead(eventId, volunteerId, action);
    default:
      throw new Error(`Unknown action type: ${action.type}`);
  }
}

async function processCheckIn(
  eventId: string,
  volunteerId: string | null,
  action: QueuedAction
): Promise<{ serverId: string }> {
  const { assignmentId } = action.data as { assignmentId: string };

  if (!assignmentId) {
    throw new Error("Missing assignmentId for CHECK_IN");
  }

  const assignment = await prisma.assignment.findFirst({
    where: {
      id: assignmentId,
      volunteer: { eventId },
      deletedAt: null,
    },
    include: {
      volunteer: true,
    },
  });

  if (!assignment) {
    throw new Error("Assignment not found");
  }

  // If volunteer token, verify they own this assignment
  if (volunteerId && assignment.volunteerId !== volunteerId) {
    throw new Error("Not authorized for this assignment");
  }

  // Check for existing active check-in (idempotency)
  const existingCheckIn = await prisma.checkIn.findFirst({
    where: {
      assignmentId,
      status: "CHECKED_IN",
      deletedAt: null,
    },
  });

  if (existingCheckIn) {
    // Already checked in - return existing (idempotent)
    return { serverId: existingCheckIn.id };
  }

  // Create check-in with the offline timestamp
  const checkInTime = new Date(action.timestamp);

  const checkIn = await prisma.checkIn.create({
    data: {
      assignmentId,
      checkInTime: isNaN(checkInTime.getTime()) ? new Date() : checkInTime,
      status: "CHECKED_IN",
    },
  });

  return { serverId: checkIn.id };
}

async function processCheckOut(
  eventId: string,
  volunteerId: string | null,
  action: QueuedAction
): Promise<{ serverId: string }> {
  const { checkInId } = action.data as { checkInId: string };

  if (!checkInId) {
    throw new Error("Missing checkInId for CHECK_OUT");
  }

  // Verify check-in exists and belongs to this event
  const checkIn = await prisma.checkIn.findFirst({
    where: {
      id: checkInId,
      assignment: {
        volunteer: { eventId },
      },
      deletedAt: null,
    },
    include: {
      assignment: {
        include: { volunteer: true },
      },
    },
  });

  if (!checkIn) {
    throw new Error("Check-in not found");
  }

  // If volunteer token, verify they own this check-in
  if (volunteerId && checkIn.assignment.volunteerId !== volunteerId) {
    throw new Error("Not authorized for this check-in");
  }

  // Already checked out (idempotency)
  if (checkIn.checkOutTime) {
    return { serverId: checkIn.id };
  }

  // Update with checkout time
  const checkOutTime = new Date(action.timestamp);

  await prisma.checkIn.update({
    where: { id: checkInId },
    data: {
      checkOutTime: isNaN(checkOutTime.getTime()) ? new Date() : checkOutTime,
      status: "CHECKED_OUT",
    },
  });

  return { serverId: checkIn.id };
}

async function processQuickAlert(
  eventId: string,
  volunteerId: string | null,
  action: QueuedAction
): Promise<{ serverId: string }> {
  const { alertId, additionalNote } = action.data as {
    alertId: string;
    additionalNote?: string;
  };

  if (!alertId) {
    throw new Error("Missing alertId for QUICK_ALERT");
  }

  if (!volunteerId) {
    throw new Error("Volunteer ID required for QUICK_ALERT");
  }

  // Get the quick alert template
  const alert = await prisma.quickAlert.findFirst({
    where: {
      id: alertId,
      eventId,
      isActive: true,
    },
  });

  if (!alert) {
    throw new Error("Quick alert not found or inactive");
  }

  // Get volunteer info for context
  const volunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
    include: {
      role: true,
      assignments: {
        where: { deletedAt: null },
        include: {
          zone: true,
          session: true,
        },
        orderBy: { createdAt: "desc" },
        take: 1,
      },
    },
  });

  if (!volunteer) {
    throw new Error("Volunteer not found");
  }

  // Build message content with context
  let content = `🚨 ${alert.name}\n\n${alert.message}`;
  content += `\n\n— ${volunteer.name}`;

  if (volunteer.role) {
    content += ` (${volunteer.role.name})`;
  }

  // Add current assignment location if available
  const currentAssignment = volunteer.assignments[0];
  if (currentAssignment?.zone) {
    content += `\n📍 ${currentAssignment.zone.name}`;
  }

  if (additionalNote) {
    const sanitizedNote = additionalNote.slice(0, 200);
    content += `\n\n💬 "${sanitizedNote}"`;
  }

  // Get event admin to be the "sender" for system messages
  const event = await prisma.event.findUnique({
    where: { id: eventId },
  });

  if (!event) {
    throw new Error("Event not found");
  }

  // Create the message as a broadcast (all volunteers will see it)
  const message = await prisma.message.create({
    data: {
      content,
      priority: alert.priority,
      recipientType: "BROADCAST",
      eventId,
      senderAdminId: event.createdById, // System message from admin
    },
  });

  // Create recipient records for all volunteers
  const volunteers = await prisma.volunteer.findMany({
    where: { eventId },
    select: { id: true },
  });

  await prisma.messageRecipient.createMany({
    data: volunteers.map((v) => ({
      messageId: message.id,
      volunteerId: v.id,
    })),
  });

  return { serverId: message.id };
}

async function processMessageRead(
  eventId: string,
  volunteerId: string | null,
  action: QueuedAction
): Promise<{ serverId: string }> {
  const { messageId } = action.data as { messageId: string };

  if (!messageId) {
    throw new Error("Missing messageId for MESSAGE_READ");
  }

  if (!volunteerId) {
    throw new Error("Volunteer ID required for MESSAGE_READ");
  }

  // Find the recipient record
  const recipient = await prisma.messageRecipient.findFirst({
    where: {
      messageId,
      volunteerId: volunteerId,
      message: {
        eventId,
        deletedAt: null,
      },
    },
  });

  if (!recipient) {
    throw new Error("Message not found or not a recipient");
  }

  // Already read (idempotency)
  if (recipient.readAt) {
    return { serverId: recipient.id };
  }

  // Mark as read
  const readTime = new Date(action.timestamp);

  await prisma.messageRecipient.update({
    where: { id: recipient.id },
    data: {
      readAt: isNaN(readTime.getTime()) ? new Date() : readTime,
    },
  });

  return { serverId: recipient.id };
}

interface VolunteerSyncData {
  syncedAt: string;
  event: {
    id: string;
    name: string;
    type: string;
    location: string;
    startDate: string;
    endDate: string;
  };
  volunteer: {
    id: string;
    name: string;
    generatedId: string;
    roleId: string | null;
    roleName: string | null;
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
  }>;
  myAssignments: Array<{
    id: string;
    sessionId: string;
    zoneId: string;
    zoneName: string;
    sessionName: string;
    sessionDate: Date;
    sessionStartTime: Date;
    sessionEndTime: Date;
    notes: string | null;
  }>;
  messages: Array<{
    id: string;
    content: string;
    priority: string;
    senderName: string | null;
    createdAt: Date;
    isRead: boolean;
  }>;
  quickAlerts: Array<{
    id: string;
    name: string;
    message: string;
    priority: string;
  }>;
  myCheckIns: Array<{
    id: string;
    assignmentId: string;
    checkInTime: Date;
    checkOutTime: Date | null;
    status: string;
  }>;
}

export async function getVolunteerFullSync(
  volunteerId: string,
  eventId: string
): Promise<VolunteerSyncData> {
  // Verify volunteer exists and belongs to event
  const volunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
    include: {
      role: true,
      event: true,
    },
  });

  if (!volunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // Fetch all data in parallel
  const [
    sessions,
    zones,
    roles,
    allVolunteers,
    assignments,
    myAssignments,
    myMessages,
    quickAlerts,
    myCheckIns,
  ] = await Promise.all([
    // All sessions
    prisma.session.findMany({
      where: { eventId },
      select: {
        id: true,
        name: true,
        date: true,
        startTime: true,
        endTime: true,
      },
      orderBy: [{ date: "asc" }, { startTime: "asc" }],
    }),

    // All zones (no description for volunteers)
    prisma.zone.findMany({
      where: { eventId },
      select: {
        id: true,
        name: true,
        requiredCount: true,
        displayOrder: true,
      },
      orderBy: { displayOrder: "asc" },
    }),

    // All roles
    prisma.role.findMany({
      where: { eventId },
      select: {
        id: true,
        name: true,
        displayOrder: true,
      },
      orderBy: { displayOrder: "asc" },
    }),

    // All volunteers (sanitized - no phone, email, tokens)
    prisma.volunteer.findMany({
      where: { eventId },
      select: {
        id: true,
        name: true,
        congregation: true,
        appointment: true,
        roleId: true,
        role: { select: { name: true } },
      },
      orderBy: [{ role: { displayOrder: "asc" } }, { name: "asc" }],
    }),

    // All assignments (for schedule grid)
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
      },
    }),

    // My assignments with details
    prisma.assignment.findMany({
      where: {
        volunteerId,
        deletedAt: null,
      },
      select: {
        id: true,
        sessionId: true,
        zoneId: true,
        notes: true,
        zone: { select: { name: true } },
        session: {
          select: {
            name: true,
            date: true,
            startTime: true,
            endTime: true,
          },
        },
      },
      orderBy: {
        session: { startTime: "asc" },
      },
    }),

    // Messages where I'm a recipient
    prisma.message.findMany({
      where: {
        eventId,
        deletedAt: null,
        recipients: {
          some: { volunteerId },
        },
      },
      select: {
        id: true,
        content: true,
        priority: true,
        createdAt: true,
        senderAdmin: { select: { name: true } },
        senderVolunteer: { select: { name: true } },
        recipients: {
          where: { volunteerId },
          select: { readAt: true },
        },
      },
      orderBy: { createdAt: "desc" },
    }),

    // Active quick alerts
    prisma.quickAlert.findMany({
      where: {
        eventId,
        isActive: true,
      },
      select: {
        id: true,
        name: true,
        message: true,
        priority: true,
      },
      orderBy: { displayOrder: "asc" },
    }),

    // My check-ins
    prisma.checkIn.findMany({
      where: {
        assignment: { volunteerId },
        deletedAt: null,
      },
      select: {
        id: true,
        assignmentId: true,
        checkInTime: true,
        checkOutTime: true,
        status: true,
      },
      orderBy: { checkInTime: "desc" },
    }),
  ]);

  return {
    syncedAt: new Date().toISOString(),
    event: {
      id: volunteer.event.id,
      name: volunteer.event.name,
      type: volunteer.event.type,
      location: volunteer.event.location,
      startDate: volunteer.event.startDate.toISOString(),
      endDate: volunteer.event.endDate.toISOString(),
    },
    volunteer: {
      id: volunteer.id,
      name: volunteer.name,
      generatedId: volunteer.generatedId,
      roleId: volunteer.roleId,
      roleName: volunteer.role?.name || null,
    },
    sessions,
    zones,
    roles,
    volunteers: allVolunteers.map((v) => ({
      id: v.id,
      name: v.name,
      congregation: v.congregation,
      appointment: v.appointment,
      roleId: v.roleId,
      roleName: v.role?.name || null,
    })),
    assignments,
    myAssignments: myAssignments.map((a) => ({
      id: a.id,
      sessionId: a.sessionId,
      zoneId: a.zoneId,
      zoneName: a.zone.name,
      sessionName: a.session.name,
      sessionDate: a.session.date,
      sessionStartTime: a.session.startTime,
      sessionEndTime: a.session.endTime,
      notes: a.notes,
    })),
    messages: myMessages.map((m) => ({
      id: m.id,
      content: m.content,
      priority: m.priority,
      senderName: m.senderAdmin?.name || m.senderVolunteer?.name || null,
      createdAt: m.createdAt,
      isRead: m.recipients[0]?.readAt !== null,
    })),
    quickAlerts,
    myCheckIns,
  };
}

interface VolunteerDeltaSyncData {
  syncedAt: string;
  since: string;
  changes: {
    sessions: DeltaChanges<{
      id: string;
      name: string;
      date: Date;
      startTime: Date;
      endTime: Date;
    }>;
    zones: DeltaChanges<{
      id: string;
      name: string;
      requiredCount: number;
      displayOrder: number;
    }>;
    assignments: DeltaChanges<{
      id: string;
      volunteerId: string;
      sessionId: string;
      zoneId: string;
      notes: string | null;
    }>;
    myAssignments: DeltaChanges<{
      id: string;
      sessionId: string;
      zoneId: string;
      zoneName: string;
      sessionName: string;
      notes: string | null;
    }>;
    messages: DeltaChanges<{
      id: string;
      content: string;
      priority: string;
      senderName: string | null;
      createdAt: Date;
    }>;
    myCheckIns: DeltaChanges<{
      id: string;
      assignmentId: string;
      checkInTime: Date;
      checkOutTime: Date | null;
      status: string;
    }>;
  };
}

export async function getVolunteerDeltaSync(
  volunteerId: string,
  eventId: string,
  since: Date
): Promise<VolunteerDeltaSyncData> {
  // Verify volunteer exists and belongs to event
  const volunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
  });

  if (!volunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // Helper to categorize records
  const categorize = <
    T extends { id: string; createdAt: Date; updatedAt: Date },
  >(
    records: T[],
    sinceDate: Date
  ): { created: T[]; updated: T[] } => {
    const created: T[] = [];
    const updated: T[] = [];

    for (const record of records) {
      if (record.createdAt > sinceDate) {
        created.push(record);
      } else if (record.updatedAt > sinceDate) {
        updated.push(record);
      }
    }

    return { created, updated };
  };

  // Fetch changed data
  const [
    changedSessions,
    changedZones,
    changedAssignments,
    deletedAssignments,
    changedMyAssignments,
    deletedMyAssignments,
    changedMessages,
    deletedMessages,
    changedMyCheckIns,
    deletedMyCheckIns,
  ] = await Promise.all([
    // Changed sessions
    prisma.session.findMany({
      where: {
        eventId,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        name: true,
        date: true,
        startTime: true,
        endTime: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Changed zones
    prisma.zone.findMany({
      where: {
        eventId,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        name: true,
        requiredCount: true,
        displayOrder: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Changed assignments (all)
    prisma.assignment.findMany({
      where: {
        volunteer: { eventId },
        deletedAt: null,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        volunteerId: true,
        sessionId: true,
        zoneId: true,
        notes: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Deleted assignments
    prisma.assignment.findMany({
      where: {
        volunteer: { eventId },
        deletedAt: { gt: since },
      },
      select: { id: true },
    }),

    // Changed my assignments
    prisma.assignment.findMany({
      where: {
        volunteerId,
        deletedAt: null,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        sessionId: true,
        zoneId: true,
        notes: true,
        zone: { select: { name: true } },
        session: { select: { name: true } },
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Deleted my assignments
    prisma.assignment.findMany({
      where: {
        volunteerId,
        deletedAt: { gt: since },
      },
      select: { id: true },
    }),

    // Changed messages (where I'm recipient)
    prisma.message.findMany({
      where: {
        eventId,
        deletedAt: null,
        recipients: { some: { volunteerId } },
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        content: true,
        priority: true,
        createdAt: true,
        updatedAt: true,
        senderAdmin: { select: { name: true } },
        senderVolunteer: { select: { name: true } },
      },
    }),

    // Deleted messages
    prisma.message.findMany({
      where: {
        eventId,
        recipients: { some: { volunteerId } },
        deletedAt: { gt: since },
      },
      select: { id: true },
    }),

    // Changed my check-ins
    prisma.checkIn.findMany({
      where: {
        assignment: { volunteerId },
        deletedAt: null,
        OR: [{ createdAt: { gt: since } }, { updatedAt: { gt: since } }],
      },
      select: {
        id: true,
        assignmentId: true,
        checkInTime: true,
        checkOutTime: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    }),

    // Deleted my check-ins
    prisma.checkIn.findMany({
      where: {
        assignment: { volunteerId },
        deletedAt: { gt: since },
      },
      select: { id: true },
    }),
  ]);

  // Categorize
  const sessionChanges = categorize(changedSessions, since);
  const zoneChanges = categorize(changedZones, since);
  const assignmentChanges = categorize(changedAssignments, since);
  const myAssignmentChanges = categorize(changedMyAssignments, since);
  const messageChanges = categorize(changedMessages, since);
  const myCheckInChanges = categorize(changedMyCheckIns, since);

  return {
    syncedAt: new Date().toISOString(),
    since: since.toISOString(),
    changes: {
      sessions: {
        created: sessionChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: sessionChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: [],
      },
      zones: {
        created: zoneChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: zoneChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: [],
      },
      assignments: {
        created: assignmentChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: assignmentChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: deletedAssignments.map((a) => a.id),
      },
      myAssignments: {
        created: myAssignmentChanges.created.map((a) => ({
          id: a.id,
          sessionId: a.sessionId,
          zoneId: a.zoneId,
          zoneName: a.zone.name,
          sessionName: a.session.name,
          notes: a.notes,
        })),
        updated: myAssignmentChanges.updated.map((a) => ({
          id: a.id,
          sessionId: a.sessionId,
          zoneId: a.zoneId,
          zoneName: a.zone.name,
          sessionName: a.session.name,
          notes: a.notes,
        })),
        deleted: deletedMyAssignments.map((a) => a.id),
      },
      messages: {
        created: messageChanges.created.map((m) => ({
          id: m.id,
          content: m.content,
          priority: m.priority,
          senderName: m.senderAdmin?.name || m.senderVolunteer?.name || null,
          createdAt: m.createdAt,
        })),
        updated: messageChanges.updated.map((m) => ({
          id: m.id,
          content: m.content,
          priority: m.priority,
          senderName: m.senderAdmin?.name || m.senderVolunteer?.name || null,
          createdAt: m.createdAt,
        })),
        deleted: deletedMessages.map((m) => m.id),
      },
      myCheckIns: {
        created: myCheckInChanges.created.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        updated: myCheckInChanges.updated.map(
          ({ createdAt: _createdAt, updatedAt: _updatedAt, ...rest }) => rest
        ),
        deleted: deletedMyCheckIns.map((c) => c.id),
      },
    },
  };
}

import { prisma } from "../config/database.js";

interface CreateAssignmentInput {
  volunteerId: string;
  sessionId: string;
  zoneId: string;
  notes?: string;
  eventId: string;
}

interface BulkAssignmentInput {
  assignments: Array<{
    volunteerId: string;
    sessionId: string;
    zoneId: string;
    notes?: string;
  }>;
  eventId: string;
}

export async function createAssignment(
  input: CreateAssignmentInput,
  adminId: string
) {
  const { volunteerId, sessionId, zoneId, notes, eventId } = input;

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

  // Verify volunteer belongs to this event
  const volunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
  });

  if (!volunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // Verify session belongs to this event
  const session = await prisma.session.findFirst({
    where: {
      id: sessionId,
      eventId,
    },
  });

  if (!session) {
    throw new Error("SESSION_NOT_FOUND");
  }

  // Verify zone belongs to this event
  const zone = await prisma.zone.findFirst({
    where: {
      id: zoneId,
      eventId,
    },
  });

  if (!zone) {
    throw new Error("ZONE_NOT_FOUND");
  }

  // Check if volunteer is available for this session
  const availability = await prisma.volunteerAvailability.findUnique({
    where: {
      volunteerId_sessionId: {
        volunteerId,
        sessionId,
      },
    },
  });

  // If availability record exists and is false, volunteer is unavailable
  if (availability && !availability.isAvailable) {
    throw new Error("VOLUNTEER_UNAVAILABLE");
  }

  // Check for existing assignment (double-booking)
  const existingAssignment = await prisma.assignment.findUnique({
    where: {
      volunteerId_sessionId: {
        volunteerId,
        sessionId,
      },
    },
  });

  if (existingAssignment) {
    throw new Error("VOLUNTEER_ALREADY_ASSIGNED");
  }

  const assignment = await prisma.assignment.create({
    data: {
      volunteerId,
      sessionId,
      zoneId,
      notes: notes ?? null,
    },
    include: {
      volunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
        },
      },
      session: {
        select: {
          id: true,
          name: true,
          date: true,
          startTime: true,
          endTime: true,
        },
      },
      zone: {
        select: {
          id: true,
          name: true,
          requiredCount: true,
        },
      },
    },
  });

  return assignment;
}

export async function bulkCreateAssignments(
  input: BulkAssignmentInput,
  adminId: string
) {
  const { assignments, eventId } = input;

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

  // Collect unique IDs for validation
  const volunteerIds = [...new Set(assignments.map((a) => a.volunteerId))];
  const sessionIds = [...new Set(assignments.map((a) => a.sessionId))];
  const zoneIds = [...new Set(assignments.map((a) => a.zoneId))];

  // Verify all volunteers belong to this event
  const volunteers = await prisma.volunteer.findMany({
    where: {
      id: { in: volunteerIds },
      eventId,
    },
  });

  if (volunteers.length !== volunteerIds.length) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // Verify all sessions belong to this event
  const sessions = await prisma.session.findMany({
    where: {
      id: { in: sessionIds },
      eventId,
    },
  });

  if (sessions.length !== sessionIds.length) {
    throw new Error("SESSION_NOT_FOUND");
  }

  // Verify all zones belong to this event
  const zones = await prisma.zone.findMany({
    where: {
      id: { in: zoneIds },
      eventId,
    },
  });

  if (zones.length !== zoneIds.length) {
    throw new Error("ZONE_NOT_FOUND");
  }

  // Check availability for all volunteer-session pairs
  const unavailableRecords = await prisma.volunteerAvailability.findMany({
    where: {
      volunteerId: { in: volunteerIds },
      sessionId: { in: sessionIds },
      isAvailable: false,
    },
  });

  if (unavailableRecords.length > 0) {
    const unavailableVolunteer = unavailableRecords[0]!;
    throw new Error(
      `VOLUNTEER_UNAVAILABLE:${unavailableVolunteer.volunteerId}`
    );
  }

  // Check for existing assignments (conflicts)
  const existingAssignments = await prisma.assignment.findMany({
    where: {
      OR: assignments.map((a) => ({
        volunteerId: a.volunteerId,
        sessionId: a.sessionId,
      })),
    },
  });

  if (existingAssignments.length > 0) {
    throw new Error(
      `VOLUNTEER_ALREADY_ASSIGNED:${existingAssignments[0]!.volunteerId}`
    );
  }

  // Check for duplicates within the input itself
  const seen = new Set<string>();
  for (const a of assignments) {
    const key = `${a.volunteerId}-${a.sessionId}`;
    if (seen.has(key)) {
      throw new Error(`DUPLICATE_IN_REQUEST:${a.volunteerId}`);
    }
    seen.add(key);
  }

  // Create all assignments
  await prisma.assignment.createMany({
    data: assignments.map((a) => ({
      volunteerId: a.volunteerId,
      sessionId: a.sessionId,
      zoneId: a.zoneId,
      notes: a.notes ?? null,
    })),
  });

  // Fetch created assignments with relations
  const createdAssignments = await prisma.assignment.findMany({
    where: {
      OR: assignments.map((a) => ({
        volunteerId: a.volunteerId,
        sessionId: a.sessionId,
      })),
    },
    include: {
      volunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
        },
      },
      session: {
        select: {
          id: true,
          name: true,
          date: true,
          startTime: true,
          endTime: true,
        },
      },
      zone: {
        select: {
          id: true,
          name: true,
          requiredCount: true,
        },
      },
    },
  });

  return createdAssignments;
}

export async function getAssignmentsByEvent(eventId: string, adminId: string) {
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

  const assignments = await prisma.assignment.findMany({
    where: {
      session: { eventId },
    },
    include: {
      volunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
          role: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      },
      session: {
        select: {
          id: true,
          name: true,
          date: true,
          startTime: true,
          endTime: true,
        },
      },
      zone: {
        select: {
          id: true,
          name: true,
          requiredCount: true,
          displayOrder: true,
        },
      },
    },
    orderBy: [
      { session: { date: "asc" } },
      { session: { startTime: "asc" } },
      { zone: { displayOrder: "asc" } },
      { volunteer: { name: "asc" } },
    ],
  });

  return assignments;
}

export async function getAssignmentsBySession(
  sessionId: string,
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

  // Verify session belongs to this event
  const session = await prisma.session.findFirst({
    where: {
      id: sessionId,
      eventId,
    },
  });

  if (!session) {
    throw new Error("SESSION_NOT_FOUND");
  }

  const assignments = await prisma.assignment.findMany({
    where: { sessionId },
    include: {
      volunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
          role: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      },
      zone: {
        select: {
          id: true,
          name: true,
          requiredCount: true,
          displayOrder: true,
        },
      },
    },
    orderBy: [
      { zone: { displayOrder: "asc" } },
      { volunteer: { name: "asc" } },
    ],
  });

  return {
    session,
    assignments,
  };
}

export async function getAssignmentsByZone(
  zoneId: string,
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

  // Verify zone belongs to this event
  const zone = await prisma.zone.findFirst({
    where: {
      id: zoneId,
      eventId,
    },
  });

  if (!zone) {
    throw new Error("ZONE_NOT_FOUND");
  }

  const assignments = await prisma.assignment.findMany({
    where: { zoneId },
    include: {
      volunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
          role: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      },
      session: {
        select: {
          id: true,
          name: true,
          date: true,
          startTime: true,
          endTime: true,
        },
      },
    },
    orderBy: [
      { session: { date: "asc" } },
      { session: { startTime: "asc" } },
      { volunteer: { name: "asc" } },
    ],
  });

  return {
    zone,
    assignments,
  };
}

export async function deleteAssignment(
  assignmentId: string,
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

  // Verify assignment exists and belongs to this event
  const assignment = await prisma.assignment.findFirst({
    where: {
      id: assignmentId,
      session: { eventId },
    },
  });

  if (!assignment) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Soft delete instead of hard delete
  await prisma.assignment.update({
    where: { id: assignmentId },
    data: { deletedAt: new Date() },
  });

  return { deleted: true };
}

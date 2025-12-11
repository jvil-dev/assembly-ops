import { prisma } from "../config/database";

interface ZoneFillStatus {
  zone: {
    id: string;
    name: string;
    requiredCount: number;
    displayOrder: number;
  };
  assignedCount: number;
  isFilled: boolean;
  volunteers: Array<{
    id: string;
    name: string;
    phone: string | null;
    congregation: string | null;
    assignmentId: string;
    notes: string | null;
  }>;
}

interface SessionSchedule {
  session: {
    id: string;
    name: string;
    date: Date;
    startTime: Date;
    endTime: Date;
  };
  zones: ZoneFillStatus[];
  totalRequired: number;
  totalAssigned: number;
}

interface ScheduleGrid {
  eventId: string;
  eventName: string;
  sessions: SessionSchedule[];
  overallSummary: {
    totalRequired: number;
    totalAssigned: number;
    fillPercentage: number;
  };
}

export async function getScheduleGrid(
  eventId: string,
  adminId: string
): Promise<ScheduleGrid> {
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

  // Get all sessions ordered by date and time
  const sessions = await prisma.session.findMany({
    where: { eventId },
    orderBy: [{ date: "asc" }, { startTime: "asc" }],
  });

  // Get all zones ordered by display order
  const zones = await prisma.zone.findMany({
    where: { eventId },
    orderBy: { displayOrder: "asc" },
  });

  // Get all assignments
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
        },
      },
    },
  });

  // Build the grid
  let overallTotalRequired = 0;
  let overallTotalAssigned = 0;

  const SessionSchedules: SessionSchedule[] = sessions.map((session) => {
    const ZoneFillStatuses: ZoneFillStatus[] = zones.map((zone) => {
      // Find assignments for this session + zone combo
      const zoneAssignments = assignments.filter(
        (a) => a.sessionId === session.id && a.zoneId === zone.id
      );

      const assignedCount = zoneAssignments.length;
      const isFilled = assignedCount >= zone.requiredCount;

      return {
        zone: {
          id: zone.id,
          name: zone.name,
          requiredCount: zone.requiredCount,
          displayOrder: zone.displayOrder,
        },
        assignedCount,
        isFilled,
        volunteers: zoneAssignments.map((a) => ({
          id: a.volunteer.id,
          name: a.volunteer.name,
          phone: a.volunteer.phone,
          congregation: a.volunteer.congregation,
          assignmentId: a.id,
          notes: a.notes,
        })),
      };
    });

    const sessionTotalRequired = zones.reduce(
      (sum, z) => sum + z.requiredCount,
      0
    );
    const sessionTotalAssigned = ZoneFillStatuses.reduce(
      (sum, z) => sum + z.assignedCount,
      0
    );

    overallTotalRequired += sessionTotalRequired;
    overallTotalAssigned += sessionTotalAssigned;

    return {
      session: {
        id: session.id,
        name: session.name,
        date: session.date,
        startTime: session.startTime,
        endTime: session.endTime,
      },
      zones: ZoneFillStatuses,
      totalRequired: sessionTotalRequired,
      totalAssigned: sessionTotalAssigned,
    };
  });

  const fillPercentage =
    overallTotalRequired > 0
      ? Math.round((overallTotalAssigned / overallTotalRequired) * 100)
      : 0;
  return {
    eventId: event.id,
    eventName: event.name,
    sessions: SessionSchedules,
    overallSummary: {
      totalRequired: overallTotalRequired,
      totalAssigned: overallTotalAssigned,
      fillPercentage,
    },
  };
}

interface SessionSummary {
  session: {
    id: string;
    name: string;
    date: Date;
    startTime: Date;
    endTime: Date;
  };
  totalRequired: number;
  totalAssigned: number;
  fillPercentage: number;
  isFilled: boolean;
  zonesNeedingCoverage: Array<{
    zoneId: string;
    zoneName: string;
    required: number;
    assigned: number;
    needed: number;
  }>;
}

export async function getScheduleSummary(
  eventId: string,
  adminId: string
): Promise<SessionSummary[]> {
  // Verify if admin owns the event
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  // Get all sessions
  const sessions = await prisma.session.findMany({
    where: { eventId },
    orderBy: [{ date: "asc" }, { startTime: "asc" }],
  });

  // Get all zones
  const zones = await prisma.zone.findMany({
    where: { eventId },
    orderBy: { displayOrder: "asc" },
  });

  // Get assignment counts per session per zone
  const assignmentCounts = await prisma.assignment.groupBy({
    by: ["sessionId", "zoneId"],
    where: {
      session: { eventId },
    },
    _count: true,
  });

  // Build summary for each session
  const summaries: SessionSummary[] = sessions.map((session) => {
    const zonesNeedingCoverage: SessionSummary["zonesNeedingCoverage"] = [];
    let totalRequired = 0;
    let totalAssigned = 0;

    zones.forEach((zone) => {
      const countRecord = assignmentCounts.find(
        (c) => c.sessionId === session.id && c.zoneId === zone.id
      );
      const assigned = countRecord?._count ?? 0;
      const needed = zone.requiredCount - assigned;

      totalRequired += zone.requiredCount;
      totalAssigned += assigned;

      if (needed > 0) {
        zonesNeedingCoverage.push({
          zoneId: zone.id,
          zoneName: zone.name,
          required: zone.requiredCount,
          assigned,
          needed,
        });
      }
    });

    const fillPercentage =
      totalRequired > 0 ? Math.round((totalAssigned / totalRequired) * 100) : 0;

    return {
      session: {
        id: session.id,
        name: session.name,
        date: session.date,
        startTime: session.startTime,
        endTime: session.endTime,
      },
      totalRequired,
      totalAssigned,
      fillPercentage,
      isFilled: totalAssigned >= totalRequired,
      zonesNeedingCoverage,
    };
  });

  return summaries;
}

export async function getVolunteerAssignments(
  volunteerId: string,
  eventId: string
) {
  // Verify volunteer belongs to this event
  const volunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
    select: {
      id: true,
      name: true,
      generatedId: true,
      role: {
        select: {
          id: true,
          name: true,
        },
      },
    },
  });

  if (!volunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // Get event info
  const event = await prisma.event.findUnique({
    where: { id: eventId },
    select: {
      id: true,
      name: true,
      type: true,
      location: true,
      startDate: true,
      endDate: true,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  // Get volunteer's assignments
  const assignments = await prisma.assignment.findMany({
    where: {
      volunteerId,
      session: { eventId },
    },
    include: {
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
          description: true,
        },
      },
    },
    orderBy: [{ session: { date: "asc" } }, { session: { startTime: "asc" } }],
  });

  // Get any pending swap requests for this volunteer's assignments
  const assignmentIds = assignments.map((a) => a.id);
  const pendingSwapRequests = await prisma.swapRequest.findMany({
    where: {
      assignmentId: { in: assignmentIds },
      status: "PENDING",
    },
    select: {
      id: true,
      assignmentId: true,
      reason: true,
      createdAt: true,
    },
  });

  // Attach swap request status to assignments
  const assignmentsWithSwapStatus = assignments.map((assignment) => {
    const pendingRequest = pendingSwapRequests.find(
      (r) => r.assignmentId === assignment.id
    );
    return {
      id: assignment.id,
      notes: assignment.notes,
      session: assignment.session,
      zone: assignment.zone,
      hasPendingSwapRequest: !!pendingRequest,
      pendingSwapRequests: pendingRequest || null,
    };
  });

  return {
    volunteer: {
      id: volunteer.id,
      name: volunteer.name,
      generatedId: volunteer.generatedId,
      role: volunteer.role,
    },
    event,
    assignments: assignmentsWithSwapStatus,
    totalAssignments: assignments.length,
  };
}

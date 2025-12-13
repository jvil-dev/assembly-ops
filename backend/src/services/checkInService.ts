import { prisma } from "../config/database.js";
import { CheckInStatus } from "../generated/prisma/client.js";

// Grace period in minutes before marking as late
const LATE_THRESHOLD_MINUTES = 5;

interface CheckInResult {
  checkIn: {
    id: string;
    checkInTime: Date;
    checkOutTime: Date | null;
    status: CheckInStatus;
    isLate: boolean;
    notes: string | null;
    assignmentId: string;
  };
  assignment: {
    id: string;
    zone: {
      id: string;
      name: string;
    };
    session: {
      id: string;
      name: string;
      startTime: Date;
      endTime: Date;
    };
  };
}

export async function volunteerCheckIn(
  volunteerId: string
): Promise<CheckInResult> {
  // Get current time
  const now = new Date();

  // Find the volunteer's assignment for current or upcoming session
  const assignment = await prisma.assignment.findFirst({
    where: {
      volunteerId,
      session: {
        endTime: {
          gte: now,
        },
      },
      checkIn: null,
    },
    include: {
      session: true,
      zone: true,
    },
    orderBy: {
      session: {
        startTime: "asc",
      },
    },
  });

  if (!assignment) {
    // Check if they have any assignments at all
    const anyAssignment = await prisma.assignment.findFirst({
      where: { volunteerId },
    });

    if (!anyAssignment) {
      throw new Error("NO_ASSIGNMENT");
    }

    // Check if already checked in
    const existingCheckIn = await prisma.assignment.findFirst({
      where: {
        volunteerId,
        checkIn: {
          status: CheckInStatus.CHECKED_IN,
        },
      },
    });

    if (existingCheckIn) {
      throw new Error("ALREADY_CHECKED_IN");
    }

    throw new Error("NO_ELIGIBLE_ASSIGNMENT");
  }

  // Calculate if late (more than threshold after session start)
  const sessionStart = assignment.session.startTime;
  const lateThreshold = new Date(
    sessionStart.getTime() + LATE_THRESHOLD_MINUTES * 60 * 1000
  );
  const isLate = now > lateThreshold;

  // Create check-in record
  const checkIn = await prisma.checkIn.create({
    data: {
      checkInTime: now,
      status: CheckInStatus.CHECKED_IN,
      isLate,
      assignmentId: assignment.id,
    },
  });

  return {
    checkIn,
    assignment: {
      id: assignment.id,
      zone: {
        id: assignment.zone.id,
        name: assignment.zone.name,
      },
      session: {
        id: assignment.session.id,
        name: assignment.session.name,
        startTime: assignment.session.startTime,
        endTime: assignment.session.endTime,
      },
    },
  };
}

export async function getVolunteerStatus(volunteerId: string) {
  const now = new Date();

  // Get current check-in
  const currentCheckIn = await prisma.checkIn.findFirst({
    where: {
      assignment: { volunteerId },
      status: CheckInStatus.CHECKED_IN,
    },
    include: {
      assignment: {
        include: {
          session: true,
          zone: true,
        },
      },
    },
  });

  // Get upcoming assignments (sessions that haven't ended)
  const upcomingAssignments = await prisma.assignment.findMany({
    where: {
      volunteerId,
      session: {
        endTime: { gte: now },
      },
    },
    include: {
      session: true,
      zone: true,
      checkIn: true,
    },
    orderBy: {
      session: { startTime: "asc" },
    },
  });

  // Get today's completed check-ins
  const todayStart = new Date(now);
  todayStart.setHours(0, 0, 0, 0);
  const todayEnd = new Date(now);
  todayEnd.setHours(23, 59, 59, 999);

  const todaysCheckIns = await prisma.checkIn.findMany({
    where: {
      assignment: { volunteerId },
      checkInTime: {
        gte: todayStart,
        lte: todayEnd,
      },
    },
    include: {
      assignment: {
        include: {
          session: true,
          zone: true,
        },
      },
    },
    orderBy: {
      checkInTime: "asc",
    },
  });

  return {
    currentCheckIn: currentCheckIn
      ? {
          id: currentCheckIn.id,
          checkInTime: currentCheckIn.checkInTime,
          isLate: currentCheckIn.isLate,
          assignment: {
            id: currentCheckIn.assignment.id,
            zone: {
              id: currentCheckIn.assignment.zone.id,
              name: currentCheckIn.assignment.zone.name,
            },
            session: {
              id: currentCheckIn.assignment.session.id,
              name: currentCheckIn.assignment.session.name,
              startTime: currentCheckIn.assignment.session.startTime,
              endTime: currentCheckIn.assignment.session.endTime,
            },
          },
        }
      : null,
    upcomingAssignments: upcomingAssignments.map((a) => ({
      id: a.id,
      zone: { id: a.zone.id, name: a.zone.name },
      session: {
        id: a.session.id,
        name: a.session.name,
        startTime: a.session.startTime,
        endTime: a.session.endTime,
      },
      isCheckedIn: a.checkIn !== null,
      checkInTime: a.checkIn?.checkInTime || null,
    })),
    todaysHistory: todaysCheckIns.map((c) => ({
      id: c.id,
      checkInTime: c.checkInTime,
      checkOutTime: c.checkOutTime,
      status: c.status,
      isLate: c.isLate,
      zone: c.assignment.zone.name,
      session: c.assignment.session.name,
    })),
  };
}

export async function volunteerCheckOut(volunteerId: string) {
  // Find current active check-in
  const checkIn = await prisma.checkIn.findFirst({
    where: {
      assignment: { volunteerId },
      status: CheckInStatus.CHECKED_IN,
    },
    include: {
      assignment: {
        include: {
          session: true,
          zone: true,
        },
      },
    },
  });

  if (!checkIn) {
    throw new Error("NOT_CHECKED_IN");
  }

  // Update check-in record
  const now = new Date();
  const updatedCheckIn = await prisma.checkIn.update({
    where: { id: checkIn.id },
    data: {
      checkOutTime: now,
      status: CheckInStatus.CHECKED_OUT,
    },
  });

  return {
    checkIn: updatedCheckIn,
    assignment: {
      id: checkIn.assignment.id,
      zone: {
        id: checkIn.assignment.zone.id,
        name: checkIn.assignment.zone.name,
      },
      session: {
        id: checkIn.assignment.session.id,
        name: checkIn.assignment.session.name,
        startTime: checkIn.assignment.session.startTime,
        endTime: checkIn.assignment.session.endTime,
      },
    },
  };
}

interface AdminCheckInInput {
  assignmentId: string;
  eventId: string;
  adminId: string;
  checkInTime?: Date;
  isLate?: boolean;
  notes?: string;
}

export async function adminCheckIn(input: AdminCheckInInput) {
  const { assignmentId, eventId, adminId, checkInTime, isLate, notes } = input;

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

  // Get assignment and verify it belongs to this event
  const assignment = await prisma.assignment.findFirst({
    where: {
      id: assignmentId,
    },
    include: {
      session: true,
      zone: true,
      volunteer: true,
      checkIn: true,
    },
  });

  if (!assignment) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Verify assignment belongs to this event (via session)
  if (assignment.session.eventId !== eventId) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Check if already has a check-in
  if (assignment.checkIn) {
    throw new Error("ALREADY_CHECKED_IN");
  }

  // Determine check-in time and late status
  const actualCheckInTime = checkInTime || new Date();

  // Calculate late status if not explicitly provided
  let calculatedIsLate = isLate;
  if (calculatedIsLate === undefined) {
    const sessionStart = assignment.session.startTime;
    const lateThreshold = new Date(sessionStart.getTime() + 5 * 60 * 1000);
    calculatedIsLate = actualCheckInTime > lateThreshold;
  }

  // Create check-in record
  const checkIn = await prisma.checkIn.create({
    data: {
      checkInTime: actualCheckInTime,
      status: CheckInStatus.CHECKED_IN,
      isLate: calculatedIsLate,
      notes: notes ?? null,
      assignmentId,
    },
  });

  return {
    checkIn,
    assignment: {
      id: assignment.id,
      volunteer: {
        id: assignment.volunteer.id,
        name: assignment.volunteer.name,
      },
      zone: {
        id: assignment.zone.id,
        name: assignment.zone.name,
      },
      session: {
        id: assignment.session.id,
        name: assignment.session.name,
        startTime: assignment.session.startTime,
        endTime: assignment.session.endTime,
      },
    },
  };
}

interface AdminUpdateCheckInInput {
  assignmentId: string;
  eventId: string;
  adminId: string;
  status?: CheckInStatus;
  checkOutTime?: Date;
  isLate?: boolean;
  notes?: string;
}

export async function adminUpdateCheckIn(input: AdminUpdateCheckInInput) {
  const {
    assignmentId,
    eventId,
    adminId,
    status,
    checkOutTime,
    isLate,
    notes,
  } = input;

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

  // Get assignment with check-in
  const assignment = await prisma.assignment.findFirst({
    where: {
      id: assignmentId,
    },
    include: {
      session: true,
      zone: true,
      volunteer: true,
      checkIn: true,
    },
  });

  if (!assignment) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Verify assignment belongs to this event
  if (assignment.session.eventId !== eventId) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Must have existing check-in to update
  if (!assignment.checkIn) {
    throw new Error("NO_CHECK_IN");
  }

  // Build update data
  const updateData: Record<string, unknown> = {};

  if (status !== undefined) {
    updateData.status = status;

    // If marking as CHECKED_OUT, set checkOutTime if not provided
    if (
      status === CheckInStatus.CHECKED_OUT &&
      !checkOutTime &&
      !assignment.checkIn.checkOutTime
    ) {
      updateData.checkOutTime = new Date();
    }
  }

  if (checkOutTime !== undefined) {
    updateData.checkOutTime = checkOutTime;
  }

  if (isLate !== undefined) {
    updateData.isLate = isLate;
  }

  if (notes !== undefined) {
    updateData.notes = notes;
  }

  if (Object.keys(updateData).length === 0) {
    throw new Error("NO_UPDATES");
  }

  // Update check-in record
  const updatedCheckIn = await prisma.checkIn.update({
    where: { id: assignment.checkIn.id },
    data: updateData,
  });

  return {
    checkIn: updatedCheckIn,
    assignment: {
      id: assignment.id,
      volunteer: {
        id: assignment.volunteer.id,
        name: assignment.volunteer.name,
      },
      zone: {
        id: assignment.zone.id,
        name: assignment.zone.name,
      },
      session: {
        id: assignment.session.id,
        name: assignment.session.name,
        startTime: assignment.session.startTime,
        endTime: assignment.session.endTime,
      },
    },
  };
}

interface AdminDeleteCheckInInput {
  assignmentId: string;
  eventId: string;
  adminId: string;
}

export async function adminDeleteCheckIn(input: AdminDeleteCheckInInput) {
  const { assignmentId, eventId, adminId } = input;

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

  // Get assignment with check-in
  const assignment = await prisma.assignment.findFirst({
    where: {
      id: assignmentId,
    },
    include: {
      session: true,
      checkIn: true,
    },
  });

  if (!assignment) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Verify assignment belongs to this event
  if (assignment.session.eventId !== eventId) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Must have existing check-in to delete
  if (!assignment.checkIn) {
    throw new Error("NO_CHECK_IN");
  }

  // Delete check-in record
  await prisma.checkIn.delete({
    where: {
      id: assignment.checkIn.id,
    },
  });

  return { deleted: true };
}

export async function getActiveCheckIns(eventId: string, adminId: string) {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  const activeCheckIns = await prisma.checkIn.findMany({
    where: {
      status: CheckInStatus.CHECKED_IN,
      assignment: {
        session: { eventId },
      },
    },
    include: {
      assignment: {
        include: {
          volunteer: {
            select: {
              id: true,
              name: true,
              phone: true,
              generatedId: true,
            },
          },
          zone: {
            select: {
              id: true,
              name: true,
            },
          },
          session: {
            select: {
              id: true,
              name: true,
              startTime: true,
              endTime: true,
            },
          },
        },
      },
    },
    orderBy: {
      checkInTime: "desc",
    },
  });

  return {
    activeCount: activeCheckIns.length,
    checkIns: activeCheckIns.map((checkIn) => ({
      id: checkIn.id,
      checkInTime: checkIn.checkInTime,
      isLate: checkIn.isLate,
      volunteer: checkIn.assignment.volunteer,
      zone: checkIn.assignment.zone,
      session: checkIn.assignment.session,
    })),
  };
}

export async function getCheckInsByZone(
  zoneId: string,
  eventId: string,
  adminId: string
) {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  const zone = await prisma.zone.findFirst({
    where: {
      id: zoneId,
      eventId,
    },
  });

  if (!zone) {
    throw new Error("ZONE_NOT_FOUND");
  }

  const activeCheckIns = await prisma.checkIn.findMany({
    where: {
      status: CheckInStatus.CHECKED_IN,
      assignment: {
        zoneId,
      },
    },
    include: {
      assignment: {
        include: {
          volunteer: {
            select: {
              id: true,
              name: true,
              phone: true,
              generatedId: true,
            },
          },
          session: {
            select: {
              id: true,
              name: true,
              startTime: true,
              endTime: true,
            },
          },
        },
      },
    },
    orderBy: {
      checkInTime: "asc",
    },
  });

  return {
    zone: {
      id: zone.id,
      name: zone.name,
      requiredCount: zone.requiredCount,
    },
    activeCount: activeCheckIns.length,
    isFilled: activeCheckIns.length >= zone.requiredCount,
    checkIns: activeCheckIns.map((checkIn) => ({
      id: checkIn.id,
      checkInTime: checkIn.checkInTime,
      isLate: checkIn.isLate,
      volunteer: checkIn.assignment.volunteer,
      session: checkIn.assignment.session,
    })),
  };
}

export async function getCheckInsBySession(
  sessionId: string,
  eventId: string,
  adminId: string
) {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

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
    where: {
      sessionId,
    },
    include: {
      volunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          generatedId: true,
        },
      },
      zone: {
        select: {
          id: true,
          name: true,
        },
      },
      checkIn: true,
    },
    orderBy: [
      { zone: { displayOrder: "asc" } },
      { volunteer: { name: "asc" } },
    ],
  });

  // Calculate stats
  const stats = {
    total: assignments.length,
    checkedIn: 0,
    checkedOut: 0,
    missed: 0,
    pending: 0,
    late: 0,
  };

  const assignmentDetails = assignments.map((assignment) => {
    const checkIn = assignment.checkIn;
    let status: string;

    if (!checkIn) {
      status = "PENDING";
      stats.pending++;
    } else {
      status = checkIn.status;
      if (checkIn.status === CheckInStatus.CHECKED_IN) stats.checkedIn++;
      else if (checkIn.status === CheckInStatus.CHECKED_OUT) stats.checkedOut++;
      else if (checkIn.status === CheckInStatus.MISSED) stats.missed++;

      if (checkIn.isLate) stats.late++;
    }

    return {
      assignmentId: assignment.id,
      volunteer: assignment.volunteer,
      zone: assignment.zone,
      status,
      checkIn: checkIn
        ? {
            id: checkIn.id,
            checkInTime: checkIn.checkInTime,
            checkOutTime: checkIn.checkOutTime,
            isLate: checkIn.isLate,
          }
        : null,
    };
  });

  return {
    session: {
      id: session.id,
      name: session.name,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
    },
    stats,
    assignments: assignmentDetails,
  };
}

interface SummaryFilters {
  sessionId?: string;
  date?: Date;
}

export async function getCheckInSummary(
  eventId: string,
  adminId: string,
  filters: SummaryFilters = {}
) {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  const assignmentFilter: Record<string, unknown> = {
    session: { eventId },
  };

  if (filters.sessionId) {
    assignmentFilter.sessionId = filters.sessionId;
  }

  if (filters.sessionId) {
    assignmentFilter.sessionId = filters.sessionId;
  }

  if (filters.date) {
    const startOfDay = new Date(filters.date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(filters.date);
    endOfDay.setHours(23, 59, 59, 999);

    assignmentFilter.session = {
      ...(assignmentFilter.session as object),
      date: {
        gte: startOfDay,
        lte: endOfDay,
      },
    };
  }

  const assignments = await prisma.assignment.findMany({
    where: assignmentFilter,
    include: {
      checkIn: true,
      session: {
        select: {
          id: true,
          name: true,
          date: true,
          endTime: true,
        },
      },
      zone: {
        select: {
          id: true,
          name: true,
        },
      },
      volunteer: {
        select: {
          id: true,
          name: true,
        },
      },
    },
  });

  const now = new Date();

  const summary = {
    totalAssignments: assignments.length,
    completed: 0,
    checkedIn: 0,
    missed: 0,
    pending: 0,
    lateArrivals: 0,
  };

  const zoneStats: Record<
    string,
    {
      zoneName: string;
      total: number;
      completed: number;
      checkedIn: number;
      missed: number;
      pending: number;
    }
  > = {};

  const lateArrivals: Array<{
    volunteer: { id: string; name: string };
    zone: { id: string; name: string };
    session: { id: string; name: string };
    checkInTime: Date;
  }> = [];

  const missedShifts: Array<{
    volunteer: { id: string; name: string };
    zone: { id: string; name: string };
    session: { id: string; name: string };
  }> = [];

  for (const assignment of assignments) {
    const zoneId = assignment.zone.id;

    if (!zoneStats[zoneId]) {
      zoneStats[zoneId] = {
        zoneName: assignment.zone.name,
        total: 0,
        completed: 0,
        checkedIn: 0,
        missed: 0,
        pending: 0,
      };
    }
    zoneStats[zoneId].total++;

    const checkIn = assignment.checkIn;
    const sessionEnded = assignment.session.endTime < now;

    if (!checkIn) {
      if (sessionEnded) {
        summary.missed++;
        zoneStats[zoneId].missed++;
        missedShifts.push({
          volunteer: assignment.volunteer,
          zone: assignment.zone,
          session: { id: assignment.session.id, name: assignment.session.name },
        });
      } else {
        summary.pending++;
        zoneStats[zoneId].pending++;
      }
    } else if (checkIn.status === CheckInStatus.CHECKED_OUT) {
      summary.completed++;
      zoneStats[zoneId].completed++;
      if (checkIn.isLate) {
        summary.lateArrivals++;
        lateArrivals.push({
          volunteer: assignment.volunteer,
          zone: assignment.zone,
          session: { id: assignment.zone.id, name: assignment.session.name },
          checkInTime: checkIn.checkInTime,
        });
      }
    } else if (checkIn.status === CheckInStatus.CHECKED_IN) {
      summary.checkedIn++;
      zoneStats[zoneId].checkedIn++;
      if (checkIn.isLate) {
        summary.lateArrivals++;
        lateArrivals.push({
          volunteer: assignment.volunteer,
          zone: assignment.zone,
          session: { id: assignment.session.id, name: assignment.session.name },
          checkInTime: checkIn.checkInTime,
        });
      }
    } else if (checkIn.status === CheckInStatus.MISSED) {
      summary.missed++;
      zoneStats[zoneId].missed++;
      missedShifts.push({
        volunteer: assignment.volunteer,
        zone: assignment.zone,
        session: { id: assignment.session.id, name: assignment.session.name },
      });
    }
  }

  const completedOrCheckedIn = summary.completed + summary.checkedIn;
  const completionRate =
    summary.totalAssignments > 0
      ? Math.round((completedOrCheckedIn / summary.totalAssignments) * 100)
      : 0;

  return {
    summary: {
      ...summary,
      completionRate,
    },
    byZone: Object.entries(zoneStats).map(([zoneId, stats]) => ({
      zoneId,
      ...stats,
    })),
    lateArrivals,
    missedShifts,
  };
}

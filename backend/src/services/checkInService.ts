import { prisma } from "../config/database";
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
  volunteerId: string,
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
    sessionStart.getTime() + LATE_THRESHOLD_MINUTES * 60 * 1000,
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

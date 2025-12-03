import { prisma } from "../config/database";

interface SetAvailabilityInput {
  sessionId: string;
  isAvailable: boolean;
}

export async function getVolunteerAvailability(
  volunteerId: string,
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

  // Get all sessions for this event with availability status
  const sessions = await prisma.session.findMany({
    where: { eventId },
    orderBy: [{ date: "asc" }, { startTime: "asc" }],
    include: {
      availability: {
        where: { volunteerId },
      },
    },
  });

  // Transform to cleaner format
  const availability = sessions.map((session) => {
    const availRecord = session.availability[0];
    return {
      sessionId: session.id,
      sessionName: session.name,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
      isAvailable: availRecord?.isAvailable ?? true,
    };
  });

  return {
    volunteerId,
    volunteerName: volunteer.name,
    availability,
  };
}

export async function setVolunteerAvailability(
  volunteerId: string,
  eventId: string,
  adminId: string,
  availabilityData: SetAvailabilityInput[]
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

  // Verify all sessionIds belong to this event
  const sessionIds = availabilityData.map((a) => a.sessionId);
  const sessions = await prisma.session.findMany({
    where: {
      id: { in: sessionIds },
      eventId,
    },
  });

  if (sessions.length !== sessionIds.length) {
    throw new Error("SESSION_NOT_FOUND");
  }

  // Upsert availability records
  const results = await Promise.all(
    availabilityData.map((item) =>
      prisma.volunteerAvailability.upsert({
        where: {
          volunteerId_sessionId: {
            volunteerId,
            sessionId: item.sessionId,
          },
        },
        update: {
          isAvailable: item.isAvailable,
        },
        create: {
          volunteerId,
          sessionId: item.sessionId,
          isAvailable: item.isAvailable,
        },
      })
    )
  );

  return results;
}

export async function getAvailableVolunteersForSession(
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

  // Get all volunteers for this event
  const volunteers = await prisma.volunteer.findMany({
    where: { eventId },
    include: {
      role: true,
      availability: {
        where: { sessionId },
      },
    },
    orderBy: [{ role: { displayOrder: "asc" } }, { name: "asc" }],
  });

  // Filter to only available volunteers
  // If no availability record exists, default to available (true)
  const availableVolunteers = volunteers.filter((vol) => {
    const availRecord = vol.availability[0];
    return availRecord?.isAvailable ?? true;
  });

  // Clean up response (remove availability array from each volunteer)
  const result = availableVolunteers.map((vol) => {
    const { availability: _, ...volunteerWithoutAvailability } = vol;
    return volunteerWithoutAvailability;
  });

  return {
    session: {
      id: session.id,
      name: session.name,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
    },
    availableCount: result.length,
    volunteers: result,
  };
}

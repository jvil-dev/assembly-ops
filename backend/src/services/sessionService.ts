import { prisma } from "../config/database.js";

interface CreateSessionInput {
  name: string;
  date: Date;
  startTime: Date;
  endTime: Date;
  eventId: string;
}

interface UpdateSessionInput {
  name?: string;
  date?: Date;
  startTime?: Date;
  endTime?: Date;
}

export async function createSession(
  input: CreateSessionInput,
  adminId: string
) {
  const { name, date, startTime, endTime, eventId } = input;

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

  // Validate times
  if (endTime <= startTime) {
    throw new Error("INVALID_TIME_RANGE");
  }

  const session = await prisma.session.create({
    data: {
      name,
      date,
      startTime,
      endTime,
      eventId,
    },
  });

  return session;
}

export async function getSessionsByEvent(eventId: string, adminId: string) {
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

  const sessions = await prisma.session.findMany({
    where: { eventId },
    orderBy: [{ date: "asc" }, { startTime: "asc" }],
  });

  return sessions;
}

export async function getSessionById(
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

  const session = await prisma.session.findFirst({
    where: {
      id: sessionId,
      eventId,
    },
  });

  if (!session) {
    throw new Error("SESSION_NOT_FOUND");
  }

  return session;
}

export async function updateSession(
  sessionId: string,
  eventId: string,
  adminId: string,
  input: UpdateSessionInput
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

  // Verify session exists and belongs to event
  const existingSession = await prisma.session.findFirst({
    where: {
      id: sessionId,
      eventId,
    },
  });

  if (!existingSession) {
    throw new Error("SESSION_NOT_FOUND");
  }

  // If updating times, validate the range
  const newStartTime = input.startTime || existingSession.startTime;
  const newEndTime = input.endTime || existingSession.endTime;

  if (newEndTime <= newStartTime) {
    throw new Error("INVALID_TIME_RANGE");
  }

  // Build update data object, only including defined properties
  const updateData: {
    name?: string;
    date?: Date;
    startTime?: Date;
    endTime?: Date;
  } = {};

  if (input.name !== undefined) updateData.name = input.name;
  if (input.date !== undefined) updateData.date = input.date;
  if (input.startTime !== undefined) updateData.startTime = input.startTime;
  if (input.endTime !== undefined) updateData.endTime = input.endTime;

  const session = await prisma.session.update({
    where: { id: sessionId },
    data: updateData,
  });

  return session;
}

export async function deleteSession(
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

  // Verify session exists and belongs to event
  const existingSession = await prisma.session.findFirst({
    where: {
      id: sessionId,
      eventId,
    },
  });

  if (!existingSession) {
    throw new Error("SESSION_NOT_FOUND");
  }

  await prisma.session.delete({
    where: { id: sessionId },
  });

  return { deleted: true };
}

import { prisma } from "../config/database.js";
import { EventType } from "../generated/prisma/client.js";

interface CreateEventInput {
  name: string;
  type: EventType;
  location: string;
  startDate: Date;
  endDate: Date;
  createdById: string;
}

interface UpdateEventInput {
  name?: string;
  type?: EventType;
  location?: string;
  startDate?: Date;
  endDate?: Date;
}

export async function createEvent(input: CreateEventInput) {
  const { name, type, location, startDate, endDate, createdById } = input;

  const event = await prisma.event.create({
    data: {
      name,
      type,
      location,
      startDate,
      endDate,
      createdById,
    },
  });

  return event;
}

export async function getEventsByAdmin(adminId: string) {
  const events = await prisma.event.findMany({
    where: { createdById: adminId },
    orderBy: { startDate: "desc" },
  });

  return events;
}

export async function getEventById(eventId: string, adminId: string) {
  const event = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!event) {
    throw new Error("EVENT_NOT_FOUND");
  }

  return event;
}

export async function updateEvent(
  eventId: string,
  adminId: string,
  input: UpdateEventInput
) {
  const existing = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!existing) {
    throw new Error("EVENT_NOT_FOUND");
  }

  const event = await prisma.event.update({
    where: { id: eventId },
    data: input,
  });

  return event;
}

export async function deleteEvent(eventId: string, adminId: string) {
  const existing = await prisma.event.findFirst({
    where: {
      id: eventId,
      createdById: adminId,
    },
  });

  if (!existing) {
    throw new Error("EVENT_NOT_FOUND");
  }

  await prisma.event.delete({
    where: { id: eventId },
  });

  return { deleted: true };
}

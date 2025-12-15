import { prisma } from "../config/database.js";

interface CreateZoneInput {
  name: string;
  description?: string;
  requiredCount?: number;
  displayOrder?: number;
  eventId: string;
}

interface UpdateZoneInput {
  name?: string;
  description?: string | null;
  requiredCount?: number;
  displayOrder?: number;
}

export async function createZone(input: CreateZoneInput, adminId: string) {
  const { name, description, requiredCount, displayOrder, eventId } = input;

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

  // Check for duplicate zone name in this event
  const existingZone = await prisma.zone.findFirst({
    where: {
      eventId,
      name: { equals: name, mode: "insensitive" },
    },
  });

  if (existingZone) {
    throw new Error("ZONE_EXISTS");
  }

  // If no displayOrder provided, put it at the end
  let order = displayOrder;
  if (order === undefined) {
    const lastZone = await prisma.zone.findFirst({
      where: { eventId },
      orderBy: { displayOrder: "desc" },
    });
    order = lastZone ? lastZone.displayOrder + 1 : 0;
  }

  const zone = await prisma.zone.create({
    data: {
      name,
      description: description ?? null,
      requiredCount: requiredCount ?? 1,
      displayOrder: order,
      eventId,
    },
  });

  return zone;
}

export async function getZonesByEvent(eventId: string, adminId: string) {
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

  const zones = await prisma.zone.findMany({
    where: { eventId },
    orderBy: { displayOrder: "asc" },
  });

  return zones;
}

export async function getZoneById(
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

  const zone = await prisma.zone.findFirst({
    where: {
      id: zoneId,
      eventId,
    },
  });

  if (!zone) {
    throw new Error("ZONE_NOT_FOUND");
  }

  return zone;
}

export async function updateZone(
  zoneId: string,
  eventId: string,
  adminId: string,
  input: UpdateZoneInput
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

  // Verify zone exists and belongs to event
  const existingZone = await prisma.zone.findFirst({
    where: {
      id: zoneId,
      eventId,
    },
  });

  if (!existingZone) {
    throw new Error("ZONE_NOT_FOUND");
  }

  // If updating name, check for duplicates
  if (input.name && input.name !== existingZone.name) {
    const duplicateZone = await prisma.zone.findFirst({
      where: {
        eventId,
        name: { equals: input.name, mode: "insensitive" },
        id: { not: zoneId },
      },
    });

    if (duplicateZone) {
      throw new Error("ZONE_EXISTS");
    }
  }

  // Build update data object, only including defined properties
  const updateData: {
    name?: string;
    description?: string | null;
    requiredCount?: number;
    displayOrder?: number;
  } = {};

  if (input.name !== undefined) updateData.name = input.name;
  if (input.description !== undefined)
    updateData.description = input.description;
  if (input.requiredCount !== undefined)
    updateData.requiredCount = input.requiredCount;
  if (input.displayOrder !== undefined)
    updateData.displayOrder = input.displayOrder;

  const zone = await prisma.zone.update({
    where: { id: zoneId },
    data: updateData,
  });

  return zone;
}

export async function deleteZone(
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

  // Verify zone exists and belongs to event
  const existingZone = await prisma.zone.findFirst({
    where: {
      id: zoneId,
      eventId,
    },
  });

  if (!existingZone) {
    throw new Error("ZONE_NOT_FOUND");
  }

  await prisma.zone.delete({
    where: { id: zoneId },
  });

  return { deleted: true };
}

import { prisma } from "../config/database.js";

interface CreateRoleInput {
  name: string;
  displayOrder?: number;
  eventId: string;
}

interface UpdateRoleInput {
  name?: string;
  displayOrder?: number;
}

export async function createRole(input: CreateRoleInput, adminId: string) {
  const { name, displayOrder, eventId } = input;

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

  // Check for duplicate role name in this event
  const existingRole = await prisma.role.findFirst({
    where: {
      eventId,
      name: { equals: name, mode: "insensitive" },
    },
  });

  if (existingRole) {
    throw new Error("ROLE_EXISTS");
  }

  // If no displayOrder provided, put it at the end
  let order = displayOrder;
  if (order === undefined) {
    const lastRole = await prisma.role.findFirst({
      where: { eventId },
      orderBy: { displayOrder: "desc" },
    });
    order = lastRole ? lastRole.displayOrder + 1 : 0;
  }

  const role = await prisma.role.create({
    data: {
      name,
      displayOrder: order,
      eventId,
    },
  });

  return role;
}

export async function getRolesByEvent(eventId: string, adminId: string) {
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

  const roles = await prisma.role.findMany({
    where: { eventId },
    orderBy: { displayOrder: "asc" },
  });

  return roles;
}

export async function getRoleById(
  roleId: string,
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

  const role = await prisma.role.findFirst({
    where: {
      id: roleId,
      eventId,
    },
  });

  if (!role) {
    throw new Error("ROLE_NOT_FOUND");
  }

  return role;
}

export async function updateRole(
  roleId: string,
  eventId: string,
  adminId: string,
  input: UpdateRoleInput
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

  // Verify role exists and belongs to event
  const existingRole = await prisma.role.findFirst({
    where: {
      id: roleId,
      eventId,
    },
  });

  if (!existingRole) {
    throw new Error("ROLE_NOT_FOUND");
  }

  // If updating name, check for duplicates
  if (input.name && input.name !== existingRole.name) {
    const duplicateRole = await prisma.role.findFirst({
      where: {
        eventId,
        name: { equals: input.name, mode: "insensitive" },
        id: { not: roleId },
      },
    });

    if (duplicateRole) {
      throw new Error("ROLE_EXISTS");
    }
  }

  const role = await prisma.role.update({
    where: { id: roleId },
    data: input,
  });

  return role;
}

export async function deleteRole(
  roleId: string,
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

  // Verify role exists and belongs to event
  const existingRole = await prisma.role.findFirst({
    where: {
      id: roleId,
      eventId,
    },
    include: {
      volunteers: { select: { id: true } },
    },
  });

  if (!existingRole) {
    throw new Error("ROLE_NOT_FOUND");
  }

  // Check if role has volunteers assigned
  if (existingRole.volunteers.length > 0) {
    throw new Error("ROLE_HAS_VOLUNTEERS");
  }

  await prisma.role.delete({
    where: { id: roleId },
  });

  return { deleted: true };
}

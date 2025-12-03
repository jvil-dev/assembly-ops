import { prisma } from "../config/database.js";
import { generateCredentials } from "../utils/credentialUtils.js";
import { VolunteerAppointment } from "../generated/prisma/client.js";

const DEFAULT_APPOINTMENT = VolunteerAppointment.PUBLISHER;

interface CreateVolunteerInput {
  name: string;
  phone?: string;
  email?: string;
  congregation: string;
  appointment?: VolunteerAppointment;
  roleId?: string;
  eventId: string;
}

interface UpdateVolunteerInput {
  name?: string;
  phone?: string;
  email?: string;
  congregation?: string;
  appointment?: VolunteerAppointment;
  roleId?: string | null;
}

interface BulkCreateInput {
  volunteers: Array<{
    name: string;
    phone?: string;
    email?: string;
    congregation: string;
    appointment?: VolunteerAppointment;
    roleId?: string;
  }>;
  eventId: string;
}

interface GetVolunteersFilter {
  name?: string | undefined;
  roleId?: string | undefined;
  congregation?: string | undefined;
  appointment?: string | undefined;
  sort?: string | undefined;
  limit?: number | undefined;
  offset?: number | undefined;
}

export async function createVolunteer(
  input: CreateVolunteerInput,
  adminId: string
) {
  const { name, phone, email, congregation, appointment, roleId, eventId } =
    input;

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

  // If roleId provided, verify it belongs to this event
  if (roleId) {
    const role = await prisma.role.findFirst({
      where: {
        id: roleId,
        eventId,
      },
    });

    if (!role) {
      throw new Error("ROLE_NOT_FOUND");
    }
  }

  // Generate unique credentials
  let credentials = generateCredentials();
  let attempts = 0;
  const maxAttempts = 10;

  // Ensure generatedId is unique
  while (attempts < maxAttempts) {
    const existing = await prisma.volunteer.findUnique({
      where: { generatedId: credentials.generatedId },
    });

    if (!existing) break;

    credentials = generateCredentials();
    attempts++;
  }

  if (attempts >= maxAttempts) {
    throw new Error("CREDENTIAL_GENERATION_FAILED");
  }

  const volunteer = await prisma.volunteer.create({
    data: {
      name,
      phone: phone ?? null,
      email: email ?? null,
      congregation,
      appointment: appointment ?? DEFAULT_APPOINTMENT,
      roleId: roleId ?? null,
      eventId,
      generatedId: credentials.generatedId,
      loginToken: credentials.loginToken,
    },
    include: {
      role: true,
    },
  });

  return volunteer;
}

export async function bulkCreateVolunteers(
  input: BulkCreateInput,
  adminId: string
) {
  const { volunteers, eventId } = input;

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

  // Collect unique roleIds to validate
  const roleIds = [...new Set(volunteers.map((v) => v.roleId).filter(Boolean))];

  if (roleIds.length > 0) {
    const roles = await prisma.role.findMany({
      where: {
        id: { in: roleIds as string[] },
        eventId,
      },
    });

    if (roles.length !== roleIds.length) {
      throw new Error("ROLE_NOT_FOUND");
    }
  }

  // Generate credentials for all volunteers
  const volunteersWithCredentials = [];

  for (const vol of volunteers) {
    let credentials = generateCredentials();
    let attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      const existing = await prisma.volunteer.findUnique({
        where: { generatedId: credentials.generatedId },
      });

      if (!existing) break;

      credentials = generateCredentials();
      attempts++;
    }

    if (attempts >= maxAttempts) {
      throw new Error("CREDENTIAL_GENERATION_FAILED");
    }

    volunteersWithCredentials.push({
      name: vol.name,
      phone: vol.phone ?? null,
      email: vol.email ?? null,
      congregation: vol.congregation,
      appointment: vol.appointment ?? DEFAULT_APPOINTMENT,
      roleId: vol.roleId ?? null,
      eventId,
      generatedId: credentials.generatedId,
      loginToken: credentials.loginToken,
    });
  }

  // Bulk create
  await prisma.volunteer.createMany({
    data: volunteersWithCredentials,
  });

  // Fetch created volunteers with roles
  const createdVolunteers = await prisma.volunteer.findMany({
    where: {
      generatedId: {
        in: volunteersWithCredentials.map((v) => v.generatedId),
      },
    },
    include: {
      role: true,
    },
  });

  return createdVolunteers;
}

export async function getVolunteersByEvent(
  eventId: string,
  adminId: string,
  filters: GetVolunteersFilter = {}
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

  // Build where clause
  const where: Record<string, unknown> = { eventId };

  // Name search (partial, case-insensitive)
  if (filters.name) {
    where.name = {
      contains: filters.name,
      mode: "insensitive",
    };
  }

  // Role filter (exact match)
  if (filters.roleId) {
    where.roleId = filters.roleId;
  }

  // Congregation filter (partial, case-insensitive)
  if (filters.congregation) {
    where.congregation = {
      contains: filters.congregation,
      mode: "insensitive",
    };
  }

  // Appointment filter
  if (filters.appointment) {
    where.appointment = filters.appointment;
  }

  // Build orderBy clause
  let orderBy: Record<string, unknown>[] = [
    { role: { displayOrder: "asc" } },
    { name: "asc" },
  ];

  if (filters.sort) {
    switch (filters.sort) {
      case "name_asc":
        orderBy = [{ name: "asc" }];
        break;
      case "name_desc":
        orderBy = [{ name: "desc" }];
        break;
      case "role_asc":
        orderBy = [{ role: { displayOrder: "asc" } }, { name: "asc" }];
        break;
      default:
        // Keep default
        break;
    }
  }

  // Pagination
  const limit = Math.min(filters.limit || 50, 100);
  const offset = filters.offset || 0;

  // Get total count for pagination
  const total = await prisma.volunteer.count({ where });

  // Get volunteers
  const volunteers = await prisma.volunteer.findMany({
    where,
    include: {
      role: true,
    },
    orderBy,
    take: limit,
    skip: offset,
  });

  return {
    volunteers,
    pagination: {
      total,
      limit,
      offset,
      hasMore: offset + volunteers.length < total,
    },
  };
}

export async function getVolunteerById(
  volunteerId: string,
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

  const volunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
    include: {
      role: true,
    },
  });

  if (!volunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  return volunteer;
}

export async function updateVolunteer(
  volunteerId: string,
  eventId: string,
  adminId: string,
  input: UpdateVolunteerInput
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

  // Verify volunteer exists and belongs to event
  const existingVolunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
  });

  if (!existingVolunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // If updating roleId, verify the role belongs to this event
  if (input.roleId) {
    const role = await prisma.role.findFirst({
      where: {
        id: input.roleId,
        eventId,
      },
    });

    if (!role) {
      throw new Error("ROLE_NOT_FOUND");
    }
  }

  // Convert undefined to null for Prisma compatibility
  const updateData: any = {};
  if (input.name !== undefined) updateData.name = input.name;
  if (input.phone !== undefined) updateData.phone = input.phone ?? null;
  if (input.email !== undefined) updateData.email = input.email ?? null;
  if (input.congregation !== undefined)
    updateData.congregation = input.congregation;
  if (input.appointment !== undefined)
    updateData.appointment = input.appointment ?? DEFAULT_APPOINTMENT;
  if (input.roleId !== undefined) updateData.roleId = input.roleId ?? null;

  const volunteer = await prisma.volunteer.update({
    where: { id: volunteerId },
    data: updateData,
    include: {
      role: true,
    },
  });

  return volunteer;
}

export async function deleteVolunteer(
  volunteerId: string,
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

  // Verify volunteer exists and belongs to event
  const existingVolunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
  });

  if (!existingVolunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  await prisma.volunteer.delete({
    where: { id: volunteerId },
  });

  return { deleted: true };
}

export async function regenerateCredentials(
  volunteerId: string,
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

  // Verify volunteer exists
  const existingVolunteer = await prisma.volunteer.findFirst({
    where: {
      id: volunteerId,
      eventId,
    },
  });

  if (!existingVolunteer) {
    throw new Error("VOLUNTEER_NOT_FOUND");
  }

  // Generate new credentials
  let credentials = generateCredentials();
  let attempts = 0;
  const maxAttempts = 10;

  while (attempts < maxAttempts) {
    const existing = await prisma.volunteer.findUnique({
      where: { generatedId: credentials.generatedId },
    });

    if (!existing) break;

    credentials = generateCredentials();
    attempts++;
  }

  if (attempts >= maxAttempts) {
    throw new Error("CREDENTIAL_GENERATION_FAILED");
  }

  const volunteer = await prisma.volunteer.update({
    where: { id: volunteerId },
    data: {
      generatedId: credentials.generatedId,
      loginToken: credentials.loginToken,
    },
    include: {
      role: true,
    },
  });

  return volunteer;
}

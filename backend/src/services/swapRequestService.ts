import { prisma } from "../config/database.js";
import { SwapRequestStatus } from "../generated/prisma/client.js";

interface CreateSwapRequestInput {
  assignmentId: string;
  reason: string;
  suggestedVolunteerId?: string;
  eventId: string;
}

interface GetSwapRequestsFilter {
  status?: SwapRequestStatus | undefined;
}

export async function createSwapRequest(
  input: CreateSwapRequestInput,
  adminId: string
) {
  const { assignmentId, reason, suggestedVolunteerId, eventId } = input;

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
    include: {
      volunteer: true,
      session: true,
      zone: true,
    },
  });

  if (!assignment) {
    throw new Error("ASSIGNMENT_NOT_FOUND");
  }

  // Check if there's already a pending request for this assignment
  const existingRequest = await prisma.swapRequest.findFirst({
    where: {
      assignmentId,
      status: "PENDING",
    },
  });

  if (existingRequest) {
    throw new Error("PENDING_REQUEST_EXISTS");
  }

  // If suggested volunteer provided, verify they belong to this event
  if (suggestedVolunteerId) {
    const suggestedVolunteer = await prisma.volunteer.findFirst({
      where: {
        id: suggestedVolunteerId,
        eventId,
      },
    });

    if (!suggestedVolunteer) {
      throw new Error("SUGGESTED_VOLUNTEER_NOT_FOUND");
    }

    // Check if suggested volunteer is available for this session
    const availability = await prisma.volunteerAvailability.findUnique({
      where: {
        volunteerId_sessionId: {
          volunteerId: suggestedVolunteerId,
          sessionId: assignment.sessionId,
        },
      },
    });

    if (availability && !availability.isAvailable) {
      throw new Error("SUGGESTED_VOLUNTEER_UNAVAILABLE");
    }

    // Check if suggested volunteer is already assigned to this session
    const existingAssignment = await prisma.assignment.findUnique({
      where: {
        volunteerId_sessionId: {
          volunteerId: suggestedVolunteerId,
          sessionId: assignment.sessionId,
        },
      },
    });

    if (existingAssignment) {
      throw new Error("SUGGESTED_VOLUNTEER_ALREADY_ASSIGNED");
    }
  }

  const swapRequest = await prisma.swapRequest.create({
    data: {
      reason,
      assignmentId,
      suggestedVolunteerId: suggestedVolunteerId ?? null,
    },
    include: {
      assignment: {
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
            },
          },
        },
      },
      suggestedVolunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
        },
      },
    },
  });

  return swapRequest;
}

export async function getSwapRequestsByEvent(
  eventId: string,
  adminId: string,
  filters: GetSwapRequestsFilter = {}
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
  const where: Record<string, unknown> = {
    assignment: {
      session: { eventId },
    },
  };

  if (filters.status) {
    where.status = filters.status;
  }

  const swapRequests = await prisma.swapRequest.findMany({
    where,
    include: {
      assignment: {
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
            },
          },
        },
      },
      suggestedVolunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
        },
      },
      resolvedBy: {
        select: {
          id: true,
          name: true,
        },
      },
    },
    orderBy: [
      { status: "asc" }, // PENDING first (alphabetically before APPROVED/DENIED)
      { createdAt: "desc" },
    ],
  });

  return swapRequests;
}

export async function getSwapRequestById(
  requestId: string,
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

  const swapRequest = await prisma.swapRequest.findFirst({
    where: {
      id: requestId,
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
            },
          },
        },
      },
      suggestedVolunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
        },
      },
      resolvedBy: {
        select: {
          id: true,
          name: true,
        },
      },
    },
  });

  if (!swapRequest) {
    throw new Error("SWAP_REQUEST_NOT_FOUND");
  }

  return swapRequest;
}

export async function approveSwapRequest(
  requestId: string,
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

  // Get the swap request
  const swapRequest = await prisma.swapRequest.findFirst({
    where: {
      id: requestId,
      assignment: {
        session: { eventId },
      },
    },
    include: {
      assignment: true,
    },
  });

  if (!swapRequest) {
    throw new Error("SWAP_REQUEST_NOT_FOUND");
  }

  if (swapRequest.status !== "PENDING") {
    throw new Error("REQUEST_ALREADY_RESOLVED");
  }

  // Use transaction to update request and delete assignment
  const result = await prisma.$transaction(async (tx) => {
    // Update swap request status
    const updatedRequest = await tx.swapRequest.update({
      where: { id: requestId },
      data: {
        status: "APPROVED",
        resolvedById: adminId,
        resolvedAt: new Date(),
      },
      include: {
        assignment: {
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
              },
            },
          },
        },
        suggestedVolunteer: {
          select: {
            id: true,
            name: true,
            phone: true,
            congregation: true,
          },
        },
        resolvedBy: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    // Delete the original assignment
    await tx.assignment.delete({
      where: { id: swapRequest.assignmentId },
    });

    return updatedRequest;
  });

  return result;
}

export async function denySwapRequest(
  requestId: string,
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

  // Get the swap request
  const swapRequest = await prisma.swapRequest.findFirst({
    where: {
      id: requestId,
      assignment: {
        session: { eventId },
      },
    },
  });

  if (!swapRequest) {
    throw new Error("SWAP_REQUEST_NOT_FOUND");
  }

  if (swapRequest.status !== "PENDING") {
    throw new Error("REQUEST_ALREADY_RESOLVED");
  }

  const updatedRequest = await prisma.swapRequest.update({
    where: { id: requestId },
    data: {
      status: "DENIED",
      resolvedById: adminId,
      resolvedAt: new Date(),
    },
    include: {
      assignment: {
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
            },
          },
        },
      },
      suggestedVolunteer: {
        select: {
          id: true,
          name: true,
          phone: true,
          congregation: true,
        },
      },
      resolvedBy: {
        select: {
          id: true,
          name: true,
        },
      },
    },
  });

  return updatedRequest;
}

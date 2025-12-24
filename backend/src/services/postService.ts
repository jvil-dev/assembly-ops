import { prisma } from "../config/database.js";

interface CreatePostInput {
  name: string;
  description?: string;
  capacity?: number;
  displayOrder?: number;
  departmentId: string;
  isActive?: boolean;
  eventId: string;
}

interface UpdatePostInput {
  name?: string;
  description?: string | null;
  capacity?: number;
  displayOrder?: number;
  departmentId?: string;
  isActive?: boolean;
}

export async function createPost(input: CreatePostInput, adminId: string) {
  const {
    name,
    description,
    capacity,
    displayOrder,
    departmentId,
    isActive,
    eventId,
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

  // Verify department exists and belongs to event
  const department = await prisma.department.findFirst({
    where: {
      id: departmentId,
      eventId,
    },
  });

  if (!department) {
    throw new Error("DEPARTMENT_NOT_FOUND");
  }

  // Check for duplicate post name in this department
  const existingPost = await prisma.post.findFirst({
    where: {
      departmentId,
      name: { equals: name, mode: "insensitive" },
    },
  });

  if (existingPost) {
    throw new Error("POST_EXISTS");
  }

  // If no displayOrder provided, put it at the end
  let order = displayOrder;
  if (order === undefined) {
    const lastPost = await prisma.post.findFirst({
      where: { departmentId },
      orderBy: { displayOrder: "desc" },
    });
    order = lastPost ? lastPost.displayOrder + 1 : 0;
  }

  const post = await prisma.post.create({
    data: {
      name,
      description: description ?? null,
      capacity: capacity ?? 1,
      displayOrder: order,
      isActive: isActive ?? true,
      eventId,
      departmentId,
    },
    include: {
      department: true,
    },
  });

  return post;
}

export async function getPostsByEvent(
  eventId: string,
  adminId: string,
  departmentId?: string
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

  const whereClause: { eventId: string; departmentId?: string } = { eventId };

  if (departmentId) {
    whereClause.departmentId = departmentId;
  }

  const posts = await prisma.post.findMany({
    where: whereClause,
    orderBy: [{ department: { displayOrder: "asc" } }, { displayOrder: "asc" }],
    include: {
      department: true,
    },
  });

  return posts;
}

export async function getPostById(
  postId: string,
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

  const post = await prisma.post.findFirst({
    where: {
      id: postId,
      eventId,
    },
    include: {
      department: true,
      scheduleAssignments: {
        include: {
          volunteer: true,
          session: true,
        },
      },
    },
  });

  if (!post) {
    throw new Error("POST_NOT_FOUND");
  }

  return post;
}

export async function updatePost(
  postId: string,
  eventId: string,
  adminId: string,
  input: UpdatePostInput
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

  // Verify post exists and belongs to event
  const existingPost = await prisma.post.findFirst({
    where: {
      id: postId,
      eventId,
    },
  });

  if (!existingPost) {
    throw new Error("POST_NOT_FOUND");
  }

  // If updating departmentId, verify department exists
  if (input.departmentId && input.departmentId !== existingPost.departmentId) {
    const department = await prisma.department.findFirst({
      where: {
        id: input.departmentId,
        eventId,
      },
    });

    if (!department) {
      throw new Error("DEPARTMENT_NOT_FOUND");
    }
  }

  // If updating name, check for duplicates in the target department
  const targetDepartmentId = input.departmentId || existingPost.departmentId;
  if (input.name && input.name !== existingPost.name) {
    const duplicatePost = await prisma.post.findFirst({
      where: {
        departmentId: targetDepartmentId,
        name: { equals: input.name, mode: "insensitive" },
        id: { not: postId },
      },
    });

    if (duplicatePost) {
      throw new Error("POST_EXISTS");
    }
  }

  // Build update data object
  const updateData: {
    name?: string;
    description?: string | null;
    capacity?: number;
    displayOrder?: number;
    departmentId?: string;
    isActive?: boolean;
  } = {};

  if (input.name !== undefined) updateData.name = input.name;
  if (input.description !== undefined)
    updateData.description = input.description;
  if (input.capacity !== undefined) updateData.capacity = input.capacity;
  if (input.displayOrder !== undefined)
    updateData.displayOrder = input.displayOrder;
  if (input.departmentId !== undefined)
    updateData.departmentId = input.departmentId;
  if (input.isActive !== undefined) updateData.isActive = input.isActive;

  const post = await prisma.post.update({
    where: { id: postId },
    data: updateData,
    include: {
      department: true,
    },
  });

  return post;
}

export async function deletePost(
  postId: string,
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

  // Verify post exists and belongs to event
  const existingPost = await prisma.post.findFirst({
    where: {
      id: postId,
      eventId,
    },
  });

  if (!existingPost) {
    throw new Error("POST_NOT_FOUND");
  }

  await prisma.post.delete({
    where: { id: postId },
  });

  return { deleted: true };
}

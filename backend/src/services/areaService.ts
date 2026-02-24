/**
 * Area Service
 *
 * Business logic for area management: CRUD operations for areas,
 * captain assignment per area+session, and area group queries.
 *
 * Areas group posts within a department (Attendant dept initially).
 * Each area can have one captain per session (enforced by DB unique constraint).
 *
 * Methods:
 *   CRUD:
 *     - createArea(departmentId, input): Create a new area in a department
 *     - updateArea(areaId, input): Update area name/description/sortOrder
 *     - deleteArea(areaId): Delete an area (posts remain, areaId set to null)
 *     - getArea(areaId): Get single area with posts and captains
 *     - getDepartmentAreas(departmentId): Get all areas for a department
 *
 *   Post Assignment:
 *     - assignPostToArea(postId, areaId): Link a post to an area
 *     - removePostFromArea(postId): Unlink a post from its area
 *
 *   Captain Management:
 *     - setAreaCaptain(input): Assign a captain to area+session (upsert)
 *     - removeAreaCaptain(areaId, sessionId): Remove captain from area+session
 *
 *   Group Queries:
 *     - getAreaGroup(areaId, sessionId): Get captain + all members in area for session
 *     - getMyAreaGroups(eventVolunteerId): Get all area groups where volunteer is captain
 *
 *   Access Control Helpers:
 *     - getAreaEventId(areaId): Get eventId for authorization checks
 *
 * Used by: ../graphql/resolvers/area.ts
 */
import { PrismaClient } from '@prisma/client';
import {
  createAreaSchema,
  updateAreaSchema,
  setAreaCaptainSchema,
  removeAreaCaptainSchema,
  type CreateAreaInput,
  type UpdateAreaInput,
  type SetAreaCaptainInput,
  type RemoveAreaCaptainInput,
} from '../graphql/validators/area.js';
import {
  NotFoundError,
  ValidationError,
  ConflictError,
} from '../utils/errors.js';

export class AreaService {
  constructor(private prisma: PrismaClient) {}

  // MARK: - CRUD

  async createArea(departmentId: string, input: CreateAreaInput) {
    const result = createAreaSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    // Verify department exists
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
    });
    if (!department) {
      throw new NotFoundError('Department');
    }

    // Check for duplicate name in department+category
    const existing = await this.prisma.area.findUnique({
      where: {
        departmentId_category_name: {
          departmentId,
          category: result.data.category ?? '',
          name: result.data.name,
        },
      },
    });
    if (existing) {
      throw new ConflictError(
        `An area named "${result.data.name}" already exists in this department`
      );
    }

    return this.prisma.area.create({
      data: {
        ...result.data,
        departmentId,
      },
      include: {
        department: true,
        posts: { orderBy: { sortOrder: 'asc' } },
        captains: {
          include: {
            session: true,
            eventVolunteer: { include: { volunteerProfile: true } },
          },
        },
      },
    });
  }

  async updateArea(areaId: string, input: UpdateAreaInput) {
    const result = updateAreaSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const area = await this.prisma.area.findUnique({
      where: { id: areaId },
    });
    if (!area) {
      throw new NotFoundError('Area');
    }

    // Check for duplicate name if name or category is being changed
    const newName = result.data.name ?? area.name;
    const newCategory = result.data.category !== undefined ? result.data.category : area.category;
    if (newName !== area.name || newCategory !== area.category) {
      const existing = await this.prisma.area.findUnique({
        where: {
          departmentId_category_name: {
            departmentId: area.departmentId,
            category: newCategory ?? '',
            name: newName,
          },
        },
      });
      if (existing && existing.id !== areaId) {
        throw new ConflictError(
          `An area named "${newName}" already exists in this department`
        );
      }
    }

    return this.prisma.area.update({
      where: { id: areaId },
      data: result.data,
      include: {
        department: true,
        posts: { orderBy: { sortOrder: 'asc' } },
        captains: {
          include: {
            session: true,
            eventVolunteer: { include: { volunteerProfile: true } },
          },
        },
      },
    });
  }

  async deleteArea(areaId: string) {
    const area = await this.prisma.area.findUnique({
      where: { id: areaId },
    });
    if (!area) {
      throw new NotFoundError('Area');
    }

    await this.prisma.area.delete({ where: { id: areaId } });
    return true;
  }

  async getArea(areaId: string) {
    const area = await this.prisma.area.findUnique({
      where: { id: areaId },
      include: {
        department: true,
        posts: { orderBy: { sortOrder: 'asc' } },
        captains: {
          include: {
            session: true,
            eventVolunteer: { include: { volunteerProfile: true } },
          },
        },
        _count: { select: { posts: true } },
      },
    });
    if (!area) {
      throw new NotFoundError('Area');
    }
    return area;
  }

  async getDepartmentAreas(departmentId: string) {
    return this.prisma.area.findMany({
      where: { departmentId },
      orderBy: { sortOrder: 'asc' },
      include: {
        department: true,
        posts: { orderBy: { sortOrder: 'asc' } },
        captains: {
          include: {
            session: true,
            eventVolunteer: { include: { volunteerProfile: true } },
          },
        },
        _count: { select: { posts: true } },
      },
    });
  }

  // MARK: - Post Assignment

  async assignPostToArea(postId: string, areaId: string) {
    const [post, area] = await Promise.all([
      this.prisma.post.findUnique({ where: { id: postId } }),
      this.prisma.area.findUnique({ where: { id: areaId } }),
    ]);

    if (!post) throw new NotFoundError('Post');
    if (!area) throw new NotFoundError('Area');

    // Ensure post and area belong to the same department
    if (post.departmentId !== area.departmentId) {
      throw new ValidationError(
        'Post and area must belong to the same department'
      );
    }

    // Auto-derive Post.category from Area.category
    const derivedCategory = area.category ?? post.category;

    return this.prisma.post.update({
      where: { id: postId },
      data: { areaId, category: derivedCategory },
      include: {
        area: true,
        department: true,
      },
    });
  }

  async removePostFromArea(postId: string) {
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
    });
    if (!post) throw new NotFoundError('Post');

    return this.prisma.post.update({
      where: { id: postId },
      data: { areaId: null },
      include: {
        area: true,
        department: true,
      },
    });
  }

  // MARK: - Captain Management

  async setAreaCaptain(input: SetAreaCaptainInput) {
    const result = setAreaCaptainSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { areaId, sessionId, eventVolunteerId } = result.data;

    // Verify area and session exist
    const [area, session] = await Promise.all([
      this.prisma.area.findUnique({
        where: { id: areaId },
        include: { department: true },
      }),
      this.prisma.session.findUnique({ where: { id: sessionId } }),
    ]);

    if (!area) throw new NotFoundError('Area');
    if (!session) throw new NotFoundError('Session');

    // Try to find EventVolunteer directly first, then fall back to legacy Volunteer lookup
    let resolvedEventVolunteerId = eventVolunteerId;
    let volunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: eventVolunteerId },
    });

    if (!volunteer) {
      // Try looking up via legacy Volunteer model → find matching EventVolunteer
      const legacyVolunteer = await this.prisma.volunteer.findUnique({
        where: { id: eventVolunteerId },
      });
      if (legacyVolunteer) {
        const ev = await this.prisma.eventVolunteer.findFirst({
          where: {
            volunteerId: legacyVolunteer.volunteerId,
            eventId: area.department.eventId,
          },
        });
        if (ev) {
          volunteer = ev;
          resolvedEventVolunteerId = ev.id;
        }
      }
    }

    if (!volunteer) throw new NotFoundError('EventVolunteer');

    // Upsert: replace existing captain or create new
    return this.prisma.areaCaptain.upsert({
      where: {
        areaId_sessionId: { areaId, sessionId },
      },
      create: {
        areaId,
        sessionId,
        eventVolunteerId: resolvedEventVolunteerId,
      },
      update: {
        eventVolunteerId: resolvedEventVolunteerId,
      },
      include: {
        area: true,
        session: true,
        eventVolunteer: { include: { volunteerProfile: true } },
      },
    });
  }

  async removeAreaCaptain(input: RemoveAreaCaptainInput) {
    const result = removeAreaCaptainSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { areaId, sessionId } = result.data;

    const existing = await this.prisma.areaCaptain.findUnique({
      where: {
        areaId_sessionId: { areaId, sessionId },
      },
    });

    if (!existing) {
      throw new NotFoundError('AreaCaptain');
    }

    await this.prisma.areaCaptain.delete({
      where: {
        areaId_sessionId: { areaId, sessionId },
      },
    });

    return true;
  }

  // MARK: - Group Queries

  async getAreaGroup(areaId: string, sessionId: string) {
    const area = await this.prisma.area.findUnique({
      where: { id: areaId },
      include: {
        posts: { orderBy: { sortOrder: 'asc' } },
      },
    });
    if (!area) throw new NotFoundError('Area');

    // Get captain for this area+session
    const captain = await this.prisma.areaCaptain.findUnique({
      where: {
        areaId_sessionId: { areaId, sessionId },
      },
      include: {
        area: true,
        session: true,
        eventVolunteer: { include: { volunteerProfile: true } },
      },
    });

    // Get all assignments for posts in this area for this session
    const postIds = area.posts.map((p) => p.id);
    const assignments = await this.prisma.scheduleAssignment.findMany({
      where: {
        postId: { in: postIds },
        sessionId,
      },
      include: {
        post: true,
        session: true,
        volunteer: true,
        eventVolunteer: { include: { volunteerProfile: true } },
        checkIn: true,
      },
      orderBy: [{ post: { sortOrder: 'asc' } }, { createdAt: 'asc' }],
    });

    return {
      area,
      captain,
      members: assignments.map((assignment) => ({
        assignment,
        postName: assignment.post.name,
        postId: assignment.post.id,
      })),
    };
  }

  async getMyAreaGroups(eventVolunteerId: string) {
    // Find all areas where this volunteer is captain
    const captainAssignments = await this.prisma.areaCaptain.findMany({
      where: { eventVolunteerId },
      include: {
        area: {
          include: {
            posts: { orderBy: { sortOrder: 'asc' } },
          },
        },
        session: true,
        eventVolunteer: { include: { volunteerProfile: true } },
      },
      orderBy: [{ session: { date: 'asc' } }, { session: { startTime: 'asc' } }],
    });

    // For each captain assignment, load the group members
    const groups = await Promise.all(
      captainAssignments.map(async (captainAssignment) => {
        const postIds = captainAssignment.area.posts.map((p) => p.id);

        const assignments = await this.prisma.scheduleAssignment.findMany({
          where: {
            postId: { in: postIds },
            sessionId: captainAssignment.sessionId,
          },
          include: {
            post: true,
            session: true,
            volunteer: true,
            eventVolunteer: { include: { volunteerProfile: true } },
            checkIn: true,
          },
          orderBy: [{ post: { sortOrder: 'asc' } }, { createdAt: 'asc' }],
        });

        return {
          area: captainAssignment.area,
          captain: captainAssignment,
          members: assignments.map((assignment) => ({
            assignment,
            postName: assignment.post.name,
            postId: assignment.post.id,
          })),
        };
      })
    );

    return groups;
  }

  // MARK: - Access Control Helpers

  async getAreaEventId(areaId: string): Promise<string> {
    const area = await this.prisma.area.findUnique({
      where: { id: areaId },
      include: {
        department: {
          select: { eventId: true },
        },
      },
    });
    if (!area) throw new NotFoundError('Area');
    return area.department.eventId;
  }

  async getPostEventId(postId: string): Promise<string> {
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      include: {
        department: {
          select: { eventId: true },
        },
      },
    });
    if (!post) throw new NotFoundError('Post');
    return post.department.eventId;
  }
}

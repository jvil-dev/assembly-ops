/**
 * Event Service
 *
 * Business logic for event management: templates, department purchasing, hierarchy.
 *
 * Methods:
 *   - getEventTemplates(serviceYear?): Get available event templates
 *   - purchaseDepartment(input, userId): Purchase a department in an event (creates EventAdmin + Department + access code)
 *   - joinDepartmentByAccessCode(code, userId): Volunteer joins a department via access code
 *   - getDepartmentInfo(departmentId): Get department with overseer, hierarchy, event info
 *   - setDepartmentPrivacy(departmentId, isPublic, userId): Toggle department privacy
 *   - assignHierarchyRole(departmentId, eventVolunteerId, role, userId): Assign hierarchy role
 *   - removeHierarchyRole(departmentId, eventVolunteerId, userId): Remove hierarchy role
 *   - getMyEvents(userId): Get all events this user is part of (overseer view)
 *   - getMyAllEvents(userId): Get all events this user is part of (all roles)
 *   - getEvent(eventId): Get single event with all related data
 *   - getEventDepartments(eventId): Get departments for an event
 *   - getEventAdmins(eventId): Get all overseers for an event
 *
 * Department Purchase Flow:
 *   1. Events are pre-created (seeded or via admin panel)
 *   2. Overseer discovers event via discoverEvents query
 *   3. Overseer calls purchaseDepartment() → creates EventAdmin + Department + access code
 *   4. Volunteers join via access code (joinDepartmentByAccessCode) or overseer invitation
 *
 * Access Code Format:
 *   {3-CHAR-PREFIX}-{4-CHAR-RANDOM} e.g. "ATT-7X9K"
 *   Prefix auto-assigned from department type.
 *   Character set excludes ambiguous chars (O, 0, I, 1).
 *
 * Called by: ../graphql/resolvers/event.ts
 */
import { PrismaClient, EventRole, DepartmentType, HierarchyRole } from '@prisma/client';
import {
  NotFoundError,
  ConflictError,
  ValidationError,
  AuthorizationError,
} from '../utils/errors.js';
import { timeStringToDate } from '../utils/time.js';
import {
  purchaseDepartmentSchema,
  joinDepartmentByCodeSchema,
  assignHierarchyRoleSchema,
  PurchaseDepartmentInput,
  JoinDepartmentByCodeInput,
  AssignHierarchyRoleInput,
} from '../graphql/validators/event.js';

// Department display names
const DEPARTMENT_NAMES: Record<DepartmentType, string> = {
  ACCOUNTS: 'Accounts',
  ATTENDANT: 'Attendant',
  AUDIO: 'Audio',
  BAPTISM: 'Baptism',
  CLEANING: 'Cleaning',
  FIRST_AID: 'First Aid',
  INFORMATION_VOLUNTEER_SERVICE: 'Information & Volunteer Service',
  INSTALLATION: 'Installation',
  LOST_FOUND_CHECKROOM: 'Lost & Found / Checkroom',
  PARKING: 'Parking',
  ROOMING: 'Rooming',
  STAGE: 'Stage',
  TRUCKING_EQUIPMENT: 'Trucking & Equipment',
  VIDEO: 'Video',
};

// 3-char prefixes for access code generation
const DEPARTMENT_ACCESS_CODE_PREFIX: Record<DepartmentType, string> = {
  ACCOUNTS: 'ACC',
  ATTENDANT: 'ATT',
  AUDIO: 'AUD',
  BAPTISM: 'BAP',
  CLEANING: 'CLN',
  FIRST_AID: 'AID',
  INFORMATION_VOLUNTEER_SERVICE: 'IVS',
  INSTALLATION: 'INS',
  LOST_FOUND_CHECKROOM: 'LFC',
  PARKING: 'PRK',
  ROOMING: 'ROM',
  STAGE: 'STG',
  TRUCKING_EQUIPMENT: 'TRK',
  VIDEO: 'VID',
};

// Default posts auto-seeded when a department is purchased (CO-160 positions).
// Each entry: { name, description?, category?, sortOrder }
const DEPARTMENT_DEFAULT_POSTS: Partial<
  Record<
    DepartmentType,
    Array<{
      name: string;
      description?: string;
      category?: string;
      sortOrder: number;
    }>
  >
> = {
  AUDIO: [
    {
      name: 'Mixer Operator',
      description: 'Operates the mixing console during sessions',
      category: 'Audio',
      sortOrder: 0,
    },
    {
      name: 'Mixer Operator Assistant',
      description: 'Assists the mixer operator and monitors audio levels',
      category: 'Audio',
      sortOrder: 1,
    },
  ],
  VIDEO: [
    {
      name: 'Technical Director',
      description: 'Directs all video operations during sessions',
      category: 'Video',
      sortOrder: 0,
    },
    {
      name: 'Switcher Operator',
      description: 'Switches between camera feeds and media sources',
      category: 'Video',
      sortOrder: 1,
    },
    {
      name: 'Media Operator',
      description: 'Controls media playback and presentation slides',
      category: 'Video',
      sortOrder: 2,
    },
    {
      name: 'PTZ Camera Operator',
      description: 'Remotely controls all PTZ cameras from the video desk',
      category: 'Video',
      sortOrder: 3,
    },
    {
      name: 'Manned Camera Operator',
      description: 'Operates manned cameras near the stage for close-up coverage',
      category: 'Video',
      sortOrder: 4,
    },
  ],
  STAGE: [
    {
      name: 'Microphone Adjuster',
      description: 'Adjusts microphone positions for each speaker',
      category: 'Stage',
      sortOrder: 0,
    },
    {
      name: 'Participant Reminder',
      description: 'Gives Appendix F reminders to participants before going on stage',
      category: 'Stage',
      sortOrder: 1,
    },
    {
      name: 'Stage Configuration',
      description: 'Marks floor positions, manages furniture placement and entry/exit sides',
      category: 'Stage',
      sortOrder: 2,
    },
    {
      name: 'Makeup',
      description: 'Applies makeup for speakers appearing on video',
      category: 'Stage',
      sortOrder: 3,
    },
  ],
};

// Characters for access code shortcode (excludes ambiguous: O, 0, I, 1)
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function generateShortcode(length: number): string {
  let code = '';
  for (let i = 0; i < length; i++) {
    code += CODE_CHARS.charAt(Math.floor(Math.random() * CODE_CHARS.length));
  }
  return code;
}

export class EventService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Generate a unique access code for a department.
   * Format: {PREFIX}-{4-char alphanumeric} e.g. "ATT-7X9K"
   */
  private async generateUniqueAccessCode(departmentType: DepartmentType): Promise<string> {
    const prefix = DEPARTMENT_ACCESS_CODE_PREFIX[departmentType];
    let attempts = 0;
    while (attempts < 10) {
      const code = `${prefix}-${generateShortcode(4)}`;
      const existing = await this.prisma.department.findUnique({
        where: { accessCode: code },
      });
      if (!existing) return code;
      attempts++;
    }
    throw new Error('Could not generate unique access code after 10 attempts');
  }

  /**
   * Purchase a department in an event.
   *
   * Creates EventAdmin (if needed) + Department + access code in one step.
   * If the user has no EventAdmin for this event, one is created.
   * If the user already has a department in this event, throws conflict.
   */
  async purchaseDepartment(input: PurchaseDepartmentInput, userId: string) {
    const result = purchaseDepartmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, departmentType } = result.data;

    // Verify event exists
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    // Check if department type already claimed in this event
    const existingDepartment = await this.prisma.department.findUnique({
      where: {
        eventId_departmentType: {
          eventId,
          departmentType,
        },
      },
      include: { overseer: { include: { user: true } } },
    });

    if (existingDepartment) {
      const overseerName = existingDepartment.overseer
        ? `${existingDepartment.overseer.user.firstName} ${existingDepartment.overseer.user.lastName}`
        : 'Unknown';
      throw new ConflictError(
        `${DEPARTMENT_NAMES[departmentType]} is already claimed by ${overseerName}`
      );
    }

    // Get or create EventAdmin for this user + event
    let eventAdmin = await this.prisma.eventAdmin.findUnique({
      where: {
        userId_eventId: {
          userId,
          eventId,
        },
      },
    });

    if (eventAdmin && eventAdmin.departmentId) {
      throw new ConflictError('You have already purchased a department in this event');
    }

    if (!eventAdmin) {
      eventAdmin = await this.prisma.eventAdmin.create({
        data: {
          userId,
          eventId,
          role: EventRole.DEPARTMENT_OVERSEER,
        },
      });
    }

    // Generate access code
    const accessCode = await this.generateUniqueAccessCode(departmentType);

    // Create department
    const department = await this.prisma.department.create({
      data: {
        name: DEPARTMENT_NAMES[departmentType],
        departmentType,
        eventId,
        accessCode,
        isPublic: true,
      },
    });

    // Link department to EventAdmin
    await this.prisma.eventAdmin.update({
      where: { id: eventAdmin.id },
      data: {
        departmentId: department.id,
        role: EventRole.DEPARTMENT_OVERSEER,
      },
    });

    // Auto-seed required posts for department types that have defaults (CO-160)
    const defaultPosts = DEPARTMENT_DEFAULT_POSTS[departmentType];
    if (defaultPosts && defaultPosts.length > 0) {
      await this.prisma.post.createMany({
        data: defaultPosts.map((p) => ({
          name: p.name,
          description: p.description,
          category: p.category,
          sortOrder: p.sortOrder,
          departmentId: department.id,
        })),
      });
    }

    // Auto-create default sessions if this is the first department (no sessions yet)
    const sessionCount = await this.prisma.session.count({ where: { eventId } });
    if (sessionCount === 0) {
      const dayCount =
        Math.round((event.endDate.getTime() - event.startDate.getTime()) / (1000 * 60 * 60 * 24)) +
        1;

      for (let d = 0; d < dayCount; d++) {
        const date = new Date(event.startDate);
        date.setDate(date.getDate() + d);

        await this.prisma.session.create({
          data: {
            name: 'Morning',
            date,
            startTime: timeStringToDate('09:20'),
            endTime: timeStringToDate('12:00'),
            eventId,
          },
        });

        await this.prisma.session.create({
          data: {
            name: 'Afternoon',
            date,
            startTime: timeStringToDate('13:30'),
            endTime: timeStringToDate('16:00'),
            eventId,
          },
        });
      }

      // Seed standard department roles (CO-1 hierarchy)
      const defaultRoles = [
        { name: 'Volunteer', description: 'General department volunteer', sortOrder: 0 },
        {
          name: 'Captain',
          description: 'Leads volunteers during a session or shift',
          sortOrder: 1,
        },
        { name: 'Keyman', description: 'Supervises a specific area or function', sortOrder: 2 },
        {
          name: 'Assistant Overseer',
          description: 'Assists the department overseer',
          sortOrder: 3,
        },
      ];
      await Promise.all(
        defaultRoles.map((r) => this.prisma.role.create({ data: { ...r, eventId } }))
      );
    }

    return this.prisma.department.findUnique({
      where: { id: department.id },
      include: {
        overseer: {
          include: { user: true },
        },
        event: true,
      },
    });
  }

  /**
   * Join a department by access code (volunteer flow).
   * Finds the department by access code, creates EventVolunteer immediately.
   * No approval needed — the access code is the authorization.
   */
  async joinDepartmentByAccessCode(input: JoinDepartmentByCodeInput, userId: string) {
    const result = joinDepartmentByCodeSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { accessCode } = result.data;

    // Find department by access code (case-insensitive)
    const department = await this.prisma.department.findFirst({
      where: {
        accessCode: {
          equals: accessCode.toUpperCase(),
          mode: 'insensitive',
        },
      },
      include: {
        event: true,
      },
    });

    if (!department) {
      throw new NotFoundError('No department found with this access code');
    }

    // Check if user already has an EventVolunteer for this event
    const existing = await this.prisma.eventVolunteer.findUnique({
      where: {
        userId_eventId: {
          userId,
          eventId: department.eventId,
        },
      },
    });

    if (existing) {
      throw new ConflictError('You are already a volunteer for this event');
    }

    // Create EventVolunteer membership record
    const eventVolunteer = await this.prisma.eventVolunteer.create({
      data: {
        userId,
        eventId: department.eventId,
        departmentId: department.id,
      },
      include: {
        user: true,
        event: true,
      },
    });

    return eventVolunteer;
  }

  /**
   * Get detailed department info including hierarchy and event data.
   */
  async getDepartmentInfo(departmentId: string) {
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      include: {
        overseer: {
          include: { user: true },
        },
        hierarchyRoles: {
          include: {
            eventVolunteer: {
              include: { user: true },
            },
          },
          orderBy: { assignedAt: 'asc' },
        },
        event: true,
        _count: {
          select: { eventVolunteers: true, posts: true },
        },
      },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    return department;
  }

  /**
   * Toggle department privacy (public/private).
   * Only the department overseer can change this.
   */
  async setDepartmentPrivacy(departmentId: string, isPublic: boolean, userId: string) {
    // Verify caller is the department overseer
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      include: { overseer: true },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    if (!department.overseer || department.overseer.userId !== userId) {
      throw new AuthorizationError('Only the department overseer can change privacy settings');
    }

    return this.prisma.department.update({
      where: { id: departmentId },
      data: { isPublic },
      include: {
        overseer: { include: { user: true } },
      },
    });
  }

  /**
   * Assign a hierarchy role (e.g. ASSISTANT_OVERSEER) to a volunteer.
   * Only the department overseer can do this.
   */
  async assignHierarchyRole(input: AssignHierarchyRoleInput, userId: string) {
    const result = assignHierarchyRoleSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { departmentId, eventVolunteerId, hierarchyRole } = result.data;

    // Verify caller is the department overseer
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      include: { overseer: true },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    if (!department.overseer || department.overseer.userId !== userId) {
      throw new AuthorizationError('Only the department overseer can assign hierarchy roles');
    }

    // Resolve eventVolunteerId — try direct lookup first, then by human-readable userId
    let eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: eventVolunteerId },
    });

    if (!eventVolunteer) {
      // Try resolving as human-readable User.userId
      const user = await this.prisma.user.findUnique({
        where: { userId: eventVolunteerId },
        select: { id: true },
      });
      if (user) {
        eventVolunteer = await this.prisma.eventVolunteer.findUnique({
          where: { userId_eventId: { userId: user.id, eventId: department.eventId } },
        });
      }
    }

    if (!eventVolunteer || eventVolunteer.departmentId !== departmentId) {
      throw new ValidationError('Volunteer is not a member of this department');
    }

    const resolvedEvId = eventVolunteer.id;

    // Upsert the hierarchy role
    return this.prisma.departmentHierarchy.upsert({
      where: {
        departmentId_hierarchyRole_eventVolunteerId: {
          departmentId,
          hierarchyRole: hierarchyRole as HierarchyRole,
          eventVolunteerId: resolvedEvId,
        },
      },
      update: {},
      create: {
        departmentId,
        eventVolunteerId: resolvedEvId,
        hierarchyRole: hierarchyRole as HierarchyRole,
      },
      include: {
        eventVolunteer: {
          include: { user: true },
        },
        department: true,
      },
    });
  }

  /**
   * Remove a hierarchy role assignment.
   * Only the department overseer can do this.
   */
  async removeHierarchyRole(departmentId: string, eventVolunteerId: string, callerUserId: string) {
    // Verify caller is the department overseer
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      include: { overseer: true },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    if (!department.overseer || department.overseer.userId !== callerUserId) {
      throw new AuthorizationError('Only the department overseer can remove hierarchy roles');
    }

    // Resolve eventVolunteerId — try direct lookup first, then by human-readable userId
    let resolvedEvId = eventVolunteerId;
    const directLookup = await this.prisma.eventVolunteer.findUnique({
      where: { id: eventVolunteerId },
      select: { id: true },
    });

    if (!directLookup) {
      const user = await this.prisma.user.findUnique({
        where: { userId: eventVolunteerId },
        select: { id: true },
      });
      if (user) {
        const ev = await this.prisma.eventVolunteer.findUnique({
          where: { userId_eventId: { userId: user.id, eventId: department.eventId } },
          select: { id: true },
        });
        if (ev) resolvedEvId = ev.id;
      }
    }

    // Delete any hierarchy role for this volunteer in this department
    await this.prisma.departmentHierarchy.deleteMany({
      where: {
        departmentId,
        eventVolunteerId: resolvedEvId,
      },
    });

    return true;
  }

  async getMyAllEvents(userId: string) {
    // 1. Fetch overseer memberships
    const eventAdmins = await this.prisma.eventAdmin.findMany({
      where: { userId },
      include: {
        event: {
          include: {
            departments: true,
            _count: { select: { eventVolunteers: true } },
          },
        },
        department: true,
      },
      orderBy: { event: { startDate: 'asc' } },
    });

    // 2. Fetch volunteer memberships
    const eventVolunteers = await this.prisma.eventVolunteer.findMany({
      where: { userId },
      include: {
        event: {
          include: {
            _count: { select: { eventVolunteers: true } },
          },
        },
        department: true,
      },
      orderBy: { event: { startDate: 'asc' } },
    });

    // 3. Fetch hierarchy roles for all volunteer memberships (batch query)
    const volunteerIds = eventVolunteers.map((ev) => ev.id);
    const hierarchyRoles = volunteerIds.length > 0
      ? await this.prisma.departmentHierarchy.findMany({
          where: { eventVolunteerId: { in: volunteerIds } },
          select: { eventVolunteerId: true, hierarchyRole: true },
        })
      : [];
    const hierarchyByVolunteer = new Map(
      hierarchyRoles.map((h) => [h.eventVolunteerId, h.hierarchyRole])
    );

    // 4. Merge all memberships (a user can be both overseer and volunteer
    //    for the same event in different departments — return both)
    const results: Array<{
      eventId: string;
      event: (typeof eventAdmins)[0]['event'] | (typeof eventVolunteers)[0]['event'];
      membershipType: 'OVERSEER' | 'VOLUNTEER';
      overseerRole: string | null;
      departmentId: string | null;
      departmentName: string | null;
      departmentType: string | null;
      departmentAccessCode: string | null;
      eventVolunteerId: string | null;
      hierarchyRole: string | null;
    }> = [];

    for (const ea of eventAdmins) {
      results.push({
        eventId: ea.eventId,
        event: ea.event,
        membershipType: 'OVERSEER',
        overseerRole: ea.role,
        departmentId: ea.department?.id ?? null,
        departmentName: ea.department?.name ?? null,
        departmentType: ea.department?.departmentType ?? null,
        departmentAccessCode: ea.department?.accessCode ?? null,
        eventVolunteerId: null,
        hierarchyRole: null,
      });
    }

    for (const ev of eventVolunteers) {
      results.push({
        eventId: ev.eventId,
        event: ev.event,
        membershipType: 'VOLUNTEER',
        overseerRole: null,
        departmentId: ev.department?.id ?? null,
        departmentName: ev.department?.name ?? null,
        departmentType: ev.department?.departmentType ?? null,
        departmentAccessCode: null,
        eventVolunteerId: ev.id,
        hierarchyRole: hierarchyByVolunteer.get(ev.id) ?? null,
      });
    }

    return results;
  }

  async getMyEvents(adminId: string) {
    const eventAdmins = await this.prisma.eventAdmin.findMany({
      where: { userId: adminId },
      include: {
        event: {
          include: {
            departments: true,
            _count: {
              select: { eventVolunteers: true },
            },
          },
        },
        department: true,
      },
      orderBy: {
        event: {
          startDate: 'asc',
        },
      },
    });

    return eventAdmins;
  }

  async getEvent(eventId: string) {
    return this.prisma.event.findUnique({
      where: { id: eventId },
      include: {
        admins: {
          include: {
            user: true,
            department: true,
          },
        },
        departments: {
          include: {
            overseer: {
              include: { user: true },
            },
            _count: {
              select: { eventVolunteers: true, posts: true },
            },
          },
        },
        _count: {
          select: { eventVolunteers: true, sessions: true },
        },
      },
    });
  }

  async getEventDepartments(eventId: string) {
    return this.prisma.department.findMany({
      where: { eventId },
      include: {
        overseer: {
          include: { user: true },
        },
        _count: {
          select: { eventVolunteers: true, posts: true },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  async getEventAdmins(eventId: string) {
    return this.prisma.eventAdmin.findMany({
      where: { eventId },
      include: {
        user: true,
        event: true,
        department: true,
      },
      orderBy: { claimedAt: 'asc' },
    });
  }
}

/**
 * Event Service
 *
 * Business logic for event management: templates, activation, joining, departments.
 *
 * Methods:
 *   - getEventTemplates(serviceYear?): Get available event templates
 *   - activateEvent(input, adminId): Create event from template, admin becomes EVENT_OVERSEER
 *   - joinEvent(input, adminId): Join event using join code as DEPARTMENT_OVERSEER
 *   - claimDepartment(input, adminId): Claim a department in an event
 *   - getMyEvents(adminId): Get all events this admin is part of
 *   - getEvent(eventId): Get single event with all related data
 *   - getEventDepartments(eventId): Get departments for an event
 *
 * Event Lifecycle:
 *   1. HQ seeds event templates (Circuit Assembly 2025, etc.)
 *   2. Event Overseer calls activateEvent() → creates Event with unique joinCode
 *   3. Department Overseers call joinEvent() with the joinCode
 *   4. Department Overseers call claimDepartment() to claim their department
 *   5. Overseers manage volunteers, posts, sessions within their scope
 *
 * Department Names:
 *   DEPARTMENT_NAMES constant maps enum values (ATTENDANT) to display names (Attendant).
 *   Based on CO-1 convention guidelines for standard department names.
 *
 * Authorization:
 *   - Resolvers handle auth checks before calling these methods
 *   - This service assumes the caller has verified permissions
 *
 * Called by: ../graphql/resolvers/event.ts
 */
import { PrismaClient, EventRole, DepartmentType } from '@prisma/client';
import { NotFoundError, ConflictError, ValidationError } from '../utils/errors.js';
import {
  activateEventSchema,
  joinEventSchema,
  claimDepartmentSchema,
  ActivateEventInput,
  JoinEventInput,
  ClaimDepartmentInput,
} from '../graphql/validators/event.js';

// Department display names
const DEPARTMENT_NAMES: Record<DepartmentType, string> = {
  ACCOUNTS: 'Accounts',
  ATTENDANT: 'Attendant',
  AUDIO_VIDEO: 'Audio/Video',
  BAPTISM: 'Baptism',
  CLEANING: 'Cleaning',
  FIRST_AID: 'First Aid',
  INFORMATION_VOLUNTEER_SERVICE: 'Information & Volunteer Service',
  INSTALLATION: 'Installation',
  LOST_FOUND_CHECKROOM: 'Lost & Found / Checkroom',
  PARKING: 'Parking',
  ROOMING: 'Rooming',
  TRUCKING_EQUIPMENT: 'Trucking & Equipment',
};

export class EventService {
  constructor(private prisma: PrismaClient) {}

  async getEventTemplates(serviceYear?: number) {
    const where = serviceYear ? { serviceYear } : {};

    return this.prisma.eventTemplate.findMany({
      where,
      orderBy: { startDate: 'asc' },
    });
  }

  async activateEvent(input: ActivateEventInput, adminId: string) {
    const result = activateEventSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { templateId } = result.data;

    // Check template exists
    const template = await this.prisma.eventTemplate.findUnique({
      where: { id: templateId },
    });

    if (!template) {
      throw new NotFoundError('Event template');
    }

    // Check if already activated by this admin
    const existingEvent = await this.prisma.event.findFirst({
      where: {
        templateId,
        admins: {
          some: { adminId },
        },
      },
    });

    if (existingEvent) {
      throw new ConflictError('You have already activated this event');
    }

    // Create event and add admin as EVENT_OVERSEER
    const event = await this.prisma.event.create({
      data: {
        templateId,
        admins: {
          create: {
            adminId,
            role: EventRole.EVENT_OVERSEER,
          },
        },
      },
      include: {
        template: true,
        admins: {
          include: { admin: true },
        },
      },
    });

    return event;
  }

  async joinEvent(input: JoinEventInput, adminId: string) {
    const result = joinEventSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { joinCode } = result.data;

    // Find event by join code
    const event = await this.prisma.event.findUnique({
      where: { joinCode },
      include: { template: true },
    });

    if (!event) {
      throw new NotFoundError('Event with this join code');
    }

    // Check if already a member
    const existingMembership = await this.prisma.eventAdmin.findUnique({
      where: {
        adminId_eventId: {
          adminId,
          eventId: event.id,
        },
      },
    });

    if (existingMembership) {
      throw new ConflictError('You are already a member of this event');
    }

    // Add as member (no role yet - must claim department)
    const eventAdmin = await this.prisma.eventAdmin.create({
      data: {
        adminId,
        eventId: event.id,
        role: EventRole.DEPARTMENT_OVERSEER, // Default role until they claim
      },
      include: {
        event: {
          include: { template: true },
        },
        admin: true,
      },
    });

    return eventAdmin;
  }

  async claimDepartment(input: ClaimDepartmentInput, adminId: string) {
    const result = claimDepartmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, departmentType } = result.data;

    // Check admin is member of event
    const eventAdmin = await this.prisma.eventAdmin.findUnique({
      where: {
        adminId_eventId: {
          adminId,
          eventId,
        },
      },
    });

    if (!eventAdmin) {
      throw new NotFoundError('Event membership');
    }

    // Check if department already exists (already claimed)
    const existingDepartment = await this.prisma.department.findUnique({
      where: {
        eventId_departmentType: {
          eventId,
          departmentType,
        },
      },
      include: { overseer: { include: { admin: true } } },
    });

    if (existingDepartment) {
      const overseerName = existingDepartment.overseer
        ? `${existingDepartment.overseer.admin.firstName} ${existingDepartment.overseer.admin.lastName}`
        : 'Unknown';
      throw new ConflictError(
        `${DEPARTMENT_NAMES[departmentType]} is already claimed by ${overseerName}`
      );
    }

    // Check if admin already has a department in this event
    if (eventAdmin.departmentId) {
      throw new ConflictError('You have already claimed a department in this event');
    }

    // Create department and assign overseer
    const department = await this.prisma.department.create({
      data: {
        name: DEPARTMENT_NAMES[departmentType],
        departmentType,
        eventId,
      },
    });

    // Update eventAdmin with department
    await this.prisma.eventAdmin.update({
      where: { id: eventAdmin.id },
      data: {
        departmentId: department.id,
        role: EventRole.DEPARTMENT_OVERSEER,
      },
    });

    return this.prisma.department.findUnique({
      where: { id: department.id },
      include: {
        overseer: {
          include: { admin: true },
        },
        event: {
          include: { template: true },
        },
      },
    });
  }

  async getMyEvents(adminId: string) {
    const eventAdmins = await this.prisma.eventAdmin.findMany({
      where: { adminId },
      include: {
        event: {
          include: {
            template: true,
            departments: true,
            _count: {
              select: { volunteers: true },
            },
          },
        },
        department: true,
      },
      orderBy: {
        event: {
          template: {
            startDate: 'asc',
          },
        },
      },
    });

    return eventAdmins;
  }

  async getEvent(eventId: string) {
    return this.prisma.event.findUnique({
      where: { id: eventId },
      include: {
        template: true,
        admins: {
          include: {
            admin: true,
            department: true,
          },
        },
        departments: {
          include: {
            overseer: {
              include: { admin: true },
            },
            _count: {
              select: { volunteers: true, posts: true },
            },
          },
        },
        _count: {
          select: { volunteers: true, sessions: true },
        },
      },
    });
  }

  async getEventDepartments(eventId: string) {
    return this.prisma.department.findMany({
      where: { eventId },
      include: {
        overseer: {
          include: { admin: true },
        },
        _count: {
          select: { volunteers: true, posts: true },
        },
      },
      orderBy: { name: 'asc' },
    });
  }
}

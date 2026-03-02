/**
 * Volunteer Service
 *
 * Business logic for volunteer management within events.
 * Volunteers authenticate as Users (email/password or OAuth).
 * EventVolunteer is a per-event membership record — no credentials.
 *
 * Methods:
 *   - createVolunteer(eventId, input, departmentId?): Create single volunteer
 *   - createVolunteers(input, defaultDepartmentId?): Bulk create volunteers
 *   - getVolunteer(id): Get volunteer with all related data
 *   - getEventVolunteers(eventId, departmentId?): List volunteers for event/department
 *   - updateVolunteer(id, input): Update volunteer details
 *   - deleteVolunteer(id): Remove volunteer
 *
 * Called by: ../graphql/resolvers/volunteer.ts
 */
import { PrismaClient, DepartmentType, JoinRequestStatus } from '@prisma/client';
import { NotFoundError, ValidationError } from '../utils/errors.js';
import { generateUserId } from '../utils/credentials.js';
import {
  createVolunteerSchema,
  createVolunteersSchema,
  CreateVolunteerInput,
  CreateVolunteersInput,
} from '../graphql/validators/volunteer.js';

export interface CreatedVolunteer {
  id: string;
  firstName: string;
  lastName: string;
  congregation: string;
}

export class VolunteerService {
  constructor(private prisma: PrismaClient) {}

  async createVolunteer(
    eventId: string,
    input: CreateVolunteerInput,
    departmentId?: string
  ): Promise<CreatedVolunteer> {
    const result = createVolunteerSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const validated = result.data;

    // Verify event exists and get event type for ID prefix
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    const deptId = departmentId || validated.departmentId;

    // Find or create Congregation and User, then create EventVolunteer in transaction
    const eventVolunteer = await this.prisma.$transaction(async (tx) => {
      // Find or create Congregation for User
      const congregationRecord = await this.findOrCreateCongregation(
        tx, validated.congregation, event.circuitId
      );

      // Find or create User (persistent across events)
      let user = validated.email
        ? await tx.user.findUnique({ where: { email: validated.email } })
        : null;

      if (!user) {
        const newUserId = generateUserId();
        user = await tx.user.create({
          data: {
            userId: newUserId,
            email: validated.email ?? `${newUserId}@placeholder.assemblyops.io`,
            firstName: validated.firstName,
            lastName: validated.lastName,
            phone: validated.phone,
            appointmentStatus: validated.appointmentStatus || 'PUBLISHER',
            congregation: validated.congregation,
            congregationId: congregationRecord.id,
            isPlaceholder: !validated.email,
          },
        });
      }

      // EventVolunteer (per-event membership record)
      const ev = await tx.eventVolunteer.create({
        data: {
          userId: user.id,
          eventId,
          departmentId: deptId,
          roleId: validated.roleId,
        },
        include: { user: true },
      });

      return ev;
    });

    return {
      id: eventVolunteer.id,
      firstName: eventVolunteer.user.firstName,
      lastName: eventVolunteer.user.lastName,
      congregation: eventVolunteer.user.congregation ?? validated.congregation,
    };
  }

  async createVolunteers(
    input: CreateVolunteersInput,
    defaultDepartmentId?: string
  ): Promise<CreatedVolunteer[]> {
    const result = createVolunteersSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, volunteers } = result.data;

    // Verify event exists and get event type for ID prefix
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    const createdVolunteers: CreatedVolunteer[] = [];

    for (const volunteerInput of volunteers) {
      const deptId = volunteerInput.departmentId || defaultDepartmentId;

      const eventVolunteer = await this.prisma.$transaction(async (tx) => {
        const congregationRecord = await this.findOrCreateCongregation(
          tx, volunteerInput.congregation, event.circuitId
        );

        let user = volunteerInput.email
          ? await tx.user.findUnique({ where: { email: volunteerInput.email } })
          : null;

        if (!user) {
          const newUserId = generateUserId();
          user = await tx.user.create({
            data: {
              userId: newUserId,
              email: volunteerInput.email ?? `${newUserId}@placeholder.assemblyops.io`,
              firstName: volunteerInput.firstName,
              lastName: volunteerInput.lastName,
              phone: volunteerInput.phone,
              appointmentStatus: volunteerInput.appointmentStatus || 'PUBLISHER',
              congregation: volunteerInput.congregation,
              congregationId: congregationRecord.id,
              isPlaceholder: !volunteerInput.email,
            },
          });
        }

        const ev = await tx.eventVolunteer.create({
          data: {
            userId: user.id,
            eventId,
            departmentId: deptId,
            roleId: volunteerInput.roleId,
          },
          include: { user: true },
        });

        return ev;
      });

      createdVolunteers.push({
        id: eventVolunteer.id,
        firstName: eventVolunteer.user.firstName,
        lastName: eventVolunteer.user.lastName,
        congregation: eventVolunteer.user.congregation ?? volunteerInput.congregation,
      });
    }

    return createdVolunteers;
  }

  async getVolunteer(volunteerId: string) {
    return this.prisma.eventVolunteer.findUnique({
      where: { id: volunteerId },
      include: {
        user: true,
        event: true,
        department: true,
        role: true,
        assignments: {
          include: {
            post: true,
            session: true,
            checkIn: true,
          },
        },
      },
    });
  }

  async getEventVolunteers(eventId: string, departmentId?: string) {
    const where: { eventId: string; departmentId?: string } = { eventId };
    if (departmentId) {
      where.departmentId = departmentId;
    }

    return this.prisma.eventVolunteer.findMany({
      where,
      include: {
        user: true,
        department: true,
        role: true,
      },
      orderBy: [{ user: { lastName: 'asc' } }, { user: { firstName: 'asc' } }],
    });
  }

  async updateVolunteer(volunteerId: string, input: Partial<CreateVolunteerInput>) {
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: volunteerId },
      include: { user: true },
    });

    if (!eventVolunteer) {
      throw new NotFoundError('Volunteer');
    }

    // Update User fields if provided
    if (input.firstName || input.lastName || input.email || input.phone || input.congregation || input.appointmentStatus) {
      await this.prisma.user.update({
        where: { id: eventVolunteer.userId },
        data: {
          ...(input.firstName && { firstName: input.firstName }),
          ...(input.lastName && { lastName: input.lastName }),
          ...(input.email && { email: input.email }),
          ...(input.phone !== undefined && { phone: input.phone }),
          ...(input.congregation && { congregation: input.congregation }),
          ...(input.appointmentStatus && { appointmentStatus: input.appointmentStatus }),
        },
      });
    }

    return this.prisma.eventVolunteer.update({
      where: { id: volunteerId },
      data: {
        departmentId: input.departmentId,
        roleId: input.roleId,
      },
      include: {
        user: true,
        department: true,
        role: true,
      },
    });
  }

  async deleteVolunteer(volunteerId: string) {
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: volunteerId },
    });

    if (!eventVolunteer) {
      throw new NotFoundError('Volunteer');
    }

    await this.prisma.eventVolunteer.delete({
      where: { id: volunteerId },
    });

    return true;
  }

  /**
   * Request to join an event as a volunteer.
   * Circuit Assembly events: creates a PENDING join request.
   * Regional or Special Convention: invite-only, throws error.
   */
  async requestToJoinEvent(
    eventId: string,
    userId: string,
    departmentType?: string,
    note?: string
  ) {
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    // Regional and special conventions are invite-only
    if (
      event.eventType === 'REGIONAL_CONVENTION' ||
      event.eventType === 'SPECIAL_CONVENTION'
    ) {
      throw new ValidationError(
        'Regional and special convention events are invite-only. Please contact your department overseer.'
      );
    }

    // Check if already a volunteer for this event
    const existingVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { userId_eventId: { userId, eventId } },
    });

    if (existingVolunteer) {
      throw new ValidationError('You are already a volunteer for this event.');
    }

    // Check for existing request
    const existingRequest = await this.prisma.eventJoinRequest.findUnique({
      where: { eventId_userId: { eventId, userId } },
    });

    if (existingRequest) {
      if (existingRequest.status === 'PENDING') {
        throw new ValidationError('You already have a pending join request for this event.');
      }
      // If denied, allow re-request by updating
      return this.prisma.eventJoinRequest.update({
        where: { id: existingRequest.id },
        data: {
          status: 'PENDING' as JoinRequestStatus,
          departmentType: (departmentType as DepartmentType) || null,
          note,
          resolvedAt: null,
          resolvedById: null,
        },
        include: { user: true, event: true },
      });
    }

    return this.prisma.eventJoinRequest.create({
      data: {
        eventId,
        userId,
        departmentType: (departmentType as DepartmentType) || null,
        note,
      },
      include: { user: true, event: true },
    });
  }

  /**
   * Cancel a pending join request (by the requesting user).
   */
  async cancelJoinRequest(requestId: string, userId: string) {
    const request = await this.prisma.eventJoinRequest.findUnique({
      where: { id: requestId },
    });

    if (!request) {
      throw new NotFoundError('Join request');
    }

    if (request.userId !== userId) {
      throw new ValidationError('You can only cancel your own join requests.');
    }

    if (request.status !== 'PENDING') {
      throw new ValidationError('Only pending requests can be cancelled.');
    }

    return this.prisma.eventJoinRequest.delete({
      where: { id: requestId },
    });
  }

  /**
   * Approve a join request (overseer action).
   * Creates an EventVolunteer record with generated credentials.
   */
  async approveJoinRequest(requestId: string, adminUserId: string) {
    const request = await this.prisma.eventJoinRequest.findUnique({
      where: { id: requestId },
      include: { user: true, event: true },
    });

    if (!request) {
      throw new NotFoundError('Join request');
    }

    if (request.status !== 'PENDING') {
      throw new ValidationError('Only pending requests can be approved.');
    }

    return this.prisma.$transaction(async (tx) => {
      // Mark request approved
      await tx.eventJoinRequest.update({
        where: { id: requestId },
        data: {
          status: 'APPROVED',
          resolvedAt: new Date(),
          resolvedById: adminUserId,
        },
      });

      // Create EventVolunteer membership record
      const eventVolunteer = await tx.eventVolunteer.create({
        data: {
          userId: request.userId,
          eventId: request.eventId,
        },
        include: { user: true, event: true },
      });

      return eventVolunteer;
    });
  }

  /**
   * Deny a join request (overseer action).
   */
  async denyJoinRequest(requestId: string, adminUserId: string, reason?: string) {
    const request = await this.prisma.eventJoinRequest.findUnique({
      where: { id: requestId },
    });

    if (!request) {
      throw new NotFoundError('Join request');
    }

    if (request.status !== 'PENDING') {
      throw new ValidationError('Only pending requests can be denied.');
    }

    return this.prisma.eventJoinRequest.update({
      where: { id: requestId },
      data: {
        status: 'DENIED',
        resolvedAt: new Date(),
        resolvedById: adminUserId,
        note: reason || request.note,
      },
      include: { user: true, event: true },
    });
  }

  /**
   * Add a volunteer directly by their 6-char userId (overseer action).
   * Bypasses join request flow — overseer invites directly.
   */
  async addVolunteerByUserId(
    eventId: string,
    userShortId: string,
    adminUserId: string,
    departmentId?: string
  ) {
    const user = await this.prisma.user.findUnique({
      where: { userId: userShortId },
    });

    if (!user) {
      throw new NotFoundError(`No user found with ID: ${userShortId}`);
    }

    // Check if already added
    const existing = await this.prisma.eventVolunteer.findUnique({
      where: { userId_eventId: { userId: user.id, eventId } },
    });

    if (existing) {
      throw new ValidationError('This user is already a volunteer for this event.');
    }

    const eventVolunteer = await this.prisma.eventVolunteer.create({
      data: {
        userId: user.id,
        eventId,
        departmentId,
      },
      include: { user: true, event: true },
    });

    return eventVolunteer;
  }

  /**
   * Link a placeholder user to a real user account.
   * Transfers all EventVolunteer records and their child data, then deletes the placeholder.
   * Uses 6-char userId shortcodes for both inputs.
   */
  async linkPlaceholderUser(placeholderShortId: string, realUserShortId: string) {
    const placeholder = await this.prisma.user.findUnique({
      where: { userId: placeholderShortId },
      include: { eventVolunteers: true },
    });

    if (!placeholder) {
      throw new NotFoundError(`No user found with ID: ${placeholderShortId}`);
    }

    if (!placeholder.isPlaceholder) {
      throw new ValidationError('The specified user is not a placeholder account.');
    }

    const realUser = await this.prisma.user.findUnique({
      where: { userId: realUserShortId },
      include: { eventVolunteers: true },
    });

    if (!realUser) {
      throw new NotFoundError(`No user found with ID: ${realUserShortId}`);
    }

    if (realUser.isPlaceholder) {
      throw new ValidationError('Real user cannot itself be a placeholder.');
    }

    let mergedCount = 0;

    await this.prisma.$transaction(async (tx) => {
      const realUserEventIds = new Set(realUser.eventVolunteers.map(ev => ev.eventId));

      for (const placeholderEv of placeholder.eventVolunteers) {
        if (!realUserEventIds.has(placeholderEv.eventId)) {
          // Simple case: real user has no EV for this event — re-point
          await tx.eventVolunteer.update({
            where: { id: placeholderEv.id },
            data: { userId: realUser.id },
          });
          mergedCount++;
        } else {
          // Conflict case: real user already has EV for this event — merge child records
          const realEv = realUser.eventVolunteers.find(ev => ev.eventId === placeholderEv.eventId)!;

          // --- Tables with unique constraints: delete conflicts first, then re-parent ---

          // ScheduleAssignment: @@unique([eventVolunteerId, sessionId, shiftId])
          const realAssignments = await tx.scheduleAssignment.findMany({
            where: { eventVolunteerId: realEv.id },
            select: { sessionId: true, shiftId: true },
          });
          const assignmentKeys = new Set(realAssignments.map(a => `${a.sessionId}|${a.shiftId}`));
          const placeholderAssignments = await tx.scheduleAssignment.findMany({
            where: { eventVolunteerId: placeholderEv.id },
            select: { id: true, sessionId: true, shiftId: true },
          });
          const conflictAssignmentIds = placeholderAssignments
            .filter(a => assignmentKeys.has(`${a.sessionId}|${a.shiftId}`))
            .map(a => a.id);
          if (conflictAssignmentIds.length > 0) {
            await tx.scheduleAssignment.deleteMany({ where: { id: { in: conflictAssignmentIds } } });
          }
          await tx.scheduleAssignment.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // DepartmentHierarchy: @@unique([departmentId, hierarchyRole, eventVolunteerId])
          const realHierarchy = await tx.departmentHierarchy.findMany({
            where: { eventVolunteerId: realEv.id },
            select: { departmentId: true, hierarchyRole: true },
          });
          const hierarchyKeys = new Set(realHierarchy.map(h => `${h.departmentId}|${h.hierarchyRole}`));
          const placeholderHierarchy = await tx.departmentHierarchy.findMany({
            where: { eventVolunteerId: placeholderEv.id },
            select: { id: true, departmentId: true, hierarchyRole: true },
          });
          const conflictHierarchyIds = placeholderHierarchy
            .filter(h => hierarchyKeys.has(`${h.departmentId}|${h.hierarchyRole}`))
            .map(h => h.id);
          if (conflictHierarchyIds.length > 0) {
            await tx.departmentHierarchy.deleteMany({ where: { id: { in: conflictHierarchyIds } } });
          }
          await tx.departmentHierarchy.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // ReminderConfirmation: @@unique([eventVolunteerId, shiftId]) + @@unique([eventVolunteerId, sessionId])
          const realReminders = await tx.reminderConfirmation.findMany({
            where: { eventVolunteerId: realEv.id },
            select: { shiftId: true, sessionId: true },
          });
          const reminderShiftKeys = new Set(realReminders.filter(r => r.shiftId).map(r => r.shiftId));
          const reminderSessionKeys = new Set(realReminders.filter(r => r.sessionId).map(r => r.sessionId));
          const placeholderReminders = await tx.reminderConfirmation.findMany({
            where: { eventVolunteerId: placeholderEv.id },
            select: { id: true, shiftId: true, sessionId: true },
          });
          const conflictReminderIds = placeholderReminders
            .filter(r =>
              (r.shiftId && reminderShiftKeys.has(r.shiftId)) ||
              (r.sessionId && reminderSessionKeys.has(r.sessionId))
            )
            .map(r => r.id);
          if (conflictReminderIds.length > 0) {
            await tx.reminderConfirmation.deleteMany({ where: { id: { in: conflictReminderIds } } });
          }
          await tx.reminderConfirmation.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // LanyardCheckout: @@unique([eventVolunteerId, date])
          const realLanyards = await tx.lanyardCheckout.findMany({
            where: { eventVolunteerId: realEv.id },
            select: { date: true },
          });
          const lanyardDates = new Set(realLanyards.map(l => l.date.toISOString()));
          const placeholderLanyards = await tx.lanyardCheckout.findMany({
            where: { eventVolunteerId: placeholderEv.id },
            select: { id: true, date: true },
          });
          const conflictLanyardIds = placeholderLanyards
            .filter(l => lanyardDates.has(l.date.toISOString()))
            .map(l => l.id);
          if (conflictLanyardIds.length > 0) {
            await tx.lanyardCheckout.deleteMany({ where: { id: { in: conflictLanyardIds } } });
          }
          await tx.lanyardCheckout.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // MeetingAttendance: @@unique([meetingId, eventVolunteerId])
          const realAttendance = await tx.meetingAttendance.findMany({
            where: { eventVolunteerId: realEv.id },
            select: { meetingId: true },
          });
          const attendanceKeys = new Set(realAttendance.map(a => a.meetingId));
          const placeholderAttendance = await tx.meetingAttendance.findMany({
            where: { eventVolunteerId: placeholderEv.id },
            select: { id: true, meetingId: true },
          });
          const conflictAttendanceIds = placeholderAttendance
            .filter(a => attendanceKeys.has(a.meetingId))
            .map(a => a.id);
          if (conflictAttendanceIds.length > 0) {
            await tx.meetingAttendance.deleteMany({ where: { id: { in: conflictAttendanceIds } } });
          }
          await tx.meetingAttendance.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // AVSafetyBriefingAttendee: @@unique([briefingId, eventVolunteerId])
          const realBriefings = await tx.aVSafetyBriefingAttendee.findMany({
            where: { eventVolunteerId: realEv.id },
            select: { briefingId: true },
          });
          const briefingKeys = new Set(realBriefings.map(b => b.briefingId));
          const placeholderBriefings = await tx.aVSafetyBriefingAttendee.findMany({
            where: { eventVolunteerId: placeholderEv.id },
            select: { id: true, briefingId: true },
          });
          const conflictBriefingIds = placeholderBriefings
            .filter(b => briefingKeys.has(b.briefingId))
            .map(b => b.id);
          if (conflictBriefingIds.length > 0) {
            await tx.aVSafetyBriefingAttendee.deleteMany({ where: { id: { in: conflictBriefingIds } } });
          }
          await tx.aVSafetyBriefingAttendee.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // --- Tables without unique constraints: simple updateMany ---

          // AreaCaptain (unique on areaId+sessionId, not volunteer)
          await tx.areaCaptain.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // WalkThroughCompletion
          await tx.walkThroughCompletion.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // PostSessionStatus (unique on postId+sessionId, not volunteer)
          await tx.postSessionStatus.updateMany({
            where: { updatedById: placeholderEv.id },
            data: { updatedById: realEv.id },
          });

          // AVEquipmentCheckout
          await tx.aVEquipmentCheckout.updateMany({
            where: { checkedOutById: placeholderEv.id },
            data: { checkedOutById: realEv.id },
          });

          // AVDamageReport
          await tx.aVDamageReport.updateMany({
            where: { reportedById: placeholderEv.id },
            data: { reportedById: realEv.id },
          });

          // CheckIn (optional FK)
          await tx.checkIn.updateMany({
            where: { checkedInByVolId: placeholderEv.id },
            data: { checkedInByVolId: realEv.id },
          });

          // Message (two optional FKs)
          await tx.message.updateMany({
            where: { senderVolId: placeholderEv.id },
            data: { senderVolId: realEv.id },
          });
          await tx.message.updateMany({
            where: { eventVolunteerId: placeholderEv.id },
            data: { eventVolunteerId: realEv.id },
          });

          // LostPersonAlert
          await tx.lostPersonAlert.updateMany({
            where: { reportedById: placeholderEv.id },
            data: { reportedById: realEv.id },
          });

          // SafetyIncident
          await tx.safetyIncident.updateMany({
            where: { reportedById: placeholderEv.id },
            data: { reportedById: realEv.id },
          });

          // Delete the placeholder EventVolunteer (all children re-parented)
          await tx.eventVolunteer.delete({ where: { id: placeholderEv.id } });
          mergedCount++;
        }
      }

      // Delete the placeholder User record
      await tx.user.delete({ where: { id: placeholder.id } });
    });

    return {
      success: true,
      mergedCount,
      message: `Linked ${mergedCount} event membership(s) from placeholder to real user.`,
    };
  }

  /**
   * Get all join requests for an event (overseer view).
   */
  async getEventJoinRequests(eventId: string, status?: string) {
    return this.prisma.eventJoinRequest.findMany({
      where: {
        eventId,
        ...(status && { status: status as JoinRequestStatus }),
      },
      include: { user: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get all join requests for the current user.
   */
  async getMyJoinRequests(userId: string) {
    return this.prisma.eventJoinRequest.findMany({
      where: { userId },
      include: { event: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Find or create a Congregation record for VolunteerProfile.
   * Uses congregation name + circuitId. If circuit is unknown, creates with defaults.
   */
  private async findOrCreateCongregation(
    tx: Parameters<Parameters<PrismaClient['$transaction']>[0]>[0],
    congregationName: string,
    circuitId?: string | null
  ) {
    // Try to find existing congregation by name within the circuit
    if (circuitId) {
      const existing = await tx.congregation.findFirst({
        where: { name: congregationName, circuitId },
      });
      if (existing) return existing;
    }

    // Find or create a default circuit if none provided
    let resolvedCircuitId = circuitId;
    if (!resolvedCircuitId) {
      const defaultCircuit = await tx.circuit.upsert({
        where: { code: 'UNKNOWN' },
        update: {},
        create: { code: 'UNKNOWN', region: 'Unknown' },
      });
      resolvedCircuitId = defaultCircuit.id;
    }

    // Create new congregation
    return tx.congregation.create({
      data: {
        name: congregationName,
        state: 'Unknown',
        circuitId: resolvedCircuitId,
      },
    });
  }
}

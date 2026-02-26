/**
 * Volunteer Service
 *
 * Business logic for volunteer management: create, update, delete, login, credentials.
 *
 * Methods:
 *   - createVolunteer(eventId, input, departmentId?): Create single volunteer
 *   - createVolunteers(input, defaultDepartmentId?): Bulk create volunteers
 *   - getVolunteer(id): Get volunteer with all related data
 *   - getEventVolunteers(eventId, departmentId?): List volunteers for event/department
 *   - updateVolunteer(id, input): Update volunteer details
 *   - deleteVolunteer(id): Remove volunteer
 *   - regenerateCredentials(id): Generate new login credentials (invalidates old ones)
 *
 * Volunteer Credentials:
 *   - volunteerId: 8-character alphanumeric ID (e.g., "ABC12345")
 *   - token: 6-character alphanumeric token (e.g., "XY7890")
 *   - tokenHash: bcrypt hash of the token stored in database
 *   - Plain token is ONLY returned when creating/regenerating (never stored)
 *
 * CreatedVolunteer Interface:
 *   When creating a volunteer, we return the plain token (for printing/sending).
 *   This is the ONLY time the plain token is available.
 *
 * Called by: ../graphql/resolvers/volunteer.ts
 */
import { PrismaClient } from '@prisma/client';
import { NotFoundError, ValidationError } from '../utils/errors.js';
import { generateEventVolunteerId, generateToken, hashToken, decryptToken } from '../utils/credentials.js';
import { encryptField } from '../utils/encryption.js';
import { TokenService } from './tokenService.js';
import {
  createVolunteerSchema,
  createVolunteersSchema,
  CreateVolunteerInput,
  CreateVolunteersInput,
} from '../graphql/validators/volunteer.js';

export interface CreatedVolunteer {
  id: string;
  volunteerId: string;
  token: string; // Plain token - only returned on creation
  firstName: string;
  lastName: string;
  congregation: string;
}

export class VolunteerService {
  private tokenService: TokenService;

  constructor(private prisma: PrismaClient) {
    this.tokenService = new TokenService(prisma);
  }

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
      include: { template: true },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    // Generate volunteer credentials
    const volunteerId = generateEventVolunteerId();
    const token = generateToken();
    const tokenHash = await hashToken(token);

    const deptId = departmentId || validated.departmentId;

    // Find or create Congregation and User, then create EventVolunteer in transaction
    const eventVolunteer = await this.prisma.$transaction(async (tx) => {
      // Find or create Congregation for User
      const congregationRecord = await this.findOrCreateCongregation(
        tx, validated.congregation, event.template.circuitId
      );

      // Find or create User (persistent across events)
      let user = validated.email
        ? await tx.user.findUnique({ where: { email: validated.email } })
        : null;

      if (!user) {
        // Generate a unique userId for the User record
        const { generateUserId } = await import('../utils/credentials.js');
        const newUserId = generateUserId();
        user = await tx.user.create({
          data: {
            userId: newUserId,
            email: validated.email ?? `${volunteerId}@placeholder.assemblyops.io`,
            firstName: validated.firstName,
            lastName: validated.lastName,
            phone: validated.phone,
            appointmentStatus: validated.appointmentStatus || 'PUBLISHER',
            congregation: validated.congregation,
            congregationId: congregationRecord.id,
          },
        });
      }

      // EventVolunteer (per-event credential record)
      const ev = await tx.eventVolunteer.create({
        data: {
          volunteerId,
          tokenHash,
          encryptedToken: encryptField(token),
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
      volunteerId: eventVolunteer.volunteerId,
      token, // Plain token to give to volunteer
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
      include: { template: true },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    const createdVolunteers: CreatedVolunteer[] = [];

    for (const volunteerInput of volunteers) {
      const volId = generateEventVolunteerId();
      const volToken = generateToken();
      const volTokenHash = await hashToken(volToken);
      const deptId = volunteerInput.departmentId || defaultDepartmentId;

      const eventVolunteer = await this.prisma.$transaction(async (tx) => {
        const congregationRecord = await this.findOrCreateCongregation(
          tx, volunteerInput.congregation, event.template.circuitId
        );

        let user = volunteerInput.email
          ? await tx.user.findUnique({ where: { email: volunteerInput.email } })
          : null;

        if (!user) {
          const { generateUserId } = await import('../utils/credentials.js');
          const newUserId = generateUserId();
          user = await tx.user.create({
            data: {
              userId: newUserId,
              email: volunteerInput.email ?? `${volId}@placeholder.assemblyops.io`,
              firstName: volunteerInput.firstName,
              lastName: volunteerInput.lastName,
              phone: volunteerInput.phone,
              appointmentStatus: volunteerInput.appointmentStatus || 'PUBLISHER',
              congregation: volunteerInput.congregation,
              congregationId: congregationRecord.id,
            },
          });
        }

        const ev = await tx.eventVolunteer.create({
          data: {
            volunteerId: volId,
            tokenHash: volTokenHash,
            encryptedToken: encryptField(volToken),
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
        volunteerId: eventVolunteer.volunteerId,
        token: volToken,
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
        event: {
          include: { template: true },
        },
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

  async regenerateCredentials(volunteerId: string): Promise<{
    volunteerId: string;
    token: string;
  }> {
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: volunteerId },
    });

    if (!eventVolunteer) {
      throw new NotFoundError('Volunteer');
    }

    const newVolunteerId = generateEventVolunteerId();
    const token = generateToken();
    const tokenHash = await hashToken(token);
    await this.prisma.eventVolunteer.update({
      where: { id: volunteerId },
      data: {
        volunteerId: newVolunteerId,
        tokenHash,
        encryptedToken: encryptField(token),
      },
    });

    // Revoke any existing refresh tokens
    await this.tokenService.revokeAllUserTokens(volunteerId, 'eventVolunteer');

    return {
      volunteerId: newVolunteerId,
      token,
    };
  }

  async getVolunteerToken(volunteerId: string): Promise<string> {
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: volunteerId },
    });

    if (!eventVolunteer) {
      throw new NotFoundError('Volunteer');
    }

    if (!eventVolunteer.encryptedToken) {
      throw new NotFoundError('Token not available for this volunteer');
    }

    return decryptToken(eventVolunteer.encryptedToken);
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
      include: { template: true },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    // Regional and special conventions are invite-only
    if (
      event.template.eventType === 'REGIONAL_CONVENTION' ||
      event.template.eventType === 'SPECIAL_CONVENTION'
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
          status: 'PENDING',
          departmentType: departmentType as any,
          note,
          resolvedAt: null,
          resolvedById: null,
        },
        include: { user: true, event: { include: { template: true } } },
      });
    }

    return this.prisma.eventJoinRequest.create({
      data: {
        eventId,
        userId,
        departmentType: departmentType as any,
        note,
      },
      include: { user: true, event: { include: { template: true } } },
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
      include: { user: true, event: { include: { template: true } } },
    });

    if (!request) {
      throw new NotFoundError('Join request');
    }

    if (request.status !== 'PENDING') {
      throw new ValidationError('Only pending requests can be approved.');
    }

    const volunteerId = generateEventVolunteerId();
    const token = generateToken();
    const tokenHash = await hashToken(token);

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

      // Create EventVolunteer record
      const eventVolunteer = await tx.eventVolunteer.create({
        data: {
          volunteerId,
          tokenHash,
          encryptedToken: encryptField(token),
          userId: request.userId,
          eventId: request.eventId,
          departmentId: undefined,
        },
        include: { user: true, event: { include: { template: true } } },
      });

      return {
        eventVolunteer,
        volunteerId,
        token,
        inviteMessage: `Hi ${request.user.firstName}! Your request to join ${request.event.template.name} has been approved.\n\nYour login credentials:\nVolunteer ID: ${volunteerId}\nToken: ${token}`,
      };
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
      include: { user: true, event: { include: { template: true } } },
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

    const volunteerId = generateEventVolunteerId();
    const token = generateToken();
    const tokenHash = await hashToken(token);

    const eventVolunteer = await this.prisma.eventVolunteer.create({
      data: {
        volunteerId,
        tokenHash,
        encryptedToken: encryptField(token),
        userId: user.id,
        eventId,
        departmentId,
      },
      include: { user: true, event: { include: { template: true } } },
    });

    return {
      eventVolunteer,
      volunteerId,
      token,
      inviteMessage: `Hi ${user.firstName}! You've been added to ${eventVolunteer.event.template.name}.\n\nYour login credentials:\nVolunteer ID: ${volunteerId}\nToken: ${token}`,
    };
  }

  /**
   * Get all join requests for an event (overseer view).
   */
  async getEventJoinRequests(eventId: string, status?: string) {
    return this.prisma.eventJoinRequest.findMany({
      where: {
        eventId,
        ...(status && { status: status as any }),
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
      include: { event: { include: { template: true } } },
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
        city: 'Unknown',
        state: 'Unknown',
        circuitId: resolvedCircuitId,
      },
    });
  }
}

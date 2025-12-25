import { PrismaClient } from '@prisma/client';
import { NotFoundError, ValidationError, AuthenticationError } from '../utils/errors.js';
import { generateVolunteerCredentials } from '../utils/credentials.js';
import { verifyPassword } from '../utils/password.js';
import { generateTokens, TokenPair } from '../utils/jwt.js';
import { TokenService } from './tokenService.js';
import {
  createVolunteerSchema,
  createVolunteersSchema,
  loginVolunteerSchema,
  CreateVolunteerInput,
  CreateVolunteersInput,
  LoginVolunteerInput,
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

    // Verify event exists
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    // Generate credentials
    const credentials = await generateVolunteerCredentials();

    // Create volunteer
    const volunteer = await this.prisma.volunteer.create({
      data: {
        volunteerId: credentials.volunteerId,
        tokenHash: credentials.tokenHash,
        firstName: validated.firstName,
        lastName: validated.lastName,
        email: validated.email,
        phone: validated.phone,
        congregation: validated.congregation,
        appointmentStatus: validated.appointmentStatus,
        notes: validated.notes,
        eventId,
        departmentId: departmentId || validated.departmentId,
        roleId: validated.roleId,
      },
    });

    return {
      id: volunteer.id,
      volunteerId: volunteer.volunteerId,
      token: credentials.token, // Plain token to give to volunteer
      firstName: volunteer.firstName,
      lastName: volunteer.lastName,
      congregation: volunteer.congregation,
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

    // Verify event exists
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    const createdVolunteers: CreatedVolunteer[] = [];

    for (const volunteerInput of volunteers) {
      const credentials = await generateVolunteerCredentials();

      const volunteer = await this.prisma.volunteer.create({
        data: {
          volunteerId: credentials.volunteerId,
          tokenHash: credentials.tokenHash,
          firstName: volunteerInput.firstName,
          lastName: volunteerInput.lastName,
          email: volunteerInput.email,
          phone: volunteerInput.phone,
          congregation: volunteerInput.congregation,
          appointmentStatus: volunteerInput.appointmentStatus,
          notes: volunteerInput.notes,
          eventId,
          departmentId: volunteerInput.departmentId || defaultDepartmentId,
          roleId: volunteerInput.roleId,
        },
      });

      createdVolunteers.push({
        id: volunteer.id,
        volunteerId: volunteer.volunteerId,
        token: credentials.token,
        firstName: volunteer.firstName,
        lastName: volunteer.lastName,
        congregation: volunteer.congregation,
      });
    }

    return createdVolunteers;
  }

  async loginVolunteer(input: LoginVolunteerInput): Promise<{
    volunteer: { id: string; firstName: string; lastName: string; eventId: string };
    tokens: TokenPair;
  }> {
    const result = loginVolunteerSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerId, token } = result.data;

    // Find volunteer
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { volunteerId },
    });

    if (!volunteer) {
      throw new AuthenticationError('Invalid volunteer ID or token');
    }

    // Verify token
    const isValid = await verifyPassword(token, volunteer.tokenHash);
    if (!isValid) {
      throw new AuthenticationError('Invalid volunteer ID or token');
    }

    // Generate tokens
    const tokens = generateTokens({
      sub: volunteer.id,
      type: 'volunteer',
    });

    // Store refresh token
    await this.tokenService.createRefreshToken(tokens.refreshToken, volunteer.id, 'volunteer');

    return {
      volunteer: {
        id: volunteer.id,
        firstName: volunteer.firstName,
        lastName: volunteer.lastName,
        eventId: volunteer.eventId,
      },
      tokens,
    };
  }

  async getVolunteer(volunteerId: string) {
    return this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
      include: {
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

    return this.prisma.volunteer.findMany({
      where,
      include: {
        department: true,
        role: true,
      },
      orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
    });
  }

  async updateVolunteer(volunteerId: string, input: Partial<CreateVolunteerInput>) {
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
    });

    if (!volunteer) {
      throw new NotFoundError('Volunteer');
    }

    return this.prisma.volunteer.update({
      where: { id: volunteerId },
      data: {
        firstName: input.firstName,
        lastName: input.lastName,
        email: input.email,
        phone: input.phone,
        congregation: input.congregation,
        appointmentStatus: input.appointmentStatus,
        notes: input.notes,
        departmentId: input.departmentId,
        roleId: input.roleId,
      },
      include: {
        department: true,
        role: true,
      },
    });
  }

  async deleteVolunteer(volunteerId: string) {
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
    });

    if (!volunteer) {
      throw new NotFoundError('Volunteer');
    }

    await this.prisma.volunteer.delete({
      where: { id: volunteerId },
    });

    return true;
  }

  async regenerateCredentials(volunteerId: string): Promise<{
    volunteerId: string;
    token: string;
  }> {
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
    });

    if (!volunteer) {
      throw new NotFoundError('Volunteer');
    }

    const credentials = await generateVolunteerCredentials();

    await this.prisma.volunteer.update({
      where: { id: volunteerId },
      data: {
        volunteerId: credentials.volunteerId,
        tokenHash: credentials.tokenHash,
      },
    });

    // Revoke any existing refresh tokens
    await this.tokenService.revokeAllUserTokens(volunteerId, 'volunteer');

    return {
      volunteerId: credentials.volunteerId,
      token: credentials.token,
    };
  }
}

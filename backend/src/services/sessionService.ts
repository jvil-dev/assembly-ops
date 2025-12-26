/**
 * Session Service
 *
 * Business logic for managing sessions within events.
 * Sessions are event-wide time blocks (e.g., "Friday Morning", "Saturday Afternoon").
 * All departments share the same sessions — they define when volunteers can be scheduled.
 *
 * Operations:
 *   - createSession: Create single session for an event
 *   - createSessions: Bulk create multiple sessions
 *   - updateSession: Update session details (name, date, times)
 *   - deleteSession: Remove a session
 *   - getSession: Fetch single session with event info and assignment count
 *   - getEventSessions: List all sessions for an event (ordered by date/time)
 *   - getSessionEventId: Get parent eventId for access control
 *
 * Time Handling:
 *   Input times are "HH:MM" strings, converted to Date objects via timeStringToDate.
 *   Sessions ordered by date first, then start time.
 *
 * Used by: Session resolvers
 */
import { PrismaClient, Session } from '@prisma/client';
import { NotFoundError, ValidationError } from '../utils/errors.js';
import { timeStringToDate } from '../utils/time.js';
import {
  createSessionSchema,
  createSessionsSchema,
  updateSessionSchema,
  CreateSessionInput,
  CreateSessionsInput,
  UpdateSessionInput,
} from '../graphql/validators/session.js';

export class SessionService {
  constructor(private prisma: PrismaClient) {}

  async createSession(eventId: string, input: CreateSessionInput): Promise<Session> {
    const result = createSessionSchema.safeParse(input);
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

    return this.prisma.session.create({
      data: {
        name: validated.name,
        date: validated.date,
        startTime: timeStringToDate(validated.startTime),
        endTime: timeStringToDate(validated.endTime),
        eventId,
      },
    });
  }

  async createSessions(input: CreateSessionsInput): Promise<Session[]> {
    const result = createSessionsSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, sessions } = result.data;

    // Verify event exists
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    const createdSessions: Session[] = [];

    for (const sessionInput of sessions) {
      const session = await this.prisma.session.create({
        data: {
          name: sessionInput.name,
          date: sessionInput.date,
          startTime: timeStringToDate(sessionInput.startTime),
          endTime: timeStringToDate(sessionInput.endTime),
          eventId,
        },
      });
      createdSessions.push(session);
    }

    return createdSessions;
  }

  async updateSession(sessionId: string, input: UpdateSessionInput): Promise<Session> {
    const result = updateSessionSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const validated = result.data;

    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new NotFoundError('Session');
    }

    return this.prisma.session.update({
      where: { id: sessionId },
      data: {
        name: validated.name,
        date: validated.date,
        startTime: validated.startTime ? timeStringToDate(validated.startTime) : undefined,
        endTime: validated.endTime ? timeStringToDate(validated.endTime) : undefined,
      },
    });
  }

  async deleteSession(sessionId: string): Promise<boolean> {
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new NotFoundError('Session');
    }

    await this.prisma.session.delete({
      where: { id: sessionId },
    });

    return true;
  }

  async getSession(sessionId: string) {
    return this.prisma.session.findUnique({
      where: { id: sessionId },
      include: {
        event: {
          include: { template: true },
        },
        _count: {
          select: { assignments: true },
        },
      },
    });
  }

  async getEventSessions(eventId: string) {
    return this.prisma.session.findMany({
      where: { eventId },
      include: {
        _count: {
          select: { assignments: true },
        },
      },
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
    });
  }

  /**
   * Get session's eventId for access control
   */
  async getSessionEventId(sessionId: string): Promise<string> {
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
      select: { eventId: true },
    });

    if (!session) {
      throw new NotFoundError('Session');
    }

    return session.eventId;
  }
}

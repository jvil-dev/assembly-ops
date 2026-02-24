/**
 * Post Session Status Service
 *
 * Business logic for seating section status management.
 * Attendants update section status (OPEN/FILLING/FULL) during sessions.
 *
 * Methods:
 *   - updateStatus(updatedById, input): Upsert post/session status
 *   - getStatusesForSession(sessionId): Get all statuses for a session
 *   - getStatusesForEvent(eventId): Get all statuses for an event's sessions
 *
 * Called by: ../graphql/resolvers/postSessionStatus.ts
 */
import { PrismaClient, PostSessionStatus } from '@prisma/client';
import { ValidationError } from '../utils/errors.js';
import {
  updatePostSessionStatusSchema,
  UpdatePostSessionStatusInput,
} from '../graphql/validators/postSessionStatus.js';

export class PostSessionStatusService {
  constructor(private prisma: PrismaClient) {}

  async updateStatus(
    updatedById: string,
    input: UpdatePostSessionStatusInput
  ): Promise<PostSessionStatus> {
    const result = updatePostSessionStatusSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    return this.prisma.postSessionStatus.upsert({
      where: {
        postId_sessionId: {
          postId: result.data.postId,
          sessionId: result.data.sessionId,
        },
      },
      update: {
        status: result.data.status,
        updatedById,
      },
      create: {
        postId: result.data.postId,
        sessionId: result.data.sessionId,
        status: result.data.status,
        updatedById,
      },
      include: { post: true, session: true },
    });
  }

  async getStatusesForSession(sessionId: string): Promise<PostSessionStatus[]> {
    return this.prisma.postSessionStatus.findMany({
      where: { sessionId },
      include: { post: true, session: true },
      orderBy: { post: { sortOrder: 'asc' } },
    });
  }

  async getStatusesForEvent(eventId: string): Promise<PostSessionStatus[]> {
    return this.prisma.postSessionStatus.findMany({
      where: { session: { eventId } },
      include: { post: true, session: true },
      orderBy: [{ session: { date: 'asc' } }, { post: { sortOrder: 'asc' } }],
    });
  }
}

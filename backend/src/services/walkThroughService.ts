/**
 * Walk-Through Completion Service
 *
 * Business logic for walk-through checklist persistence.
 * Captains complete walk-throughs before each session and submit results.
 *
 * Methods:
 *   - submitCompletion(eventVolunteerId, input): Record a walk-through completion
 *   - getCompletions(eventId, sessionId?): Get completions for an event (optionally filtered by session)
 *   - getMyCompletions(eventVolunteerId): Get volunteer's own completions
 *
 * Called by: ../graphql/resolvers/walkThrough.ts
 */
import { PrismaClient, WalkThroughCompletion } from '@prisma/client';
import { ValidationError } from '../utils/errors.js';
import {
  submitWalkThroughCompletionSchema,
  SubmitWalkThroughCompletionInput,
} from '../graphql/validators/walkThrough.js';

export class WalkThroughService {
  constructor(private prisma: PrismaClient) {}

  async submitCompletion(
    eventVolunteerId: string,
    input: SubmitWalkThroughCompletionInput
  ): Promise<WalkThroughCompletion> {
    const result = submitWalkThroughCompletionSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    return this.prisma.walkThroughCompletion.create({
      data: {
        eventId: result.data.eventId,
        sessionId: result.data.sessionId,
        eventVolunteerId,
        itemCount: result.data.itemCount,
        notes: result.data.notes,
      },
      include: { session: true, eventVolunteer: true },
    });
  }

  async getCompletions(
    eventId: string,
    sessionId?: string
  ): Promise<WalkThroughCompletion[]> {
    return this.prisma.walkThroughCompletion.findMany({
      where: { eventId, ...(sessionId ? { sessionId } : {}) },
      include: { session: true, eventVolunteer: true },
      orderBy: { completedAt: 'desc' },
    });
  }

  async getMyCompletions(eventVolunteerId: string): Promise<WalkThroughCompletion[]> {
    return this.prisma.walkThroughCompletion.findMany({
      where: { eventVolunteerId },
      include: { session: true },
      orderBy: { completedAt: 'desc' },
    });
  }
}

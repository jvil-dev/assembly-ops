/**
 * GraphQL Context
 *
 * Created fresh for each request. Identifies the caller via JWT and
 * attaches user or eventVolunteer info for guards and resolvers to use.
 *
 * Token types:
 *   'user'           → logged-in User (volunteer or overseer) → context.user
 *   'eventVolunteer' → printed-card event-day session         → context.volunteer
 */
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import prisma from '../config/database.js';
import { extractTokenFromHeader, verifyAccessToken } from '../utils/jwt.js';

export interface UserContext {
  id: string;
  userId: string; // 6-char permanent ID
  email: string;
  isOverseer: boolean;
}

export interface VolunteerContext {
  id: string;
  eventId: string;
  departmentId?: string;
}

export interface Context {
  prisma: PrismaClient;
  req: Request;
  res: Response;
  user?: UserContext;         // Logged-in User (volunteer or overseer)
  volunteer?: VolunteerContext; // EventVolunteer printed-card session
  // Legacy aliases kept so existing guards/resolvers compile during migration
  admin?: UserContext;
}

export async function createContext({
  req,
  res,
}: {
  req: Request;
  res: Response;
}): Promise<Context> {
  const context: Context = { prisma, req, res };

  const token = extractTokenFromHeader(req.headers.authorization);
  if (!token) return context;

  try {
    const payload = verifyAccessToken(token);

    if (payload.type === 'user') {
      const user = await prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, userId: true, email: true, isOverseer: true },
      });

      if (user) {
        context.user = user;
        context.admin = user; // backward-compat alias
      }
    } else if (payload.type === 'eventVolunteer') {
      const ev = await prisma.eventVolunteer.findUnique({
        where: { id: payload.sub },
        select: { id: true, eventId: true, departmentId: true },
      });

      if (ev) {
        context.volunteer = {
          id: ev.id,
          eventId: ev.eventId,
          departmentId: ev.departmentId || undefined,
        };
      }
    }
  } catch {
    // Invalid token — continue without auth context
  }

  return context;
}

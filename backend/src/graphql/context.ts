/**
 * GraphQL Context
 *
 * The context is an object that's available to every resolver. It's created
 * fresh for each request and contains:
 *   - prisma: Database client for queries
 *   - req/res: Express request/response objects
 *   - admin: If an admin is logged in, their id and email
 *   - volunteer: If a volunteer is logged in, their id, eventId, departmentId
 *
 * How it works:
 *   1. Every request hits createContext() before reaching resolvers
 *   2. We extract the JWT from the Authorization header
 *   3. We verify and decode the token to identify the user
 *   4. We attach admin or volunteer info to the context
 *   5. Resolvers can then check context.admin or context.volunteer
 *
 * Used by:
 *   - ./guards/auth.ts: Checks context.admin/volunteer for authorization
 *   - ./resolvers/*: Access prisma and auth info via context
 *
 * Called by: Apollo Server (./index.ts) on every request
 */
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import prisma from '../config/database.js';
import { extractTokenFromHeader, verifyAccessToken } from '../utils/jwt.js';

export interface AdminContext {
  id: string;
  email: string;
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
  admin?: AdminContext;
  volunteer?: VolunteerContext;
}

export async function createContext({
  req,
  res,
}: {
  req: Request;
  res: Response;
}): Promise<Context> {
  const context: Context = {
    prisma,
    req,
    res,
  };

  const token = extractTokenFromHeader(req.headers.authorization);

  if (token) {
    try {
      const payload = verifyAccessToken(token);

      if (payload.type === 'admin') {
        context.admin = {
          id: payload.sub,
          email: payload.email || '',
        };
      } else if (payload.type === 'volunteer') {
        const volunteer = await prisma.volunteer.findUnique({
          where: { id: payload.sub },
          select: { id: true, eventId: true, departmentId: true },
        });

        if (volunteer) {
          context.volunteer = {
            id: volunteer.id,
            eventId: volunteer.eventId,
            departmentId: volunteer.departmentId || undefined,
          };
        }
      }
    } catch {
      // Invalid token - continue without auth context
    }
  }

  return context;
}

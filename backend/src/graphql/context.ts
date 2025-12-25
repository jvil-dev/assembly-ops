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

import { Request, Response } from 'express';
import prisma from '../config/database.js';
import { PrismaClient } from '@prisma/client';

export interface AdminContext {
  id: string;
  email: string;
  adminType: string;
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
  return {
    prisma,
    req,
    res,
  };
}

import { z } from 'zod';
import { DepartmentType } from '@prisma/client';

export const activateEventSchema = z.object({
  templateId: z.string().min(1, 'Template ID is required'),
});

export const joinEventSchema = z.object({
  joinCode: z.string().min(1, 'Join code is required'),
});

export const claimDepartmentSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  departmentType: z.nativeEnum(DepartmentType, {
    error: 'Invalid department type',
  }),
});

export type ActivateEventInput = z.infer<typeof activateEventSchema>;
export type JoinEventInput = z.infer<typeof joinEventSchema>;
export type ClaimDepartmentInput = z.infer<typeof claimDepartmentSchema>;

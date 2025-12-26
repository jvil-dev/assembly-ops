import { z } from 'zod';
import { AppointmentStatus } from '@prisma/client';

export const createVolunteerSchema = z.object({
  firstName: z
    .string()
    .min(1, 'First name is required')
    .max(50, 'First name too long')
    .transform((v: string) => v.trim()),
  lastName: z
    .string()
    .min(1, 'Last name is required')
    .max(50, 'Last name too long')
    .transform((v: string) => v.trim()),
  email: z
    .string()
    .email('Invalid email')
    .nullish()
    .transform((v: string | null | undefined) => v?.toLowerCase().trim() || null),
  phone: z
    .string()
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  congregation: z
    .string()
    .min(1, 'Congregation is required')
    .max(100, 'Congregation name too long')
    .transform((v: string) => v.trim()),
  appointmentStatus: z.nativeEnum(AppointmentStatus).nullish(),
  notes: z
    .string()
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  departmentId: z.string().nullish(),
  roleId: z.string().nullish(),
});

export const createVolunteersSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  volunteers: z.array(createVolunteerSchema).min(1, 'At least one volunteer required'),
});

export const loginVolunteerSchema = z.object({
  volunteerId: z
    .string()
    .min(1, 'Volunteer ID is required')
    .transform((v: string) => v.toUpperCase().trim()),
  token: z
    .string()
    .min(1, 'Token is required')
    .transform((v: string) => v.toUpperCase().trim()),
});

export type CreateVolunteerInput = z.infer<typeof createVolunteerSchema>;
export type CreateVolunteersInput = z.infer<typeof createVolunteersSchema>;
export type LoginVolunteerInput = z.infer<typeof loginVolunteerSchema>;

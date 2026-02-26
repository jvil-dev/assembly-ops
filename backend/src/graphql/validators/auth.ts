/**
 * Auth Validators (Zod Schemas)
 *
 * Runtime validation for unified authentication inputs.
 * Validates and normalizes data before it reaches the service layer.
 */
import { z } from 'zod';

export const registerUserSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .transform((v: string) => v.toLowerCase().trim()),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
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
  phone: z.string().optional(),
  congregation: z.string().optional(),
  congregationId: z.string().optional(),
  appointmentStatus: z.enum(['PUBLISHER', 'MINISTERIAL_SERVANT', 'ELDER']).optional(),
  isOverseer: z.boolean().optional(),
});

export const loginUserSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .transform((v: string) => v.toLowerCase().trim()),
  password: z.string().min(1, 'Password is required'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

export const loginEventVolunteerSchema = z.object({
  volunteerId: z.string().min(1, 'Volunteer ID is required'),
  token: z.string().min(1, 'Token is required'),
});

export type RegisterUserInput = z.infer<typeof registerUserSchema>;
export type LoginUserInput = z.infer<typeof loginUserSchema>;
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;
export type LoginEventVolunteerInput = z.infer<typeof loginEventVolunteerSchema>;

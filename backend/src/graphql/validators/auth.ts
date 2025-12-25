import { z } from 'zod';

export const registerAdminSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .transform((v) => v.toLowerCase().trim()),
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
    .transform((v) => v.trim()),
  lastName: z
    .string()
    .min(1, 'Last name is required')
    .max(50, 'Last name too long')
    .transform((v) => v.trim()),
  phone: z
    .string()
    .nullish()
    .transform((v) => v?.trim() || null),
  congregation: z
    .string()
    .min(1, 'Congregation is required')
    .max(100, 'Congregation name too long')
    .transform((v) => v.trim()),
});

export const loginAdminSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .transform((v) => v.toLowerCase().trim()),
  password: z.string().min(1, 'Password is required'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

export type RegisterAdminInput = z.infer<typeof registerAdminSchema>;
export type LoginAdminInput = z.infer<typeof loginAdminSchema>;
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;

/**
 * Auth Validators (Zod Schemas)
 *
 * Runtime validation for authentication inputs. These schemas validate and
 * transform data BEFORE it reaches the service layer.
 *
 * Schemas:
 *   - registerAdminSchema: Validates registration (email, password rules, name, congregation)
 *   - loginAdminSchema: Validates login (email, password)
 *   - refreshTokenSchema: Validates token refresh
 *
 * What Zod does:
 *   1. Validates: Checks required fields, formats (email), lengths, patterns
 *   2. Transforms: Normalizes data (lowercase email, trim whitespace)
 *   3. Types: Exports TypeScript types via z.infer<>
 *
 * Password requirements:
 *   - Minimum 8 characters
 *   - At least one uppercase letter
 *   - At least one lowercase letter
 *   - At least one number
 *
 * Used by: ../../services/authService.ts (validates input before processing)
 */
import { z } from 'zod';

export const registerAdminSchema = z.object({
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
  phone: z
    .string()
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  congregation: z
    .string()
    .min(1, 'Congregation is required')
    .max(100, 'Congregation name too long')
    .transform((v: string) => v.trim()),
});

export const loginAdminSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .transform((v: string) => v.toLowerCase().trim()),
  password: z.string().min(1, 'Password is required'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

export type RegisterAdminInput = z.infer<typeof registerAdminSchema>;
export type LoginAdminInput = z.infer<typeof loginAdminSchema>;
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;

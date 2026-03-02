/**
 * Admin Import Validators
 *
 * Zod schemas for validating individual CSV rows in the admin import pipeline.
 * Each schema validates a single row of data after CSV parsing.
 *
 * Used by: services/adminService.ts
 */
import { z } from 'zod';

// ─── Required Headers ─────────────────────────────────────────────────

export const CONGREGATION_REQUIRED_HEADERS = ['name', 'state', 'circuitCode'];
export const EVENT_REQUIRED_HEADERS = ['eventType', 'region', 'serviceYear', 'name', 'venue', 'address', 'startDate', 'endDate'];
export const VOLUNTEER_REQUIRED_HEADERS = ['firstName', 'lastName', 'congregation'];

// ─── Row Schemas ──────────────────────────────────────────────────────

export const congregationRowSchema = z.object({
  name: z.string().min(1, 'Congregation name is required'),
  state: z.string().min(1, 'State is required'),
  circuitCode: z.string().min(1, 'Circuit code is required'),
  language: z.string().default('en'),
});

export const eventRowSchema = z.object({
  eventType: z.enum(['CIRCUIT_ASSEMBLY_CO', 'CIRCUIT_ASSEMBLY_BR', 'REGIONAL_CONVENTION', 'SPECIAL_CONVENTION'], {
    message: 'Invalid event type',
  }),
  circuitCode: z.string().optional().default(''),
  region: z.string().min(1, 'Region is required'),
  serviceYear: z.string().min(1, 'Service year is required').transform(Number),
  name: z.string().min(1, 'Event name is required'),
  theme: z.string().optional().default(''),
  themeScripture: z.string().optional().default(''),
  venue: z.string().min(1, 'Venue is required'),
  address: z.string().min(1, 'Address is required'),
  startDate: z.string().min(1, 'Start date is required'),
  endDate: z.string().min(1, 'End date is required'),
  language: z.string().optional().default('en'),
});

export const volunteerRowSchema = z.object({
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  congregation: z.string().min(1, 'Congregation is required'),
  email: z.string().email().optional().or(z.literal('')),
  phone: z.string().optional().default(''),
  appointmentStatus: z.enum(['PUBLISHER', 'MINISTERIAL_SERVANT', 'ELDER']).optional(),
});

// ─── Types ────────────────────────────────────────────────────────────

export type CongregationRow = z.infer<typeof congregationRowSchema>;
export type EventRow = z.infer<typeof eventRowSchema>;
export type VolunteerRow = z.infer<typeof volunteerRowSchema>;

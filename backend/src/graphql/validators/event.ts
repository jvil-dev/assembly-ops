/**
 * Event Validators (Zod Schemas)
 *
 * Runtime validation for event-related inputs.
 *
 * Schemas:
 *   - activateEventSchema: Validates event activation (templateId required)
 *   - joinEventSchema: Validates joining an event (joinCode required)
 *   - claimDepartmentSchema: Validates department claiming (eventId + departmentType)
 *   - promoteToAppAdminSchema: Validates admin promotion (eventId + adminId)
 *
 * Note on nativeEnum:
 *   z.nativeEnum(DepartmentType) validates against Prisma's enum values.
 *   This ensures only valid department types (ATTENDANT, PARKING, etc.) are accepted.
 *
 * Used by: ../../services/eventService.ts
 */
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

export const promoteToAppAdminSchema = z.object({
  eventId: z.string().cuid('Invalid event ID format'),
  adminId: z.string().cuid('Invalid admin ID format'),
});

export type ActivateEventInput = z.infer<typeof activateEventSchema>;
export type JoinEventInput = z.infer<typeof joinEventSchema>;
export type ClaimDepartmentInput = z.infer<typeof claimDepartmentSchema>;
export type PromoteToAppAdminInput = z.infer<typeof promoteToAppAdminSchema>;

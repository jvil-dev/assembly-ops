/**
 * Event Validators (Zod Schemas)
 *
 * Runtime validation for event-related inputs.
 *
 * Schemas:
 *   - purchaseDepartmentSchema: Validates department purchase (eventId + departmentType)
 *   - joinDepartmentByCodeSchema: Validates joining by access code
 *   - assignHierarchyRoleSchema: Validates hierarchy role assignment
 *
 * Used by: ../../services/eventService.ts
 */
import { z } from 'zod';
import { DepartmentType } from '@prisma/client';

export const purchaseDepartmentSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  departmentType: z.nativeEnum(DepartmentType, {
    error: 'Invalid department type',
  }),
});

export const joinDepartmentByCodeSchema = z.object({
  accessCode: z.string().min(5, 'Access code is required').max(12, 'Access code too long'),
});

export const assignHierarchyRoleSchema = z.object({
  departmentId: z.string().min(1, 'Department ID is required'),
  eventVolunteerId: z.string().min(1, 'Event Volunteer ID is required'),
  hierarchyRole: z.enum(['ASSISTANT_OVERSEER'], {
    error: 'Invalid hierarchy role',
  }),
});

export type PurchaseDepartmentInput = z.infer<typeof purchaseDepartmentSchema>;
export type JoinDepartmentByCodeInput = z.infer<typeof joinDepartmentByCodeSchema>;
export type AssignHierarchyRoleInput = z.infer<typeof assignHierarchyRoleSchema>;

/**
 * Audio/Video Department Input Validators
 *
 * Zod schemas for validating AV department inputs before processing.
 *
 * Schemas:
 *   - createAVEquipmentSchema: Equipment name, category, condition, optional model/serial/location
 *   - bulkCreateAVEquipmentSchema: Array of equipment items (min 1)
 *   - updateAVEquipmentSchema: Partial equipment fields
 *   - checkoutEquipmentSchema: Equipment ID, volunteer, optional session/notes
 *   - reportAVDamageSchema: Equipment ID, description, severity
 *   - createAVHazardAssessmentSchema: Title, hazard type, description, controls, PPE
 *   - createAVSafetyBriefingSchema: Topic, optional notes, attendee IDs (min 1)
 *
 * Business Rules Enforced:
 *   - Name/title/topic max 200 chars
 *   - Description/controls/notes max 2000 chars
 *   - Serial number max 100 chars
 *   - At least one attendee required for briefings
 *   - At least one item required for bulk create
 *
 * Used by: ../../services/audioVideoService.ts
 */
import { z } from 'zod';

const avEquipmentCategories = [
  'CAMERA_PTZ',
  'CAMERA_MANNED',
  'TRIPOD',
  'AUDIO_MIXER',
  'VIDEO_SWITCHER',
  'MEDIA_PLAYER',
  'LED_PANEL',
  'LOUDSPEAKER',
  'MICROPHONE',
  'STAGE_MONITOR',
  'INTERCOM',
  'CABLE',
  'STAGE_LIGHTING',
  'RECORDING_DEVICE',
  'ASSISTIVE_LISTENING',
  'ACCESSORY',
] as const;

const avEquipmentConditions = ['GOOD', 'NEEDS_REPAIR', 'OUT_OF_SERVICE'] as const;

const avDamageSeverities = ['MINOR', 'MODERATE', 'SEVERE'] as const;

const avHazardTypes = [
  'WORKING_AT_HEIGHT',
  'ELECTRICAL_EXPOSURE',
  'ELEVATED_PLATFORM',
  'POWER_TOOLS',
  'MOVING_EQUIPMENT',
  'NEAR_STAIRS',
  'UNEVEN_SURFACE',
  'HEAVY_LIFTING',
  'PINCH_CRUSH_CUT',
  'EXTREME_CONDITIONS',
] as const;

// ── Equipment ──────────────────────────────────────────

const equipmentItemFields = z.object({
  name: z.string().min(1).max(200),
  category: z.enum(avEquipmentCategories),
  condition: z.enum(avEquipmentConditions).optional(),
  model: z.string().max(200).optional(),
  serialNumber: z.string().max(100).optional(),
  location: z.string().max(200).optional(),
  notes: z.string().max(2000).optional(),
  areaId: z.string().min(1).optional(),
});

export const createAVEquipmentSchema = equipmentItemFields.extend({
  eventId: z.string().min(1),
});

export const bulkCreateAVEquipmentSchema = z.object({
  eventId: z.string().min(1),
  items: z.array(equipmentItemFields).min(1),
});

export const updateAVEquipmentSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  category: z.enum(avEquipmentCategories).optional(),
  condition: z.enum(avEquipmentConditions).optional(),
  model: z.string().max(200).nullable().optional(),
  serialNumber: z.string().max(100).nullable().optional(),
  location: z.string().max(200).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
  areaId: z.string().min(1).nullable().optional(),
});

// ── Checkout ───────────────────────────────────────────

export const checkoutEquipmentSchema = z.object({
  equipmentId: z.string().min(1),
  checkedOutById: z.string().min(1),
  sessionId: z.string().min(1).optional(),
  notes: z.string().max(2000).optional(),
});

// ── Damage ─────────────────────────────────────────────

export const reportAVDamageSchema = z.object({
  equipmentId: z.string().min(1),
  description: z.string().min(1).max(2000),
  severity: z.enum(avDamageSeverities),
  sessionId: z.string().min(1).optional(),
});

// ── Safety ─────────────────────────────────────────────

export const createAVHazardAssessmentSchema = z.object({
  eventId: z.string().min(1),
  title: z.string().min(1).max(200),
  hazardType: z.enum(avHazardTypes),
  description: z.string().min(1).max(2000),
  controls: z.string().min(1).max(2000),
  ppeRequired: z.array(z.string().min(1)),
  sessionId: z.string().min(1).optional(),
});

export const createAVSafetyBriefingSchema = z.object({
  eventId: z.string().min(1),
  topic: z.string().min(1).max(200),
  notes: z.string().max(2000).optional(),
  attendeeIds: z.array(z.string().min(1)).min(1),
});

// ── Exported Types ─────────────────────────────────────

export type CreateAVEquipmentInput = z.infer<typeof createAVEquipmentSchema>;
export type BulkCreateAVEquipmentInput = z.infer<typeof bulkCreateAVEquipmentSchema>;
export type UpdateAVEquipmentInput = z.infer<typeof updateAVEquipmentSchema>;
export type CheckoutEquipmentInput = z.infer<typeof checkoutEquipmentSchema>;
export type ReportAVDamageInput = z.infer<typeof reportAVDamageSchema>;
export type CreateAVHazardAssessmentInput = z.infer<typeof createAVHazardAssessmentSchema>;
export type CreateAVSafetyBriefingInput = z.infer<typeof createAVSafetyBriefingSchema>;

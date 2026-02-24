/**
 * Credential Generation Utilities
 *
 * Generates secure volunteer IDs and tokens for event authentication.
 *
 * NEW EventVolunteer Format (Sprint 6.3):
 *   - volunteerId: [PREFIX]-[6 alphanumeric chars]
 *     - CA = Circuit Assembly
 *     - RC = Regional Convention
 *     Example: CA-A7X9K2, RC-B3M8P1
 *   - token: 32 characters, cryptographically secure
 *
 * LEGACY Volunteer Format (kept for backward compatibility):
 *   - volunteerId: "VOL-XXXXXX" (6 alphanumeric chars after prefix)
 *   - token: 8 hex characters (e.g., "A1B2C3D4")
 *
 * Character Set:
 *   Uses ABCDEFGHJKLMNPQRSTUVWXYZ23456789 (removes ambiguous: 0, O, I, 1)
 *   This makes it easier to read/type from printed cards.
 *
 * Security:
 *   - Plain token is ONLY returned once (at creation)
 *   - Only the bcrypt hash (tokenHash) is stored in database
 *   - If volunteer loses credentials, use regenerateCredentials()
 *
 * Used by:
 *   - VolunteerService (legacy Volunteer model)
 *   - volunteerProfileResolvers (new EventVolunteer model)
 */
import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { hashPassword } from './password.js';

// Characters for volunteer ID suffix (removed confusing: I, O, 0, 1)
const ID_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

// ============================================
// NEW: EventVolunteer Credential Functions
// ============================================

/**
 * Generate a volunteer ID with event-type prefix
 * Format: [PREFIX]-[6 alphanumeric chars]
 * Example: CA-A7X9K2, RC-B3M8P1
 */
export function generateEventVolunteerId(prefix: 'CA' | 'RC'): string {
  let suffix = '';

  for (let i = 0; i < 6; i++) {
    suffix += ID_CHARS.charAt(crypto.randomInt(ID_CHARS.length));
  }

  return `${prefix}-${suffix}`;
}

/**
 * Generate a secure random token using the unambiguous character set
 * 8 characters, easy to read/type from printed cards
 * Combined with volunteerId, provides sufficient entropy for login
 */
export function generateToken(): string {
  let token = '';
  for (let i = 0; i < 8; i++) {
    token += ID_CHARS.charAt(crypto.randomInt(ID_CHARS.length));
  }
  return token;
}

/**
 * Hash a token using bcrypt
 */
export async function hashToken(token: string): Promise<string> {
  return bcrypt.hash(token, 10);
}

/**
 * Verify a token against its hash
 */
export async function verifyToken(token: string, hash: string): Promise<boolean> {
  return bcrypt.compare(token, hash);
}

// ============================================
// TOKEN ENCRYPTION (delegates to encryption.ts)
// ============================================
import { encryptField, decryptField } from './encryption.js';

/**
 * Encrypt a volunteer token using AES-256-GCM
 * @deprecated Use encryptField() from encryption.ts directly
 */
export function encryptToken(plainToken: string): string {
  return encryptField(plainToken);
}

/**
 * Decrypt an AES-256-GCM encrypted token
 * @deprecated Use decryptField() from encryption.ts directly
 */
export function decryptToken(encryptedToken: string): string {
  return decryptField(encryptedToken);
}

// ============================================
// LEGACY: Volunteer Credential Functions
// (kept for backward compatibility during migration)
// ============================================

/**
 * Generates a volunteer ID like "VOL-A1B2C3"
 * @deprecated Use generateEventVolunteerId() for new EventVolunteer model
 */
export function generateVolunteerId(): string {
  let id = '';
  for (let i = 0; i < 6; i++) {
    id += ID_CHARS.charAt(crypto.randomInt(ID_CHARS.length));
  }
  return `VOL-${id}`;
}

/**
 * Generates a random token for volunteer login
 * @deprecated Use generateToken() for new EventVolunteer model
 */
export function generateLoginToken(): string {
  return crypto.randomBytes(4).toString('hex').toUpperCase(); // 8 chars like "A1B2C3D4"
}

/**
 * Generates volunteer credentials (ID + token + hash)
 * @deprecated Use generateEventVolunteerId() + generateToken() + hashToken() for new model
 */
export async function generateVolunteerCredentials(): Promise<{
  volunteerId: string;
  token: string;
  tokenHash: string;
}> {
  const volunteerId = generateVolunteerId();
  const token = generateLoginToken();
  const tokenHash = await hashPassword(token);

  return {
    volunteerId,
    token, // Return plain token to give to volunteer (only time it's visible)
    tokenHash, // Store this in DB
  };
}

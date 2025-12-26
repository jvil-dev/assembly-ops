/**
 * Volunteer Credentials Generator
 *
 * Generates unique login credentials for volunteers. Unlike admins who use
 * email/password, volunteers get a generated ID + token that can be printed
 * on cards or sent via SMS.
 *
 * Credential Format:
 *   - volunteerId: "VOL-XXXXXX" (6 alphanumeric chars after prefix)
 *   - token: 8 hex characters (e.g., "A1B2C3D4")
 *
 * Character Set:
 *   Uses ABCDEFGHJKLMNPQRSTUVWXYZ23456789 (removes ambiguous: 0, O, I, 1)
 *   This makes it easier to read/type from printed cards.
 *
 * Functions:
 *   - generateVolunteerId(): Creates "VOL-XXXXXX" ID
 *   - generateLoginToken(): Creates 8-char hex token
 *   - generateVolunteerCredentials(): Returns { volunteerId, token, tokenHash }
 *
 * Security:
 *   - Plain token is ONLY returned once (at creation)
 *   - Only the bcrypt hash (tokenHash) is stored in database
 *   - If volunteer loses credentials, use regenerateCredentials()
 *
 * Used by: VolunteerService.createVolunteer(), regenerateCredentials()
 */
import crypto from 'crypto';
import { hashPassword } from './password.js';

/**
 * Generates a volunteer ID like "VOL-A1B2C3"
 */
export function generateVolunteerId(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous: 0, O, I, 1
  let id = '';
  for (let i = 0; i < 6; i++) {
    id += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `VOL-${id}`;
}

/**
 * Generates a random token for volunteer login
 */
export function generateLoginToken(): string {
  return crypto.randomBytes(4).toString('hex').toUpperCase(); // 8 chars like "A1B2C3D4"
}

/**
 * Generates volunteer credentials (ID + token + hash)
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

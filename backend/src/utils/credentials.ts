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

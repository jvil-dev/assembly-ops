/**
 * Password Hashing Utilities
 *
 * Secure password hashing using bcrypt. Used for both admin passwords
 * and volunteer login tokens.
 *
 * Functions:
 *   - hashPassword(password): Hash a password with salt (12 rounds)
 *   - verifyPassword(password, hash): Compare password against hash
 *
 * Security:
 *   - Salt rounds: 12 (good balance of security vs performance)
 *   - Each hash includes a unique salt (stored in the hash itself)
 *   - Timing-safe comparison (prevents timing attacks)
 *
 * Usage:
 *   const hash = await hashPassword('myPassword123');  // Store this
 *   const isValid = await verifyPassword('myPassword123', hash);  // true
 *
 * Used by:
 *   - AuthService: Admin password hashing/verification
 *   - VolunteerService: Volunteer token hashing/verification
 *   - credentials.ts: Hashing generated volunteer tokens
 */
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 12;

export async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(SALT_ROUNDS);
  return bcrypt.hash(password, salt);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

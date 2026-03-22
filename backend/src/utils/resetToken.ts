/**
 * Password Reset Token Utilities
 *
 * Generates and hashes 6-digit reset codes for the forgot password flow.
 *
 * Functions:
 *   - generateResetCode(): Cryptographically random 6-digit numeric code
 *   - hashResetCode(code): SHA-256 hash for secure DB storage
 *
 * Called by: ../services/authService.ts
 */
import crypto from 'crypto';

export function generateResetCode(): string {
  return crypto.randomInt(100000, 999999).toString();
}

export function hashResetCode(code: string): string {
  return crypto.createHash('sha256').update(code).digest('hex');
}

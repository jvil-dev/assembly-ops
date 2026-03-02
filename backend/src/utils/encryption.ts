/**
 * Field-Level Encryption Utilities (AES-256-GCM)
 *
 * Provides authenticated encryption for sensitive PII fields stored in the database.
 * Uses AES-256-GCM (Galois/Counter Mode) which provides both confidentiality and
 * integrity — encrypted data cannot be forged or tampered with.
 *
 * Used for:
 *   - EventVolunteer.encryptedToken (login credential)
 *   - LostPersonAlert PII (personName, contactName, contactPhone)
 *   - OAuthConnection.encryptedEmail
 *
 * Format: Base64 string containing [IV (12 bytes)][authTag (16 bytes)][ciphertext]
 *
 * Environment Variables:
 *   - PII_ENCRYPTION_KEY: 64-character hex string (32 bytes) for AES-256
 *     Falls back to VOLUNTEER_TOKEN_KEY for backward compatibility
 *
 * Used by: volunteerProfileResolvers, attendantService, oauthService, credentials.ts
 */
import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm' as const;
const IV_LENGTH = 12;
const AUTH_TAG_LENGTH = 16;

function getEncryptionKey(): Buffer {
  const keyHex = process.env.PII_ENCRYPTION_KEY || process.env.VOLUNTEER_TOKEN_KEY;
  if (!keyHex || keyHex.length !== 64) {
    throw new Error(
      'PII_ENCRYPTION_KEY (or VOLUNTEER_TOKEN_KEY) must be set as a 64-character hex string'
    );
  }
  return Buffer.from(keyHex, 'hex');
}

/**
 * Encrypt a string value using AES-256-GCM.
 * Returns a base64 string safe for database storage.
 * Each call produces different output (random IV) even for the same input.
 */
export function encryptField(value: string): string {
  const key = getEncryptionKey();
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv, { authTagLength: AUTH_TAG_LENGTH });

  const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();

  return Buffer.concat([iv, authTag, encrypted]).toString('base64');
}

/**
 * Decrypt a base64-encoded AES-256-GCM encrypted value.
 * Throws if the data has been tampered with (auth tag verification).
 */
export function decryptField(encrypted: string): string {
  const key = getEncryptionKey();
  const data = Buffer.from(encrypted, 'base64');

  const iv = data.subarray(0, IV_LENGTH);
  const authTag = data.subarray(IV_LENGTH, IV_LENGTH + AUTH_TAG_LENGTH);
  const ciphertext = data.subarray(IV_LENGTH + AUTH_TAG_LENGTH);

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv, { authTagLength: AUTH_TAG_LENGTH });
  decipher.setAuthTag(authTag);

  return decipher.update(ciphertext, undefined, 'utf8') + decipher.final('utf8');
}

/**
 * Validate that the encryption key is configured at startup.
 */
export function validateEncryptionKey(): void {
  const keyHex = process.env.PII_ENCRYPTION_KEY || process.env.VOLUNTEER_TOKEN_KEY;
  if (!keyHex) {
    throw new Error('PII_ENCRYPTION_KEY or VOLUNTEER_TOKEN_KEY environment variable is required');
  }
  if (keyHex.length !== 64) {
    throw new Error('Encryption key must be a 64-character hex string (32 bytes)');
  }
}

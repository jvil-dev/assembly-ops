/**
 * Credential Generation Utilities
 *
 * User ID Format (global, permanent):
 *   - userId: 6 alphanumeric chars, no prefix — e.g. "A7X9K2"
 *   - Assigned once at User creation, never changes
 *   - Volunteers share this ID with overseers to be added to events
 *
 * Character Set:
 *   Uses ABCDEFGHJKLMNPQRSTUVWXYZ23456789 (removes ambiguous: 0, O, I, 1)
 */
import crypto from 'crypto';

// Characters for ID generation (removed confusing: I, O, 0, 1)
const ID_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/**
 * Generate a 6-char alphanumeric User ID
 * This is the user's permanent global identity — assigned at account creation
 * Example: "A7X9K2"
 */
export function generateUserId(): string {
  let id = '';
  for (let i = 0; i < 6; i++) {
    id += ID_CHARS.charAt(crypto.randomInt(ID_CHARS.length));
  }
  return id;
}

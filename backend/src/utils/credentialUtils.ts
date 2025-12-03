import crypto from "crypto";

/**
 * Generates a volunteer ID in format: VOL-XXXXXX
 * 6 alphanumeric characters, uppercase
 */
export function generateVolunteerId(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let id = "VOL-";
  for (let i = 0; i < 6; i++) {
    const randomIndex = crypto.randomInt(0, chars.length);
    id += chars[randomIndex];
  }
  return id;
}

/**
 * Generates a secure login token
 * 32 character hex string
 */
export function generateLoginToken(): string {
  return crypto.randomBytes(16).toString("hex");
}

/**
 * Generates both credentials as a pair
 */

export function generateCredentials(): {
  generatedId: string;
  loginToken: string;
} {
  return {
    generatedId: generateVolunteerId(),
    loginToken: generateLoginToken(),
  };
}

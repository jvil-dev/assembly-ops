// Password hashing utilities

import bcrypt from "bcrypt";

const SALT_ROUNDS = 10;

export async function hashPassword(password: string): Promise<string> {
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
  return hashedPassword;
}

export async function comparePassword(
  password: string,
  hash: string
): Promise<boolean> {
  const isMatch = await bcrypt.compare(password, hash);
  return isMatch;
}

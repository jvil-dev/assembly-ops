import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  throw new Error("JWT_SECRET environment variable is required");
}

const SECRET: string = JWT_SECRET;

export interface TokenPayload {
  id: string;
  email?: string;
  type: "admin" | "volunteer";
  eventId?: string;
}

export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "7d",
  } as any);
}

export function verifyToken(token: string): TokenPayload {
  return jwt.verify(token, SECRET) as TokenPayload;
}

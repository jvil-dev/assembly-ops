import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

export interface TokenPayload {
  id: string;
  email: string;
  type: "admin" | "volunteer";
}

export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  });
}

export function verifyToken(token: string): TokenPayload {
  return jwt.verify(token, JWT_SECRET) as TokenPayload;
}

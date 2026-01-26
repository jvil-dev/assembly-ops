import jwt from 'jsonwebtoken';
import { AuthProvider } from '@prisma/client';

const SECRET = process.env.JWT_SECRET!;

interface PendingOAuthPayload {
  provider: AuthProvider;
  providerId: string;
  email: string;
}

export function generatePendingOAuthToken(payload: PendingOAuthPayload): string {
  return jwt.sign(
    {
      ...payload,
      purpose: 'pending_oauth',
    },
    SECRET,
    { expiresIn: '15m' }
  );
}

export function verifyPendingOAuthToken(token: string): PendingOAuthPayload | null {
  try {
    const payload = jwt.verify(token, SECRET) as jwt.JwtPayload & {
      purpose?: string;
      provider?: AuthProvider;
      providerId?: string;
      email?: string;
    };
    if (payload.purpose !== 'pending_oauth') return null;
    return {
      provider: payload.provider!,
      providerId: payload.providerId!,
      email: payload.email!,
    };
  } catch {
    return null;
  }
}

import jwt, { SignOptions, JwtPayload } from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET!;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET!;

const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

export interface AccessTokenPayload extends JwtPayload {
  sub: string;
  type: 'admin' | 'volunteer';
  email?: string;
}

export interface RefreshTokenPayload extends JwtPayload {
  sub: string;
  type: 'admin' | 'volunteer';
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export function generateTokens(payload: {
  sub: string;
  type: 'admin' | 'volunteer';
  email?: string;
}): TokenPair {
  const accessTokenOptions: SignOptions = {
    expiresIn: ACCESS_TOKEN_EXPIRY,
  };

  const refreshTokenOptions: SignOptions = {
    expiresIn: REFRESH_TOKEN_EXPIRY,
  };

  const accessToken = jwt.sign(
    { sub: payload.sub, type: payload.type, email: payload.email },
    JWT_SECRET,
    accessTokenOptions
  );

  const refreshToken = jwt.sign(
    { sub: payload.sub, type: payload.type },
    JWT_REFRESH_SECRET,
    refreshTokenOptions
  );

  return {
    accessToken,
    refreshToken,
    expiresIn: 15 * 60, // 15 minutes in seconds
  };
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const payload = jwt.verify(token, JWT_SECRET) as AccessTokenPayload;
  return payload;
}

export function verifyRefreshToken(token: string): RefreshTokenPayload {
  const payload = jwt.verify(token, JWT_REFRESH_SECRET) as RefreshTokenPayload;
  return payload;
}

export function extractTokenFromHeader(authHeader?: string): string | null {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.slice(7);
}

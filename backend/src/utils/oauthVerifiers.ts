import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import { AuthenticationError } from './errors.js';

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID!;
const APPLE_CLIENT_ID = process.env.APPLE_CLIENT_ID!;

interface OAuthUserInfo {
  providerId: string;
  email: string;
  firstName?: string;
  lastName?: string;
}

// Google verification
const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

export async function verifyGoogleToken(idToken: string): Promise<OAuthUserInfo> {
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    if (!payload?.email) throw new AuthenticationError('Invalid Google token');

    return {
      providerId: payload.sub,
      email: payload.email,
      firstName: payload.given_name,
      lastName: payload.family_name,
    };
  } catch {
    throw new AuthenticationError('Failed to verify Google token');
  }
}

// Apple verification
const appleJwksClient = jwksClient({
  jwksUri: 'https://appleid.apple.com/auth/keys',
  cache: true,
});

export async function verifyAppleToken(identityToken: string): Promise<OAuthUserInfo> {
  try {
    const decoded = jwt.decode(identityToken, { complete: true });
    if (!decoded) throw new AuthenticationError('Invalid Apple token');

    const key = await appleJwksClient.getSigningKey(decoded.header.kid);
    const payload = jwt.verify(identityToken, key.getPublicKey(), {
      algorithms: ['RS256'],
      issuer: 'https://appleid.apple.com',
      audience: APPLE_CLIENT_ID,
    }) as jwt.JwtPayload;

    if (!payload.sub || !payload.email) {
      throw new AuthenticationError('Invalid Apple token payload');
    }

    return {
      providerId: payload.sub,
      email: payload.email as string,
    };
  } catch (error) {
    if (error instanceof AuthenticationError) throw error;
    throw new AuthenticationError('Failed to verify Apple token');
  }
}

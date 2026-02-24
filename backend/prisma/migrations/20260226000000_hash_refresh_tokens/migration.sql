-- Refresh tokens are now stored as SHA-256 hashes instead of plaintext JWTs.
-- Revoke all existing plaintext tokens so they can't be used with the new hashing logic.
-- Users will need to re-authenticate after this migration.
UPDATE "RefreshToken" SET "revoked" = true WHERE "revoked" = false;

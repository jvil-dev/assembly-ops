-- Rename plaintext PII columns to encrypted variants.
-- After this migration, a backfill script must encrypt existing plaintext data.

-- EventVolunteer: rename plaintext token to encryptedToken
ALTER TABLE "EventVolunteer" RENAME COLUMN "token" TO "encryptedToken";

-- LostPersonAlert: rename PII columns
ALTER TABLE "LostPersonAlert" RENAME COLUMN "personName" TO "encryptedPersonName";
ALTER TABLE "LostPersonAlert" RENAME COLUMN "contactName" TO "encryptedContactName";
ALTER TABLE "LostPersonAlert" RENAME COLUMN "contactPhone" TO "encryptedContactPhone";

-- OAuthConnection: rename email to encryptedEmail
ALTER TABLE "OAuthConnection" RENAME COLUMN "email" TO "encryptedEmail";

import { hashPassword, comparePassword } from "../../utils/passwordUtils.js";

describe("passwordUtils", () => {
  const testPassword = "MySecurePassword123!";

  describe("hashPassword", () => {
    it("should return a bcrypt hash", async () => {
      const hash = await hashPassword(testPassword);

      // Bcrypt hashes start with $2b$ or $2a$
      expect(hash).toMatch(/^\$2[ab]\$/);
    });

    it("should generate different hashes for same password", async () => {
      const hash1 = await hashPassword(testPassword);
      const hash2 = await hashPassword(testPassword);

      // Same password should produce different hashes (due to salt)
      expect(hash1).not.toBe(hash2);
    });

    it("should generate hash of correct length", async () => {
      const hash = await hashPassword(testPassword);

      // Bcrypt hashes are 60 characters
      expect(hash.length).toBe(60);
    });
  });

  describe("comparePassword", () => {
    it("should return true for matching password", async () => {
      const hash = await hashPassword(testPassword);
      const result = await comparePassword(testPassword, hash);

      expect(result).toBe(true);
    });

    it("should return false for non-matching password", async () => {
      const hash = await hashPassword(testPassword);
      const result = await comparePassword("WrongPassword", hash);

      expect(result).toBe(false);
    });

    it("should handle empty password", async () => {
      const hash = await hashPassword(testPassword);
      const result = await comparePassword("", hash);

      expect(result).toBe(false);
    });
  });
});

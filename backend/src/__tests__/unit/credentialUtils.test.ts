import {
  generateVolunteerId,
  generateLoginToken,
  generateCredentials,
} from "../../utils/credentialUtils.js";

describe("credentialUtils", () => {
  describe("generateVolunteerId", () => {
    it("should generate ID in format VOL-XXXXXX", () => {
      const id = generateVolunteerId();
      expect(id).toMatch(/^VOL-[A-Z0-9]{6}$/);
    });

    it("should generate unique IDs", () => {
      const ids = new Set<string>();
      for (let i = 0; i < 100; i++) {
        ids.add(generateVolunteerId());
      }
      // With 6 chars from 32 options, collisions are very unlikely
      expect(ids.size).toBe(100);
    });

    it("should not contain ambiguous characters (I, O, 0, 1)", () => {
      // Generate many IDs to increase chance of catching issues
      for (let i = 0; i < 100; i++) {
        const id = generateVolunteerId();
        // Only check the 6-character suffix, not the "VOL-" prefix
        const suffix = id.substring(4);
        expect(suffix).not.toMatch(/[IO01]/);
      }
    });
  });

  describe("generateLoginToken", () => {
    it("should generate 32-character hex string", () => {
      const token = generateLoginToken();
      expect(token).toMatch(/^[a-f0-9]{32}$/);
    });

    it("should generate unique tokens", () => {
      const tokens = new Set<string>();
      for (let i = 0; i < 100; i++) {
        tokens.add(generateLoginToken());
      }
      expect(tokens.size).toBe(100);
    });
  });

  describe("generateCredentials", () => {
    it("should return object with generatedId and loginToken", () => {
      const credentials = generateCredentials();

      expect(credentials).toHaveProperty("generatedId");
      expect(credentials).toHaveProperty("loginToken");
      expect(credentials.generatedId).toMatch(/^VOL-[A-Z0-9]{6}$/);
      expect(credentials.loginToken).toMatch(/^[a-f0-9]{32}$/);
    });
  });
});

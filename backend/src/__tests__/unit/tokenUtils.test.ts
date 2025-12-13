import {
  generateToken,
  verifyToken,
  TokenPayload,
} from "../../utils/tokenUtils.js";

describe("tokenUtils", () => {
  const adminPayload: TokenPayload = {
    id: "test-admin-id",
    email: "admin@example.com",
    type: "admin",
  };

  const volunteerPayload: TokenPayload = {
    id: "test-volunteer-id",
    type: "volunteer",
    eventId: "test-event-id",
  };

  describe("generateToken", () => {
    it("should generate a valid JWT for admin", () => {
      const token = generateToken(adminPayload);

      // JWT format: header.payload.signature
      expect(token.split(".")).toHaveLength(3);
    });

    it("should generate a valid JWT for volunteer", () => {
      const token = generateToken(volunteerPayload);

      expect(token.split(".")).toHaveLength(3);
    });
  });

  describe("verifyToken", () => {
    it("should decode admin token correctly", () => {
      const token = generateToken(adminPayload);
      const decoded = verifyToken(token);

      expect(decoded.id).toBe(adminPayload.id);
      expect(decoded.email).toBe(adminPayload.email);
      expect(decoded.type).toBe("admin");
      expect(decoded).toHaveProperty("iat");
      expect(decoded).toHaveProperty("exp");
    });

    it("should decode volunteer token correctly", () => {
      const token = generateToken(volunteerPayload);
      const decoded = verifyToken(token);

      expect(decoded.id).toBe(volunteerPayload.id);
      expect(decoded.type).toBe("volunteer");
      expect(decoded.eventId).toBe(volunteerPayload.eventId);
    });

    it("should throw for invalid token", () => {
      expect(() => verifyToken("invalid-token")).toThrow();
    });

    it("should throw for tampered token", () => {
      const token = generateToken(adminPayload);
      const tamperedToken = token.slice(0, -5) + "xxxxx";

      expect(() => verifyToken(tamperedToken)).toThrow();
    });
  });
});

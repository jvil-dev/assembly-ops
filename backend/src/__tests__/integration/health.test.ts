import request from "supertest";
import app from "../../app.js";

describe("Health Endpoint", () => {
  describe("GET /health", () => {
    it("should return 200 and status ok", async () => {
      const response = await request(app)
        .get("/health")
        .expect("Content-Type", /json/)
        .expect(200);

      expect(response.body).toHaveProperty("status", "ok");
      expect(response.body).toHaveProperty("message");
      expect(response.body).toHaveProperty("timestamp");
    });

    it("should return valid timestamp", async () => {
      const response = await request(app).get("/health").expect(200);

      const timestamp = new Date(response.body.timestamp);
      expect(timestamp).toBeInstanceOf(Date);
      expect(timestamp.getTime()).not.toBeNaN();
    });
  });
});

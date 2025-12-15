import request from "supertest";
import app from "../../app.js";
import { prisma } from "../../config/database.js";

describe("Auth Endpoints", () => {
  // Clean up test data after all tests
  afterAll(async () => {
    // Delete test users created during tests
    await prisma.admin.deleteMany({
      where: {
        email: {
          contains: "test-",
        },
      },
    });
  });

  describe("POST /auth/admin/register", () => {
    const testEmail = `test-${Date.now()}@example.com`;

    it("should register a new admin", async () => {
      const response = await request(app)
        .post("/auth/admin/register")
        .send({
          email: testEmail,
          password: "password123",
          name: "Test Admin",
          congregation: "Test Congregation",
        })
        .expect("Content-Type", /json/)
        .expect(201);

      expect(response.body).toHaveProperty(
        "message",
        "Admin registered successfully"
      );
      expect(response.body).toHaveProperty("admin");
      expect(response.body).toHaveProperty("token");
      expect(response.body.admin.email).toBe(testEmail.toLowerCase());
      expect(response.body.admin).not.toHaveProperty("passwordHash");
    });

    it("should return 400 for missing fields", async () => {
      const response = await request(app)
        .post("/auth/admin/register")
        .send({
          email: "incomplete@example.com",
        })
        .expect(400);

      expect(response.body).toHaveProperty("error");
    });

    it("should return 400 for invalid email", async () => {
      const response = await request(app)
        .post("/auth/admin/register")
        .send({
          email: "invalid-email",
          password: "password123",
          name: "Test",
          congregation: "Test",
        })
        .expect(400);

      expect(response.body.error).toContain("email");
    });

    it("should return 400 for short password", async () => {
      const response = await request(app)
        .post("/auth/admin/register")
        .send({
          email: "short-pass@example.com",
          password: "short",
          name: "Test",
          congregation: "Test",
        })
        .expect(400);

      expect(response.body.error).toContain("Password");
    });

    it("should return 409 for duplicate email", async () => {
      // First registration already done above
      const response = await request(app)
        .post("/auth/admin/register")
        .send({
          email: testEmail,
          password: "password123",
          name: "Duplicate Admin",
          congregation: "Test",
        })
        .expect(409);

      expect(response.body.error).toContain("already registered");
    });
  });

  describe("POST /auth/admin/login", () => {
    const loginEmail = `test-login-${Date.now()}@example.com`;
    const loginPassword = "password123";

    beforeAll(async () => {
      // Create a test admin for login tests
      await request(app).post("/auth/admin/register").send({
        email: loginEmail,
        password: loginPassword,
        name: "Login Test Admin",
        congregation: "Test",
      });
    });

    it("should login with valid credentials", async () => {
      const response = await request(app)
        .post("/auth/admin/login")
        .send({
          email: loginEmail,
          password: loginPassword,
        })
        .expect(200);

      expect(response.body).toHaveProperty("message", "Login successful");
      expect(response.body).toHaveProperty("admin");
      expect(response.body).toHaveProperty("token");
      expect(response.body.admin.email).toBe(loginEmail.toLowerCase());
    });

    it("should return 400 for missing fields", async () => {
      const response = await request(app)
        .post("/auth/admin/login")
        .send({
          email: loginEmail,
        })
        .expect(400);

      expect(response.body).toHaveProperty("error");
    });

    it("should return 401 for wrong password", async () => {
      const response = await request(app)
        .post("/auth/admin/login")
        .send({
          email: loginEmail,
          password: "wrongpassword",
        })
        .expect(401);

      expect(response.body.error).toBe("Invalid credentials");
    });

    it("should return 401 for non-existent email", async () => {
      const response = await request(app)
        .post("/auth/admin/login")
        .send({
          email: "nonexistent@example.com",
          password: "password123",
        })
        .expect(401);

      expect(response.body.error).toBe("Invalid credentials");
    });
  });

  describe("GET /auth/admin/me", () => {
    let authToken: string;
    const meEmail = `test-me-${Date.now()}@example.com`;

    beforeAll(async () => {
      // Create and login test admin
      const response = await request(app).post("/auth/admin/register").send({
        email: meEmail,
        password: "password123",
        name: "Me Test Admin",
        congregation: "Test",
      });
      authToken = response.body.token;
    });

    it("should return admin info with valid token", async () => {
      const response = await request(app)
        .get("/auth/admin/me")
        .set("Authorization", `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty("message", "Authenticated");
      expect(response.body).toHaveProperty("admin");
      expect(response.body.admin.email).toBe(meEmail.toLowerCase());
    });

    it("should return 401 without token", async () => {
      const response = await request(app).get("/auth/admin/me").expect(401);

      expect(response.body).toHaveProperty("error");
    });

    it("should return 401 with invalid token", async () => {
      const response = await request(app)
        .get("/auth/admin/me")
        .set("Authorization", "Bearer invalid-token")
        .expect(401);

      expect(response.body.error).toContain("Invalid");
    });
  });
});

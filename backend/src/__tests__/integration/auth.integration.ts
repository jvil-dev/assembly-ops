import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

let app: Application;

describe('Auth', () => {
  const testUser = {
    email: `test-${Date.now()}@example.com`,
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'User',
    congregation: 'Test Congregation',
  };

  let accessToken: string;
  let refreshToken: string;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('registerAdmin', () => {
    it('should register a new admin', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation RegisterAdmin($input: RegisterAdminInput!) {
              registerAdmin(input: $input) {
                admin {
                  id
                  email
                  firstName
                  lastName
                }
                accessToken
                refreshToken
                expiresIn
              }
            }
          `,
          variables: { input: testUser },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.registerAdmin.admin.email).toBe(testUser.email);
      expect(response.body.data.registerAdmin.accessToken).toBeDefined();
      expect(response.body.data.registerAdmin.refreshToken).toBeDefined();

      accessToken = response.body.data.registerAdmin.accessToken;
      refreshToken = response.body.data.registerAdmin.refreshToken;
    });

    it('should reject duplicate email', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation RegisterAdmin($input: RegisterAdminInput!) {
              registerAdmin(input: $input) {
                admin { id }
              }
            }
          `,
          variables: { input: testUser },
        });

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toContain('already exists');
    });
  });

  describe('loginAdmin', () => {
    it('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation LoginAdmin($input: LoginAdminInput!) {
              loginAdmin(input: $input) {
                admin {
                  email
                }
                accessToken
                refreshToken
              }
            }
          `,
          variables: {
            input: {
              email: testUser.email,
              password: testUser.password,
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.loginAdmin.admin.email).toBe(testUser.email);

      // Update tokens - login deletes old tokens and creates new ones
      accessToken = response.body.data.loginAdmin.accessToken;
      refreshToken = response.body.data.loginAdmin.refreshToken;
    });

    it('should reject invalid password', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation LoginAdmin($input: LoginAdminInput!) {
              loginAdmin(input: $input) {
                admin { id }
              }
            }
          `,
          variables: {
            input: {
              email: testUser.email,
              password: 'WrongPassword123',
            },
          },
        });

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toContain('Invalid');
    });
  });

  describe('me', () => {
    it('should return current admin when authenticated', async () => {
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Me {
              me {
                id
                email
                firstName
                lastName
                fullName
              }
            }
          `,
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.me.email).toBe(testUser.email);
      expect(response.body.data.me.fullName).toBe(`${testUser.firstName} ${testUser.lastName}`);
    });

    it('should return null when not authenticated', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query Me {
              me {
                id
              }
            }
          `,
        });

      expect(response.status).toBe(200);
      expect(response.body.data.me).toBeNull();
    });
  });

  describe('refreshToken', () => {
    it('should refresh tokens', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation RefreshToken($input: RefreshTokenInput!) {
              refreshToken(input: $input) {
                accessToken
                refreshToken
                expiresIn
              }
            }
          `,
          variables: { input: { refreshToken } },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.refreshToken.accessToken).toBeDefined();
      expect(response.body.data.refreshToken.refreshToken).toBeDefined();
    });
  });
});

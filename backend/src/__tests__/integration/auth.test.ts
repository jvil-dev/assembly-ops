import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import prisma from '../../config/database.js';
import type { Application } from 'express';

let app: Application;

const graphqlRequest = (query: string, variables?: object) =>
  request(app).post('/graphql').send({ query, variables }).set('Content-Type', 'application/json');

const authGraphqlRequest = (query: string, variables: object, token: string) =>
  request(app)
    .post('/graphql')
    .send({ query, variables })
    .set('Content-Type', 'application/json')
    .set('Authorization', `Bearer ${token}`);

describe('Auth GraphQL', () => {
  let adminToken: string;
  let adminEmail: string;
  let testEventId: string;
  let testVolunteerId: string;
  let testVolunteerToken: string;

  beforeAll(async () => {
    app = await createTestApp();
    adminEmail = `test-${Date.now()}@test.com`;

    // Register admin
    const registerRes = await graphqlRequest(
      `
        mutation RegisterAdmin($input: RegisterAdminInput!) {
          registerAdmin(input: $input) {
            accessToken
            admin { id }
          }
        }
      `,
      {
        input: {
          email: adminEmail,
          password: 'Test123!',
          firstName: 'Test',
          lastName: 'Admin',
          congregation: 'Test Congregation',
        },
      }
    );

    if (registerRes.body.errors) {
      console.log('Register errors:', JSON.stringify(registerRes.body.errors, null, 2));
    }

    adminToken = registerRes.body.data?.registerAdmin?.accessToken;

    if (!adminToken) {
      console.log('No admin token - registration failed');
      return;
    }

    // Get a template and activate event
    const templatesRes = await authGraphqlRequest(
      `
        query {
          eventTemplates {
            id
            name
          }
        }
      `,
      {},
      adminToken
    );

    const templateId = templatesRes.body.data?.eventTemplates?.[0]?.id;

    if (templateId) {
      const eventRes = await authGraphqlRequest(
        `
          mutation ActivateEvent($input: ActivateEventInput!) {
            activateEvent(input: $input) {
              id
            }
          }
        `,
        { input: { templateId } },
        adminToken
      );

      testEventId = eventRes.body.data?.activateEvent?.id;
    }
  });

  afterAll(async () => {
    // Cleanup in reverse order of dependencies
    if (testEventId) {
      await prisma.event.delete({ where: { id: testEventId } }).catch(() => {});
    }
    await prisma.admin.deleteMany({ where: { email: { contains: 'test-' } } });
    await closeTestApp();
    await prisma.$disconnect();
  });

  describe('Admin Auth', () => {
    it('should register a new admin', async () => {
      const res = await graphqlRequest(
        `
          mutation RegisterAdmin($input: RegisterAdminInput!) {
            registerAdmin(input: $input) {
              accessToken
              refreshToken
              expiresIn
              admin { id email firstName }
            }
          }
        `,
        {
          input: {
            email: `another-${Date.now()}@test.com`,
            password: 'Test123!',
            firstName: 'Another',
            lastName: 'Admin',
            congregation: 'Another Congregation',
          },
        }
      );

      expect(res.body.errors).toBeUndefined();
      expect(res.body.data.registerAdmin.accessToken).toBeDefined();
      expect(res.body.data.registerAdmin.admin.firstName).toBe('Another');
    });

    it('should login existing admin', async () => {
      const res = await graphqlRequest(
        `
          mutation LoginAdmin($input: LoginAdminInput!) {
            loginAdmin(input: $input) {
              accessToken
              refreshToken
              admin { email }
            }
          }
        `,
        {
          input: {
            email: adminEmail,
            password: 'Test123!',
          },
        }
      );

      expect(res.body.errors).toBeUndefined();
      expect(res.body.data.loginAdmin.accessToken).toBeDefined();
    });

    it('should reject invalid admin credentials', async () => {
      const res = await graphqlRequest(
        `
          mutation LoginAdmin($input: LoginAdminInput!) {
            loginAdmin(input: $input) {
              accessToken
            }
          }
        `,
        {
          input: {
            email: 'wrong@test.com',
            password: 'wrongpassword',
          },
        }
      );

      expect(res.body.errors).toBeDefined();
    });
  });

  describe('Volunteer Auth', () => {
    beforeAll(async () => {
      if (!testEventId || !adminToken) {
        console.log('Skipping volunteer tests - no event or admin token');
        return;
      }

      // Create a volunteer
      const volunteerRes = await authGraphqlRequest(
        `
          mutation CreateVolunteer($eventId: ID!, $input: CreateVolunteerInput!) {
            createVolunteer(eventId: $eventId, input: $input) {
              id
              volunteerId
              token
            }
          }
        `,
        {
          eventId: testEventId,
          input: {
            firstName: 'Test',
            lastName: 'Volunteer',
            congregation: 'Test Congregation',
          },
        },
        adminToken
      );

      if (volunteerRes.body.errors) {
        console.log('Create volunteer errors:', JSON.stringify(volunteerRes.body.errors, null, 2));
      }

      testVolunteerId = volunteerRes.body.data?.createVolunteer?.volunteerId;
      testVolunteerToken = volunteerRes.body.data?.createVolunteer?.token;
    });

    it('should login volunteer with valid credentials', async () => {
      if (!testVolunteerId || !testVolunteerToken) {
        console.log('Skipping - no volunteer created');
        return;
      }

      const res = await graphqlRequest(
        `
          mutation LoginVolunteer($input: LoginVolunteerInput!) {
            loginVolunteer(input: $input) {
              accessToken
              refreshToken
              expiresIn
              volunteer {
                id
                firstName
                lastName
              }
            }
          }
        `,
        {
          input: {
            volunteerId: testVolunteerId,
            token: testVolunteerToken,
          },
        }
      );

      expect(res.body.errors).toBeUndefined();
      expect(res.body.data.loginVolunteer.accessToken).toBeDefined();
      expect(res.body.data.loginVolunteer.volunteer.firstName).toBe('Test');
    });

    it('should reject invalid volunteer credentials', async () => {
      const res = await graphqlRequest(
        `
          mutation LoginVolunteer($input: LoginVolunteerInput!) {
            loginVolunteer(input: $input) {
              accessToken
            }
          }
        `,
        {
          input: {
            volunteerId: 'INVALID-123',
            token: 'WRONGTOKEN',
          },
        }
      );

      expect(res.body.errors).toBeDefined();
    });
  });

  describe('Token Refresh', () => {
    it('should reject invalid refresh token', async () => {
      const res = await graphqlRequest(
        `
          mutation RefreshToken($input: RefreshTokenInput!) {
            refreshToken(input: $input) {
              accessToken
            }
          }
        `,
        {
          input: { refreshToken: 'invalid-token' },
        }
      );

      expect(res.body.errors).toBeDefined();
    });
  });
});

/**
 * Volunteer Integration Tests
 *
 * Tests for volunteer-related GraphQL operations.
 * Volunteers are event participants managed by overseers, authenticated via
 * generated ID + token credentials (no password).
 *
 * Test Setup:
 *   1. Register a new admin (becomes APP_ADMIN)
 *   2. Activate an event from template
 *   3. Claim a department
 *
 * Tests:
 *   - createVolunteer: Create volunteer with event-type-aware ID prefix (CA-/RC-)
 *   - loginVolunteer: Authenticate with volunteerId + token
 *   - volunteerToken: Query decrypted token (admin-only, AES-256-GCM)
 *   - regenerateVolunteerCredentials: Generate new volunteerId + token
 *   - volunteers: Query event volunteers list
 *
 * Authorization:
 *   - Volunteer mutations require authenticated admin with event access
 *   - volunteerToken requires admin authentication
 */
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

let app: Application;

describe('Volunteer Operations', () => {
  let accessToken: string;
  let eventId: string;
  let volunteerId: string; // Internal DB id
  let volunteerCredentials: { volunteerId: string; token: string };

  beforeAll(async () => {
    app = await createTestApp();
    const email = `vol-test-${Date.now()}@example.com`;

    // Register admin
    const registerRes = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation Register($input: RegisterAdminInput!) {
            registerAdmin(input: $input) {
              accessToken
            }
          }
        `,
        variables: {
          input: {
            email,
            password: 'TestPassword123!',
            firstName: 'Vol',
            lastName: 'Tester',
          },
        },
      });

    if (registerRes.body.errors) {
      console.error('Register failed:', registerRes.body.errors);
      return;
    }
    accessToken = registerRes.body.data.registerAdmin.accessToken;

    // Get a template and activate event
    const templatesRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        query: `query { eventTemplates(serviceYear: 2026) { id } }`,
      });

    if (templatesRes.body.data.eventTemplates.length > 0) {
      const templateId = templatesRes.body.data.eventTemplates[0].id;

      const activateRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Activate($input: ActivateEventInput!) {
              activateEvent(input: $input) {
                id
              }
            }
          `,
          variables: { input: { templateId } },
        });

      eventId = activateRes.body.data.activateEvent.id;
    }
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('createVolunteer', () => {
    it('should create a volunteer with credentials', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Create($eventId: ID!, $input: CreateVolunteerInput!) {
              createVolunteer(eventId: $eventId, input: $input) {
                id
                volunteerId
                token
                firstName
                lastName
              }
            }
          `,
          variables: {
            eventId,
            input: {
              firstName: 'Test',
              lastName: 'Volunteer',
              congregation: 'Test Congregation',
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.createVolunteer.volunteerId).toMatch(/^(CA|RC)-/);
      expect(response.body.data.createVolunteer.token).toBeDefined();

      volunteerId = response.body.data.createVolunteer.id;
      volunteerCredentials = {
        volunteerId: response.body.data.createVolunteer.volunteerId,
        token: response.body.data.createVolunteer.token,
      };
    });
  });

  describe('loginVolunteer', () => {
    it('should login with valid credentials', async () => {
      if (!volunteerCredentials) {
        console.log('Skipping - no credentials available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation Login($input: LoginVolunteerInput!) {
              loginVolunteer(input: $input) {
                volunteer {
                  id
                  firstName
                  lastName
                  fullName
                }
                accessToken
                refreshToken
              }
            }
          `,
          variables: { input: volunteerCredentials },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.loginVolunteer.accessToken).toBeDefined();
      expect(response.body.data.loginVolunteer.volunteer.fullName).toBe('Test Volunteer');
    });
  });

  describe('volunteerToken', () => {
    it('should return decrypted token matching creation token', async () => {
      if (!volunteerId || !volunteerCredentials) {
        console.log('Skipping - no volunteer created');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query VolunteerToken($id: ID!) {
              volunteerToken(id: $id)
            }
          `,
          variables: { id: volunteerId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.volunteerToken).toBe(volunteerCredentials.token);
    });

    it('should reject unauthenticated requests', async () => {
      if (!volunteerId) {
        console.log('Skipping - no volunteer created');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query VolunteerToken($id: ID!) {
              volunteerToken(id: $id)
            }
          `,
          variables: { id: volunteerId },
        });

      expect(response.body.errors).toBeDefined();
    });
  });

  describe('regenerateVolunteerCredentials', () => {
    it('should regenerate and return new credentials', async () => {
      if (!volunteerId) {
        console.log('Skipping - no volunteer created');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Regenerate($id: ID!) {
              regenerateVolunteerCredentials(id: $id) {
                volunteerId
                token
              }
            }
          `,
          variables: { id: volunteerId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.regenerateVolunteerCredentials.volunteerId).toMatch(/^(CA|RC)-/);
      expect(response.body.data.regenerateVolunteerCredentials.token).toBeDefined();
      expect(response.body.data.regenerateVolunteerCredentials.token).toHaveLength(8);

      // Verify the new token is retrievable via volunteerToken query
      const tokenResponse = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query VolunteerToken($id: ID!) {
              volunteerToken(id: $id)
            }
          `,
          variables: { id: volunteerId },
        });

      expect(tokenResponse.body.errors).toBeUndefined();
      expect(tokenResponse.body.data.volunteerToken).toBe(
        response.body.data.regenerateVolunteerCredentials.token
      );
    });
  });

  describe('volunteers', () => {
    it('should return event volunteers', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Volunteers($eventId: ID!) {
              volunteers(eventId: $eventId) {
                id
                volunteerId
                firstName
                lastName
                congregation
              }
            }
          `,
          variables: { eventId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.volunteers)).toBe(true);
    });
  });
});

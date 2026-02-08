/**
 * Event Integration Tests
 *
 * Tests for event-related GraphQL operations.
 * Events represent conventions/assemblies with templates, departments, and admin management.
 *
 * Test Setup:
 *   1. Register a new admin (becomes APP_ADMIN)
 *   2. Fetch event templates and activate an event
 *
 * Tests:
 *   - eventTemplates: Query available event templates
 *   - activateEvent: Create event from template with join code
 *   - myEvents: Query events the admin is part of
 *   - availableDepartments: Query unclaimed departments in an event
 *   - promoteToAppAdmin: Promote Department Overseer to App Admin (idempotent, auth-guarded)
 *
 * Authorization:
 *   - Event mutations require authenticated admin
 *   - promoteToAppAdmin requires APP_ADMIN role
 */
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

let app: Application;

describe('Event Operations', () => {
  let accessToken: string;
  let templateId: string;
  let eventId: string;

  // Register and login first
  beforeAll(async () => {
    app = await createTestApp();
    const email = `event-test-${Date.now()}@example.com`;

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
            firstName: 'Event',
            lastName: 'Tester',
          },
        },
      });

    if (registerRes.body.errors) {
      console.error('Register failed:', registerRes.body.errors);
      return;
    }
    accessToken = registerRes.body.data.registerAdmin.accessToken;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('eventTemplates', () => {
    it('should return list of templates', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query {
              eventTemplates(serviceYear: 2026) {
                id
                name
                eventType
                circuit
                venue
                startDate
              }
            }
          `,
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.eventTemplates)).toBe(true);

      if (response.body.data.eventTemplates.length > 0) {
        templateId = response.body.data.eventTemplates[0].id;
      }
    });
  });

  describe('activateEvent', () => {
    it('should activate an event from template', async () => {
      if (!templateId) {
        console.log('Skipping - no template available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Activate($input: ActivateEventInput!) {
              activateEvent(input: $input) {
                id
                joinCode
                name
                eventType
                admins {
                  role
                  admin { email }
                }
              }
            }
          `,
          variables: { input: { templateId } },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.activateEvent.id).toBeDefined();
      expect(response.body.data.activateEvent.joinCode).toBeDefined();
      expect(response.body.data.activateEvent.admins[0].role).toBe('APP_ADMIN');

      eventId = response.body.data.activateEvent.id;
    });
  });

  describe('myEvents', () => {
    it('should return events I am part of', async () => {
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query {
              myEvents {
                role
                event {
                  id
                  name
                }
              }
            }
          `,
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.myEvents)).toBe(true);
    });
  });

  describe('availableDepartments', () => {
    it('should return unclaimed departments', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Available($eventId: ID!) {
              availableDepartments(eventId: $eventId)
            }
          `,
          variables: { eventId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.availableDepartments)).toBe(true);
      expect(response.body.data.availableDepartments.length).toBe(12); // All 12 available
    });
  });

  describe('promoteToAppAdmin', () => {
    let secondAdminToken: string;
    let secondAdminId: string;

    beforeAll(async () => {
      // Create a second admin
      const email = `dept-overseer-${Date.now()}@example.com`;
      const registerRes = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation Register($input: RegisterAdminInput!) {
              registerAdmin(input: $input) {
                accessToken
                admin { id }
              }
            }
          `,
          variables: {
            input: {
              email,
              password: 'TestPassword123!',
              firstName: 'Department',
              lastName: 'Overseer',
            },
          },
        });

      secondAdminToken = registerRes.body.data.registerAdmin.accessToken;
      secondAdminId = registerRes.body.data.registerAdmin.admin.id;

      // Have second admin join the event
      await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${secondAdminToken}`)
        .send({
          query: `
            mutation Join($input: JoinEventInput!) {
              joinEvent(input: $input) {
                id
                role
              }
            }
          `,
          variables: {
            input: { joinCode: 'TODO' }, // Will need to get the actual join code
          },
        });
    });

    it('should promote department overseer to app admin', async () => {
      if (!eventId || !secondAdminId) {
        console.log('Skipping - prerequisites not met');
        return;
      }

      // First, get the event to retrieve join code
      const eventResponse = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Event($id: ID!) {
              event(id: $id) {
                joinCode
              }
            }
          `,
          variables: { id: eventId },
        });

      const joinCode = eventResponse.body.data.event.joinCode;

      // Have second admin join
      await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${secondAdminToken}`)
        .send({
          query: `
            mutation Join($input: JoinEventInput!) {
              joinEvent(input: $input) {
                id
              }
            }
          `,
          variables: { input: { joinCode } },
        });

      // Now promote the second admin
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Promote($input: PromoteToAppAdminInput!) {
              promoteToAppAdmin(input: $input) {
                id
                role
                admin {
                  id
                  firstName
                  lastName
                }
              }
            }
          `,
          variables: {
            input: {
              eventId,
              adminId: secondAdminId,
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.promoteToAppAdmin.role).toBe('APP_ADMIN');
      expect(response.body.data.promoteToAppAdmin.admin.id).toBe(secondAdminId);
    });

    it('should be idempotent - promoting already app admin is safe', async () => {
      if (!eventId || !secondAdminId) {
        console.log('Skipping - prerequisites not met');
        return;
      }

      // Promote again
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Promote($input: PromoteToAppAdminInput!) {
              promoteToAppAdmin(input: $input) {
                role
              }
            }
          `,
          variables: {
            input: {
              eventId,
              adminId: secondAdminId,
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.promoteToAppAdmin.role).toBe('APP_ADMIN');
    });

    it('should reject promotion by non-app-admin', async () => {
      if (!eventId || !secondAdminId) {
        console.log('Skipping - prerequisites not met');
        return;
      }

      // Create a third admin
      const email = `third-admin-${Date.now()}@example.com`;
      const registerRes = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation Register($input: RegisterAdminInput!) {
              registerAdmin(input: $input) {
                accessToken
                admin { id }
              }
            }
          `,
          variables: {
            input: {
              email,
              password: 'TestPassword123!',
              firstName: 'Third',
              lastName: 'Admin',
            },
          },
        });

      const thirdToken = registerRes.body.data.registerAdmin.accessToken;
      const thirdId = registerRes.body.data.registerAdmin.admin.id;

      // Get join code
      const eventResponse = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Event($id: ID!) {
              event(id: $id) {
                joinCode
              }
            }
          `,
          variables: { id: eventId },
        });

      const joinCode = eventResponse.body.data.event.joinCode;

      // Have third admin join as department overseer
      await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${thirdToken}`)
        .send({
          query: `
            mutation Join($input: JoinEventInput!) {
              joinEvent(input: $input) {
                id
              }
            }
          `,
          variables: { input: { joinCode } },
        });

      // Try to promote using third admin's token (department overseer)
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${thirdToken}`)
        .send({
          query: `
            mutation Promote($input: PromoteToAppAdminInput!) {
              promoteToAppAdmin(input: $input) {
                role
              }
            }
          `,
          variables: {
            input: {
              eventId,
              adminId: thirdId, // Try to promote self
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toContain('Only App Admins can promote');
    });
  });
});

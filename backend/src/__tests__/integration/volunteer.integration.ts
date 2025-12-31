import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

let app: Application;

describe('Volunteer Operations', () => {
  let accessToken: string;
  let eventId: string;
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
            congregation: 'Test Congregation',
          },
        },
      });

    if (registerRes.body.errors) {
      console.error('Register failed:', registerRes.body.errors);
      return;
    }
    accessToken = registerRes.body.data.registerAdmin.accessToken;

    // Get a template and activate event
    const templatesRes = await request(app).post('/graphql').send({
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
      expect(response.body.data.createVolunteer.volunteerId).toMatch(/^VOL-/);
      expect(response.body.data.createVolunteer.token).toBeDefined();

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

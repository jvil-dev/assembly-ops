import request from 'supertest';
import app from '../../app.js';

describe('Event Operations', () => {
  let accessToken: string;
  let templateId: string;
  let eventId: string;

  // Register and login first
  beforeAll(async () => {
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
            password: 'TestPassword123',
            firstName: 'Event',
            lastName: 'Tester',
            congregation: 'Test Congregation',
          },
        },
      });

    accessToken = registerRes.body.data.registerAdmin.accessToken;
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
      expect(response.body.data.activateEvent.admins[0].role).toBe('EVENT_OVERSEER');

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
});

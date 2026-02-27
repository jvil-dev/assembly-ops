/**
 * Test Helpers
 *
 * Shared utilities for integration tests.
 * Creates events directly via Prisma (events are first-class records in production).
 *
 * Used by: integration/*.ts
 */
import express from 'express';
import supertest from 'supertest';
import prisma from '../config/database.js';

/**
 * Create a test event directly in the database (simulating seed/admin import).
 * Returns the event ID.
 */
export async function createTestEvent(overrides?: {
  name?: string;
  eventType?: 'CIRCUIT_ASSEMBLY_CO' | 'CIRCUIT_ASSEMBLY_BR' | 'REGIONAL_CONVENTION' | 'SPECIAL_CONVENTION';
  startDate?: Date;
  endDate?: Date;
}): Promise<string> {
  const now = new Date();
  const startDate = overrides?.startDate ?? new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const endDate = overrides?.endDate ?? new Date(startDate.getTime() + 2 * 24 * 60 * 60 * 1000);

  const eventName = overrides?.name ?? `Test Event ${Date.now()}`;
  const eventType = overrides?.eventType ?? 'CIRCUIT_ASSEMBLY_CO';

  const event = await prisma.event.create({
    data: {
      name: eventName,
      eventType,
      region: 'US-MA',
      venue: `Test Venue ${Date.now()}`,
      address: '123 Test St',
      startDate,
      endDate,
      serviceYear: startDate.getFullYear(),
      isPublic: true,
    },
  });

  return event.id;
}

/**
 * Set a user as app admin by email.
 */
export async function setAppAdmin(email: string): Promise<void> {
  await prisma.user.update({
    where: { email },
    data: { isAppAdmin: true },
  });
}

/**
 * Clean up test data created during integration tests.
 */
export async function cleanupTestData() {
  // Delete test events (cascades to departments, sessions, etc.)
  await prisma.event.deleteMany({
    where: { name: { startsWith: 'Test Event' } },
  });

  // Delete test users
  await prisma.user.deleteMany({
    where: { email: { contains: 'test-' } },
  });
}

/**
 * Create a test user who is also an EventVolunteer for the given event.
 * 1. Register a new User via GraphQL
 * 2. Create an EventVolunteer via Prisma
 * Returns { accessToken, userId, eventVolunteerId }
 */
export async function createTestVolunteerUser(
  app: express.Application,
  eventId: string,
  departmentId?: string
): Promise<{ accessToken: string; userId: string; eventVolunteerId: string }> {
  const email = `test-vol-${Date.now()}-${Math.random().toString(36).slice(2, 6)}@test.com`;
  const res = await supertest(app)
    .post('/graphql')
    .send({
      query: `mutation RegisterUser($input: RegisterUserInput!) {
        registerUser(input: $input) {
          user { id }
          accessToken
        }
      }`,
      variables: {
        input: {
          email,
          password: 'TestPass123',
          firstName: 'TestVol',
          lastName: 'User',
        },
      },
    });

  const { user, accessToken } = res.body.data.registerUser;

  const eventVolunteer = await prisma.eventVolunteer.create({
    data: {
      userId: user.id,
      eventId,
      ...(departmentId && { departmentId }),
    },
  });

  return { accessToken, userId: user.id, eventVolunteerId: eventVolunteer.id };
}

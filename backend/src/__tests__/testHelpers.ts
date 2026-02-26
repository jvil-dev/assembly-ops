/**
 * Test Helpers
 *
 * Shared utilities for integration tests.
 * Creates events directly via Prisma (events are pre-created in production via seed script).
 *
 * Used by: integration/*.ts
 */
import prisma from '../config/database.js';

/**
 * Create a test event directly in the database (simulating seed script).
 * Returns the event ID.
 */
export async function createTestEvent(overrides?: {
  name?: string;
  eventType?: 'CIRCUIT_ASSEMBLY' | 'REGIONAL_CONVENTION' | 'SPECIAL_CONVENTION';
  startDate?: Date;
  endDate?: Date;
}): Promise<string> {
  const now = new Date();
  const startDate = overrides?.startDate ?? new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const endDate = overrides?.endDate ?? new Date(startDate.getTime() + 2 * 24 * 60 * 60 * 1000);

  const eventName = overrides?.name ?? `Test Event ${Date.now()}`;
  const eventType = overrides?.eventType ?? 'CIRCUIT_ASSEMBLY';

  // Event requires a template — create one inline
  const template = await prisma.eventTemplate.create({
    data: {
      name: eventName,
      eventType,
      circuit: `Test Circuit ${Date.now()}`,
      region: 'Test Region',
      venue: 'Test Venue',
      address: '123 Test St',
      startDate,
      endDate,
      serviceYear: startDate.getFullYear(),
    },
  });

  const event = await prisma.event.create({
    data: {
      templateId: template.id,
      isPublic: true,
    },
  });

  return event.id;
}

/**
 * Create a test event template for template-related tests.
 */
export async function createTestEventTemplate(): Promise<string> {
  const template = await prisma.eventTemplate.create({
    data: {
      name: `Template ${Date.now()}`,
      eventType: 'CIRCUIT_ASSEMBLY',
      circuit: `Test Circuit ${Date.now()}`,
      region: 'Test Region',
      venue: 'Test Venue',
      address: '123 Test St',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-06-02'),
      serviceYear: 2026,
    },
  });

  return template.id;
}

/**
 * Clean up test data created during integration tests.
 */
export async function cleanupTestData() {
  // Delete test events (cascades to departments, sessions, etc.)
  await prisma.event.deleteMany({
    where: { name: { startsWith: 'Test Event' } },
  });

  // Delete test templates
  await prisma.eventTemplate.deleteMany({
    where: { name: { startsWith: 'Template' } },
  });

  // Delete test users
  await prisma.user.deleteMany({
    where: { email: { contains: 'test-' } },
  });
}

/**
 * seed-roles.ts
 *
 * One-time script to backfill the 4 standard CO-1 department roles into
 * existing events that were activated before role seeding was added to
 * activateEvent(). Safe to run multiple times — skips events that already
 * have roles.
 *
 * Usage (from /backend):
 *   npx tsx scripts/seed-roles.ts
 */

import prisma from '../src/config/database.js';

const DEFAULT_ROLES = [
  { name: 'Volunteer',          description: 'General department volunteer',               sortOrder: 0 },
  { name: 'Captain',            description: 'Leads volunteers during a session or shift', sortOrder: 1 },
  { name: 'Keyman',             description: 'Supervises a specific area or function',     sortOrder: 2 },
  { name: 'Assistant Overseer', description: 'Assists the department overseer',            sortOrder: 3 },
];

async function main() {
  const events = await prisma.event.findMany({
    select: { id: true, joinCode: true, template: { select: { name: true } } },
  });

  console.log(`Found ${events.length} event(s). Checking role seeding status...\n`);

  let seeded = 0;
  let skipped = 0;

  for (const event of events) {
    const label = `${event.template.name} (${event.joinCode})`;
    const existingCount = await prisma.role.count({ where: { eventId: event.id } });

    if (existingCount > 0) {
      console.log(`  ⏭  Skipped "${label}" — already has ${existingCount} role(s)`);
      skipped++;
      continue;
    }

    await prisma.role.createMany({
      data: DEFAULT_ROLES.map(r => ({ ...r, eventId: event.id })),
    });

    console.log(`  ✓  Seeded 4 roles for "${label}"`);
    seeded++;
  }

  console.log(`\nDone. Seeded: ${seeded}, Skipped (already had roles): ${skipped}`);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error('seed-roles failed:', e);
    await prisma.$disconnect();
    process.exit(1);
  });

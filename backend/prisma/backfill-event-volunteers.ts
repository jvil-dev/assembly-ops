/**
 * Backfill Script: Create EventVolunteer + VolunteerProfile for existing Volunteers
 *
 * Run: npx tsx prisma/backfill-event-volunteers.ts
 *
 * For each Volunteer that doesn't have a corresponding EventVolunteer (matched by volunteerId),
 * creates a VolunteerProfile + EventVolunteer record with the same credentials.
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { decryptToken } from '../src/utils/credentials.js';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function findOrCreateCongregation(
  tx: Parameters<Parameters<PrismaClient['$transaction']>[0]>[0],
  congregationName: string,
  circuitId?: string | null
) {
  if (circuitId) {
    const existing = await tx.congregation.findFirst({
      where: { name: congregationName, circuitId },
    });
    if (existing) return existing;
  }

  let resolvedCircuitId = circuitId;
  if (!resolvedCircuitId) {
    const defaultCircuit = await tx.circuit.upsert({
      where: { code: 'UNKNOWN' },
      update: {},
      create: { code: 'UNKNOWN', region: 'Unknown' },
    });
    resolvedCircuitId = defaultCircuit.id;
  }

  return tx.congregation.create({
    data: {
      name: congregationName,
      city: 'Unknown',
      state: 'Unknown',
      circuitId: resolvedCircuitId,
    },
  });
}

async function main() {
  console.log('Starting EventVolunteer backfill...\n');

  // Find all volunteers
  const volunteers = await prisma.volunteer.findMany({
    include: {
      event: { include: { template: true } },
    },
  });

  // Find all existing EventVolunteers (by volunteerId)
  const existingEVs = await prisma.eventVolunteer.findMany({
    select: { volunteerId: true },
  });
  const existingVolunteerIds = new Set(existingEVs.map(ev => ev.volunteerId));

  // Filter to only volunteers that don't have an EventVolunteer
  const missing = volunteers.filter(v => !existingVolunteerIds.has(v.volunteerId));

  console.log(`Total volunteers: ${volunteers.length}`);
  console.log(`Already have EventVolunteer: ${existingVolunteerIds.size}`);
  console.log(`Need backfill: ${missing.length}\n`);

  if (missing.length === 0) {
    console.log('Nothing to backfill!');
    return;
  }

  let created = 0;
  let errors = 0;

  for (const vol of missing) {
    try {
      // Decrypt the plain token from encryptedToken
      let plainToken = '';
      if (vol.encryptedToken) {
        plainToken = decryptToken(vol.encryptedToken);
      } else {
        console.warn(`  WARNING: Volunteer ${vol.volunteerId} has no encryptedToken, using empty string`);
      }

      const circuitId = vol.event.template.circuitId;

      await prisma.$transaction(async (tx) => {
        // Find or create congregation
        const congregation = await findOrCreateCongregation(tx, vol.congregation, circuitId);

        // Create VolunteerProfile
        const profile = await tx.volunteerProfile.create({
          data: {
            firstName: vol.firstName,
            lastName: vol.lastName,
            email: vol.email,
            phone: vol.phone,
            appointmentStatus: vol.appointmentStatus || 'PUBLISHER',
            notes: vol.notes,
            congregationId: congregation.id,
          },
        });

        // Create EventVolunteer with same credentials
        await tx.eventVolunteer.create({
          data: {
            volunteerId: vol.volunteerId,
            tokenHash: vol.tokenHash,
            token: plainToken,
            volunteerProfileId: profile.id,
            eventId: vol.eventId,
            departmentId: vol.departmentId,
            roleId: vol.roleId,
          },
        });
      });

      created++;
      console.log(`  ✓ ${vol.volunteerId} (${vol.firstName} ${vol.lastName})`);
    } catch (err) {
      errors++;
      console.error(`  ✗ ${vol.volunteerId}: ${err}`);
    }
  }

  console.log(`\nBackfill complete: ${created} created, ${errors} errors`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

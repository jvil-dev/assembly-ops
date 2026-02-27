/**
 * Seed script for Congregation data.
 * Reads congregations.csv and upserts each row into the Congregation table.
 * Auto-derives Circuit records from the circuitCode column (no separate circuits.csv needed).
 * CSV columns: name, state, circuitCode, language
 */

import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import prisma from '../../src/config/database.js';
import { parseCSV } from './parseCSV.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Map state name → region code (e.g. "Massachusetts" → "US-MA") */
const STATE_TO_REGION: Record<string, string> = {
  Alabama: 'US-AL',
  Alaska: 'US-AK',
  Arizona: 'US-AZ',
  Arkansas: 'US-AR',
  California: 'US-CA',
  Colorado: 'US-CO',
  Connecticut: 'US-CT',
  Delaware: 'US-DE',
  Florida: 'US-FL',
  Georgia: 'US-GA',
  Hawaii: 'US-HI',
  Idaho: 'US-ID',
  Illinois: 'US-IL',
  Indiana: 'US-IN',
  Iowa: 'US-IA',
  Kansas: 'US-KS',
  Kentucky: 'US-KY',
  Louisiana: 'US-LA',
  Maine: 'US-ME',
  Maryland: 'US-MD',
  Massachusetts: 'US-MA',
  Michigan: 'US-MI',
  Minnesota: 'US-MN',
  Mississippi: 'US-MS',
  Missouri: 'US-MO',
  Montana: 'US-MT',
  Nebraska: 'US-NE',
  Nevada: 'US-NV',
  'New Hampshire': 'US-NH',
  'New Jersey': 'US-NJ',
  'New Mexico': 'US-NM',
  'New York': 'US-NY',
  'North Carolina': 'US-NC',
  'North Dakota': 'US-ND',
  Ohio: 'US-OH',
  Oklahoma: 'US-OK',
  Oregon: 'US-OR',
  Pennsylvania: 'US-PA',
  'Rhode Island': 'US-RI',
  'South Carolina': 'US-SC',
  'South Dakota': 'US-SD',
  Tennessee: 'US-TN',
  Texas: 'US-TX',
  Utah: 'US-UT',
  Vermont: 'US-VT',
  Virginia: 'US-VA',
  Washington: 'US-WA',
  'West Virginia': 'US-WV',
  Wisconsin: 'US-WI',
  Wyoming: 'US-WY',
  // Typo-tolerant entries
  Conneticut: 'US-CT',
};

export async function seedCongregations() {
  const csvPath = resolve(__dirname, 'congregations.csv');
  const rows = parseCSV(csvPath);

  if (rows.length === 0) {
    console.log('No congregation data in CSV, skipping...');
    return;
  }

  // --- Phase 1: Auto-derive and upsert circuits from congregation data ---
  // Collect unique circuit codes with their first-seen region and language
  const circuitMap = new Map<string, { region: string; language: string }>();

  for (const row of rows) {
    const code = row.circuitCode?.trim();
    if (!code) continue;

    if (!circuitMap.has(code)) {
      const region = STATE_TO_REGION[row.state] || 'US-XX';
      circuitMap.set(code, { region, language: row.language || 'en' });
    }
  }

  console.log(`Auto-deriving ${circuitMap.size} circuits from congregations data...`);

  for (const [code, { region, language }] of circuitMap) {
    await prisma.circuit.upsert({
      where: { code },
      update: { region, language },
      create: { code, region, language },
    });
  }

  console.log(`Upserted ${circuitMap.size} circuits`);

  // --- Phase 2: Clean up stale congregations not in current CSV ---
  const csvNames = new Set(rows.map(r => `${r.name}|${r.state}`));
  const existingCongregations = await prisma.congregation.findMany({
    select: { id: true, name: true, state: true },
  });

  const staleIds = existingCongregations
    .filter(c => !csvNames.has(`${c.name}|${c.state}`))
    .map(c => c.id);

  if (staleIds.length > 0) {
    // Unlink users referencing stale congregations before deleting
    await prisma.user.updateMany({
      where: { congregationId: { in: staleIds } },
      data: { congregationId: null },
    });
    await prisma.congregation.deleteMany({
      where: { id: { in: staleIds } },
    });
    console.log(`Removed ${staleIds.length} stale congregations`);
  }

  // --- Phase 3: Upsert congregations ---
  console.log(`Seeding ${rows.length} congregations...`);

  let seeded = 0;
  let skipped = 0;

  for (const row of rows) {
    const code = row.circuitCode?.trim();
    if (!code) {
      console.warn(`  No circuitCode for "${row.name}", skipping`);
      skipped++;
      continue;
    }

    const circuit = await prisma.circuit.findUnique({
      where: { code },
    });

    if (!circuit) {
      console.warn(`  Circuit ${code} not found, skipping "${row.name}"`);
      skipped++;
      continue;
    }

    await prisma.congregation.upsert({
      where: {
        name_state: {
          name: row.name,
          state: row.state,
        },
      },
      update: {
        language: row.language || 'en',
        circuitId: circuit.id,
      },
      create: {
        name: row.name,
        state: row.state,
        language: row.language || 'en',
        circuitId: circuit.id,
      },
    });

    seeded++;
  }

  console.log(`Seeded ${seeded} congregations (${skipped} skipped)`);
}

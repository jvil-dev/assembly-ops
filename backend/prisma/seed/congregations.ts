/**
 * Seed script for Congregation data.
 * Reads congregations.csv and upserts each row into the Congregation table.
 * Resolves circuitCode to circuitId via Circuit lookup.
 * CSV columns: name, city, state, circuitCode, language
 */

import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import prisma from '../../src/config/database.js';
import { parseCSV } from './parseCSV.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function seedCongregations() {
  const csvPath = resolve(__dirname, 'congregations.csv');
  const rows = parseCSV(csvPath);

  if (rows.length === 0) {
    console.log('No congregation data in CSV, skipping...');
    return;
  }

  console.log(`Seeding ${rows.length} congregations...`);

  let seeded = 0;
  let skipped = 0;

  for (const row of rows) {
    // Look up circuit by code
    const circuit = await prisma.circuit.findUnique({
      where: { code: row.circuitCode },
    });

    if (!circuit) {
      console.warn(`  Circuit ${row.circuitCode} not found, skipping "${row.name}"`);
      skipped++;
      continue;
    }

    await prisma.congregation.upsert({
      where: {
        name_city_state: {
          name: row.name,
          city: row.city,
          state: row.state,
        },
      },
      update: {
        language: row.language || 'en',
        circuitId: circuit.id,
      },
      create: {
        name: row.name,
        city: row.city,
        state: row.state,
        language: row.language || 'en',
        circuitId: circuit.id,
      },
    });

    seeded++;
  }

  console.log(`Seeded ${seeded} congregations (${skipped} skipped)`);
}

/**
 * Seed script for Circuit data.
 * Reads circuits.csv and upserts each row into the Circuit table.
 * CSV columns: code, region, language
 */

import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import prisma from '../../src/config/database.js';
import { parseCSV } from './parseCSV.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function seedCircuits() {
  const csvPath = resolve(__dirname, 'circuits.csv');
  const rows = parseCSV(csvPath);

  if (rows.length === 0) {
    console.log('No circuit data in CSV, skipping...');
    return;
  }

  console.log(`Seeding ${rows.length} circuits...`);

  for (const row of rows) {
    await prisma.circuit.upsert({
      where: { code: row.code },
      update: {
        region: row.region,
        language: row.language || 'en',
      },
      create: {
        code: row.code,
        region: row.region,
        language: row.language || 'en',
      },
    });
  }

  console.log(`Seeded ${rows.length} circuits`);
}

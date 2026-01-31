/**
 * Seed script for EventTemplate data.
 * Reads event_templates.csv and upserts each row into the EventTemplate table.
 * Resolves circuit code to circuitId via Circuit lookup.
 * CSV columns: eventType, circuit, region, serviceYear, name, theme,
 *              themeScripture, venue, address, startDate, endDate, language
 */

import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EventType } from '@prisma/client';
import prisma from '../../src/config/database.js';
import { parseCSV } from './parseCSV.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function seedEventTemplates() {
  const csvPath = resolve(__dirname, 'event_templates.csv');
  const rows = parseCSV(csvPath);

  if (rows.length === 0) {
    console.log('No event template data in CSV, skipping...');
    return;
  }

  console.log(`Seeding ${rows.length} event templates...`);

  for (const row of rows) {
    const eventType = row.eventType as EventType;
    const circuit = row.circuitCode || null;
    const startDate = new Date(row.startDate);

    // Look up circuitId if circuitCode is provided
    let circuitId: string | null = null;
    if (row.circuitCode) {
      const circuitRecord = await prisma.circuit.findUnique({
        where: { code: row.circuitCode },
      });
      if (circuitRecord) {
        circuitId = circuitRecord.id;
      } else {
        console.warn(`  Circuit ${row.circuitCode} not found for template "${row.name}"`);
      }
    }

    await prisma.eventTemplate.upsert({
      where: {
        eventType_circuit_startDate: {
          eventType,
          circuit: circuit ?? '',
          startDate,
        },
      },
      update: {
        region: row.region,
        serviceYear: parseInt(row.serviceYear, 10),
        name: row.name,
        theme: row.theme || null,
        themeScripture: row.themeScripture || null,
        venue: row.venue,
        address: row.address,
        endDate: new Date(row.endDate),
        language: row.language || 'en',
        circuitId,
      },
      create: {
        eventType,
        circuit,
        circuitId,
        region: row.region,
        serviceYear: parseInt(row.serviceYear, 10),
        name: row.name,
        theme: row.theme || null,
        themeScripture: row.themeScripture || null,
        venue: row.venue,
        address: row.address,
        startDate,
        endDate: new Date(row.endDate),
        language: row.language || 'en',
      },
    });
  }

  console.log(`Seeded ${rows.length} event templates`);
}

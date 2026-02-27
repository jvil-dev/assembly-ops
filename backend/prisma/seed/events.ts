/**
 * Seed script for Event data.
 * Reads events.csv and upserts each row directly into the Event table.
 * Resolves circuit code to circuitId via Circuit lookup.
 * Derives state from region (e.g. "US-MA" → "MA").
 * CSV columns: eventType, circuitCode, region, serviceYear, name, theme,
 *              themeScripture, venue, address, startDate, endDate, language
 */

import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EventType } from '@prisma/client';
import prisma from '../../src/config/database.js';
import { parseCSV } from './parseCSV.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function seedEvents() {
  const csvPath = resolve(__dirname, 'events.csv');
  const rows = parseCSV(csvPath);

  if (rows.length === 0) {
    console.log('No event data in CSV, skipping...');
    return;
  }

  console.log(`Seeding ${rows.length} events...`);

  for (const row of rows) {
    const eventType = row.eventType as EventType;
    const circuit = row.circuitCode || null;
    const startDate = new Date(row.startDate);
    const language = row.language || 'en';

    // Derive state from region (e.g. "US-MA" → "MA")
    const state = row.region.startsWith('US-') ? row.region.substring(3) : null;

    // Look up circuitId if circuitCode is provided
    let circuitId: string | null = null;
    if (row.circuitCode) {
      const circuitRecord = await prisma.circuit.findUnique({
        where: { code: row.circuitCode },
      });
      if (circuitRecord) {
        circuitId = circuitRecord.id;
      } else {
        console.warn(`  Circuit ${row.circuitCode} not found for event "${row.name}"`);
      }
    }

    await prisma.event.upsert({
      where: {
        eventType_venue_startDate_language: {
          eventType,
          venue: row.venue,
          startDate,
          language,
        },
      },
      update: {
        circuit,
        circuitId,
        region: row.region,
        state,
        serviceYear: parseInt(row.serviceYear, 10),
        name: row.name,
        theme: row.theme || null,
        themeScripture: row.themeScripture || null,
        address: row.address,
        endDate: new Date(row.endDate),
      },
      create: {
        eventType,
        circuit,
        circuitId,
        region: row.region,
        state,
        serviceYear: parseInt(row.serviceYear, 10),
        name: row.name,
        theme: row.theme || null,
        themeScripture: row.themeScripture || null,
        venue: row.venue,
        address: row.address,
        startDate,
        endDate: new Date(row.endDate),
        language,
      },
    });
  }

  console.log(`Seeded ${rows.length} events`);
}

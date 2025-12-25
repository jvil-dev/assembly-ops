/// <reference types="node" />
import { EventType } from '@prisma/client';
import prisma from '../src/config/database.js';

async function main() {
  console.log('Seeding EventTemplates...');

  const templates = [
    {
      eventType: EventType.CIRCUIT_ASSEMBLY,
      circuit: 'MA-11',
      region: 'US-MA',
      serviceYear: 2026,
      name: 'Circuit Assembly with Circuit Overseer',
      theme: 'Worship With Spirit and Truth',
      themeScripture: 'John 4:24',
      venue: 'Natick, Massachusetts (AH)',
      address: '85 Bacon St, Natick MA 01760-2901',
      startDate: new Date('2026-03-07'),
      endDate: new Date('2026-03-07'),
      language: 'en',
    },
    {
      eventType: EventType.REGIONAL_CONVENTION,
      circuit: null,
      region: 'US-MA',
      serviceYear: 2026,
      name: 'Regional Convention',
      theme: 'Eternal Happiness',
      themeScripture: null,
      venue: "Natick, MA Assembly Hall of Jehovah's Witnesses",
      address: '85 Bacon St, Natick MA 01760-2901',
      startDate: new Date('2026-06-12'),
      endDate: new Date('2026-06-14'),
      language: 'en',
    },
    {
      eventType: EventType.CIRCUIT_ASSEMBLY,
      circuit: 'MA-12',
      region: 'US-MA',
      serviceYear: 2026,
      name: 'Circuit Assembly with Circuit Overseer',
      theme: 'Worship With Spirit and Truth',
      themeScripture: 'John 4:24',
      venue: 'Natick, Massachusetts (AH)',
      address: '85 Bacon St, Natick MA 01760-2901',
      startDate: new Date('2026-03-14'),
      endDate: new Date('2026-03-14'),
      language: 'en',
    },
    {
      eventType: EventType.CIRCUIT_ASSEMBLY,
      circuit: 'MA-11',
      region: 'US-MA',
      serviceYear: 2026,
      name: 'Circuit Assembly',
      theme: null,
      themeScripture: null,
      venue: 'Natick, Massachusetts (AH)',
      address: '85 Bacon St, Natick MA 01760-2901',
      startDate: new Date('2026-09-12'),
      endDate: new Date('2026-09-12'),
      language: 'en',
    },
  ];

  for (const template of templates) {
    await prisma.eventTemplate.upsert({
      where: {
        eventType_circuit_startDate: {
          eventType: template.eventType,
          circuit: template.circuit ?? '',
          startDate: template.startDate,
        },
      },
      update: template,
      create: template,
    });
  }

  console.log(`Seeded ${templates.length} EventTemplates`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

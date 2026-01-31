/// <reference types="node" />
import { seedCircuits } from './seed/circuits.js';
import { seedCongregations } from './seed/congregations.js';
import { seedEventTemplates } from './seed/event_templates.js';

async function main() {
  console.log('Starting seed...\n');

  // Seed in order: circuits → congregations → event templates
  // (congregations reference circuits, templates reference circuits)
  await seedCircuits();
  await seedCongregations();
  await seedEventTemplates();

  console.log('\nSeed complete!');
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  });

/**
 * One-time script to create the app admin user.
 *
 * Usage:
 *   EMAIL=you@example.com PASSWORD=yourpassword FIRST=Your LAST=Name \
 *     npx tsx prisma/create-admin.ts
 *
 * The user is created with isAppAdmin: true.
 * Safe to re-run — it upserts by email, so running it again just updates the password.
 */
import { hashPassword } from '../src/utils/password.js';
import { generateUserId } from '../src/utils/credentials.js';
import prisma from '../src/config/database.js';

async function main() {
  const email = process.env.EMAIL;
  const password = process.env.PASSWORD;
  const firstName = process.env.FIRST ?? 'Admin';
  const lastName = process.env.LAST ?? 'User';

  if (!email || !password) {
    console.error('Error: EMAIL and PASSWORD env vars are required.\n');
    console.error('Usage:');
    console.error('  EMAIL=you@example.com PASSWORD=yourpassword FIRST=Your LAST=Name npx tsx prisma/create-admin.ts');
    process.exit(1);
  }

  const passwordHash = await hashPassword(password);

  const existing = await prisma.user.findUnique({ where: { email } });

  if (existing) {
    // Update existing user — set isAppAdmin and refresh password
    const updated = await prisma.user.update({
      where: { email },
      data: {
        passwordHash,
        isAppAdmin: true,
        firstName,
        lastName,
      },
    });
    console.log(`✓ Updated existing user: ${updated.email} (userId: ${updated.userId})`);
    console.log(`  isAppAdmin: ${updated.isAppAdmin}`);
  } else {
    // Create new admin user
    const userId = generateUserId();
    const created = await prisma.user.create({
      data: {
        userId,
        email,
        passwordHash,
        firstName,
        lastName,
        isAppAdmin: true,
      },
    });
    console.log(`✓ Created admin user: ${created.email} (userId: ${created.userId})`);
    console.log(`  isAppAdmin: ${created.isAppAdmin}`);
  }
}

main()
  .catch(e => {
    console.error('Failed:', e.message);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

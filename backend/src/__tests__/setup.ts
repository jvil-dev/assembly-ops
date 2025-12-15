import { prisma } from "../config/database.js";

// Clean up database connections after all tests
afterAll(async () => {
  await prisma.$disconnect();
});

// Optional: Clear database between tests (for integration tests)
// Uncomment if you want a clean slate for each test file
// beforeEach(async () => {
//   await prisma.checkIn.deleteMany();
//   await prisma.swapRequest.deleteMany();
//   await prisma.assignment.deleteMany();
//   await prisma.volunteerAvailability.deleteMany();
//   await prisma.volunteer.deleteMany();
//   await prisma.zone.deleteMany();
//   await prisma.session.deleteMany();
//   await prisma.role.deleteMany();
//   await prisma.event.deleteMany();
//   await prisma.admin.deleteMany();
// });

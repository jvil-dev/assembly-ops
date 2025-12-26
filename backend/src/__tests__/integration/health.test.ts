import request from 'supertest';
import app from '../../app.js';
import prisma from '../../config/database.js';

afterAll(async () => {
  await prisma.$disconnect();
});

describe('GET /health', () => {
  it('should return healthy status', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'healthy');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body.services).toHaveProperty('database', 'connected');
  });
});

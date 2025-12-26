import request from 'supertest';
import app from '../../server.js';

describe('GET /health', () => {
  it('should return healthy status', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'healthy');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body.services).toHaveProperty('database', 'connected');
  });
});

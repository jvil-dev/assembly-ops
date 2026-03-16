/**
 * Floor Plan Service
 *
 * Manages event floor plan images stored in Google Cloud Storage.
 * Generates signed URLs for upload and view access.
 *
 * Methods:
 *   - getUploadUrl(eventId): Generate a signed GCS PUT URL for uploading a floor plan
 *   - confirmUpload(eventId): Persist the GCS key to the event record after upload completes
 *   - getViewUrl(eventId): Generate a signed GCS GET URL for viewing the floor plan
 *   - delete(eventId): Remove the floor plan from GCS and clear the DB reference
 *
 * Called by: ../graphql/resolvers/floorPlan.ts
 */
import { Storage } from '@google-cloud/storage';
import { PrismaClient } from '@prisma/client';
import { NotFoundError } from '../utils/errors.js';
import { logger } from '../utils/logger.js';

const storage = new Storage();
const BUCKET = process.env.GCS_BUCKET?.trim() ?? '';

/** Validate GCS_BUCKET is set and the bucket is accessible. Call at startup. */
export async function validateGcsBucket(): Promise<void> {
  if (!BUCKET) {
    throw new Error('GCS_BUCKET environment variable is required');
  }
  const [exists] = await storage.bucket(BUCKET).exists();
  if (!exists) {
    throw new Error(`GCS bucket "${BUCKET}" does not exist or is not accessible`);
  }
  logger.info('GCS bucket verified', { bucket: BUCKET });
}

export class FloorPlanService {
  constructor(private prisma: PrismaClient) {}

  async getUploadUrl(eventId: string): Promise<string> {
    const key = `floor-plans/${eventId}.jpg`;
    logger.debug('Generating GCS signed upload URL', { bucket: BUCKET, key });
    const [url] = await storage.bucket(BUCKET).file(key).getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + 5 * 60 * 1000,
      contentType: 'image/jpeg',
    });
    return url;
  }

  async confirmUpload(eventId: string): Promise<void> {
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      select: { id: true },
    });
    if (!event) {
      throw new NotFoundError('Event');
    }
    const key = `floor-plans/${eventId}.jpg`;
    await this.prisma.event.update({ where: { id: eventId }, data: { floorPlanKey: key } });
  }

  async getViewUrl(eventId: string): Promise<string | null> {
    const event = await this.prisma.event.findUnique({ where: { id: eventId }, select: { floorPlanKey: true } });
    if (!event?.floorPlanKey) return null;
    const [url] = await storage.bucket(BUCKET).file(event.floorPlanKey).getSignedUrl({
      version: 'v4',
      action: 'read',
      expires: Date.now() + 60 * 60 * 1000,
    });
    return url;
  }

  async delete(eventId: string): Promise<void> {
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      select: { floorPlanKey: true },
    });

    const key = event?.floorPlanKey;

    // Clear the DB reference first. If the GCS delete below fails, the floor plan
    // becomes unreachable (no signed URL is generated) rather than generating
    // a broken URL pointing to a deleted object.
    await this.prisma.event.update({ where: { id: eventId }, data: { floorPlanKey: null } });

    if (key) {
      await storage.bucket(BUCKET).file(key).delete();
    }
  }
}

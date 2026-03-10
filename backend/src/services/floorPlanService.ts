/**
 * Floor Plan Service
 *
 * Manages event floor plan images stored in S3.
 * Generates presigned URLs for upload and view access.
 *
 * Methods:
 *   - getUploadUrl(eventId): Generate a presigned S3 PUT URL for uploading a floor plan
 *   - confirmUpload(eventId): Persist the S3 key to the event record after upload completes
 *   - getViewUrl(eventId): Generate a presigned S3 GET URL for viewing the floor plan
 *   - delete(eventId): Remove the floor plan from S3 and clear the DB reference
 *
 * Called by: ../graphql/resolvers/floorPlan.ts
 */
import { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { PrismaClient } from '@prisma/client';
import { NotFoundError } from '../utils/errors.js';

const s3 = new S3Client({ region: process.env.AWS_REGION });
const BUCKET = process.env.AWS_S3_BUCKET!;

export class FloorPlanService {
  constructor(private prisma: PrismaClient) {}

  async getUploadUrl(eventId: string): Promise<string> {
    const key = `floor-plans/${eventId}.jpg`;
    const cmd = new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: 'image/jpeg' });
    return getSignedUrl(s3, cmd, { expiresIn: 300 });
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
    const cmd = new GetObjectCommand({ Bucket: BUCKET, Key: event.floorPlanKey });
    return getSignedUrl(s3, cmd, { expiresIn: 3600 });
  }

  async delete(eventId: string): Promise<void> {
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      select: { floorPlanKey: true },
    });

    const key = event?.floorPlanKey;

    // Clear the DB reference first. If the S3 delete below fails, the floor plan
    // becomes unreachable (no presigned URL is generated) rather than generating
    // a broken URL pointing to a deleted object.
    await this.prisma.event.update({ where: { id: eventId }, data: { floorPlanKey: null } });

    if (key) {
      await s3.send(new DeleteObjectCommand({ Bucket: BUCKET, Key: key }));
    }
  }
}

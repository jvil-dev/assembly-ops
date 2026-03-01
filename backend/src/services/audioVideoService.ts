/**
 * Audio/Video Department Service
 *
 * Business logic for AV department features: equipment inventory,
 * checkout/return, damage reports, hazard assessments, and safety briefings.
 *
 * Methods:
 *   Equipment:
 *   - createEquipment(input): Add an equipment item
 *   - bulkCreateEquipment(input): Add multiple equipment items
 *   - updateEquipment(id, input): Update an equipment item
 *   - deleteEquipment(id): Remove an equipment item
 *   - getEquipment(eventId, category?, areaId?): List equipment with optional filters
 *   - getEquipmentItem(id): Get a single equipment item with full details
 *   - getEquipmentSummary(eventId): Aggregate stats for dashboard
 *   - getEquipmentCheckouts(eventId, checkedIn?): List checkouts
 *
 *   Checkout:
 *   - checkoutEquipment(input): Check out equipment to a volunteer
 *   - returnEquipment(checkoutId): Return checked-out equipment
 *
 *   Damage:
 *   - reportDamage(reportedById, input): Report equipment damage
 *   - resolveDamage(id, userId, resolutionNotes?): Resolve a damage report
 *   - getDamageReports(eventId, resolved?): List damage reports
 *
 *   Hazard Assessments:
 *   - createHazardAssessment(completedById, input): Create a hazard assessment
 *   - deleteHazardAssessment(id): Remove a hazard assessment
 *   - getHazardAssessments(eventId): List hazard assessments
 *
 *   Safety Briefings:
 *   - createSafetyBriefing(conductedById, input): Create a safety briefing
 *   - updateBriefingNotes(id, notes): Update briefing notes
 *   - deleteSafetyBriefing(id): Remove a safety briefing
 *   - getSafetyBriefings(eventId): List safety briefings
 *   - getMySafetyBriefings(eventVolunteerId): Briefings where volunteer attended
 *
 *   Access Control:
 *   - getEquipmentEventId(id): Get event ID for equipment item
 *   - getCheckoutEventId(checkoutId): Get event ID for checkout
 *   - getDamageReportEventId(id): Get event ID for damage report
 *   - getHazardAssessmentEventId(id): Get event ID for hazard assessment
 *   - getBriefingEventId(id): Get event ID for safety briefing
 *
 * Called by: ../graphql/resolvers/audioVideo.ts
 */
import {
  PrismaClient,
  AVEquipmentItem,
  AVEquipmentCheckout,
  AVDamageReport,
  AVHazardAssessment,
  AVSafetyBriefing,
  AVEquipmentCategory,
} from '@prisma/client';
import { NotFoundError, ValidationError } from '../utils/errors.js';
import {
  createAVEquipmentSchema,
  bulkCreateAVEquipmentSchema,
  updateAVEquipmentSchema,
  checkoutEquipmentSchema,
  reportAVDamageSchema,
  createAVHazardAssessmentSchema,
  createAVSafetyBriefingSchema,
  CreateAVEquipmentInput,
  BulkCreateAVEquipmentInput,
  UpdateAVEquipmentInput,
  CheckoutEquipmentInput,
  ReportAVDamageInput,
  CreateAVHazardAssessmentInput,
  CreateAVSafetyBriefingInput,
} from '../graphql/validators/audioVideo.js';

export interface AVEquipmentSummary {
  totalItems: number;
  checkedOutCount: number;
  needsRepairCount: number;
  outOfServiceCount: number;
  byCategory: AVCategorySummary[];
}

export interface AVCategorySummary {
  category: string;
  count: number;
  checkedOutCount: number;
}

export class AudioVideoService {
  constructor(private prisma: PrismaClient) {}

  // MARK: - Equipment CRUD

  async createEquipment(input: CreateAVEquipmentInput): Promise<AVEquipmentItem> {
    const result = createAVEquipmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    return this.prisma.aVEquipmentItem.create({
      data: result.data,
      include: { area: true },
    });
  }

  async bulkCreateEquipment(input: BulkCreateAVEquipmentInput): Promise<AVEquipmentItem[]> {
    const result = bulkCreateAVEquipmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, items } = result.data;
    const created: AVEquipmentItem[] = [];

    for (const item of items) {
      const record = await this.prisma.aVEquipmentItem.create({
        data: { ...item, eventId },
        include: { area: true },
      });
      created.push(record);
    }

    return created;
  }

  async updateEquipment(id: string, input: UpdateAVEquipmentInput): Promise<AVEquipmentItem> {
    const result = updateAVEquipmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const existing = await this.prisma.aVEquipmentItem.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('AV equipment item');
    }

    // Convert nullable optionals: undefined = don't update, null = clear field
    const data: Record<string, unknown> = {};
    const validated = result.data;
    for (const [key, value] of Object.entries(validated)) {
      if (value !== undefined) {
        data[key] = value;
      }
    }

    return this.prisma.aVEquipmentItem.update({
      where: { id },
      data,
      include: { area: true },
    });
  }

  async deleteEquipment(id: string): Promise<boolean> {
    const existing = await this.prisma.aVEquipmentItem.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('AV equipment item');
    }

    await this.prisma.aVEquipmentItem.delete({ where: { id } });
    return true;
  }

  async getEquipment(
    eventId: string,
    category?: string,
    areaId?: string
  ): Promise<AVEquipmentItem[]> {
    return this.prisma.aVEquipmentItem.findMany({
      where: {
        eventId,
        ...(category ? { category: category as AVEquipmentCategory } : {}),
        ...(areaId ? { areaId } : {}),
      },
      include: { area: true },
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });
  }

  async getEquipmentItem(id: string): Promise<AVEquipmentItem | null> {
    return this.prisma.aVEquipmentItem.findUnique({
      where: { id },
      include: {
        area: true,
        event: true,
        checkouts: {
          include: { checkedOutBy: { include: { user: true } }, session: true },
          orderBy: { checkedOutAt: 'desc' },
        },
        damageReports: {
          include: { reportedBy: { include: { user: true } }, resolvedBy: true, session: true },
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }

  async getEquipmentSummary(eventId: string): Promise<AVEquipmentSummary> {
    const [allItems, openCheckouts] = await Promise.all([
      this.prisma.aVEquipmentItem.findMany({
        where: { eventId },
        select: { id: true, category: true, condition: true },
      }),
      this.prisma.aVEquipmentCheckout.findMany({
        where: {
          equipment: { eventId },
          checkedInAt: null,
        },
        select: { equipmentId: true, equipment: { select: { category: true } } },
      }),
    ]);

    const checkedOutIds = new Set(openCheckouts.map((c) => c.equipmentId));

    // Build per-category summaries
    const categoryMap = new Map<string, { count: number; checkedOutCount: number }>();
    for (const item of allItems) {
      const entry = categoryMap.get(item.category) || { count: 0, checkedOutCount: 0 };
      entry.count++;
      if (checkedOutIds.has(item.id)) {
        entry.checkedOutCount++;
      }
      categoryMap.set(item.category, entry);
    }

    return {
      totalItems: allItems.length,
      checkedOutCount: checkedOutIds.size,
      needsRepairCount: allItems.filter((i) => i.condition === 'NEEDS_REPAIR').length,
      outOfServiceCount: allItems.filter((i) => i.condition === 'OUT_OF_SERVICE').length,
      byCategory: Array.from(categoryMap.entries()).map(([category, stats]) => ({
        category,
        ...stats,
      })),
    };
  }

  async getEquipmentCheckouts(
    eventId: string,
    checkedIn?: boolean
  ): Promise<AVEquipmentCheckout[]> {
    return this.prisma.aVEquipmentCheckout.findMany({
      where: {
        equipment: { eventId },
        ...(checkedIn === true
          ? { checkedInAt: { not: null } }
          : checkedIn === false
            ? { checkedInAt: null }
            : {}),
      },
      include: {
        equipment: true,
        checkedOutBy: { include: { user: true } },
        session: true,
      },
      orderBy: { checkedOutAt: 'desc' },
    });
  }

  // MARK: - Checkout / Return

  async checkoutEquipment(input: CheckoutEquipmentInput): Promise<AVEquipmentCheckout> {
    const result = checkoutEquipmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { equipmentId, checkedOutById, sessionId, notes } = result.data;

    // Verify equipment exists
    const equipment = await this.prisma.aVEquipmentItem.findUnique({
      where: { id: equipmentId },
    });
    if (!equipment) {
      throw new NotFoundError('AV equipment item');
    }

    // Verify no open checkout
    const openCheckout = await this.prisma.aVEquipmentCheckout.findFirst({
      where: { equipmentId, checkedInAt: null },
    });
    if (openCheckout) {
      throw new ValidationError('Equipment is already checked out');
    }

    return this.prisma.aVEquipmentCheckout.create({
      data: { equipmentId, checkedOutById, sessionId, notes },
      include: {
        equipment: true,
        checkedOutBy: { include: { user: true } },
        session: true,
      },
    });
  }

  async returnEquipment(checkoutId: string): Promise<AVEquipmentCheckout> {
    const checkout = await this.prisma.aVEquipmentCheckout.findUnique({
      where: { id: checkoutId },
    });
    if (!checkout) {
      throw new NotFoundError('Equipment checkout');
    }
    if (checkout.checkedInAt) {
      throw new ValidationError('Equipment has already been returned');
    }

    return this.prisma.aVEquipmentCheckout.update({
      where: { id: checkoutId },
      data: { checkedInAt: new Date() },
      include: {
        equipment: true,
        checkedOutBy: { include: { user: true } },
        session: true,
      },
    });
  }

  // MARK: - Damage Reports

  async reportDamage(
    reportedById: string,
    input: ReportAVDamageInput
  ): Promise<AVDamageReport> {
    const result = reportAVDamageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    return this.prisma.aVDamageReport.create({
      data: {
        ...result.data,
        reportedById,
      },
      include: {
        equipment: true,
        reportedBy: { include: { user: true } },
        session: true,
      },
    });
  }

  async resolveDamage(
    id: string,
    userId: string,
    resolutionNotes?: string
  ): Promise<AVDamageReport> {
    const existing = await this.prisma.aVDamageReport.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Damage report');
    }

    // Update the parent equipment condition based on severity
    const newCondition =
      existing.severity === 'SEVERE' ? 'OUT_OF_SERVICE' : 'NEEDS_REPAIR';

    await this.prisma.aVEquipmentItem.update({
      where: { id: existing.equipmentId },
      data: { condition: newCondition },
    });

    return this.prisma.aVDamageReport.update({
      where: { id },
      data: {
        resolved: true,
        resolvedAt: new Date(),
        resolvedById: userId,
        resolutionNotes,
      },
      include: {
        equipment: true,
        reportedBy: { include: { user: true } },
        resolvedBy: true,
        session: true,
      },
    });
  }

  async getDamageReports(eventId: string, resolved?: boolean): Promise<AVDamageReport[]> {
    return this.prisma.aVDamageReport.findMany({
      where: {
        equipment: { eventId },
        ...(resolved !== undefined ? { resolved } : {}),
      },
      include: {
        equipment: true,
        reportedBy: { include: { user: true } },
        resolvedBy: true,
        session: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // MARK: - Hazard Assessments

  async createHazardAssessment(
    completedById: string,
    input: CreateAVHazardAssessmentInput
  ): Promise<AVHazardAssessment> {
    const result = createAVHazardAssessmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    return this.prisma.aVHazardAssessment.create({
      data: {
        ...result.data,
        completedById,
      },
      include: { completedBy: true, session: true, event: true },
    });
  }

  async deleteHazardAssessment(id: string): Promise<boolean> {
    const existing = await this.prisma.aVHazardAssessment.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Hazard assessment');
    }

    await this.prisma.aVHazardAssessment.delete({ where: { id } });
    return true;
  }

  async getHazardAssessments(eventId: string): Promise<AVHazardAssessment[]> {
    return this.prisma.aVHazardAssessment.findMany({
      where: { eventId },
      include: { completedBy: true, session: true },
      orderBy: { completedAt: 'desc' },
    });
  }

  // MARK: - Safety Briefings

  async createSafetyBriefing(
    conductedById: string,
    input: CreateAVSafetyBriefingInput
  ): Promise<AVSafetyBriefing> {
    const result = createAVSafetyBriefingSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, topic, notes, attendeeIds } = result.data;

    return this.prisma.aVSafetyBriefing.create({
      data: {
        eventId,
        topic,
        notes,
        conductedById,
        attendees: {
          create: attendeeIds.map((id) => ({ eventVolunteerId: id })),
        },
      },
      include: {
        conductedBy: true,
        event: true,
        attendees: { include: { eventVolunteer: { include: { user: true } } } },
      },
    });
  }

  async updateBriefingNotes(id: string, notes: string): Promise<AVSafetyBriefing> {
    const existing = await this.prisma.aVSafetyBriefing.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Safety briefing');
    }

    return this.prisma.aVSafetyBriefing.update({
      where: { id },
      data: { notes },
      include: {
        conductedBy: true,
        event: true,
        attendees: { include: { eventVolunteer: { include: { user: true } } } },
      },
    });
  }

  async deleteSafetyBriefing(id: string): Promise<boolean> {
    const existing = await this.prisma.aVSafetyBriefing.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Safety briefing');
    }

    await this.prisma.aVSafetyBriefing.delete({ where: { id } });
    return true;
  }

  async getSafetyBriefings(eventId: string): Promise<AVSafetyBriefing[]> {
    return this.prisma.aVSafetyBriefing.findMany({
      where: { eventId },
      include: {
        conductedBy: true,
        attendees: { include: { eventVolunteer: { include: { user: true } } } },
      },
      orderBy: { conductedAt: 'desc' },
    });
  }

  async getMySafetyBriefings(eventVolunteerId: string): Promise<AVSafetyBriefing[]> {
    return this.prisma.aVSafetyBriefing.findMany({
      where: {
        attendees: {
          some: { eventVolunteerId },
        },
      },
      include: {
        conductedBy: true,
        attendees: { include: { eventVolunteer: { include: { user: true } } } },
      },
      orderBy: { conductedAt: 'desc' },
    });
  }

  // MARK: - Access Control Helpers

  async getEquipmentEventId(id: string): Promise<string> {
    const item = await this.prisma.aVEquipmentItem.findUnique({
      where: { id },
      select: { eventId: true },
    });
    if (!item) {
      throw new NotFoundError('AV equipment item');
    }
    return item.eventId;
  }

  async getCheckoutEventId(checkoutId: string): Promise<string> {
    const checkout = await this.prisma.aVEquipmentCheckout.findUnique({
      where: { id: checkoutId },
      include: { equipment: { select: { eventId: true } } },
    });
    if (!checkout) {
      throw new NotFoundError('Equipment checkout');
    }
    return checkout.equipment.eventId;
  }

  async getDamageReportEventId(id: string): Promise<string> {
    const report = await this.prisma.aVDamageReport.findUnique({
      where: { id },
      include: { equipment: { select: { eventId: true } } },
    });
    if (!report) {
      throw new NotFoundError('Damage report');
    }
    return report.equipment.eventId;
  }

  async getHazardAssessmentEventId(id: string): Promise<string> {
    const assessment = await this.prisma.aVHazardAssessment.findUnique({
      where: { id },
      select: { eventId: true },
    });
    if (!assessment) {
      throw new NotFoundError('Hazard assessment');
    }
    return assessment.eventId;
  }

  async getBriefingEventId(id: string): Promise<string> {
    const briefing = await this.prisma.aVSafetyBriefing.findUnique({
      where: { id },
      select: { eventId: true },
    });
    if (!briefing) {
      throw new NotFoundError('Safety briefing');
    }
    return briefing.eventId;
  }
}

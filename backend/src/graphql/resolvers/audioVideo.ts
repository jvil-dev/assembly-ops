/**
 * Equipment & Safety Resolvers
 *
 * GraphQL resolvers for equipment inventory, checkout/return, damage reports,
 * hazard assessments, and safety briefings. These features are event-scoped
 * and accessible to any event volunteer or overseer.
 *
 * Authorization:
 *   - Equipment CRUD / hazard assessments: Overseer auth + event access
 *   - Checkout/return / damage report: Event volunteer or overseer
 *   - Safety briefings: Overseer (create/manage), volunteer (view own)
 *   - Equipment queries: Event volunteer or overseer
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { AudioVideoService } from '../../services/audioVideoService.js';
import { requireAdmin, requireAuth, requireEventAccess, resolveUserEventVolunteer } from '../guards/auth.js';
import {
  CreateAVEquipmentInput,
  BulkCreateAVEquipmentInput,
  UpdateAVEquipmentInput,
  CheckoutEquipmentInput,
  ReportAVDamageInput,
  CreateAVHazardAssessmentInput,
  CreateAVSafetyBriefingInput,
} from '../validators/audioVideo.js';
import { AuthorizationError } from '../../utils/errors.js';

/**
 * Helper: resolve the EventVolunteer record for the authenticated user.
 * Verifies they belong to the event as a volunteer.
 */
async function resolveEventVolunteer(
  context: Context,
  eventId: string
): Promise<{ eventVolunteerId: string }> {
  if (!context.user) throw new AuthorizationError('You must be logged in');
  const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user.id, eventId } },
  });

  if (!eventVolunteer) {
    throw new AuthorizationError('You must be a volunteer for this event');
  }

  return { eventVolunteerId: eventVolunteer.id };
}

const audioVideoResolvers = {
  Query: {
    // ── Equipment Queries ──────────────────────────────

    avEquipment: async (
      _parent: unknown,
      { eventId, category, areaId }: { eventId: string; category?: string; areaId?: string },
      context: Context
    ) => {
      requireAuth(context);
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveEventVolunteer(context, eventId);
      }

      const avService = new AudioVideoService(context.prisma);
      return avService.getEquipment(eventId, category, areaId);
    },

    avEquipmentItem: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAuth(context);
      const avService = new AudioVideoService(context.prisma);
      return avService.getEquipmentItem(id);
    },

    avEquipmentSummary: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveEventVolunteer(context, eventId);
      }

      const avService = new AudioVideoService(context.prisma);
      return avService.getEquipmentSummary(eventId);
    },

    avEquipmentCheckouts: async (
      _parent: unknown,
      { eventId, checkedIn }: { eventId: string; checkedIn?: boolean },
      context: Context
    ) => {
      requireAuth(context);
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveEventVolunteer(context, eventId);
      }

      const avService = new AudioVideoService(context.prisma);
      return avService.getEquipmentCheckouts(eventId, checkedIn);
    },

    // ── Damage Queries ─────────────────────────────────

    avDamageReports: async (
      _parent: unknown,
      { eventId, resolved }: { eventId: string; resolved?: boolean },
      context: Context
    ) => {
      requireAuth(context);
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveEventVolunteer(context, eventId);
      }

      const avService = new AudioVideoService(context.prisma);
      return avService.getDamageReports(eventId, resolved);
    },

    // ── Safety Queries ─────────────────────────────────

    avHazardAssessments: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveEventVolunteer(context, eventId);
      }

      const avService = new AudioVideoService(context.prisma);
      return avService.getHazardAssessments(eventId);
    },

    avSafetyBriefings: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const avService = new AudioVideoService(context.prisma);
      return avService.getSafetyBriefings(eventId);
    },

    myAVSafetyBriefings: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      const { eventVolunteerId } = await resolveEventVolunteer(context, eventId);

      const avService = new AudioVideoService(context.prisma);
      return avService.getMySafetyBriefings(eventVolunteerId);
    },
  },

  Mutation: {
    // ── Equipment CRUD ─────────────────────────────────

    createAVEquipment: async (
      _parent: unknown,
      { input }: { input: CreateAVEquipmentInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      const avService = new AudioVideoService(context.prisma);
      return avService.createEquipment(input);
    },

    bulkCreateAVEquipment: async (
      _parent: unknown,
      { input }: { input: BulkCreateAVEquipmentInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      const avService = new AudioVideoService(context.prisma);
      return avService.bulkCreateEquipment(input);
    },

    updateAVEquipment: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateAVEquipmentInput },
      context: Context
    ) => {
      requireAdmin(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getEquipmentEventId(id);
      await requireEventAccess(context, eventId);

      return avService.updateEquipment(id, input);
    },

    deleteAVEquipment: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAdmin(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getEquipmentEventId(id);
      await requireEventAccess(context, eventId);

      return avService.deleteEquipment(id);
    },

    // ── Checkout / Return ──────────────────────────────

    checkoutEquipment: async (
      _parent: unknown,
      { input }: { input: CheckoutEquipmentInput },
      context: Context
    ) => {
      requireAuth(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getEquipmentEventId(input.equipmentId);

      // Either admin or AV volunteer can checkout
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveEventVolunteer(context, eventId);
      }

      return avService.checkoutEquipment(input);
    },

    returnEquipment: async (
      _parent: unknown,
      { checkoutId }: { checkoutId: string },
      context: Context
    ) => {
      requireAuth(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getCheckoutEventId(checkoutId);

      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveEventVolunteer(context, eventId);
      }

      return avService.returnEquipment(checkoutId);
    },

    // ── Damage Reports ─────────────────────────────────

    reportAVDamage: async (
      _parent: unknown,
      { input }: { input: ReportAVDamageInput },
      context: Context
    ) => {
      requireAuth(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getEquipmentEventId(input.equipmentId);
      const { eventVolunteerId } = await resolveEventVolunteer(context, eventId);

      return avService.reportDamage(eventVolunteerId, input);
    },

    resolveAVDamage: async (
      _parent: unknown,
      { id, resolutionNotes }: { id: string; resolutionNotes?: string },
      context: Context
    ) => {
      requireAdmin(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getDamageReportEventId(id);
      await requireEventAccess(context, eventId);

      return avService.resolveDamage(id, context.user!.id, resolutionNotes);
    },

    // ── Hazard Assessments ─────────────────────────────

    createAVHazardAssessment: async (
      _parent: unknown,
      { input }: { input: CreateAVHazardAssessmentInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      const avService = new AudioVideoService(context.prisma);
      return avService.createHazardAssessment(context.user!.id, input);
    },

    deleteAVHazardAssessment: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAdmin(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getHazardAssessmentEventId(id);
      await requireEventAccess(context, eventId);

      return avService.deleteHazardAssessment(id);
    },

    // ── Safety Briefings ───────────────────────────────

    createAVSafetyBriefing: async (
      _parent: unknown,
      { input }: { input: CreateAVSafetyBriefingInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      const avService = new AudioVideoService(context.prisma);
      return avService.createSafetyBriefing(context.user!.id, input);
    },

    updateAVSafetyBriefingNotes: async (
      _parent: unknown,
      { id, notes }: { id: string; notes: string },
      context: Context
    ) => {
      requireAdmin(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getBriefingEventId(id);
      await requireEventAccess(context, eventId);

      return avService.updateBriefingNotes(id, notes);
    },

    deleteAVSafetyBriefing: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAdmin(context);

      const avService = new AudioVideoService(context.prisma);
      const eventId = await avService.getBriefingEventId(id);
      await requireEventAccess(context, eventId);

      return avService.deleteSafetyBriefing(id);
    },
  },

  // ── Type Resolvers ─────────────────────────────────

  AVEquipmentItem: {
    currentCheckout: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      return context.prisma.aVEquipmentCheckout.findFirst({
        where: { equipmentId: parent.id as string, checkedInAt: null },
        include: { checkedOutBy: { include: { user: true } }, session: true },
      });
    },
    checkoutHistory: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      return context.prisma.aVEquipmentCheckout.findMany({
        where: { equipmentId: parent.id as string },
        include: { checkedOutBy: { include: { user: true } }, session: true },
        orderBy: { checkedOutAt: 'desc' },
      });
    },
    damageReports: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      return context.prisma.aVDamageReport.findMany({
        where: { equipmentId: parent.id as string },
        include: { reportedBy: { include: { user: true } }, resolvedBy: true, session: true },
        orderBy: { createdAt: 'desc' },
      });
    },
    area: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if (!parent.areaId) return null;
      return context.prisma.area.findUnique({ where: { id: parent.areaId as string } });
    },
    event: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      return context.prisma.event.findUnique({ where: { id: parent.eventId as string } });
    },
  },

  AVEquipmentCheckout: {
    equipment: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).equipment) return (parent as any).equipment;
      return context.prisma.aVEquipmentItem.findUnique({ where: { id: parent.equipmentId as string } });
    },
    checkedOutBy: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).checkedOutBy) return (parent as any).checkedOutBy;
      return context.prisma.eventVolunteer.findUnique({
        where: { id: parent.checkedOutById as string },
        include: { user: true },
      });
    },
    session: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).session !== undefined) return (parent as any).session;
      if (!parent.sessionId) return null;
      return context.prisma.session.findUnique({ where: { id: parent.sessionId as string } });
    },
  },

  AVDamageReport: {
    equipment: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).equipment) return (parent as any).equipment;
      return context.prisma.aVEquipmentItem.findUnique({ where: { id: parent.equipmentId as string } });
    },
    reportedBy: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).reportedBy) return (parent as any).reportedBy;
      return context.prisma.eventVolunteer.findUnique({
        where: { id: parent.reportedById as string },
        include: { user: true },
      });
    },
    resolvedBy: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).resolvedBy !== undefined) return (parent as any).resolvedBy;
      if (!parent.resolvedById) return null;
      return context.prisma.user.findUnique({ where: { id: parent.resolvedById as string } });
    },
    session: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).session !== undefined) return (parent as any).session;
      if (!parent.sessionId) return null;
      return context.prisma.session.findUnique({ where: { id: parent.sessionId as string } });
    },
  },

  AVHazardAssessment: {
    completedBy: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).completedBy) return (parent as any).completedBy;
      return context.prisma.user.findUnique({ where: { id: parent.completedById as string } });
    },
    event: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).event) return (parent as any).event;
      return context.prisma.event.findUnique({ where: { id: parent.eventId as string } });
    },
    session: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).session !== undefined) return (parent as any).session;
      if (!parent.sessionId) return null;
      return context.prisma.session.findUnique({ where: { id: parent.sessionId as string } });
    },
  },

  AVSafetyBriefing: {
    conductedBy: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).conductedBy) return (parent as any).conductedBy;
      return context.prisma.user.findUnique({ where: { id: parent.conductedById as string } });
    },
    event: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).event) return (parent as any).event;
      return context.prisma.event.findUnique({ where: { id: parent.eventId as string } });
    },
    attendees: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).attendees) return (parent as any).attendees;
      return context.prisma.aVSafetyBriefingAttendee.findMany({
        where: { briefingId: parent.id as string },
        include: { eventVolunteer: { include: { user: true } } },
      });
    },
    attendeeCount: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if ((parent as any).attendees) return (parent as any).attendees.length;
      return context.prisma.aVSafetyBriefingAttendee.count({
        where: { briefingId: parent.id as string },
      });
    },
  },
};

export default audioVideoResolvers;

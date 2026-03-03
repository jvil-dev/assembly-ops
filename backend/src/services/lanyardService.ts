/**
 * Lanyard Tracking Service
 *
 * Business logic for per-day lanyard pickup/return tracking.
 * Uses upsert on the compound unique [eventVolunteerId, date] to ensure
 * one record per volunteer per day.
 *
 * Methods:
 *   - pickUp(eventVolunteerId, eventId): Mark lanyard picked up today
 *   - returnLanyard(eventVolunteerId, eventId): Mark lanyard returned today
 *   - resetLanyard(eventVolunteerId, eventId): Reset lanyard to not picked up
 *   - getMyStatus(eventVolunteerId, date?): Get volunteer's status
 *   - getStatuses(eventId, date?): All volunteers' statuses for a day
 *   - getSummary(eventId, date?): Aggregate counts
 *
 * Used by: ../graphql/resolvers/lanyard.ts
 */
import { PrismaClient } from '@prisma/client';

export class LanyardService {
  constructor(private prisma: PrismaClient) {}

  private getDateOnly(dateStr?: string): Date {
    if (dateStr) {
      return new Date(dateStr + 'T00:00:00.000Z');
    }
    const now = new Date();
    return new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
  }

  async pickUp(eventVolunteerId: string, eventId: string) {
    const date = this.getDateOnly();
    return this.prisma.lanyardCheckout.upsert({
      where: {
        eventVolunteerId_date: { eventVolunteerId, date },
      },
      update: {
        pickedUpAt: new Date(),
      },
      create: {
        eventVolunteerId,
        eventId,
        date,
        pickedUpAt: new Date(),
      },
      include: {
        eventVolunteer: { include: { user: true } },
      },
    });
  }

  async returnLanyard(eventVolunteerId: string, eventId: string) {
    const date = this.getDateOnly();
    return this.prisma.lanyardCheckout.upsert({
      where: {
        eventVolunteerId_date: { eventVolunteerId, date },
      },
      update: {
        returnedAt: new Date(),
      },
      create: {
        eventVolunteerId,
        eventId,
        date,
        pickedUpAt: new Date(), // Auto-mark pickup if returning without explicit pickup
        returnedAt: new Date(),
      },
      include: {
        eventVolunteer: { include: { user: true } },
      },
    });
  }

  async resetLanyard(eventVolunteerId: string, eventId: string) {
    const date = this.getDateOnly();
    // Delete the checkout record to reset to "not picked up"
    const existing = await this.prisma.lanyardCheckout.findUnique({
      where: { eventVolunteerId_date: { eventVolunteerId, date } },
    });
    if (existing) {
      await this.prisma.lanyardCheckout.delete({
        where: { id: existing.id },
      });
    }
    // Return a virtual "not picked up" record
    const vol = await this.prisma.eventVolunteer.findUniqueOrThrow({
      where: { id: eventVolunteerId },
      include: { user: true },
    });
    return {
      id: `pending-${vol.id}`,
      eventVolunteerId: vol.id,
      eventId,
      date,
      pickedUpAt: null,
      returnedAt: null,
      eventVolunteer: vol,
    };
  }

  async getMyStatus(eventVolunteerId: string, dateStr?: string) {
    const date = this.getDateOnly(dateStr);
    return this.prisma.lanyardCheckout.findUnique({
      where: {
        eventVolunteerId_date: { eventVolunteerId, date },
      },
      include: {
        eventVolunteer: { include: { user: true } },
      },
    });
  }

  async getStatuses(eventId: string, dateStr?: string) {
    const date = this.getDateOnly(dateStr);

    // Get all attendant volunteers for the event
    const attendantVolunteers = await this.prisma.eventVolunteer.findMany({
      where: {
        eventId,
        department: { departmentType: 'ATTENDANT' },
      },
      include: { user: true },
    });

    // Get existing checkouts for this date
    const checkouts = await this.prisma.lanyardCheckout.findMany({
      where: { eventId, date },
      include: {
        eventVolunteer: { include: { user: true } },
      },
    });

    const checkoutMap = new Map(
      checkouts.map((c) => [c.eventVolunteerId, c])
    );

    // Return a status for every attendant volunteer (with or without checkout record)
    return attendantVolunteers.map((vol) => {
      const checkout = checkoutMap.get(vol.id);
      return {
        id: checkout?.id ?? `pending-${vol.id}`,
        eventVolunteerId: vol.id,
        eventId,
        date: date.toISOString().split('T')[0],
        pickedUpAt: checkout?.pickedUpAt ?? null,
        returnedAt: checkout?.returnedAt ?? null,
        volunteerName: `${vol.user.firstName} ${vol.user.lastName}`,
      };
    });
  }

  async getSummary(eventId: string, dateStr?: string) {
    const date = this.getDateOnly(dateStr);

    const totalAttendant = await this.prisma.eventVolunteer.count({
      where: {
        eventId,
        department: { departmentType: 'ATTENDANT' },
      },
    });

    const checkouts = await this.prisma.lanyardCheckout.findMany({
      where: { eventId, date },
    });

    const pickedUp = checkouts.filter((c) => c.pickedUpAt && !c.returnedAt).length;
    const returned = checkouts.filter((c) => c.returnedAt).length;
    const notPickedUp = totalAttendant - checkouts.length;

    return {
      total: totalAttendant,
      pickedUp,
      returned,
      notPickedUp,
    };
  }
}

/**
 * Admin Service
 *
 * Handles app-admin operations: CSV imports and analytics.
 *
 * Import Methods:
 *   - importCongregations(csvData): Parse CSV → auto-derive circuits → upsert congregations
 *   - importEvents(csvData): Parse CSV → create/update Event records directly
 *   - importVolunteers(eventId, csvData): Parse CSV → create User + EventVolunteer records
 *
 * Analytics Methods:
 *   - getAppAnalytics(): Aggregate counts across models
 *   - getUserGrowth(period): Time-series user creation data
 *   - getEventStats(): Per-event statistics
 *
 * Called by: ../graphql/resolvers/admin.ts
 */
import { PrismaClient, EventType } from '@prisma/client';
import { parseCSVString } from '../utils/csvParser.js';
import {
  congregationRowSchema,
  eventRowSchema,
  volunteerRowSchema,
  CONGREGATION_REQUIRED_HEADERS,
  EVENT_REQUIRED_HEADERS,
  VOLUNTEER_REQUIRED_HEADERS,
} from '../graphql/validators/admin.js';
import { generateUserId } from '../utils/credentials.js';

export interface ImportError {
  row: number;
  field: string;
  message: string;
}

export interface ImportResult {
  success: boolean;
  created: number;
  updated: number;
  skipped: number;
  totalRows: number;
  errors: ImportError[];
}

export class AdminService {
  constructor(private prisma: PrismaClient) {}

  // ─────────────────────────────────────────────
  // IMPORT: CONGREGATIONS
  // ─────────────────────────────────────────────

  async importCongregations(csvData: string): Promise<ImportResult> {
    const { headers, rows, errors: parseErrors } = parseCSVString(csvData);
    const result: ImportResult = { success: true, created: 0, updated: 0, skipped: 0, totalRows: rows.length, errors: [] };

    // Validate headers
    const missingHeaders = CONGREGATION_REQUIRED_HEADERS.filter(h => !headers.includes(h));
    if (missingHeaders.length > 0) {
      return { ...result, success: false, errors: [{ row: 0, field: 'headers', message: `Missing required headers: ${missingHeaders.join(', ')}` }] };
    }

    // Add parse errors
    for (const err of parseErrors) {
      result.errors.push({ row: 0, field: 'csv', message: err });
    }

    // Phase 1: Validate all rows and collect unique circuits
    const validRows: Array<{ row: number; data: { name: string; state: string; circuitCode: string; language: string } }> = [];
    const circuitMap = new Map<string, { code: string; region: string; language: string }>();

    for (let i = 0; i < rows.length; i++) {
      const parsed = congregationRowSchema.safeParse(rows[i]);
      if (!parsed.success) {
        result.skipped++;
        for (const issue of parsed.error.issues) {
          result.errors.push({ row: i + 2, field: issue.path.join('.'), message: issue.message });
        }
        continue;
      }
      validRows.push({ row: i + 2, data: parsed.data });

      // Auto-derive circuit
      if (!circuitMap.has(parsed.data.circuitCode)) {
        circuitMap.set(parsed.data.circuitCode, {
          code: parsed.data.circuitCode,
          region: `US-${parsed.data.state}`,
          language: parsed.data.language,
        });
      }
    }

    // Phase 2: Upsert circuits
    for (const circuit of circuitMap.values()) {
      await this.prisma.circuit.upsert({
        where: { code: circuit.code },
        update: { region: circuit.region, language: circuit.language },
        create: circuit,
      });
    }

    // Phase 3: Upsert congregations
    for (const { data } of validRows) {
      const circuit = await this.prisma.circuit.findUnique({ where: { code: data.circuitCode } });
      if (!circuit) {
        result.skipped++;
        continue;
      }

      const existing = await this.prisma.congregation.findFirst({
        where: { name: data.name, state: data.state },
      });

      if (existing) {
        await this.prisma.congregation.update({
          where: { id: existing.id },
          data: { circuitId: circuit.id },
        });
        result.updated++;
      } else {
        await this.prisma.congregation.create({
          data: { name: data.name, state: data.state, circuitId: circuit.id },
        });
        result.created++;
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // IMPORT: EVENTS
  // ─────────────────────────────────────────────

  async importEvents(csvData: string): Promise<ImportResult> {
    const { headers, rows, errors: parseErrors } = parseCSVString(csvData);
    const result: ImportResult = { success: true, created: 0, updated: 0, skipped: 0, totalRows: rows.length, errors: [] };

    const missingHeaders = EVENT_REQUIRED_HEADERS.filter(h => !headers.includes(h));
    if (missingHeaders.length > 0) {
      return { ...result, success: false, errors: [{ row: 0, field: 'headers', message: `Missing required headers: ${missingHeaders.join(', ')}` }] };
    }

    for (const err of parseErrors) {
      result.errors.push({ row: 0, field: 'csv', message: err });
    }

    for (let i = 0; i < rows.length; i++) {
      const parsed = eventRowSchema.safeParse(rows[i]);
      if (!parsed.success) {
        result.skipped++;
        for (const issue of parsed.error.issues) {
          result.errors.push({ row: i + 2, field: issue.path.join('.'), message: issue.message });
        }
        continue;
      }

      const data = parsed.data;

      // Lookup circuit if circuitCode provided
      let circuitId: string | null = null;
      if (data.circuitCode) {
        const circuit = await this.prisma.circuit.findUnique({ where: { code: data.circuitCode } });
        if (circuit) circuitId = circuit.id;
      }

      // Derive state from region
      const state = data.region.startsWith('US-') ? data.region.substring(3) : null;

      const startDate = new Date(data.startDate);
      const endDate = new Date(data.endDate);
      const language = data.language || 'en';

      // Upsert by unique constraint: eventType + venue + startDate + language
      const existing = await this.prisma.event.findFirst({
        where: {
          eventType: data.eventType as EventType,
          venue: data.venue,
          startDate,
          language,
        },
      });

      if (existing) {
        await this.prisma.event.update({
          where: { id: existing.id },
          data: {
            name: data.name,
            circuit: data.circuitCode || null,
            circuitId,
            region: data.region,
            state,
            serviceYear: data.serviceYear,
            theme: data.theme || null,
            themeScripture: data.themeScripture || null,
            address: data.address,
            endDate,
          },
        });
        result.updated++;
      } else {
        await this.prisma.event.create({
          data: {
            eventType: data.eventType as EventType,
            name: data.name,
            circuit: data.circuitCode || null,
            circuitId,
            region: data.region,
            state,
            serviceYear: data.serviceYear,
            theme: data.theme || null,
            themeScripture: data.themeScripture || null,
            venue: data.venue,
            address: data.address,
            startDate,
            endDate,
            language,
          },
        });
        result.created++;
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // IMPORT: VOLUNTEERS
  // ─────────────────────────────────────────────

  async importVolunteers(eventId: string, csvData: string): Promise<ImportResult> {
    const { headers, rows, errors: parseErrors } = parseCSVString(csvData);
    const result: ImportResult = { success: true, created: 0, updated: 0, skipped: 0, totalRows: rows.length, errors: [] };

    const missingHeaders = VOLUNTEER_REQUIRED_HEADERS.filter(h => !headers.includes(h));
    if (missingHeaders.length > 0) {
      return { ...result, success: false, errors: [{ row: 0, field: 'headers', message: `Missing required headers: ${missingHeaders.join(', ')}` }] };
    }

    // Verify event exists
    const event = await this.prisma.event.findUnique({ where: { id: eventId } });
    if (!event) {
      return { ...result, success: false, errors: [{ row: 0, field: 'eventId', message: 'Event not found' }] };
    }

    for (const err of parseErrors) {
      result.errors.push({ row: 0, field: 'csv', message: err });
    }

    for (let i = 0; i < rows.length; i++) {
      const parsed = volunteerRowSchema.safeParse(rows[i]);
      if (!parsed.success) {
        result.skipped++;
        for (const issue of parsed.error.issues) {
          result.errors.push({ row: i + 2, field: issue.path.join('.'), message: issue.message });
        }
        continue;
      }

      const data = parsed.data;

      // Find or create User
      let user = data.email ? await this.prisma.user.findUnique({ where: { email: data.email } }) : null;

      if (!user) {
        const userId = generateUserId();
        const email = data.email || `${userId}@placeholder.assemblyops.io`;

        user = await this.prisma.user.create({
          data: {
            userId,
            email,
            firstName: data.firstName,
            lastName: data.lastName,
            phone: data.phone || null,
            congregation: data.congregation,
            appointmentStatus: data.appointmentStatus || 'PUBLISHER',
          },
        });
      }

      // Check if already an EventVolunteer for this event
      const existing = await this.prisma.eventVolunteer.findUnique({
        where: { userId_eventId: { userId: user.id, eventId } },
      });

      if (existing) {
        result.skipped++;
        result.errors.push({ row: i + 2, field: 'email', message: `${data.firstName} ${data.lastName} is already a volunteer for this event` });
        continue;
      }

      // Create EventVolunteer membership record
      await this.prisma.eventVolunteer.create({
        data: {
          userId: user.id,
          eventId,
        },
      });

      result.created++;
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────

  async getAppAnalytics() {
    const [totalUsers, totalOverseers, totalEvents, totalVolunteers, totalAssignments, totalCheckIns] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { isOverseer: true } }),
      this.prisma.event.count(),
      this.prisma.eventVolunteer.count(),
      this.prisma.scheduleAssignment.count(),
      this.prisma.checkIn.count(),
    ]);

    return { totalUsers, totalOverseers, totalEvents, totalVolunteers, totalAssignments, totalCheckIns };
  }

  async getUserGrowth(period: string) {
    const days = period === '7d' ? 7 : period === '30d' ? 30 : period === '90d' ? 90 : 365;
    const since = new Date();
    since.setDate(since.getDate() - days);

    const result = await this.prisma.$queryRaw<Array<{ date: Date; count: bigint }>>`
      SELECT DATE_TRUNC('day', "createdAt") as date, COUNT(*) as count
      FROM "User"
      WHERE "createdAt" >= ${since}
      GROUP BY DATE_TRUNC('day', "createdAt")
      ORDER BY date ASC
    `;

    return result.map(r => ({ date: r.date, count: Number(r.count) }));
  }

  async adminListUsers(limit = 25, offset = 0, search?: string) {
    const where = search
      ? {
          OR: [
            { email: { contains: search, mode: 'insensitive' as const } },
            { firstName: { contains: search, mode: 'insensitive' as const } },
            { lastName: { contains: search, mode: 'insensitive' as const } },
          ],
        }
      : {};

    const [users, totalCount] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          userId: true,
          email: true,
          firstName: true,
          lastName: true,
          isOverseer: true,
          isAppAdmin: true,
          createdAt: true,
          _count: {
            select: {
              eventAdmins: true,
              eventVolunteers: true,
            },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      users: users.map(u => ({
        id: u.id,
        userId: u.userId,
        email: u.email,
        firstName: u.firstName,
        lastName: u.lastName,
        isOverseer: u.isOverseer,
        isAppAdmin: u.isAppAdmin,
        createdAt: u.createdAt,
        eventCount: u._count.eventAdmins + u._count.eventVolunteers,
      })),
      totalCount,
    };
  }

  async adminListEvents(limit = 25, offset = 0) {
    const [events, totalCount] = await Promise.all([
      this.prisma.event.findMany({
        skip: offset,
        take: limit,
        orderBy: { startDate: 'desc' },
        select: {
          id: true,
          name: true,
          eventType: true,
          startDate: true,
          endDate: true,
          venue: true,
          state: true,
          _count: {
            select: {
              eventVolunteers: true,
              departments: true,
              sessions: true,
              admins: true,
            },
          },
        },
      }),
      this.prisma.event.count(),
    ]);

    return {
      events: events.map(e => ({
        eventId: e.id,
        name: e.name,
        eventType: e.eventType,
        startDate: e.startDate,
        endDate: e.endDate,
        venue: e.venue,
        state: e.state,
        volunteerCount: e._count.eventVolunteers,
        departmentCount: e._count.departments,
        sessionCount: e._count.sessions,
        overseerCount: e._count.admins,
      })),
      totalCount,
    };
  }

  async getEventStats() {
    const events = await this.prisma.event.findMany({
      select: {
        id: true,
        name: true,
        eventType: true,
        startDate: true,
        _count: {
          select: {
            eventVolunteers: true,
            departments: true,
            sessions: true,
          },
        },
      },
      orderBy: { startDate: 'desc' },
    });

    return events.map(e => ({
      eventId: e.id,
      name: e.name,
      eventType: e.eventType,
      startDate: e.startDate,
      volunteerCount: e._count.eventVolunteers,
      departmentCount: e._count.departments,
      sessionCount: e._count.sessions,
    }));
  }
}

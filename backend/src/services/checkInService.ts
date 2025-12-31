/**
 * Check-In Service
 *
 * Business logic for volunteer check-in/check-out and attendance tracking.
 *
 * Methods:
 *   - checkIn(volunteerId, input): Volunteer checks in to their assignment
 *   - checkOut(volunteerId, input): Volunteer checks out of their assignment
 *   - adminCheckIn(adminId, input): Admin checks in a volunteer on their behalf
 *   - markNoShow(adminId, input): Admin marks a volunteer as no-show
 *   - getCheckIn(id): Get a check-in record by ID
 *   - getSessionCheckIns(sessionId): Get all check-ins for a session
 *   - getCheckInStats(sessionId): Get check-in statistics for a session
 *   - getAssignmentEventId(assignmentId): Get event ID for access control
 *
 * Check-In Status Flow:
 *   [No CheckIn] → checkIn → CHECKED_IN → checkOut → CHECKED_OUT
 *                                ↓
 *                      markNoShow → NO_SHOW
 *
 * Authorization:
 *   - Volunteers can only check in/out of their own assignments
 *   - Admins can check in any volunteer in events they have access to
 *
 * Called by: ../graphql/resolvers/checkIn.ts
 */
import { PrismaClient, CheckIn, CheckInStatus } from '@prisma/client';
import {
  NotFoundError,
  ValidationError,
  ConflictError,
  AuthorizationError,
} from '../utils/errors.js';
import {
  checkInSchema,
  checkOutSchema,
  adminCheckInSchema,
  markNoShowSchema,
  CheckInInput,
  CheckOutInput,
  AdminCheckInInput,
  MarkNoShowInput,
} from '../graphql/validators/checkIn.js';

export interface CheckInStats {
  sessionId: string;
  totalAssignments: number;
  checkedIn: number;
  checkedOut: number;
  noShow: number;
  pending: number;
}

export class CheckInService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Volunteer checks in to their assignment
   */
  async checkIn(volunteerId: string, input: CheckInInput): Promise<CheckIn> {
    const result = checkInSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { assignmentId } = result.data;

    // Verify assignment exists and belongs to this volunteer
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        volunteer: true,
        session: true,
        checkIn: true,
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    if (assignment.volunteerId !== volunteerId) {
      throw new AuthorizationError('This assignment does not belong to you');
    }

    // Check if already checked in
    if (assignment.checkIn) {
      if (assignment.checkIn.status === CheckInStatus.CHECKED_IN) {
        throw new ConflictError('Already checked in to this assignment');
      }
      if (assignment.checkIn.status === CheckInStatus.CHECKED_OUT) {
        throw new ConflictError('Already checked out of this assignment');
      }
    }

    // Create or update check-in record
    if (assignment.checkIn) {
      return this.prisma.checkIn.update({
        where: { id: assignment.checkIn.id },
        data: {
          status: CheckInStatus.CHECKED_IN,
          checkInTime: new Date(),
          checkOutTime: null,
        },
        include: {
          assignment: {
            include: {
              volunteer: true,
              post: true,
              session: true,
            },
          },
        },
      });
    }

    return this.prisma.checkIn.create({
      data: {
        status: CheckInStatus.CHECKED_IN,
        checkInTime: new Date(),
        assignmentId,
      },
      include: {
        assignment: {
          include: {
            volunteer: true,
            post: true,
            session: true,
          },
        },
      },
    });
  }

  /**
   * Volunteer checks out of their assignment
   */
  async checkOut(volunteerId: string, input: CheckOutInput): Promise<CheckIn> {
    const result = checkOutSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { assignmentId } = result.data;

    // Verify assignment exists and belongs to this volunteer
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        checkIn: true,
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    if (assignment.volunteerId !== volunteerId) {
      throw new AuthorizationError('This assignment does not belong to you');
    }

    if (!assignment.checkIn) {
      throw new ValidationError('Must check in before checking out');
    }

    if (assignment.checkIn.status === CheckInStatus.CHECKED_OUT) {
      throw new ConflictError('Already checked out of this assignment');
    }

    if (assignment.checkIn.status === CheckInStatus.NO_SHOW) {
      throw new ValidationError('Cannot check out from a no-show assignment');
    }

    return this.prisma.checkIn.update({
      where: { id: assignment.checkIn.id },
      data: {
        status: CheckInStatus.CHECKED_OUT,
        checkOutTime: new Date(),
      },
      include: {
        assignment: {
          include: {
            volunteer: true,
            post: true,
            session: true,
          },
        },
      },
    });
  }

  /**
   * Admin checks in a volunteer on their behalf
   */
  async adminCheckIn(adminId: string, input: AdminCheckInInput): Promise<CheckIn> {
    const result = adminCheckInSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { assignmentId, notes } = result.data;

    // Verify assignment exists
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        checkIn: true,
        session: true,
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    // Check if already checked in
    if (assignment.checkIn && assignment.checkIn.status === CheckInStatus.CHECKED_IN) {
      throw new ConflictError('Volunteer already checked in');
    }

    // Create or update check-in record
    if (assignment.checkIn) {
      return this.prisma.checkIn.update({
        where: { id: assignment.checkIn.id },
        data: {
          status: CheckInStatus.CHECKED_IN,
          checkInTime: new Date(),
          checkOutTime: null,
          notes,
          checkedInById: adminId,
        },
        include: {
          assignment: {
            include: {
              volunteer: true,
              post: true,
              session: true,
            },
          },
          checkedInBy: true,
        },
      });
    }

    return this.prisma.checkIn.create({
      data: {
        status: CheckInStatus.CHECKED_IN,
        checkInTime: new Date(),
        assignmentId,
        notes,
        checkedInById: adminId,
      },
      include: {
        assignment: {
          include: {
            volunteer: true,
            post: true,
            session: true,
          },
        },
        checkedInBy: true,
      },
    });
  }

  /**
   * Admin marks a volunteer as no-show
   */
  async markNoShow(adminId: string, input: MarkNoShowInput): Promise<CheckIn> {
    const result = markNoShowSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { assignmentId, notes } = result.data;

    // Verify assignment exists
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        checkIn: true,
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    // Check current status
    if (assignment.checkIn) {
      if (assignment.checkIn.status === CheckInStatus.CHECKED_IN) {
        throw new ConflictError('Cannot mark as no-show – volunteer is checked in');
      }
      if (assignment.checkIn.status === CheckInStatus.CHECKED_OUT) {
        throw new ConflictError('Cannot mark as no-show – volunteer already checked out');
      }
    }

    // Create or update check-in record
    if (assignment.checkIn) {
      return this.prisma.checkIn.update({
        where: { id: assignment.checkIn.id },
        data: {
          status: CheckInStatus.NO_SHOW,
          notes,
          checkedInById: adminId,
        },
        include: {
          assignment: {
            include: {
              volunteer: true,
              post: true,
              session: true,
            },
          },
          checkedInBy: true,
        },
      });
    }

    return this.prisma.checkIn.create({
      data: {
        status: CheckInStatus.NO_SHOW,
        checkInTime: new Date(),
        assignmentId,
        notes,
        checkedInById: adminId,
      },
      include: {
        assignment: {
          include: {
            volunteer: true,
            post: true,
            session: true,
          },
        },
        checkedInBy: true,
      },
    });
  }

  /**
   * Get check-in by ID
   */
  async getCheckIn(checkedInId: string) {
    return this.prisma.checkIn.findUnique({
      where: { id: checkedInId },
      include: {
        assignment: {
          include: {
            volunteer: true,
            post: { include: { department: true } },
            session: true,
          },
        },
        checkedInBy: true,
      },
    });
  }

  /**
   * Get all check-ins for a session
   */
  async getSessionCheckIns(sessionId: string) {
    return this.prisma.checkIn.findMany({
      where: {
        assignment: { sessionId },
      },
      include: {
        assignment: {
          include: {
            volunteer: true,
            post: { include: { department: true } },
          },
        },
        checkedInBy: true,
      },
      orderBy: { checkInTime: 'desc' },
    });
  }

  /**
   * Get check-in stats for a session
   */
  async getCheckInStats(sessionId: string): Promise<CheckInStats> {
    // Get total assignments for this session
    const totalAssignments = await this.prisma.scheduleAssignment.count({
      where: { sessionId },
    });

    // Get counts by status
    const statusCounts = await this.prisma.checkIn.groupBy({
      by: ['status'],
      where: {
        assignment: { sessionId },
      },
      _count: true,
    });

    const checkedIn = statusCounts.find((s) => s.status === CheckInStatus.CHECKED_IN)?._count ?? 0;
    const checkedOut =
      statusCounts.find((s) => s.status === CheckInStatus.CHECKED_OUT)?._count ?? 0;
    const noShow = statusCounts.find((s) => s.status === CheckInStatus.NO_SHOW)?._count ?? 0;
    const pending = totalAssignments - checkedIn - checkedOut - noShow;

    return {
      sessionId,
      totalAssignments,
      checkedIn,
      checkedOut,
      noShow,
      pending,
    };
  }

  /**
   * Get assignment's event ID for access control
   */
  async getAssignmentEventId(assignmentId: string): Promise<string> {
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        session: { select: { eventId: true } },
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    return assignment.session.eventId;
  }
}

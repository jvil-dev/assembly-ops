import { Request, Response } from "express";
import {
  volunteerCheckIn,
  getVolunteerStatus,
  volunteerCheckOut,
  adminCheckIn,
  adminUpdateCheckIn,
  adminDeleteCheckIn,
  getActiveCheckIns,
  getCheckInsByZone,
  getCheckInsBySession,
  getCheckInSummary,
} from "../services/checkInService";
import { CheckInStatus } from "../generated/prisma/enums";

export async function handleVolunteerCheckIn(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const volunteerId = req.volunteer!.id;

    const result = await volunteerCheckIn(volunteerId);

    const message = result.checkIn.isLate
      ? "Checked in successfully (late arrival recorded)"
      : "Checked in successfully";

    res.status(201).json({
      message,
      checkIn: result.checkIn,
      assignment: result.assignment,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "NO_ASSIGNMENT") {
        res.status(404).json({
          error: "You have no assignments for this event",
        });
        return;
      }
      if (error.message === "ALREADY_CHECKED_IN") {
        res.status(409).json({
          error: "You are already checked in to an active shift",
        });
        return;
      }
      if (error.message === "NO_ELIGIBLE_ASSIGNMENT") {
        res.status(400).json({
          error:
            "No eligible assignment found. Your sessions may have ended or you're already checked in",
        });
        return;
      }
    }

    console.error("Volunteer check-in error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetVolunteerStatus(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const volunteerId = req.volunteer!.id;
    const status = await getVolunteerStatus(volunteerId);
    res.status(200).json(status);
  } catch (error) {
    console.error("Get volunteer status error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleVolunteerCheckOut(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const volunteerId = req.volunteer!.id;

    const result = await volunteerCheckOut(volunteerId);

    res.status(200).json({
      message: "Checked out successfully",
      checkIn: result.checkIn,
      assignment: result.assignment,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "NOT_CHECKED_IN") {
        res.status(400).json({
          error: "You are not currently checked in to any shift",
        });
        return;
      }
    }
    console.error("Volunteer check-out error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

const VALID_CHECK_IN_STATUSES: CheckInStatus[] = [
  CheckInStatus.CHECKED_IN,
  CheckInStatus.CHECKED_OUT,
  CheckInStatus.MISSED,
];

export async function handleAdminCheckIn(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, assignmentId } = req.params;
    const { checkInTime, isLate, notes } = req.body;
    const adminId = req.admin!.id;

    let parsedCheckInTime: Date | undefined;
    if (checkInTime !== undefined) {
      parsedCheckInTime = new Date(checkInTime);
      if (isNaN(parsedCheckInTime.getTime())) {
        res.status(400).json({
          error: "Invalid checkInTime format",
        });
        return;
      }
    }

    // Validate isLate if provided
    if (isLate !== undefined && typeof isLate !== "boolean") {
      res.status(400).json({
        error: "isLate must be a boolean",
      });
      return;
    }

    const result = await adminCheckIn({
      assignmentId: assignmentId!,
      eventId: eventId!,
      adminId,
      ...(parsedCheckInTime !== undefined && {
        checkInTime: parsedCheckInTime,
      }),
      ...(isLate !== undefined && { isLate }),
      ...(notes !== undefined && { notes }),
    });

    res.status(201).json({
      message: "Volunteer checked in successfully",
      checkIn: result.checkIn,
      assignment: result.assignment,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({
          error: "Event not found",
        });
        return;
      }
      if (error.message === "ASSIGNMENT_NOT_FOUND") {
        res.status(404).json({
          error: "Assignment not found",
        });
        return;
      }
      if (error.message === "ALREADY_CHECKED_IN") {
        res.status(409).json({
          error: "Volunteer is already checked in for this assignment",
        });
        return;
      }
    }

    console.error("Admin check-in error: ", error);
    res.status(500).json({
      error: "Internal server error",
    });
  }
}

export async function handleAdminUpdateCheckIn(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, assignmentId } = req.params;
    const { status, checkOutTime, isLate, notes } = req.body;
    const adminId = req.admin!.id;

    // Validate status if provided
    if (status !== undefined && !VALID_CHECK_IN_STATUSES.includes(status)) {
      res.status(400).json({
        error: `Invalid status. Must be one of: ${VALID_CHECK_IN_STATUSES.join(", ")}`,
      });
      return;
    }

    // Validate checkOutTime if provided
    let parsedCheckOutTime: Date | undefined;
    if (checkOutTime !== undefined) {
      parsedCheckOutTime = new Date(checkOutTime);
      if (isNaN(parsedCheckOutTime.getTime())) {
        res.status(400).json({
          error: "Invalid checkOutTime format",
        });
        return;
      }
    }

    // Validate isLate if provided
    if (isLate !== undefined && typeof isLate !== "boolean") {
      res.status(400).json({ error: "isLate must be a boolean" });
      return;
    }

    const result = await adminUpdateCheckIn({
      assignmentId: assignmentId!,
      eventId: eventId!,
      adminId,
      ...(status !== undefined && { status }),
      ...(parsedCheckOutTime !== undefined && {
        checkOutTime: parsedCheckOutTime,
      }),
      ...(isLate !== undefined && { isLate }),
      ...(notes !== undefined && { notes }),
    });

    res.status(200).json({
      message: "Check-in updated successfully",
      checkIn: result.checkIn,
      assignment: result.assignment,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({
          error: "Event not found",
        });
        return;
      }
      if (error.message === "ASSIGNMENT_NOT_FOUND") {
        res.status(404).json({ error: "Assignment not found" });
        return;
      }
      if (error.message === "NO_CHECK_IN") {
        res
          .status(404)
          .json({ error: "No check-in record exists for this assignment" });
        return;
      }
      if (error.message === "NO_UPDATES") {
        res.status(400).json({ error: "No fields to update" });
        return;
      }
    }

    console.error("Admin update check-in error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleAdminDeleteCheckIn(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, assignmentId } = req.params;
    const adminId = req.admin!.id;

    await adminDeleteCheckIn({
      assignmentId: assignmentId!,
      eventId: eventId!,
      adminId,
    });

    res.status(200).json({ message: "Check-in record deleted successfully" });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "ASSIGNMENT_NOT_FOUND") {
        res.status(404).json({ error: "Assignment not found" });
        return;
      }
      if (error.message === "NO_CHECK_IN") {
        res
          .status(404)
          .json({ error: "No check-in record exists for this assignment" });
        return;
      }
    }

    console.error("Admin delete check-in error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetActiveCheckIns(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const result = await getActiveCheckIns(eventId!, adminId);

    res.status(200).json(result);
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get active check-ins error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetCheckInsByZone(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, zoneId } = req.params;
    const adminId = req.admin!.id;

    const result = await getCheckInsByZone(zoneId!, eventId!, adminId);

    res.status(200).json(result);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "ZONE_NOT_FOUND") {
        res.status(404).json({ error: "Zone not found" });
        return;
      }
    }

    console.error("Get check-ins by zone error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetCheckInsBySession(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, sessionId } = req.params;
    const adminId = req.admin!.id;

    const result = await getCheckInsBySession(sessionId!, eventId!, adminId);

    res.status(200).json(result);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "SESSION_NOT_FOUND") {
        res.status(404).json({ error: "Session not found" });
        return;
      }
    }

    console.error("Get check-ins by session error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetCheckInSummary(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { sessionId, date } = req.query;
    const adminId = req.admin!.id;

    // Parse date if provided
    let parsedDate: Date | undefined;
    if (date) {
      parsedDate = new Date(date as string);
      if (isNaN(parsedDate.getTime())) {
        res.status(400).json({ error: "Invalid date format" });
        return;
      }
    }

    const result = await getCheckInSummary(eventId!, adminId, {
      ...(sessionId && { sessionId: sessionId as string }),
      ...(parsedDate && { date: parsedDate }),
    });

    res.status(200).json(result);
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get check-in summary error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

import { Request, Response } from "express";
import {
  volunteerCheckIn,
  getVolunteerStatus,
} from "../services/checkInService";

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

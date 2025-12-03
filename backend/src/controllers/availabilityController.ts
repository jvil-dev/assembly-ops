import { Request, Response } from "express";
import {
  getVolunteerAvailability,
  setVolunteerAvailability,
  getAvailableVolunteersForSession,
} from "../services/availabilityService.js";

export async function handleGetVolunteerAvailability(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, volunteerId } = req.params;
    const adminId = req.admin!.id;

    const result = await getVolunteerAvailability(
      volunteerId!,
      eventId!,
      adminId
    );

    res.status(200).json(result);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "VOLUNTEER_NOT_FOUND") {
        res.status(404).json({ error: "Volunteer not found" });
        return;
      }
    }

    console.error("Get volunteer availability error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleSetVolunteerAvailability(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, volunteerId } = req.params;
    const { availability } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!availability || !Array.isArray(availability)) {
      res.status(400).json({ error: "Availability array is required" });
      return;
    }

    if (availability.length === 0) {
      res.status(400).json({ error: "Availability array cannot be empty" });
      return;
    }

    // Validate each item
    for (let i = 0; i < availability.length; i++) {
      const item = availability[i];

      if (!item.sessionId) {
        res.status(400).json({
          error: `Item at index ${i} is missing sessionId`,
        });
        return;
      }

      if (typeof item.isAvailable !== "boolean") {
        res.status(400).json({
          error: `Item at index ${i} must have isAvailable as boolean`,
        });
        return;
      }
    }

    const results = await setVolunteerAvailability(
      volunteerId!,
      eventId!,
      adminId,
      availability
    );

    res.status(200).json({
      message: "Availability updated successfully",
      updated: results.length,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "VOLUNTEER_NOT_FOUND") {
        res.status(404).json({ error: "Volunteer not found" });
        return;
      }
      if (error.message === "SESSION_NOT_FOUND") {
        res.status(404).json({ error: "One or more sessions not found" });
        return;
      }
    }

    console.error("Set volunteer availability error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetAvailableVolunteers(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, sessionId } = req.params;
    const adminId = req.admin!.id;

    const result = await getAvailableVolunteersForSession(
      sessionId!,
      eventId!,
      adminId
    );

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

    console.error("Get available volunteers error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

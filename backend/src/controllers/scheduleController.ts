import { Request, Response } from "express";
import {
  getScheduleGrid,
  getScheduleSummary,
  getVolunteerAssignments,
} from "../services/scheduleService.js";

export async function handleGetScheduleGrid(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const schedule = await getScheduleGrid(eventId!, adminId);

    res.status(200).json(schedule);
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get schedule grid error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetScheduleSummary(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const summary = await getScheduleSummary(eventId!, adminId);

    res.status(200).json({ sessions: summary });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get schedule summary error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetMyAssignments(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const volunteerId = req.volunteer!.id;
    const eventId = req.volunteer!.eventId;

    const result = await getVolunteerAssignments(volunteerId, eventId);

    res.status(200).json(result);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "VOLUNTEER_NOT_FOUND") {
        res.status(404).json({ error: "Volunteer not found" });
        return;
      }
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
    }

    console.error("Get my assignments error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

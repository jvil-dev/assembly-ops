import { Request, Response } from "express";
import {
  getSyncStatus,
  getFullSync,
  getDeltaSync,
  processActionQueue,
  getVolunteerDeltaSync,
  getVolunteerFullSync,
} from "../services/syncService.js";

export async function handleGetSyncStatus(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const status = await getSyncStatus(eventId!, adminId);

    res.status(200).json(status);
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get sync status error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetFullSync(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const data = await getFullSync(eventId!, adminId);

    res.status(200).json(data);
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get full sync error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetDeltaSync(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { since } = req.query;
    const adminId = req.admin!.id;

    if (!since) {
      res.status(400).json({
        error: "Missing required query parameters: since",
      });
      return;
    }

    const sinceDate = new Date(since as string);

    if (isNaN(sinceDate.getTime())) {
      res.status(400).json({
        error: "Invalid date format for 'since' parameter",
      });
      return;
    }

    const maxAge = 7 * 24 * 60 * 60 * 1000;
    const now = new Date();
    const minSince = new Date(now.getTime() - maxAge);

    if (sinceDate < minSince) {
      res.status(400).json({
        error:
          "The 'since' parameter is too old. Maximun age is 7 days. Use full sync instead",
        suggestedFullSync: true,
      });
      return;
    }

    // Prevent future dates
    if (sinceDate > now) {
      res.status(400).json({
        error: "The 'since' parameter cannot be in the future",
      });
      return;
    }

    const data = await getDeltaSync(eventId!, adminId, sinceDate);

    res.status(200).json(data);
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({
        error: "Event not found",
      });
      return;
    }

    console.error("Get delta sync error: ", error);
    res.status(500).json({
      error: "Internal server error",
    });
  }
}

export async function handleProcessQueue(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { actions } = req.body;

    // Get user context (admin or volunteer)
    const adminId = req.admin?.id || null;
    const volunteerId = req.volunteer?.id || null;

    // Validate actions array
    if (!actions || !Array.isArray(actions)) {
      res.status(400).json({ error: "Missing or invalid 'actions' array" });
      return;
    }

    if (actions.length === 0) {
      res.status(400).json({ error: "Actions array cannot be empty" });
      return;
    }

    if (actions.length > 100) {
      res.status(400).json({ error: "Maximum 100 actions per request" });
      return;
    }

    // Validate each action
    const validTypes = ["CHECK_IN", "CHECK_OUT", "QUICK_ALERT", "MESSAGE_READ"];

    for (let i = 0; i < actions.length; i++) {
      const action = actions[i];

      if (!action.id) {
        res.status(400).json({ error: `Action at index ${i} missing 'id'` });
        return;
      }

      if (!action.type || !validTypes.includes(action.type)) {
        res.status(400).json({
          error: `Action at index ${i} has invalid type. Must be one of: ${validTypes.join(", ")}`,
        });
        return;
      }

      if (!action.timestamp) {
        res
          .status(400)
          .json({ error: `Action at index ${i} missing 'timestamp'` });
        return;
      }

      if (!action.data || typeof action.data !== "object") {
        res
          .status(400)
          .json({ error: `Action at index ${i} missing or invalid 'data'` });
        return;
      }
    }

    const result = await processActionQueue(
      eventId!,
      adminId,
      volunteerId,
      actions
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

    console.error("Process queue error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleVolunteerFullSync(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const volunteerId = req.volunteer!.id;
    const eventId = req.volunteer!.eventId;

    if (!eventId) {
      res
        .status(400)
        .json({ error: "Invalid volunteer token - missing eventId" });
      return;
    }

    const data = await getVolunteerFullSync(volunteerId, eventId);

    res.status(200).json(data);
  } catch (error) {
    if (error instanceof Error && error.message === "VOLUNTEER_NOT_FOUND") {
      res.status(404).json({ error: "Volunteer not found" });
      return;
    }

    console.error("Volunteer full sync error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleVolunteerDeltaSync(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const volunteerId = req.volunteer!.id;
    const eventId = req.volunteer!.eventId;
    const { since } = req.query;

    if (!eventId) {
      res
        .status(400)
        .json({ error: "Invalid volunteer token - missing eventId" });
      return;
    }

    // Validate 'since' parameter
    if (!since) {
      res
        .status(400)
        .json({ error: "Missing required query parameter: since" });
      return;
    }

    const sinceDate = new Date(since as string);

    if (isNaN(sinceDate.getTime())) {
      res
        .status(400)
        .json({ error: "Invalid date format for 'since' parameter" });
      return;
    }

    // Cap 'since' to reasonable window (7 days)
    const maxAge = 7 * 24 * 60 * 60 * 1000;
    const now = new Date();
    const minSince = new Date(now.getTime() - maxAge);

    if (sinceDate < minSince) {
      res.status(400).json({
        error:
          "The 'since' parameter is too old. Maximum age is 7 days. Use full sync instead.",
        suggestFullSync: true,
      });
      return;
    }

    if (sinceDate > now) {
      res
        .status(400)
        .json({ error: "The 'since' parameter cannot be in the future" });
      return;
    }

    const data = await getVolunteerDeltaSync(volunteerId, eventId, sinceDate);

    res.status(200).json(data);
  } catch (error) {
    if (error instanceof Error && error.message === "VOLUNTEER_NOT_FOUND") {
      res.status(404).json({ error: "Volunteer not found" });
      return;
    }

    console.error("Volunteer delta sync error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

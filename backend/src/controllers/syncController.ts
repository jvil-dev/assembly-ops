import { Request, Response } from "express";
import {
  getSyncStatus,
  getFullSync,
  getDeltaSync,
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

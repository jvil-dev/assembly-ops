import { Request, Response } from "express";
import { getSyncStatus, getFullSync } from "../services/syncService.js";

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

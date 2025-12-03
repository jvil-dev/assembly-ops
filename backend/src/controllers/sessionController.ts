import { Request, Response } from "express";
import {
  createSession,
  getSessionsByEvent,
  getSessionById,
  updateSession,
  deleteSession,
} from "../services/sessionService.js";

export async function handleCreateSession(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { name, date, startTime, endTime } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!name || !date || !startTime || !endTime) {
      res.status(400).json({
        error: "Missing required fields: name, date, startTime, endTime",
      });
      return;
    }

    if (typeof name !== "string" || name.trim().length === 0) {
      res.status(400).json({ error: "Name must be a non-empty string" });
      return;
    }

    // Parse dates
    const parsedDate = new Date(date);
    const parsedStartTime = new Date(startTime);
    const parsedEndTime = new Date(endTime);

    if (isNaN(parsedDate.getTime())) {
      res.status(400).json({ error: "Invalid date format" });
      return;
    }

    if (isNaN(parsedStartTime.getTime()) || isNaN(parsedEndTime.getTime())) {
      res.status(400).json({ error: "Invalid time format" });
      return;
    }

    const session = await createSession(
      {
        name: name.trim(),
        date: parsedDate,
        startTime: parsedStartTime,
        endTime: parsedEndTime,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Session created successfully",
      session,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "INVALID_TIME_RANGE") {
        res.status(400).json({ error: "End time must be after start time" });
        return;
      }
    }

    console.error("Create session error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetSessions(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const sessions = await getSessionsByEvent(eventId!, adminId);

    res.status(200).json({ sessions });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get sessions error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetSession(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, sessionId } = req.params;
    const adminId = req.admin!.id;

    const session = await getSessionById(sessionId!, eventId!, adminId);

    res.status(200).json({ session });
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

    console.error("Get session error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleUpdateSession(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, sessionId } = req.params;
    const { name, date, startTime, endTime } = req.body;
    const adminId = req.admin!.id;

    // Build update object
    const updateData: Record<string, unknown> = {};

    if (name !== undefined) {
      if (typeof name !== "string" || name.trim().length === 0) {
        res.status(400).json({ error: "Name must be a non-empty string" });
        return;
      }
      updateData.name = name.trim();
    }

    if (date !== undefined) {
      const parsedDate = new Date(date);
      if (isNaN(parsedDate.getTime())) {
        res.status(400).json({ error: "Invalid date format" });
        return;
      }
      updateData.date = parsedDate;
    }

    if (startTime !== undefined) {
      const parsedStartTime = new Date(startTime);
      if (isNaN(parsedStartTime.getTime())) {
        res.status(400).json({ error: "Invalid start time format" });
        return;
      }
      updateData.startTime = parsedStartTime;
    }

    if (endTime !== undefined) {
      const parsedEndTime = new Date(endTime);
      if (isNaN(parsedEndTime.getTime())) {
        res.status(400).json({ error: "Invalid end time format" });
        return;
      }
      updateData.endTime = parsedEndTime;
    }

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }

    const session = await updateSession(
      sessionId!,
      eventId!,
      adminId,
      updateData
    );

    res.status(200).json({
      message: "Session updated successfully",
      session,
    });
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
      if (error.message === "INVALID_TIME_RANGE") {
        res.status(400).json({ error: "End time must be after start time" });
        return;
      }
    }

    console.error("Update session error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeleteSession(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, sessionId } = req.params;
    const adminId = req.admin!.id;

    await deleteSession(sessionId!, eventId!, adminId);

    res.status(200).json({ message: "Session deleted successfully" });
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

    console.error("Delete session error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

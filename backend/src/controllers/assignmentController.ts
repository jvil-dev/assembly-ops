import { Request, Response } from "express";
import {
  createAssignment,
  bulkCreateAssignments,
  getAssignmentsByEvent,
  getAssignmentsBySession,
  getAssignmentsByZone,
  deleteAssignment,
} from "../services/assignmentService.js";

export async function handleCreateAssignment(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { volunteerId, sessionId, zoneId, notes } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!volunteerId || !sessionId || !zoneId) {
      res.status(400).json({
        error: "Missing required fields: volunteerId, sessionId, zoneId",
      });
      return;
    }

    const assignment = await createAssignment(
      {
        volunteerId,
        sessionId,
        zoneId,
        notes,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Assignment created successfully",
      assignment,
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
        res.status(404).json({ error: "Session not found" });
        return;
      }
      if (error.message === "ZONE_NOT_FOUND") {
        res.status(404).json({ error: "Zone not found" });
        return;
      }
      if (error.message === "VOLUNTEER_UNAVAILABLE") {
        res
          .status(409)
          .json({ error: "Volunteer is not available for this session" });
        return;
      }
      if (error.message === "VOLUNTEER_ALREADY_ASSIGNED") {
        res.status(409).json({
          error: "Volunteer is already assigned to a zone in this session",
        });
        return;
      }
    }

    console.error("Create assignment error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleBulkCreateAssignments(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { assignments } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!assignments || !Array.isArray(assignments)) {
      res.status(400).json({ error: "Assignments array is required" });
      return;
    }

    if (assignments.length === 0) {
      res.status(400).json({ error: "Assignments array cannot be empty" });
      return;
    }

    if (assignments.length > 100) {
      res.status(400).json({ error: "Maximum 100 assignments per request" });
      return;
    }

    // Validate each assignment
    for (let i = 0; i < assignments.length; i++) {
      const a = assignments[i];
      if (!a.volunteerId || !a.sessionId || !a.zoneId) {
        res.status(400).json({
          error: `Assignment at index ${i} missing required fields: volunteerId, sessionId, zoneId`,
        });
        return;
      }
    }

    const createdAssignments = await bulkCreateAssignments(
      {
        assignments,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: `${createdAssignments.length} assignments created successfully`,
      assignments: createdAssignments,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "VOLUNTEER_NOT_FOUND") {
        res.status(404).json({ error: "One or more volunteers not found" });
        return;
      }
      if (error.message === "SESSION_NOT_FOUND") {
        res.status(404).json({ error: "One or more sessions not found" });
        return;
      }
      if (error.message === "ZONE_NOT_FOUND") {
        res.status(404).json({ error: "One or more zones not found" });
        return;
      }
      if (error.message.startsWith("VOLUNTEER_UNAVAILABLE:")) {
        const volunteerId = error.message.split(":")[1];
        res.status(409).json({
          error: "A volunteer is not available for their assigned session",
          volunteerId,
        });
        return;
      }
      if (error.message.startsWith("VOLUNTEER_ALREADY_ASSIGNED:")) {
        const volunteerId = error.message.split(":")[1];
        res.status(409).json({
          error: "A volunteer is already assigned to a zone in their session",
          volunteerId,
        });
        return;
      }
      if (error.message.startsWith("DUPLICATE_IN_REQUEST:")) {
        const volunteerId = error.message.split(":")[1];
        res.status(400).json({
          error: "Duplicate volunteer-session pair in request",
          volunteerId,
        });
        return;
      }
    }

    console.error("Bulk create assignments error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetAssignments(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const assignments = await getAssignmentsByEvent(eventId!, adminId);

    res.status(200).json({ assignments });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get assignments error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetAssignmentsBySession(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, sessionId } = req.params;
    const adminId = req.admin!.id;

    const result = await getAssignmentsBySession(sessionId!, eventId!, adminId);

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

    console.error("Get assignments by session error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetAssignmentsByZone(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, zoneId } = req.params;
    const adminId = req.admin!.id;

    const result = await getAssignmentsByZone(zoneId!, eventId!, adminId);

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

    console.error("Get assignments by zone error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeleteAssignment(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, assignmentId } = req.params;
    const adminId = req.admin!.id;

    await deleteAssignment(assignmentId!, eventId!, adminId);

    res.status(200).json({ message: "Assignment deleted successfully" });
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
    }

    console.error("Delete assignment error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

import { Request, Response } from "express";
import {
  createQuickAlert,
  getQuickAlertsByEvent,
  getQuickAlertById,
  updateQuickAlert,
  deleteQuickAlert,
  getAvailableQuickAlerts,
  sendQuickAlert,
} from "../services/quickAlertService.js";
import { MessagePriority } from "../generated/prisma/client.js";

const VALID_PRIORITIES: MessagePriority[] = ["NORMAL", "URGENT"];

// Admin handlers

export async function handleCreateQuickAlert(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { name, message, priority, displayOrder } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!name || !message) {
      res.status(400).json({ error: "Name and message are required" });
      return;
    }

    if (typeof name !== "string" || name.trim().length === 0) {
      res.status(400).json({ error: "Name must be a non-empty string" });
      return;
    }

    if (typeof message !== "string" || message.trim().length === 0) {
      res.status(400).json({ error: "Message must be a non-empty string" });
      return;
    }

    if (message.length > 500) {
      res.status(400).json({ error: "Message must be 500 characters or less" });
      return;
    }

    if (priority && !VALID_PRIORITIES.includes(priority)) {
      res.status(400).json({
        error: `Invalid priority. Must be one of: ${VALID_PRIORITIES.join(", ")}`,
      });
      return;
    }

    const quickAlert = await createQuickAlert(
      {
        name: name.trim(),
        message: message.trim(),
        priority,
        displayOrder,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Quick alert created successfully",
      quickAlert,
    });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Create quick alert error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetQuickAlerts(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;
    const includeInactive = req.query.includeInactive === "true";

    const quickAlerts = await getQuickAlertsByEvent(
      eventId!,
      adminId,
      includeInactive
    );

    res.status(200).json({ quickAlerts });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get quick alerts error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetQuickAlert(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, alertId } = req.params;
    const adminId = req.admin!.id;

    const quickAlert = await getQuickAlertById(alertId!, eventId!, adminId);

    res.status(200).json({ quickAlert });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "QUICK_ALERT_NOT_FOUND") {
        res.status(404).json({ error: "Quick alert not found" });
        return;
      }
    }

    console.error("Get quick alert error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleUpdateQuickAlert(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, alertId } = req.params;
    const { name, message, priority, isActive, displayOrder } = req.body;
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

    if (message !== undefined) {
      if (typeof message !== "string" || message.trim().length === 0) {
        res.status(400).json({ error: "Message must be a non-empty string" });
        return;
      }
      if (message.length > 500) {
        res
          .status(400)
          .json({ error: "Message must be 500 characters or less" });
        return;
      }
      updateData.message = message.trim();
    }

    if (priority !== undefined) {
      if (!VALID_PRIORITIES.includes(priority)) {
        res.status(400).json({
          error: `Invalid priority. Must be one of: ${VALID_PRIORITIES.join(", ")}`,
        });
        return;
      }
      updateData.priority = priority;
    }

    if (isActive !== undefined) {
      if (typeof isActive !== "boolean") {
        res.status(400).json({ error: "isActive must be a boolean" });
        return;
      }
      updateData.isActive = isActive;
    }

    if (displayOrder !== undefined) {
      if (typeof displayOrder !== "number") {
        res.status(400).json({ error: "displayOrder must be a number" });
        return;
      }
      updateData.displayOrder = displayOrder;
    }

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }

    const quickAlert = await updateQuickAlert(
      alertId!,
      eventId!,
      adminId,
      updateData
    );

    res.status(200).json({
      message: "Quick alert updated successfully",
      quickAlert,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "QUICK_ALERT_NOT_FOUND") {
        res.status(404).json({ error: "Quick alert not found" });
        return;
      }
    }

    console.error("Update quick alert error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeleteQuickAlert(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, alertId } = req.params;
    const adminId = req.admin!.id;

    await deleteQuickAlert(alertId!, eventId!, adminId);

    res.status(200).json({ message: "Quick alert deleted successfully" });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "QUICK_ALERT_NOT_FOUND") {
        res.status(404).json({ error: "Quick alert not found" });
        return;
      }
    }

    console.error("Delete quick alert error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// Volunteer handlers

export async function handleGetAvailableAlerts(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const eventId = req.volunteer!.eventId;

    if (!eventId) {
      res.status(400).json({ error: "Volunteer token missing eventId" });
      return;
    }

    const quickAlerts = await getAvailableQuickAlerts(eventId);

    res.status(200).json({ quickAlerts });
  } catch (error) {
    console.error("Get available alerts error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleSendQuickAlert(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { alertId } = req.params;
    const { additionalNote } = req.body;
    const volunteerId = req.volunteer!.id;
    const eventId = req.volunteer!.eventId;

    if (!eventId) {
      res.status(400).json({ error: "Volunteer token missing eventId" });
      return;
    }

    if (additionalNote && typeof additionalNote !== "string") {
      res.status(400).json({ error: "Additional note must be a string" });
      return;
    }

    if (additionalNote && additionalNote.length > 200) {
      res
        .status(400)
        .json({ error: "Additional note must be 200 characters or less" });
      return;
    }

    const result = await sendQuickAlert(
      alertId!,
      volunteerId,
      eventId,
      additionalNote?.trim()
    );

    res.status(200).json({
      message: `Alert "${result.alertName}" sent successfully`,
      messageId: result.messageId,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "QUICK_ALERT_NOT_FOUND") {
        res.status(404).json({ error: "Quick alert not found or inactive" });
        return;
      }
      if (error.message === "VOLUNTEER_NOT_FOUND") {
        res.status(404).json({ error: "Volunteer not found" });
        return;
      }
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
    }

    console.error("Send quick alert error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

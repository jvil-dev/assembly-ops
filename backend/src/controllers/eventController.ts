import { Request, Response } from "express";
import {
  createEvent,
  getEventsByAdmin,
  getEventById,
  updateEvent,
  deleteEvent,
} from "../services/eventService.js";
import { EventType } from "../generated/prisma/client.js";

const VALID_EVENT_TYPES: EventType[] = [
  "CIRCUIT_ASSEMBLY",
  "REGIONAL_CONVENTION",
];

export async function handleCreateEvent(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { name, type, location, startDate, endDate } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!name || !type || !location || !startDate || !endDate) {
      res.status(400).json({
        error:
          "Missing required fields: name, type, location, startDate, endDate",
      });
      return;
    }

    // Validate event type
    if (!VALID_EVENT_TYPES.includes(type)) {
      res.status(400).json({
        error: `Invalid event type. Must be one of: ${VALID_EVENT_TYPES.join(
          ", "
        )}`,
      });
      return;
    }

    // Parse dates
    const parsedStartDate = new Date(startDate);
    const parsedEndDate = new Date(endDate);

    if (isNaN(parsedStartDate.getTime()) || isNaN(parsedEndDate.getTime())) {
      res.status(400).json({ error: "Invalid date format" });
      return;
    }

    if (parsedEndDate < parsedStartDate) {
      res.status(400).json({ error: "End date must be after start date" });
      return;
    }

    const event = await createEvent({
      name,
      type,
      location,
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      createdById: adminId,
    });

    res.status(201).json({
      message: "Event created successfully",
      event,
    });
  } catch (error) {
    console.error("Create event error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetEvents(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const adminId = req.admin!.id;
    const events = await getEventsByAdmin(adminId);

    res.status(200).json({ events });
  } catch (error) {
    console.error("Get events error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetEvent(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { id } = req.params;
    const adminId = req.admin!.id;

    const event = await getEventById(id!, adminId);

    res.status(200).json({ event });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get event error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleUpdateEvent(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { id } = req.params;
    const adminId = req.admin!.id;
    const { name, type, location, startDate, endDate } = req.body;

    // Build update object with only provided fields
    const updateData: Record<string, unknown> = {};

    if (name !== undefined) updateData.name = name;
    if (location !== undefined) updateData.location = location;

    if (type !== undefined) {
      if (!VALID_EVENT_TYPES.includes(type)) {
        res.status(400).json({
          error: `Invalid event type. Must be one of: ${VALID_EVENT_TYPES.join(
            ", "
          )}`,
        });
        return;
      }
      updateData.type = type;
    }

    if (startDate !== undefined) {
      const parsedStartDate = new Date(startDate);
      if (isNaN(parsedStartDate.getTime())) {
        res.status(400).json({ error: "Invalid start date format" });
        return;
      }
      updateData.startDate = parsedStartDate;
    }

    if (endDate !== undefined) {
      const parsedEndDate = new Date(endDate);
      if (isNaN(parsedEndDate.getTime())) {
        res.status(400).json({ error: "Invalid end date format" });
        return;
      }
      updateData.endDate = parsedEndDate;
    }

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }

    const event = await updateEvent(id!, adminId, updateData);

    res.status(200).json({
      message: "Event updated successfully",
      event,
    });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Update event error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeleteEvent(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { id } = req.params;
    const adminId = req.admin!.id;

    await deleteEvent(id!, adminId);

    res.status(200).json({ message: "Event deleted successfully" });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Delete event error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

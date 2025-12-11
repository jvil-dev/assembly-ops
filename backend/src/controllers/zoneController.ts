import { Request, Response } from "express";
import {
  createZone,
  getZonesByEvent,
  getZoneById,
  updateZone,
  deleteZone,
} from "../services/zoneService.js";

export async function handleCreateZone(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { name, description, requiredCount, displayOrder } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!name) {
      res.status(400).json({ error: "Zone name is required" });
      return;
    }

    if (typeof name !== "string" || name.trim().length === 0) {
      res.status(400).json({ error: "Zone name must be a non-empty string" });
      return;
    }

    if (requiredCount !== undefined) {
      if (typeof requiredCount !== "number" || requiredCount < 1) {
        res
          .status(400)
          .json({ error: "Required count must be a positive number" });
        return;
      }
    }

    if (displayOrder !== undefined && typeof displayOrder !== "number") {
      res.status(400).json({ error: "Display order must be a number" });
      return;
    }

    const zone = await createZone(
      {
        name: name.trim(),
        description: description?.trim(),
        requiredCount,
        displayOrder,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Zone created successfully",
      zone,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "ZONE_EXISTS") {
        res.status(409).json({ error: "Zone with this name already exists" });
        return;
      }
    }

    console.error("Create zone error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetZones(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const zones = await getZonesByEvent(eventId!, adminId);

    res.status(200).json({ zones });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get zones error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetZone(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, zoneId } = req.params;
    const adminId = req.admin!.id;

    const zone = await getZoneById(zoneId!, eventId!, adminId);

    res.status(200).json({ zone });
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

    console.error("Get zone error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleUpdateZone(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, zoneId } = req.params;
    const { name, description, requiredCount, displayOrder } = req.body;
    const adminId = req.admin!.id;

    // Build update object
    const updateData: Record<string, unknown> = {};

    if (name !== undefined) {
      if (typeof name !== "string" || name.trim().length === 0) {
        res.status(400).json({ error: "Zone name must be a non-empty string" });
        return;
      }
      updateData.name = name.trim();
    }

    if (description !== undefined) {
      updateData.description = description?.trim() || null;
    }

    if (requiredCount !== undefined) {
      if (typeof requiredCount !== "number" || requiredCount < 1) {
        res
          .status(400)
          .json({ error: "Required count must be a positive number" });
        return;
      }
      updateData.requiredCount = requiredCount;
    }

    if (displayOrder !== undefined) {
      if (typeof displayOrder !== "number") {
        res.status(400).json({ error: "Display order must be a number" });
        return;
      }
      updateData.displayOrder = displayOrder;
    }

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }

    const zone = await updateZone(zoneId!, eventId!, adminId, updateData);

    res.status(200).json({
      message: "Zone updated successfully",
      zone,
    });
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
      if (error.message === "ZONE_EXISTS") {
        res.status(409).json({ error: "Zone with this name already exists" });
        return;
      }
    }

    console.error("Update zone error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeleteZone(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, zoneId } = req.params;
    const adminId = req.admin!.id;

    await deleteZone(zoneId!, eventId!, adminId);

    res.status(200).json({ message: "Zone deleted successfully" });
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

    console.error("Delete zone error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

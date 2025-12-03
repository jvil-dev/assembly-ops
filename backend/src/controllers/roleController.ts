import { Request, Response } from "express";
import {
  createRole,
  getRolesByEvent,
  updateRole,
  deleteRole,
} from "../services/roleService.js";

export async function handleCreateRole(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { name, displayOrder } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!name) {
      res.status(400).json({ error: "Role name is required" });
      return;
    }

    if (typeof name !== "string" || name.trim().length === 0) {
      res.status(400).json({ error: "Role name must be a non-empty string" });
      return;
    }

    if (displayOrder !== undefined && typeof displayOrder !== "number") {
      res.status(400).json({ error: "Display order must be a number" });
      return;
    }

    const role = await createRole(
      {
        name: name.trim(),
        displayOrder,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Role created successfully",
      role,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "ROLE_EXISTS") {
        res.status(409).json({ error: "Role with this name already exists" });
        return;
      }
    }

    console.error("Create role error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetRoles(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const roles = await getRolesByEvent(eventId!, adminId);

    res.status(200).json({ roles });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get roles error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleUpdateRole(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, roleId } = req.params;
    const { name, displayOrder } = req.body;
    const adminId = req.admin!.id;

    // Build update object
    const updateData: Record<string, unknown> = {};

    if (name !== undefined) {
      if (typeof name !== "string" || name.trim().length === 0) {
        res.status(400).json({ error: "Role name must be a non-empty string" });
        return;
      }
      updateData.name = name.trim();
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

    const role = await updateRole(roleId!, eventId!, adminId, updateData);

    res.status(200).json({
      message: "Role updated successfully",
      role,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "ROLE_NOT_FOUND") {
        res.status(404).json({ error: "Role not found" });
        return;
      }
      if (error.message === "ROLE_EXISTS") {
        res.status(409).json({ error: "Role with this name already exists" });
        return;
      }
    }

    console.error("Update role error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeleteRole(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, roleId } = req.params;
    const adminId = req.admin!.id;

    await deleteRole(roleId!, eventId!, adminId);

    res.status(200).json({ message: "Role deleted successfully" });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "ROLE_NOT_FOUND") {
        res.status(404).json({ error: "Role not found" });
        return;
      }
      if (error.message === "ROLE_HAS_VOLUNTEERS") {
        res
          .status(409)
          .json({ error: "Cannot delete role with assigned volunteers" });
        return;
      }
    }

    console.error("Delete role error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

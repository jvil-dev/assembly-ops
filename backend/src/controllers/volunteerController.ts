import { Request, Response } from "express";
import {
  createVolunteer,
  bulkCreateVolunteers,
  getVolunteerById,
  getVolunteersByEvent,
  updateVolunteer,
  deleteVolunteer,
  regenerateCredentials,
} from "../services/volunteerService.js";
import { VolunteerAppointment } from "../generated/prisma/client.js";

const VALID_APPOINTMENTS: VolunteerAppointment[] = [
  "PUBLISHER",
  "MINISTERIAL_SERVANT",
  "ELDER",
];

export async function handleCreateVolunteer(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { name, phone, email, congregation, appointment, roleId } = req.body;
    const adminId = req.admin!.id;

    if (!name) {
      res.status(400).json({ error: "Volunteer name is required" });
      return;
    }

    if (typeof name !== "string" || name.trim().length === 0) {
      res.status(400).json({ error: "Name must be a non-empty string" });
      return;
    }

    if (!congregation) {
      res.status(400).json({ error: "Congregation is required" });
      return;
    }

    if (typeof congregation !== "string" || congregation.trim().length === 0) {
      res
        .status(400)
        .json({ error: "Congregation must be a non-empty string" });
      return;
    }

    if (appointment && !VALID_APPOINTMENTS.includes(appointment)) {
      res.status(400).json({
        error: `Invalid appointment. Must be one of: ${VALID_APPOINTMENTS.join(
          ", "
        )}`,
      });
      return;
    }

    const volunteer = await createVolunteer(
      {
        name: name.trim(),
        congregation: congregation.trim(),
        phone,
        email,
        appointment,
        roleId,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Volunteer created successfully",
      volunteer,
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
      if (error.message === "CREDENTIAL_GENERATION_FAILED") {
        res
          .status(500)
          .json({ error: "Failed to generate unique credentials" });
        return;
      }
    }

    console.error("Create volunteer error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleBulkCreateVolunteers(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { volunteers } = req.body;
    const adminId = req.admin!.id;

    if (!volunteers || !Array.isArray(volunteers)) {
      res.status(400).json({ error: "Volunteers array is required" });
      return;
    }

    if (volunteers.length === 0) {
      res.status(400).json({ error: "Volunteers array cannot be empty" });
      return;
    }

    if (volunteers.length > 100) {
      res.status(400).json({ error: "Maximum 100 volunteers per request" });
      return;
    }

    for (let i = 0; i < volunteers.length; i++) {
      const vol = volunteers[i];

      if (
        !vol.name ||
        typeof vol.name !== "string" ||
        vol.name.trim().length === 0
      ) {
        res.status(400).json({
          error: `Volunteer at index ${i} must have a valid name`,
        });
        return;
      }

      if (
        !vol.congregation ||
        typeof vol.congregation !== "string" ||
        vol.congregation.trim().length === 0
      ) {
        res.status(400).json({
          error: `Volunteer at index ${i} must have a valid congregation`,
        });
        return;
      }

      if (vol.appointment && !VALID_APPOINTMENTS.includes(vol.appointment)) {
        res.status(400).json({
          error: `Volunteer at index ${i} has invalid appointment. Must be one of: ${VALID_APPOINTMENTS.join(
            ", "
          )}`,
        });
        return;
      }
    }

    const createdVolunteers = await bulkCreateVolunteers(
      {
        volunteers: volunteers.map((v: Record<string, unknown>) => {
          const volunteer: {
            name: string;
            congregation: string;
            phone?: string;
            email?: string;
            appointment?: VolunteerAppointment;
            roleId?: string;
          } = {
            name: (v.name as string).trim(),
            congregation: (v.congregation as string).trim(),
          };

          if (v.phone !== undefined) volunteer.phone = v.phone as string;
          if (v.email !== undefined) volunteer.email = v.email as string;
          if (v.appointment !== undefined)
            volunteer.appointment = v.appointment as VolunteerAppointment;
          if (v.roleId !== undefined) volunteer.roleId = v.roleId as string;

          return volunteer;
        }),
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: `${createdVolunteers.length} volunteers created successfully`,
      volunteers: createdVolunteers,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "ROLE_NOT_FOUND") {
        res.status(404).json({ error: "One or more roles not found" });
        return;
      }
      if (error.message === "CREDENTIAL_GENERATION_FAILED") {
        res
          .status(500)
          .json({ error: "Failed to generate unique credentials" });
        return;
      }
    }

    console.error("Bulk create volunteers error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetVolunteers(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const volunteers = await getVolunteersByEvent(eventId!, adminId);

    res.status(200).json({ volunteers });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get volunteers error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetVolunteer(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, volunteerId } = req.params;
    const adminId = req.admin!.id;

    const volunteer = await getVolunteerById(volunteerId!, eventId!, adminId);

    res.status(200).json({ volunteer });
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

    console.error("Get volunteer error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleUpdateVolunteer(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, volunteerId } = req.params;
    const { name, phone, email, congregation, appointment, roleId } = req.body;
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

    if (phone !== undefined) updateData.phone = phone;
    if (email !== undefined) updateData.email = email;
    if (congregation !== undefined) updateData.congregation = congregation;

    if (appointment !== undefined) {
      if (appointment !== null && !VALID_APPOINTMENTS.includes(appointment)) {
        res.status(400).json({
          error: `Invalid appointment. Must be one of: ${VALID_APPOINTMENTS.join(
            ", "
          )}`,
        });
        return;
      }
      updateData.appointment = appointment;
    }

    if (roleId !== undefined) updateData.roleId = roleId; // Can be null to unassign

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }

    const volunteer = await updateVolunteer(
      volunteerId!,
      eventId!,
      adminId,
      updateData
    );

    res.status(200).json({
      message: "Volunteer updated successfully",
      volunteer,
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
      if (error.message === "ROLE_NOT_FOUND") {
        res.status(404).json({ error: "Role not found" });
        return;
      }
    }

    console.error("Update volunteer error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeleteVolunteer(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, volunteerId } = req.params;
    const adminId = req.admin!.id;

    await deleteVolunteer(volunteerId!, eventId!, adminId);

    res.status(200).json({ message: "Volunteer deleted successfully" });
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

    console.error("Delete volunteer error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleRegenerateCredentials(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, volunteerId } = req.params;
    const adminId = req.admin!.id;

    const volunteer = await regenerateCredentials(
      volunteerId!,
      eventId!,
      adminId
    );

    res.status(200).json({
      message: "Credentials regenerated successfully",
      volunteer,
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
      if (error.message === "CREDENTIAL_GENERATION_FAILED") {
        res
          .status(500)
          .json({ error: "Failed to generate unique credentials" });
        return;
      }
    }

    console.error("Regenerate credentials error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

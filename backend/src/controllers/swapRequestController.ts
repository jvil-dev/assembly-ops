import { Request, Response } from "express";
import {
  createSwapRequest,
  getSwapRequestsByEvent,
  getSwapRequestById,
  approveSwapRequest,
  denySwapRequest,
} from "../services/swapRequestService.js";
import { SwapRequestStatus } from "../generated/prisma/client.js";

const VALID_STATUSES: SwapRequestStatus[] = ["PENDING", "APPROVED", "DENIED"];

export async function handleCreateSwapRequest(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { assignmentId, reason, suggestedVolunteerId } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!assignmentId || !reason) {
      res.status(400).json({
        error: "Missing required fields: assignmentId, reason",
      });
      return;
    }

    if (typeof reason !== "string" || reason.trim().length === 0) {
      res.status(400).json({ error: "Reason must be a non-empty string" });
      return;
    }

    const swapRequest = await createSwapRequest(
      {
        assignmentId,
        reason: reason.trim(),
        suggestedVolunteerId,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Swap request created successfully",
      swapRequest,
    });
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
      if (error.message === "PENDING_REQUEST_EXISTS") {
        res.status(409).json({
          error: "A pending swap request already exists for this assignment",
        });
        return;
      }
      if (error.message === "SUGGESTED_VOLUNTEER_NOT_FOUND") {
        res.status(404).json({ error: "Suggested volunteer not found" });
        return;
      }
      if (error.message === "SUGGESTED_VOLUNTEER_UNAVAILABLE") {
        res.status(409).json({
          error: "Suggested volunteer is not available for this session",
        });
        return;
      }
      if (error.message === "SUGGESTED_VOLUNTEER_ALREADY_ASSIGNED") {
        res.status(409).json({
          error: "Suggested volunteer is already assigned to this session",
        });
        return;
      }
    }

    console.error("Create swap request error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetSwapRequests(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { status } = req.query;
    const adminId = req.admin!.id;

    // Validate status filter if provided
    if (status && !VALID_STATUSES.includes(status as SwapRequestStatus)) {
      res.status(400).json({
        error: `Invalid status filter. Must be one of: ${VALID_STATUSES.join(
          ", "
        )}`,
      });
      return;
    }

    const swapRequests = await getSwapRequestsByEvent(eventId!, adminId, {
      status: status as SwapRequestStatus | undefined,
    });

    res.status(200).json({ swapRequests });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get swap requests error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetSwapRequest(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, requestId } = req.params;
    const adminId = req.admin!.id;

    const swapRequest = await getSwapRequestById(requestId!, eventId!, adminId);

    res.status(200).json({ swapRequest });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "SWAP_REQUEST_NOT_FOUND") {
        res.status(404).json({ error: "Swap request not found" });
        return;
      }
    }

    console.error("Get swap request error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleApproveSwapRequest(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, requestId } = req.params;
    const adminId = req.admin!.id;

    const swapRequest = await approveSwapRequest(requestId!, eventId!, adminId);

    res.status(200).json({
      message: "Swap request approved. Original assignment has been removed.",
      swapRequest,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "SWAP_REQUEST_NOT_FOUND") {
        res.status(404).json({ error: "Swap request not found" });
        return;
      }
      if (error.message === "REQUEST_ALREADY_RESOLVED") {
        res
          .status(409)
          .json({ error: "This request has already been resolved" });
        return;
      }
    }

    console.error("Approve swap request error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDenySwapRequest(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, requestId } = req.params;
    const adminId = req.admin!.id;

    const swapRequest = await denySwapRequest(requestId!, eventId!, adminId);

    res.status(200).json({
      message: "Swap request denied. Assignment remains unchanged.",
      swapRequest,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "SWAP_REQUEST_NOT_FOUND") {
        res.status(404).json({ error: "Swap request not found" });
        return;
      }
      if (error.message === "REQUEST_ALREADY_RESOLVED") {
        res
          .status(409)
          .json({ error: "This request has already been resolved" });
        return;
      }
    }

    console.error("Deny swap request error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

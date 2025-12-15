import { Request, Response } from "express";
import {
  sendMessage,
  getMessagesByEvent,
  getMessageById,
} from "../services/messageService.js";
import { MessagePriority, RecipientType } from "../generated/prisma/client.js";

const VALID_PRIORITIES: MessagePriority[] = ["NORMAL", "URGENT"];
const VALID_RECIPIENT_TYPES: RecipientType[] = [
  "INDIVIDUAL",
  "ZONE",
  "ROLE",
  "BROADCAST",
];

export async function handleSendMessage(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const {
      content,
      priority,
      recipientType,
      targetVolunteerId,
      targetZoneId,
      targetRoleId,
    } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (
      !content ||
      typeof content !== "string" ||
      content.trim().length === 0
    ) {
      res.status(400).json({ error: "Message content is required" });
      return;
    }

    if (content.length > 1000) {
      res
        .status(400)
        .json({ error: "Message content must be 1000 characters or less" });
      return;
    }

    if (!recipientType) {
      res.status(400).json({ error: "Recipient type is required" });
      return;
    }

    if (!VALID_RECIPIENT_TYPES.includes(recipientType)) {
      res.status(400).json({
        error: `Invalid recipient type. Must be one of: ${VALID_RECIPIENT_TYPES.join(", ")}`,
      });
      return;
    }

    if (priority && !VALID_PRIORITIES.includes(priority)) {
      res.status(400).json({
        error: `Invalid priority. Must be one of: ${VALID_PRIORITIES.join(", ")}`,
      });
      return;
    }

    // Validate target based on recipient type
    if (recipientType === "INDIVIDUAL" && !targetVolunteerId) {
      res.status(400).json({
        error: "targetVolunteerId is required for INDIVIDUAL messages",
      });
      return;
    }

    if (recipientType === "ZONE" && !targetZoneId) {
      res.status(400).json({
        error: "targetZoneId is required for ZONE messages",
      });
      return;
    }

    if (recipientType === "ROLE" && !targetRoleId) {
      res.status(400).json({
        error: "targetRoleId is required for ROLE messages",
      });
      return;
    }

    const message = await sendMessage(
      {
        content: content.trim(),
        priority,
        recipientType,
        targetVolunteerId,
        targetZoneId,
        targetRoleId,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Message sent successfully",
      data: message,
    });
  } catch (error) {
    if (error instanceof Error) {
      switch (error.message) {
        case "EVENT_NOT_FOUND":
          res.status(404).json({ error: "Event not found" });
          return;
        case "VOLUNTEER_NOT_FOUND":
          res.status(404).json({ error: "Target volunteer not found" });
          return;
        case "ZONE_NOT_FOUND":
          res.status(404).json({ error: "Target zone not found" });
          return;
        case "ROLE_NOT_FOUND":
          res.status(404).json({ error: "Target role not found" });
          return;
        case "NO_RECIPIENTS":
          res
            .status(400)
            .json({ error: "No recipients found for this message" });
          return;
        case "TARGET_VOLUNTEER_REQUIRED":
        case "TARGET_ZONE_REQUIRED":
        case "TARGET_ROLE_REQUIRED":
          res.status(400).json({ error: "Required target not provided" });
          return;
      }
    }

    console.error("Send message error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetMessages(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const adminId = req.admin!.id;

    const messages = await getMessagesByEvent(eventId!, adminId);

    res.status(200).json({ messages });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get messages error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetMessage(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, messageId } = req.params;
    const adminId = req.admin!.id;

    const message = await getMessageById(messageId!, eventId!, adminId);

    res.status(200).json({ message });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "MESSAGE_NOT_FOUND") {
        res.status(404).json({ error: "Message not found" });
        return;
      }
    }

    console.error("Get message error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

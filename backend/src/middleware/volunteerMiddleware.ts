import { Request, Response, NextFunction } from "express";
import { verifyToken } from "../utils/tokenUtils.js";

declare global {
  namespace Express {
    interface Request {
      volunteer?: {
        id: string;
        email?: string | undefined;
        type: "volunteer";
        eventId: string;
      };
    }
  }
}

export async function requireVolunteer(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      res.status(401).json({ error: "Authorization header required" });
      return;
    }

    const parts = authHeader.split(" ");

    if (parts.length !== 2 || parts[0] !== "Bearer") {
      res
        .status(401)
        .json({ error: "Invalid authorization format. Use: Bearer <token>" });
      return;
    }

    const token = parts[1]!;
    const payload = verifyToken(token);

    // Ensure this is a volunteer token
    if (payload.type !== "volunteer") {
      res.status(403).json({ error: "Volunteer access required" });
      return;
    }

    // Ensure eventId is present (volunteer tokens should have this)
    if (!payload.eventId) {
      res.status(403).json({ error: "Invalid volunteer token" });
      return;
    }

    // Attach volunteer data to request
    req.volunteer = {
      id: payload.id,
      email: payload.email,
      type: "volunteer",
      eventId: payload.eventId,
    };

    next();
  } catch (error) {
    res.status(401).json({ error: "Invalid or required token" });
  }
}

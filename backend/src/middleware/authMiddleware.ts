import { Request, Response, NextFunction } from "express";
import { verifyToken } from "../utils/tokenUtils.js";

export function requireAdmin(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      res.status(401).json({ error: "Authorization header required" });
      return;
    }

    // Expected format: "Bearer <token>"
    const parts = authHeader.split(" ");

    if (parts.length !== 2 || parts[0] !== "Bearer") {
      res
        .status(401)
        .json({ error: "Invalid authorization format. Use: Bearer <token>" });
      return;
    }

    const token = parts[1]!;
    const payload = verifyToken(token);

    // Ensure this is an admin token
    if (payload.type !== "admin") {
      res.status(403).json({ error: "Admin access required" });
      return;
    }

    // Attach admin data to request
    req.admin = payload;
    next();
  } catch (error) {
    // Log error for debugging
    if (error instanceof Error) {
      // JWT-specific errors are expected and don't need stack traces
      if (
        error.name === "JsonWebTokenError" ||
        error.name === "TokenExpiredError"
      ) {
        console.log("Auth failed:", error.message);
        res.status(401).json({ error: "Invalid or expired token" });
        return;
      }

      // Unexpected errors should be logged with stack trace
      console.error("Unexpected auth error:", error);
      res.status(500).json({ error: "Internal server error" });
      return;
    }

    // Unknown error type
    console.error("Unknown auth error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export function requireVolunteer(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      res.status(401).json({
        error: "Authorization header required",
      });
      return;
    }

    const parts = authHeader.split(" ");

    if (parts.length !== 2 || parts[0] !== "Bearer") {
      res.status(401).json({
        error: "Invalid authorization format. Use: Bearer <token>",
      });
      return;
    }

    const token = parts[1]!;
    const payload = verifyToken(token);

    if (payload.type !== "volunteer") {
      res.status(403).json({
        error: "Volunteer access required",
      });
      return;
    }

    req.volunteer = {
      id: payload.id,
      email: payload.email,
      type: "volunteer",
      eventId: payload.eventId!,
    };
    next();
  } catch (_error) {
    res.status(401).json({
      error: "Invalid or expired token",
    });
  }
}

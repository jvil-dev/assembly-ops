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
    // Token verification failed (invalid, expired, etc)
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

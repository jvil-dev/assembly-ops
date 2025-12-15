import { Router } from "express";
import {
  handleCreateEvent,
  handleGetEvents,
  handleGetEvent,
  handleUpdateEvent,
  handleDeleteEvent,
} from "../controllers/eventController.js";
import { requireAdmin } from "../middleware/authMiddleware.js";
import roleRoutes from "./roleRoutes.js";
import volunteerRoutes from "./volunteerRoutes.js";
import sessionRoutes from "./sessionRoutes.js";
import zoneRoutes from "./zoneRoutes.js";
import assignmentRoutes from "./assignmentRoutes.js";
import swapRequestRoutes from "./swapRequestRoutes.js";
import scheduleRoutes from "./scheduleRoutes.js";
import checkInRoutes from "./checkInRoutes.js";
import messageRoutes from "./messageRoutes.js";
import quickAlertRoutes from "./quickAlertRoutes.js";

const router = Router();

// All event routes require admin authentication
router.use(requireAdmin);

router.post("/", handleCreateEvent);
router.get("/", handleGetEvents);
router.get("/:id", handleGetEvent);
router.put("/:id", handleUpdateEvent);
router.delete("/:id", handleDeleteEvent);

router.use("/:eventId/roles", roleRoutes);
router.use("/:eventId/volunteers", volunteerRoutes);
router.use("/:eventId/sessions", sessionRoutes);
router.use("/:eventId/zones", zoneRoutes);
router.use("/:eventId/assignments", assignmentRoutes);
router.use("/:eventId/swap-requests", swapRequestRoutes);
router.use("/:eventId/schedule", scheduleRoutes);
router.use("/:eventId/check-ins", checkInRoutes);
router.use("/:eventId/messages", messageRoutes);
router.use("/:eventId/quick-alerts", quickAlertRoutes);

export default router;

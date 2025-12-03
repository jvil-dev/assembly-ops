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

export default router;

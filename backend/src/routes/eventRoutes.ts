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

const router = Router();

// All event routes require admin authentication
router.use(requireAdmin);

router.post("/", handleCreateEvent);
router.get("/", handleGetEvents);
router.get("/:id", handleGetEvent);
router.put("/:id", handleUpdateEvent);
router.delete("/:id", handleDeleteEvent);

router.use("/:eventId/roles", roleRoutes);

export default router;

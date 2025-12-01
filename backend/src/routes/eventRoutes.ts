import { Router } from "express";
import {
  handleCreateEvent,
  handleGetEvents,
  handleGetEvent,
  handleUpdateEvent,
  handleDeleteEvent,
} from "../controllers/eventController.js";
import { requireAdmin } from "../middleware/authMiddleware.js";

const router = Router();

// All event routes require admin authentication
router.use(requireAdmin);

router.post("/", handleCreateEvent);
router.get("/", handleGetEvents);
router.get("/", handleGetEvent);
router.put("/", handleUpdateEvent);
router.delete("/", handleDeleteEvent);

export default router;

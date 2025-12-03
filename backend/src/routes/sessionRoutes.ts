import { Router } from "express";
import {
  handleCreateSession,
  handleGetSessions,
  handleGetSession,
  handleUpdateSession,
  handleDeleteSession,
} from "../controllers/sessionController.js";
import { handleGetAvailableVolunteers } from "../controllers/availabilityController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateSession);
router.get("/", handleGetSessions);
router.get("/:sessionId", handleGetSession);
router.put("/:sessionId", handleUpdateSession);
router.delete("/:sessionId", handleDeleteSession);

router.get("/:sessionId/available-volunteers", handleGetAvailableVolunteers);
export default router;

import { Router } from "express";
import {
  handleCreateSession,
  handleGetSessions,
  handleGetSession,
  handleUpdateSession,
  handleDeleteSession,
} from "../controllers/sessionController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateSession);
router.get("/", handleGetSessions);
router.get("/:sessionId", handleGetSession);
router.put("/:sessionId", handleUpdateSession);
router.delete("/:sessionId", handleDeleteSession);

export default router;

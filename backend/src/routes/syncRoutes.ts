import { Router } from "express";
import {
  handleGetSyncStatus,
  handleGetFullSync,
  handleGetDeltaSync,
  handleProcessQueue,
} from "../controllers/syncController.js";
import { requireAuth } from "../middleware/authMiddleware.js";

const router = Router({ mergeParams: true });

router.get("/status", handleGetSyncStatus);
router.get("/full", handleGetFullSync);
router.get("/delta", handleGetDeltaSync);

// Queue accepts both admin and volunteer tokens
router.post("/queue", requireAuth, handleProcessQueue);

export default router;

import { Router } from "express";
import {
  handleGetSyncStatus,
  handleGetFullSync,
  handleGetDeltaSync,
} from "../controllers/syncController.js";

const router = Router({ mergeParams: true });

router.get("/status", handleGetSyncStatus);
router.get("/full", handleGetFullSync);
router.get("/delta", handleGetDeltaSync);

export default router;

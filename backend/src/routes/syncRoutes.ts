import { Router } from "express";
import {
  handleGetSyncStatus,
  handleGetFullSync,
} from "../controllers/syncController.js";

const router = Router({ mergeParams: true });

router.get("/status", handleGetSyncStatus);
router.get("/full", handleGetFullSync);

export default router;

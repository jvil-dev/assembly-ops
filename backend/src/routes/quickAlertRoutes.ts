import { Router } from "express";
import {
  handleCreateQuickAlert,
  handleGetQuickAlerts,
  handleGetQuickAlert,
  handleUpdateQuickAlert,
  handleDeleteQuickAlert,
} from "../controllers/quickAlertController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateQuickAlert);
router.get("/", handleGetQuickAlerts);
router.get("/:alertId", handleGetQuickAlert);
router.put("/:alertId", handleUpdateQuickAlert);
router.delete("/:alertId", handleDeleteQuickAlert);

export default router;

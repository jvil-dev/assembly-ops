import { Router } from "express";
import {
  handleCreateZone,
  handleGetZones,
  handleGetZone,
  handleUpdateZone,
  handleDeleteZone,
} from "../controllers/zoneController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateZone);
router.get("/", handleGetZones);
router.get("/:zoneId", handleGetZone);
router.put("/:zoneId", handleUpdateZone);
router.delete("/:zoneId", handleDeleteZone);

export default router;

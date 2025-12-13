import { Router } from "express";
import {
  handleAdminCheckIn,
  handleAdminUpdateCheckIn,
  handleAdminDeleteCheckIn,
  handleGetActiveCheckIns,
  handleGetCheckInsByZone,
  handleGetCheckInsBySession,
  handleGetCheckInSummary,
} from "../controllers/checkInController.js";

const router = Router({ mergeParams: true });

// Status view routes
router.get("/active", handleGetActiveCheckIns);
router.get("/by-zone/:zoneId", handleGetCheckInsByZone);
router.get("/by-session/:sessionId", handleGetCheckInsBySession);
router.get("/summary", handleGetCheckInSummary);

// Admin check-in controls
router.post("/:assignmentId", handleAdminCheckIn);
router.put("/:assignmentId", handleAdminUpdateCheckIn);
router.delete("/:assignmentId", handleAdminDeleteCheckIn);

export default router;

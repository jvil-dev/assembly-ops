import { Router } from "express";
import {
  handleAdminCheckIn,
  handleAdminUpdateCheckIn,
  handleAdminDeleteCheckIn,
} from "../controllers/checkInController.js";

const router = Router({ mergeParams: true });

// Admin check-in controls
router.post("/:assignmentId", handleAdminCheckIn);
router.put("/:assignmentId", handleAdminUpdateCheckIn);
router.delete("/:assignmentId", handleAdminDeleteCheckIn);

export default router;

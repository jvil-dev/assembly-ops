// Defines /auth endpoints

import { Router } from "express";
import {
  handleAdminRegister,
  handleAdminLogin,
  handleGetMe,
  handleVolunteerLogin,
} from "../controllers/authController.js";
import { requireAdmin } from "../middleware/authMiddleware.js";
import { requireVolunteer } from "../middleware/volunteerMiddleware.js";
import { handleGetMyAssignments } from "../controllers/scheduleController.js";

const router = Router();

// Admin routes
router.post("/admin/register", handleAdminRegister);
router.post("/admin/login", handleAdminLogin);
router.get("/admin/me", requireAdmin, handleGetMe);

// Volunteer routes
router.post("/volunteer/login", handleVolunteerLogin);
router.get(
  "/volunteer/my-assignments",
  requireVolunteer,
  handleGetMyAssignments
);

export default router;

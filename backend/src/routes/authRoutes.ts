// Defines /auth endpoints

import { Router } from "express";
import {
  handleAdminRegister,
  handleAdminLogin,
  handleGetMe,
  handleVolunteerLogin,
} from "../controllers/authController.js";
import {
  handleVolunteerCheckIn,
  handleGetVolunteerStatus,
  handleVolunteerCheckOut,
} from "../controllers/checkInController.js";
import { requireAdmin } from "../middleware/authMiddleware.js";
import { requireVolunteer } from "../middleware/volunteerMiddleware.js";
import { handleGetMyAssignments } from "../controllers/scheduleController.js";
import {
  handleGetVolunteerInbox,
  handleGetUnreadCount,
  handleMarkAsRead,
} from "../controllers/messageController.js";
import {
  handleGetAvailableAlerts,
  handleSendQuickAlert,
} from "../controllers/quickAlertController.js";

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
router.get("/volunteer/my-status", requireVolunteer, handleGetVolunteerStatus);
router.post("/volunteer/check-in", requireVolunteer, handleVolunteerCheckIn);
router.post("/volunteer/check-out", requireVolunteer, handleVolunteerCheckOut);

// Volunteer message routes
router.get("/volunteer/messages", requireVolunteer, handleGetVolunteerInbox);
router.get(
  "/volunteer/messages/unread-count",
  requireVolunteer,
  handleGetUnreadCount
);
router.put(
  "/volunteer/messages/:messageId/read",
  requireVolunteer,
  handleMarkAsRead
);

// Volunteer quick alert routes
router.get(
  "/volunteer/quick-alerts",
  requireVolunteer,
  handleGetAvailableAlerts
);
router.post(
  "/volunteer/quick-alerts/:alertId/send",
  requireVolunteer,
  handleSendQuickAlert
);

export default router;

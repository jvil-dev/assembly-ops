// Defines /auth endpoints

import { Router } from "express";
import {
  handleAdminRegister,
  handleAdminLogin,
  handleGetMe,
} from "../controllers/authController.js";
import { requireAdmin } from "../middleware/authMiddleware.js";

const router = Router();

// Admin routes
router.post("/admin/register", handleAdminRegister);
router.post("/admin/login", handleAdminLogin);
router.get("/admin/me", requireAdmin, handleGetMe);

export default router;

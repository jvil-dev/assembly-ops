// Defines /auth endpoints

import { Router } from "express";
import {
  handleAdminRegister,
  handleAdminLogin,
} from "../controllers/authController";

const router = Router();

// Admin routes
router.post("/admin/register", handleAdminRegister);
router.post("/admin/login", handleAdminLogin);

export default router;

// Defines /auth endpoints

import { Router } from "express";
import { handleAdminRegister } from "../controllers/authController";

const router = Router();

// Admin routes
router.post("/admin/register", handleAdminRegister);

export default router;

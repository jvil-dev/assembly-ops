// Handles HTTP request/response

import { Request, Response } from "express";
import { registerAdmin } from "../services/authService.js";

export async function handleAdminRegister(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { email, password, name, congregation } = req.body;

    // Basic validation
    if (!email || !password || !name || !congregation) {
      res.status(400).json({
        error: "Missing required fields: email, password, name, congregation",
      });
      return;
    }

    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      res.status(400).json({ error: "Invalid email format" });
      return;
    }

    // Password length validation
    if (password.length < 8) {
      res.status(400).json({
        error: "Password must contain at least 8 characters",
      });
      return;
    }

    const { admin, token } = await registerAdmin({
      email,
      password,
      name,
      congregation,
    });

    res.status(201).json({
      message: "Admin registered successfully",
      admin,
      token,
    });
  } catch (error) {
    if (error instanceof Error && error.message === "EMAIL_EXISTS") {
      res.status(409).json({ error: "Email already registered" });
      return;
    }

    console.error("Registration error: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

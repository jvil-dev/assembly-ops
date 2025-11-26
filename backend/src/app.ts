import express from "express";
import cors from "cors";
import helmet from "helmet";
import "dotenv/config";

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Test Route
app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    message: "AssemblyOps Backend is running!",
    timestamp: new Date().toISOString(),
  });
});

export default app;

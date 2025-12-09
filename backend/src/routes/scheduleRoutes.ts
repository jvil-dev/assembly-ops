import { Router } from "express";
import {
  handleGetScheduleGrid,
  handleGetScheduleSummary,
} from "../controllers/scheduleController.js";

const router = Router({ mergeParams: true });

router.get("/", handleGetScheduleGrid);
router.get("/summary", handleGetScheduleSummary);

export default router;

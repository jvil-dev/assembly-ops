import { Router } from "express";
import {
  handleCreateAssignment,
  handleBulkCreateAssignments,
  handleGetAssignments,
  handleGetAssignmentsBySession,
  handleGetAssignmentsByZone,
  handleDeleteAssignment,
} from "../controllers/assignmentController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateAssignment);
router.post("/bulk", handleBulkCreateAssignments);
router.get("/", handleGetAssignments);
router.get("/by-session/:sessionId", handleGetAssignmentsBySession);
router.get("/by-zone/:zoneId", handleGetAssignmentsByZone);
router.delete("/:assignmentId", handleDeleteAssignment);

export default router;

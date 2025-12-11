import { Router } from "express";
import {
  handleCreateSwapRequest,
  handleGetSwapRequests,
  handleGetSwapRequest,
  handleApproveSwapRequest,
  handleDenySwapRequest,
} from "../controllers/swapRequestController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateSwapRequest);
router.get("/", handleGetSwapRequests);
router.get("/:requestId", handleGetSwapRequest);
router.put("/:requestId/approve", handleApproveSwapRequest);
router.put("/:requestId/deny", handleDenySwapRequest);

export default router;

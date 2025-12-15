import { Router } from "express";
import {
  handleSendMessage,
  handleGetMessages,
  handleGetMessage,
  handleGetReceipts,
} from "../controllers/messageController.js";

const router = Router({ mergeParams: true });

router.post("/", handleSendMessage);
router.get("/", handleGetMessages);
router.get("/:messageId", handleGetMessage);
router.get("/:messageId/receipts", handleGetReceipts);

export default router;

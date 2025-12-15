import { Router } from "express";
import {
  handleSendMessage,
  handleGetMessages,
  handleGetMessage,
} from "../controllers/messageController.js";

const router = Router({ mergeParams: true });

router.post("/", handleSendMessage);
router.get("/", handleGetMessages);
router.get("/:messageId", handleGetMessage);

export default router;

import { Router } from "express";
import {
  handleCreatePost,
  handleGetPosts,
  handleGetPost,
  handleUpdatePost,
  handleDeletePost,
} from "../controllers/postController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreatePost);
router.get("/", handleGetPosts);
router.get("/:postId", handleGetPost);
router.get("/:postId", handleGetPost);
router.put("/:postId", handleUpdatePost);
router.delete("/:postId", handleDeletePost);

export default router;

import { Request, Response } from "express";
import {
  createPost,
  getPostsByEvent,
  getPostById,
  updatePost,
  deletePost,
} from "../services/postService.js";

export async function handleCreatePost(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const {
      name,
      description,
      capacity,
      displayOrder,
      departmentId,
      isActive,
    } = req.body;
    const adminId = req.admin!.id;

    // Validation
    if (!name) {
      res.status(400).json({ error: "Post name is required" });
      return;
    }

    if (typeof name !== "string" || name.trim().length === 0) {
      res.status(400).json({ error: "Post name must be a non-empty string" });
      return;
    }

    if (!departmentId) {
      res.status(400).json({ error: "Department ID is required" });
      return;
    }

    if (capacity !== undefined) {
      if (typeof capacity !== "number" || capacity < 1) {
        res.status(400).json({ error: "Capacity must be a positive number" });
        return;
      }
    }

    if (displayOrder !== undefined && typeof displayOrder !== "number") {
      res.status(400).json({ error: "Display order must be a number" });
      return;
    }

    const post = await createPost(
      {
        name: name.trim(),
        description: description?.trim(),
        capacity,
        displayOrder,
        departmentId,
        isActive: isActive ?? true,
        eventId: eventId!,
      },
      adminId
    );

    res.status(201).json({
      message: "Post created successfully",
      post,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "DEPARTMENT_NOT_FOUND") {
        res.status(404).json({ error: "Department not found" });
        return;
      }
      if (error.message === "POST_EXISTS") {
        res.status(409).json({
          error: "Post with this name already exists in this department",
        });
        return;
      }
    }

    console.error("Create post error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetPosts(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId } = req.params;
    const { departmentId } = req.query;
    const adminId = req.admin!.id;

    const posts = await getPostsByEvent(
      eventId!,
      adminId,
      departmentId as string | undefined
    );

    res.status(200).json({ posts });
  } catch (error) {
    if (error instanceof Error && error.message === "EVENT_NOT_FOUND") {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    console.error("Get posts error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleGetPost(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, postId } = req.params;
    const adminId = req.admin!.id;

    const post = await getPostById(postId!, eventId!, adminId);

    res.status(200).json({ post });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "POST_NOT_FOUND") {
        res.status(404).json({ error: "Post not found" });
        return;
      }
    }

    console.error("Get post error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleUpdatePost(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, postId } = req.params;
    const {
      name,
      description,
      capacity,
      displayOrder,
      departmentId,
      isActive,
    } = req.body;
    const adminId = req.admin!.id;

    // Build update object
    const updateData: Record<string, unknown> = {};

    if (name !== undefined) {
      if (typeof name !== "string" || name.trim().length === 0) {
        res.status(400).json({ error: "Post name must be a non-empty string" });
        return;
      }
      updateData.name = name.trim();
    }

    if (description !== undefined) {
      updateData.description = description?.trim() || null;
    }

    if (capacity !== undefined) {
      if (typeof capacity !== "number" || capacity < 1) {
        res.status(400).json({ error: "Capacity must be a positive number" });
        return;
      }
      updateData.capacity = capacity;
    }

    if (displayOrder !== undefined) {
      if (typeof displayOrder !== "number") {
        res.status(400).json({ error: "Display order must be a number" });
        return;
      }
      updateData.displayOrder = displayOrder;
    }

    if (departmentId !== undefined) {
      updateData.departmentId = departmentId;
    }

    if (isActive !== undefined) {
      if (typeof isActive !== "boolean") {
        res.status(400).json({ error: "isActive must be a boolean" });
        return;
      }
      updateData.isActive = isActive;
    }

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }

    const post = await updatePost(postId!, eventId!, adminId, updateData);

    res.status(200).json({
      message: "Post updated successfully",
      post,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "POST_NOT_FOUND") {
        res.status(404).json({ error: "Post not found" });
        return;
      }
      if (error.message === "DEPARTMENT_NOT_FOUND") {
        res.status(404).json({ error: "Department not found" });
        return;
      }
      if (error.message === "POST_EXISTS") {
        res.status(409).json({
          error: "Post with this name already exists in this department",
        });
        return;
      }
    }

    console.error("Update post error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

export async function handleDeletePost(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { eventId, postId } = req.params;
    const adminId = req.admin!.id;

    await deletePost(postId!, eventId!, adminId);

    res.status(200).json({ message: "Post deleted successfully" });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === "EVENT_NOT_FOUND") {
        res.status(404).json({ error: "Event not found" });
        return;
      }
      if (error.message === "POST_NOT_FOUND") {
        res.status(404).json({ error: "Post not found" });
        return;
      }
    }

    console.error("Delete post error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

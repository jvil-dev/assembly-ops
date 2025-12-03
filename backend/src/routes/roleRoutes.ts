import { Router } from "express";
import {
  handleCreateRole,
  handleGetRoles,
  handleUpdateRole,
  handleDeleteRole,
} from "../controllers/roleController.js";

const router = Router({ mergeParams: true });
// "mergeParams: true" lets this router access ":eventId" from the parent route

router.post("/", handleCreateRole);
router.get("/", handleGetRoles);
router.put("/:roleId", handleUpdateRole);
router.delete("/:roleId", handleDeleteRole);

export default router;

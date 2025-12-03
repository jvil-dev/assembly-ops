import { Router } from "express";
import {
  handleCreateVolunteer,
  handleBulkCreateVolunteers,
  handleGetVolunteers,
  handleGetVolunteer,
  handleUpdateVolunteer,
  handleDeleteVolunteer,
  handleRegenerateCredentials,
} from "../controllers/volunteerController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateVolunteer);
router.post("/", handleBulkCreateVolunteers);
router.get("/", handleGetVolunteers);
router.get("/:volunteerId", handleGetVolunteer);
router.put("/:volunteerId", handleUpdateVolunteer);
router.delete("/:volunteerId", handleDeleteVolunteer);
router.post("/:volunteerId/regenerate", handleRegenerateCredentials);

export default router;

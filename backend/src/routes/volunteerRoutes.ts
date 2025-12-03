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
import {
  handleGetVolunteerAvailability,
  handleSetVolunteerAvailability,
} from "../controllers/availabilityController.js";

const router = Router({ mergeParams: true });

router.post("/", handleCreateVolunteer);
router.post("/bulk", handleBulkCreateVolunteers);
router.get("/", handleGetVolunteers);
router.get("/:volunteerId", handleGetVolunteer);
router.put("/:volunteerId", handleUpdateVolunteer);
router.delete("/:volunteerId", handleDeleteVolunteer);
router.post("/:volunteerId/regenerate", handleRegenerateCredentials);

router.get("/:volunteerId/availability", handleGetVolunteerAvailability);
router.put("/:volunteerId/availability", handleSetVolunteerAvailability);

export default router;

/**
 * Event Note Resolvers
 *
 * GraphQL resolvers for overseer coordination notes.
 *
 * Queries:
 *   - eventNote: Get note by ID (admin only)
 *   - departmentNotes: Get notes for a department (admin)
 *   - eventNotes: Get all notes for an event (admin)
 *
 * Mutations:
 *   - createEventNote: Create a new note (admin)
 *   - updateEventNote: Update an existing note (admin)
 *   - deleteEventNote: Delete a note (admin)
 */
import { Context } from '../context.js';
import { EventNoteService } from '../../services/eventNoteService.js';
import { requireAdmin, requireEventAccess } from '../guards/auth.js';
import { CreateEventNoteInput, UpdateEventNoteInput } from '../validators/eventNote';

const eventNoteResolvers = {
  Query: {
    eventNote: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const eventNoteService = new EventNoteService(context.prisma);
      const note = await eventNoteService.getNote(id);

      await requireEventAccess(context, note.eventId);

      return note;
    },

    departmentNotes: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ) => {
      requireAdmin(context);

      const eventNoteService = new EventNoteService(context.prisma);
      const eventId = await eventNoteService.getDepartmentEventId(departmentId);
      await requireEventAccess(context, eventId);

      return eventNoteService.getDepartmentNotes(departmentId);
    },

    eventNotes: async (_parent: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const eventNoteService = new EventNoteService(context.prisma);
      return eventNoteService.getEventNotes(eventId);
    },
  },

  Mutation: {
    createEventNote: async (
      _parent: unknown,
      { input }: { input: CreateEventNoteInput },
      context: Context
    ) => {
      requireAdmin(context);

      const eventNoteService = new EventNoteService(context.prisma);
      const eventId = await eventNoteService.getDepartmentEventId(input.departmentId);
      await requireEventAccess(context, eventId);

      return eventNoteService.createNote(context.admin.id, input);
    },

    updateEventNote: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateEventNoteInput },
      context: Context
    ) => {
      requireAdmin(context);

      const eventNoteService = new EventNoteService(context.prisma);
      const eventId = await eventNoteService.getNoteEventId(id);
      await requireEventAccess(context, eventId);

      return eventNoteService.updateNote(id, input);
    },

    deleteEventNote: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);

      const eventNoteService = new EventNoteService(context.prisma);
      const eventId = await eventNoteService.getNoteEventId(id);
      await requireEventAccess(context, eventId);

      return eventNoteService.deleteNote(id);
    },
  },
};

export default eventNoteResolvers;

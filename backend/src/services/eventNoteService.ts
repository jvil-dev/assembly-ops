/**
 * Event Note Service
 *
 * Business logic for overseer coordination notes on events/departments.
 *
 * Methods:
 *   - createNote(adminId, input): Create a note for a department
 *   - updateNote(noteId, input): Update an existing note
 *   - deleteNote(noteId): Delete a note
 *   - getNote(noteId): Get note by ID
 *   - getDepartmentNotes(departmentId): Get all notes for a department
 *   - getEventNotes(eventId): Get all notes for an event
 *   - getNoteEventId(noteId): Get note's eventId for access control
 *   - getDepartmentEventId(departmentId): Get department's eventId for access control
 */
import { PrismaClient, EventNote, Prisma } from '@prisma/client';
import { NotFoundError, ValidationError } from '../utils/errors';
import {
  createEventNoteSchema,
  updateEventNoteSchema,
  CreateEventNoteInput,
  UpdateEventNoteInput,
} from '../graphql/validators/eventNote';

export class EventNoteService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Create a note for a department
   */
  async createNote(adminId: string, input: CreateEventNoteInput): Promise<EventNote> {
    const result = createEventNoteSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { departmentId, title, body } = result.data;

    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      select: { id: true, eventId: true },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    return this.prisma.eventNote.create({
      data: {
        title,
        body,
        eventId: department.eventId,
        departmentId,
        createdById: adminId,
      },
      include: {
        department: true,
        createdBy: true,
      },
    });
  }

  /**
   * Update a note
   */
  async updateNote(noteId: string, input: UpdateEventNoteInput): Promise<EventNote> {
    const result = updateEventNoteSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const note = await this.prisma.eventNote.findUnique({
      where: { id: noteId },
    });

    if (!note) {
      throw new NotFoundError('Event note');
    }

    return this.prisma.eventNote.update({
      where: { id: noteId },
      data: {
        title: result.data.title,
        body: result.data.body,
      },
      include: {
        department: true,
        createdBy: true,
      },
    });
  }

  /**
   * Delete a note
   */
  async deleteNote(noteId: string): Promise<boolean> {
    const note = await this.prisma.eventNote.findUnique({
      where: { id: noteId },
    });

    if (!note) {
      throw new NotFoundError('Event note');
    }

    await this.prisma.eventNote.delete({
      where: { id: noteId },
    });

    return true;
  }

  /**
   * Get note by ID
   * @throws NotFoundError if note does not exist
   */
  async getNote(
    noteId: string
  ): Promise<Prisma.EventNoteGetPayload<{ include: { department: true; createdBy: true } }>> {
    const note = await this.prisma.eventNote.findUnique({
      where: { id: noteId },
      include: {
        department: true,
        createdBy: true,
      },
    });

    if (!note) {
      throw new NotFoundError('Event note');
    }

    return note;
  }

  /**
   * Get all notes for a department
   */
  async getDepartmentNotes(departmentId: string) {
    return this.prisma.eventNote.findMany({
      where: { departmentId },
      include: {
        createdBy: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get all notes for an event (across all departments)
   */
  async getEventNotes(eventId: string) {
    return this.prisma.eventNote.findMany({
      where: {
        department: { eventId },
      },
      include: {
        department: true,
        createdBy: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get note's eventId for access control
   */
  async getNoteEventId(noteId: string): Promise<string> {
    const note = await this.prisma.eventNote.findUnique({
      where: { id: noteId },
      select: { eventId: true },
    });

    if (!note) {
      throw new NotFoundError('Event note');
    }

    return note.eventId;
  }

  /**
   * Get department's eventId for access control
   */
  async getDepartmentEventId(departmentId: string): Promise<string> {
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      select: { eventId: true },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    return department.eventId;
  }
}

/**
 * Post Service
 *
 * Business logic for managing posts within departments.
 * Posts are physical locations/positions where volunteers are assigned
 * (e.g., "Gate A", "Main Entrance", "Information Booth").
 *
 * Operations:
 *   - createPost: Create single post in a department
 *   - createPosts: Bulk create multiple posts in a department
 *   - updatePost: Update post details (name, description, location, capacity)
 *   - deletePost: Remove a post
 *   - getPost: Fetch single post with department/event info and assignment count
 *   - getDepartmentPosts: List all posts in a department
 *   - getEventPosts: List all posts across an event (grouped by department)
 *   - verifyPostAccess: Authorization check for admin access to a post
 *
 * Authorization:
 *   Posts inherit access from their parent department/event.
 *   verifyPostAccess checks EventAdmin relationship.
 *
 * Used by: Post resolvers
 */
import { PrismaClient, Post } from '@prisma/client';
import { NotFoundError, ValidationError, AuthorizationError } from '../utils/errors.js';
import {
  createPostSchema,
  createPostsSchema,
  updatePostSchema,
  CreatePostInput,
  CreatePostsInput,
  UpdatePostInput,
} from '../graphql/validators/post.js';

export class PostService {
  constructor(private prisma: PrismaClient) {}

  async createPost(departmentId: string, input: CreatePostInput): Promise<Post> {
    const result = createPostSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const validated = result.data;

    // Verify department exists
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    return this.prisma.post.create({
      data: {
        name: validated.name,
        description: validated.description,
        location: validated.location,
        capacity: validated.capacity,
        departmentId,
      },
    });
  }

  async createPosts(input: CreatePostsInput): Promise<Post[]> {
    const result = createPostsSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { departmentId, posts } = result.data;

    // Verify department exists
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    const createdPosts: Post[] = [];

    for (const postInput of posts) {
      const post = await this.prisma.post.create({
        data: {
          name: postInput.name,
          description: postInput.description,
          location: postInput.location,
          capacity: postInput.capacity,
          departmentId,
        },
      });
      createdPosts.push(post);
    }

    return createdPosts;
  }

  async updatePost(postId: string, input: UpdatePostInput): Promise<Post> {
    const result = updatePostSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const validated = result.data;

    const post = await this.prisma.post.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundError('Post');
    }

    return this.prisma.post.update({
      where: { id: postId },
      data: {
        name: validated.name,
        description: validated.description,
        location: validated.location,
        capacity: validated.capacity,
      },
    });
  }

  async deletePost(postId: string): Promise<boolean> {
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundError('Post');
    }

    await this.prisma.post.delete({
      where: { id: postId },
    });

    return true;
  }

  async getPost(postId: string) {
    return this.prisma.post.findUnique({
      where: { id: postId },
      include: {
        department: {
          include: {
            event: {
              include: { template: true },
            },
          },
        },
        _count: {
          select: { assignments: true },
        },
      },
    });
  }

  async getDepartmentPosts(departmentId: string) {
    return this.prisma.post.findMany({
      where: { departmentId },
      include: {
        _count: {
          select: { assignments: true },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  async getEventPosts(eventId: string) {
    return this.prisma.post.findMany({
      where: {
        department: {
          eventId,
        },
      },
      include: {
        department: true,
        _count: {
          select: { assignments: true },
        },
      },
      orderBy: [{ department: { name: 'asc' } }, { name: 'asc' }],
    });
  }

  /**
   * Verify admin has access to post's department
   */
  async verifyPostAccess(postId: string, adminId: string): Promise<string> {
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      include: {
        department: {
          include: {
            event: true,
          },
        },
      },
    });

    if (!post) {
      throw new NotFoundError('Post');
    }

    const eventAdmin = await this.prisma.eventAdmin.findUnique({
      where: {
        adminId_eventId: {
          adminId,
          eventId: post.department.eventId,
        },
      },
    });

    if (!eventAdmin) {
      throw new AuthorizationError('You do not have access to this post');
    }

    return post.department.eventId;
  }
}

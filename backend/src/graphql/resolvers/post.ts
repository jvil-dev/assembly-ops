/**
 * Post Resolvers
 *
 * GraphQL resolvers for post operations.
 * Posts are physical locations/positions within a department where volunteers
 * are assigned (e.g., "Gate A", "Main Entrance", "Information Booth").
 *
 * Queries:
 *   - post(id): Get single post by ID
 *   - posts(departmentId): List all posts in a department
 *   - eventPosts(eventId): List all posts across an event (grouped by department)
 *
 * Mutations:
 *   - createPost(departmentId, input): Create single post in a department
 *   - createPosts(input): Bulk create multiple posts
 *   - updatePost(id, input): Update post details (name, description, location)
 *   - deletePost(id): Remove a post
 *
 * Field Resolvers:
 *   - assignmentCount: Number of volunteer assignments at this post
 *
 * Authorization:
 *   All operations require admin authentication.
 *   Access verified through department's parent event.
 */
import { Context } from '../context.js';
import { PostService } from '../../services/postService.js';
import { requireAdmin, requireEventAccess, requireDeptAccess, tryRequireAdmin } from '../guards/auth.js';
import { Post } from '@prisma/client';
import { CreatePostInput, CreatePostsInput, UpdatePostInput } from '../validators/post.js';

/**
 * Check overseer OR assistant overseer access for a department.
 * Tries requireAdmin + requireEventAccess first, falls back to requireDeptAccess.
 */
async function requirePostDeptAccess(context: Context, departmentId: string) {
  if (tryRequireAdmin(context)) {
    const department = await context.prisma.department.findUnique({
      where: { id: departmentId },
      select: { eventId: true },
    });
    if (department) {
      await requireEventAccess(context, department.eventId);
      return;
    }
  }
  await requireDeptAccess(context, departmentId);
}

const postResolvers = {
  Query: {
    post: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      const postService = new PostService(context.prisma);

      // Get post's department to check access
      const post = await context.prisma.post.findUnique({
        where: { id },
        select: { departmentId: true },
      });
      if (post) {
        await requirePostDeptAccess(context, post.departmentId);
      }

      return postService.getPost(id);
    },

    posts: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ) => {
      await requirePostDeptAccess(context, departmentId);

      const postService = new PostService(context.prisma);
      return postService.getDepartmentPosts(departmentId);
    },

    eventPosts: async (_parent: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const postService = new PostService(context.prisma);
      return postService.getEventPosts(eventId);
    },
  },

  Mutation: {
    createPost: async (
      _parent: unknown,
      { departmentId, input }: { departmentId: string; input: CreatePostInput },
      context: Context
    ) => {
      await requirePostDeptAccess(context, departmentId);

      const postService = new PostService(context.prisma);
      return postService.createPost(departmentId, input);
    },

    createPosts: async (
      _parent: unknown,
      { input }: { input: CreatePostsInput },
      context: Context
    ) => {
      await requirePostDeptAccess(context, input.departmentId);

      const postService = new PostService(context.prisma);
      return postService.createPosts(input);
    },

    updatePost: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdatePostInput },
      context: Context
    ) => {
      const post = await context.prisma.post.findUnique({
        where: { id },
        select: { departmentId: true },
      });
      if (post) {
        await requirePostDeptAccess(context, post.departmentId);
      }

      const postService = new PostService(context.prisma);
      return postService.updatePost(id, input);
    },

    deletePost: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      const post = await context.prisma.post.findUnique({
        where: { id },
        select: { departmentId: true },
      });
      if (post) {
        await requirePostDeptAccess(context, post.departmentId);
      }

      const postService = new PostService(context.prisma);
      return postService.deletePost(id);
    },
  },

  Post: {
    assignmentCount: (post: Post & { _count?: { assignments: number } }) => {
      return post._count?.assignments ?? 0;
    },
  },
};

export default postResolvers;

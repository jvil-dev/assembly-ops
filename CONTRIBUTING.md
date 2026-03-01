# Contributing to AssemblyOps

Thank you for your interest in contributing to AssemblyOps! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project follows Christian principles and serves a faith-based community. We expect all contributors to:

- Be respectful and kind in all interactions
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards others
- Accept constructive criticism gracefully

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Node.js** 20 or higher
- **npm** (comes with Node.js)
- **PostgreSQL** 16 or higher (or Docker)
- **Git** for version control
- **Xcode** 15+ (for iOS development)

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/assembly-ops.git
   cd assembly-ops
   ```

3. **Set up the backend**:
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Edit .env with your local database credentials
   npm run prisma:generate
   npm run prisma:migrate
   npm run prisma:seed
   npm run dev
   ```

4. **Set up the iOS app** (optional):
   ```bash
   cd ../ios/JW_AssemblyOps
   # Open AssemblyOps.xcodeproj in Xcode
   # Update the GraphQL endpoint in the code if needed
   # Build and run in simulator
   ```

## Development Workflow

### Branching Strategy

- `main` - Production-ready code
- `development` - Latest development work
- Feature branches: `feature/your-feature-name`
- Bug fixes: `fix/issue-description`

### Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards

3. **Write tests** for new functionality

4. **Run tests and linters**:
   ```bash
   npm run lint
   npm run format
   npm test
   npm run build
   ```

5. **Commit your changes** with clear, descriptive messages:
   ```bash
   git commit -m "feat: Add volunteer assignment bulk update"
   ```

## Coding Standards

### TypeScript/JavaScript

- Use **TypeScript** for all backend code
- Follow the existing code style (enforced by ESLint and Prettier)
- Use **meaningful variable names** that describe purpose
- Add **JSDoc comments** for functions and complex logic
- Avoid `any` types - use proper typing
- Keep functions small and focused (single responsibility)

### GraphQL

- Use descriptive names for queries and mutations
- Document arguments with descriptions
- Include proper error handling in resolvers
- Use Zod validators for all inputs

### Database

- Always use Prisma migrations for schema changes
- Never commit direct database changes
- Include proper indexes for query performance
- Use transactions for multi-step operations

### Swift (iOS)

- Follow Swift naming conventions
- Use SwiftUI for all UI components
- Document public APIs
- Keep view models separate from views

## Testing

### Backend Tests

- Write integration tests for GraphQL resolvers
- Use Vitest for testing
- Test both success and error cases
- Mock external dependencies

```bash
# Run all tests
npm test

# Run specific test file
npm test -- --testPathPattern="auth"

# Watch mode
npm run test:watch
```

### Test Coverage

- Aim for at least 70% code coverage
- Critical paths (authentication, authorization) require 90%+ coverage
- Add tests when fixing bugs

## Submitting Changes

### Pull Request Process

1. **Update your branch** with the latest from `development`:
   ```bash
   git checkout development
   git pull origin development
   git checkout your-branch
   git rebase development
   ```

2. **Push to your fork**:
   ```bash
   git push origin your-branch
   ```

3. **Create a Pull Request** on GitHub:
   - Use a clear, descriptive title
   - Reference any related issues (e.g., "Fixes #123")
   - Describe what changes were made and why
   - Include screenshots for UI changes
   - List any breaking changes

4. **Address review feedback**:
   - Respond to comments
   - Make requested changes
   - Push updates to the same branch

5. **Wait for approval** from maintainers

### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(backend): Add bulk volunteer assignment endpoint
fix(ios): Resolve crash on event join request
docs: Update README with Docker setup instructions
```

## Reporting Issues

### Bug Reports

When reporting bugs, include:

1. **Description**: Clear summary of the issue
2. **Steps to Reproduce**: Exact steps to trigger the bug
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**:
   - OS and version
   - Node.js version
   - Browser (if applicable)
   - iOS version (if applicable)
6. **Screenshots**: If relevant
7. **Logs**: Error messages or console output

### Feature Requests

For new features, describe:

1. **Problem**: What problem does this solve?
2. **Proposed Solution**: How should it work?
3. **Alternatives**: Other approaches considered
4. **Use Case**: Real-world scenario where this helps
5. **Priority**: How critical is this?

### Security Issues

**Do not** report security vulnerabilities as public issues. Instead:
- See [SECURITY.md](./SECURITY.md) for reporting instructions
- Contact maintainers privately
- Allow time for a fix before public disclosure

## Development Tips

### Useful Commands

```bash
# Backend
npm run dev              # Start dev server with hot reload
npm run build            # Build for production
npm run lint:fix         # Auto-fix linting issues
npm run prisma:migrate   # Run database migrations
npm run prisma:seed      # Seed database with test data

# Database
npm run prisma:generate  # Regenerate Prisma client
npm run prisma:push      # Push schema changes (dev only)
```

### Debugging

- Use the built-in debugger in VS Code or your IDE
- For backend: Set breakpoints in TypeScript files
- For GraphQL: Use Apollo Studio Sandbox at http://localhost:4000/graphql
- Check logs with `docker compose logs -f` if using Docker

### Common Issues

**Prisma errors**: Run `npm run prisma:generate` after schema changes

**Type errors**: Ensure you've regenerated Prisma client and restarted TypeScript server

**Port conflicts**: Change PORT in .env if 4000 is in use

## Resources

- [GraphQL Documentation](https://graphql.org/learn/)
- [Prisma Documentation](https://www.prisma.io/docs/)
- [Apollo Server Documentation](https://www.apollographql.com/docs/apollo-server/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

## Questions?

If you have questions about contributing:

1. Check existing documentation
2. Search closed issues
3. Ask in the GitHub Discussions
4. Contact the maintainers

Thank you for contributing to AssemblyOps! 🙏

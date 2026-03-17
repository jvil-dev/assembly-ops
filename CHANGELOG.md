# Changelog

All notable changes to AssemblyOps will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- SECURITY.md with vulnerability reporting guidelines
- Structured logging utility for consistent application logs
- Comprehensive .env.example file with all required environment variables
- Production readiness improvements

### Changed

- Upgraded Apollo Server from 5.2.0 to 5.4.0+ (fixes high-severity DoS vulnerability)
- Consolidated server setup - removed redundant app.ts file
- Improved TypeScript type safety - removed all `any` type usage

### Fixed

- Fixed TypeScript type errors in authentication and volunteer services
- Fixed health check endpoint in test setup

## [1.0.0] - Phase 7: TestFlight & Beta Prep

### Overview

AssemblyOps is a volunteer scheduling and management system for Jehovah's Witnesses assembly and convention committees. This release represents completion of core features and preparation for beta testing.

### Added

#### Backend

- GraphQL API with Apollo Server 4
- PostgreSQL database with Prisma ORM
- JWT-based authentication (access + refresh tokens)
- OAuth support (Google and Apple Sign In)
- Role-based access control (App Admin, Department Overseer, Volunteer)
- Rate limiting on authentication endpoints
- Security headers with Helmet.js
- Docker support with multi-stage builds
- Health check endpoint for load balancer
- PII encryption for sensitive data
- 12 convention departments with specialized features

#### Features

- Event management from templates
- Department and post creation
- Session scheduling across multiple days
- Volunteer assignment with capacity management
- Real-time attendance tracking
- Check-in/check-out system
- Assignment acceptance workflow with deadlines
- Captain role assignment for posts
- Area grouping for better organization
- Message system (event-wide, department-specific, post-specific)
- Event join request system for volunteers
- Equipment management for Audio/Video department
- Safety incident reporting for Attendant department
- Walk-through tracking for event preparation

#### iOS App

- SwiftUI-based native iOS application
- Apollo iOS GraphQL client
- Volunteer dashboard with assignments
- Check-in functionality
- Assignment acceptance/decline
- Message viewing
- Post and session details
- QR code support

#### DevOps

- GitHub Actions CI/CD pipeline
- Automated testing and linting
- Docker image building
- Google Cloud Run deployment
- Cloud SQL managed PostgreSQL

### Security

- All API endpoints require authentication
- Password hashing with bcrypt
- JWT token rotation with refresh tokens
- CORS protection with allowlist
- Rate limiting to prevent abuse
- GraphQL query depth limiting
- Input validation with Zod schemas
- Non-root user in Docker containers
- Secrets managed through environment variables

### Documentation

- README files for main project and backend
- Inline code documentation
- API examples in backend README
- Architecture diagrams

---

## Release Naming Convention

- **Major version (X.0.0)**: Significant milestone or breaking changes
- **Minor version (1.X.0)**: New features, backwards compatible
- **Patch version (1.0.X)**: Bug fixes, security patches

## Support

For questions or issues, please:

1. Check existing GitHub issues
2. Review the documentation
3. Contact the maintainers

[Unreleased]: https://github.com/jvil-dev/assembly-ops/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/jvil-dev/assembly-ops/releases/tag/v1.0.0

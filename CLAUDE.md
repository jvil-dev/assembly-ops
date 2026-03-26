# AssemblyOps

Event management platform for JW assemblies and conventions.

## Sub-Projects

| Directory  | Description                                             | CLAUDE.md         |
| ---------- | ------------------------------------------------------- | ----------------- |
| `backend/` | Node.js GraphQL API (Express + Apollo + Prisma)         | `backend/CLAUDE.md` |
| `flutter/` | Flutter cross-platform app (iOS, Android, web, desktop) | `flutter/CLAUDE.md` |
| `admin/`   | Next.js admin portal (React + Tailwind + Apollo Client) | `admin/CLAUDE.md`   |

> **Note:** The SwiftUI iOS app (`ios/`) is archived at tag `beta-2026-03-23` and gitignored. Flutter replaces it.

## V1 Architecture

- **app.assemblyops.org** — Flutter Web (same codebase as mobile)
- **assemblyops.org** — Next.js marketing/product page
- **admin.assemblyops.org** — Next.js admin portal (existing `admin/`)
- **Flutter app** — iOS, Android, macOS, iPad from single codebase; screen-size responsive (full management on large screens, day-of ops on phone)

## Commit Style Examples

- `feat(backend): add deleteAccount mutation for user self-deletion`
- `fix(backend): handle nullable submittedById in attendance resolver`
- `refactor(ios): replace delete volunteer with remove from department`
- `test: add unit and integration tests for account deletion and department cleanup`
- `chore: remove AWS service, schema, and resolver files`

## Git Workflow (Multi-Machine)

Development happens across two machines. Git is the sync mechanism — never use iCloud/Dropbox to sync repos.

### Switching machines

1. **Before leaving a machine:** `git add -A && git commit -m "wip: ..." && git push`
2. **When starting on the other machine:** `git pull`

### WIP commits

- Prefix with `wip:` — e.g., `wip: implementing attendance resolver`
- WIP commits are disposable; clean them up before merging to `main`

### Cleaning up before merge

- **Single WIP commit:** `git commit --amend -m "feat(backend): ..."` then `git push --force-with-lease`
- **Multiple WIP commits:** `git rebase -i HEAD~N`, squash into one clean commit, then `git push --force-with-lease`

## GitHub Projects Workflow

Issues are tracked on the **AssemblyOps Full-Release** GitHub Project board.

### Branching

- One branch per issue: `feat/issue-42-volunteer-checkin`
- PRs reference issues: `Closes #42`

### Milestones

M1: Users & RBAC → M2: Departments → M3: Modes → M4: Pricing & Stripe → M5: Polish & Launch

## Claude's Role

Claude does NOT write implementation code for this project. The developer writes all code.

**Claude does:**
- Manage GitHub Project board (issues, labels, milestones, cards)
- Break down epics into well-specified issues with acceptance criteria
- Architecture and design guidance
- Code review (feedback, not rewrites)
- Debugging guidance (questions and direction, not fixes)
- Spec writing and product planning

**Claude does not:**
- Write, edit, or generate source code
- Create implementation files or boilerplate
- Make code changes of any kind

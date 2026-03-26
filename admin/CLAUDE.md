# Admin Portal — CLAUDE.md

Next.js admin dashboard for AssemblyOps (`admin.assemblyops.org`). See root `CLAUDE.md` for workflow rules and project overview.

## Commands

```bash
# From admin/
npm run dev    # Dev server (port 3000, Turbopack)
npm run build  # Production build
npm run start  # Serve production build
```

## Tech Stack

- Next.js 16.1 (App Router, Turbopack)
- React 19.2, TypeScript 5
- Tailwind CSS 4 (via @tailwindcss/postcss, no tailwind.config — uses CSS vars)
- Apollo Client 4.1 for GraphQL
- Recharts 3.7 (area, line, bar charts)
- date-fns 4.1 for date formatting
- Font: DM Sans (400, 500, 600, 700)

## Architecture

```
src/
├── app/                    # Next.js App Router pages
│   ├── layout.tsx          # Root layout (DM Sans font, ApolloWrapper)
│   ├── page.tsx            # Overview dashboard
│   ├── login/page.tsx      # Email/password login
│   ├── events/page.tsx     # Events list (paginated, searchable)
│   ├── users/page.tsx      # Users directory (paginated, searchable)
│   ├── costs/page.tsx      # GCP cost breakdown
│   ├── metrics/page.tsx    # User growth charts, event statistics
│   ├── infra/page.tsx      # Infrastructure monitoring (Cloud Run, DB)
│   ├── logs/page.tsx       # CloudWatch log viewer
│   ├── import/page.tsx     # CSV bulk import tool
│   └── globals.css         # Design tokens, CSS vars, animations
├── components/
│   ├── DashboardShell.tsx  # Auth + Sidebar + Toast wrapper (wraps all non-login pages)
│   ├── AuthGuard.tsx       # Route protection (checks token expiry, redirects to /login)
│   ├── Sidebar.tsx         # Navigation: Monitoring | App Data | Tools sections
│   ├── ApolloWrapper.tsx   # GraphQL provider
│   ├── DataTable.tsx       # Generic typed table with CSV export
│   ├── Chart.tsx           # Recharts wrapper (area/line/bar)
│   ├── StatCard.tsx        # Metric card with status indicator
│   ├── Skeleton.tsx        # Loading placeholders (4 variants)
│   ├── ErrorCard.tsx       # Error state with retry
│   ├── Toast.tsx           # Context-based notifications (4s auto-dismiss)
│   └── LogViewer.tsx       # Terminal-style log display
├── hooks/
│   └── useAuth.ts          # Auth state management, login/logout
└── lib/
    ├── apollo.ts           # Apollo Client setup with auth link
    ├── auth.ts             # localStorage token/user management
    └── queries.ts          # ALL GraphQL operations (queries + mutations)
```

### Component Hierarchy

```
layout.tsx (ApolloWrapper)
  ├── /login (standalone)
  └── All other pages (DashboardShell)
      ├── AuthGuard
      ├── ToastProvider
      ├── Sidebar
      └── <Page Content>
```

## Auth

- **Access**: Only users with `isAppAdmin: true` can log in
- **Storage**: JWT in localStorage (`admin_token`, `admin_user`)
- **Auth link**: `lib/apollo.ts` attaches `Authorization: Bearer <token>` to every request
- **Route protection**: `AuthGuard` checks token expiry on mount, redirects to `/login` if expired
- **Login**: `LOGIN_USER` mutation → `storeAuth()` → redirect to dashboard

## Styling

- **CSS custom properties** in `globals.css` (mirrors iOS AppTheme design tokens)
- Primary: `#1a3d5d`, Tint: `#2c5282`
- Warm background gradient (`--bg-top` → `--bg-bottom`)
- Card backgrounds: `#ffffff`, `#faf8f6` (secondary)
- Status colors: ok (`#22c55e`), warn (`#f97316`), error (`#ef4444`)
- Border radii: 24/16/14/12/8px matching iOS AppTheme
- Dual-layer card shadows
- Extensive inline `style={{}}` props with CSS vars (not utility classes for most styling)

## Data Fetching

- **All operations** in `lib/queries.ts` (single file)
- **Fetch policy**: `network-only` (no cache reuse)
- **Polling**: 60s (analytics), 30s (Cloud Run service status)
- **Pagination**: 25 items per page
- **Search**: 300ms debounce (Users page)

## Pages

| Route      | Purpose        | Key Features                                                    |
| ---------- | -------------- | --------------------------------------------------------------- |
| `/`        | Overview       | Platform health, user counts, Cloud Run services, costs; auto-polling |
| `/login`   | Authentication | Email/password; admin-only access                               |
| `/events`  | Events list    | Paginated, type badges, dates, venue, counts                    |
| `/users`   | User directory | Paginated, searchable, role badges, CSV export                  |
| `/metrics` | Analytics      | User growth chart (period selector), event stats table          |
| `/costs`   | GCP costs      | Cost by service, time-series chart, date range filter           |
| `/infra`   | Infrastructure | Cloud Run metrics, CPU/memory charts, Cloud SQL stats           |
| `/logs`    | Log viewer     | Cloud Logging events, filter expressions, terminal styling      |
| `/import`  | Bulk import    | CSV upload for congregations/events/volunteers; error reporting |

## Environment

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:4000/graphql
```

Single env var — must match the backend GraphQL endpoint.

## Gotchas

- **No tailwind.config**: Tailwind v4 uses `@import "tailwindcss"` in `globals.css` + CSS custom properties
- **Inline styles dominant**: Most styling uses `style={{}}` props with CSS vars, not Tailwind utility classes
- **Single queries file**: All GraphQL operations live in `lib/queries.ts` — don't create per-feature query files
- **Auth is localStorage-based**: No cookies, no server-side sessions — purely client-side JWT

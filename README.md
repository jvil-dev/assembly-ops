# AssemblyOps

A volunteer scheduling and management system for assembly attendant teams.

AssemblyOps enables attendant overseers to create schedules, assign posts, track check-ins, and communicate with volunteers during assemblies. Built with offline-first architecture for halls/venues with limited connectivity.

## Project Structure

```
assemblyops/
├── backend/      # Node.js/Express API
├── ios-app/      # iOS app (Swift) - Coming Soon
├── android-app/  # Android app (Kotlin) - Coming Soon
└── docs/         # Documentation
```

## Tech Stack

| Layer        | Technology                           |
| ------------ | ------------------------------------ |
| **Backend**  | Node.js, Express, TypeScript         |
| **Database** | PostgreSQL (Supabase), Prisma 7 ORM  |
| **Auth**     | JWT (dual system: admin + volunteer) |
| **iOS**      | Swift, SwiftUI, Core Data            |
| **Android**  | Kotlin, Room                         |

## Features

- **Dual Authentication** — Admins use email/password; volunteers use generated credentials
- **Event Management** — Create circuit assemblies and regional conventions
- **Custom Roles** — Define role hierarchies per event (Overseer, Captain, Attendant, etc.)
- **Session Scheduling** — Morning/afternoon sessions with volunteer availability tracking
- **Volunteer Directory** — Search, filter, and manage volunteer teams
- **Offline-First** — Core features work without internet; syncs when connected

## Documentation

- [Backend API Documentation](./backend/README.md)

## Author

**Jorge Villeda** — [GitHub](https://github.com/jvil-dev)

## License

ISC

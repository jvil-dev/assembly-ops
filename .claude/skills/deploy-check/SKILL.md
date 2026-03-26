---
name: deploy-check
description: Pre-deployment checklist for AssemblyOps. Covers Cloud Build, database migrations, environment variables, and smoke tests.
disable-model-invocation: true
---

# AssemblyOps Pre-Deploy Checklist

Run through this checklist before or after deploying to production.

## Infrastructure

- **Cloud Build** (`cloudbuild.yaml`): Triggered on push to `main`. Builds Docker image → pushes to Artifact Registry → runs Prisma migrations via Cloud SQL Auth Proxy → deploys to Cloud Run.
- **Database migrations** run automatically in Cloud Build before deploy. The `DIRECT_URL` secret in GCP Secret Manager provides a TCP connection string (`localhost:5433`) used by the Cloud SQL Auth Proxy during build.
- **Cloud Run** connects to Cloud SQL via Unix socket (`?host=/cloudsql/...`). Prisma migrate does NOT support Unix sockets — that's why migrations run in Cloud Build, not at container startup.
- **`docker-entrypoint.sh`** still attempts `prisma migrate deploy` on startup as a fallback, but it will typically find no pending migrations since Cloud Build already applied them.

## Checklist

### Before Deploy
- [ ] All tests pass (`npm test` in backend)
- [ ] Lint passes (`npm run lint`)
- [ ] Build succeeds (`npm run build`)
- [ ] No pending migration conflicts
- [ ] PR approved and merged to `main`

### After Deploy
- [ ] Verify Prisma migrations ran successfully in Cloud Build logs
- [ ] Verify new tables/columns exist in production database
- [ ] Set any new environment variables on Cloud Run:
  - `ALLOWED_ORIGINS` — must include protocol (e.g., `https://admin.assemblyops.org`)
  - `SMTP_USER` / `SMTP_PASS` — for Gmail SMTP (falls back to console logging if missing)
  - Any new secrets added to GCP Secret Manager
- [ ] Smoke test: key user-facing flows work
- [ ] Check Cloud Run logs for errors
- [ ] Verify health endpoint responds: `GET /health`

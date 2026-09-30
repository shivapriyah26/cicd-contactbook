# CI/CD Workflow Explanation

**Goal:** every push to GitHub is automatically tested, built into Docker images, security-scanned with Trivy, deployed with Docker Compose, health-checked, and rolled back if something is wrong.

## Flow
1. **Checkout** - Jenkins pulls the latest code from GitHub (polls every 5 minutes).
2. **Build & Test** - the `test` stage of `backend/Dockerfile` installs dependencies and runs `pytest`. If any test fails, the pipeline stops.
3. **Build Docker Images** - `docker compose build` builds the backend (FastAPI) and frontend (Nginx) images, tagged with the Jenkins build number (e.g. `contactbook-backend:7`).
4. **Trivy Security Scan** - Trivy scans both images for HIGH/CRITICAL vulnerabilities (fixable ones). Reports are saved in `reports/` and archived in Jenkins. Any finding fails the pipeline, so vulnerable images are never deployed.
5. **Deploy** - `docker compose up -d` starts MySQL, backend and frontend. Passwords are injected from Jenkins Credentials (not stored in Git).
6. **Health Check** - Docker health checks (MySQL, backend, frontend) plus a script that calls `/api/health` until it answers OK. On success the build number is saved as the "last known good" release.
7. **Cleanup** - old image versions are removed (newest 5 are kept for rollback) and dangling layers are pruned.

## Persistent storage
MySQL data lives in the named volume `mysql_data`. Containers and images are replaced on every deploy, but the volume (and your contacts) survive. Never run `docker compose down -v` in production.

## Rollback
- **Automatic:** if Deploy or Health Check fails, the `post { failure }` block redeploys the last known good version.
- **Manual:** run the job with `ROLLBACK_TO=<older build number>`; Jenkins redeploys that already-built image and re-checks health.

## Security practices
Secrets in Jenkins Credentials, multi-stage build (no test tools in the runtime image), non-root user in the backend container, Trivy gate before deployment, only port 8081 (app) published, database not exposed to the host.

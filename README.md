# Contact Book - Jenkins + Docker + Docker Compose CI/CD

See `docs/CICD_WORKFLOW.md` for the pipeline explanation.

## Run locally (no Jenkins)
```bash
cp .env.example .env
docker compose up -d --build
curl http://localhost:8081/api/health
```

## Project layout
| Path | Purpose |
|---|---|
| `Jenkinsfile` | The CI/CD pipeline |
| `docker-compose.yml` | MySQL + backend + frontend, health checks, volume |
| `backend/Dockerfile` | Multi-stage: test -> runtime |
| `frontend/Dockerfile` | Nginx serving the UI and proxying `/api` |
| `scripts/` | Trivy scan, deploy, health check, rollback, image cleanup |
| `reports/` | Put your Trivy reports here for submission |
| `screenshots/` | Put your deployment screenshots here |

## Submission checklist
- [ ] Jenkinsfile, docker-compose.yml, both Dockerfiles (in the repo)
- [ ] Trivy report(s) in `reports/`
- [ ] Screenshots in `screenshots/`
- [ ] `docs/CICD_WORKFLOW.md`
- [ ] GitHub repo link

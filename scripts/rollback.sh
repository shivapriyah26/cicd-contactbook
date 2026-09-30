#!/usr/bin/env bash
# Usage: rollback.sh <image_tag>   (re-deploys an older, already-built version)
set -euo pipefail
TARGET="${1:?Usage: rollback.sh <image_tag>}"
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-contactbook}"
APP_URL="${APP_URL:-http://localhost:8081}"
STATE_DIR="${STATE_DIR:-$HOME/contactbook-state}"

for repo in contactbook-backend contactbook-frontend; do
  if ! docker image inspect "${repo}:${TARGET}" > /dev/null 2>&1; then
    echo "ERROR: image ${repo}:${TARGET} not found on this server. Available:"
    docker images "${repo}" --format '  {{.Repository}}:{{.Tag}}'
    exit 1
  fi
done

echo ">>> Rolling back to version ${TARGET}"
export IMAGE_TAG="${TARGET}"
docker compose up -d --no-build
bash "$(dirname "$0")/health_check.sh" "${APP_URL}/api/health"

mkdir -p "${STATE_DIR}"
echo "${TARGET}" > "${STATE_DIR}/current_tag"
echo ">>> Rollback to ${TARGET} complete"

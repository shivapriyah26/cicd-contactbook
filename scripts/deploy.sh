#!/usr/bin/env bash
# Starts (or updates) the stack using the images tagged with IMAGE_TAG.
set -euo pipefail
: "${IMAGE_TAG:?IMAGE_TAG must be set}"
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-contactbook}"

echo ">>> Deploying version ${IMAGE_TAG}"
docker compose config -q                       # validate the compose file
docker compose up -d --no-build --remove-orphans
docker compose ps

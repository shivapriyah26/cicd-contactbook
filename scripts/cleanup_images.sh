#!/usr/bin/env bash
# Keeps the newest KEEP_IMAGES tagged versions (for rollback); removes older ones.
set -uo pipefail
KEEP="${KEEP_IMAGES:-5}"

for repo in contactbook-backend contactbook-frontend; do
  { docker images "${repo}" --format '{{.Tag}}' | grep -E '^[0-9]+$' || true; } \
    | sort -rn | tail -n +"$((KEEP + 1))" \
    | while read -r tag; do
        echo "Removing old image ${repo}:${tag}"
        docker rmi "${repo}:${tag}" || true
      done
done

docker image prune -f      # remove dangling (untagged) layers
echo "Images kept:"
docker images --filter "reference=contactbook-*" --format '  {{.Repository}}:{{.Tag}}  ({{.Size}})'

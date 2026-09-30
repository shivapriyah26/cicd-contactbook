#!/usr/bin/env bash
# Usage: health_check.sh <url> [retries] [sleep_seconds]
set -uo pipefail
URL="${1:?Usage: health_check.sh <url> [retries] [sleep_seconds]}"
RETRIES="${2:-20}"
SLEEP="${3:-5}"

for i in $(seq 1 "${RETRIES}"); do
  if curl -fsS "${URL}" > /tmp/health_response.json 2>/dev/null; then
    echo "HEALTHY (attempt ${i}): $(cat /tmp/health_response.json)"
    exit 0
  fi
  echo "Attempt ${i}/${RETRIES}: not healthy yet, waiting ${SLEEP}s..."
  sleep "${SLEEP}"
done
echo "UNHEALTHY: ${URL} did not become healthy"
exit 1

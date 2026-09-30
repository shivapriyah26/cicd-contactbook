#!/usr/bin/env bash
# Scans both application images with Trivy and saves a report per image.
# Exit code 1 (pipeline fails) if fixable HIGH/CRITICAL vulnerabilities exist.
set -uo pipefail
: "${IMAGE_TAG:?IMAGE_TAG must be set}"
SEVERITY="${TRIVY_SEVERITY:-HIGH,CRITICAL}"
mkdir -p reports
overall=0

for name in backend frontend; do
  IMAGE="contactbook-${name}:${IMAGE_TAG}"
  echo "=== Trivy scan: ${IMAGE} (severity: ${SEVERITY}) ==="
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v trivy-cache:/root/.cache/ \
    aquasec/trivy:latest image \
      --no-progress --severity "${SEVERITY}" --ignore-unfixed --exit-code 1 \
      "${IMAGE}" | tee "reports/trivy-${name}-${IMAGE_TAG}.txt"
  rc=${PIPESTATUS[0]}
  if [ "${rc}" -ne 0 ]; then
    echo "!!! ${IMAGE}: vulnerabilities at or above ${SEVERITY} found"
    overall=1
  fi
done
exit "${overall}"

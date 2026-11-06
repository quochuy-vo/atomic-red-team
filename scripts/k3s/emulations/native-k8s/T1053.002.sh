#!/usr/bin/env bash
# T1053.002: Scheduled Task/Job: At in a Pod
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1053.002: Scheduled Task/Job (At)"

POD_NAME="t1053-at-pod"

kubectl delete pod "${POD_NAME}" -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true

log_telemetry "T1053.002" "${POD_NAME}" "schedule job via at in pod"

log_info "Scheduling an 'at' job inside an ephemeral pod..."
OUTPUT="$(kubectl run "${POD_NAME}" -n "${TARGET_NAMESPACE}" \
  --image=ubuntu:22.04 --restart=Never --attach --rm -i \
  -- bash -c "apt-get update -qq >/dev/null && apt-get install -y -qq at >/dev/null && echo 'echo atomic' | at now + 1 minute 2>&1" 2>/dev/null || true)"

echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -qiE "job|warning|commands will be executed"; then
    log_success "T1053.002 emulation succeeded ('at' job scheduled)."
else
    log_error "T1053.002 emulation failed: Could not schedule 'at' job."
    exit 1
fi

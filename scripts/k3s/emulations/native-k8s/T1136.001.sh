#!/usr/bin/env bash
# T1136.001: Create Account - Local Account in a Pod
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1136.001: Create Local Account"

POD_NAME="t1136-adduser-pod"
TEST_USER="artuser101"

kubectl delete pod "${POD_NAME}" -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true

log_telemetry "T1136.001" "${POD_NAME}" "adduser -D ${TEST_USER} in pod"

log_info "Running pod to create local user account '${TEST_USER}'..."
OUTPUT="$(kubectl run "${POD_NAME}" -n "${TARGET_NAMESPACE}" \
  --image=alpine:latest --restart=Never --attach --rm -i \
  -- sh -c "adduser -D ${TEST_USER} && id ${TEST_USER}" 2>/dev/null || true)"

echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -q "uid="; then
    log_success "T1136.001 emulation succeeded (User account created in pod)."
else
    log_error "T1136.001 emulation failed: User account was not created."
    exit 1
fi

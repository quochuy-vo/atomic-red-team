#!/usr/bin/env bash
# T1046: Network Service Discovery in Pod
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1046: Network Service Discovery"

TARGET_HOST="kubernetes.default.svc"
TARGET_PORT="443"

log_telemetry "T1046" "${RUNNER_POD_NAME}" "probe tcp port ${TARGET_HOST}:${TARGET_PORT}"

log_info "Probing cluster internal API service '${TARGET_HOST}:${TARGET_PORT}' from '${RUNNER_POD_NAME}'..."
OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "timeout 2 bash -c '</dev/tcp/${TARGET_HOST}/${TARGET_PORT}' && echo 'PORT_OPEN' || echo 'PORT_CLOSED'")"

echo "Probe result: ${OUTPUT}"

if [ "${OUTPUT}" == "PORT_OPEN" ]; then
    log_success "T1046 emulation succeeded (Service port discovery confirmed)."
else
    log_error "T1046 emulation failed: Unable to connect to cluster service."
    exit 1
fi

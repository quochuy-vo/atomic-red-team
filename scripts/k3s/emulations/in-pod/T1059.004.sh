#!/usr/bin/env bash
# T1059.004: Command and Scripting Interpreter - Unix Shell
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1059.004: Unix Shell Living-off-the-Land"

log_telemetry "T1059.004" "${RUNNER_POD_NAME}" "awk shell spawn system(/bin/sh)"

log_info "Spawning shell via awk command inside '${RUNNER_POD_NAME}'..."
OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- awk 'BEGIN {system("id")}')"
echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -q "uid="; then
    log_success "T1059.004 emulation succeeded (Subshell spawned via awk)."
else
    log_error "T1059.004 emulation failed: Could not spawn subshell."
    exit 1
fi

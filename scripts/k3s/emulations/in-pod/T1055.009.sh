#!/usr/bin/env bash
# T1055.009: Process Injection - Proc Memory Overwrite
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1055.009: Proc Memory Injection"

log_telemetry "T1055.009" "${RUNNER_POD_NAME}" "write to /proc/\$PID/mem"

log_info "Executing child memory access emulation inside '${RUNNER_POD_NAME}'..."
OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  'sleep 30 & PID=$!; head -c 8 /proc/$PID/mem 2>/dev/null && echo "PROC_MEM_READ" || echo "PROC_MEM_BLOCKED"; kill -9 $PID >/dev/null 2>&1 || true')"

echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -qE "PROC_MEM_READ|PROC_MEM_BLOCKED"; then
    log_success "T1055.009 emulation succeeded (Exercised /proc/<pid>/mem access syscall path)."
else
    log_error "T1055.009 emulation failed: Target process manipulation error."
    exit 1
fi

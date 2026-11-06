#!/usr/bin/env bash
# T1070.006: Indicator Removal - Timestomp in Pod
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1070.006: Timestomp"

TEST_FILE="/tmp/t1070_timestomp_target"

log_telemetry "T1070.006" "${RUNNER_POD_NAME}" "utimensat touch -t 1970 on ${TEST_FILE}"

log_info "Modifying timestamp of '${TEST_FILE}' inside '${RUNNER_POD_NAME}'..."
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "touch '${TEST_FILE}' && touch -a -t 197001010000.00 '${TEST_FILE}'"

YEAR="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c "stat -c %x '${TEST_FILE}' | cut -d'-' -f1")"
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- rm -f "${TEST_FILE}"

if [ "${YEAR}" == "1970" ]; then
    log_success "T1070.006 emulation succeeded (Access timestamp shifted to 1970)."
else
    log_error "T1070.006 emulation failed: Timestamp year is ${YEAR} (expected 1970)."
    exit 1
fi

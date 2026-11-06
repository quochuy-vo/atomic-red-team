#!/usr/bin/env bash
# T1070.004: Indicator Removal - File Deletion in Pod
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1070.004: File Deletion"

TEST_FILE="/tmp/t1070_malware.log"

log_telemetry "T1070.004" "${RUNNER_POD_NAME}" "unlinkat on ${TEST_FILE}"

log_info "Creating and deleting target file inside '${RUNNER_POD_NAME}'..."
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "touch '${TEST_FILE}' && rm -f '${TEST_FILE}'"

OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c "test ! -f '${TEST_FILE}' && echo 'FILE_DELETED'")"

if [ "${OUTPUT}" == "FILE_DELETED" ]; then
    log_success "T1070.004 emulation succeeded (File unlinked and deleted)."
else
    log_error "T1070.004 emulation failed: File still exists."
    exit 1
fi

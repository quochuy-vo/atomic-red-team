#!/usr/bin/env bash
# T1070.003: Indicator Removal - Clear Command History in Pod
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1070.003: Clear Command History"

log_telemetry "T1070.003" "${RUNNER_POD_NAME}" "unlink/truncate .bash_history"

log_info "Creating dummy bash history and executing removal inside '${RUNNER_POD_NAME}'..."
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "echo 'malicious_command_entry' >> ~/.bash_history && rm -f ~/.bash_history"

OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c "test ! -f ~/.bash_history && echo 'HISTORY_CLEARED'")"

if [ "${OUTPUT}" == "HISTORY_CLEARED" ]; then
    log_success "T1070.003 emulation succeeded (Command history deleted)."
else
    log_error "T1070.003 emulation failed: History file still exists."
    exit 1
fi

#!/usr/bin/env bash
# T1053.003: Scheduled Task/Job - Cron Persistence
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1053.003: Cron Persistence"

CRON_FILE="/etc/cron.d/art_persistence"

log_telemetry "T1053.003" "${RUNNER_POD_NAME}" "create cron file ${CRON_FILE}"

log_info "Creating persistence entry in /etc/cron.d inside '${RUNNER_POD_NAME}'..."
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "echo '* * * * * root date >/dev/null' > '${CRON_FILE}'"

EXISTS="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c "test -f '${CRON_FILE}' && echo 'CRON_EXISTS'")"
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- rm -f "${CRON_FILE}"

if [ "${EXISTS}" == "CRON_EXISTS" ]; then
    log_success "T1053.003 emulation succeeded (Cron persistence file written and verified)."
else
    log_error "T1053.003 emulation failed: Cron persistence file not found."
    exit 1
fi

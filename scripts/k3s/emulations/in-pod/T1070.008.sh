#!/usr/bin/env bash
# T1070.008: Indicator Removal - Clear Mailbox Data in Pod
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1070.008: Clear Mailbox Data"

MAIL_SPOOL="/var/spool/mail/testuser"

log_telemetry "T1070.008" "${RUNNER_POD_NAME}" "unlink mailbox ${MAIL_SPOOL}"

log_info "Creating and deleting dummy mailbox inside '${RUNNER_POD_NAME}'..."
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "mkdir -p /var/spool/mail && echo 'sensitive_email' > '${MAIL_SPOOL}' && rm -f '${MAIL_SPOOL}'"

OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c "test ! -f '${MAIL_SPOOL}' && echo 'MAILBOX_CLEARED'")"

if [ "${OUTPUT}" == "MAILBOX_CLEARED" ]; then
    log_success "T1070.008 emulation succeeded (Mailbox spool data cleared)."
else
    log_error "T1070.008 emulation failed: Mailbox spool file still exists."
    exit 1
fi

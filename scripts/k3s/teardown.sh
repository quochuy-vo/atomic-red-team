#!/usr/bin/env bash
# Ending script: Completely removes test namespace and all associated cluster resources

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "k3s Atomic Emulation Suite - Teardown"

check_prerequisites

if ! kubectl get namespace "${TARGET_NAMESPACE}" >/dev/null 2>&1; then
    log_info "Namespace '${TARGET_NAMESPACE}' does not exist. Nothing to tear down."
    exit 0
fi

# 1. Clean up transient pods with zero grace period for fast teardown
log_info "Cleaning up any lingering pods in '${TARGET_NAMESPACE}'..."
kubectl delete pods --all -n "${TARGET_NAMESPACE}" --grace-period=0 --force --ignore-not-found >/dev/null 2>&1 || true

# 2. Clean up cronjobs
kubectl delete cronjobs --all -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true

# 3. Delete the test namespace
log_info "Deleting namespace '${TARGET_NAMESPACE}'..."
kubectl delete namespace "${TARGET_NAMESPACE}" --timeout="${KUBECTL_TIMEOUT}" --ignore-not-found

# 4. Verify removal
log_info "Verifying namespace removal..."
TIMEOUT=30
ELAPSED=0
while kubectl get namespace "${TARGET_NAMESPACE}" >/dev/null 2>&1; do
    if [ "${ELAPSED}" -ge "${TIMEOUT}" ]; then
        log_warn "Namespace '${TARGET_NAMESPACE}' is still terminating after ${TIMEOUT}s."
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if ! kubectl get namespace "${TARGET_NAMESPACE}" >/dev/null 2>&1; then
    log_success "Namespace '${TARGET_NAMESPACE}' completely removed. Cluster is clean."
else
    log_warn "Namespace '${TARGET_NAMESPACE}' is finalizing deletion."
fi

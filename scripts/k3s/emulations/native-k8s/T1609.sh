#!/usr/bin/env bash
# T1609: Container Administration Command (kubectl exec)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1609: Container Administration Command"

MANIFEST="${REPO_ROOT}/atomics/T1609/src/busybox.yaml"
POD_NAME="busybox"

# 1. Ensure target pod is deployed
log_info "Deploying target pod '${POD_NAME}' from ${MANIFEST}..."
kubectl apply -f "${MANIFEST}" -n "${TARGET_NAMESPACE}"
kubectl wait --for=condition=Ready "pod/${POD_NAME}" -n "${TARGET_NAMESPACE}" --timeout="${KUBECTL_TIMEOUT}"

# 2. Record telemetry
log_telemetry "T1609" "${POD_NAME}" "kubectl exec -n ${TARGET_NAMESPACE} ${POD_NAME} -- uname -a"

# 3. Execute emulation
log_info "Executing administrative command in container..."
OUTPUT="$(kubectl exec -n "${TARGET_NAMESPACE}" "${POD_NAME}" -- uname -a)"
echo "${OUTPUT}"

# 4. Assert outcome
if echo "${OUTPUT}" | grep -q "Linux"; then
    log_success "T1609 emulation succeeded (Container executed 'uname -a')."
else
    log_error "T1609 emulation failed: Unexpected output."
    exit 1
fi

# 5. Local cleanup
log_info "Cleaning up '${POD_NAME}'..."
kubectl delete pod "${POD_NAME}" -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1

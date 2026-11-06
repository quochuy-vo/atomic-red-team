#!/usr/bin/env bash
# Starting script: Sets up dedicated namespace, labels Pod Security, and deploys runner pod

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "k3s Atomic Emulation Suite - Setup"

check_prerequisites

# 1. Create target namespace if not present
if ! kubectl get namespace "${TARGET_NAMESPACE}" >/dev/null 2>&1; then
    log_info "Creating namespace '${TARGET_NAMESPACE}'..."
    kubectl create namespace "${TARGET_NAMESPACE}"
else
    log_info "Namespace '${TARGET_NAMESPACE}' already exists."
fi

# 2. Configure Pod Security Admission (PSA) to privileged
log_info "Applying Pod Security Admission 'privileged' label to '${TARGET_NAMESPACE}'..."
kubectl label namespace "${TARGET_NAMESPACE}" pod-security.kubernetes.io/enforce=privileged --overwrite
kubectl label namespace "${TARGET_NAMESPACE}" pod-security.kubernetes.io/audit=privileged --overwrite
kubectl label namespace "${TARGET_NAMESPACE}" pod-security.kubernetes.io/warn=privileged --overwrite

# 3. Deploy persistent runner pod for in-pod attacks
if ! kubectl get pod "${RUNNER_POD_NAME}" -n "${TARGET_NAMESPACE}" >/dev/null 2>&1; then
    log_info "Deploying test runner pod '${RUNNER_POD_NAME}' (${RUNNER_IMAGE})..."
    kubectl run "${RUNNER_POD_NAME}" -n "${TARGET_NAMESPACE}" \
      --image="${RUNNER_IMAGE}" --restart=Never \
      --overrides='{"spec":{"containers":[{"name":"runner","image":"'"${RUNNER_IMAGE}"'","command":["sleep","86400"],"securityContext":{"privileged":true}}]}}'
else
    log_info "Test runner pod '${RUNNER_POD_NAME}' already exists."
fi

# 4. Wait for runner pod to be ready
log_info "Waiting for pod '${RUNNER_POD_NAME}' to enter Ready state (timeout: ${KUBECTL_TIMEOUT})..."
kubectl wait --for=condition=Ready pod/"${RUNNER_POD_NAME}" -n "${TARGET_NAMESPACE}" --timeout="${KUBECTL_TIMEOUT}"

# 5. Output runner metadata
NODE_NAME="$(kubectl get pod "${RUNNER_POD_NAME}" -n "${TARGET_NAMESPACE}" -o jsonpath='{.spec.nodeName}')"
log_success "Environment ready. Runner '${RUNNER_POD_NAME}' is active on node '${NODE_NAME}'."

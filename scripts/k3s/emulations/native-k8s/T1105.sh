#!/usr/bin/env bash
# T1105: Ingress Tool Transfer (Curl connection from a pod)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_header "Emulation T1105: Ingress Tool Transfer"

POD_NAME="t1105-curl-pod"
TARGET_URL="${TARGET_URL:-https://kubernetes.default.svc}"

kubectl delete pod "${POD_NAME}" -n "${TARGET_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true

log_telemetry "T1105" "${POD_NAME}" "curl -ksI ${TARGET_URL}"

log_info "Running ephemeral curl pod to transfer tool / connect to '${TARGET_URL}'..."
OUTPUT="$(kubectl run "${POD_NAME}" -n "${TARGET_NAMESPACE}" \
  --image=curlimages/curl:latest --restart=Never --attach --rm -i \
  -- curl -ks -I "${TARGET_URL}" 2>/dev/null || true)"

echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -qE "HTTP/|401|403|200"; then
    log_success "T1105 emulation succeeded (Ingress HTTP transfer connection established)."
else
    log_error "T1105 emulation failed: No HTTP response received."
    exit 1
fi

#!/usr/bin/env bash
# Dispatches and executes a single atomic emulation technique against k3s
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <TECHNIQUE_ID> (e.g. $0 T1609)"
    exit 1
fi

TECHNIQUE_ID="$1"

# 1. Ensure test environment is initialized
if ! kubectl get namespace "${TARGET_NAMESPACE}" >/dev/null 2>&1; then
    log_info "Namespace '${TARGET_NAMESPACE}' not found. Initializing setup..."
    "${SCRIPT_DIR}/setup.sh"
fi

# 2. Locate emulation script
SCRIPT_PATH=""
for DIR in native-k8s in-pod node; do
    CANDIDATE="${SCRIPT_DIR}/emulations/${DIR}/${TECHNIQUE_ID}.sh"
    if [ -f "${CANDIDATE}" ]; then
        SCRIPT_PATH="${CANDIDATE}"
        break
    fi
done

if [ -z "${SCRIPT_PATH}" ]; then
    log_error "No emulation script found for technique '${TECHNIQUE_ID}'."
    echo "Available techniques:"
    find "${SCRIPT_DIR}/emulations" -type f -name "*.sh" | sed 's|.*/||;s|\.sh||' | sort | column
    exit 1
fi

# 3. Execute emulation
START_TIME=$(date +%s)
log_info "Executing ${TECHNIQUE_ID} via $(basename "${SCRIPT_PATH}")..."

set +e
"${SCRIPT_PATH}"
EXIT_CODE=$?
set -e

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ "${EXIT_CODE}" -eq 0 ]; then
    log_success "${TECHNIQUE_ID} passed in ${DURATION}s."
    exit 0
else
    log_error "${TECHNIQUE_ID} failed (exit code ${EXIT_CODE}) after ${DURATION}s."
    exit "${EXIT_CODE}"
fi

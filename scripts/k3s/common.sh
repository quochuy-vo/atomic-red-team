#!/usr/bin/env bash
# Common helper functions and assertions for k3s Atomic Red Team Emulation Testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date +'%Y-%m-%dT%H:%M:%S%z') - $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $(date +'%Y-%m-%dT%H:%M:%S%z') - $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date +'%Y-%m-%dT%H:%M:%S%z') - $*"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $(date +'%Y-%m-%dT%H:%M:%S%z') - $*" >&2
}

log_header() {
    echo -e "\n${CYAN}===================================================================${NC}"
    echo -e "${CYAN}  $*${NC}"
    echo -e "${CYAN}===================================================================${NC}"
}

# Verify kubectl binary and cluster connectivity
check_prerequisites() {
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl command not found in PATH. Please install kubectl."
        return 1
    fi

    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Unable to connect to Kubernetes cluster. Check your KUBECONFIG."
        return 1
    fi

    mkdir -p "${LOG_DIR}"
    return 0
}

# Output metadata for bpftrace correlation
log_telemetry() {
    local technique="$1"
    local target_pod="$2"
    local action="$3"
    local timestamp
    timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    local node_name
    node_name="$(kubectl get pod "${target_pod}" -n "${TARGET_NAMESPACE}" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "N/A")"

    local container_id
    container_id="$(kubectl get pod "${target_pod}" -n "${TARGET_NAMESPACE}" -o jsonpath='{.status.containerStatuses[0].containerID}' 2>/dev/null || echo "N/A")"

    echo -e "${YELLOW}[TELEMETRY]${NC} Time: ${timestamp} | Technique: ${technique} | Pod: ${target_pod} | Node: ${node_name} | ContainerID: ${container_id} | Action: ${action}"
}

# Assert exit code
assert_exit_code() {
    local exit_code="$1"
    local test_name="$2"
    if [ "${exit_code}" -eq 0 ]; then
        log_success "${test_name} completed successfully."
        return 0
    else
        log_error "${test_name} failed with exit code ${exit_code}."
        return "${exit_code}"
    fi
}

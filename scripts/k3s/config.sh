#!/usr/bin/env bash
# Global Configuration for k3s Atomic Red Team Emulation Testing

# Kubernetes namespace to isolate atomic tests
export TARGET_NAMESPACE="${TARGET_NAMESPACE:-atomic-test}"

# Persistent runner pod for in-pod workload emulations
export RUNNER_POD_NAME="${RUNNER_POD_NAME:-atomic-runner}"
export RUNNER_IMAGE="${RUNNER_IMAGE:-ubuntu:22.04}"

# Default timeout for kubectl operations
export KUBECTL_TIMEOUT="${KUBECTL_TIMEOUT:-60s}"

# Repository directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export SCRIPTS_DIR="${SCRIPT_DIR}"
export LOG_DIR="${REPO_ROOT}/logs/k3s-emulation"

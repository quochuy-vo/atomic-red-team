#!/usr/bin/env bash
# Master test runner: Executes k3s Atomic Red Team Emulation Suite and generates summary report
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

SKIP_TEARDOWN=false
CLEAN_ONLY=false
CATEGORY="all"

while [ $# -gt 0 ]; do
    case "$1" in
        --skip-teardown)
            SKIP_TEARDOWN=true
            shift
            ;;
        --clean-only)
            CLEAN_ONLY=true
            shift
            ;;
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --category [k8s|in-pod|all]   Select subset of tests (default: all)"
            echo "  --skip-teardown               Preserve test namespace after run for inspection"
            echo "  --clean-only                  Run teardown only"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [ "${CLEAN_ONLY}" = true ]; then
    "${SCRIPT_DIR}/teardown.sh"
    exit 0
fi

log_header "k3s Atomic Red Team Emulation Suite - Starting Run"

# 1. Run Setup
"${SCRIPT_DIR}/setup.sh"

# 2. Select tests based on category
TESTS=()
if [ "${CATEGORY}" = "k8s" ] || [ "${CATEGORY}" = "all" ]; then
    for T in "${SCRIPT_DIR}"/emulations/native-k8s/*.sh; do
        [ -f "${T}" ] && TESTS+=("${T}")
    done
fi

if [ "${CATEGORY}" = "in-pod" ] || [ "${CATEGORY}" = "all" ]; then
    for T in "${SCRIPT_DIR}"/emulations/in-pod/*.sh; do
        [ -f "${T}" ] && TESTS+=("${T}")
    done
fi

log_info "Discovered ${#TESTS[@]} tests to execute (category: ${CATEGORY})."

# Results tracking
PASSED=0
FAILED=0
RESULTS=()

TOTAL_START=$(date +%s)

for TEST_SCRIPT in "${TESTS[@]}"; do
    T_NAME="$(basename "${TEST_SCRIPT}" .sh)"
    T_START=$(date +%s)
    
    set +e
    "${TEST_SCRIPT}"
    EXIT_CODE=$?
    set -e
    
    T_END=$(date +%s)
    DUR=$((T_END - T_START))
    
    if [ "${EXIT_CODE}" -eq 0 ]; then
        PASSED=$((PASSED + 1))
        RESULTS+=("${T_NAME}|PASS|${DUR}s")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("${T_NAME}|FAIL|${DUR}s")
    fi
done

TOTAL_END=$(date +%s)
TOTAL_DUR=$((TOTAL_END - TOTAL_START))

# 3. Print Summary Report
log_header "k3s Atomic Emulation Suite - Execution Summary"

printf "%-14s | %-8s | %-10s\n" "Technique" "Status" "Duration"
echo "---------------------------------------"
for R in "${RESULTS[@]}"; do
    IFS="|" read -r ID STATUS DUR <<< "${R}"
    if [ "${STATUS}" == "PASS" ]; then
        printf "%-14s | \033[0;32m%-8s\033[0m | %-10s\n" "${ID}" "${STATUS}" "${DUR}"
    else
        printf "%-14s | \033[0;31m%-8s\033[0m | %-10s\n" "${ID}" "${STATUS}" "${DUR}"
    fi
done
echo "---------------------------------------"
echo "Total: ${#TESTS[@]} | Passed: ${PASSED} | Failed: ${FAILED} | Duration: ${TOTAL_DUR}s"

# 4. Teardown
if [ "${SKIP_TEARDOWN}" = false ]; then
    "${SCRIPT_DIR}/teardown.sh"
else
    log_warn "Teardown skipped via --skip-teardown. Target namespace '${TARGET_NAMESPACE}' is preserved."
fi

if [ "${FAILED}" -gt 0 ]; then
    exit 1
fi
exit 0

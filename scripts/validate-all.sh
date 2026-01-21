#!/bin/bash
# -----------------------------------------------------------------------------
# Validate All Terraform Configurations
# Runs terraform validate on all modules and environments
#
# Usage:
#   ./scripts/validate-all.sh
# -----------------------------------------------------------------------------

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

echo "=============================================="
echo "Terraform Validation"
echo "Project Root: ${PROJECT_ROOT}"
echo "=============================================="
echo ""

# Track results
FAILED=0
PASSED=0

validate_dir() {
    local dir=$1
    local name=$2

    echo -n "Validating ${name}... "

    cd "${dir}"

    # Initialize without backend
    if ! terraform init -backend=false -input=false > /dev/null 2>&1; then
        echo "FAILED (init)"
        ((FAILED++))
        return 1
    fi

    # Validate
    if terraform validate > /dev/null 2>&1; then
        echo "PASSED"
        ((PASSED++))
        return 0
    else
        echo "FAILED (validate)"
        terraform validate
        ((FAILED++))
        return 1
    fi
}

# Validate modules
echo "=== Modules ==="
for module_dir in "${PROJECT_ROOT}"/modules/*/; do
    module_name=$(basename "${module_dir}")
    validate_dir "${module_dir}" "modules/${module_name}" || true
done
echo ""

# Validate environments
echo "=== Environments ==="
for env_dir in "${PROJECT_ROOT}"/environments/*/; do
    env_name=$(basename "${env_dir}")
    validate_dir "${env_dir}" "environments/${env_name}" || true
done
echo ""

# Summary
echo "=============================================="
echo "Validation Summary"
echo "=============================================="
echo "Passed: ${PASSED}"
echo "Failed: ${FAILED}"
echo "=============================================="

if [ ${FAILED} -gt 0 ]; then
    echo "Some validations failed!"
    exit 1
else
    echo "All validations passed!"
    exit 0
fi

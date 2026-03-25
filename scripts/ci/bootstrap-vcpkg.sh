#!/usr/bin/env bash
# Clone/checkout vcpkg at VCPKG_COMMIT (default in common.sh). Safe to run repeatedly.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
bootstrap_vcpkg
echo "vcpkg ready at ${VCPKG_ROOT} (commit ${VCPKG_COMMIT})"

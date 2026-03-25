#!/usr/bin/env bash
# Configure, build, and install GameNetworkingSockets for Linux x64 (vcpkg x64-linux).
# Local: sudo apt install ninja-build pkg-config build-essential
# Optional: PACKAGE_NAME=GameNetworkingSockets-v1.0.0-linux-x64 to emit a .tar.gz in cwd.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

bootstrap_vcpkg
cd "${GNS_REPO_ROOT}"

BUILD_DIR="${BUILD_DIR:-${GNS_REPO_ROOT}/build-linux-x64}"
INSTALL_PREFIX="${INSTALL_PREFIX:-${GNS_REPO_ROOT}/install-linux-x64}"
# shellcheck disable=SC2086
cmake -B "${BUILD_DIR}" -G Ninja -S . \
  $(gns_release_cmake_flags) \
  -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_TARGET_TRIPLET=x64-linux

cmake --build "${BUILD_DIR}" --verbose
rm -rf "${INSTALL_PREFIX}"
cmake --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"

if [[ -n "${PACKAGE_NAME:-}" ]]; then
  "${SCRIPT_DIR}/package-install-tree.sh" --prefix "${INSTALL_PREFIX}" --name "${PACKAGE_NAME}" --format tgz
fi

echo "Installed to ${INSTALL_PREFIX}"

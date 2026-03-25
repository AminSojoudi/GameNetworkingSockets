#!/usr/bin/env bash
# macOS host, arm64-osx triplet. Run on Apple Silicon (or Rosetta). Requires Xcode CLI tools, Ninja.
# Optional: PACKAGE_NAME=... to write .tar.gz in cwd.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

bootstrap_vcpkg
cd "${GNS_REPO_ROOT}"

BUILD_DIR="${BUILD_DIR:-${GNS_REPO_ROOT}/build-macos-arm64}"
INSTALL_PREFIX="${INSTALL_PREFIX:-${GNS_REPO_ROOT}/install-macos-arm64}"
# shellcheck disable=SC2086
cmake -B "${BUILD_DIR}" -G Ninja -S . \
  $(gns_release_cmake_flags) \
  -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_TARGET_TRIPLET=arm64-osx

cmake --build "${BUILD_DIR}" --verbose
rm -rf "${INSTALL_PREFIX}"
cmake --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"

if [[ -n "${PACKAGE_NAME:-}" ]]; then
  "${SCRIPT_DIR}/package-install-tree.sh" --prefix "${INSTALL_PREFIX}" --name "${PACKAGE_NAME}" --format tgz
fi

echo "Installed to ${INSTALL_PREFIX}"

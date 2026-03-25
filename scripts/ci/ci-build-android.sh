#!/usr/bin/env bash
# Android cross-build via vcpkg + NDK. Requires ANDROID_NDK_HOME, Ninja, pkg-config.
#
# Usage:
#   export ANDROID_NDK_HOME=/path/to/ndk
#   ./ci-build-android.sh [--triplet arm64-android] [--abi arm64-v8a]
#
# Optional: PACKAGE_NAME=... to write .tar.gz in cwd after install.
# Optional: --no-install  only configure + build (CI uploads .so from build dir).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TRIPLET="arm64-android"
ABI="arm64-v8a"
DO_INSTALL=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --triplet) TRIPLET="${2:-}"; shift 2 ;;
    --abi) ABI="${2:-}"; shift 2 ;;
    --no-install) DO_INSTALL=0; shift ;;
    -h|--help)
      echo "Usage: ANDROID_NDK_HOME=... $0 [--triplet T] [--abi A] [--no-install]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

: "${ANDROID_NDK_HOME:?Set ANDROID_NDK_HOME to the Android NDK root (contains build/cmake/android.toolchain.cmake)}"
CHAIN="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"
[[ -f "${CHAIN}" ]] || { echo "Missing NDK toolchain: ${CHAIN}"; exit 1; }

bootstrap_vcpkg
cd "${GNS_REPO_ROOT}"

BUILD_DIR="${BUILD_DIR:-${GNS_REPO_ROOT}/build-android-${TRIPLET}}"
INSTALL_PREFIX="${INSTALL_PREFIX:-${GNS_REPO_ROOT}/install-android-${TRIPLET}}"
# shellcheck disable=SC2086
cmake -B "${BUILD_DIR}" -G Ninja -S . \
  $(gns_release_cmake_flags) \
  -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="${CHAIN}" \
  -DVCPKG_TARGET_TRIPLET="${TRIPLET}" \
  -DANDROID_ABI="${ABI}" \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_HAVE_LIBC_PTHREAD=ON

cmake --build "${BUILD_DIR}" --verbose

if [[ "${DO_INSTALL}" -eq 1 ]]; then
  rm -rf "${INSTALL_PREFIX}"
  cmake --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"
  if [[ -n "${PACKAGE_NAME:-}" ]]; then
    "${SCRIPT_DIR}/package-install-tree.sh" --prefix "${INSTALL_PREFIX}" --name "${PACKAGE_NAME}" --format tgz
  fi
  echo "Installed to ${INSTALL_PREFIX}"
else
  echo "Build only: output under ${BUILD_DIR}"
fi

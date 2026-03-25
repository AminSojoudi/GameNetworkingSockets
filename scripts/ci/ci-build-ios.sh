#!/usr/bin/env bash
# iOS device or simulator static libs via vcpkg. macOS + Xcode only.
#
# Usage:
#   ./ci-build-ios.sh [--triplet arm64-ios|arm64-ios-simulator|x64-ios] [--deployment-target 13.0]
#
# Optional: PACKAGE_NAME=... to write .tar.gz in cwd after install.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TRIPLET="arm64-ios"
DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-13.0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --triplet) TRIPLET="${2:-}"; shift 2 ;;
    --deployment-target) DEPLOYMENT_TARGET="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--triplet arm64-ios|arm64-ios-simulator|x64-ios] [--deployment-target 13.0]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

case "$(uname -s)" in
  Darwin) ;;
  *) echo "iOS builds must run on macOS with Xcode."; exit 1 ;;
esac

ARCH=""
SYSROOT_CMAKE=""
case "${TRIPLET}" in
  arm64-ios)
    ARCH=arm64
    SYSROOT_CMAKE=-DCMAKE_OSX_SYSROOT=iphoneos
    ;;
  arm64-ios-simulator)
    ARCH=arm64
    SYSROOT_CMAKE=-DCMAKE_OSX_SYSROOT=iphonesimulator
    ;;
  x64-ios)
    ARCH=x86_64
    SYSROOT_CMAKE=-DCMAKE_OSX_SYSROOT=iphonesimulator
    ;;
  *)
    echo "Unsupported triplet: ${TRIPLET} (expected arm64-ios, arm64-ios-simulator, or x64-ios)"
    exit 1
    ;;
esac

bootstrap_vcpkg
cd "${GNS_REPO_ROOT}"

BUILD_DIR="${BUILD_DIR:-${GNS_REPO_ROOT}/build-ios-${TRIPLET}}"
INSTALL_PREFIX="${INSTALL_PREFIX:-${GNS_REPO_ROOT}/install-ios-${TRIPLET}}"
# shellcheck disable=SC2086
cmake -B "${BUILD_DIR}" -G Ninja -S . \
  $(gns_release_cmake_flags) \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" \
  -DCMAKE_OSX_ARCHITECTURES="${ARCH}" \
  ${SYSROOT_CMAKE} \
  -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_TARGET_TRIPLET="${TRIPLET}" \
  -DBUILD_SHARED_LIB=OFF \
  -DBUILD_STATIC_LIB=ON

cmake --build "${BUILD_DIR}" --verbose
rm -rf "${INSTALL_PREFIX}"
cmake --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"

if [[ -n "${PACKAGE_NAME:-}" ]]; then
  "${SCRIPT_DIR}/package-install-tree.sh" --prefix "${INSTALL_PREFIX}" --name "${PACKAGE_NAME}" --format tgz
fi

echo "Installed to ${INSTALL_PREFIX}"

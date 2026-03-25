#!/usr/bin/env bash
# shellcheck shell=bash
# Source from other scripts in this directory (do not execute directly).
_GNS_CI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GNS_REPO_ROOT="$(cd "${_GNS_CI_LIB_DIR}/../.." && pwd)"

: "${VCPKG_ROOT:=${GNS_REPO_ROOT}/vcpkg}"
: "${VCPKG_COMMIT:=fba75d09065fcc76a25dcf386b1d00d33f5175af}"

bootstrap_vcpkg() {
  if [[ ! -d "${VCPKG_ROOT}/.git" ]]; then
    git clone https://github.com/microsoft/vcpkg.git "${VCPKG_ROOT}"
  fi
  git -C "${VCPKG_ROOT}" checkout -f "${VCPKG_COMMIT}"
  if [[ -x "${VCPKG_ROOT}/bootstrap-vcpkg.sh" ]] && [[ ! -f "${VCPKG_ROOT}/vcpkg" ]] && [[ ! -f "${VCPKG_ROOT}/vcpkg.exe" ]]; then
    "${VCPKG_ROOT}/bootstrap-vcpkg.sh"
  fi
}

# Extra CMake arguments shared by release-style builds (no tests/examples/tools).
gns_release_cmake_flags() {
  printf '%s' "-DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TOOLS=OFF"
}

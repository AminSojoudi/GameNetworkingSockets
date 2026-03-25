#!/usr/bin/env bash
# Create an archive of a CMake install prefix (run from repo root or any cwd).
set -euo pipefail

FORMAT="tgz"
PREFIX=""
NAME=""

usage() {
  echo "Usage: $0 --prefix <install-dir> --name <archive-base-no-extension> [--format tgz|zip]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX="${2:-}"; shift 2 ;;
    --name) NAME="${2:-}"; shift 2 ;;
    --format) FORMAT="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ -n "$PREFIX" && -n "$NAME" ]] || usage
[[ -d "$PREFIX" ]] || { echo "Prefix not a directory: $PREFIX"; exit 1; }

OUT_DIR="$(pwd)"
case "$FORMAT" in
  tgz)
    tar czf "${OUT_DIR}/${NAME}.tar.gz" -C "$PREFIX" .
    echo "Wrote ${OUT_DIR}/${NAME}.tar.gz"
    ;;
  zip)
    if command -v zip >/dev/null 2>&1; then
      (cd "$PREFIX" && zip -qr "${OUT_DIR}/${NAME}.zip" .)
    else
      echo "zip(1) not found; install zip or use --format tgz"
      exit 1
    fi
    echo "Wrote ${OUT_DIR}/${NAME}.zip"
    ;;
  *) echo "Unsupported format: $FORMAT"; exit 1 ;;
esac

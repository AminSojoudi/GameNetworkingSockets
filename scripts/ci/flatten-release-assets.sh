#!/usr/bin/env bash
# Used by the Release workflow: copy all nested tarball/zip artifacts into one directory.
set -euo pipefail
SRC="${1:?usage: $0 <download-artifact-root> [output-dir]}"
OUT="${2:-release-assets}"
mkdir -p "${OUT}"
find "${SRC}" -type f \( -name '*.tar.gz' -o -name '*.zip' \) -exec cp -v {} "${OUT}/" \;
ls -la "${OUT}"

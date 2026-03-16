#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
BIN_SOURCE="$SCRIPT_DIR/bin/EvoProgrammer"
INSTALL_DIR="${1:-$HOME/.local/bin}"
BIN_TARGET="$INSTALL_DIR/EvoProgrammer"

source "$COMMON_LIB"
evop_require_executable_file "$BIN_SOURCE" "CLI entrypoint"

mkdir -p "$INSTALL_DIR"
ln -sfn "$BIN_SOURCE" "$BIN_TARGET"

cat <<EOF
Installed EvoProgrammer to:
  $BIN_TARGET

Make sure '$INSTALL_DIR' is on your PATH, then run:
  EvoProgrammer "your prompt"
EOF

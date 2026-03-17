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

PATH_LINE="export PATH=\"$INSTALL_DIR:\$PATH\""

ensure_path_in_rc() {
    local rc_file="$1"

    if [[ ! -f "$rc_file" ]]; then
        return 1
    fi

    if grep -Fq "$INSTALL_DIR" "$rc_file" 2>/dev/null; then
        return 0
    fi

    printf '\n# EvoProgrammer\n%s\n' "$PATH_LINE" >>"$rc_file"
    echo "Added $INSTALL_DIR to PATH in $rc_file"
    return 0
}

path_configured=0
if ensure_path_in_rc "$HOME/.zshrc"; then
    path_configured=1
fi
if ensure_path_in_rc "$HOME/.bashrc"; then
    path_configured=1
fi

cat <<EOF
Installed EvoProgrammer to:
  $BIN_TARGET
EOF

if (( path_configured == 0 )); then
    cat <<EOF

Make sure '$INSTALL_DIR' is on your PATH, then run:
  EvoProgrammer "your prompt"
EOF
else
    cat <<EOF

Restart your shell or run:
  source ~/.zshrc
Then:
  EvoProgrammer "your prompt"
EOF
fi

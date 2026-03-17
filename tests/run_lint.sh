#!/usr/bin/env zsh

# shellcheck source=lib/bootstrap.sh
. "$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

ROOT_DIR="$(cd "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=tests/lib/test_runner.sh
source "$ROOT_DIR/tests/lib/test_runner.sh"

if ! command -v shellcheck >/dev/null 2>&1; then
    printf 'shellcheck is required for lint checks.\n' >&2
    exit 127
fi

evop_collect_shellcheck_targets "$ROOT_DIR"
shellcheck -x "${EVOP_SHELLCHECK_TARGETS[@]}"

evop_collect_zsh_syntax_targets "$ROOT_DIR"
zsh -n "${EVOP_ZSH_SYNTAX_TARGETS[@]}"

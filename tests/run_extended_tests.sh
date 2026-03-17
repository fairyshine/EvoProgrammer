#!/usr/bin/env zsh

# shellcheck source=lib/bootstrap.sh
. "$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

ROOT_DIR="$(cd "$(dirname -- "$0")/.." && pwd)"

usage() {
    cat <<'EOF'
Usage: tests/run_extended_tests.sh [options] [case-filter...]

Options:
  --skip-lint        Skip zsh syntax checks and shellcheck
  --skip-shellcheck  Backward-compatible alias for --skip-lint
  --list             Print matching test case files and exit
  -h, --help         Show this help text
EOF
}

# shellcheck source=tests/lib/test_runner.sh
source "$ROOT_DIR/tests/lib/test_runner.sh"

SKIP_LINT=0
LIST_ONLY=0
FORWARDED_ARGS=()

while (($# > 0)); do
    case "$1" in
        --skip-lint)
            SKIP_LINT=1
            ;;
        --skip-shellcheck)
            SKIP_LINT=1
            ;;
        --list)
            LIST_ONLY=1
            FORWARDED_ARGS+=("$1")
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            FORWARDED_ARGS+=("$1")
            ;;
    esac
    shift
done

if (( SKIP_LINT == 0 && LIST_ONLY == 0 )); then
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf 'shellcheck is required for extended tests.\n' >&2
        exit 127
    fi

    evop_collect_shellcheck_targets "$ROOT_DIR"
    shellcheck -x "${EVOP_SHELLCHECK_TARGETS[@]}"
    evop_collect_zsh_syntax_targets "$ROOT_DIR"
    zsh -n "${EVOP_ZSH_SYNTAX_TARGETS[@]}"
fi

if ((${#FORWARDED_ARGS[@]} == 0)); then
    exec zsh "$ROOT_DIR/tests/run_tests.sh"
fi

exec zsh "$ROOT_DIR/tests/run_tests.sh" "${FORWARDED_ARGS[@]}"

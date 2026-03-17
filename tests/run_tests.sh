#!/usr/bin/env zsh

# shellcheck source=lib/bootstrap.sh
. "$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

ROOT_DIR="$(cd "$(dirname -- "$0")/.." && pwd)"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

usage() {
    cat <<'EOF'
Usage: tests/run_tests.sh [options] [case-filter...]

Options:
  --list      Print matching test case files and exit
  -h, --help  Show this help text

Arguments:
  case-filter Match test case paths or filenames by substring
EOF
}

# shellcheck source=tests/lib/test_runner.sh
source "$ROOT_DIR/tests/lib/test_runner.sh"

LIST_ONLY=0
FILTERS=()

while (($# > 0)); do
    case "$1" in
        --list)
            LIST_ONLY=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while (($# > 0)); do
                FILTERS+=("$1")
                shift
            done
            break
            ;;
        -*)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
        *)
            FILTERS+=("$1")
            ;;
    esac
    shift
done

if (( LIST_ONLY == 1 )); then
    if ((${#FILTERS[@]} == 0)); then
        evop_print_selected_test_cases "$ROOT_DIR"
    else
        evop_print_selected_test_cases "$ROOT_DIR" "${FILTERS[@]}"
    fi
    exit 0
fi

# shellcheck source=tests/lib/test_helpers.sh
source "$ROOT_DIR/tests/lib/test_helpers.sh"

if ((${#FILTERS[@]} == 0)); then
    evop_select_test_case_files "$ROOT_DIR"
else
    evop_select_test_case_files "$ROOT_DIR" "${FILTERS[@]}"
fi

if ((${#EVOP_SELECTED_TEST_CASE_FILES[@]} == 0)); then
    printf 'No test cases matched'
    if ((${#FILTERS[@]} > 0)); then
        printf ' filters:'
        printf ' %s' "${FILTERS[@]}"
    fi
    printf '\n' >&2
    exit 1
fi

for evop_test_case_file in "${EVOP_SELECTED_TEST_CASE_FILES[@]}"; do
    # shellcheck disable=SC1090
    source "$evop_test_case_file"
done

echo "All $PASS_COUNT tests passed."

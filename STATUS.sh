#!/bin/sh
# shellcheck shell=bash disable=SC1090,SC1091,SC2034

. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
EVOP_LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
STATUS_LIB="$SCRIPT_DIR/lib/status.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$STATUS_LIB"

LAST_N=10
SHOW_ALL=0
TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
ARTIFACTS_DIR="${EVOPROGRAMMER_ARTIFACTS_DIR:-}"
OUTPUT_FORMAT="summary"
REPORT_FILE=""
REPORT_FORMAT=""
STATUS_KIND="all"
STATUS_FILTER=""
STATUS_AGENT_FILTER=""

usage() {
    cat <<'EOF'
Usage: ./STATUS.sh [options]

Shows recent run and session history from the artifacts directory.

Options:
  --last N              Show the last N entries. Default: 10.
  --all                 Show all entries.
  --kind NAME           Filter by entry kind: all, run, or session.
  --status VALUE        Filter by recorded session state or run status.
  --agent NAME          Filter by agent name.
  --format NAME         Output format: summary, json, or env.
  --report-file FILE    Also write status output to a file.
  --report-format NAME  Report file format. Defaults to --format.
  -t, --target-dir DIR  Repository directory. Default: current directory.
  -o, --artifacts-dir DIR
                        Root directory used to store run artifacts.
  -h, --help            Show this help text.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --last)
            evop_require_option_value "$1" "$#"
            LAST_N="$2"
            shift 2
            ;;
        --all)
            SHOW_ALL=1
            shift
            ;;
        --kind)
            evop_require_option_value "$1" "$#"
            STATUS_KIND="$2"
            shift 2
            ;;
        --status)
            evop_require_option_value "$1" "$#"
            STATUS_FILTER="$2"
            shift 2
            ;;
        --agent)
            evop_require_option_value "$1" "$#"
            STATUS_AGENT_FILTER="$2"
            shift 2
            ;;
        --format)
            evop_require_option_value "$1" "$#"
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --report-file)
            evop_require_option_value "$1" "$#"
            REPORT_FILE="$2"
            shift 2
            ;;
        --report-format)
            evop_require_option_value "$1" "$#"
            REPORT_FORMAT="$2"
            shift 2
            ;;
        -t|--target-dir)
            evop_require_option_value "$1" "$#"
            TARGET_DIR="$2"
            shift 2
            ;;
        -o|--artifacts-dir)
            evop_require_option_value "$1" "$#"
            ARTIFACTS_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

evop_validate_non_negative_integer "last" "$LAST_N"
evop_status_validate_kind "$STATUS_KIND"
evop_status_validate_format "$OUTPUT_FORMAT"
if [[ -z "$REPORT_FORMAT" ]]; then
    REPORT_FORMAT="$OUTPUT_FORMAT"
fi
evop_status_validate_format "$REPORT_FORMAT"
evop_require_directory "$TARGET_DIR"
artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"

if [[ ! -d "$artifacts_root" ]]; then
    echo "No artifacts directory found: $artifacts_root"
    exit 0
fi

if (( SHOW_ALL == 0 )); then
    limit="$LAST_N"
else
    limit=0
fi

evop_collect_status_entries "$artifacts_root" "$STATUS_KIND" "$STATUS_FILTER" "$STATUS_AGENT_FILTER" "$SHOW_ALL" "$limit"
evop_print_status_output "$OUTPUT_FORMAT"
evop_write_status_report "$REPORT_FILE" "$REPORT_FORMAT"

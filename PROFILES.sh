#!/bin/sh
# shellcheck shell=bash disable=SC1090,SC1091,SC2034

. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
EVOP_LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
PROFILE_LIB="$SCRIPT_DIR/lib/profile.sh"
PROFILE_REPORT_LIB="$SCRIPT_DIR/lib/profiles/report.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$PROFILE_LIB"
source "$PROFILE_REPORT_LIB"

OUTPUT_CATEGORY="all"
OUTPUT_FORMAT="summary"
REPORT_FILE=""
REPORT_FORMAT=""

usage() {
    cat <<'EOF'
Usage: ./PROFILES.sh [options]

List the built-in language, framework, and project-type profiles that
EvoProgrammer can inject into agent prompts.

Options:
      --category NAME      Category: all, languages, frameworks, or project-types.
      --format NAME        Output format: summary, json, or env.
      --report-file FILE   Also write the selected output to a file.
      --report-format NAME Report file format. Defaults to --format.
  -q, --quiet              Suppress informational output.
  -v, --verbose            Show extra detail.
  -h, --help               Show this help text.
EOF
}

while (($# > 0)); do
    case "$1" in
        --category)
            evop_require_option_value "$1" "$#"
            OUTPUT_CATEGORY="$2"
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
        -q|--quiet)
            EVOP_VERBOSITY=0
            shift
            ;;
        -v|--verbose)
            EVOP_VERBOSITY=2
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if (($# > 0)); then
    printf 'Unexpected extra arguments: %s\n' "$*" >&2
    exit 1
fi

evop_profiles_validate_category "$OUTPUT_CATEGORY"
evop_profiles_validate_format "$OUTPUT_FORMAT"

if [[ -z "$REPORT_FORMAT" ]]; then
    REPORT_FORMAT="$OUTPUT_FORMAT"
fi
evop_profiles_validate_format "$REPORT_FORMAT"

evop_print_profiles_output "$OUTPUT_FORMAT" "$OUTPUT_CATEGORY"
evop_write_profiles_report "$REPORT_FILE" "$REPORT_FORMAT" "$OUTPUT_CATEGORY"

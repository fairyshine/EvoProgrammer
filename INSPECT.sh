#!/bin/sh
# shellcheck shell=bash disable=SC1090,SC1091,SC2034,SC2154

. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
EVOP_LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
AGENT_LIB="$SCRIPT_DIR/lib/agent.sh"
PROFILE_LIB="$SCRIPT_DIR/lib/profile.sh"
CLI_LIB="$SCRIPT_DIR/lib/cli.sh"
CONFIG_LIB="$SCRIPT_DIR/lib/config.sh"
INSPECT_LIB="$SCRIPT_DIR/lib/inspect.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"
source "$CLI_LIB"
source "$CONFIG_LIB"
source "$INSPECT_LIB"

evop_init_common_context
OUTPUT_FORMAT="summary"
REPORT_FILE=""
REPORT_FORMAT=""

usage() {
    cat <<'EOF'
Usage: ./INSPECT.sh [options]

Inspect the target repository, detect language/framework/project type, and print
the inferred command plan and project context.

Options:
  -g, --agent NAME         Agent profile context to use. Default: codex.
      --language NAME      Language profile. Auto-detected when omitted.
      --framework NAME     Framework profile. Auto-detected when omitted.
      --project-type NAME  Project-type profile. Auto-detected when omitted.
  -p, --prompt TEXT        Optional prompt signal used for task-kind inference.
  -f, --prompt-file FILE   Read the optional prompt signal from a file.
  -t, --target-dir DIR     Repository directory to inspect.
      --context-file FILE  Reuse an `inspect --format env` context snapshot.
      --format NAME        Output format: summary, diagnostics, profiles, doctor, prompt, timings, json, or env.
      --report-file FILE   Also write inspect output to a file.
      --report-format NAME Report file format. Defaults to --format.
  -h, --help               Show this help text.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
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
        --)
            shift
            break
            ;;
        -*)
            evop_parse_common_option "$1" "$#" "${2-}"
            if (( EVOP_CLI_OPTION_HANDLED == 1 )); then
                shift "$EVOP_CLI_OPTION_SHIFT"
            else
                echo "Unknown option: $1" >&2
                exit 1
            fi
            ;;
        *)
            echo "Unexpected argument: $1" >&2
            exit 1
            ;;
    esac
done

if (($# > 0)); then
    echo "Unexpected extra arguments: $*" >&2
    exit 1
fi

evop_validate_inspect_format "$OUTPUT_FORMAT"

if [[ -z "$REPORT_FORMAT" ]]; then
    REPORT_FORMAT="$OUTPUT_FORMAT"
fi
evop_validate_inspect_format "$REPORT_FORMAT"

evop_finalize_analysis_context

evop_print_project_inspection_output "$OUTPUT_FORMAT"
evop_write_project_inspection_report "$REPORT_FILE" "$REPORT_FORMAT"

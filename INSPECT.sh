#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
AGENT_LIB="$SCRIPT_DIR/lib/agent.sh"
PROFILE_LIB="$SCRIPT_DIR/lib/profile.sh"
CLI_LIB="$SCRIPT_DIR/lib/cli.sh"
CONFIG_LIB="$SCRIPT_DIR/lib/config.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"
source "$CLI_LIB"
source "$CONFIG_LIB"

evop_init_common_context
OUTPUT_FORMAT="summary"

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
      --format NAME        Output format: summary, doctor, or prompt.
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

case "$OUTPUT_FORMAT" in
    summary|doctor|prompt)
        ;;
    *)
        evop_fail "Unsupported inspect format: $OUTPUT_FORMAT"
        ;;
esac

evop_finalize_analysis_context

case "$OUTPUT_FORMAT" in
    summary)
        evop_print_project_inspection_report
        ;;
    doctor)
        printf 'OK agent %s\n' "$AGENT"
        evop_print_current_profiles "doctor"
        printf 'OK target-dir %s\n' "$TARGET_DIR"
        ;;
    prompt)
        printf '%s' "$(evop_render_project_context_prompt)"
        ;;
esac

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
AGENT_LIB="$SCRIPT_DIR/lib/agent.sh"
PROFILE_LIB="$SCRIPT_DIR/lib/profile.sh"
CLI_LIB="$SCRIPT_DIR/lib/cli.sh"
CONFIG_LIB="$SCRIPT_DIR/lib/config.sh"
MAIN_SCRIPT="$SCRIPT_DIR/MAIN.sh"
LOOP_SCRIPT="$SCRIPT_DIR/LOOP.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"
source "$CLI_LIB"
source "$CONFIG_LIB"

evop_init_common_context

usage() {
    cat <<'EOF'
Usage: ./DOCTOR.sh [options]

Checks whether EvoProgrammer can run in the requested target directory.

Options:
  -g, --agent NAME       Agent to validate: codex or claude.
      --language NAME    Language adaptation profile. Auto-detected when omitted.
      --framework NAME   Framework adaptation profile. Auto-detected when omitted.
      --project-type NAME
                         Project-type adaptation profile. Auto-detected when omitted.
  -t, --target-dir DIR   Repository directory to validate.
  -o, --artifacts-dir DIR
                         Root directory used to store run artifacts.
  -h, --help             Show this help text.

Environment variables:
  EVOPROGRAMMER_AGENT       Agent to validate. Default: codex.
  EVOPROGRAMMER_LANGUAGE_PROFILE
                           Language adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_FRAMEWORK_PROFILE
                           Framework adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_PROJECT_TYPE
                           Project-type adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_TARGET_DIR  Repository directory to validate. Default: current directory.
  EVOPROGRAMMER_ARTIFACTS_DIR
                           Root directory used to store run artifacts.
                           Default: TARGET_DIR/.evoprogrammer/runs
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            evop_parse_doctor_option "$1" "$#" "${2-}"
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

evop_require_executable_file "$MAIN_SCRIPT" "Main script"
evop_require_executable_file "$LOOP_SCRIPT" "Loop script"
evop_finalize_doctor_context
agent_command_name="$(evop_agent_command_name "$AGENT")"
evop_require_command "$agent_command_name"
mkdir -p "$artifacts_root"

printf 'OK main-script %s\n' "$MAIN_SCRIPT"
printf 'OK loop-script %s\n' "$LOOP_SCRIPT"
printf 'OK agent %s\n' "$AGENT"
evop_print_current_profiles "doctor"
printf 'OK target-dir %s\n' "$TARGET_DIR"
printf 'OK artifacts-dir %s\n' "$artifacts_root"
printf 'OK command %s\n' "$(command -v "$agent_command_name")"
